import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, rmSync, statSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import * as baileys from 'baileys';
import pino from 'pino';
import { WhatsAppStore } from '../store.mjs';
import { WhatsAppClient } from '../client.mjs';
import { phoneNumber } from '../model.mjs';
import { Attachments,prepareSticker,prepareStickerPreview } from '../media.mjs';
import sharp from 'sharp';
import { pathToFileURL } from 'node:url';
import { Readable } from 'node:stream';
import { execFileSync } from 'node:child_process';

const settle = async () => { await new Promise(resolve => setImmediate(resolve)); };
function setup(t) {
  const directory=mkdtempSync(join(tmpdir(),'velora-whatsapp-test-'));
  const store=new WhatsAppStore(directory,baileys);
  const sockets=[],states=[];
  const library={...baileys,default:config=>{
    const ev=baileys.makeEventBuffer(pino({level:'silent'}));
    // Match Baileys' own credential listener and its real event ordering.
    ev.on('creds.update',update=>Object.assign(config.auth.creds,update));
    const socket={ config, authState:config.auth, user:{name:'Test account'}, sends:0, pairRequests:[], closed:false,
      ev,
      requestPairingCode:async phone=>{socket.pairRequests.push(phone);return 'ABCD1234';},
      sendMessage:()=>{socket.sends++;throw new Error('Sending is outside this client');},
      end:()=>{socket.closed=true;}, logout:async()=>{},
      profilePictureUrl:async()=>{throw new Error('No image');},
      batch:async events=>{
        for (const [name,value] of Object.entries(events)) ev.emit(name,value);
        await settle();
      }};
    sockets.push(socket);return socket;
  }};
  const client=new WhatsAppClient({library,store,logger:pino({level:'silent'}),
    renderQr:async qr=>'data:image/svg+xml;base64,'+Buffer.from(qr).toString('base64'),
    publish:value=>states.push(value)});
  t.after(()=>{client.stop();store.close();rmSync(directory,{recursive:true,force:true});});
  return {client,store,sockets,states,directory};
}

test('an unpaired start stays local; QR and phone pairing can alternate',async t=>{
  const {client,sockets,states}=setup(t);
  client.start();assert.equal(sockets.length,0);assert.equal(states.at(-1).state,'idle');
  await client.command({action:'pair',method:'qr'});
  await sockets[0].batch({'connection.update':{qr:'fixture-qr'}});
  assert.equal(states.at(-1).state,'awaiting_qr');
  assert.match(states.at(-1).qrImage,/^data:image\/svg\+xml;base64,/);
  assert.equal(sockets[0].pairRequests.length,0);
  await client.command({action:'method',method:'code'});
  assert.equal(sockets[0].closed,true);assert.equal(states.at(-1).qrImage,'');
  await client.command({action:'pair',method:'code',phone:'+55 (11) 99999-0000'});
  await sockets[1].batch({'connection.update':{qr:'ready-to-pair'}});
  assert.deepEqual(sockets[1].pairRequests,['5511999990000']);
  assert.equal(states.at(-1).pairingCode,'ABCD-1234');
  await client.command({action:'method',method:'qr'});
  await sockets[1].batch({'connection.update':{qr:'stale'}});
  assert.equal(states.at(-1).state,'idle');assert.equal(states.at(-1).pairingCode,'');
});

test('bad phone input does not contact WhatsApp; cancel discards late codes',async t=>{
  const {client,sockets,states}=setup(t);
  assert.equal(phoneNumber('number; shell-command'),'');
  await client.command({action:'pair',method:'code',phone:'abc123'});
  assert.equal(sockets.length,0);assert.ok(states.at(-1).error);
  await client.command({action:'pair',method:'code',phone:'5511999990000'});
  let resolveCode;
  sockets[0].requestPairingCode=()=>new Promise(resolve=>{resolveCode=resolve;});
  await sockets[0].batch({'connection.update':{qr:'ready'}});
  await client.command({action:'cancel'});
  resolveCode('LATECODE');await settle();
  assert.equal(states.at(-1).state,'idle');assert.equal(states.at(-1).pairingCode,'');
});

test('private and group messages are deduplicated and displayed without executing prefixes',async t=>{
  const {client,sockets,states,store}=setup(t);
  await client.command({action:'pair',method:'qr'});
  const socket=sockets[0];
  await socket.batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  const privateMessage={key:{remoteJid:'5511999990000@s.whatsapp.net',id:'private-1'},
    pushName:'Ana',messageTimestamp:1000,message:{conversation:'/menu <b>literal</b>'}};
  const groupMessage={key:{remoteJid:'12036300000@g.us',id:'group-1'},
    pushName:'Ana',messageTimestamp:1001,message:{extendedTextMessage:{text:'Olá, grupo'}}};
  await socket.batch({'groups.upsert':[{id:'12036300000@g.us',subject:'Friends'}],
    'messages.upsert':{type:'notify',messages:[privateMessage,groupMessage,privateMessage,
      {...privateMessage,key:{remoteJid:'status@broadcast',id:'ignored'}}]}});
  assert.equal(states.at(-1).contacts.length,1);
  assert.equal(states.at(-1).contacts[0].messages.length,1);
  assert.equal(states.at(-1).contacts[0].messages[0].text,'/menu <b>literal</b>');
  assert.equal(socket.sends,0);
  assert.deepEqual(store.getMessage(privateMessage.key),privateMessage.message);
  await client.command({action:'groups',groups:true});
  assert.equal(states.at(-1).contacts[0].name,'Friends');
  assert.equal(states.at(-1).contacts[0].messages[0].text,'Olá, grupo');
  assert.equal(states.at(-1).contacts[0].messages[0].sender,'Ana');
  await socket.batch({'messages.update':[{key:groupMessage.key,update:{message:{conversation:'Edited'}}}]});
  assert.equal(states.at(-1).contacts[0].messages[0].text,'Edited');
  await socket.batch({'messages.delete':{keys:[groupMessage.key]}});
  assert.equal(states.at(-1).contacts[0].messages[0].text,'Mensagem apagada');
});

test('LID and phone identifiers resolve to the same conversation',async t=>{
  const {store}=setup(t);
  const lid='100000000000@lid',pn='5511999990000@s.whatsapp.net';
  store.addMessages([{key:{remoteJid:lid,id:'one'},pushName:'Ana',messageTimestamp:10,message:{conversation:'one'}}]);
  store.contacts([{id:pn,lid,phoneNumber:pn,name:'Ana saved'}]);
  store.addMessages([{key:{remoteJid:lid,remoteJidAlt:pn,id:'two'},messageTimestamp:11,message:{conversation:'two'}}]);
  const snapshot=store.snapshot(lid);
  assert.equal(snapshot.contacts.length,1);assert.equal(snapshot.selectedId,pn);
  assert.equal(snapshot.contacts[0].name,'Ana saved');
  assert.equal(snapshot.contacts[0].messages.length,2);
  assert.equal(store.getMessage({remoteJid:lid,id:'one'}).conversation,'one');
});

test('credentials and Signal key batches survive restart with private file permissions',async t=>{
  const directory=mkdtempSync(join(tmpdir(),'velora-whatsapp-auth-test-'));
  let store=new WhatsAppStore(directory,baileys);
  t.after(()=>{store.close();rmSync(directory,{recursive:true,force:true});});
  const auth=store.authState();
  assert.deepEqual(store.authState().state.creds.noiseKey,auth.state.creds.noiseKey,
    'Reading auth before the first network update must not generate a different identity');
  auth.state.creds.registered=true;auth.saveCreds();
  const identity=Buffer.from(auth.state.creds.noiseKey.private);
  await auth.state.keys.set({session:{'key-one':Buffer.from([1,2,3])},
    'app-state-sync-key':{'sync-one':baileys.proto.Message.AppStateSyncKeyData.create({keyData:Buffer.from([4,5])})}});
  store.close();store=new WhatsAppStore(directory,baileys);
  const restored=store.authState();
  assert.equal(restored.state.creds.registered,true);
  assert.deepEqual(Buffer.from(restored.state.creds.noiseKey.private),identity);
  assert.deepEqual((await restored.state.keys.get('session',['key-one']))['key-one'],Buffer.from([1,2,3]));
  assert.deepEqual(Buffer.from((await restored.state.keys.get('app-state-sync-key',['sync-one']))['sync-one'].keyData),Buffer.from([4,5]));
  await restored.state.keys.set({session:{'key-one':null}});
  assert.deepEqual(await restored.state.keys.get('session',['key-one']),{});
  assert.equal(statSync(directory).mode&0o777,0o700);
  assert.equal(statSync(join(directory,'whatsapp.sqlite')).mode&0o777,0o600);
});

test('generic WebSocket failures reconnect with the same credentials, keys and conversations',async t=>{
  t.mock.timers.enable({apis:['setTimeout']});
  const {client,sockets,store,states,directory}=setup(t);
  await client.command({action:'pair',method:'qr'});
  await sockets[0].batch({'creds.update':{me:{id:'5511999990000:1@s.whatsapp.net'},
    account:{details:Buffer.from([4,5,6])}},'connection.update':{connection:'open'}});
  const identity=Buffer.from(client.auth.state.creds.noiseKey.private);
  await client.auth.state.keys.set({session:{fixture:Buffer.from([1,2,3])}});
  const chat='5511999990000@s.whatsapp.net';
  store.addMessages([{key:{remoteJid:chat,id:'saved'},messageTimestamp:10,message:{conversation:'Saved locally'}}]);
  mkdirSync(join(directory,'media'),{recursive:true});
  const media=join(directory,'media','saved.png');writeFileSync(media,'fixture');
  store.saveMedia(chat,'saved',media);
  const reason=baileys.getCodeFromWSError(new Error('WebSocket transport failure'));
  assert.equal(reason,baileys.DisconnectReason.badSession);
  await sockets[0].batch({'connection.update':{connection:'close',lastDisconnect:{error:{output:{statusCode:reason}}}}});
  assert.equal(states.at(-1).state,'reconnecting');
  assert.equal(states.at(-1).hasSession,true);
  assert.equal(store.getMessage({remoteJid:chat,id:'saved'}).conversation,'Saved locally');
  assert.equal(store.mediaPath(chat,'saved'),media);
  assert.deepEqual(Buffer.from(store.authState().state.creds.noiseKey.private),identity);
  assert.deepEqual(await store.authState().state.keys.get('session',['fixture']),{fixture:Buffer.from([1,2,3])});
  t.mock.timers.tick(1000);await settle();
  assert.equal(sockets.length,2);
  assert.deepEqual(Buffer.from(sockets[1].config.auth.creds.noiseKey.private),identity);
  await sockets[1].batch({'connection.update':{connection:'open'}});
  assert.equal(states.at(-1).state,'connected');assert.equal(states.at(-1).qrImage,'');
  assert.equal(sockets[1].pairRequests.length,0);
});

test('an actual server revocation requires pairing again and ignores stale credential updates',async t=>{
  const {client,sockets,store,states}=setup(t);
  await client.command({action:'pair',method:'qr'});
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  const chat='5511999990000@s.whatsapp.net';
  store.addMessages([{key:{remoteJid:chat,id:'saved'},messageTimestamp:10,message:{conversation:'Saved locally'}}]);
  store.select(chat,false);
  await sockets[0].batch({'connection.update':{connection:'close',
    lastDisconnect:{error:{output:{statusCode:baileys.DisconnectReason.loggedOut}}}}});
  assert.equal(states.at(-1).hasSession,false);assert.equal(client.retry,null);
  assert.equal(store.getMessage({remoteJid:chat,id:'saved'}),undefined);
  assert.deepEqual(store.selection(),{});
  await sockets[0].batch({'creds.update':{registered:true}});
  assert.equal(store.authState().state.creds.registered,false,'A stale socket cannot restore revoked auth');
  await client.command({action:'pair',method:'qr'});
  assert.equal(sockets.length,2);assert.equal(states.at(-1).hasSession,false);
});

test('logout removes the linked account and local conversations',async t=>{
  const {client,sockets,store,states}=setup(t);
  await client.command({action:'pair',method:'qr'});
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  store.addMessages([{key:{remoteJid:'5511999990000@s.whatsapp.net',id:'one'},messageTimestamp:10,message:{conversation:'private'}}]);
  await client.command({action:'logout'});
  assert.equal(states.at(-1).hasSession,false);assert.equal(states.at(-1).contacts.length,0);
  assert.equal(store.authState().state.creds.registered,false);assert.equal(sockets[0].sends,0);
});

test('a QR identity restores even when the phone-registration flag is false',async t=>{
  const {client,sockets,states}=setup(t);
  client.auth.state.creds.me={id:'5511999990000:1@s.whatsapp.net',name:'Fixture'};
  client.auth.saveCreds();
  assert.equal(client.auth.state.creds.registered,false);
  client.start();assert.equal(sockets.length,1);
  await sockets[0].batch({'connection.update':{qr:'must-not-repair',connection:'open'}});
  assert.equal(states.at(-1).hasSession,true);
  assert.equal(states.at(-1).state,'connected');assert.equal(states.at(-1).qrImage,'');
  assert.equal(sockets[0].pairRequests.length,0);
});

test('cancelling stops a scheduled reconnection and stale socket updates',async t=>{
  const {client,sockets,states}=setup(t);
  await client.command({action:'pair',method:'qr'});
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  await sockets[0].batch({'connection.update':{connection:'close',
    lastDisconnect:{error:{output:{statusCode:baileys.DisconnectReason.restartRequired}}}}});
  assert.equal(states.at(-1).state,'reconnecting');
  await client.command({action:'cancel'});
  await new Promise(resolve=>setTimeout(resolve,350));
  assert.equal(sockets.length,1);assert.equal(states.at(-1).state,'idle');
  await sockets[0].batch({'connection.update':{connection:'open'}});
  assert.equal(states.at(-1).state,'idle');
});

test('photos preload without selection; groups use each sender and community announcement uses its parent',async t=>{
  const {client,sockets,store}=setup(t);
  const person='5511999990000@s.whatsapp.net',other='5511888880000@s.whatsapp.net';
  const group='12036300001@g.us',parent='12036300002@g.us';
  store.contacts([{id:person,name:'Ana'},{id:other,name:'Bea'},{id:group,subject:'Community'}]);
  store.addMessages([{key:{remoteJid:group,participant:person,id:'group-1'},pushName:'Ana',
    messageTimestamp:10,message:{conversation:'Olá'}}]);
  await client.command({action:'pair',method:'qr'}); // pairing clears the test cache
  store.contacts([{id:person,name:'Ana'},{id:other,name:'Bea'},{id:group,subject:'Community'}]);
  store.addMessages([{key:{remoteJid:group,participant:person,id:'group-1'},pushName:'Ana',
    messageTimestamp:10,message:{conversation:'Olá'}}]);
  const calls=[];
  sockets[0].profilePictureUrl=async id=>{calls.push(id);return id===group ? undefined : 'https://example.test/'+id;};
  sockets[0].groupFetchAllParticipating=async()=>({[group]:{id:group,subject:'Community',isCommunityAnnounce:true,linkedParent:parent}});
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  await settle();await settle();
  assert.ok(calls.includes(other),'Photo of an unselected contact was fetched');
  assert.ok(calls.includes(group));assert.ok(calls.includes(parent));
  const snapshot=store.snapshot(group,true);
  assert.equal(snapshot.contacts[0].avatar,'https://example.test/'+parent);
  assert.equal(snapshot.contacts[0].messages[0].senderAvatar,'https://example.test/'+person);
  assert.notEqual(snapshot.contacts[0].messages[0].senderAvatar,snapshot.contacts[0].avatar);
  const before=calls.length;client.prefetch();await settle();assert.equal(calls.length,before,'Cache avoids repeated queries');
});

test('late photo results cannot write into a logged out account',async t=>{
  const {client,sockets,store}=setup(t);
  await client.command({action:'pair',method:'qr'});
  const person='5511999990000@s.whatsapp.net';store.contacts([{id:person,name:'Ana'}]);
  let resolvePhoto;sockets[0].profilePictureUrl=()=>new Promise(resolve=>{resolvePhoto=resolve;});
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  await client.command({action:'logout'});resolvePhoto('https://example.test/private');await settle();
  assert.equal(store.profile(person).avatar,'');assert.equal(store.snapshot('').contacts.length,0);
});

test('synced group history resolves top-level participants into separate people',async t=>{
  const {store}=setup(t), group='12036300001@g.us';
  const first='5511999990000@s.whatsapp.net',second='5511888880000@s.whatsapp.net';
  store.contacts([{id:group,subject:'Friends'},{id:first,name:'Ana'},{id:second,name:'Bea'}]);
  store.avatar(first,'https://example.test/ana');store.avatar(second,'https://example.test/bea');
  store.addMessages([first,second].map((participant,index)=>({key:{remoteJid:group,id:'old-'+index},
    participant,messageTimestamp:10+index,message:{conversation:'History'}})));
  const messages=store.snapshot(group,true).contacts[0].messages;
  assert.deepEqual(messages.map(value=>value.sender),['Ana','Bea']);
  assert.deepEqual(messages.map(value=>value.senderAvatar),['https://example.test/ana','https://example.test/bea']);
  assert.deepEqual(messages.map(value=>value.senderId),[first,second]);
});

test('the composer sends only explicit text and preserves failed drafts and attachments',async t=>{
  const {client,sockets,store,states,directory}=setup(t);
  await client.command({action:'pair',method:'qr'});
  const person='5511999990000@s.whatsapp.net';store.contacts([{id:person,name:'Ana'}]);
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  assert.equal(sockets[0].sends,0);
  const calls=[];
  sockets[0].sendMessage=async(chat,content)=>{
    calls.push({chat,content});
    return {key:{remoteJid:chat,id:'sent-'+calls.length,fromMe:true},messageTimestamp:10,
      message:content.text ? {conversation:content.text} : {documentMessage:{fileName:content.fileName}}};
  };
  await client.command({action:'send',chat:person,text:'/menu <b>literal</b>'});await settle();
  assert.deepEqual(calls[0],{chat:person,content:{text:'/menu <b>literal</b>'}});
  assert.equal(store.snapshot(person).contacts[0].messages[0].outgoing,true);
  assert.ok(states.some(value=>value.type==='sent' && value.text==='/menu <b>literal</b>'));
  const path=join(directory,'file name.txt');writeFileSync(path,'content');
  await client.command({action:'attach',urls:[pathToFileURL(path).href]});
  const attachment=client.attachments.snapshot()[0];assert.equal(attachment.name,'file name.txt');
  sockets[0].sendMessage=async()=>{throw new Error('Offline');};
  await client.command({action:'send',chat:person,text:'Preserve me',attachments:[attachment.id]});await settle();
  assert.equal(client.attachments.snapshot().length,1);assert.equal(client.sending,false);
  assert.ok(states.some(value=>value.type==='operation' && value.error));
  assert.ok(!states.some(value=>value.type==='sent' && value.text==='Preserve me'));
  sockets[0].sendMessage=async(chat,content)=>{calls.push({chat,content});return undefined;};
  await client.command({action:'send',chat:person,text:'',attachments:[attachment.id]});await settle();
  assert.equal(calls.at(-1).content.document.url,path);
  assert.equal(client.attachments.snapshot().length,0);
});

test('clipboard files, image bytes and plain text stay pending until Send',async t=>{
  const {directory}=setup(t);
  const path=join(directory,'file with spaces.png');writeFileSync(path,Buffer.from([1,2,3]));
  let mode='files';const calls=[];
  const clipboard=new Attachments(directory,async(file,args)=>{
    calls.push({file,args});
    if (args.includes('--list-types')) return {stdout:mode==='files'?'text/uri-list\n':mode==='image'?'image/png\n':'text/plain\n'};
    return {stdout:mode==='files'?'# files\r\n'+pathToFileURL(path).href+'\r\n':mode==='image'?Buffer.from([4,5,6]):'plain\ntext'};
  });
  assert.equal((await clipboard.paste()).attachments[0].name,'file with spaces.png');
  mode='image';const image=(await clipboard.paste()).attachments[0];
  assert.equal(image.mime,'image/png');assert.deepEqual(readFileSync(image.path),Buffer.from([4,5,6]));
  assert.equal(statSync(image.path).mode&0o777,0o600);
  clipboard.remove(image.id);assert.equal(existsSync(image.path),false);
  mode='text';assert.equal((await clipboard.paste()).text,'plain\ntext');
  assert.ok(calls.every(value=>value.file==='wl-paste'));assert.equal(clipboard.snapshot().length,1);
});

test('images download on selection; videos remain thumbnails until explicitly opened',async t=>{
  const {client,sockets,store}=setup(t);
  await client.command({action:'pair',method:'qr'});
  const person='5511999990000@s.whatsapp.net',calls=[];
  client.library.downloadMediaMessage=async raw=>{calls.push(raw.key.id);return Readable.from([Buffer.from('test media bytes')]);};
  store.contacts([{id:person,name:'Ana'}]);
  store.addMessages(['image','video'].map((kind,index)=>({key:{remoteJid:person,id:kind},messageTimestamp:10+index,
    message:{[kind+'Message']:{mimetype:kind==='image'?'image/png':'video/mp4',jpegThumbnail:Buffer.from('thumb')}}})));
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  for (let i=0;i<30&&!store.mediaPath(person,'image');i++) await new Promise(resolve=>setTimeout(resolve,10));
  assert.ok(store.mediaPath(person,'image'));assert.deepEqual(calls,['image']);
  assert.equal(statSync(store.mediaPath(person,'image')).mode&0o777,0o600);
  const video=store.snapshot(person).contacts[0].messages[1].media;
  assert.equal(video.kind,'video');assert.equal(video.source,'');assert.match(video.thumbnail,/^data:image\/jpeg/);
  await client.command({action:'media',chat:person,id:'video'});
  for (let i=0;i<30&&!store.mediaPath(person,'video');i++) await new Promise(resolve=>setTimeout(resolve,10));
  assert.ok(store.mediaPath(person,'video'));assert.deepEqual(calls,['image','video']);
  await client.command({action:'media',chat:person,id:'video'});assert.equal(calls.length,2);
});

test('emoji sequences are sent as unchanged Unicode text',async t=>{
  const {client,sockets,store}=setup(t),chat='5511999990000@s.whatsapp.net';
  await client.command({action:'pair',method:'qr'});store.contacts([{id:chat,name:'Ana'}]);
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  let content;
  sockets[0].sendMessage=async(_,value)=>{content=value;return {key:{remoteJid:chat,id:'emoji',fromMe:true},
    messageTimestamp:10,message:{conversation:value.text}};};
  const text='Olá 👩🏽‍💻 ❤️ 😀';await client.command({action:'send',chat,text});await settle();
  assert.equal(content.text,text);assert.equal(store.snapshot(chat).contacts[0].messages[0].text,text);
});

test('imported images become private 512px WebP stickers and use the sticker SDK message type',async t=>{
  const {client,sockets,store,directory,states}=setup(t),chat='5511999990000@s.whatsapp.net';
  const path=join(directory,'portrait.png');
  await sharp({create:{width:60,height:120,channels:4,background:{r:255,g:0,b:0,alpha:1}}}).png().toFile(path);
  await client.command({action:'pair',method:'qr'});store.contacts([{id:chat,name:'Ana'}]);
  await sockets[0].batch({'creds.update':{registered:true},'connection.update':{connection:'open'}});
  await client.command({action:'importStickers',urls:[pathToFileURL(path).href]});
  const attachment=client.attachments.snapshot()[0];assert.equal(attachment.kind,'sticker');
  assert.match(attachment.displaySource,/\.png$/);
  assert.equal(attachment.mime,'image/webp');assert.ok(attachment.size<=100*1024);
  const pendingPath=client.attachments.entries.get(attachment.id).path;
  const metadata=await sharp(pendingPath).metadata();assert.equal(metadata.width,512);assert.equal(metadata.height,512);
  assert.equal(metadata.format,'webp');assert.ok(metadata.hasAlpha);assert.equal(statSync(pendingPath).mode&0o777,0o600);
  let sent;
  sockets[0].sendMessage=async(_,content)=>{
    assert.ok(content.sticker);assert.ok(!content.image);assert.equal(content.isAnimated,false);
    sent=await baileys.prepareWAMessageMedia(content,{logger:pino({level:'silent'}),
      upload:async(_,options)=>{assert.equal(options.mediaType,'sticker');return {mediaUrl:'https://example.test/media',directPath:'/fixture'};}});
    return {key:{remoteJid:chat,id:'sent-sticker',fromMe:true},messageTimestamp:10,message:sent};
  };
  await client.command({action:'send',chat,text:'',attachments:[attachment.id]});
  for(let i=0;i<100&&client.sending;i++) await new Promise(resolve=>setTimeout(resolve,10));
  assert.ok(sent?.stickerMessage);assert.ok(!sent.imageMessage);assert.equal(sent.stickerMessage.width,512);
  assert.equal(client.attachments.snapshot().length,0);assert.equal(existsSync(pendingPath),false);
  const cached=store.mediaPath(chat,'sent-sticker');assert.ok(cached);assert.equal(statSync(cached).mode&0o777,0o600);
  await client.command({action:'stickers',visible:true});
  assert.equal(states.at(-1).stickers[0].kind,'sticker');assert.ok(states.at(-1).stickers[0].source);
  assert.match(states.at(-1).stickers[0].displaySource,/\.png$/);
  await client.command({action:'attachSticker',chat,id:'sent-sticker'});
  assert.equal(client.attachments.snapshot()[0].kind,'sticker');assert.equal(sockets[0].sends,0,'Selecting never automatically sends');
});

test('existing animated WebP stickers retain their animation and byte content',async t=>{
  const {directory}=setup(t),path=join(directory,'animated.webp');
  for(let i=1;i<=2;i++) await sharp({create:{width:512,height:512,channels:4,
    background:i===1?{r:255,g:0,b:0,alpha:1}:{r:0,g:0,b:255,alpha:1}}}).png().toFile(join(directory,'frame'+i+'.png'));
  execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-framerate','10','-start_number','1',
    '-i',join(directory,'frame%d.png'),'-frames:v','2','-c:v','libwebp_anim','-loop','0',path]);
  const metadata=await sharp(path,{animated:true}).metadata();assert.equal(metadata.pages,2);assert.equal(metadata.pageHeight,512);
  const sticker=await prepareSticker(path,directory);
  assert.equal(sticker.isAnimated,true);assert.equal(sticker.path,path);assert.equal(sticker.temporary,false);
  const gif=join(directory,'animated.gif');
  execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-framerate','10','-start_number','1',
    '-i',join(directory,'frame%d.png'),'-frames:v','2','-vf','scale=96:64','-loop','0',gif]);
  const converted=await prepareSticker(gif,directory);
  assert.equal(converted.isAnimated,true);assert.equal(converted.temporary,true);assert.ok(converted.size<=500*1024);
  const resized=await sharp(converted.path,{animated:true}).metadata();
  assert.equal(resized.width,512);assert.equal(resized.pageHeight,512);assert.equal(resized.pages,2);
  const preview=await prepareStickerPreview(converted.path,directory,true);
  const displayed=await sharp(preview,{animated:true}).metadata();
  assert.equal(displayed.format,'gif');assert.equal(displayed.width,256);assert.equal(displayed.pages,2);
  assert.equal(statSync(preview).mode&0o777,0o600);
  assert.equal(await prepareStickerPreview(converted.path,directory,true),preview,'Display copies are cached');
});

test('an old sticker import cannot remove pending files in the newly selected chat',async t=>{
  const {client,store,directory}=setup(t),a='1@s.whatsapp.net',b='2@s.whatsapp.net';
  store.contacts([{id:a,name:'Ana'},{id:b,name:'Bea'}]);client.selectedId=a;
  const png=join(directory,'sticker.png');
  await sharp({create:{width:20,height:20,channels:4,background:'#ff0000'}}).png().toFile(png);
  const add=client.attachments.addStickers.bind(client.attachments);
  let prepared=false,release;const hold=new Promise(resolve=>{release=resolve;});
  client.attachments.addStickers=async urls=>{const entries=await add(urls);prepared=true;await hold;return entries;};
  const pending=client.command({action:'importStickers',urls:[pathToFileURL(png).href]});
  for(let i=0;i<100&&!prepared;i++) await new Promise(resolve=>setTimeout(resolve,10));
  assert.ok(prepared);
  await client.command({action:'select',id:b});
  const document=join(directory,'pending.txt');writeFileSync(document,'new chat');
  await client.command({action:'attach',urls:[pathToFileURL(document).href]});
  release();await pending;
  assert.equal(client.attachments.snapshot().length,1);assert.equal(client.attachments.snapshot()[0].name,'pending.txt');
});
