'use strict';

const { PDFDocument, StandardFonts, rgb } = require('pdf-lib');
const { arYmd, addYmd, arDayBounds, toArYmd, supabaseSelect } = require('./collect');

const ASK =
  /(tarif|precio|valor(?:es)?|cotiz|cu[aá]nto\s+(sale|cuesta|saldr[ií]a)|presupuesto|m[aá]s econ[oó]mico|cuanto\s+(sale|cuesta)|pasame (el )?precio|me pas[aá]s?.*(precio|tarifa|valor))/i;
const HAS_PRICE =
  /USD\s*\d|\d+\s*USD|US\$\s*\d|\$\s*\d{2,}|\d{2,}\s*(d[oó]lares|usd)|la tarifa es|tarifa (es|desde) de/i;
const COTIZAR = /cotizar\.checkin24hs/i;
const ALERT_PHONE = /2944210725|2944200748|2944579759/;
const VENDOR_PERSIST_FROM = '2026-09-24';
const PAGE = 1000;
const MAX_ROWS = 20000;

let lastReport = null;
let inflight = null;

function looksLikeSalesControl(text) {
  const t = String(text || '').toLowerCase();
  return /informe (semanal|comercial)|control (comercial|vendedores)|pdf (semanal|comercial|vendedores)|qui[eé]n (pidi[oó]|cerr[oó]).{0,40}(precio|tarifa)|control comercial whatsapp/.test(
    t
  );
}

function msgText(m) {
  return String(m?.message || m?.body || '').replace(/\s+/g, ' ').trim();
}

function roleOf(m) {
  if (m.is_from_flor) return 'flor';
  if (m.is_from_me) return 'vendor';
  return 'client';
}

function hoursBetween(fromIso, toIso) {
  const a = new Date(fromIso).getTime();
  const b = new Date(toIso).getTime();
  if (!Number.isFinite(a) || !Number.isFinite(b) || b < a) return null;
  return Math.round((b - a) / 3600000);
}

function minutesBetween(fromIso, toIso) {
  const a = new Date(fromIso).getTime();
  const b = new Date(toIso).getTime();
  if (!Number.isFinite(a) || !Number.isFinite(b) || b < a) return null;
  return Math.round((b - a) / 60000);
}

function periodBounds() {
  const toYmd = arYmd();
  const fromYmd = addYmd(toYmd, -6);
  const { from } = arDayBounds(fromYmd);
  return { fromYmd, toYmd, fromIso: from, toIso: new Date().toISOString() };
}

async function fetchMessages(fromIso, toIso) {
  const select =
    'id,phone,chat_id,message,body,is_from_me,is_from_flor,sent_at,created_at,sender,whatsapp_instance';
  const all = [];
  let offset = 0;
  while (offset < MAX_ROWS) {
    const q = [
      `select=${select}`,
      `sent_at=gte.${encodeURIComponent(fromIso)}`,
      `sent_at=lt.${encodeURIComponent(toIso)}`,
      'order=sent_at.asc',
      `limit=${PAGE}`,
      `offset=${offset}`,
    ].join('&');
    const { ok, status, data } = await supabaseSelect('whatsapp_messages', q);
    if (!ok) throw new Error(`whatsapp_messages ${status}`);
    const rows = Array.isArray(data) ? data : [];
    all.push(...rows);
    if (rows.length < PAGE) break;
    offset += PAGE;
  }
  return all;
}

function analyze(rows, nowIso) {
  const byPhone = new Map();
  const daily = {};
  const ensureDay = (ymd) => {
    if (!daily[ymd]) {
      daily[ymd] = {
        ymd,
        client: 0,
        flor: 0,
        vendor: 0,
        asked: 0,
        pricedFlor: 0,
        pricedVendor: 0,
      };
    }
    return daily[ymd];
  };

  for (const m of rows) {
    const phone = String(m.phone || '').replace(/\D/g, '');
    if (!phone || ALERT_PHONE.test(phone)) continue;
    const when = m.sent_at || m.created_at;
    const ymd = toArYmd(when);
    const role = roleOf(m);
    const text = msgText(m);
    const day = ymd ? ensureDay(ymd) : null;
    if (day) day[role] += 1;

    let rec = byPhone.get(phone);
    if (!rec) {
      rec = {
        phone,
        askedAt: null,
        askedText: '',
        pricedAt: null,
        pricedBy: null,
        pricedText: '',
        vendorMsgs: 0,
        florMsgs: 0,
        clientMsgs: 0,
        vendorName: '',
      };
      byPhone.set(phone, rec);
    }
    if (role === 'vendor') {
      rec.vendorMsgs += 1;
      if (!rec.vendorName && m.sender) rec.vendorName = String(m.sender).slice(0, 40);
    } else if (role === 'flor') rec.florMsgs += 1;
    else rec.clientMsgs += 1;

    if (role === 'client' && ASK.test(text) && !rec.askedAt) {
      rec.askedAt = when;
      rec.askedText = text.slice(0, 140);
      if (day) day.asked += 1;
    }
    const closes = (HAS_PRICE.test(text) || COTIZAR.test(text)) && (role === 'flor' || role === 'vendor');
    if (closes && rec.askedAt && !rec.pricedAt) {
      rec.pricedAt = when;
      rec.pricedBy = role;
      rec.pricedText = text.slice(0, 140);
      if (day) {
        if (role === 'flor') day.pricedFlor += 1;
        else day.pricedVendor += 1;
      }
    }
  }

  const cases = [...byPhone.values()].filter((c) => c.askedAt);
  const priced = cases.filter((c) => c.pricedAt);
  const open = cases
    .filter((c) => !c.pricedAt)
    .map((c) => ({ ...c, waitH: hoursBetween(c.askedAt, nowIso) }))
    .sort((a, b) => (b.waitH || 0) - (a.waitH || 0));
  const pricedList = priced
    .map((c) => ({ ...c, waitMin: minutesBetween(c.askedAt, c.pricedAt) }))
    .sort((a, b) => (b.waitMin || 0) - (a.waitMin || 0));

  const kpis = {
    messages: rows.length,
    contacts: byPhone.size,
    asked: cases.length,
    priced: priced.length,
    pricedFlor: priced.filter((c) => c.pricedBy === 'flor').length,
    pricedVendor: priced.filter((c) => c.pricedBy === 'vendor').length,
    open: open.length,
    openOver2h: open.filter((c) => (c.waitH || 0) >= 2).length,
    vendorMsgs: [...byPhone.values()].reduce((n, c) => n + c.vendorMsgs, 0),
    vendorContacts: [...byPhone.values()].filter((c) => c.vendorMsgs > 0).length,
  };

  const days = Object.keys(daily)
    .sort()
    .map((k) => daily[k]);

  return { kpis, days, open, pricedList, cases };
}

function pdfSafe(s) {
  return String(s || '')
    .replace(/[–—]/g, '-')
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/•/g, '-')
    .replace(/[^\x20-\x7E\u00A0-\u00FF]/g, ' ');
}

function wrapLine(font, text, size, maxWidth) {
  const words = pdfSafe(text).split(/\s+/).filter(Boolean);
  const lines = [];
  let cur = '';
  for (const w of words) {
    const trial = cur ? `${cur} ${w}` : w;
    if (font.widthOfTextAtSize(trial, size) > maxWidth && cur) {
      lines.push(cur);
      cur = w;
    } else cur = trial;
  }
  if (cur) lines.push(cur);
  return lines.length ? lines : [''];
}

async function buildPdf({ fromYmd, toYmd, kpis, days, open, pricedList }) {
  const doc = await PDFDocument.create();
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const ink = rgb(0.12, 0.14, 0.18);
  const muted = rgb(0.4, 0.43, 0.48);
  const line = rgb(0.85, 0.87, 0.9);
  const accent = rgb(0.07, 0.45, 0.48);
  const W = 595;
  const H = 842;
  const M = 42;
  let page = doc.addPage([W, H]);
  let y = H - 46;

  const newPage = () => {
    page = doc.addPage([W, H]);
    y = H - 46;
  };
  const need = (h) => {
    if (y - h < 48) newPage();
  };
  const text = (str, x, yy, size, f, color) => {
    page.drawText(pdfSafe(str), { x, y: yy, size, font: f || font, color: color || ink });
  };

  text('Checkin24hs  ·  ANA', M, y, 9, font, muted);
  y -= 18;
  text('Control comercial WhatsApp', M, y, 18, bold, ink);
  y -= 16;
  text(`Periodo ${fromYmd} a ${toYmd} (7 dias, hora Argentina)`, M, y, 10, font, muted);
  y -= 14;
  text(`Generado ${new Date().toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' })}`, M, y, 9, font, muted);
  y -= 22;
  page.drawLine({ start: { x: M, y }, end: { x: W - M, y }, thickness: 1, color: accent });
  y -= 22;

  const cards = [
    ['Pidieron tarifa', String(kpis.asked)],
    ['Cerraron precio', String(kpis.priced)],
    ['Cierre Flor', String(kpis.pricedFlor)],
    ['Cierre vendedor', String(kpis.pricedVendor)],
    ['Sin precio', String(kpis.open)],
    ['Sin precio >2 h', String(kpis.openOver2h)],
    ['Msgs vendedor', String(kpis.vendorMsgs)],
    ['Chats con vendedor', String(kpis.vendorContacts)],
  ];
  const cardW = 118;
  const cardH = 44;
  cards.forEach((c, i) => {
    const col = i % 4;
    const row = Math.floor(i / 4);
    const x = M + col * (cardW + 10);
    const cy = y - row * (cardH + 10);
    page.drawRectangle({
      x,
      y: cy - cardH,
      width: cardW,
      height: cardH,
      borderColor: line,
      borderWidth: 0.8,
      color: rgb(0.97, 0.98, 0.99),
    });
    text(c[0], x + 8, cy - 16, 8, font, muted);
    text(c[1], x + 8, cy - 34, 16, bold, ink);
  });
  y -= 2 * (cardH + 10) + 8;

  need(70);
  text('Como se lee', M, y, 12, bold, ink);
  y -= 16;
  const notes = [
    'Pedido de tarifa = mensaje del cliente que pide precio / cotizacion / valor.',
    'Cierre de precio = primer mensaje de Flor o vendedor con USD / tarifa / link cotizar.checkin24hs luego del pedido.',
    'Vendedor = mensaje saliente humano del celular (is_from_me, no Flor). Flor no cuenta como vendedor.',
    `Los mensajes del vendedor en el celular se registran desde ${VENDOR_PERSIST_FROM}. Dias anteriores pueden subcontar cierre humano.`,
    'No incluye los numeros internos de alerta de ANA.',
  ];
  for (const n of notes) {
    const lines = wrapLine(font, n, 9, W - M * 2);
    need(lines.length * 12 + 4);
    for (const ln of lines) {
      text(ln, M, y, 9, font, ink);
      y -= 12;
    }
    y -= 2;
  }

  y -= 8;
  need(40);
  text('Actividad por dia', M, y, 12, bold, ink);
  y -= 18;
  const cols = [
    { k: 'ymd', h: 'Fecha', w: 70 },
    { k: 'client', h: 'Cliente', w: 54 },
    { k: 'flor', h: 'Flor', w: 44 },
    { k: 'vendor', h: 'Vendedor', w: 58 },
    { k: 'asked', h: 'Pidieron', w: 54 },
    { k: 'pricedFlor', h: 'Cierre Flor', w: 70 },
    { k: 'pricedVendor', h: 'Cierre vend.', w: 70 },
  ];
  const drawHeader = () => {
    let x = M;
    for (const c of cols) {
      text(c.h, x, y, 8, bold, muted);
      x += c.w;
    }
    y -= 6;
    page.drawLine({ start: { x: M, y }, end: { x: W - M, y }, thickness: 0.6, color: line });
    y -= 12;
  };
  drawHeader();
  for (const d of days) {
    need(16);
    let x = M;
    for (const c of cols) {
      text(String(d[c.k] ?? ''), x, y, 9, font, ink);
      x += c.w;
    }
    y -= 14;
  }

  y -= 10;
  need(36);
  text('Sin precio (los que mas esperan)', M, y, 12, bold, ink);
  y -= 16;
  if (!open.length) {
    text('Nadie pidio tarifa sin recibir precio en este periodo.', M, y, 9, font, muted);
    y -= 14;
  } else {
    for (const c of open.slice(0, 28)) {
      const title = `${c.phone}  ·  ${c.waitH != null ? c.waitH + ' h' : 'n/d'}  ·  pidio ${toArYmd(c.askedAt)}`;
      const snip = c.askedText || '';
      const snipLines = wrapLine(font, snip, 8, W - M * 2);
      need(16 + snipLines.length * 11);
      text(title, M, y, 9, bold, ink);
      y -= 12;
      for (const ln of snipLines.slice(0, 2)) {
        text(ln, M, y, 8, font, muted);
        y -= 11;
      }
      y -= 4;
    }
  }

  y -= 8;
  need(36);
  text('Cierres de precio (Flor vs vendedor)', M, y, 12, bold, ink);
  y -= 16;
  if (!pricedList.length) {
    text('No hubo cierre de precio detectable en el periodo.', M, y, 9, font, muted);
    y -= 14;
  } else {
    for (const c of pricedList.slice(0, 24)) {
      const who = c.pricedBy === 'vendor' ? `vendedor${c.vendorName ? ' ' + c.vendorName : ''}` : 'Flor';
      const title = `${c.phone}  ·  ${who}  ·  ${c.waitMin != null ? c.waitMin + ' min' : 'n/d'}`;
      need(26);
      text(title, M, y, 9, bold, ink);
      y -= 12;
      const snip = wrapLine(font, c.pricedText || '', 8, W - M * 2);
      for (const ln of snip.slice(0, 2)) {
        text(ln, M, y, 8, font, muted);
        y -= 11;
      }
      y -= 4;
    }
  }

  y -= 10;
  need(40);
  text('Accion', M, y, 12, bold, ink);
  y -= 16;
  const actions = [
    kpis.openOver2h
      ? `Hay ${kpis.openOver2h} pedidos de tarifa sin precio hace mas de 2 h: ventas tiene que responder o Flor tiene que cotizar.`
      : 'No hay pedidos de tarifa viejos sin precio en esta muestra.',
    kpis.pricedVendor === 0 && kpis.vendorMsgs === 0
      ? 'Cero mensajes de vendedor en el recorte: o no hablaron, o el celular no estaba persistiendo (antes del 24/09).'
      : `Vendedor interviene en ${kpis.vendorContacts} chats (${kpis.vendorMsgs} msgs) y cerro ${kpis.pricedVendor} precios.`,
    'Este PDF lo genera ANA sola los lunes 10:00 ART y lo manda por WhatsApp al numero de alerta.',
  ];
  for (const a of actions) {
    const lines = wrapLine(font, a, 9, W - M * 2);
    need(lines.length * 12 + 4);
    for (const ln of lines) {
      text(ln, M, y, 9, font, ink);
      y -= 12;
    }
    y -= 4;
  }

  return Buffer.from(await doc.save());
}

function summaryLines(fromYmd, toYmd, kpis) {
  return [
    `Informe comercial WhatsApp ${fromYmd} → ${toYmd}`,
    `Pidieron tarifa: ${kpis.asked}`,
    `Cerraron precio: ${kpis.priced} (Flor ${kpis.pricedFlor} / vendedor ${kpis.pricedVendor})`,
    `Siguen sin precio: ${kpis.open} (${kpis.openOver2h} con más de 2 h)`,
    `Mensajes de vendedor: ${kpis.vendorMsgs} en ${kpis.vendorContacts} chats`,
  ];
}

async function buildReport() {
  const { fromYmd, toYmd, fromIso, toIso } = periodBounds();
  const rows = await fetchMessages(fromIso, toIso);
  const { kpis, days, open, pricedList } = analyze(rows, toIso);
  const filename = `Control-comercial-WhatsApp-${toYmd}.pdf`;
  const pdfBuffer = await buildPdf({ fromYmd, toYmd, kpis, days, open, pricedList });
  const lines = summaryLines(fromYmd, toYmd, kpis);
  lastReport = {
    at: new Date().toISOString(),
    from: fromYmd,
    to: toYmd,
    filename,
    pdfBuffer,
    kpis,
    openPreview: open.slice(0, 8).map((c) => ({
      phone: c.phone,
      waitH: c.waitH,
      askedAt: c.askedAt,
    })),
    summaryText: lines.join('\n'),
    whatsappText: [`📊 *ANA · Control comercial*`, ...lines.slice(1), `PDF adjunto.`].join('\n'),
  };
  return lastReport;
}

async function generateSalesControlReport() {
  if (inflight) return inflight;
  inflight = buildReport().finally(() => {
    inflight = null;
  });
  return inflight;
}

function getLastSalesControl() {
  return lastReport;
}

module.exports = {
  looksLikeSalesControl,
  generateSalesControlReport,
  getLastSalesControl,
};
