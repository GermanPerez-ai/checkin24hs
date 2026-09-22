'use strict';

const { ImapFlow } = require('imapflow');

const IMAP_HOST = String(process.env.IMAP_HOST || 'mail.checkin24hs.com').trim();
const IMAP_PORT = parseInt(process.env.IMAP_PORT || '993', 10) || 993;
const IMAP_SECURE = process.env.IMAP_SECURE !== '0' && process.env.IMAP_SECURE !== 'false';
const IMAP_USER = String(process.env.IMAP_USER || 'reservas').trim();
const IMAP_PASS = String(process.env.IMAP_PASS || '').trim();
const IMAP_MAILBOX = String(process.env.IMAP_MAILBOX || 'INBOX').trim();
const IMAP_TIMEOUT_MS = Math.max(4000, parseInt(process.env.IMAP_TIMEOUT_MS || '20000', 10) || 20000);

const URGENT_FROM =
  /ratehawk|juniper|siteminder|travelgate|hotelbeds|huilo|corralco|puyehue|enjoy|mayorista|canopy|booking\.com|expedia/i;
const URGENT_SUBJ =
  /reserva|tarifa|convenio|cancel|modific|urgente|contrato|comisi[oó]n|overbooking|disponib|no.?show|voucher/i;

function withTimeout(promise, ms, label) {
  let t;
  const timeout = new Promise((_, reject) => {
    t = setTimeout(() => reject(new Error(`${label || 'IMAP'} timeout ${ms}ms`)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(t));
}

function addrList(list) {
  if (!Array.isArray(list) || !list.length) return '';
  return list
    .map((a) => {
      const email = `${a.mailbox || ''}@${a.host || ''}`.replace(/^@|@$/g, '');
      const name = a.name || '';
      return name ? `${name} <${email}>` : email;
    })
    .filter(Boolean)
    .join(', ');
}

function priorityOf(from, subject, unseen) {
  const blob = `${from} ${subject}`;
  if (URGENT_FROM.test(blob) || URGENT_SUBJ.test(subject || '')) return 'urgent';
  if (unseen) return 'unread';
  return 'normal';
}

function decodeQuotedPrintable(s) {
  return String(s || '')
    .replace(/=\r?\n/g, '')
    .replace(/=([0-9A-Fa-f]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16)));
}

function stripMailText(raw) {
  let s = Buffer.isBuffer(raw) ? raw.toString('utf8') : String(raw || '');
  const sep = s.search(/\r?\n\r?\n/);
  if (sep >= 0 && /^(From|Return-Path|Received|MIME-Version|Content-Type|Delivered-To):/im.test(s.slice(0, 500))) {
    s = s.slice(sep + 2);
  }
  s = decodeQuotedPrintable(s);
  s = s.replace(/<style[\s\S]*?<\/style>/gi, ' ').replace(/<script[\s\S]*?<\/script>/gi, ' ');
  s = s.replace(/<br\s*\/?>/gi, ' ').replace(/<\/p>/gi, ' ').replace(/<[^>]+>/g, ' ');
  s = s.replace(/&nbsp;/gi, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
  s = s.replace(/^[>].*$/gm, '');
  s = s.replace(/^\s*On .+wrote:\s*$/gim, '');
  s = s.replace(/\s+/g, ' ').trim();
  return s;
}

function summarize(raw) {
  const t = stripMailText(raw);
  if (!t) return { preview: '', summary: '' };
  const preview = t.slice(0, 500);
  const parts = t
    .split(/(?<=[.!?])\s+/)
    .map((x) => x.trim())
    .filter((x) => x.length > 35 && !/unsubscribe|view in browser|click here|abrir en el navegador|no.?reply/i.test(x));
  let summary = (parts[0] || t).slice(0, 240);
  if ((parts[0] || t).length > 240) summary += '…';
  return { preview, summary };
}

async function openClient() {
  if (!IMAP_PASS) {
    throw new Error('Falta IMAP_PASS (la misma de reservas@ / scripts/email-reservations/.env)');
  }
  const client = new ImapFlow({
    host: IMAP_HOST,
    port: IMAP_PORT,
    secure: IMAP_SECURE,
    auth: { user: IMAP_USER, pass: IMAP_PASS },
    logger: false,
    tls: { rejectUnauthorized: process.env.IMAP_TLS_REJECT_UNAUTHORIZED !== '0' },
  });
  await client.connect();
  return client;
}

async function fetchInbox(limit = 30) {
  const max = Math.min(40, Math.max(5, Number(limit) || 30));
  if (!IMAP_PASS) {
    return {
      connected: false,
      mailbox: `${IMAP_USER}@ (IMAP)`,
      reason: 'Falta IMAP_PASS en el servicio ANA. Copiar la de scripts/email-reservations/.env',
      unseen: 0,
      urgent: 0,
      messages: [],
    };
  }

  let client;
  try {
    client = await withTimeout(openClient(), IMAP_TIMEOUT_MS, 'IMAP connect');
    const lock = await client.getMailboxLock(IMAP_MAILBOX);
    try {
      const total = Number(client.mailbox.exists || 0);
      const status = await client.status(IMAP_MAILBOX, { unseen: true, messages: true });
      const unseen = Number(status.unseen || 0);
      const fromSeq = Math.max(1, total - max + 1);
      const range = total ? `${fromSeq}:*` : '1:0';
      const messages = [];
      if (total) {
        for await (const msg of client.fetch(range, {
          envelope: true,
          flags: true,
          uid: true,
          source: { maxLength: 12000 },
        })) {
          const env = msg.envelope || {};
          const from = addrList(env.from);
          const subject = String(env.subject || '(sin asunto)');
          const flags = msg.flags || new Set();
          const isUnseen = !(flags.has('\\Seen') || flags.has('Seen'));
          const { preview, summary } = summarize(msg.source);
          messages.push({
            uid: msg.uid,
            from,
            to: addrList(env.to),
            subject,
            date: env.date ? new Date(env.date).toISOString() : null,
            unseen: isUnseen,
            priority: priorityOf(from, subject, isUnseen),
            summary,
            preview,
          });
        }
      }
      messages.sort((a, b) => String(b.date || '').localeCompare(String(a.date || '')));
      const urgent = messages.filter((m) => m.priority === 'urgent').length;
      return {
        connected: true,
        host: IMAP_HOST,
        user: IMAP_USER,
        mailbox: IMAP_MAILBOX,
        total,
        unseen,
        urgent,
        messages: messages.slice(0, max),
      };
    } finally {
      lock.release();
    }
  } catch (e) {
    return {
      connected: false,
      mailbox: IMAP_USER,
      host: IMAP_HOST,
      reason: e.message || String(e),
      unseen: 0,
      urgent: 0,
      messages: [],
    };
  } finally {
    if (client) {
      try {
        await client.logout();
      } catch {
        /* ignore */
      }
    }
  }
}

async function fetchBody(uid) {
  const id = parseInt(uid, 10);
  if (!Number.isFinite(id) || id < 1) throw new Error('uid inválido');
  const client = await withTimeout(openClient(), IMAP_TIMEOUT_MS, 'IMAP connect');
  try {
    const lock = await client.getMailboxLock(IMAP_MAILBOX);
    try {
      let found = null;
      for await (const msg of client.fetch({ uid: String(id) }, { envelope: true, source: true, uid: true })) {
        const env = msg.envelope || {};
        const raw = msg.source
          ? Buffer.isBuffer(msg.source)
            ? msg.source.toString('utf8')
            : String(msg.source)
          : '';
        const text = stripMailText(raw).slice(0, 4000);
        found = {
          uid: msg.uid,
          from: addrList(env.from),
          subject: String(env.subject || ''),
          date: env.date ? new Date(env.date).toISOString() : null,
          text,
        };
      }
      if (!found) throw new Error('Mail no encontrado');
      return found;
    } finally {
      lock.release();
    }
  } finally {
    try {
      await client.logout();
    } catch {
      /* ignore */
    }
  }
}

module.exports = { fetchInbox, fetchBody };
