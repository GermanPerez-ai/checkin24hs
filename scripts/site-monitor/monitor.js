#!/usr/bin/env node
/**
 * Monitor Checkin24hs → avisos por WhatsApp
 *
 * Chequea web, dashboard, cotizador y API WhatsApp.
 * Con --digest incluye visitas + WhatsApp por línea + SLA respuesta humana (>5min / promedio).
 *
 * Uso:
 *   node scripts/site-monitor/monitor.js
 *   node scripts/site-monitor/monitor.js --digest
 *   node scripts/site-monitor/monitor.js --dry-run
 *
 * Variables:
 *   MONITOR_ALERT_PHONE, WHATSAPP_API_URL, MONITOR_WEB_URL, ...
 *   SUPABASE_URL / SUPABASE_ANON_KEY  (visitas + chats + SLA)
 *
 * Preferí RPC whatsapp_ops_daily_stats (migración 067); si falta, calcula SLA en cliente.
 */

const WEB_URL = (process.env.MONITOR_WEB_URL || 'https://www.checkin24hs.com').replace(/\/$/, '');
const DASHBOARD_URL = (process.env.MONITOR_DASHBOARD_URL || 'https://dashboard.checkin24hs.com').replace(/\/$/, '');
const COTIZADOR_URL = (process.env.MONITOR_COTIZADOR_URL || 'https://cotizar.checkin24hs.com').replace(/\/$/, '');
const WA_API = (process.env.WHATSAPP_API_URL || 'https://whatsapp.checkin24hs.com').replace(/\/$/, '');
const SUPABASE_URL = (process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co').replace(/\/$/, '');
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4';

const ALERT_PHONE = String(process.env.MONITOR_ALERT_PHONE || '')
  .replace(/^\+/, '')
  .replace(/\D/g, '')
  .trim();
const TIMEOUT_MS = Math.max(3000, parseInt(process.env.MONITOR_TIMEOUT_MS || '15000', 10) || 15000);
const ONLY_FAILURES = process.env.MONITOR_ONLY_FAILURES !== '0' && process.env.MONITOR_ONLY_FAILURES !== 'false';

const args = new Set(process.argv.slice(2));
const DRY_RUN = args.has('--dry-run');
const DIGEST = args.has('--digest');

/** YYYY-MM-DD en zona Argentina */
function arYmd(date = new Date()) {
  return date.toLocaleDateString('en-CA', { timeZone: 'America/Argentina/Buenos_Aires' });
}

function addYmd(ymd, deltaDays) {
  const [y, m, d] = ymd.split('-').map(Number);
  const utc = new Date(Date.UTC(y, m - 1, d + deltaDays));
  return utc.toISOString().slice(0, 10);
}

/** Medianoche Argentina → ISO */
function arDayBounds(ymd) {
  const from = new Date(`${ymd}T00:00:00.000-03:00`);
  const to = new Date(`${addYmd(ymd, 1)}T00:00:00.000-03:00`);
  return { from: from.toISOString(), to: to.toISOString(), ymd };
}

async function supabaseRpc(fnName, body) {
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

async function fetchVisitStats() {
  const today = arYmd();
  const yesterday = addYmd(today, -1);
  const ranges = [
    { label: 'hoy', ...arDayBounds(today) },
    { label: 'ayer', ...arDayBounds(yesterday) },
  ];
  const out = { today: null, yesterday: null, error: null };

  try {
    for (const r of ranges) {
      const { ok, status, data } = await supabaseRpc('site_visit_stats', {
        p_from: r.from,
        p_to: r.to,
      });
      if (!ok) {
        out.error =
          status === 404
            ? 'Falta migración 064 (site_pageviews / site_visit_stats) en Supabase'
            : `Supabase ${status}: ${typeof data === 'string' ? data : JSON.stringify(data)}`;
        return out;
      }
      const stats = {
        ymd: r.ymd,
        visitors: Number(data?.visitors ?? 0),
        pageviews: Number(data?.pageviews ?? 0),
      };
      if (r.label === 'hoy') out.today = stats;
      else out.yesterday = stats;
    }
  } catch (e) {
    out.error = e.message || String(e);
  }
  return out;
}

function fmtDurationSec(sec) {
  if (sec == null || Number.isNaN(Number(sec))) return '—';
  const s = Math.max(0, Math.round(Number(sec)));
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  const r = s % 60;
  if (m < 60) return r ? `${m}m ${r}s` : `${m}m`;
  const h = Math.floor(m / 60);
  const rm = m % 60;
  return rm ? `${h}h ${rm}m` : `${h}h`;
}

function formatWaPhone(phone) {
  const p = String(phone || '').replace(/\D/g, '');
  if (p.length < 8) return '';
  return `···${p.slice(-4)}`;
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
      if (row.phone) phoneByLine[line] = String(row.phone).replace(/\D/g, '');
      slaByLine[line] = {
        measured: Number(row.measured ?? 0),
        avg_sec: row.avg_sec == null ? null : Number(row.avg_sec),
        median_sec: row.median_sec == null ? null : Number(row.median_sec),
        over_5min: Number(row.over_5min ?? 0),
        over_15min: Number(row.over_15min ?? 0),
        phone: phoneByLine[line] || String(row.phone || '').replace(/\D/g, ''),
      };
    }
  }
  const handoffsByLine = lineMapFromArray(data?.handoffs_by_line, 'handoffs');
  const lines = [1, 2, 3, 4].map((line) => ({
    line,
    phone: phoneByLine[line] || slaByLine[line]?.phone || '',
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
    recontacts: Number(data?.recontacts ?? 0),
    handoffs_total: Number(data?.handoffs_total ?? 0),
    top_hotels: Array.isArray(data?.top_hotels) ? data.top_hotels : [],
    lines,
    has_sla: Array.isArray(data?.human_sla_by_line),
  };
}

function medianOf(nums) {
  if (!nums.length) return null;
  const a = [...nums].sort((x, y) => x - y);
  const mid = Math.floor(a.length / 2);
  return a.length % 2 ? a[mid] : Math.round((a[mid - 1] + a[mid]) / 2);
}

async function supabaseSelect(table, query) {
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

/** SLA humano por línea si aún no está la RPC 067. */
async function computeHumanSlaClient(fromIso, toIso) {
  const replyTo = new Date(new Date(toIso).getTime() + 24 * 3600 * 1000).toISOString();
  const select =
    'chat_id,is_from_me,is_from_flor,whatsapp_instance,sent_at,created_at,sender';
  const qIn = `select=${select}&is_from_me=eq.false&sent_at=gte.${fromIso}&sent_at=lt.${toIso}&order=sent_at.asc&limit=5000`;
  const qOut = `select=${select}&is_from_me=eq.true&sent_at=gte.${fromIso}&sent_at=lt.${replyTo}&order=sent_at.asc&limit=5000`;
  const [inn, out] = await Promise.all([
    supabaseSelect('whatsapp_messages', qIn),
    supabaseSelect('whatsapp_messages', qOut),
  ]);
  if (!inn.ok || !out.ok) return null;

  const inbound = Array.isArray(inn.data) ? inn.data : [];
  const outs = Array.isArray(out.data) ? out.data : [];
  const humanOut = outs.filter((m) => !m.is_from_flor);
  const phoneByLine = {};
  for (const m of outs) {
    const line = Number(m.whatsapp_instance || 1);
    const phone = String(m.sender || '').replace(/\D/g, '');
    if (phone.length >= 10 && phone.length <= 15) phoneByLine[line] = phone;
  }

  const byChatHuman = {};
  for (const m of humanOut) {
    const cid = m.chat_id;
    if (!cid) continue;
    if (!byChatHuman[cid]) byChatHuman[cid] = [];
    byChatHuman[cid].push(new Date(m.sent_at || m.created_at).getTime());
  }
  for (const cid of Object.keys(byChatHuman)) byChatHuman[cid].sort((a, b) => a - b);

  const secsByLine = {};
  for (const m of inbound) {
    const cid = m.chat_id;
    const line = Number(m.whatsapp_instance || 1);
    const t0 = new Date(m.sent_at || m.created_at).getTime();
    const times = byChatHuman[cid];
    if (!times || !times.length) continue;
    let reply = null;
    for (const t of times) {
      if (t > t0) {
        reply = t;
        break;
      }
    }
    if (reply == null) continue;
    const sec = (reply - t0) / 1000;
    if (sec < 0 || sec >= 86400) continue;
    if (!secsByLine[line]) secsByLine[line] = [];
    secsByLine[line].push(sec);
  }

  const human_sla_by_line = Object.keys(secsByLine)
    .map(Number)
    .sort((a, b) => a - b)
    .map((line) => {
      const arr = secsByLine[line];
      const sum = arr.reduce((a, b) => a + b, 0);
      return {
        line,
        phone: phoneByLine[line] || '',
        measured: arr.length,
        avg_sec: Math.round(sum / arr.length),
        median_sec: medianOf(arr),
        over_5min: arr.filter((s) => s > 300).length,
        over_15min: arr.filter((s) => s > 900).length,
      };
    });

  return {
    human_sla_by_line,
    line_phones: Object.keys(phoneByLine).map((line) => ({
      line: Number(line),
      phone: phoneByLine[line],
    })),
  };
}

async function fetchWhatsappChatStats() {
  const today = arYmd();
  const yesterday = addYmd(today, -1);
  const ranges = [
    { label: 'hoy', ...arDayBounds(today) },
    { label: 'ayer', ...arDayBounds(yesterday) },
  ];
  const out = { today: null, yesterday: null, error: null, source: null };

  try {
    let useOps = true;
    for (const r of ranges) {
      let data = null;
      if (useOps) {
        const ops = await supabaseRpc('whatsapp_ops_daily_stats', {
          p_from: r.from,
          p_to: r.to,
        });
        if (ops.ok) {
          data = ops.data;
          out.source = 'ops';
        } else if (ops.status === 404) {
          useOps = false;
        } else {
          out.error = `Supabase ${ops.status}: ${typeof ops.data === 'string' ? ops.data : JSON.stringify(ops.data)}`;
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
              ? 'Falta migración 067 (whatsapp_ops_daily_stats) o 065 en Supabase'
              : `Supabase ${legacy.status}: ${typeof legacy.data === 'string' ? legacy.data : JSON.stringify(legacy.data)}`;
          return out;
        }
        data = { ...(legacy.data || {}) };
        const sla = await computeHumanSlaClient(r.from, r.to);
        if (sla) {
          data.human_sla_by_line = sla.human_sla_by_line;
          data.line_phones = sla.line_phones;
          out.source = 'legacy+sla';
        } else {
          out.source = out.source || 'legacy';
        }
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
      method: opts.method || 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: {
        'User-Agent': 'Checkin24hs-SiteMonitor/1.0 (node)',
        Accept: opts.accept || 'text/html,application/json,*/*',
        ...(opts.headers || {}),
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
    if (res.status < 200 || res.status >= 400) {
      if (res.status === 404 && /404 page not found/i.test(bodyText)) {
        issues.push('404 Traefik (endpoint no expuesto públicamente; usá WHATSAPP_API_URL interno en el servidor)');
      } else {
        issues.push(`HTTP ${res.status}`);
      }
    }

    if (opts.expectIncludes) {
      for (const needle of opts.expectIncludes) {
        if (!bodyText.includes(needle)) issues.push(`falta texto "${needle}"`);
      }
    }

    let json = null;
    if (opts.parseJson || opts.expectJsonKeys || opts.expectWhatsappOpen) {
      try {
        json = JSON.parse(bodyText);
      } catch {
        issues.push('respuesta no es JSON válido');
      }
    }
    if (json && opts.expectJsonKeys) {
      for (const key of opts.expectJsonKeys) {
        if (!(key in json)) issues.push(`JSON sin clave "${key}"`);
      }
    }
    if (json && opts.expectWhatsappOpen) {
      if (json.whatsapp && json.whatsapp !== 'open' && json.whatsapp !== 'connected') {
        issues.push(`WhatsApp status="${json.whatsapp}" (esperado open/connected)`);
      }
    }
    if (opts.maxMs && ms > opts.maxMs) {
      issues.push(`lento ${ms}ms (umbral ${opts.maxMs}ms)`);
    }

    return {
      name,
      url,
      ok: issues.length === 0,
      status: res.status,
      ms,
      issues,
      hint: opts.hint || null,
    };
  } catch (e) {
    return {
      name,
      url,
      ok: false,
      status: 0,
      ms: Date.now() - started,
      issues: [e.name === 'AbortError' ? `timeout ${TIMEOUT_MS}ms` : (e.message || String(e))],
      hint: opts.hint || null,
    };
  } finally {
    clearTimeout(timer);
  }
}

function ideasFromResults(results, visitStats, waStats) {
  const ideas = [];
  const failed = results.filter((r) => !r.ok);
  const slow = results.filter((r) => r.ok && r.ms > 4000);

  if (failed.some((r) => r.name.startsWith('Web'))) {
    ideas.push('Revisar deploy de appwebcheckin24hs / Traefik y logs del contenedor web.');
  }
  if (failed.some((r) => r.name.startsWith('Dashboard'))) {
    ideas.push('Revisar servicio dashboard en EasyPanel y que el HTML/BUILD esté al día.');
  }
  if (failed.some((r) => r.name.includes('WhatsApp'))) {
    ideas.push('WhatsApp caído o desconectado: mirar sesión Baileys/QR y reiniciar whatsapp si hace falta.');
  }
  if (failed.some((r) => r.name.startsWith('Cotizador'))) {
    ideas.push('Revisar servicio cotizador en EasyPanel (tráfico de conversión).');
  }
  if (visitStats?.error) {
    ideas.push('Visitas web: correr migración 064 en Supabase y redeploy web.');
  }
  if (waStats?.error) {
    ideas.push('Chats WA: correr migración 067 (whatsapp_ops_daily_stats) en Supabase.');
  }
  const y = waStats?.yesterday;
  if (y?.has_sla) {
    const slowLines = (y.lines || []).filter((L) => L.sla && L.sla.over_5min > 0);
    if (slowLines.length) {
      const parts = slowLines.map(
        (L) => `L${L.line}${formatWaPhone(L.phone) ? ' ' + formatWaPhone(L.phone) : ''}: ${L.sla.over_5min} >5min`
      );
      ideas.push(`SLA empleados: ayer hubo respuestas >5 min (${parts.join('; ')}).`);
    }
  }
  if (slow.length) {
    ideas.push(`Rendimiento: ${slow.map((r) => `${r.name} ${r.ms}ms`).join(', ')}.`);
  }
  if (!failed.length && !visitStats?.error && !waStats?.error) {
    ideas.push('Todo verde. Si visitas=0, confirmá deploy web + migración 064.');
  }
  return ideas.slice(0, 5);
}

function formatLineLabel(L) {
  const tip = formatWaPhone(L.phone);
  return tip ? `L${L.line} ${tip}` : `L${L.line}`;
}

function formatWaDayBlock(label, stats) {
  if (!stats) return [];
  const lines = [];
  lines.push(
    `📅 ${label} (${stats.ymd}): *${stats.new_chats_total}* chats nuevos · *${stats.active_chats_with_inbound}* activos · ${stats.inbound_messages_total} msgs`
  );
  for (const L of stats.lines) {
    if (L.new_chats === 0 && L.inbound === 0 && !(L.sla && L.sla.measured)) continue;
    lines.push(
      `   · ${formatLineLabel(L)}: ${L.new_chats} chats · ${L.inbound} msgs` +
        (L.handoffs ? ` · ${L.handoffs} hand-off` : '')
    );
  }

  // SLA empleados (respuesta humana, excluye Flor)
  const withSla = (stats.lines || []).filter((L) => L.sla && L.sla.measured > 0);
  if (withSla.length) {
    lines.push('   *⏱ Respuesta humana (empleados)*');
    for (const L of withSla) {
      const s = L.sla;
      lines.push(
        `   · ${formatLineLabel(L)}: prom *${fmtDurationSec(s.avg_sec)}* · mediana ${fmtDurationSec(s.median_sec)} · *${s.over_5min}* >5min` +
          (s.over_15min ? ` · ${s.over_15min} >15min` : '') +
          ` (n=${s.measured})`
      );
    }
  } else if (stats.has_sla && !(stats.lines || []).some((L) => L.sla && L.sla.measured > 0)) {
    lines.push('   · Sin respuestas humanas medidas (solo Flor o sin reply)');
  }

  if (stats.handoffs_total > 0) {
    lines.push(`   · Hand-offs Flor→humano: *${stats.handoffs_total}*`);
  }
  if (stats.chats_with_hotel > 0) {
    lines.push(`   · Chats con hotel detectado: ${stats.chats_with_hotel}`);
  }
  if (stats.recontacts > 0) {
    lines.push(`   · Recontactos (ya escribieron antes): ${stats.recontacts}`);
  }
  if (Array.isArray(stats.top_hotels) && stats.top_hotels.length) {
    const top = stats.top_hotels
      .slice(0, 3)
      .map((h) => `${h.hotel_name} (${h.hits})`)
      .join(', ');
    lines.push(`   · Top hoteles: ${top}`);
  }

  const silent = stats.lines.filter((L) => L.new_chats === 0 && L.inbound === 0).map((L) => L.line);
  if (silent.length && silent.length < 4) {
    lines.push(`   · Sin actividad: L${silent.join(', L')}`);
  }
  return lines;
}

function formatWhatsApp(results, visitStats, waStats) {
  const failed = results.filter((r) => !r.ok);
  const okCount = results.length - failed.length;
  const when = new Date().toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' });
  const lines = [];

  if (failed.length) {
    lines.push(`🚨 *Monitor Checkin24hs* — ${failed.length} problema(s)`);
  } else {
    lines.push(`✅ *Monitor Checkin24hs* — ${DIGEST ? 'digest OK' : 'todo OK'}`);
  }
  lines.push(`🕐 ${when}`);
  lines.push(`Checks: ${okCount}/${results.length} OK`);
  lines.push('');

  if (DIGEST || visitStats) {
    lines.push('*Visitas web (www)*');
    if (visitStats?.error) {
      lines.push(`⚠️ Sin datos: ${visitStats.error}`);
    } else {
      const t = visitStats.today;
      const y = visitStats.yesterday;
      if (t) {
        lines.push(`📅 Hoy (${t.ymd}): *${t.visitors}* personas · ${t.pageviews} páginas vistas`);
      }
      if (y) {
        lines.push(`📅 Ayer (${y.ymd}): *${y.visitors}* personas · ${y.pageviews} páginas vistas`);
      }
    }
    lines.push('');
  }

  if (DIGEST || waStats) {
    lines.push('*WhatsApp por línea / número*');
    if (waStats?.error) {
      lines.push(`⚠️ Sin datos: ${waStats.error}`);
    } else {
      lines.push(...formatWaDayBlock('Hoy', waStats.today));
      lines.push(...formatWaDayBlock('Ayer', waStats.yesterday));
    }
    lines.push('');
  }

  for (const r of results) {
    const icon = r.ok ? '✅' : '❌';
    lines.push(`${icon} *${r.name}* — ${r.status || '—'} (${r.ms}ms)`);
    if (!r.ok) {
      for (const issue of r.issues) lines.push(`   · ${issue}`);
      if (r.hint) lines.push(`   💡 ${r.hint}`);
    }
  }

  const ideas = ideasFromResults(results, visitStats, waStats);
  if (ideas.length) {
    lines.push('');
    lines.push('*Ideas / siguientes pasos*');
    ideas.forEach((idea, i) => lines.push(`${i + 1}. ${idea}`));
  }

  lines.push('');
  lines.push('_Site monitor automático_');
  return lines.join('\n');
}

async function sendWhatsApp(text) {
  if (!ALERT_PHONE) {
    throw new Error('Falta MONITOR_ALERT_PHONE (ej. 54911XXXXXXXX)');
  }
  const res = await fetch(`${WA_API}/api/send`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ number: ALERT_PHONE, text }),
  });
  const body = await res.text();
  let json = null;
  try {
    json = body ? JSON.parse(body) : null;
  } catch {
    json = { raw: body };
  }
  if (!res.ok) {
    throw new Error(`WhatsApp API ${res.status}: ${typeof json === 'object' ? JSON.stringify(json) : body}`);
  }
  return json;
}

async function main() {
  console.log(`🔍 Monitor Checkin24hs (timeout ${TIMEOUT_MS}ms)`);
  console.log(`   Web: ${WEB_URL}`);
  console.log(`   Dashboard: ${DASHBOARD_URL}`);
  console.log(`   Cotizador: ${COTIZADOR_URL}`);
  console.log(`   WA API: ${WA_API}`);

  const results = [
    await fetchCheck('Web home', `${WEB_URL}/`, {
      expectIncludes: ['Checkin'],
      maxMs: 8000,
      hint: 'Si falla, deploy web o DNS/Traefik.',
    }),
    await fetchCheck('Dashboard home', `${DASHBOARD_URL}/`, {
      maxMs: 10000,
      hint: 'Si es 502/504, reiniciar dashboard en EasyPanel.',
    }),
    await fetchCheck('Cotizador', `${COTIZADOR_URL}/`, {
      maxMs: 10000,
      hint: 'Servicio cotizador en EasyPanel.',
    }),
    await fetchCheck('WhatsApp health', `${WA_API}/api/health`, {
      accept: 'application/json',
      expectJsonKeys: ['status', 'whatsapp'],
      expectWhatsappOpen: true,
      maxMs: 5000,
      hint: 'Desde tu PC usá --dry-run. En producción: WHATSAPP_API_URL=http://checkin24hs_whatsapp:3001',
    }),
  ];

  const failed = results.filter((r) => !r.ok);
  for (const r of results) {
    console.log(
      `${r.ok ? '✅' : '❌'} ${r.name}: status=${r.status} ${r.ms}ms${r.issues.length ? ' — ' + r.issues.join('; ') : ''}`
    );
  }

  let visitStats = null;
  let waStats = null;
  if (DIGEST || failed.length > 0 || !ONLY_FAILURES) {
    visitStats = await fetchVisitStats();
    if (visitStats.error) console.warn('⚠️ Visitas:', visitStats.error);
    else {
      console.log(
        `👥 Hoy: ${visitStats.today?.visitors ?? 0} personas / ${visitStats.today?.pageviews ?? 0} vistas`
      );
      console.log(
        `👥 Ayer: ${visitStats.yesterday?.visitors ?? 0} personas / ${visitStats.yesterday?.pageviews ?? 0} vistas`
      );
    }

    waStats = await fetchWhatsappChatStats();
    if (waStats.error) console.warn('⚠️ Chats WA:', waStats.error);
    else {
      console.log(
        `💬 Hoy WA: ${waStats.today?.new_chats_total ?? 0} chats nuevos / ${waStats.today?.inbound_messages_total ?? 0} msgs` +
          (waStats.source === 'ops' ? ' [ops+SLA]' : waStats.source === 'legacy+sla' ? ' [SLA cliente]' : ' [legacy]')
      );
      console.log(
        `💬 Ayer WA: ${waStats.yesterday?.new_chats_total ?? 0} chats nuevos / ${waStats.yesterday?.inbound_messages_total ?? 0} msgs`
      );
      for (const day of [waStats.today, waStats.yesterday]) {
        if (!day) continue;
        for (const L of day.lines || []) {
          if (!L.sla || !L.sla.measured) continue;
          console.log(
            `   ⏱ ${day.ymd} ${formatLineLabel(L)}: avg=${fmtDurationSec(L.sla.avg_sec)} over5=${L.sla.over_5min} n=${L.sla.measured}`
          );
        }
      }
    }
  }

  const shouldNotify = DIGEST || failed.length > 0 || !ONLY_FAILURES;
  const text = formatWhatsApp(results, visitStats, waStats);

  if (!shouldNotify) {
    console.log('ℹ️ Sin fallos y ONLY_FAILURES=1 — no se envía WhatsApp.');
    return;
  }

  console.log('——— Mensaje ———');
  console.log(text);
  console.log('———————');

  if (DRY_RUN) {
    console.log('🧪 --dry-run: no se envió WhatsApp.');
    return;
  }

  const sent = await sendWhatsApp(text);
  console.log('📲 WhatsApp enviado:', sent?.success ? 'OK' : JSON.stringify(sent));
}

main().catch((e) => {
  console.error('❌ Monitor error:', e.message || e);
  process.exit(1);
});
