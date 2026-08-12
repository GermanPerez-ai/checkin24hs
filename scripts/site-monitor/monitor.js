#!/usr/bin/env node
/**
 * Monitor Checkin24hs → avisos por WhatsApp
 *
 * Chequea web, dashboard, cotizador y API WhatsApp.
 * Con --digest incluye visitas del día (tabla site_pageviews / RPC site_visit_stats).
 *
 * Uso:
 *   node scripts/site-monitor/monitor.js
 *   node scripts/site-monitor/monitor.js --digest
 *   node scripts/site-monitor/monitor.js --dry-run
 *
 * Variables:
 *   MONITOR_ALERT_PHONE, WHATSAPP_API_URL, MONITOR_WEB_URL, ...
 *   SUPABASE_URL / SUPABASE_ANON_KEY  (para stats de visitas; defaults del proyecto)
 *
 * Nota: /api/send pausa Flor 45 min en el chat del destinatario.
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

async function fetchWhatsappChatStats() {
  const today = arYmd();
  const yesterday = addYmd(today, -1);
  const ranges = [
    { label: 'hoy', ...arDayBounds(today) },
    { label: 'ayer', ...arDayBounds(yesterday) },
  ];
  const out = { today: null, yesterday: null, error: null };

  try {
    for (const r of ranges) {
      const { ok, status, data } = await supabaseRpc('whatsapp_daily_chat_stats', {
        p_from: r.from,
        p_to: r.to,
      });
      if (!ok) {
        out.error =
          status === 404
            ? 'Falta migración 065 (whatsapp_daily_chat_stats) en Supabase'
            : `Supabase ${status}: ${typeof data === 'string' ? data : JSON.stringify(data)}`;
        return out;
      }
      const chatsByLine = lineMapFromArray(data?.new_chats_by_line, 'new_chats');
      const inboundByLine = lineMapFromArray(data?.inbound_by_line, 'inbound_messages');
      const lines = [1, 2, 3, 4].map((line) => ({
        line,
        new_chats: chatsByLine[line] || 0,
        inbound: inboundByLine[line] || 0,
      }));
      const stats = {
        ymd: r.ymd,
        new_chats_total: Number(data?.new_chats_total ?? 0),
        inbound_messages_total: Number(data?.inbound_messages_total ?? 0),
        active_chats_with_inbound: Number(data?.active_chats_with_inbound ?? 0),
        lines,
      };
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
    ideas.push('Chats WA: correr migración 065 (whatsapp_daily_chat_stats) en Supabase.');
  }
  if (slow.length) {
    ideas.push(`Rendimiento: ${slow.map((r) => `${r.name} ${r.ms}ms`).join(', ')}.`);
  }
  if (!failed.length && !visitStats?.error && !waStats?.error) {
    ideas.push('Todo verde. Si visitas=0, confirmá deploy web + migración 064.');
  }
  return ideas.slice(0, 5);
}

function formatWaDayBlock(label, stats) {
  if (!stats) return [];
  const lines = [];
  lines.push(
    `📅 ${label} (${stats.ymd}): *${stats.new_chats_total}* chats nuevos · *${stats.active_chats_with_inbound}* chats activos · ${stats.inbound_messages_total} msgs entrantes`
  );
  for (const L of stats.lines) {
    if (L.new_chats === 0 && L.inbound === 0) continue;
    lines.push(`   · Línea ${L.line}: ${L.new_chats} chats nuevos · ${L.inbound} msgs`);
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
    lines.push('*WhatsApp por línea*');
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
        `💬 Hoy WA: ${waStats.today?.new_chats_total ?? 0} chats nuevos / ${waStats.today?.inbound_messages_total ?? 0} msgs`
      );
      console.log(
        `💬 Ayer WA: ${waStats.yesterday?.new_chats_total ?? 0} chats nuevos / ${waStats.yesterday?.inbound_messages_total ?? 0} msgs`
      );
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
