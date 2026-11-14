import { DatabaseSync } from 'node:sqlite';
import { mkdirSync, chmodSync, existsSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { normalizedMessage, chatId, senderId, messageMedia } from './model.mjs';
import { stickerPreviewPath } from './media.mjs';

// Credentials and messages stay in the user's private state directory.
// Signal key batches commit before their Promise resolves.
export class WhatsAppStore {
  constructor(directory, library) {
    mkdirSync(directory, { recursive: true, mode: 0o700 });
    chmodSync(directory, 0o700);
    this.library = library;
    this.directory = directory;
    this.db = new DatabaseSync(join(directory, 'whatsapp.sqlite'));
    chmodSync(join(directory, 'whatsapp.sqlite'), 0o600);
    this.db.exec(`PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL;
      CREATE TABLE IF NOT EXISTS auth (type TEXT, id TEXT, value TEXT NOT NULL, PRIMARY KEY(type,id));
      CREATE TABLE IF NOT EXISTS aliases (id TEXT PRIMARY KEY, target TEXT NOT NULL);
      CREATE TABLE IF NOT EXISTS chats (id TEXT PRIMARY KEY, name TEXT NOT NULL DEFAULT '', avatar TEXT NOT NULL DEFAULT '',
        is_group INTEGER NOT NULL, updated REAL NOT NULL DEFAULT 0, unread INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE IF NOT EXISTS messages (chat TEXT, id TEXT, text TEXT NOT NULL, timestamp REAL NOT NULL,
        outgoing INTEGER NOT NULL, sender TEXT NOT NULL, status INTEGER NOT NULL, raw TEXT NOT NULL, PRIMARY KEY(chat,id));
      CREATE INDEX IF NOT EXISTS messages_order ON messages(chat,timestamp);
      CREATE TABLE IF NOT EXISTS profiles (id TEXT PRIMARY KEY, avatar TEXT NOT NULL DEFAULT '', checked REAL NOT NULL DEFAULT 0);
      CREATE TABLE IF NOT EXISTS group_info (id TEXT PRIMARY KEY, parent TEXT NOT NULL DEFAULT '', community INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE IF NOT EXISTS media (chat TEXT, id TEXT, path TEXT NOT NULL, PRIMARY KEY(chat,id));
      CREATE TABLE IF NOT EXISTS preferences (id TEXT PRIMARY KEY, value TEXT NOT NULL);
      INSERT OR IGNORE INTO profiles(id,avatar) SELECT id,avatar FROM chats WHERE avatar!='';`);
  }
  encode(value) { return JSON.stringify(value, this.library.BufferJSON.replacer); }
  decode(value) { return JSON.parse(value, this.library.BufferJSON.reviver); }
  transaction(fn) {
    this.db.exec('BEGIN IMMEDIATE');
    try { const result = fn(); this.db.exec('COMMIT'); return result; }
    catch (error) { this.db.exec('ROLLBACK'); throw error; }
  }
  authState() {
    const row = this.db.prepare('SELECT value FROM auth WHERE type=? AND id=?').get('creds', 'current');
    const creds = row ? this.decode(row.value) : this.library.initAuthCreds();
    const saveCreds = update => {
      if (update) Object.assign(creds, update);
      this.db.prepare('INSERT OR REPLACE INTO auth VALUES(?,?,?)')
        .run('creds', 'current', this.encode(creds));
    };
    // Keep the identity used by the first socket even before pairing completes.
    // Reloading auth must never replace its Noise/identity keys mid-handshake.
    if (!row) saveCreds();
    const keys = {
      get: async (type, ids) => {
        const result = {};
        const query = this.db.prepare('SELECT value FROM auth WHERE type=? AND id=?');
        for (const id of ids) {
          const row = query.get(type, id);
          if (!row) continue;
          let value = this.decode(row.value);
          if (type === 'app-state-sync-key') value = this.library.proto.Message.AppStateSyncKeyData.fromObject(value);
          result[id] = value;
        }
        return result;
      },
      set: async (data) => this.transaction(() => {
        const write = this.db.prepare('INSERT OR REPLACE INTO auth VALUES(?,?,?)');
        const remove = this.db.prepare('DELETE FROM auth WHERE type=? AND id=?');
        for (const [type, entries] of Object.entries(data)) for (const [id, value] of Object.entries(entries)) {
          if (value == null) remove.run(type, id); else write.run(type, id, this.encode(value));
        }
      }),
      clear: async () => this.db.prepare("DELETE FROM auth WHERE type!='creds'").run(),
    };
    return { state: { creds, keys }, saveCreds };
  }
  clearAccount() {
    this.transaction(() => this.db.exec('DELETE FROM auth; DELETE FROM chats; DELETE FROM messages; DELETE FROM aliases; DELETE FROM profiles; DELETE FROM group_info; DELETE FROM media; DELETE FROM preferences;'));
    rmSync(join(this.directory,'media'), {recursive:true,force:true});
    rmSync(join(this.directory,'attachments'), {recursive:true,force:true});
  }
  canonical(value) {
    const id = chatId(value);
    return id ? this.db.prepare('SELECT target FROM aliases WHERE id=?').get(id)?.target || id : '';
  }
  linkLid(value) {
    const lid = chatId(value?.lid), pn = chatId(value?.pn);
    if (!lid.endsWith('@lid') || !pn.endsWith('@s.whatsapp.net')) return;
    if (this.canonical(lid) === pn) return;
    this.transaction(() => {
      this.db.prepare(`INSERT INTO chats SELECT ?,name,avatar,is_group,updated,unread FROM chats WHERE id=?
        ON CONFLICT(id) DO UPDATE SET name=CASE WHEN chats.name='' THEN excluded.name ELSE chats.name END,
          avatar=CASE WHEN chats.avatar='' THEN excluded.avatar ELSE chats.avatar END,
          updated=MAX(chats.updated,excluded.updated),unread=MAX(chats.unread,excluded.unread)`).run(pn,lid);
      this.db.prepare('INSERT OR IGNORE INTO messages SELECT ?,id,text,timestamp,outgoing,sender,status,raw FROM messages WHERE chat=?').run(pn,lid);
      this.db.prepare('DELETE FROM chats WHERE id=?').run(lid);
      this.db.prepare('DELETE FROM messages WHERE chat=?').run(lid);
      this.db.prepare(`INSERT INTO profiles SELECT ?,avatar,checked FROM profiles WHERE id=?
        ON CONFLICT(id) DO UPDATE SET avatar=CASE WHEN profiles.avatar='' THEN excluded.avatar ELSE profiles.avatar END,
        checked=MAX(profiles.checked,excluded.checked)`).run(pn,lid);
      this.db.prepare('DELETE FROM profiles WHERE id=?').run(lid);
      this.db.prepare('INSERT OR IGNORE INTO media SELECT ?,id,path FROM media WHERE chat=?').run(pn,lid);
      this.db.prepare('DELETE FROM media WHERE chat=?').run(lid);
      this.db.prepare('INSERT OR REPLACE INTO aliases VALUES(?,?)').run(lid,pn);
    });
  }
  contacts(values) {
    const write = this.db.prepare(`INSERT INTO chats(id,name,is_group) VALUES(?,?,?)
      ON CONFLICT(id) DO UPDATE SET name=CASE WHEN excluded.name!='' THEN excluded.name ELSE chats.name END`);
    for (const value of values || []) {
      this.linkLid({lid: value.lid || (String(value.id).endsWith('@lid') ? value.id : ''),
        pn: value.phoneNumber || (String(value.id).endsWith('@s.whatsapp.net') ? value.id : '')});
      const id = this.canonical(value.id);
      if (!id) continue;
      write.run(id, String(value.name || value.subject || value.notify || ''), id.endsWith('@g.us') ? 1 : 0);
      if (value.imgUrl === 'changed') this.invalidateAvatar(id);
      else if (/^https:\/\//.test(value.imgUrl || '')) this.avatar(id,value.imgUrl);
      else if (value.imgUrl === null) this.avatar(id,'');
      if (id.endsWith('@g.us') && (value.linkedParent !== undefined || value.isCommunity !== undefined || value.isCommunityAnnounce !== undefined)) {
        this.db.prepare(`INSERT INTO group_info VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET
          parent=excluded.parent,community=excluded.community`).run(id,chatId(value.linkedParent),value.isCommunity || value.isCommunityAnnounce ? 1 : 0);
      }
    }
  }
  addMessages(values, notify = false) {
    let added = 0;
    for (const raw of values || []) {
      if (String(raw.key?.remoteJid).endsWith('@lid')) this.linkLid({lid:raw.key.remoteJid,pn:raw.key.remoteJidAlt});
      if (String(raw.key?.participant).endsWith('@lid')) this.linkLid({lid:raw.key.participant,pn:raw.key.participantAlt});
    }
    this.transaction(() => {
      const insert = this.db.prepare('INSERT OR IGNORE INTO messages VALUES(?,?,?,?,?,?,?,?)');
      const ensure = this.db.prepare('INSERT OR IGNORE INTO chats(id,name,is_group) VALUES(?,?,?)');
      const update = this.db.prepare(`UPDATE chats SET updated=MAX(updated,?), unread=unread+?,
        name=CASE WHEN name='' AND is_group=0 AND ?!='' THEN ? ELSE name END WHERE id=?`);
      const prune = this.db.prepare(`DELETE FROM messages WHERE chat=? AND id NOT IN
        (SELECT id FROM messages WHERE chat=? ORDER BY timestamp DESC,id DESC LIMIT 500)`);
      for (const raw of values || []) {
        const message = normalizedMessage(raw);
        if (!message) continue;
        message.chat = this.canonical(message.chat);
        const group = message.chat.endsWith('@g.us');
        ensure.run(message.chat, !group && !message.outgoing ? message.sender : '', group ? 1 : 0);
        const result = insert.run(message.chat, message.id, message.text, message.timestamp,
          message.outgoing ? 1 : 0, message.sender, message.status, this.encode(message.raw));
        if (!result.changes) continue;
        added++;
        const name = !message.outgoing ? message.sender : '';
        update.run(message.timestamp, notify && !message.outgoing ? 1 : 0, name, name, message.chat);
        prune.run(message.chat, message.chat);
      }
    });
    return added;
  }
  updateMessages(updates) {
    for (const { key, update } of updates || []) {
      const chat = this.canonical(key?.remoteJid);
      if (!chat || !key?.id) continue;
      if (update?.status !== undefined) this.db.prepare('UPDATE messages SET status=? WHERE chat=? AND id=?')
        .run(Number(update.status), chat, key.id);
      const text = update?.message && normalizedMessage({ key, message: update.message })?.text;
      if (text !== undefined && text !== null) this.db.prepare('UPDATE messages SET text=? WHERE chat=? AND id=?').run(text, chat, key.id);
    }
  }
  deleteMessages(event) {
    if (event?.all && this.canonical(event.jid)) this.db.prepare('DELETE FROM messages WHERE chat=?').run(this.canonical(event.jid));
    for (const key of event?.keys || []) if (this.canonical(key.remoteJid)) {
      this.db.prepare("UPDATE messages SET text='Mensagem apagada' WHERE chat=? AND id=?").run(this.canonical(key.remoteJid), key.id);
    }
  }
  deleteChats(ids) {
    this.transaction(() => {
      for (const original of ids || []) {
        const id = this.canonical(original);
        if (!id) continue;
        this.db.prepare('DELETE FROM chats WHERE id=?').run(id);
        this.db.prepare('DELETE FROM messages WHERE chat=?').run(id);
      }
    });
  }
  avatar(id, url) {
    id = this.canonical(id); if (!id) return;
    this.db.prepare('INSERT OR REPLACE INTO profiles VALUES(?,?,?)').run(id,url,Date.now());
    this.db.prepare('UPDATE chats SET avatar=? WHERE id=?').run(url,id);
  }
  invalidateAvatar(id) { this.db.prepare('UPDATE profiles SET checked=0 WHERE id=?').run(this.canonical(id)); }
  profile(id) { return this.db.prepare('SELECT * FROM profiles WHERE id=?').get(this.canonical(id)) || {avatar:'',checked:0}; }
  selection() { const row=this.db.prepare("SELECT value FROM preferences WHERE id='selection'").get(); return row ? JSON.parse(row.value) : {}; }
  select(id,groups) { this.db.prepare("INSERT OR REPLACE INTO preferences VALUES('selection',?)").run(JSON.stringify({id,groups})); }
  communityParent(id) { const info=this.db.prepare('SELECT * FROM group_info WHERE id=?').get(this.canonical(id)); return info?.community ? info.parent : ''; }
  photoIds(selected, self='') {
    const ids = new Set([this.canonical(selected)]);
    for (const row of this.db.prepare('SELECT id FROM chats ORDER BY updated DESC LIMIT 200').all()) ids.add(row.id);
    for (const row of this.db.prepare('SELECT raw FROM messages WHERE chat=? ORDER BY timestamp DESC LIMIT 100').all(this.canonical(selected))) {
      ids.add(this.canonical(senderId(this.decode(row.raw),self)));
    }
    return [...ids].filter(Boolean);
  }
  rawMessage(chat,id) { const row=this.db.prepare('SELECT raw FROM messages WHERE chat=? AND id=?').get(this.canonical(chat),id); return row ? this.decode(row.raw) : null; }
  mediaPath(chat,id) {
    const path=this.db.prepare('SELECT path FROM media WHERE chat=? AND id=?').get(this.canonical(chat),id)?.path;
    return path && existsSync(path) ? path : '';
  }
  saveMedia(chat,id,path) { this.db.prepare('INSERT OR REPLACE INTO media VALUES(?,?,?)').run(this.canonical(chat),id,path); }
  displaySource(path,media) {
    if (!path || (media.kind!=='sticker' && media.mime!=='image/webp')) return '';
    const preview=stickerPreviewPath(path,this.directory,media.isAnimated);
    return existsSync(preview) ? pathToFileURL(preview).href : '';
  }
  recentStickers() {
    const result=[],seen=new Set();
    const rows=this.db.prepare(`SELECT chat,id,raw FROM messages WHERE text!='Mensagem apagada'
      AND raw LIKE '%"stickerMessage"%' ORDER BY timestamp DESC LIMIT 96`).all();
    for (const row of rows) {
      const raw=this.decode(row.raw),media=messageMedia(raw.message);
      if (media?.kind!=='sticker') continue;
      const content=this.library.normalizeMessageContent(raw.message)?.stickerMessage;
      const fingerprint=content?.fileSha256 ? Buffer.from(content.fileSha256).toString('base64') : row.chat+'\0'+row.id;
      if (seen.has(fingerprint)) continue;
      seen.add(fingerprint);
      const path=this.mediaPath(row.chat,row.id);
      result.push({...media,chat:row.chat,id:row.id,source:path ? pathToFileURL(path).href : '',displaySource:this.displaySource(path,media)});
      if (result.length===32) break;
    }
    return result;
  }
  viewed(id) { this.db.prepare('UPDATE chats SET unread=0 WHERE id=?').run(id); }
  getMessage(key) {
    const row = this.db.prepare('SELECT raw FROM messages WHERE chat=? AND id=?').get(this.canonical(key.remoteJid), key.id);
    return row ? this.decode(row.raw).message : undefined;
  }
  snapshot(selected, groups = false, self = '') {
    selected = this.canonical(selected);
    const rows = this.db.prepare('SELECT * FROM chats WHERE is_group=? ORDER BY updated DESC,id LIMIT 100').all(groups ? 1 : 0);
    const chosen = rows.some(row => row.id === selected) ? selected : rows[0]?.id || '';
    const contacts = rows.map(row => ({
      id: row.id, name: row.name || row.id.split('@')[0], style: -1,
      avatar: this.profile(row.id).avatar || this.profile(this.communityParent(row.id)).avatar || row.avatar,
      status: row.is_group ? 'Grupo' : 'Conversa', unread: row.unread,
      messages: row.id === chosen ? this.db.prepare(`SELECT * FROM
        (SELECT id,text,timestamp,outgoing,sender,status,raw FROM messages WHERE chat=? ORDER BY timestamp DESC,id DESC LIMIT 100)
        ORDER BY timestamp,id`).all(chosen).map(message => {
          const raw=this.decode(message.raw), sender=this.canonical(senderId(raw,self));
          const senderName=this.db.prepare('SELECT name FROM chats WHERE id=?').get(sender)?.name;
          const media=message.text==='Mensagem apagada' ? null : messageMedia(raw.message);
          const path=media ? this.mediaPath(chosen,message.id) : '';
          return {
          id: message.id, text: message.text, timestamp: message.timestamp,
          time: new Date(message.timestamp * 1000).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
          outgoing: !!message.outgoing, sender: row.is_group && !message.outgoing
            ? senderName || raw.pushName || message.sender || sender.split('@')[0] : '',
          senderId: sender, senderAvatar: this.profile(sender).avatar,
          media: media ? {...media,source:path ? pathToFileURL(path).href : '',displaySource:this.displaySource(path,media)} : null,
          read: message.status >= 4,
        }; }) : [],
    }));
    return { contacts, selectedId: chosen, groups };
  }
  close() { this.db.close(); }
}
