'use strict';

function digits(value) {
  return String(value || '').replace(/\D/g, '');
}

function samePhone(a, b) {
  const x = digits(a);
  const y = digits(b);
  if (!x || !y || x.length < 8 || y.length < 8) return false;
  return x === y || x.endsWith(y.slice(-10)) || y.endsWith(x.slice(-10));
}

/**
 * Si el mensaje viene del teléfono ejecutivo (ANA_ALERT_PHONE), lo manda a ANA Copiloto
 * y Flor no responde. Si falta env o no coincide el número, no hace nada.
 */
async function tryAnaCopilotInbound({ phones, text }) {
  const secret = String(process.env.ANA_JOBS_SECRET || '').trim();
  const exec = digits(process.env.ANA_ALERT_PHONE || process.env.MONITOR_ALERT_PHONE || '');
  const raw = String(text || '').trim();
  if (!secret || !exec || !raw || raw === '[Audio]' || raw.startsWith('[Imagen]')) return false;
  const list = (phones || []).filter(Boolean);
  if (!list.some((p) => samePhone(p, exec))) return false;
  const base = String(process.env.ANA_COPILOT_URL || 'https://ana.checkin24hs.com').replace(/\/$/, '');
  const res = await fetch(`${base}/api/copilot/inbound`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Ana-Jobs-Secret': secret,
    },
    body: JSON.stringify({ text: raw, source: 'whatsapp' }),
    signal: AbortSignal.timeout(25000),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    console.warn('ANA copiloto inbound HTTP', res.status, body.slice(0, 180));
    return false;
  }
  console.log('📌 ANA copiloto inbound OK');
  return true;
}

module.exports = { tryAnaCopilotInbound };
