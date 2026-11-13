import { createInterface } from 'node:readline';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { openSync, writeFileSync, readFileSync, unlinkSync, mkdirSync, closeSync } from 'node:fs';
import { WhatsAppStore } from './store.mjs';
import { WhatsAppClient } from './client.mjs';

process.umask(0o077);
const publish = value => process.stdout.write(JSON.stringify(value) + '\n');
let store, client, lock;
try {
  const [library, { default: pino }, { default: qr }] = await Promise.all([
    import('baileys'), import('pino'), import('qrcode'),
  ]);
  if (process.argv.includes('--check')) {
    publish({ available: true, receiveOnly: false, protocol: 1 });
    process.exit(0);
  }
  const directory = join(process.env.XDG_STATE_HOME || join(homedir(), '.local', 'state'), 'velora-shell', 'whatsapp');
  mkdirSync(directory, { recursive: true, mode: 0o700 });
  lock = join(directory, 'client.lock');
  try { closeSync(openSync(lock, 'wx', 0o600)); }
  catch (error) {
    if (error.code !== 'EEXIST') throw error;
    const pid = Number(readFileSync(lock, 'utf8'));
    let alive = false;
    if (pid > 0) try { process.kill(pid, 0); alive = true; } catch (failure) { if (failure.code !== 'ESRCH') alive = true; }
    else alive = true;
    if (alive) { lock = null; throw Object.assign(new Error(), { code: 'CLIENT_RUNNING' }); }
    unlinkSync(lock); closeSync(openSync(lock, 'wx', 0o600));
  }
  writeFileSync(lock, String(process.pid), { mode: 0o600 });
  store = new WhatsAppStore(directory, library);
  client = new WhatsAppClient({ library, store, publish, logger: pino({ level: 'silent' }),
    renderQr: async text => 'data:image/svg+xml;base64,' + Buffer.from(await qr.toString(text,
      { type: 'svg', margin: 3, width: 256, color: { dark: '#101316', light: '#ffffff' } })).toString('base64') });
  const input = createInterface({ input: process.stdin });
  let commands = Promise.resolve();
  input.on('line', line => {
    if (line.length > 131072) return;
    let value;
    try { value = JSON.parse(line); } catch { return; }
    commands = commands.then(() => client.command(value)).catch(() => client.operationError('Não foi possível concluir a operação.'));
  });
  input.on('close', () => { void commands.finally(() => finish()); });
  process.on('SIGTERM', finish); process.on('SIGINT', finish);
  client.start();
} catch (error) {
  publish({ type: 'state', ready: false, state: 'error', contacts: [], code: error.code === 'CLIENT_RUNNING' ? 'client_running' : 'service_error',
    error: error.code === 'CLIENT_RUNNING' ? 'O WhatsApp já está aberto em outra instância do Velora.'
      : error.code === 'ERR_MODULE_NOT_FOUND' ? 'A integração do WhatsApp ainda não está instalada.'
      : 'Não foi possível iniciar a integração do WhatsApp.' });
  finish(1);
}
function finish(code = 0) {
  client?.stop(); store?.close(); store = null;
  if (lock) { try { if (readFileSync(lock, 'utf8') === String(process.pid)) unlinkSync(lock); } catch {} lock = null; }
  process.exit(typeof code === 'number' ? code : 0);
}
