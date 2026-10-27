export function chatId(value) {
  const id = String(value || '').replace(/:\d+(?=@)/, '');
  return /^[\w.-]+@(s\.whatsapp\.net|lid|g\.us)$/.test(id) ? id : '';
}

export function phoneNumber(value) {
  const text = String(value || '').trim();
  if (!/^[+\d\s()-]+$/.test(text)) return '';
  const digits = text.replace(/\D/g, '');
  return /^[1-9]\d{7,14}$/.test(digits) ? digits : '';
}

export function unwrappedMessage(message) {
  let body = message;
  for (let i = 0; i < 8; i++) {
    const wrapped = body?.ephemeralMessage || body?.viewOnceMessage
      || body?.viewOnceMessageV2 || body?.documentWithCaptionMessage;
    if (!wrapped?.message) break;
    body = wrapped.message;
  }
  return body;
}

export function messageMedia(message) {
  const body = unwrappedMessage(message);
  for (const [field, kind] of [['imageMessage','image'], ['videoMessage','video'],
    ['stickerMessage','sticker'], ['documentMessage','document'], ['audioMessage','audio']]) {
    const value = body?.[field];
    if (value) return { kind, mime: String(value.mimetype || (kind==='sticker' ? 'image/webp' : '')).split(';')[0].trim(), filename: value.fileName || '', seconds:Number(value.seconds || 0),
      isAnimated:value.isAnimated===true,caption: value.caption || '', thumbnail: value.jpegThumbnail || value.pngThumbnail
        ? 'data:image/'+(value.jpegThumbnail ? 'jpeg' : 'png')+';base64,' + Buffer.from(value.jpegThumbnail || value.pngThumbnail).toString('base64') : '' };
  }
  return null;
}

export function senderId(raw, self = '') {
  if (raw?.key?.fromMe) return chatId(self);
  // Synced history keeps the participant on WAMessageInfo; live messages
  // generally put it on the key. Both must resolve to the individual sender.
  const participant=chatId(raw?.key?.participantAlt || raw?.key?.participant || raw?.participant);
  if (chatId(raw?.key?.remoteJid).endsWith('@g.us')) return participant;
  return participant || chatId(raw?.key?.remoteJidAlt || raw?.key?.remoteJid);
}

export function messageBody(message) {
  const body = unwrappedMessage(message);
  if (!body || body.protocolMessage || body.senderKeyDistributionMessage && Object.keys(body).length === 1) return null;
  if (typeof body.conversation === 'string') return body.conversation;
  if (typeof body.extendedTextMessage?.text === 'string') return body.extendedTextMessage.text;
  if (body.imageMessage) return body.imageMessage.caption || 'Imagem';
  if (body.videoMessage) return body.videoMessage.caption || 'Vídeo';
  if (body.audioMessage) return body.audioMessage.ptt ? 'Mensagem de voz' : 'Áudio';
  if (body.stickerMessage) return 'Figurinha';
  if (body.documentMessage) return body.documentMessage.fileName || 'Documento';
  if (body.contactMessage) return body.contactMessage.displayName || 'Contato';
  if (body.contactsArrayMessage) return 'Contatos';
  if (body.locationMessage || body.liveLocationMessage) return 'Localização';
  if (body.reactionMessage) return null;
  return 'Mensagem';
}

export function normalizedMessage(raw) {
  const id = chatId(raw?.key?.remoteJid);
  const text = messageBody(raw?.message);
  if (!id || !raw.key.id || text === null) return null;
  const value = raw.messageTimestamp;
  const timestamp = typeof value?.toNumber === 'function' ? value.toNumber() : Number(value);
  return {
    chat: id, id: String(raw.key.id), text: String(text),
    timestamp: Number.isFinite(timestamp) && timestamp > 0 ? timestamp : Math.floor(Date.now() / 1000),
    outgoing: raw.key.fromMe === true,
    sender: String(raw.pushName || chatId(raw.key.participant || raw.participant).split('@')[0] || ''),
    status: Number(raw.status || 0),
    raw,
  };
}
