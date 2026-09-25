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
const { fetchAdsSnapshot } = require('./ads');

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

function visitRange(fromYmd, toYmd) {
  return {
    from: arDayBounds(fromYmd).from,
    to: arDayBounds(toYmd).to,
    ymd: fromYmd === toYmd ? fromYmd : `${fromYmd}→${toYmd}`,
  };
}

function normalizeVisitStats(ymd, data) {
  return {
    ymd,
    visitors: Number(data?.visitors ?? 0),
    pageviews: Number(data?.pageviews ?? 0),
    top_utm: Array.isArray(data?.top_utm) ? data.top_utm : [],
    top_pages: Array.isArray(data?.top_pages) ? data.top_pages : [],
  };
}

async function fetchVisitStats() {
  const today = arYmd();
  const yesterday = addYmd(today, -1);
  const out = {
    today: null,
    yesterday: null,
    last_7d: null,
    last_30d: null,
    last_60d: null,
    error: null,
  };
  const ranges = [
    { key: 'today', ...visitRange(today, today) },
    { key: 'yesterday', ...visitRange(yesterday, yesterday) },
    { key: 'last_7d', ...visitRange(addYmd(today, -6), today) },
    { key: 'last_30d', ...visitRange(addYmd(today, -29), today) },
    { key: 'last_60d', ...visitRange(addYmd(today, -59), today) },
  ];
  try {
    const results = await Promise.all(
      ranges.map((r) =>
        supabaseRpc('site_visit_stats', { p_from: r.from, p_to: r.to }).then((res) => ({ r, res }))
      )
    );
    for (const { r, res } of results) {
      if (!res.ok) {
        out.error =
          res.status === 404
            ? 'Falta migración de visitas (site_visit_stats) en Supabase'
            : `Supabase visitas ${res.status}`;
        return out;
      }
      out[r.key] = normalizeVisitStats(r.ymd, res.data);
    }
  } catch (e) {
    out.error = e.message || String(e);
  }
  return out;
}

function classifyWebConsulta(text) {
  const t = String(text || '');
  if (/vi la promo en checkin24hs/i.test(t)) {
    const m = t.match(/quiero info:\s*(.+)$/i);
    return { kind: 'promo', product: (m ? m[1] : '').trim().slice(0, 80) };
  }
  const hotel = t.match(/m[aá]s info del hotel\s+(.+)$/i);
  if (hotel) return { kind: 'hotel', product: hotel[1].trim().slice(0, 80) };
  const pack = t.match(/m[aá]s info del pack\s+(.+)$/i);
  if (pack) return { kind: 'pack', product: pack[1].trim().slice(0, 80) };
  const about = t.match(/sobre:\s*(.+)$/i);
  if (about) return { kind: 'general', product: about[1].trim().slice(0, 80) };
  return { kind: 'general', product: '' };
}

function emptyConsultaBucket() {
  return { count: 0, unique: 0, hotel: 0, pack: 0, promo: 0, general: 0 };
}

async function fetchWebConsultas() {
  const today = arYmd();
  const bounds = {
    today: visitRange(today, today),
    last_7d: visitRange(addYmd(today, -6), today),
    last_30d: visitRange(addYmd(today, -29), today),
    last_60d: visitRange(addYmd(today, -59), today),
  };
  const fromIso = bounds.last_60d.from;
  const toIso = bounds.last_60d.to;
  const rows = [];
  try {
    for (let offset = 0; offset < 8000; offset += 1000) {
      const q = [
        'select=phone,message,body,is_from_me,whatsapp_instance,sent_at,created_at',
        `sent_at=gte.${encodeURIComponent(fromIso)}`,
        `sent_at=lt.${encodeURIComponent(toIso)}`,
        'is_from_me=eq.false',
        'or=(message.ilike.*consulta desde checkin24hs*,body.ilike.*consulta desde checkin24hs*,message.ilike.*promo en checkin24hs*,body.ilike.*promo en checkin24hs*)',
        'order=sent_at.desc',
        'limit=1000',
        `offset=${offset}`,
      ].join('&');
      const { ok, status, data } = await supabaseSelect('whatsapp_messages', q);
      if (!ok) {
        return { error: `Supabase consultas web ${status}`, ...Object.fromEntries(Object.keys(bounds).map((k) => [k, emptyConsultaBucket()])), top: [], recent: [] };
      }
      const page = Array.isArray(data) ? data : [];
      rows.push(...page);
      if (page.length < 1000) break;
    }
  } catch (e) {
    return {
      error: e.message || String(e),
      today: emptyConsultaBucket(),
      last_7d: emptyConsultaBucket(),
      last_30d: emptyConsultaBucket(),
      last_60d: emptyConsultaBucket(),
      top: [],
      recent: [],
    };
  }

  const WEB = /consulta desde checkin24hs\.com|promo en checkin24hs\.com/i;
  const inbound = rows.filter((m) => WEB.test(String(m.message || m.body || '')));
  const summarize = (from, to) => {
    const t0 = new Date(from).getTime();
    const t1 = new Date(to).getTime();
    const slice = inbound.filter((m) => {
      const t = new Date(m.sent_at || m.created_at).getTime();
      return Number.isFinite(t) && t >= t0 && t < t1;
    });
    const bucket = emptyConsultaBucket();
    const phones = new Set();
    for (const m of slice) {
      const { kind } = classifyWebConsulta(m.message || m.body);
      bucket.count += 1;
      bucket[kind] = (bucket[kind] || 0) + 1;
      phones.add(String(m.phone || ''));
    }
    bucket.unique = phones.size;
    return bucket;
  };

  const products = {};
  for (const m of inbound) {
    const { kind, product } = classifyWebConsulta(m.message || m.body);
    if (!product) continue;
    const key = `${kind}:${product}`;
    if (!products[key]) products[key] = { kind, name: product, count: 0 };
    products[key].count += 1;
  }

  return {
    error: null,
    source: 'whatsapp L2 · botón web al 1580',
    today: summarize(bounds.today.from, bounds.today.to),
    last_7d: summarize(bounds.last_7d.from, bounds.last_7d.to),
    last_30d: summarize(bounds.last_30d.from, bounds.last_30d.to),
    last_60d: summarize(bounds.last_60d.from, bounds.last_60d.to),
    top: Object.values(products)
      .sort((a, b) => b.count - a.count)
      .slice(0, 8),
    recent: inbound.slice(0, 8).map((m) => {
      const { kind, product } = classifyWebConsulta(m.message || m.body);
      return {
        at: m.sent_at || m.created_at,
        kind,
        product,
        phone: String(m.phone || '').slice(-4),
      };
    }),
  };
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
  const s = String(status || '');
  return /cancelad/i.test(s) || /^cancelada$/i.test(s.trim());
}

function isConfirmed(status) {
  return /confirm|pagad|cerrad|check.?in/i.test(String(status || ''));
}

function isPending(status) {
  const s = String(status || '');
  return /pendient|nueva|proceso|hold/i.test(s) && !isCancelled(s);
}

function ymdMonth(value) {
  const s = String(value || '').slice(0, 7);
  return /^\d{4}-\d{2}$/.test(s) ? s : '';
}

function emptyHotelMonth(hotel, month) {
  return {
    hotel,
    month,
    created_count: 0,
    created_amount: 0,
    checkin_count: 0,
    checkin_amount: 0,
    checkout_count: 0,
    checkout_amount: 0,
    cancelled_count: 0,
    cancelled_amount: 0,
    cancelled_checkin_count: 0,
    cancelled_checkin_amount: 0,
    cancelled_checkout_count: 0,
    cancelled_checkout_amount: 0,
  };
}

function bumpHotelMonth(map, hotel, month, field, amount) {
  if (!month) return;
  const name = String(hotel || 'Sin hotel').trim() || 'Sin hotel';
  const key = `${name.toLowerCase()}||${month}`;
  if (!map.has(key)) map.set(key, emptyHotelMonth(name, month));
  const row = map.get(key);
  row[`${field}_count`] += 1;
  if (Number.isFinite(amount) && amount > 0) row[`${field}_amount`] += amount;
}

function emptyPeriodMonth(month) {
  return {
    month,
    created_count: 0,
    created_amount: 0,
    checkin_count: 0,
    checkin_amount: 0,
    checkout_count: 0,
    checkout_amount: 0,
    cancelled_count: 0,
    cancelled_amount: 0,
  };
}

function bumpPeriod(map, month, field, amount) {
  if (!month) return;
  if (!map.has(month)) map.set(month, emptyPeriodMonth(month));
  const row = map.get(month);
  row[`${field}_count`] += 1;
  if (Number.isFinite(amount) && amount > 0) row[`${field}_amount`] += amount;
}

async function fetchReservationBundle(fromYmd, fromIso) {
  const select =
    'id,reservation_code,hotel_name,customer_name,check_in,check_out,total_amount,status,created_at,updated_at,customer_phone';
  const queries = [
    `select=${select}&created_at=gte.${encodeURIComponent(fromIso)}&order=created_at.desc&limit=2000`,
    `select=${select}&check_in=gte.${fromYmd}&order=check_in.desc&limit=2000`,
    `select=${select}&check_out=gte.${fromYmd}&order=check_out.desc&limit=2000`,
  ];
  const byId = new Map();
  let truncated = false;
  let lastError = null;
  for (const q of queries) {
    const { ok, status, data } = await supabaseSelect('reservations', q);
    if (!ok) {
      lastError = status === 0 ? 'Falta SUPABASE_ANON_KEY' : `Supabase reservas ${status}`;
      continue;
    }
    const rows = Array.isArray(data) ? data : [];
    if (rows.length >= 2000) truncated = true;
    for (const r of rows) {
      if (r && r.id) byId.set(r.id, r);
    }
  }
  if (!byId.size && lastError) return { ok: false, error: lastError, rows: [], truncated: false };
  return { ok: true, error: null, rows: [...byId.values()], truncated };
}

async function fetchSales() {
  const today = arYmd();
  const fromYmd = addYmd(monthStartYmd(today), -400);
  const fromIso = `${fromYmd}T00:00:00.000-03:00`;
  const empty = {
    error: null,
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
    by_month: [],
  };
  const bundle = await fetchReservationBundle(fromYmd, fromIso);
  if (!bundle.ok) {
    return { ...empty, error: bundle.error };
  }
  const rows = bundle.rows;
  const active = rows.filter((r) => !isCancelled(r.status));
  const cancelled = rows.filter((r) => isCancelled(r.status));
  const todayRows = active.filter((r) => toArYmd(r.created_at) === today);
  const yesterday = addYmd(today, -1);
  const yesterdayRows = active.filter((r) => toArYmd(r.created_at) === yesterday);
  const thisMonth = today.slice(0, 7);
  const monthRows = active.filter((r) => toArYmd(r.created_at).slice(0, 7) === thisMonth);
  const pendingRows = rows.filter((r) => isPending(r.status));
  const todaySum = moneySum(todayRows, 'total_amount');
  const yesterdaySum = moneySum(yesterdayRows, 'total_amount');
  const monthSum = moneySum(monthRows, 'total_amount');
  const pendingSum = moneySum(pendingRows, 'total_amount');
  const monthCancelled = cancelled.filter((r) => toArYmd(r.updated_at || r.created_at).slice(0, 7) === thisMonth);

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
  const periodMonth = new Map();
  for (const r of active) {
    const amount = Number(r.total_amount) || 0;
    bumpHotelMonth(hotelMonth, r.hotel_name, ymdMonth(toArYmd(r.created_at)), 'created', amount);
    bumpHotelMonth(hotelMonth, r.hotel_name, ymdMonth(r.check_in), 'checkin', amount);
    bumpHotelMonth(hotelMonth, r.hotel_name, ymdMonth(r.check_out), 'checkout', amount);
    bumpPeriod(periodMonth, ymdMonth(toArYmd(r.created_at)), 'created', amount);
    bumpPeriod(periodMonth, ymdMonth(r.check_in), 'checkin', amount);
    bumpPeriod(periodMonth, ymdMonth(r.check_out), 'checkout', amount);
  }
  for (const r of cancelled) {
    const amount = Number(r.total_amount) || 0;
    bumpHotelMonth(hotelMonth, r.hotel_name, ymdMonth(toArYmd(r.updated_at || r.created_at)), 'cancelled', amount);
    bumpHotelMonth(hotelMonth, r.hotel_name, ymdMonth(r.check_in), 'cancelled_checkin', amount);
    bumpHotelMonth(hotelMonth, r.hotel_name, ymdMonth(r.check_out), 'cancelled_checkout', amount);
    bumpPeriod(periodMonth, ymdMonth(toArYmd(r.updated_at || r.created_at)), 'cancelled', amount);
  }

  const roundMoney = (row) => {
    const out = { ...row };
    for (const k of Object.keys(out)) {
      if (k.endsWith('_amount')) out[k] = Math.round(Number(out[k]) || 0);
    }
    return out;
  };

  const by_hotel_month = [...hotelMonth.values()]
    .map(roundMoney)
    .sort((a, b) => b.month.localeCompare(a.month) || b.checkin_amount - a.checkin_amount)
    .slice(0, 400);

  const by_month = [...periodMonth.values()].map(roundMoney).sort((a, b) => b.month.localeCompare(a.month)).slice(0, 18);

  const out = {
    error: null,
    currency: 'USD',
    range_from: fromYmd,
    truncated: bundle.truncated,
    axes: {
      created: 'cuando se cargó la reserva en el dashboard',
      checkin: 'fecha de entrada (check-in)',
      checkout: 'fecha de salida (check-out)',
      cancelled: 'pasó a estado Cancelada (updated_at)',
    },
    today: { ymd: today, count: todayRows.length, amount: todaySum.amount, with_amount: todaySum.n },
    yesterday: { ymd: yesterday, count: yesterdayRows.length, amount: yesterdaySum.amount, with_amount: yesterdaySum.n },
    month: {
      ymd: monthStartYmd(today),
      count: monthRows.length,
      amount: monthSum.amount,
      with_amount: monthSum.n,
      confirmed: monthRows.filter((r) => isConfirmed(r.status)).length,
      cancelled_count: monthCancelled.length,
      cancelled_amount: moneySum(monthCancelled, 'total_amount').amount,
    },
    pending: { count: pendingRows.length, amount: pendingSum.amount },
    weeks: weekKeys.map((k) => {
      const w = weekMap.get(k);
      return { ...w, amount: Math.round(w.amount) };
    }),
    by_month,
    by_hotel_month,
    recent: active
      .slice()
      .sort((a, b) => String(b.created_at || '').localeCompare(String(a.created_at || '')))
      .slice(0, 8)
      .map((r) => ({
        code: r.reservation_code || r.id,
        hotel: r.hotel_name || 'Hotel',
        customer: r.customer_name || '',
        amount: Number(r.total_amount) || 0,
        status: r.status || '',
        check_in: r.check_in || '',
        check_out: r.check_out || '',
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

function isActiveHotel(status) {
  const s = String(status || '').trim().toLowerCase();
  if (!s) return true;
  if (/inactiv/.test(s)) return false;
  return /activ/.test(s);
}

function uniqueStrings(values) {
  const out = [];
  const seen = new Set();
  for (const raw of values) {
    const v = String(raw || '').trim();
    if (!v) continue;
    const key = v.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(v);
  }
  return out;
}

function hotelAmenities(h) {
  const fromCol = Array.isArray(h.amenities)
    ? h.amenities
    : String(h.amenities || '')
        .split(',')
        .map((x) => x.trim())
        .filter(Boolean);
  const flags = [];
  if (h.wifi) flags.push('WiFi');
  if (h.desayuno) flags.push('Desayuno');
  if (h.piscina) flags.push('Piscina');
  if (h.estacionamiento) flags.push('Estacionamiento');
  if (h.calefaccion) flags.push('Calefacción');
  if (h.pet_friendly) flags.push('Pet friendly');
  return uniqueStrings([...fromCol, ...flags]).slice(0, 16);
}

function hotelBlob(h) {
  return `${h.name || ''} ${h.location || ''} ${h.region || ''} ${h.ciudad || ''} ${h.description || ''} ${hotelAmenities(h).join(' ')}`;
}

function inferPais(h) {
  const p = String(h.pais || '').trim();
  if (p) return p;
  const blob = hotelBlob(h);
  if (/chile/i.test(blob)) return 'Chile';
  if (/argentin/i.test(blob)) return 'Argentina';
  if (/brasil|brazil/i.test(blob)) return 'Brasil';
  if (/m[eé]xico|mexico/i.test(blob)) return 'México';
  if (/uruguay/i.test(blob)) return 'Uruguay';
  if (/per[uú]/i.test(blob)) return 'Perú';
  if (/caribe|punta cana|canc[uú]n/i.test(blob)) return 'Caribe';
  return 'Sin país';
}

function bumpCount(map, key) {
  const k = String(key || 'Sin dato').trim() || 'Sin dato';
  map[k] = (map[k] || 0) + 1;
}

function mapHotelCatalogRow(h) {
  const amenities = hotelAmenities(h);
  const blob = hotelBlob(h);
  const flags = {
    piscina: Boolean(h.piscina) || /piscina|pileta/i.test(blob),
    termas: /terma|thermal|aguas calientes|aguas termales/i.test(blob),
    spa: /\bspa\b/i.test(blob),
    wifi: Boolean(h.wifi) || /wifi|wi-fi/i.test(blob),
    desayuno: Boolean(h.desayuno) || /desayuno/i.test(blob),
    pet_friendly: Boolean(h.pet_friendly) || /pet.?friendly|mascota/i.test(blob),
    estacionamiento: Boolean(h.estacionamiento) || /estacionamiento|parking/i.test(blob),
  };
  const desc = String(h.description || '').replace(/\s+/g, ' ').trim();
  return {
    name: h.name || 'Sin nombre',
    pais: inferPais(h),
    region: h.region || '',
    ciudad: h.ciudad || '',
    location: h.location || '',
    status: h.status || '',
    activo: isActiveHotel(h.status),
    tipo: String(h.tipo_producto || 'hotel').toLowerCase() === 'paquete' ? 'paquete' : 'hotel',
    mostrar_hotel: h.mostrar_como_hotel !== false,
    mostrar_pack: Boolean(h.mostrar_como_paquete),
    elegido_del_mes: Boolean(h.elegido_del_mes),
    precio_desde: Number(h.precio_desde || h.price) || null,
    rating: Number(h.rating) || null,
    amenities,
    flags,
    description: desc.slice(0, 180),
  };
}

async function fetchHotels() {
  const selects = [
    'id,name,location,status,pais,region,ciudad,tipo_producto,mostrar_como_hotel,mostrar_como_paquete,amenities,wifi,desayuno,piscina,estacionamiento,calefaccion,pet_friendly,precio_desde,price,rating,description,elegido_del_mes',
    'id,name,location,status,pais,region,amenities,precio_desde,description',
    'id,name,location,status,pais,region',
    'id,name,location,status',
  ];
  let items = [];
  let lastError = null;
  for (const select of selects) {
    const { ok, status, data } = await supabaseSelect(
      'hotels',
      `select=${select}&order=name.asc&limit=500`
    );
    if (ok && Array.isArray(data)) {
      items = data;
      lastError = null;
      break;
    }
    lastError = status === 0 ? 'Falta SUPABASE_ANON_KEY' : `Supabase hoteles ${status}`;
  }
  if (lastError) {
    return { error: lastError, items: [], count: 0 };
  }
  const mapped = items.map(mapHotelCatalogRow).filter((h) => h.name && h.name !== 'Sin nombre');
  const activos = mapped.filter((h) => h.activo);
  const by_pais = {};
  const by_pais_activos = {};
  const by_tipo = {};
  const by_region = {};
  const by_amenity = { piscina: 0, termas: 0, spa: 0, wifi: 0, desayuno: 0, pet_friendly: 0 };
  for (const h of mapped) {
    bumpCount(by_pais, h.pais);
    bumpCount(by_tipo, h.tipo);
    if (h.region) bumpCount(by_region, `${h.pais} / ${h.region}`);
    if (h.activo) bumpCount(by_pais_activos, h.pais);
  }
  for (const h of activos) {
    if (h.flags.piscina) by_amenity.piscina += 1;
    if (h.flags.termas) by_amenity.termas += 1;
    if (h.flags.spa) by_amenity.spa += 1;
    if (h.flags.wifi) by_amenity.wifi += 1;
    if (h.flags.desayuno) by_amenity.desayuno += 1;
    if (h.flags.pet_friendly) by_amenity.pet_friendly += 1;
  }
  return {
    error: null,
    currency_note: 'precio_desde puede estar incompleto; no inventar tarifas.',
    count: mapped.length,
    count_activos: activos.length,
    count_inactivos: mapped.length - activos.length,
    by_pais,
    by_pais_activos,
    by_tipo,
    by_region,
    by_amenity,
    items: mapped,
  };
}

async function fetchPromotions() {
  const { ok, status, data } = await supabaseSelect(
    'promotions',
    'select=id,name,status,discount,start_date,end_date,hotel_id&order=end_date.desc&limit=80'
  );
  if (!ok) {
    return { error: status === 0 ? 'Falta SUPABASE_ANON_KEY' : `Supabase promociones ${status}`, items: [], count: 0 };
  }
  const rows = Array.isArray(data) ? data : [];
  const today = arYmd();
  const items = rows.map((p) => ({
    name: p.name || '',
    status: p.status || '',
    discount: Number(p.discount) || 0,
    start_date: p.start_date || '',
    end_date: p.end_date || '',
    vigente: String(p.status || '').toLowerCase() === 'active' && (!p.end_date || String(p.end_date) >= today),
  }));
  return {
    error: null,
    count: items.length,
    vigentes: items.filter((p) => p.vigente).length,
    items: items.slice(0, 40),
  };
}

function ideasFromSnapshot({ health, visits, flor, sales, mail, ads, consultas }) {
  const ideas = [];
  const failed = (health || []).filter((r) => !r.ok);
  if (failed.length) {
    ideas.push(`Atender ${failed.length} chequeo(s) en rojo: ${failed.map((r) => r.name).join(', ')}.`);
  }
  if (visits?.error) ideas.push(`Visitas web sin datos: ${visits.error}`);
  if (consultas?.error) ideas.push(`Consultas web WhatsApp sin datos: ${consultas.error}`);
  else if (consultas?.last_7d?.count === 0 && Number(visits?.last_7d?.visitors || 0) > 20) {
    ideas.push('Hubo visitas a la web en 7 días y 0 consultas WhatsApp del botón (1580). Revisar el CTA.');
  }
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
  if (ads && !ads.google?.connected && !ads.meta?.connected) {
    ideas.push('Marketing: conectar Google Ads y Meta (env en EasyPanel) para que ANA lea gasto, CPC y campañas reales.');
  } else if (ads?.google?.connected && ads.google.prev_7d?.spend > 0 && ads.google.last_7d?.spend > ads.google.prev_7d.spend * 2.5) {
    ideas.push(
      `Google Ads: el gasto de 7 días (${ads.google.currency} ${ads.google.last_7d.spend}) superó 2.5× la semana previa.`
    );
  }
  const meta7 = ads?.meta?.metrics_summary || ads?.meta?.last_7d;
  if (ads?.meta?.connected && meta7) {
    if (Number(meta7.frequency) > 3.5) {
      ideas.push(
        `Meta: frecuencia ${meta7.frequency} en 7 días (creativo saturado). Rotar placas/video.`
      );
    }
    if (Number(meta7.landing_vs_link_pct) > 0 && Number(meta7.landing_vs_link_pct) < 60) {
      ideas.push(
        `Meta: solo ${meta7.landing_vs_link_pct}% de los clics al enlace llega a la landing. Revisar velocidad de checkin24hs.com.`
      );
    }
    const worst = ads.meta.breakdown_highlights?.worst_placement;
    if (worst && /audience_network/i.test(String(worst))) {
      ideas.push('Meta: Audience Network está entre los peores placements. Recortar presupuesto ahí.');
    }
    const prevCpl = Number(ads.meta.prev_7d?.cost_per_messaging || 0);
    const nowCpl = Number(meta7.cost_per_messaging || 0);
    if (prevCpl > 0 && nowCpl > prevCpl * 1.2) {
      const pct = Math.round(((nowCpl / prevCpl) - 1) * 100);
      ideas.push(`Meta: el costo por mensaje subió ${pct}% vs la semana previa (${nowCpl} vs ${prevCpl}).`);
    }
  }
  if (!ideas.length) {
    ideas.push('Chequeos en verde. Ocupación hotelera no está en la base.');
  }
  return ideas.slice(0, 8);
}

async function buildSnapshot() {
  const generated_at = new Date().toISOString();
  const timezone = 'America/Argentina/Buenos_Aires';
  const [health, visits, flor, sales, hotels, promotions, mail, ads, consultas] = await Promise.all([
    fetchHealth(),
    fetchVisitStats(),
    fetchWhatsappChatStats(),
    fetchSales(),
    fetchHotels(),
    fetchPromotions(),
    fetchInbox(20),
    fetchAdsSnapshot(),
    fetchWebConsultas(),
  ]);
  let copilot = { connected: false, reason: 'sin cargar' };
  try {
    const { boardSummary } = require('./copilot');
    copilot = { connected: true, ...(await boardSummary()) };
  } catch (e) {
    copilot = { connected: false, error: e.message || String(e) };
  }
  const snapshot = {
    agent: 'ANA',
    generated_at,
    timezone,
    ymd: arYmd(),
    modules: {
      monitor: { connected: true, checks: health },
      dashboard: sales.error ? { connected: false, error: sales.error } : { connected: true, sales },
      web: {
        connected: !visits.error,
        error: visits.error || null,
        visits,
        consultas,
      },
      flor: flor.error ? { connected: false, error: flor.error, source: flor.source } : { connected: true, source: flor.source, flor },
      ads,
      copilot,
      webmail: mail.connected
        ? { connected: true, mail }
        : { connected: false, reason: mail.reason || 'IMAP no disponible', mail },
      occupancy: {
        connected: false,
        reason: 'No hay PMS ni ocupación real por hotel en Supabase (Checkin24hs representa, no opera el hotel).',
      },
      empresa: hotels.error
        ? { connected: false, error: hotels.error, promotions }
        : { connected: true, hotels, promotions },
    },
    ideas: ideasFromSnapshot({ health, visits, flor, sales, mail, ads, consultas }),
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

async function supabasePatch(table, query, body) {
  if (!SUPABASE_ANON_KEY) {
    return { ok: false, status: 0, data: 'Falta SUPABASE_ANON_KEY' };
  }
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}`, {
    method: 'PATCH',
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
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
  toArYmd,
  supabaseSelect,
  supabaseRpc,
  supabaseInsert,
  supabasePatch,
};
