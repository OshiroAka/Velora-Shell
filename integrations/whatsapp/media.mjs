import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdirSync, statSync, writeFileSync, createWriteStream, rmSync, existsSync } from 'node:fs';
import { basename, extname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createHash, randomUUID } from 'node:crypto';
import { Transform } from 'node:stream';
import { pipeline } from 'node:stream/promises';

const run = promisify(execFile);
const limit = 100 * 1024 * 1024;
const types = {'.jpg':'image/jpeg','.jpeg':'image/jpeg','.png':'image/png','.webp':'image/webp',
  '.gif':'image/gif','.mp4':'video/mp4','.webm':'video/webm','.mov':'video/quicktime',
  '.mp3':'audio/mpeg','.ogg':'audio/ogg','.pdf':'application/pdf','.txt':'text/plain'};

export class Attachments {
  constructor(directory, runner=run) { this.directory=directory; this.entries=new Map(); this.run=runner; }
  add(urls) {
    const result=[];
    if (!Array.isArray(urls) || urls.length+this.entries.size>10) throw new Error('Anexe até 10 arquivos por envio.');
    for (const url of urls) {
      const path=fileURLToPath(url), stat=statSync(path);
      if (!stat.isFile() || stat.size>limit) throw new Error('Escolha arquivos de até 100 MB.');
      const mime=types[extname(path).toLowerCase()] || 'application/octet-stream';
      const entry={id:randomUUID(),path,name:basename(path),mime,size:stat.size,source:pathToFileURL(path).href};
      result.push(entry);
    }
    for (const entry of result) this.entries.set(entry.id,entry);
    return result;
  }
  async addStickers(urls) {
    if (!Array.isArray(urls) || urls.length+this.entries.size>10) throw new Error('Anexe até 10 figurinhas por envio.');
    const prepared=[];
    try {
      for (const url of urls) {
        const input=fileURLToPath(url), file=statSync(input);
        if (!file.isFile() || file.size>25*1024*1024) throw new Error('Escolha uma imagem de até 25 MB.');
        const sticker=await prepareSticker(input,this.directory);
        const entry={id:randomUUID(),...sticker,name:'Figurinha',mime:'image/webp',kind:'sticker',source:pathToFileURL(sticker.path).href};
        prepared.push(entry);
        entry.displayPath=await prepareStickerPreview(sticker.path,this.directory,sticker.isAnimated);
        entry.displaySource=pathToFileURL(entry.displayPath).href;
      }
      for (const entry of prepared) this.entries.set(entry.id,entry);
      return prepared;
    } catch (error) {
      for (const entry of prepared) if (entry.temporary) {rmSync(entry.path,{force:true});if(entry.displayPath)rmSync(entry.displayPath,{force:true});}
      throw error;
    }
  }
  async paste() {
    const {stdout:offered}=await this.run('wl-paste',['--list-types'],{timeout:3000,maxBuffer:65536});
    const types=offered.trim().split('\n');
    if (types.includes('text/uri-list')) {
      const {stdout}=await this.run('wl-paste',['--no-newline','--type','text/uri-list'],{timeout:3000,maxBuffer:65536});
      const urls=stdout.split(/\r?\n/).filter(value=>value.startsWith('file://'));
      if (urls.length) return {attachments:this.add(urls)};
    }
    const mime=types.find(value=>['image/png','image/jpeg','image/webp'].includes(value));
    if (mime) {
      const {stdout}=await this.run('wl-paste',['--no-newline','--type',mime],{encoding:'buffer',timeout:5000,maxBuffer:25*1024*1024});
      const directory=join(this.directory,'attachments'); mkdirSync(directory,{recursive:true,mode:0o700});
      const path=join(directory,randomUUID()+(mime==='image/jpeg'?'.jpg':mime==='image/webp'?'.webp':'.png'));
      writeFileSync(path,stdout,{mode:0o600});
      const entries=this.add([pathToFileURL(path).href]); entries[0].temporary=true;
      return {attachments:entries};
    }
    const {stdout}=await this.run('wl-paste',['--no-newline'],{timeout:3000,maxBuffer:65536});
    return {text:stdout};
  }
  remove(id) { const entry=this.entries.get(id); if (entry?.temporary) {rmSync(entry.path,{force:true});if(entry.displayPath)rmSync(entry.displayPath,{force:true});} this.entries.delete(id); }
  clear() { for (const id of this.entries.keys()) this.remove(id); }
  snapshot() { return [...this.entries.values()].map(({id,name,mime,size,source,kind,isAnimated,displaySource})=>({id,name,mime,size,source,kind:kind || '',isAnimated:!!isAnimated,displaySource:displaySource || ''})); }
}

// Qt's baseline plugins include PNG/GIF, but not WebP. Cache a bounded display
// copy once; the original WebP remains the only payload used for sending.
export function stickerPreviewPath(path,directory,animated) {
  const file=statSync(path);
  const hash=createHash('sha256').update(path+'\0'+file.size+'\0'+file.mtimeMs).digest('hex');
  return join(directory,'media','previews',hash+(animated ? '.gif' : '.png'));
}
export async function prepareStickerPreview(path,directory,animated) {
  const output=stickerPreviewPath(path,directory,animated);
  if (existsSync(output)) return output;
  const {default:sharp}=await import('sharp');
  const image=sharp(path,{animated:!!animated,limitInputPixels:64*1024*1024})
    .resize(animated ? 256 : 512,animated ? 256 : 512,{fit:'inside',withoutEnlargement:true});
  const buffer=await (animated ? image.gif({effort:3,colours:128}) : image.png()).toBuffer();
  if (buffer.length>10*1024*1024) throw new Error('A figurinha é complexa demais para a prévia.');
  mkdirSync(join(directory,'media','previews'),{recursive:true,mode:0o700});
  writeFileSync(output,buffer,{mode:0o600});return output;
}

// Reuse the sharp runtime already required by Baileys. Encode only after the
// user chooses an image; received valid WebP stickers can retain their bytes.
export async function prepareSticker(input,directory) {
  const {default:sharp}=await import('sharp');
  const options={animated:true,limitInputPixels:64*1024*1024};
  let metadata;
  try { metadata=await sharp(input,options).metadata(); }
  catch { throw new Error('Escolha uma imagem WebP, PNG, JPG ou GIF válida.'); }
  const isAnimated=(metadata.pages || 1)>1, height=metadata.pageHeight || metadata.height;
  if ((metadata.pages || 1)>150 || (metadata.delay || []).reduce((a,b)=>a+b,0)>10000) {
    throw new Error('Escolha uma figurinha com animação de até 10 segundos.');
  }
  const maximum=(isAnimated ? 500 : 100)*1024;
  const size=statSync(input).size;
  if (metadata.format==='webp' && metadata.width===512 && height===512 && size<=maximum) {
    return {path:input,size,isAnimated,temporary:false};
  }
  let buffer;
  for (const quality of [80,60,40,20]) {
    buffer=await sharp(input,options).resize(512,512,{fit:'contain',background:{r:0,g:0,b:0,alpha:0}})
      .webp({quality,effort:4}).toBuffer();
    if (buffer.length<=maximum) break;
  }
  if (buffer.length>maximum) throw new Error('A imagem é complexa demais para uma figurinha. Escolha uma menor.');
  const folder=join(directory,'attachments');mkdirSync(folder,{recursive:true,mode:0o700});
  const path=join(folder,randomUUID()+'.webp');writeFileSync(path,buffer,{mode:0o600});
  return {path,size:buffer.length,isAnimated,temporary:true};
}

export async function downloadMedia({library,socket,raw,directory,logger,mime,signal}) {
  const folder=join(directory,'media'); mkdirSync(folder,{recursive:true,mode:0o700});
  const hash=createHash('sha256').update(raw.key.remoteJid+'\0'+raw.key.id).digest('hex');
  const extension=Object.entries(types).find(([,value])=>value===mime)?.[0] || '.bin';
  const path=join(folder,hash+extension), temporary=path+'.'+randomUUID()+'.part';
  let size=0;
  const bounded=new Transform({transform(chunk,_,done) {
    size+=chunk.length; done(size>limit ? new Error('A mídia excede 100 MB.') : null,chunk);
  }});
  try {
    const stream=await library.downloadMediaMessage(raw,'stream',{options:{signal:AbortSignal.any([signal,AbortSignal.timeout(30000)])}},
      {logger,reuploadRequest:message=>socket.updateMediaMessage(message)});
    await pipeline(stream,bounded,createWriteStream(temporary,{mode:0o600}),{signal});
    const {renameSync}=await import('node:fs'); renameSync(temporary,path);
    return path;
  } catch (error) { rmSync(temporary,{force:true}); throw error; }
}
