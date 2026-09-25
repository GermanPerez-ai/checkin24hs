'use strict';

const { supabaseSelect, supabaseInsert } = require('./collect');

const WA_API = (process.env.WHATSAPP_API_URL || 'https://whatsapp.checkin24hs.com').replace(/\/$/, '');
const TELEGRAM_BOT_TOKEN = String(process.env.TELEGRAM_BOT_TOKEN || '').trim();
const TELEGRAM_CHAT_ID = String(process.env.TELEGRAM_CHAT_ID || '').trim();
const WEBHOOK_URL = String(process.env.ANA_ALERT_WEBHOOK_URL || '').trim();

const DEFAULT_ALERT_PHONES = ['542944210725', '5492944579759'];

function digitsPhone(value) {
  return String(value || '')
    .replace(/^\+/, '')
    .replace(/\D/g, '');
}

function samePhone(a, b) {
  const x = digitsPhone(a);
  const y = digitsPhone(b);
  if (!x || !y || x.length < 8 || y.length < 8) return false;
  return x === y || x.endsWith(y.slice(-10)) || y.endsWith(x.slice(-10));
}

function parseAlertPhones() {
  const raw = String(process.env.ANA_ALERT_PHONE || process.env.MONITOR_ALERT_PHONE || '');
  const fromEnv = raw
    .split(/[,|;\s]+/)
    .map(digitsPhone)
    .filter((n) => n.length >= 10);
  const phones = [];
  for (const n of [...fromEnv, ...DEFAULT_ALERT_PHONES]) {
    if (!phones.some((p) => samePhone(p, n))) phones.push(n);
  }
  return phones;
}

const ALERT_PHONES = parseAlertPhones();
const ALERT_PHONE = ALERT_PHONES[0] || '';

async function alreadySent(kind, fingerprint) {
  const { ok, data } = await supabaseSelect(
    'ana_alerts_log',
    `select=id,sent_ok&kind=eq.${encodeURIComponent(kind)}&fingerprint=eq.${encodeURIComponent(fingerprint)}&limit=1`
  );
  if (!ok) return false;
  return Array.isArray(data) && data.some((r) => r.sent_ok);
}

async function postWhatsApp(path, payload) {
  const res = await fetch(`${WA_API}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const body = await res.text();
  if (!res.ok) return { ok: false, error: `WhatsApp ${res.status}: ${body.slice(0, 200)}` };
  return { ok: true };
}

async function sendWhatsApp(text) {
  if (!ALERT_PHONES.length) return { ok: false, error: 'Falta ANA_ALERT_PHONE' };
  const results = [];
  for (const number of ALERT_PHONES) {
    const r = await postWhatsApp('/api/send', { number, text }).catch((e) => ({
      ok: false,
      error: e.message,
    }));
    results.push({ number, ...r });
  }
  return { ok: results.some((r) => r.ok), results };
}

async function sendWhatsAppDocument({ fileName, mimetype, base64, caption }) {
  if (!ALERT_PHONES.length) return { ok: false, error: 'Falta ANA_ALERT_PHONE' };
  const payloadBase = {
    type: 'document',
    dataBase64: base64,
    mimetype: mimetype || 'application/pdf',
    fileName: fileName || 'informe.pdf',
    caption: String(caption || '').slice(0, 1024),
  };
  const results = [];
  for (const number of ALERT_PHONES) {
    const r = await postWhatsApp('/api/send-media', { ...payloadBase, number }).catch((e) => ({
      ok: false,
      error: e.message,
    }));
    results.push({ number, ...r });
  }
  return { ok: results.some((r) => r.ok), results };
}

async function sendTelegram(text) {
  if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) return { ok: false, skipped: true };
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ chat_id: TELEGRAM_CHAT_ID, text, disable_web_page_preview: true }),
  });
  if (!res.ok) return { ok: false, error: `Telegram ${res.status}` };
  return { ok: true };
}

async function sendWebhook(payload) {
  if (!WEBHOOK_URL) return { ok: false, skipped: true };
  const res = await fetch(WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!res.ok) return { ok: false, error: `Webhook ${res.status}` };
  return { ok: true };
}

async function dispatchAlert({ kind, fingerprint, text, payload = {} }) {
  if (await alreadySent(kind, fingerprint)) {
    return { ok: true, skipped: true, reason: 'ya enviada' };
  }
  const channels = [];
  const wa = await sendWhatsApp(text).catch((e) => ({ ok: false, error: e.message }));
  channels.push({ channel: 'whatsapp', ...wa });
  const tg = await sendTelegram(text).catch((e) => ({ ok: false, error: e.message }));
  if (!tg.skipped) channels.push({ channel: 'telegram', ...tg });
  const wh = await sendWebhook({ kind, fingerprint, text, ...payload }).catch((e) => ({
    ok: false,
    error: e.message,
  }));
  if (!wh.skipped) channels.push({ channel: 'webhook', ...wh });

  const sentOk = channels.some((c) => c.ok);
  const err = channels
    .filter((c) => !c.ok && c.error)
    .map((c) => `${c.channel}:${c.error}`)
    .join('; ');
  const ins = await supabaseInsert(
    'ana_alerts_log',
    {
      kind,
      fingerprint,
      channel: channels.map((c) => c.channel).join(','),
      payload: { ...payload, channels },
      sent_ok: sentOk,
      error: err || null,
    },
    { onConflict: 'kind,fingerprint' }
  );
  return { ok: sentOk || ins.ok, skipped: false, channels, log: ins };
}

module.exports = {
  dispatchAlert,
  sendWhatsApp,
  sendWhatsAppDocument,
  alreadySent,
  ALERT_PHONE,
  ALERT_PHONES,
};
