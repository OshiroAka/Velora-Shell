import { phoneNumber, chatId, messageMedia } from './model.mjs';
import { Attachments, downloadMedia, prepareStickerPreview, stickerPreviewPath } from './media.mjs';
import { copyFileSync, mkdirSync, chmodSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

// A chat client. Sending only happens after an explicit composer action;
// received messages never trigger commands, bots or automatic replies.
export class WhatsAppClient {
  constructor({ library, store, logger, renderQr, publish }) {
    Object.assign(this, { library, store, logger, renderQr, publish });
    this.state = 'idle'; this.method = 'qr'; this.error = '';
    this.pairingCode = ''; this.qrImage = ''; this.phone = '';
    this.selectedId = ''; this.groups = false; this.accountName = '';
    this.generation = 0; this.socket = null; this.retry = null; this.attempts = 0;
    this.stopped = false; this.codeRequested = false;
    this.auth = store.authState();
    const selection=store.selection(); this.selectedId=selection.id || ''; this.groups=selection.groups===true;
    this.attachments = new Attachments(store.directory);
    this.photoQueue=[]; this.photoPending=new Set(); this.photoWorkers=0;
    this.mediaQueue=[]; this.mediaPending=new Set(); this.mediaErrors=new Map(); this.mediaWorkers=0;
    this.publishTimer=null; this.abort=new AbortController(); this.sending=false;
    this.stickersVisible=false;
  }
  get hasSession() {
    // Web QR pairing supplies me.id; the registered flag is also used by the
    // phone-code flow. Either authenticated identity must resume on restart.
    return !!this.auth.state.creds.me?.id || this.auth.state.creds.registered === true;
  }
  snapshot() {
    const chats = this.store.snapshot(this.selectedId, this.groups, this.auth.state.creds.me?.id);
    this.selectedId = chats.selectedId;
    if (this.hasSession) this.store.select(this.selectedId,this.groups);
    for (const contact of chats.contacts) for (const message of contact.messages) if (message.media) {
      const key=contact.id+'\0'+message.id;
      message.media.loading=this.mediaPending.has(key);
      message.media.error=this.mediaErrors.get(key) || '';
    }
    this.publish({ type: 'state', ready: true, receiveOnly: false, sending:this.sending,
      attachments:this.attachments.snapshot(),
      stickers:this.stickersVisible ? this.store.recentStickers().map(sticker=>({...sticker,
        loading:this.mediaPending.has(sticker.chat+'\0'+sticker.id),error:this.mediaErrors.get(sticker.chat+'\0'+sticker.id) || ''})) : [],
      state: this.state, method: this.method, error: this.error,
      pairingCode: this.pairingCode, qrImage: this.qrImage,
      hasSession: this.hasSession,
      accountName: this.accountName, ...chats });
  }
  start() {
    if (this.hasSession) this.connect();
    else this.snapshot();
  }
  endSocket() {
    this.generation++;
    this.sending=false;
    this.abort.abort(); this.abort=new AbortController();
    clearTimeout(this.publishTimer); this.publishTimer=null;
    this.photoQueue=[]; this.photoPending.clear(); this.photoWorkers=0;
    this.mediaQueue=[]; this.mediaPending.clear(); this.mediaWorkers=0;
    clearTimeout(this.retry); this.retry = null;
    const old = this.socket; this.socket = null;
    if (old) old.end(new Error('Velora connection closed'));
  }
  connect() {
    this.endSocket(); this.stopped = false; this.codeRequested = false;
    const generation = this.generation;
    this.auth = this.store.authState();
    this.state = this.attempts ? 'reconnecting' : 'connecting'; this.error = '';
    this.snapshot();
    try {
      const socket = this.library.default({
        auth: { creds: this.auth.state.creds,
          keys: this.library.makeCacheableSignalKeyStore(this.auth.state.keys, this.logger) },
        logger: this.logger,
        browser: this.library.Browsers.ubuntu('Chrome'),
        markOnlineOnConnect: false, emitOwnEvents: true, syncFullHistory: false,
        connectTimeoutMs: 20000, keepAliveIntervalMs: 30000,
        getMessage: async key => this.store.getMessage(key),
        shouldIgnoreJid: id => !chatId(id),
      });
      this.socket = socket;
      socket.ev.on('creds.update', update => {
        if (generation === this.generation) this.auth.saveCreds(update);
      });
      socket.ev.process(events => {
        if (generation !== this.generation) return;
        try { this.events(events, generation); }
        catch { this.fail('Não foi possível atualizar as conversas.'); }
      });
    } catch { this.fail('Não foi possível iniciar a conexão com o WhatsApp.'); }
  }
  events(events, generation) {
    if (events['connection.update']) {
      void this.connection(events['connection.update'], generation).catch(() => {
        if (generation === this.generation) this.fail('Não foi possível concluir o pareamento. Tente novamente.');
      });
    }
    const history = events['messaging-history.set'];
    if (events['lid-mapping.update']) this.store.linkLid(events['lid-mapping.update']);
    if (history) {
      this.store.contacts(history.contacts); this.store.contacts(history.chats);
      this.store.addMessages(history.messages);
    }
    for (const name of ['contacts.upsert', 'contacts.update', 'chats.upsert', 'chats.update', 'groups.upsert', 'groups.update']) {
      if (events[name]) this.store.contacts(events[name]);
    }
    const messages = events['messages.upsert'];
    if (messages) this.store.addMessages(messages.messages, messages.type === 'notify');
    if (events['messages.update']) this.store.updateMessages(events['messages.update']);
    if (events['messages.delete']) this.store.deleteMessages(events['messages.delete']);
    if (events['chats.delete']) this.store.deleteChats(events['chats.delete']);
    if (Object.keys(events).some(name => name !== 'connection.update' && name !== 'creds.update')) {
      this.snapshot(); this.prefetch();
    }
  }
  async connection(update, generation) {
    if (generation !== this.generation) return;
    if (update.qr && !this.hasSession) {
      if (this.method === 'qr') {
        const image = await this.renderQr(update.qr);
        if (generation !== this.generation) return;
        this.qrImage = image; this.pairingCode = ''; this.state = 'awaiting_qr'; this.snapshot();
      } else if (!this.codeRequested && this.phone) {
        this.codeRequested = true;
        const code = await this.socket.requestPairingCode(this.phone);
        if (generation !== this.generation) return;
        this.pairingCode = String(code).replace(/(.{4})(?=.)/g, '$1-');
        this.qrImage = ''; this.state = 'awaiting_code'; this.snapshot();
      }
    }
    if (generation !== this.generation) return;
    if (update.connection === 'open') {
      this.auth.saveCreds(); this.attempts = 0; this.state = 'connected'; this.error = '';
      this.qrImage = ''; this.pairingCode = ''; this.phone = '';
      this.accountName = String(this.socket?.user?.name || ''); this.snapshot();
      this.prefetch();
      const socket=this.socket;
      if (socket.groupFetchAllParticipating) void socket.groupFetchAllParticipating().then(groups=>{
        if (generation !== this.generation) return;
        this.store.contacts(Object.values(groups)); this.snapshot(); this.prefetch();
      }).catch(()=>{});
    } else if (update.connection === 'close') {
      const reason = update.lastDisconnect?.error?.output?.statusCode;
      const reasons = this.library.DisconnectReason;
      this.endSocket();
      if (this.stopped) return;
      if (reason === reasons.loggedOut) {
        // Only an actual server revocation invalidates the saved account.
        this.store.clearAccount(); this.auth = this.store.authState();
        this.state = 'idle'; this.error = 'O WhatsApp encerrou o vínculo deste aparelho. Conecte sua conta novamente.';
        this.qrImage = ''; this.pairingCode = ''; this.selectedId = ''; this.snapshot();
      } else if (reason === reasons.connectionReplaced) {
        this.state = 'error'; this.error = 'Esta sessão foi aberta em outro lugar.'; this.snapshot();
      } else if (this.hasSession || reason === reasons.restartRequired) {
        // Baileys also maps generic WebSocket/stream failures to badSession
        // (500). Retry them with the saved identity instead of erasing it.
        this.auth.saveCreds();
        this.state = 'reconnecting'; this.snapshot();
        const delay = reason === reasons.restartRequired ? 250 : Math.min(30000, 1000 * 2 ** Math.min(this.attempts++, 5));
        this.retry = setTimeout(() => this.connect(), delay);
      } else this.fail('O pareamento expirou ou a conexão foi interrompida. Tente novamente.');
    }
  }
  fail(message) {
    this.endSocket(); this.state = 'error'; this.error = message;
    this.qrImage = ''; this.pairingCode = ''; this.snapshot();
  }
  changed() {
    if (!this.publishTimer) this.publishTimer=setTimeout(()=>{this.publishTimer=null;this.snapshot();},180);
  }
  prefetch() {
    if (this.state!=='connected' || !this.socket) return;
    const ids=this.store.photoIds(this.selectedId,this.auth.state.creds.me?.id);
    for (const id of ids) {
      this.queuePhoto(id);
      const parent=this.store.communityParent(id); if (parent) this.queuePhoto(parent);
    }
    const selected=this.store.snapshot(this.selectedId,this.groups,this.auth.state.creds.me?.id).contacts.find(c=>c.id===this.selectedId);
    for (const message of (selected?.messages || []).slice(-12)) {
      if (['image','sticker'].includes(message.media?.kind)) this.queueMedia(this.selectedId,message.id,false);
    }
  }
  queuePhoto(value) {
    const id=this.store.canonical(value); if (!id || this.photoPending.has(id)) return;
    const profile=this.store.profile(id), ttl=profile.avatar ? 6*3600000 : 15*60000;
    if (profile.checked && Date.now()-profile.checked<ttl) return;
    this.photoPending.add(id); this.photoQueue.push(id); this.pumpPhotos();
  }
  pumpPhotos() {
    const socket=this.socket, generation=this.generation;
    while (socket && this.state==='connected' && this.photoWorkers<2 && this.photoQueue.length) {
      const id=this.photoQueue.shift(); this.photoWorkers++;
      void (async()=>{
        let url=this.store.profile(id).avatar || '';
        try { url=await socket.profilePictureUrl(id,'image',8000) || ''; }
        catch (error) { if ([401,403,404].includes(error?.output?.statusCode)) url=''; }
        if (generation!==this.generation) return;
        this.store.avatar(id,/^https:\/\//.test(url) ? url : '');
        this.photoPending.delete(id); this.photoWorkers--; this.changed(); this.pumpPhotos();
      })();
    }
  }
  queueMedia(chat,id,retry=true) {
    chat=this.store.canonical(chat);
    const key=chat+'\0'+id, raw=this.store.rawMessage(chat,id), media=messageMedia(raw?.message);
    const path=this.store.mediaPath(chat,id), needsPreview=media && (media.kind==='sticker' || media.mime==='image/webp');
    if (!raw || !media || (path && (!needsPreview || existsSync(stickerPreviewPath(path,this.store.directory,media.isAnimated)))) || this.mediaPending.has(key)) return;
    if (!retry && this.mediaErrors.has(key)) return;
    this.mediaErrors.delete(key); this.mediaPending.add(key); this.mediaQueue.push({chat,id,raw,media,key,path});
    this.changed(); this.pumpMedia();
  }
  pumpMedia() {
    const socket=this.socket, generation=this.generation, signal=this.abort.signal;
    while (socket && this.state==='connected' && this.mediaWorkers<2 && this.mediaQueue.length) {
      const job=this.mediaQueue.shift(); this.mediaWorkers++;
      void (async()=>{
        try {
          const path=job.path || await downloadMedia({library:this.library,socket,raw:job.raw,directory:this.store.directory,
            logger:this.logger,mime:job.media.mime,signal});
          if (generation!==this.generation) return;
          this.store.saveMedia(job.chat,job.id,path);
          if (job.media.kind==='sticker' || job.media.mime==='image/webp') await prepareStickerPreview(path,this.store.directory,job.media.isAnimated);
          if (generation!==this.generation) return;
        } catch {
          if (generation!==this.generation) return;
          this.mediaErrors.set(job.key,'Não foi possível baixar. Toque para tentar novamente.');
        }
        this.mediaPending.delete(job.key); this.mediaWorkers--; this.changed(); this.pumpMedia();
      })();
    }
  }
  operationError(error) { this.publish({type:'operation',error}); }
  async sendMessage(value) {
    const chat=this.store.canonical(value.chat);
    const text=String(value.text || '').slice(0,32768);
    const ids=Array.isArray(value.attachments) ? value.attachments.slice(0,10) : [];
    if (!chat || chat!==this.selectedId || this.state!=='connected' || !this.socket || this.sending) {
      this.operationError('Aguarde a conexão para enviar.'); return;
    }
    if (!text.trim() && !ids.length) return;
    const files=ids.map(id=>this.attachments.entries.get(id));
    if (files.some(file=>!file)) { this.operationError('Selecione os arquivos novamente.'); return; }
    const socket=this.socket, generation=this.generation;
    this.sending=true; this.snapshot();
    try {
      if (text.trim()) {
        const sent=await socket.sendMessage(chat,{text});
        if (generation!==this.generation) return;
        if (sent) this.store.addMessages([sent]);
        this.publish({type:'sent',chat,text});
      }
      for (const file of files) {
        const kind=file.kind==='sticker' ? 'sticker' : file.mime.startsWith('image/') && file.mime!=='image/gif' ? 'image'
          : file.mime.startsWith('video/') ? 'video' : 'document';
        let cached='';
        if (kind==='sticker') {
          const folder=join(this.store.directory,'media');mkdirSync(folder,{recursive:true,mode:0o700});
          cached=join(folder,file.id+'.webp');copyFileSync(file.path,cached);chmodSync(cached,0o600);
          if (file.displayPath) {
            const preview=stickerPreviewPath(cached,this.store.directory,file.isAnimated);
            copyFileSync(file.displayPath,preview);chmodSync(preview,0o600);
          }
        }
        const content=kind==='sticker' ? {sticker:{url:cached},isAnimated:!!file.isAnimated,width:512,height:512}
          : {[kind]:{url:file.path},mimetype:file.mime,fileName:file.name};
        const sent=await socket.sendMessage(chat,content);
        if (generation!==this.generation) return;
        if (sent) {
          this.store.addMessages([sent]);
          if (kind==='sticker') this.store.saveMedia(sent.key.remoteJid,sent.key.id,cached);
        }
        this.attachments.remove(file.id);
        this.publish({type:'sent',chat});
      }
    } catch { if (generation===this.generation) this.operationError('Não foi possível enviar. O conteúdo pendente foi preservado.'); }
    finally { if (generation===this.generation) {this.sending=false;this.snapshot();this.prefetch();} }
  }
  async command(value) {
    if (value?.action === 'pair') {
      const method = value.method === 'code' ? 'code' : 'qr';
      const number = method === 'code' ? phoneNumber(value.phone) : '';
      if (method === 'code' && !number) {
        this.error = 'Informe o número completo, incluindo o código do país.'; this.snapshot(); return;
      }
      if (this.hasSession) { this.connect(); return; }
      this.endSocket(); this.store.clearAccount(); this.auth = this.store.authState();
      this.method = method; this.phone = number; this.pairingCode = ''; this.qrImage = '';
      this.attempts = 0; this.connect();
    } else if (value?.action === 'method') {
      if (this.hasSession) return;
      this.endSocket(); this.stopped = true; this.state = 'idle'; this.error = '';
      this.method = value.method === 'code' ? 'code' : 'qr';
      this.qrImage = ''; this.pairingCode = ''; this.phone = ''; this.snapshot();
    } else if (value?.action === 'cancel') {
      this.endSocket(); this.stopped = true; this.state = 'idle'; this.error = '';
      this.qrImage = ''; this.pairingCode = ''; this.phone = ''; this.snapshot();
    } else if (value?.action === 'connect') this.connect();
    else if (value?.action === 'select') {
      const id = chatId(value.id);
      if (!id) return;
      this.attachments.clear(); this.selectedId = this.store.canonical(id); this.store.viewed(this.selectedId);
      this.snapshot(); this.prefetch();
    } else if (value?.action === 'groups') {
      this.attachments.clear(); this.groups = value.groups === true; this.selectedId = ''; this.snapshot(); this.prefetch();
    } else if (value?.action === 'send') {
      void this.sendMessage(value);
    } else if (value?.action === 'stickers') {
      this.stickersVisible=value.visible===true;
      if (this.stickersVisible && this.state==='connected') {
        for (const sticker of this.store.recentStickers()) this.queueMedia(sticker.chat,sticker.id,false);
      }
      this.snapshot();
    } else if (value?.action === 'attachSticker') {
      const path=this.store.mediaPath(value.chat,value.id), raw=this.store.rawMessage(value.chat,value.id);
      if (!path || messageMedia(raw?.message)?.kind!=='sticker') {this.operationError('Esta figurinha ainda não está disponível.');return;}
      const generation=this.generation, chat=this.selectedId;
      try {
        const entries=await this.attachments.addStickers([pathToFileURL(path).href]);
        if (generation!==this.generation || chat!==this.selectedId) {for(const entry of entries)this.attachments.remove(entry.id);return;}
        this.snapshot();
      } catch (error) {this.operationError(error.message);}
    } else if (value?.action === 'attach' || value?.action === 'paste' || value?.action === 'importStickers') {
      const generation=this.generation, chat=this.selectedId;
      try {
        const result=value.action==='paste' ? await this.attachments.paste()
          : {attachments:value.action==='importStickers' ? await this.attachments.addStickers(value.urls) : this.attachments.add(value.urls)};
        if (generation!==this.generation || chat!==this.selectedId) {for(const entry of result.attachments || [])this.attachments.remove(entry.id);return;}
        if (result.text!==undefined) this.publish({type:'paste',text:result.text,chat});
        this.snapshot();
      } catch (error) { this.operationError(value.action==='paste' ? 'Não foi possível colar o conteúdo.' : error.message); }
    } else if (value?.action === 'removeAttachment') {
      this.attachments.remove(value.id); this.snapshot();
    } else if (value?.action === 'media') {
      this.queueMedia(value.chat,value.id);
    } else if (value?.action === 'logout') {
      const socket = this.socket;
      this.stopped = true;
      if (socket) await socket.logout();
      this.endSocket(); this.attachments.clear(); this.store.clearAccount(); this.auth = this.store.authState();
      this.state = 'idle'; this.qrImage = ''; this.pairingCode = ''; this.error = '';
      this.selectedId = ''; this.accountName = ''; this.snapshot();
    } else if (value?.action === 'status') this.snapshot();
  }
  stop() { this.stopped = true; this.endSocket(); }
}
