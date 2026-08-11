#!/usr/bin/env node
/**
 * Monitor Checkin24hs → avisos por WhatsApp
 *
 * Chequea web, dashboard, cotizador y API WhatsApp. Si hay fallos (o con --digest),
 * envía un resumen a tu número vía POST /api/send del servicio whatsapp.
 *
 * Uso:
 *   node scripts/site-monitor/monitor.js
 *   node scripts/site-monitor/monitor.js --digest
 *   node scripts/site-monitor/monitor.js --dry-run
 *
 * Variables de entorno:
 *   MONITOR_ALERT_PHONE   Teléfono E.164 sin + (ej. 54911XXXXXXXX)  ← obligatorio para enviar
 *   WHATSAPP_API_URL      Default https://whatsapp.checkin24hs.com
 *                         En EasyPanel/Docker: http://checkin24hs_whatsapp:3001
 *   MONITOR_WEB_URL       Default https://www.checkin24hs.com
 *   MONITOR_DASHBOARD_URL Default https://dashboard.checkin24hs.com
 *   MONITOR_COTIZADOR_URL Default https://cotizar.checkin24hs.com
 *   MONITOR_ONLY_FAILURES Default 1 (solo avisa si hay errores; --digest siempre avisa)
 *   MONITOR_TIMEOUT_MS    Default 15000
 *
 * Cron ejemplo (cada 6 h en el servidor):
 *   0 star-slash-6 * * *  →  usar cron: minuto 0, cada 6 horas
 *   MONITOR_ALERT_PHONE=54911XXXXXXXX
 *   WHATSAPP_API_URL=http://checkin24hs_whatsapp:3001
 *   node scripts/site-monitor/monitor.js
 *
 * Digest diario (ideas aunque todo esté OK):
 *   node scripts/site-monitor/monitor.js --digest
 *
 * Nota: /api/send pausa Flor 45 min en el chat del destinatario (tu número). Es esperado.
 */

const WEB_URL = (process.env.MONITOR_WEB_URL || 'https://www.checkin24hs.com').replace(/\/$/, '');
const DASHBOARD_URL = (process.env.MONITOR_DASHBOARD_URL || 'https://dashboard.checkin24hs.com').replace(/\/$/, '');
const COTIZADOR_URL = (process.env.MONITOR_COTIZADOR_URL || 'https://cotizar.checkin24hs.com').replace(/\/$/, '');
const WA_API = (process.env.WHATSAPP_API_URL || 'https://whatsapp.checkin24hs.com').replace(/\/$/, '');
const ALERT_PHONE = String(process.env.MONITOR_ALERT_PHONE || '')
  .replace(/^\+/, '')
  .replace(/\D/g, '')
  .trim();
const TIMEOUT_MS = Math.max(3000, parseInt(process.env.MONITOR_TIMEOUT_MS || '15000', 10) || 15000);
const ONLY_FAILURES = process.env.MONITOR_ONLY_FAILURES !== '0' && process.env.MONITOR_ONLY_FAILURES !== 'false';

const args = new Set(process.argv.slice(2));
const DRY_RUN = args.has('--dry-run');
const DIGEST = args.has('--digest');

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

function ideasFromResults(results) {
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
  if (slow.length) {
    ideas.push(`Rendimiento: ${slow.map((r) => `${r.name} ${r.ms}ms`).join(', ')} — revisar TTFB/CDN/imágenes.`);
  }
  if (!failed.length) {
    ideas.push('Todo verde en checks HTTP. Próximo upgrade: Playwright (login dashboard + flujo Reservar).');
    ideas.push('Sumar Sentry en web/dashboard para errores JS reales de usuarios.');
  } else if (!ideas.length) {
    ideas.push('Ver logs EasyPanel del servicio que falló y repetir con --dry-run.');
  }
  return ideas.slice(0, 5);
}

function formatWhatsApp(results) {
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

  for (const r of results) {
    const icon = r.ok ? '✅' : '❌';
    lines.push(`${icon} *${r.name}* — ${r.status || '—'} (${r.ms}ms)`);
    if (!r.ok) {
      for (const issue of r.issues) lines.push(`   · ${issue}`);
      if (r.hint) lines.push(`   💡 ${r.hint}`);
    }
  }

  const ideas = ideasFromResults(results);
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

  const shouldNotify = DIGEST || failed.length > 0 || !ONLY_FAILURES;
  const text = formatWhatsApp(results);

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
