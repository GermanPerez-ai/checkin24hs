/**
 * Parser de confirmaciones Corralco (mails a reservas@checkin24hs.com).
 */
const { parseHuiloDate, stripHtml } = require('./huilo-parse');

function field(text, label) {
  const re = new RegExp('(?:^|\\n)\\s*' + label + '\\s*[:：]\\s*(.+?)\\s*(?=\\n|$)', 'im');
  const m = String(text || '').match(re);
  return m ? m[1].replace(/\s+/g, ' ').trim() : null;
}

function looksCorralco(from, subject, text) {
  const blob = `${from} ${subject} ${text}`.toLowerCase();
  if (String(from || '').toLowerCase().includes('huilohuilo.com')) return false;
  if (/\bhuilo\b/i.test(subject || '') && !blob.includes('corralco')) return false;
  return blob.includes('corralco') || /rsva\.?\s*\d{6,8}|corralco\s*#\s*\d{6,8}/i.test(`${subject} ${text}`);
}

function extractCode(text, subject = '') {
  const blob = `${subject}\n${text}`;
  const fromSubject = [...String(subject || '').matchAll(/(?:#|Rsva\.?\s*)(\d{6,8})\b/gi)].map((m) => m[1]);
  if (fromSubject.length) return [...new Set(fromSubject)].join(' y ');
  const labeled =
    field(text, '(?:N[uú]mero de (?:reserva|confirmaci[oó]n)|Localizador|C[oó]digo(?: de reserva)?|Folio|Reserva\\s*N[°ºo]?)') ||
    (blob.match(/(?:N[uú]mero de (?:reserva|confirmaci[oó]n)|Localizador|C[oó]digo(?: de reserva)?|Folio|Reserva\s*N[°ºo]?)\s*[:：#]?\s*([A-Za-z0-9\-]{5,24})/i) || [])[1];
  if (labeled) {
    const nums = labeled.match(/\b\d{6,12}\b/g);
    if (nums && nums.length) return [...new Set(nums)].join(' y ');
    const token = labeled.replace(/[^A-Za-z0-9\-]/g, '');
    if (token.length >= 5) return token.toUpperCase();
  }
  const nums = [];
  for (const n of blob.match(/\b\d{6,12}\b/g) || []) {
    if (n.startsWith('54') && n.length >= 10) continue;
    if (/^202[4-9]$|^2030$/.test(n)) continue;
    nums.push(n);
  }
  if (nums.length) return [...new Set(nums)].join(' y ');
  const m = blob.match(/\b(?:COR|CRC)[- ]?\d{4,}\b/i);
  return m ? m[0].replace(/\s+/g, '').toUpperCase() : null;
}

function extractName(text, subject) {
  const nombre = field(text, '(?:Nombre|Hu[eé]sped|Titular|Pasajero|Cliente|Guest)');
  if (nombre && nombre.length >= 2 && nombre.length <= 80) {
    return nombre.replace(/^(Sr\.?|Sra\.?|Srta\.?)\s+/i, '').split(/\s{2,}|,/)[0].trim();
  }
  const s = String(subject || '').replace(/^(RE|RV|FW|Fwd)\s*:\s*/i, '').trim();
  const sr = s.match(/\b(Sr\.?|Sra\.?|Srta\.?)\s+(.+?)\s*[-–]\s*Rsva/i);
  if (sr) return sr[2].replace(/\s+/g, ' ').trim();
  return null;
}

function extractDates(text) {
  const fechas = field(text, 'Fechas') || '';
  let checkIn =
    parseHuiloDate((fechas.match(/\b(?:In|Check[\s-]?in|Ingreso|Llegada|Entrada)\s*[:：]?\s*(.+?)(?=\s*(?:Out|Check[\s-]?out|Salida|Egreso)\b|$)/i) || [])[1]) ||
    parseHuiloDate((text.match(/\b(?:Check[\s-]?in|Ingreso|Llegada|Entrada|In)\s*[:：]?\s*([^\n]+)/i) || [])[1]);
  let checkOut =
    parseHuiloDate((fechas.match(/\b(?:Out|Check[\s-]?out|Salida|Egreso)\s*[:：]?\s*(.+)$/i) || [])[1]) ||
    parseHuiloDate((text.match(/\b(?:Check[\s-]?out|Salida|Egreso|Out)\s*[:：]?\s*([^\n]+)/i) || [])[1]);
  if (!checkIn || !checkOut) {
    const m = text.match(
      /\b(?:del|desde)\s+(\d{1,2}[/\-.](?:\d{1,2}|[a-záéíóú]+)[/\.-]?\d{0,4})\s+(?:al|hasta|a)\s+(\d{1,2}[/\-.](?:\d{1,2}|[a-záéíóú]+)[/\.-]?\d{0,4})/i
    );
    if (m) {
      checkIn = checkIn || parseHuiloDate(m[1]);
      checkOut = checkOut || parseHuiloDate(m[2]);
    }
  }
  return { checkIn, checkOut };
}

function parseCorralcoConfirmation(mail) {
  const from = String(mail.from || '');
  const subject = String(mail.subject || '');
  const text = mail.text || stripHtml(mail.html || '');
  if (!looksCorralco(from, subject, text)) return null;
  if (!/confirmaci[oó]n|reserva|localizador|check[\s-]?in|ingreso|modific|anul/i.test(`${subject}\n${text}`)) {
    return null;
  }
  const code = extractCode(text, subject);
  let nombre = extractName(text, subject);
  if (!nombre && code) nombre = `Reserva Corralco ${String(code).split(' ')[0]}`;
  if (!code || !nombre) return null;
  const { checkIn, checkOut } = extractDates(text);
  if (!checkIn || !checkOut) return null;
  const tarifaRaw =
    field(text, '(?:Tarifa final a pagar|Tarifa|Total|Monto|Importe|Valor)') ||
    (text.match(/(?:Tarifa final a pagar|Tarifa|Total|Monto|Importe|Valor)\s*[:：]?\s*([^\n]+)/i) || [])[1] ||
    '';
  const currency = /USD|US\$/i.test(tarifaRaw) ? 'USD' : 'CLP';
  const amountM = String(tarifaRaw).replace(/\./g, '').match(/([\d]+(?:[.,]\d{2})?)/);
  const total_amount = amountM ? parseFloat(amountM[1].replace(',', '.')) : 0;
  return {
    hotel_key: 'corralco',
    reservation_code: String(code).trim(),
    client_name: nombre.trim(),
    check_in: checkIn,
    check_out: checkOut,
    total_amount,
    currency,
    notes: `Moneda: ${currency} | Origen: WhatsApp grupo Reservas Corralco Paz`,
  };
}

function extractCorralcoCodes(text) {
  const s = String(text || '');
  const found = [];
  const labeled = s.matchAll(
    /(?:localizador|n[uú]mero de (?:reserva|confirmaci[oó]n)|c[oó]digo(?: de reserva)?|folio|reserva)\s*[:#]?\s*([A-Z0-9\-]{5,20})/gi
  );
  for (const m of labeled) found.push(m[1].toUpperCase());
  for (const n of s.match(/(?:#|Rsva\.?\s*)(\d{6,8})\b/gi) || []) {
    const d = n.replace(/\D/g, '');
    if (d) found.push(d);
  }
  for (const n of s.match(/\b\d{6,12}\b/g) || []) {
    if (n.startsWith('54') && n.length >= 10) continue;
    if (/^202[4-9]$|^2030$/.test(n)) continue;
    found.push(n);
  }
  const crc = s.match(/\b(?:COR|CRC)[- ]?\d{4,}\b/gi) || [];
  for (const c of crc) found.push(c.replace(/\s+/g, '').toUpperCase());
  return [...new Set(found)];
}

module.exports = {
  parseCorralcoConfirmation,
  extractCorralcoCodes,
  looksCorralco,
};
