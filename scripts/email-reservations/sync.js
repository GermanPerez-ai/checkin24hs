#!/usr/bin/env node
/**
 * Sync IMAP reservas@checkin24hs.com → Supabase (confirmaciones Huilo Huilo).
 *
 * Uso:
 *   node sync.js              # importa
 *   node sync.js --dry-run    # solo muestra qué parsearía
 *   node sync.js --since-days 30
 *
 * Variables (no subir secretos al repo):
 *   IMAP_HOST=mail.checkin24hs.com
 *   IMAP_PORT=993
 *   IMAP_USER=reservas@checkin24hs.com
 *   IMAP_PASS=***
 *   IMAP_TLS_REJECT_UNAUTHORIZED=0   # si el cert del mail es autofirmado
 *   SUPABASE_URL=https://xxxx.supabase.co
 *   SUPABASE_SERVICE_ROLE_KEY=...    # preferido
 *   # o SUPABASE_ANON_KEY=...
 *   EMAIL_SYNC_MAILBOX=INBOX
 *   EMAIL_SYNC_HUIL_FROM=*@huilohuilo.com
 */

const fs = require('fs');
const path = require('path');

try {
  require('dotenv').config({ path: path.join(__dirname, '.env') });
  require('dotenv').config({ path: path.join(__dirname, '../../.env') });
} catch (_) {
  /* dotenv opcional */
}

const { ImapFlow } = require('imapflow');
const { simpleParser } = require('mailparser');
const { parseHuiloConfirmation } = require('./parse-huilo');

const args = new Set(process.argv.slice(2));
const DRY_RUN = args.has('--dry-run');
const sinceArg = process.argv.find((a) => a.startsWith('--since-days='));
const SINCE_DAYS = Math.max(
  1,
  parseInt(sinceArg ? sinceArg.split('=')[1] : process.env.EMAIL_SYNC_SINCE_DAYS || '60', 10) || 60
);

const IMAP_HOST = (process.env.IMAP_HOST || 'mail.checkin24hs.com').trim();
const IMAP_PORT = parseInt(process.env.IMAP_PORT || '993', 10) || 993;
const IMAP_USER = (process.env.IMAP_USER || 'reservas@checkin24hs.com').trim();
const IMAP_PASS = (process.env.IMAP_PASS || '').trim();
const IMAP_LOGIN_METHOD = (process.env.IMAP_LOGIN_METHOD || 'LOGIN').trim();
const IMAP_SECURE =
  process.env.IMAP_SECURE === '1' ||
  process.env.IMAP_SECURE === 'true' ||
  (process.env.IMAP_SECURE !== '0' && IMAP_PORT === 993);
const IMAP_TLS_REJECT =
  process.env.IMAP_TLS_REJECT_UNAUTHORIZED === '1' ||
  process.env.IMAP_TLS_REJECT_UNAUTHORIZED === 'true';
const MAILBOX = process.env.EMAIL_SYNC_MAILBOX || 'INBOX';

const SUPABASE_URL = (process.env.SUPABASE_URL || '').replace(/\/$/, '');
const SUPABASE_KEY =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  '';

function mustEnv() {
  const missing = [];
  if (!IMAP_PASS) missing.push('IMAP_PASS');
  if (!SUPABASE_URL) missing.push('SUPABASE_URL');
  if (!SUPABASE_KEY) missing.push('SUPABASE_SERVICE_ROLE_KEY o SUPABASE_ANON_KEY');
  if (missing.length) {
    console.error('❌ Faltan variables:', missing.join(', '));
    console.error('   Creá scripts/email-reservations/.env (ver .env.example)');
    process.exit(1);
  }
}

async function sb(method, pathRest, body) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${pathRest}`, {
    method,
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: method === 'POST' ? 'return=representation,resolution=merge-duplicates' : 'return=representation',
    },
    body: body != null ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!res.ok) {
    const err = new Error(`Supabase ${res.status}: ${typeof data === 'string' ? data : JSON.stringify(data)}`);
    err.status = res.status;
    err.data = data;
    throw err;
  }
  return data;
}

async function alreadyImported(messageId) {
  if (!messageId) return false;
  const q = `email_reservation_imports?select=id&message_id=eq.${encodeURIComponent(messageId)}&limit=1`;
  const data = await sb('GET', q);
  return Array.isArray(data) && data.length > 0;
}

async function markImported(row) {
  await sb('POST', 'email_reservation_imports', [row]);
}

async function findHuiloHotelId() {
  const q =
    'hotels?select=id,name&or=(name.ilike.*huilo*,name.ilike.*Huilo*)&limit=5';
  const data = await sb('GET', q);
  if (!Array.isArray(data) || !data.length) return { id: null, name: 'Huilo Huilo' };
  const preferred =
    data.find((h) => /huilo/i.test(h.name || '') && !/pack/i.test(h.name || '')) || data[0];
  return { id: preferred.id || null, name: preferred.name || 'Huilo Huilo' };
}

async function upsertReservation(parsed, hotel) {
  const row = {
    reservation_code: parsed.reservation_code,
    client_name: parsed.client_name,
    client_email: '',
    client_phone: '',
    hotel_id: hotel.id,
    hotel_name: hotel.name,
    check_in: parsed.check_in,
    check_out: parsed.check_out,
    reservation_date: new Date().toISOString().slice(0, 10),
    agent_name: 'Email Huilo',
    status: 'Confirmada',
    total_amount: parsed.total_amount || 0,
    notes: parsed.notes || null,
  };
  try {
    return await sb('POST', 'reservations?on_conflict=reservation_code', [row]);
  } catch (e) {
    const msg = String(e.message || e);
    if (/notes|column/i.test(msg)) {
      delete row.notes;
      return sb('POST', 'reservations?on_conflict=reservation_code', [row]);
    }
    throw e;
  }
}

function addressListToString(addr) {
  if (!addr) return '';
  if (typeof addr === 'string') return addr;
  if (Array.isArray(addr.value)) {
    return addr.value.map((a) => a.address || a.name || '').join(', ');
  }
  return String(addr.text || addr);
}

async function main() {
  mustEnv();
  console.log(`📬 IMAP ${IMAP_USER}@${IMAP_HOST}:${IMAP_PORT} mailbox=${MAILBOX}`);
  console.log(`📅 Buscando mails de los últimos ${SINCE_DAYS} días${DRY_RUN ? ' (DRY-RUN)' : ''}`);

  const hotel = DRY_RUN ? { id: null, name: 'Huilo Huilo' } : await findHuiloHotelId();
  console.log(`🏨 Hotel destino: ${hotel.name}${hotel.id ? ` (${hotel.id})` : ''}`);

  const client = new ImapFlow({
    host: IMAP_HOST,
    port: IMAP_PORT,
    secure: IMAP_SECURE,
    disableSTARTTLS: !IMAP_SECURE && IMAP_PORT !== 993,
    auth: {
      user: IMAP_USER,
      pass: IMAP_PASS,
      loginMethod: IMAP_LOGIN_METHOD,
    },
    logger: false,
    tls: { rejectUnauthorized: IMAP_TLS_REJECT },
  });

  const stats = { scanned: 0, parsed: 0, imported: 0, skipped: 0, errors: 0 };
  const sinceDate = new Date();
  sinceDate.setDate(sinceDate.getDate() - SINCE_DAYS);

  await client.connect();
  try {
    const lock = await client.getMailboxLock(MAILBOX);
    try {
      // SINCE usa fecha IMAP (día)
      const uids = await client.search({ since: sinceDate }, { uid: true });
      console.log(`🔍 UIDs desde ${sinceDate.toISOString().slice(0, 10)}: ${uids.length}`);

      for await (const msg of client.fetch(uids, { uid: true, source: true, envelope: true }, { uid: true })) {
        stats.scanned += 1;
        let parsedMail;
        try {
          parsedMail = await simpleParser(msg.source);
        } catch (e) {
          stats.errors += 1;
          console.warn(`⚠️ UID ${msg.uid}: no se pudo parsear mail`, e.message);
          continue;
        }

        const from = addressListToString(parsedMail.from);
        const subject = parsedMail.subject || '';
        const messageId = (parsedMail.messageId || `uid-${msg.uid}`).trim();

        if (!/huilohuilo\.com/i.test(from) && !/huilo/i.test(subject)) {
          continue;
        }

        if (!DRY_RUN && (await alreadyImported(messageId))) {
          stats.skipped += 1;
          continue;
        }

        const parsed = parseHuiloConfirmation({
          from,
          subject,
          text: parsedMail.text || '',
          html: parsedMail.html || '',
        });

        if (!parsed) {
          console.log(`⏭️  No es confirmación Huilo parseable: ${subject}`);
          if (!DRY_RUN) {
            try {
              await markImported({
                message_id: messageId,
                reservation_code: null,
                hotel_key: 'huilo',
                subject,
                from_addr: from,
                status: 'skipped',
                error_detail: 'no_parse',
              });
            } catch (_) {
              /* ignore */
            }
          }
          stats.skipped += 1;
          continue;
        }

        stats.parsed += 1;
        console.log(
          `✅ ${parsed.reservation_code} | ${parsed.client_name} | ${parsed.check_in}→${parsed.check_out} | ${parsed.currency} ${parsed.total_amount}`
        );

        if (DRY_RUN) continue;

        try {
          await upsertReservation(parsed, hotel);
          await markImported({
            message_id: messageId,
            reservation_code: parsed.reservation_code,
            hotel_key: 'huilo',
            subject,
            from_addr: from,
            status: 'imported',
          });
          stats.imported += 1;
        } catch (e) {
          stats.errors += 1;
          console.error(`❌ Error importando ${parsed.reservation_code}:`, e.message);
          try {
            await markImported({
              message_id: messageId,
              reservation_code: parsed.reservation_code,
              hotel_key: 'huilo',
              subject,
              from_addr: from,
              status: 'error',
              error_detail: String(e.message || e).slice(0, 500),
            });
          } catch (_) {
            /* ignore */
          }
        }
      }
    } finally {
      lock.release();
    }
  } finally {
    await client.logout().catch(() => {});
  }

  console.log('———');
  console.log(
    `Listo. scanned=${stats.scanned} parsed=${stats.parsed} imported=${stats.imported} skipped=${stats.skipped} errors=${stats.errors}`
  );
}

main().catch((e) => {
  console.error('Fatal:', e);
  process.exit(1);
});
