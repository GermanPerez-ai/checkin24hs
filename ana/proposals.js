'use strict';

const { supabaseSelect } = require('./collect');

function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function parseCommission(text) {
  const m = String(text || '').match(/(\d+(?:[.,]\d+)?)\s*%/);
  if (!m) return 15;
  return Number(String(m[1]).replace(',', '.')) || 15;
}

function parseHotelHint(text) {
  const raw = String(text || '');
  const m =
    raw.match(/para(?:\s+el)?\s+(.+?)(?:\s+con\s+una\s+comisi|\s+con\s+\d|\s*\.\s*$|$)/i) ||
    raw.match(/hotel\s+(.+?)(?:\s+con|\s+paquete|\s*\.|$)/i) ||
    raw.match(/paquete\s+hotel\s+(.+?)(?:\s*\.|$)/i);
  return (m ? m[1] : raw).replace(/["“”]/g, '').trim().slice(0, 120);
}

async function findHotel(hint) {
  const q = String(hint || '').trim();
  if (!q) return null;
  const { ok, data } = await supabaseSelect(
    'hotels',
    `select=id,name,location,description,price,status&name=ilike.*${encodeURIComponent(q)}*&limit=5`
  );
  if (ok && Array.isArray(data) && data.length) return data[0];
  const all = await supabaseSelect('hotels', 'select=id,name,location,description,price,status&limit=200');
  if (!all.ok || !Array.isArray(all.data)) return { name: q, location: '', description: '', price: null };
  const low = q.toLowerCase();
  return (
    all.data.find((h) => String(h.name || '').toLowerCase().includes(low)) || {
      name: q,
      location: '',
      description: '',
      price: null,
    }
  );
}

function proposalHtml({ hotel, commission, ymd }) {
  const name = hotel.name || 'Hotel';
  const loc = hotel.location || 'Argentina / Chile';
  const desc = hotel.description || 'Alojamiento representado por Checkin24hs.';
  const price = hotel.price != null ? `Desde ${hotel.price}` : 'Tarifas a convenir (netas, USD)';
  return `<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><title>Propuesta ${esc(name)} — Checkin24hs</title>
<style>
  body{font-family:Georgia,serif;color:#0f172a;max-width:720px;margin:40px auto;padding:0 24px;line-height:1.45}
  .brand{font-size:13px;letter-spacing:.2em;text-transform:uppercase;color:#0d9488}
  h1{font-size:26px;margin:8px 0 4px}
  .muted{color:#64748b;font-size:13px}
  table{width:100%;border-collapse:collapse;margin:18px 0}
  td,th{border:1px solid #cbd5e1;padding:8px 10px;font-size:14px;text-align:left}
  th{background:#f1f5f9}
  .ok{margin-top:28px;font-size:12px;color:#64748b}
</style></head><body>
  <div class="brand">Checkin24hs · Representación hotelera</div>
  <h1>Propuesta comercial de representación</h1>
  <p class="muted">${esc(ymd)} · Confidencial · Borrador para revisión (no es contrato firmado)</p>
  <h2>${esc(name)}</h2>
  <p>${esc(loc)}</p>
  <p>${esc(desc)}</p>
  <table>
    <tr><th>Concepto</th><th>Condición</th></tr>
    <tr><td>Comisión Checkin24hs</td><td><strong>${esc(commission)}%</strong> sobre tarifa neta en USD</td></tr>
    <tr><td>Moneda de venta</td><td>USD (reservas de hotel)</td></tr>
    <tr><td>Tarifa de referencia</td><td>${esc(price)}</td></tr>
    <tr><td>Vigencia sugerida</td><td>Temporada en curso + 12 meses, renovable</td></tr>
    <tr><td>Cancelación / no-show</td><td>Según política del hotel; el huésped se rige por el voucher Checkin24hs</td></tr>
    <tr><td>Plazo de pago</td><td>A convenir (estándar: 15 días de checkout o prepago)</td></tr>
    <tr><td>Canales</td><td>Web checkin24hs.com, WhatsApp Flor IA, mayoristas y B2B</td></tr>
  </table>
  <h3>Cláusulas modelo (revisar con asesoría legal)</h3>
  <ol>
    <li>Checkin24hs actúa como intermediario comercial, no como operador del inmueble.</li>
    <li>El hotel garantiza disponibilidad y tarifas netas informadas por escrito o extranet.</li>
    <li>Comisión del ${esc(commission)}% sobre el importe neto de estadía confirmada, excluyendo extras in-house salvo pacto.</li>
    <li>Cualquiera de las partes puede rescindir con 30 días de preaviso por escrito, respetando reservas ya confirmadas.</li>
    <li>Material de marca: el hotel autoriza fotos y textos para web, tarjetas digitales y WhatsApp.</li>
  </ol>
  <p>Atentamente,<br><strong>Checkin24hs</strong><br>www.checkin24hs.com</p>
  <p class="ok">Generado por ANA. Imprimir a PDF desde el navegador si hace falta firma.</p>
</body></html>`;
}

function promoPack({ hotel, place, ymd }) {
  const name = hotel.name || 'Hotel';
  const loc = hotel.location || '';
  const wa = 'https://wa.me/5492944200748';
  const json = {
    type: 'promo_pack',
    ymd,
    destino: place || loc,
    hotel: name,
    headline: `${place || loc}: ${name} con Checkin24hs`,
    bullets: [
      `Alojamiento: ${name}`,
      loc ? `Ubicación: ${loc}` : null,
      'Asesoría y reserva por WhatsApp (Flor IA + equipo)',
      'Tarifas netas en USD · intermediación Checkin24hs',
    ].filter(Boolean),
    cta: { label: 'Consultar disponibilidad', whatsapp: wa, web: 'https://www.checkin24hs.com' },
  };
  const html = `<section class="pack">
  <h2>${esc(json.headline)}</h2>
  <ul>${json.bullets.map((b) => `<li>${esc(b)}</li>`).join('')}</ul>
  <p><a href="${esc(wa)}">WhatsApp</a> · <a href="https://www.checkin24hs.com">checkin24hs.com</a></p>
</section>`;
  const waText = `*${json.headline}*\n${json.bullets.map((b) => `• ${b}`).join('\n')}\n\nConsultas: ${wa}`;
  return { json, html, waText };
}

async function buildProposalFromPrompt(text, ymd) {
  const commission = parseCommission(text);
  const hint = parseHotelHint(text);
  const hotel = await findHotel(hint);
  const html = proposalHtml({ hotel, commission, ymd });
  const summary = [
    `**Propuesta B2B** para **${hotel.name}** (borrador, no contrato firmado).`,
    `Comisión: **${commission}%** sobre tarifa neta USD.`,
    hotel.location ? `Ubicación: ${hotel.location}` : null,
    `Descargá el HTML con membrete o imprimilo a PDF.`,
  ]
    .filter(Boolean)
    .join('\n');
  return { kind: 'proposal', hotel, commission, html, summary };
}

async function buildPromoFromPrompt(text, ymd) {
  const placeMatch = String(text || '').match(/paso\s+[^,+]+|cardenal\s+samor[eé]|libertadores|huemules/i);
  const place = placeMatch ? placeMatch[0] : 'Destino Checkin24hs';
  const hint = parseHotelHint(text);
  const hotel = await findHotel(hint);
  const pack = promoPack({ hotel, place, ymd });
  const summary = [
    `**Pack promocional** ${place} + **${hotel.name}**.`,
    pack.waText,
    `También hay bloque HTML/JSON para web o vCard.`,
  ].join('\n\n');
  return { kind: 'promo', hotel, place, html: pack.html, json: pack.json, waText: pack.waText, summary };
}

module.exports = {
  parseCommission,
  buildProposalFromPrompt,
  buildPromoFromPrompt,
};
