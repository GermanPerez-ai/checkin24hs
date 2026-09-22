'use strict';

const WEB_URL = (process.env.MONITOR_WEB_URL || 'https://www.checkin24hs.com').replace(/\/$/, '');
const DASHBOARD_URL = (process.env.MONITOR_DASHBOARD_URL || 'https://dashboard.checkin24hs.com').replace(
  /\/$/,
  ''
);
const COTIZADOR_URL = (process.env.MONITOR_COTIZADOR_URL || 'https://cotizar.checkin24hs.com').replace(
  /\/$/,
  ''
);
const WA_API = (process.env.WHATSAPP_API_URL || 'https://whatsapp.checkin24hs.com').replace(/\/$/, '');
const WA_LINE_APIS = [
  { line: 1, label: 'L1', url: WA_API },
  {
    line: 2,
    label: 'L2',
    url: (process.env.WHATSAPP2_API_URL || 'https://whatsapp2.checkin24hs.com').replace(/\/$/, ''),
  },
  {
    line: 3,
    label: 'L3',
    url: (process.env.WHATSAPP3_API_URL || 'https://whatsapp3.checkin24hs.com').replace(/\/$/, ''),
  },
  {
    line: 4,
    label: 'L4',
    url: (process.env.WHATSAPP4_API_URL || 'https://whatsapp4.checkin24hs.com').replace(/\/$/, ''),
  },
];

const CRYPTO_ISSUES_MAX = Math.max(
  10,
  parseInt(process.env.MONITOR_CRYPTO_ISSUES_MAX || '80', 10) || 80
);
const SUPABASE_URL = (process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co').replace(
  /\/$/,
  ''
);
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4';
const TIMEOUT_MS = Math.max(3000, parseInt(process.env.MONITOR_TIMEOUT_MS || '15000', 10) || 15000);
const CACHE_MS = Math.max(15_000, parseInt(process.env.ANA_SNAPSHOT_CACHE_MS || '45000', 10) || 45_000);
const { fetchInbox } = require('./mail');

function digitsOnly(value) {
  return String(value || '').replace(/\D/g, '');
}

const GOOGLE_ADS_CUSTOMER_ID = digitsOnly(process.env.GOOGLE_ADS_CUSTOMER_ID || '2654092864');
const GOOGLE_ADS_ACCOUNT_NAME = String(process.env.GOOGLE_ADS_ACCOUNT_NAME || 'Checkin24hs').trim();
const GOOGLE_ADS_ADVERTISER_ID = digitsOnly(process.env.GOOGLE_ADS_ADVERTISER_ID || '505321673398');
const GOOGLE_ADS_DEVELOPER_TOKEN = String(process.env.GOOGLE_ADS_DEVELOPER_TOKEN || '').trim();
const GOOGLE_ADS_REFRESH_TOKEN = String(process.env.GOOGLE_ADS_REFRESH_TOKEN || '').trim();
const META_AD_ACCOUNT_ID = digitsOnly(process.env.META_AD_ACCOUNT_ID || '');
const META_ADS_ACCESS_TOKEN = String(process.env.META_ADS_ACCESS_TOKEN || '').trim();

function formatGoogleCid(digits) {
  const d = digitsOnly(digits);
  if (d.length === 10) return d.replace(/(\d{3})(\d{3})(\d{4})/, '$1-$2-$3');
  if (d.length === 12) return d.replace(/(\d{4})(\d{4})(\d{4})/, '$1-$2-$3');
  return d;
}

let snapshotCache = { at: 0, data: null, inflight: null };

function arYmd(date = new Date()) {
  return date.toLocaleDateString('en-CA', { timeZone: 'America/Argentina/Buenos_Aires' });
}

function addYmd(ymd, deltaDays) {
  const [y, m, d] = ymd.split('-').map(Number);
  const utc = new Date(Date.UTC(y, m - 1, d + deltaDays));
  return utc.toISOString().slice(0, 10);
}

function arDayBounds(ymd) {
  const from = new Date(`${ymd}T00:00:00.000-03:00`);
  const to = new Date(`${addYmd(ymd, 1)}T00:00:00.000-03:00`);
  return { from: from.toISOString(), to: to.toISOString(), ymd };
}

function monthStartYmd(ymd) {
  return `${ymd.slice(0, 7)}-01`;
}

function toArYmd(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return String(iso).slice(0, 10);
  return d.toLocaleDateString('en-CA', { timeZone: 'America/Argentina/Buenos_Aires' });
}

async function supabaseRpc(fnName, body) {
  if (!SUPABASE_ANON_KEY) {
    return { ok: false, status: 0, data: 'Falta SUPABASE_ANON_KEY' };
  }
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fnName}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { ok: res.ok, status: res.status, data };
}

async function supabaseSelect(table, query) {
  if (!SUPABASE_ANON_KEY) {
    return { ok: false, status: 0, data: 'Falta SUPABASE_ANON_KEY' };
  }
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}`, {
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { ok: res.ok, status: res.status, data };
}

function lineMapFromArray(arr, valueKey) {
  const map = {};
  if (!Array.isArray(arr)) return map;
  for (const row of arr) {
    const line = Number(row.line ?? row.whatsapp_instance ?? 0);
    if (!line) continue;
    map[line] = Number(row[valueKey] ?? 0);
  }
  return map;
}

function normalizeOpsDay(ymd, data) {
  const chatsByLine = lineMapFromArray(data?.new_chats_by_line, 'new_chats');
  const inboundByLine = lineMapFromArray(data?.inbound_by_line, 'inbound_messages');
  const phoneByLine = {};
  if (Array.isArray(data?.line_phones)) {
    for (const row of data.line_phones) {
      const line = Number(row.line ?? 0);
      if (line) phoneByLine[line] = String(row.phone || '').replace(/\D/g, '');
    }
  }
  const slaByLine = {};
  if (Array.isArray(data?.human_sla_by_line)) {
    for (const row of data.human_sla_by_line) {
      const line = Number(row.line ?? 0);
      if (!line) continue;
      slaByLine[line] = {
        measured: Number(row.measured ?? 0),
        avg_sec: row.avg_sec == null ? null : Number(row.avg_sec),
        median_sec: row.median_sec == null ? null : Number(row.median_sec),
        over_5min: Number(row.over_5min ?? 0),
        over_15min: Number(row.over_15min ?? 0),
      };
    }
  }
  const handoffsByLine = lineMapFromArray(data?.handoffs_by_line, 'handoffs');
  const lines = [1, 2, 3, 4].map((line) => ({
    line,
    phone: phoneByLine[line] || '',
    new_chats: chatsByLine[line] || 0,
    inbound: inboundByLine[line] || 0,
    handoffs: handoffsByLine[line] || 0,
    sla: slaByLine[line] || null,
  }));
  return {
    ymd,
    new_chats_total: Number(data?.new_chats_total ?? 0),
    inbound_messages_total: Number(data?.inbound_messages_total ?? 0),
    active_chats_with_inbound: Number(data?.active_chats_with_inbound ?? 0),
    chats_with_hotel: Number(data?.chats_with_hotel ?? 0),
    handoffs_total: Number(data?.handoffs_total ?? 0),
    top_hotels: Array.isArray(data?.top_hotels) ? data.top_hotels : [],
    funnel: data?.funnel || null,
    ticket: data?.ticket || null,
    abandon: data?.abandon || null,
    origins: Array.isArray(data?.origins) ? data.origins : [],
    lines,
  };
}

async function fetchVisitStats() {
  const today = arYmd();
  const yesterday = addYmd(today, -1);
  const out = { today: null, yesterday: null, error: null };
  try {
    for (const r of [
      { label: 'hoy', ...arDayBounds(today) },
      { label: 'ayer', ...arDayBounds(yesterday) },
    ]) {
      const { ok, status, data } = await supabaseRpc('site_visit_stats', {
        p_from: r.from,
        p_to: r.to,
      });
      if (!ok) {
        out.error =
          status === 404
            ? 'Falta migración de visitas (site_visit_stats) en Supabase'
            : `Supabase visitas ${status}`;
        return out;
      }
      const stats = {
        ymd: r.ymd,
        visitors: Number(data?.visitors ?? 0),
        pageviews: Number(data?.pageviews ?? 0),
        top_utm: Array.isArray(data?.top_utm) ? data.top_utm : [],
        top_pages: Array.isArray(data?.top_pages) ? data.top_pages : [],
      };
      if (r.label === 'hoy') out.today = stats;
      else out.yesterday = stats;
    }
  } catch (e) {
    out.error = e.message || String(e);
  }
  return out;
}

async function fetchWhatsappChatStats() {
  const today = arYmd();
  const yesterday = addYmd(today, -1);
  const out = { today: null, yesterday: null, error: null, source: null };
  try {
    let useOps = true;
    for (const r of [
      { label: 'hoy', ...arDayBounds(today) },
      { label: 'ayer', ...arDayBounds(yesterday) },
    ]) {
      let data = null;
      if (useOps) {
        const ops = await supabaseRpc('whatsapp_ops_daily_stats', {
          p_from: r.from,
          p_to: r.to,
        });
        if (ops.ok) {
          data = ops.data;
          out.source = 'ops';
        } else if ([404, 500, 504, 57014].includes(ops.status)) {
          useOps = false;
        } else {
          out.error = `Supabase Flor ${ops.status}`;
          return out;
        }
      }
      if (!data) {
        const legacy = await supabaseRpc('whatsapp_daily_chat_stats', {
          p_from: r.from,
          p_to: r.to,
        });
        if (!legacy.ok) {
          out.error =
            legacy.status === 404
              ? 'Falta RPC de chats WhatsApp en Supabase'
              : `Supabase chats ${legacy.status}`;
          return out;
        }
        data = legacy.data || {};
        out.source = out.source || 'legacy';
      }
      const stats = normalizeOpsDay(r.ymd, data);
      if (r.label === 'hoy') out.today = stats;
      else out.yesterday = stats;
    }
  } catch (e) {
    out.error = e.message || String(e);
  }
  return out;
}

async function fetchCheck(name, url, opts = {}) {
  const started = Date.now();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: {
        'User-Agent': 'Checkin24hs-ANA/1.0 (node)',
        Accept: opts.accept || 'text/html,application/json,*/*',
      },
    });
    const ms = Date.now() - started;
    let bodyText = '';
    try {
      bodyText = await res.text();
    } catch {
      bodyText = '';
    }
    const issues = [];
    if (res.status < 200 || res.status >= 400) issues.push(`HTTP ${res.status}`);
    if (opts.expectIncludes) {
      for (const needle of opts.expectIncludes) {
        if (!bodyText.includes(needle)) issues.push(`falta texto "${needle}"`);
      }
    }
    let json = null;
    if (opts.parseJson || opts.expectWhatsappOpen) {
      try {
        json = JSON.parse(bodyText);
      } catch {
        issues.push('respuesta no es JSON');
      }
    }
    if (json && opts.expectWhatsappOpen) {
      if (json.whatsapp && json.whatsapp !== 'open' && json.whatsapp !== 'connected') {
        issues.push(`WhatsApp status="${json.whatsapp}"`);
      }
    }
    if (json && opts.maxCryptoIssues != null) {
      const n = Number(json.florSessionCryptoIssuesLastWindow || 0);
      if (Number.isFinite(n) && n > opts.maxCryptoIssues) {
        issues.push(`sesión inestable: ${n} errores cripto (umbral ${opts.maxCryptoIssues})`);
      }
    }
    if (opts.maxMs && ms > opts.maxMs) issues.push(`lento ${ms}ms`);
    return {
      name,
      url,
      ok: issues.length === 0,
      status: res.status,
      ms,
      issues,
      meta: json
        ? {
            whatsapp: json.whatsapp || null,
            flor: json.flor || null,
            cryptoIssues: Number(json.florSessionCryptoIssuesLastWindow || 0) || 0,
          }
        : null,
    };
  } catch (e) {
    return {
      name,
      url,
      ok: false,
      status: 0,
      ms: Date.now() - started,
      issues: [e.name === 'AbortError' ? `timeout ${TIMEOUT_MS}ms` : e.message || String(e)],
      meta: null,
    };
  } finally {
    clearTimeout(timer);
  }
}

async function fetchHealth() {
  const results = [
    await fetchCheck('Web', `${WEB_URL}/`, { expectIncludes: ['Checkin'], maxMs: 8000 }),
    await fetchCheck('Dashboard', `${DASHBOARD_URL}/`, { maxMs: 10000 }),
    await fetchCheck('Cotizador', `${COTIZADOR_URL}/`, { maxMs: 10000 }),
  ];
  for (const line of WA_LINE_APIS) {
    results.push(
      await fetchCheck(`WhatsApp ${line.label}`, `${line.url}/api/health`, {
        accept: 'application/json',
        expectWhatsappOpen: true,
        parseJson: true,
        maxCryptoIssues: CRYPTO_ISSUES_MAX,
        maxMs: 8000,
      })
    );
  }
  return results;
}

function moneySum(rows, key) {
  let n = 0;
  let amount = 0;
  for (const row of rows) {
    const v = Number(row[key]);
    if (!Number.isFinite(v) || v <= 0) continue;
    n += 1;
    amount += v;
  }
  return { n, amount: Math.round(amount) };
}

function isCancelled(status) {
  return /cancel/i.test(String(status || ''));
}

function isConfirmed(status) {
  return /confirm|pagad|cerrad|check.?in/i.test(String(status || ''));
}

function isPending(status) {
  const s = String(status || '');
  return /pendient|nueva|proceso|hold/i.test(s) && !isCancelled(s);
}

async function fetchSales() {
  const today = arYmd();
  const fromYmd = addYmd(monthStartYmd(today), -240);
  const fromIso = `${fromYmd}T00:00:00.000-03:00`;
  const select =
    'id,reservation_code,hotel_name,customer_name,check_in,check_out,total_amount,status,created_at,customer_phone';
  const { ok, status, data } = await supabaseSelect(
    'reservations',
    `select=${select}&created_at=gte.${encodeURIComponent(fromIso)}&order=created_at.desc&limit=2000`
  );
  if (!ok) {
    return {
      error: status === 0 ? 'Falta SUPABASE_ANON_KEY' : `Supabase reservas ${status}`,
      currency: 'USD',
      range_from: fromYmd,
      today: { ymd: today, count: 0, amount: 0 },
      yesterday: { ymd: addYmd(today, -1), count: 0, amount: 0 },
      month: { ymd: monthStartYmd(today), count: 0, amount: 0 },
      pending: { count: 0, amount: 0 },
      weeks: [],
      recent: [],
      pending_cancel: [],
      pending_modify: [],
      by_hotel_month: [],
    };
  }
  const rows = Array.isArray(data) ? data : [];
  const active = rows.filter((r) => !isCancelled(r.status));
  const todayRows = active.filter((r) => toArYmd(r.created_at) === today);
  const yesterday = addYmd(today, -1);
  const yesterdayRows = active.filter((r) => toArYmd(r.created_at) === yesterday);
  const monthRows = active.filter((r) => toArYmd(r.created_at).slice(0, 7) === today.slice(0, 7));
  const pendingRows = rows.filter((r) => isPending(r.status));
  const todaySum = moneySum(todayRows, 'total_amount');
  const yesterdaySum = moneySum(yesterdayRows, 'total_amount');
  const monthSum = moneySum(monthRows, 'total_amount');
  const pendingSum = moneySum(pendingRows, 'total_amount');

  const weekMap = new Map();
  for (let i = 3; i >= 0; i--) {
    const end = addYmd(today, -i * 7);
    const start = addYmd(end, -6);
    weekMap.set(start, { label: `${start.slice(5)}–${end.slice(5)}`, start, end, amount: 0, count: 0 });
  }
  const weekKeys = [...weekMap.keys()].sort();
  for (const r of active) {
    const ymd = toArYmd(r.created_at);
    const amount = Number(r.total_amount);
    if (!ymd || !Number.isFinite(amount) || amount <= 0) continue;
    for (let i = weekKeys.length - 1; i >= 0; i--) {
      const w = weekMap.get(weekKeys[i]);
      if (ymd >= w.start && ymd <= w.end) {
        w.amount += amount;
        w.count += 1;
        break;
      }
    }
  }

  const hotelMonth = new Map();
  const bump = (hotel, month, field, amount) => {
    const name = String(hotel || 'Sin hotel').trim() || 'Sin hotel';
    const key = `${name.toLowerCase()}||${month}`;
    if (!hotelMonth.has(key)) {
      hotelMonth.set(key, {
        hotel: name,
        month,
        created_count: 0,
        created_amount: 0,
        checkin_count: 0,
        checkin_amount: 0,
      });
    }
    const row = hotelMonth.get(key);
    row[`${field}_count`] += 1;
    if (Number.isFinite(amount) && amount > 0) row[`${field}_amount`] += amount;
  };
  for (const r of active) {
    const amount = Number(r.total_amount) || 0;
    const createdMonth = toArYmd(r.created_at).slice(0, 7);
    if (createdMonth.length === 7) bump(r.hotel_name, createdMonth, 'created', amount);
    const checkin = String(r.check_in || '').slice(0, 7);
    if (/^\d{4}-\d{2}$/.test(checkin)) bump(r.hotel_name, checkin, 'checkin', amount);
  }
  const by_hotel_month = [...hotelMonth.values()]
    .map((x) => ({
      ...x,
      created_amount: Math.round(x.created_amount),
      checkin_amount: Math.round(x.checkin_amount),
    }))
    .sort((a, b) => b.month.localeCompare(a.month) || b.created_amount - a.created_amount)
    .slice(0, 120);

  const out = {
    error: null,
    currency: 'USD',
    range_from: fromYmd,
    truncated: rows.length >= 2000,
    today: { ymd: today, count: todayRows.length, amount: todaySum.amount, with_amount: todaySum.n },
    yesterday: { ymd: yesterday, count: yesterdayRows.length, amount: yesterdaySum.amount, with_amount: yesterdaySum.n },
    month: {
      ymd: monthStartYmd(today),
      count: monthRows.length,
      amount: monthSum.amount,
      with_amount: monthSum.n,
      confirmed: monthRows.filter((r) => isConfirmed(r.status)).length,
    },
    pending: { count: pendingRows.length, amount: pendingSum.amount },
    weeks: weekKeys.map((k) => {
      const w = weekMap.get(k);
      return { ...w, amount: Math.round(w.amount) };
    }),
    by_hotel_month,
    recent: active.slice(0, 8).map((r) => ({
      code: r.reservation_code || r.id,
      hotel: r.hotel_name || 'Hotel',
      customer: r.customer_name || '',
      amount: Number(r.total_amount) || 0,
      status: r.status || '',
      created_at: r.created_at,
    })),
    pending_cancel: [],
    pending_modify: [],
  };
  try {
    const open = await fetchHotelActionRequests();
    out.pending_cancel = open.pending_cancel;
    out.pending_modify = open.pending_modify;
  } catch (_) {}
  return out;
}

function hoursWaiting(iso) {
  if (!iso) return null;
  const t = new Date(iso).getTime();
  if (!Number.isFinite(t)) return null;
  return Math.max(0, Math.round((Date.now() - t) / 3600000));
}

function mapHotelRequest(r) {
  const when = r.updated_at || r.created_at;
  const notes = String(r.notes || '');
  return {
    id: r.id,
    code: r.reservation_code || r.id,
    hotel: r.hotel_name || 'Hotel',
    customer: r.customer_name || '',
    amount: Number(r.total_amount) || 0,
    status: r.status || '',
    check_in: r.check_in || '',
    check_out: r.check_out || '',
    created_at: r.created_at,
    updated_at: r.updated_at || null,
    hours_waiting: hoursWaiting(when),
    notes_hint: /PEDIDO|HOTEL confirm/i.test(notes) ? notes.split('\n').filter(Boolean).slice(-1)[0] : '',
  };
}

function isAnulacionPedido(r) {
  const s = String(r.status || '');
  if (/anulaci[oó]n pedida/i.test(s)) return true;
  if (/en gesti[oó]n/i.test(s) && /anular|anulaci/i.test(String(r.notes || ''))) return true;
  return false;
}

function isModificacionPedido(r) {
  const s = String(r.status || '');
  if (/modificaci[oó]n pedida/i.test(s)) return true;
  if (/en gesti[oó]n/i.test(s) && /modificar|modificaci/i.test(String(r.notes || ''))) return true;
  return false;
}

async function fetchHotelActionRequests() {
  const select =
    'id,reservation_code,hotel_name,customer_name,check_in,check_out,total_amount,status,created_at,updated_at,notes';
  const or =
    'status.eq.' +
    encodeURIComponent('Anulación pedida') +
    ',status.eq.' +
    encodeURIComponent('Modificación pedida') +
    ',status.eq.' +
    encodeURIComponent('En gestión');
  let res = await supabaseSelect(
    'reservations',
    `select=${select}&or=(${or})&order=updated_at.desc&limit=80`
  );
  if (!res.ok) {
    res = await supabaseSelect(
      'reservations',
      `select=id,reservation_code,hotel_name,customer_name,check_in,check_out,total_amount,status,created_at,updated_at&or=(${or})&order=created_at.desc&limit=80`
    );
  }
  const rows = res.ok && Array.isArray(res.data) ? res.data : [];
  const pending_cancel = rows.filter(isAnulacionPedido).map(mapHotelRequest);
  const pending_modify = rows.filter(isModificacionPedido).map(mapHotelRequest);
  const gestionOrphans = rows.filter((r) => {
    if (!/en gesti[oó]n/i.test(String(r.status || ''))) return false;
    return !isAnulacionPedido(r) && !isModificacionPedido(r);
  }).map(mapHotelRequest);
  return {
    pending_cancel: pending_cancel.concat(gestionOrphans),
    pending_modify,
  };
}

async function fetchHotels() {
  const { ok, status, data } = await supabaseSelect(
    'hotels',
    'select=id,name,location,status&order=name.asc&limit=200'
  );
  if (!ok) {
    return { error: `Supabase hoteles ${status}`, items: [], count: 0 };
  }
  const items = Array.isArray(data) ? data : [];
  return {
    error: null,
    count: items.length,
    items: items.slice(0, 40).map((h) => ({
      name: h.name,
      location: h.location || '',
      status: h.status || '',
    })),
  };
}

function ideasFromSnapshot({ health, visits, flor, sales, mail }) {
  const ideas = [];
  const failed = (health || []).filter((r) => !r.ok);
  if (failed.length) {
    ideas.push(`Atender ${failed.length} chequeo(s) en rojo: ${failed.map((r) => r.name).join(', ')}.`);
  }
  if (visits?.error) ideas.push(`Visitas web sin datos: ${visits.error}`);
  if (flor?.error) ideas.push(`Métricas Flor sin datos: ${flor.error}`);
  if (sales?.error) ideas.push(`Reservas sin datos: ${sales.error}`);
  const y = flor?.yesterday;
  if (y?.funnel && Number(y.funnel.handoffs || 0) > 0 && Number(y.funnel.quotes || 0) === 0) {
    ideas.push('Ayer hubo hand-offs de Flor y 0 cotizaciones vinculadas: revisar seguimiento humano.');
  }
  if (sales?.pending_cancel?.length) {
    const n = sales.pending_cancel.length;
    const stale = sales.pending_cancel.filter((r) => Number(r.hours_waiting) >= 18).length;
    ideas.push(
      `${n} pedido(s) de anulación abiertos` +
        (stale ? ` · ${stale} con más de 18 h sin cierre del hotel` : '') +
        '. ANA hace seguimiento hasta que el hotel confirme.'
    );
  }
  if (sales?.pending_modify?.length) {
    const n = sales.pending_modify.length;
    const stale = sales.pending_modify.filter((r) => Number(r.hours_waiting) >= 18).length;
    ideas.push(
      `${n} pedido(s) de modificación abiertos` +
        (stale ? ` · ${stale} con más de 18 h sin respuesta` : '') +
        '. ANA hace seguimiento.'
    );
  }
  if (sales?.pending?.count > 0) {
    ideas.push(`${sales.pending.count} reserva(s) en estado pendiente — revisar cobranzas.`);
  }
  if (mail?.connected && Number(mail.urgent || 0) > 0) {
    ideas.push(`${mail.urgent} mail(s) prioritarios en reservas@ (hoteles/tarifas/proveedores).`);
  } else if (mail && !mail.connected && mail.reason) {
    ideas.push(`Webmail: ${mail.reason}`);
  }
  if (!ideas.length) {
    ideas.push('Chequeos en verde. Google Ads y Meta quedan para después; ocupación hotelera no está en la base.');
  }
  return ideas.slice(0, 8);
}

async function buildSnapshot() {
  const generated_at = new Date().toISOString();
  const timezone = 'America/Argentina/Buenos_Aires';
  const [health, visits, flor, sales, hotels, mail] = await Promise.all([
    fetchHealth(),
    fetchVisitStats(),
    fetchWhatsappChatStats(),
    fetchSales(),
    fetchHotels(),
    fetchInbox(20),
  ]);
  const snapshot = {
    agent: 'ANA',
    generated_at,
    timezone,
    ymd: arYmd(),
    modules: {
      monitor: { connected: true, checks: health },
      dashboard: sales.error ? { connected: false, error: sales.error } : { connected: true, sales },
      web: visits.error ? { connected: false, error: visits.error } : { connected: true, visits },
      flor: flor.error ? { connected: false, error: flor.error, source: flor.source } : { connected: true, source: flor.source, flor },
      ads: {
        connected: false,
        google: {
          customer_id: GOOGLE_ADS_CUSTOMER_ID,
          name: GOOGLE_ADS_ACCOUNT_NAME,
          display_id: formatGoogleCid(GOOGLE_ADS_CUSTOMER_ID),
          advertiser_id: GOOGLE_ADS_ADVERTISER_ID,
          advertiser_display_id: formatGoogleCid(GOOGLE_ADS_ADVERTISER_ID),
          token_ready: Boolean(GOOGLE_ADS_DEVELOPER_TOKEN && GOOGLE_ADS_REFRESH_TOKEN),
        },
        meta: META_AD_ACCOUNT_ID
          ? {
              account_id: META_AD_ACCOUNT_ID,
              act_id: `act_${META_AD_ACCOUNT_ID}`,
              token_ready: Boolean(META_ADS_ACCESS_TOKEN),
            }
          : { configured: false },
        campaigns: [],
        reason:
          'Solo Google Ads. Cuentas identificadas; falta developer token + OAuth para leer campañas, gasto, CPC y ROAS. Meta no está cargada. No inventar métricas.',
      },
      webmail: mail.connected
        ? { connected: true, mail }
        : { connected: false, reason: mail.reason || 'IMAP no disponible', mail },
      occupancy: {
        connected: false,
        reason: 'No hay PMS ni ocupación real por hotel en Supabase (Checkin24hs representa, no opera el hotel).',
      },
      empresa: hotels.error
        ? { connected: false, error: hotels.error }
        : { connected: true, hotels },
    },
    ideas: ideasFromSnapshot({ health, visits, flor, sales, mail }),
  };
  return snapshot;
}

async function getSnapshot({ force = false } = {}) {
  const now = Date.now();
  if (!force && snapshotCache.data && now - snapshotCache.at < CACHE_MS) {
    return snapshotCache.data;
  }
  if (snapshotCache.inflight) return snapshotCache.inflight;
  snapshotCache.inflight = buildSnapshot()
    .then((data) => {
      snapshotCache = { at: Date.now(), data, inflight: null };
      return data;
    })
    .catch((err) => {
      snapshotCache.inflight = null;
      throw err;
    });
  return snapshotCache.inflight;
}

async function supabaseInsert(table, body, { onConflict } = {}) {
  if (!SUPABASE_ANON_KEY) {
    return { ok: false, status: 0, data: 'Falta SUPABASE_ANON_KEY' };
  }
  const qs = onConflict ? `?on_conflict=${encodeURIComponent(onConflict)}` : '';
  const prefer = onConflict
    ? 'resolution=merge-duplicates,return=representation'
    : 'return=representation';
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}${qs}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
      Prefer: prefer,
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { ok: res.ok, status: res.status, data };
}

module.exports = {
  getSnapshot,
  arYmd,
  addYmd,
  arDayBounds,
  supabaseSelect,
  supabaseRpc,
  supabaseInsert,
};
