/**
 * Parser de confirmaciones Huilo Huilo (mails de paz.galvez@huilohuilo.com).
 * Solo confirmaciones; modificaciones/cancelaciones van por WhatsApp.
 */

const MONTHS_ES = {
  enero: 1,
  febrero: 2,
  marzo: 3,
  abril: 4,
  mayo: 5,
  junio: 6,
  julio: 7,
  agosto: 8,
  septiembre: 9,
  setiembre: 9,
  octubre: 10,
  noviembre: 11,
  diciembre: 12,
};

function stripHtml(html) {
  return String(html || '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<\/tr>/gi, '\n')
    .replace(/<\/div>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/\r/g, '')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();
}

/** @returns {string|null} YYYY-MM-DD */
function parseHuiloDate(raw) {
  if (!raw) return null;
  const s = String(raw).trim().toLowerCase().replace(/\s+/g, ' ');

  // 04-noviembre-2026 | 4 noviembre 2026
  let m = s.match(/^(\d{1,2})[-\s/]+([a-záéíóú]+)[-\s/]+(\d{2,4})$/i);
  if (m) {
    const day = parseInt(m[1], 10);
    const monName = m[2].normalize('NFD').replace(/\p{M}/gu, '');
    const month = MONTHS_ES[monName];
    let year = parseInt(m[3], 10);
    if (!month || !day) return null;
    if (year < 100) year += 2000;
    return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  }

  // 06-11-26 | 06/11/2026
  m = s.match(/^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})$/);
  if (m) {
    const day = parseInt(m[1], 10);
    const month = parseInt(m[2], 10);
    let year = parseInt(m[3], 10);
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  }

  return null;
}

function parsePassengers(raw) {
  const t = String(raw || '').toLowerCase();
  const adultsM = t.match(/(\d+)\s*adulto/);
  const childM = t.match(/\+\s*0?(\d+)\s*niñ/);
  const adults = adultsM ? parseInt(adultsM[1], 10) : 1;
  const children = childM ? parseInt(childM[1], 10) : 0;
  return { adults, children };
}

function field(text, label) {
  const re = new RegExp(
    '(?:^|\\n)\\s*' + label + '\\s*[:：]\\s*(.+?)\\s*(?=\\n|$)',
    'im'
  );
  const m = text.match(re);
  return m ? m[1].replace(/\s+/g, ' ').trim() : null;
}

/**
 * @param {{ subject?: string, text?: string, html?: string, from?: string }} mail
 * @returns {null | {
 *   hotel_key: string,
 *   reservation_code: string,
 *   client_name: string,
 *   alojamiento: string|null,
 *   room_category: string|null,
 *   room_type: string|null,
 *   meal_plan: string|null,
 *   adults: number,
 *   children: number,
 *   check_in: string,
 *   check_out: string,
 *   total_amount: number,
 *   currency: string,
 *   notes: string
 * }}
 */
function parseHuiloConfirmation(mail) {
  const from = String(mail.from || '').toLowerCase();
  const subject = String(mail.subject || '');
  const text = mail.text || stripHtml(mail.html || '');

  const looksHuilo =
    from.includes('huilohuilo.com') ||
    /huilo/i.test(subject) ||
    /Confirmaci[oó]n de reserva/i.test(text) ||
    /N[uú]mero de confirmaci[oó]n/i.test(text);

  if (!looksHuilo) return null;
  if (!/confirmaci[oó]n/i.test(subject) && !/Confirmaci[oó]n de reserva/i.test(text)) {
    return null;
  }

  const code =
    field(text, 'N[uú]mero de confirmaci[oó]n') ||
    (text.match(/N[uú]mero de confirmaci[oó]n\s*[:：]?\s*(\d{6,})/i) || [])[1];
  const nombre = field(text, 'Nombre');
  if (!code || !nombre) return null;

  const pasajerosRaw = field(text, 'Pasajeros') || '';
  const { adults, children } = parsePassengers(pasajerosRaw);

  const fechasBlock = field(text, 'Fechas') || '';
  let checkIn =
    parseHuiloDate((fechasBlock.match(/\bIn\s*[:：]?\s*(.+?)(?=\s*Out\b|$)/i) || [])[1]) ||
    parseHuiloDate((text.match(/\bIn\s*[:：]\s*([^\n]+)/i) || [])[1]);
  let checkOut =
    parseHuiloDate((fechasBlock.match(/\bOut\s*[:：]?\s*(.+)$/i) || [])[1]) ||
    parseHuiloDate((text.match(/\bOut\s*[:：]\s*([^\n]+)/i) || [])[1]);

  const tarifaRaw =
    field(text, 'Tarifa final a pagar') ||
    (text.match(/Tarifa final a pagar\s*[:：]?\s*(.+)/i) || [])[1] ||
    '';
  const currency = /USD|US\$/i.test(tarifaRaw) ? 'USD' : /CLP|\$/i.test(tarifaRaw) ? 'CLP' : 'USD';
  const amountM = String(tarifaRaw).replace(/\./g, '').match(/([\d]+(?:[.,]\d{2})?)/);
  const total_amount = amountM ? parseFloat(amountM[1].replace(',', '.')) : 0;

  const alojamiento = field(text, 'Alojamiento');
  const room_category = field(text, 'Categor[ií]a de habitaci[oó]n');
  const room_type = field(text, 'Tipo de habitaci[oó]n');
  const meal_plan = field(text, 'Plan de alimentaci[oó]n');

  if (!checkIn || !checkOut) return null;

  const notesParts = [
    alojamiento && `Alojamiento: ${alojamiento}`,
    room_category && `Habitación: ${room_category}`,
    room_type && `Tipo: ${room_type}`,
    meal_plan && `Plan: ${meal_plan}`,
    pasajerosRaw && `Pasajeros: ${pasajerosRaw}`,
    `Moneda: ${currency}`,
    'Origen: email Huilo (IMAP)',
  ].filter(Boolean);

  return {
    hotel_key: 'huilo',
    reservation_code: String(code).trim(),
    client_name: nombre.trim(),
    alojamiento,
    room_category,
    room_type,
    meal_plan,
    adults,
    children,
    check_in: checkIn,
    check_out: checkOut,
    total_amount,
    currency,
    notes: notesParts.join(' | '),
  };
}

module.exports = {
  parseHuiloConfirmation,
  parseHuiloDate,
  stripHtml,
};
