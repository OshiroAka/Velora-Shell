// A fresh Node process on each invocation; no connection to a real account.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import * as baileys from 'baileys';
import pino from 'pino';
import { WhatsAppStore } from '../store.mjs';
import { WhatsAppClient } from '../client.mjs';

const [mode,directory]=process.argv.slice(2);
assert.ok(['seed','resume'].includes(mode));
process.umask(0o077);
const store=new WhatsAppStore(directory,baileys);
const logger=pino({level:'silent'}), sockets=[], states=[];
const library={...baileys,default:config=>{
  const ev=baileys.makeEventBuffer(logger);
  ev.on('creds.update',update=>Object.assign(config.auth.creds,update));
  const socket={ev,user:{name:'Fixture'},end:()=>{}};
  sockets.push(socket);return socket;
}};
const client=new WhatsAppClient({library,store,logger,publish:value=>states.push(value),
  renderQr:()=>{throw new Error('A saved session must not request a QR code');}});
const identity=()=>createHash('sha256').update(client.auth.state.creds.noiseKey.private).digest('hex');
const chat='5511999990000@s.whatsapp.net';
if (mode==='seed') {
  await client.command({action:'pair',method:'qr'});
  sockets[0].ev.emit('creds.update',{me:{id:chat.replace('@',':1@')},account:{details:Buffer.from([4,5,6])}});
  sockets[0].ev.emit('connection.update',{connection:'open'});
  await client.auth.state.keys.set({session:{fixture:Buffer.from([1,2,3])}});
  store.addMessages([{key:{remoteJid:chat,id:'saved'},messageTimestamp:10,message:{conversation:'Saved locally'}}]);
  store.select(chat,false);
  writeFileSync(join(directory,'fixture-identity'),identity(),{mode:0o600});
  console.log('SESSION_SEED_OK');
  // No graceful stop, DB close or explicit final save: test WAL durability.
  process.exit(0);
}
client.start();
assert.equal(sockets.length,1);
assert.equal(client.hasSession,true);
assert.equal(identity(),readFileSync(join(directory,'fixture-identity'),'utf8'));
assert.equal(client.auth.state.creds.registered,false,'QR pairing does not require phone registration');
assert.deepEqual(await client.auth.state.keys.get('session',['fixture']),{fixture:Buffer.from([1,2,3])});
assert.equal(client.selectedId,chat);
assert.equal(store.getMessage({remoteJid:chat,id:'saved'}).conversation,'Saved locally');
sockets[0].ev.emit('connection.update',{connection:'open'});
assert.equal(states.at(-1).state,'connected');assert.equal(states.at(-1).qrImage,'');
assert.doesNotMatch(JSON.stringify(states),/noiseKey|signedIdentityKey|advSecretKey/);
client.stop();store.close();
console.log('SESSION_RESUME_OK');
