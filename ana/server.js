'use strict';

const path = require('path');
const crypto = require('crypto');
const express = require('express');
const { getSnapshot, supabaseSelect } = require('./collect');
const { compactPlatform } = require('./ads');
const { fetchBody } = require('./mail');
const { runJob } = require('./jobs');
const { buildProposalFromPrompt, buildPromoFromPrompt } = require('./proposals');
const {
  captureFromText,
  listTasks,
  listIdeas,
  patchTask,
  convertIdea,
  boardSummary,
  looksLikeCopilot,
} = require('./copilot');

const PORT = parseInt(process.env.PORT || '8080', 10) || 8080;
const ANA_PASSWORD = String(process.env.ANA_PASSWORD || '').trim();
const SESSION_SECRET = process.env.ANA_SESSION_SECRET || ANA_PASSWORD || 'ana-dev-only';
const COOKIE_NAME = 'ana_session';
const SESSION_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const GEMINI_API_KEY = String(process.env.GEMINI_API_KEY || '').trim();
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const ANA_JOBS_SECRET = String(process.env.ANA_JOBS_SECRET || '').trim();

const SYSTEM_PROMPT = `# SYSTEM PROMPT: ANA - ASISTENTE EJECUTIVO E INTELIGENCIA DE NEGOCIOS

## ROL Y IDENTIDAD
Eres ANA, la Inteligencia de Negocios y Asistente Ejecutiva Central de Checkin24hs. Tu propósito es supervisar, consolidar y analizar información operativa, comercial y técnica de la empresa.

## DIRECTRICES DE RESPUESTA
1. Idioma: Español.
2. Tono: Ejecutivo, claro, conciso, analítico. Sin saludos vacíos.
3. Estructura: Viñetas, negritas y métricas claras. Podés usar markdown simple (**negrita**, listas).
4. En cada análisis, sugerí al menos una acción táctica.
5. NUNCA inventes números. Si un módulo figura connected:false o falta un dato, decí "sin datos" y qué falta conectar.
6. No ejecutes cambios en Ads, WhatsApp, Flor ni mail: esta versión es de consulta. Podés redactar borradores.
7. No mezcles a Flor (chatbot de huéspedes) con vos. El Monitor de sitio es una de tus herramientas.

8. NUNCA reveles claves, tokens, passwords, secretos de sesión, SMTP/IMAP, API keys, ni .env. Si preguntan por eso: "eso no lo expongo". IDs de cuenta Ads (números públicos de la empresa) sí se pueden nombrar si están en el snapshot.

## MÓDULOS
- Dashboard/Supabase: **ingresos de hoteles en USD** (campo total_amount). Nunca los trates como pesos ni los conviertas. Los gastos se cargan en ARS y luego se pasan a USD; el módulo de gastos aún no está en ANA, no inventes tipo de cambio.
- Podés responder VARIAS preguntas en el mismo mensaje (ventas + anulaciones + un hotel + check-in y check-out). Usá secciones con título. No omitas un eje si te pidieron "ambas" o "por separado".
- Ejes de fecha (sales.axes y filas sales.by_hotel_month / sales.by_month). Mes en formato YYYY-MM (agosto 2026 = 2026-08):
  - **created_*** = reservas **cargadas** ese mes (cuándo se ingresó al dashboard).
  - **checkin_*** = venta con **check-in** (entrada) en ese mes. Excluye Cancelada.
  - **checkout_*** = venta con **check-out** (salida) en ese mes. Excluye Cancelada.
  - **cancelled_*** = reservas que **pasaron a Cancelada** ese mes (updated_at).
  - **cancelled_checkin_*** / **cancelled_checkout_*** = canceladas cuyo check-in o check-out cae en ese mes.
- Si preguntan "venta / ingresos / cuánto vendimos" **sin** decir check-in ni check-out: mostrá **check-in y check-out por separado** (dos bloques). Si dicen solo check-in o solo check-out, usá ese eje. Si piden "ambas", los dos. "Cargadas / ingresadas / vendidas en el mes" (cuando se tomó la reserva) = created_*.
- Hotel: filtrá by_hotel_month donde hotel contenga el nombre (Puyehue, Huilo, Corralco, Aguas…). Si hay varias filas del mismo mes, **sumá** count y amount. Si no hay fila: 0 en el recorte (sales.range_from), no digas que no podés desglosar.
- Anulaciones del mes: sales.by_month[month].cancelled_count y cancelled_amount, o sales.month.cancelled_* para el mes actual. "Anulación pedida" NO cuenta como anulada: solo estado **Cancelada**. Pedidos abiertos: pending_cancel.
- Si el SNAPSHOT trae **sales_focus** y ok=true, esos totales ya están filtrados para ESTA pregunta: respondé **por cada slice** (no mezcles hotel, mes ni eje). No recalcules a mano ni cambies el redondeo. Si un slice tiene matched_rows=0, decí 0 en el recorte (sales.range_from).
- Recorte: sales.range_from; si truncated=true, advertí que el listado puede estar topeado.
- Web: visitas (site_pageviews) y UTM.
- Ads: si ads.google.connected o ads.meta.connected, usá last_7d / last_30d / campaigns (spend, clicks, impressions, cpc, ctr, conversions, roas) con la currency que traiga cada plataforma. Nunca inventes gasto. Si connected=false, decí qué falta (missing_env o error) y no estimes CPC/ROAS.
- Ads spend/clics: solo de la API. Nunca inventes Ad Spend Anomaly si no hay datos conectados.
- Flor IA / WhatsApp: chats, hand-offs, SLA si viene en el snapshot, estado de L1–L4 (Monitor).
- Webmail: INBOX IMAP de reservas@. Usá summary/preview del cuerpo; no respondas solo con el asunto. Borradores, no envíes.
- Pedidos al hotel: sales.pending_cancel = anulaciones pedidas (y En gestión de anular). sales.pending_modify = modificaciones pedidas. hours_waiting = horas desde el último update. Tu tarea es el seguimiento: si llevan >18 h o el check-in está cerca, insistí en que ventas persiga al hotel o use los botones del dashboard. No marques Cancelada/Modificada vos: eso lo cierra el mail del hotel o ventas.
- Ocupación hotelera: no existe en nuestra base.
- Empresa / catálogo (hotels.*): fuente de verdad de con qué hoteles y packs trabaja Checkin24hs. "Cuántos hoteles en Chile" = hotels.by_pais_activos.Chile (solo Activo). Listá nombres desde hotels.items filtrando pais + activo. Distinguí tipo hotel vs paquete (by_tipo).
- Amenities: hotels.by_amenity (conteos de activos) y flags por ítem: piscina (pileta), termas (aguas termales), spa, wifi, desayuno, pet_friendly. Termas se infiere de nombre/amenities/descripcion (no hay columna aparte). Si preguntan "cuáles", listá los nombres, no solo el número.
- Si viene **catalog_focus** y ok=true, usá count + names de ese recorte primero.
- Promociones del dashboard: hotels no las trae; están en promotions (vigentes vs total). Si promotions.error, decí sin datos.
- No inventes ocupación, comisiones por hotel (no hay columna de comisión en el catálogo) ni tarifas que no estén en precio_desde.
- Propuestas B2B y packs promocionales: si el usuario pide una propuesta de representación o contenido promocional, el sistema genera HTML/JSON aparte; vos resumí y no inventes tarifas que no estén en el snapshot.
- Copiloto / agenda: snapshot.copilot (counts, p1, meetings_today). Crear con "anotá / agendame / idea:". Calendar: copilot.google_calendar.connected.
- Alertas: flash 08:00, fricción Flor cada 2 h, QA semanal, cierre 19:00. No dispares envíos desde el chat.

Abajo tenés un SNAPSHOT JSON real. Basate solo en eso y en el mensaje del usuario.`;

const app = express();
app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(express.json({ limit: '15mb' }));

function signSession(exp) {
  const payload = String(exp);
  const sig = crypto.createHmac('sha256', SESSION_SECRET).update(payload).digest('hex');
  return `${payload}.${sig}`;
}

function verifySession(token) {
  if (!token || typeof token !== 'string') return false;
  const i = token.indexOf('.');
  if (i < 1) return false;
  const payload = token.slice(0, i);
  const sig = token.slice(i + 1);
  const expected = crypto.createHmac('sha256', SESSION_SECRET).update(payload).digest('hex');
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  if (!crypto.timingSafeEqual(a, b)) return false;
  const exp = Number(payload);
  return Number.isFinite(exp) && Date.now() < exp;
}

function readCookie(req, name) {
  const raw = req.headers.cookie || '';
  for (const part of raw.split(';')) {
    const [k, ...rest] = part.trim().split('=');
    if (k === name) return decodeURIComponent(rest.join('=') || '');
  }
  return '';
}

function requestIsHttps(req) {
  if (process.env.ANA_COOKIE_SECURE === '0') return false;
  if (process.env.ANA_COOKIE_SECURE === '1') return true;
  const xf = String(req.headers['x-forwarded-proto'] || '').split(',')[0].trim();
  return xf === 'https' || Boolean(req.secure);
}

function setSessionCookie(req, res, token) {
  const parts = [
    `${COOKIE_NAME}=${encodeURIComponent(token)}`,
    'Path=/',
    'HttpOnly',
    'SameSite=Lax',
    `Max-Age=${Math.floor(SESSION_TTL_MS / 1000)}`,
  ];
  if (requestIsHttps(req)) parts.push('Secure');
  res.setHeader('Set-Cookie', parts.join('; '));
}

function clearSessionCookie(res) {
  res.setHeader('Set-Cookie', `${COOKIE_NAME}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`);
}

function requireAuth(req, res, next) {
  if (!ANA_PASSWORD) {
    if (process.env.ANA_ALLOW_OPEN === '1') return next();
    return res.status(503).json({
      error: 'ANA_PASSWORD no configurada. Definila en EasyPanel antes de usar ANA en producción.',
    });
  }
  const token = readCookie(req, COOKIE_NAME);
  if (!verifySession(token)) {
    return res.status(401).json({ error: 'No autenticado' });
  }
  next();
}

function jobsSecretOk(req) {
  if (!ANA_JOBS_SECRET) return false;
  const given = String(
    req.headers['x-ana-jobs-secret'] ||
      req.headers['authorization']?.replace(/^Bearer\s+/i, '') ||
      req.query.secret ||
      req.body?.secret ||
      ''
  ).trim();
  if (!given || given.length !== ANA_JOBS_SECRET.length) return false;
  try {
    return crypto.timingSafeEqual(Buffer.from(given), Buffer.from(ANA_JOBS_SECRET));
  } catch {
    return false;
  }
}

function requireJobAuth(req, res, next) {
  if (jobsSecretOk(req)) return next();
  return requireAuth(req, res, next);
}

function detectCommercialIntent(text) {
  const t = String(text || '').toLowerCase();
  if (/arm[aá].{0,60}propuesta|propuesta de representaci|comisi[oó]n del\s*\d/.test(t)) return 'proposal';
  if (/contenido promocional|tarjeta digital|itinerario|pack promocional|paso cardenal|vcard/.test(t)) {
    return 'promo';
  }
  return null;
}

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'ana',
    gemini: Boolean(GEMINI_API_KEY),
    authRequired: Boolean(ANA_PASSWORD),
    jobs: Boolean(ANA_JOBS_SECRET),
  });
});

app.get('/api/me', (req, res) => {
  if (!ANA_PASSWORD) {
    return res.json({ ok: process.env.ANA_ALLOW_OPEN === '1', authRequired: true, configured: false });
  }
  const token = readCookie(req, COOKIE_NAME);
  res.json({ ok: verifySession(token), authRequired: true, configured: true });
});

app.post('/api/login', (req, res) => {
  if (!ANA_PASSWORD) {
    return res.status(503).json({ error: 'ANA_PASSWORD no configurada en el servidor' });
  }
  const password = String(req.body?.password || '');
  const a = Buffer.from(password);
  const b = Buffer.from(ANA_PASSWORD);
  const match = a.length === b.length && crypto.timingSafeEqual(a, b);
  if (!match) return res.status(401).json({ error: 'Clave incorrecta' });
  setSessionCookie(req, res, signSession(Date.now() + SESSION_TTL_MS));
  res.json({ ok: true });
});

app.post('/api/logout', (_req, res) => {
  clearSessionCookie(res);
  res.json({ ok: true });
});

app.get('/api/snapshot', requireAuth, async (_req, res) => {
  try {
    const snap = await getSnapshot();
    res.json(snap);
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.get('/api/digest', requireAuth, async (_req, res) => {
  try {
    const snap = await getSnapshot({ force: true });
    res.json(snap);
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.get('/api/mail/:uid', requireAuth, async (req, res) => {
  try {
    const mail = await fetchBody(req.params.uid);
    res.json(mail);
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.get('/api/alerts', requireAuth, async (_req, res) => {
  try {
    const { ok, status, data } = await supabaseSelect(
      'ana_alerts_log',
      'select=id,kind,fingerprint,channel,sent_ok,error,created_at,payload&order=created_at.desc&limit=40'
    );
    if (!ok) return res.status(status || 500).json({ error: 'No se pudo leer ana_alerts_log', status, data });
    res.json({ ok: true, items: Array.isArray(data) ? data : [] });
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.get('/api/qa', requireAuth, async (_req, res) => {
  try {
    const { ok, status, data } = await supabaseSelect(
      'ana_qa_flor_ia',
      'select=id,period_from,period_to,metrics,gaps,prompt_suggestions,created_at&order=created_at.desc&limit=8'
    );
    if (!ok) return res.status(status || 500).json({ error: 'No se pudo leer ana_qa_flor_ia', status, data });
    res.json({ ok: true, items: Array.isArray(data) ? data : [] });
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.post('/api/jobs/:name', requireJobAuth, async (req, res) => {
  const name = String(req.params.name || '').trim();
  try {
    const result = await runJob(name);
    const code = result?.ok === false ? 500 : 200;
    res.status(code).json(result);
  } catch (e) {
    console.warn('ANA job route', name, e.message || e);
    res.status(200).json({ ok: false, error: e.message || String(e), job: name });
  }
});

app.get('/api/copilot/board', requireAuth, async (_req, res) => {
  try {
    const [board, tasks, ideas] = await Promise.all([boardSummary(), listTasks({}), listIdeas()]);
    res.json({
      ok: true,
      google_calendar: board.google_calendar,
      counts: board.counts,
      tasks: tasks.items,
      ideas: ideas.items,
      error: board.error || tasks.error || ideas.error || null,
    });
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.post('/api/copilot/capture', requireAuth, async (req, res) => {
  try {
    const text = await resolveCaptureInput(req.body || {});
    const out = await captureFromText({ text, source: req.body?.source || 'web_dashboard' });
    res.json(out);
  } catch (e) {
    res.status(400).json({ error: e.message || String(e) });
  }
});

app.post('/api/copilot/inbound', requireJobAuth, async (req, res) => {
  try {
    const text = await resolveCaptureInput(req.body || {});
    const out = await captureFromText({
      text,
      source: 'whatsapp',
      confirmWhatsApp: true,
    });
    res.json(out);
  } catch (e) {
    res.status(400).json({ error: e.message || String(e) });
  }
});

app.patch('/api/copilot/tasks/:id', requireAuth, async (req, res) => {
  try {
    const item = await patchTask(req.params.id, req.body || {});
    res.json({ ok: true, item });
  } catch (e) {
    res.status(400).json({ error: e.message || String(e) });
  }
});

app.post('/api/copilot/ideas/:id/convert', requireAuth, async (req, res) => {
  try {
    const out = await convertIdea(req.params.id);
    res.json(out);
  } catch (e) {
    res.status(400).json({ error: e.message || String(e) });
  }
});

app.post('/api/proposal', requireAuth, async (req, res) => {
  const text = String(req.body?.text || req.body?.message || '').trim();
  if (!text) return res.status(400).json({ error: 'Falta text' });
  try {
    const snap = await getSnapshot();
    const kind = detectCommercialIntent(text) || 'proposal';
    const artifact =
      kind === 'promo'
        ? await buildPromoFromPrompt(text, snap.ymd)
        : await buildProposalFromPrompt(text, snap.ymd);
    res.json({ ok: true, ...artifact });
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

function foldEs(value) {
  return String(value || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{M}/gu, '');
}

const MONTH_NAME_TO_MM = {
  enero: '01',
  febrero: '02',
  marzo: '03',
  abril: '04',
  mayo: '05',
  junio: '06',
  julio: '07',
  agosto: '08',
  septiembre: '09',
  setiembre: '09',
  octubre: '10',
  noviembre: '11',
  diciembre: '12',
};

function parseMonthsFromQuestion(text, ymd) {
  const year = String(ymd || '').slice(0, 4) || '2026';
  const current = String(ymd || '').slice(0, 7);
  const t = foldEs(text);
  const named = new Set();
  const currentMentioned = /\b(este mes|el mes|mes actual|en el mes)\b/.test(t);
  for (const m of t.matchAll(/\b(20\d{2})-(\d{2})\b/g)) {
    named.add(`${m[1]}-${m[2]}`);
  }
  for (const [name, mm] of Object.entries(MONTH_NAME_TO_MM)) {
    if (!t.includes(name)) continue;
    const withYear = t.match(new RegExp(`${name}\\s+(20\\d{2})`)) || t.match(new RegExp(`(20\\d{2})\\s+${name}`));
    named.add(`${withYear ? withYear[1] : year}-${mm}`);
  }
  const namedList = [...named];
  const all = [...new Set([...(currentMentioned && current ? [current] : []), ...namedList])];
  return { current, currentMentioned, named: namedList, all };
}

function hotelNamesFromSales(sales, snap) {
  const names = new Set();
  for (const row of sales.by_hotel_month || []) {
    if (row.hotel) names.add(String(row.hotel));
  }
  const catalog = snap?.modules?.empresa?.hotels?.items || [];
  for (const h of catalog) {
    if (h?.name) names.add(String(h.name));
  }
  return [...names];
}

function parseHotelsFromQuestion(text, names) {
  const t = foldEs(text);
  const stop = new Set([
    'hotel',
    'hoteles',
    'termas',
    'check',
    'checkin',
    'checkout',
    'reserva',
    'reservas',
    'venta',
    'agosto',
    'septiembre',
    'setiembre',
  ]);
  const hits = [];
  for (const name of names) {
    const n = foldEs(name);
    if (n.length >= 8 && t.includes(n)) {
      hits.push(name);
      continue;
    }
    const tokens = n.split(/[^a-z0-9]+/).filter((w) => w.length >= 5 && !stop.has(w));
    if (tokens.some((w) => t.includes(w))) hits.push(name);
  }
  const aliases = [
    ['puyehue', /puyehue|termas de puyehue/],
    ['huilo', /huilo/],
    ['corralco', /corralco/],
    ['aguas calientes', /aguas calientes|aguascalientes/],
  ];
  for (const [needle, re] of aliases) {
    if (!re.test(t)) continue;
    for (const name of names) {
      if (foldEs(name).includes(needle) && !hits.includes(name)) hits.push(name);
    }
  }
  return [...new Set(hits)];
}

function parseAxesFromQuestion(text) {
  const t = foldEs(text);
  const checkin = /check.?in|entrada|llegada/.test(t);
  const checkout = /check.?out|salida/.test(t);
  const created = /cargad|ingresad|cuando se tom|fecha de carga|fecha de venta/.test(t);
  const cancelled = /anulaci|cancelad/.test(t);
  const venta = /venta|ingreso|cuanto vend|cuanto factur/.test(t);
  const axes = [];
  if (checkin) axes.push('checkin');
  if (checkout) axes.push('checkout');
  if (created) axes.push('created');
  if (cancelled) axes.push('cancelled');
  if ((venta || /ambas|por separado/.test(t)) && !checkin && !checkout && !created) {
    axes.push('checkin', 'checkout');
  }
  return [...new Set(axes)];
}

function sumAxisRows(rows, axis) {
  let count = 0;
  let amount = 0;
  for (const row of rows) {
    count += Number(row[`${axis}_count`] || 0);
    amount += Number(row[`${axis}_amount`] || 0);
  }
  return { count, amount: Math.round(amount) };
}

function focusSlice(topic, hotels, months, axes, rows) {
  const totals = {};
  for (const axis of axes) totals[axis] = sumAxisRows(rows, axis);
  return {
    topic,
    hotels,
    months,
    axes,
    totals,
    matched_rows: rows.length,
  };
}

function focusSalesFromQuestion(userText, sales, snap) {
  const text = String(userText || '').trim();
  if (!text || !sales || sales.error) return null;
  const t = foldEs(text);
  const months = parseMonthsFromQuestion(text, snap?.ymd);
  const hotels = parseHotelsFromQuestion(text, hotelNamesFromSales(sales, snap));
  const axes = parseAxesFromQuestion(text);
  const wantsOpen = /pedida|abiert|pendiente/.test(t) && /anulaci|modific/.test(t);
  if (!months.all.length && !months.currentMentioned && !hotels.length && !axes.length && !wantsOpen) return null;

  const hotelRows = sales.by_hotel_month || [];
  const companyRows = sales.by_month || [];
  const saleAxes = axes.filter((a) => a !== 'cancelled');
  const slices = [];

  if (axes.includes('cancelled') || wantsOpen) {
    const cancelMonths =
      months.currentMentioned || !months.named.length ? [months.current] : months.named;
    const rows = companyRows.filter((r) => cancelMonths.includes(r.month));
    slices.push(focusSlice('anulaciones_empresa', ['(toda la empresa)'], cancelMonths, ['cancelled'], rows));
  }

  if (hotels.length) {
    const hotelMonths = months.named.length ? months.named : [months.current];
    const axesForHotel = saleAxes.length ? saleAxes : ['checkin', 'checkout'];
    const rows = hotelRows.filter(
      (r) => hotels.some((h) => foldEs(r.hotel) === foldEs(h)) && hotelMonths.includes(r.month)
    );
    slices.push(focusSlice('venta_hotel', hotels, hotelMonths, axesForHotel, rows));
  } else if (saleAxes.length) {
    const companyMonths = months.all.length ? months.all : [months.current];
    const rows = companyRows.filter((r) => companyMonths.includes(r.month));
    slices.push(focusSlice('venta_empresa', ['(toda la empresa)'], companyMonths, saleAxes, rows));
  }

  return {
    ok: slices.length > 0,
    slices,
    open_cancel: wantsOpen || axes.includes('cancelled') ? (sales.pending_cancel || []).length : undefined,
    note: 'Totales ya filtrados para esta pregunta. Respondé por slice, sin mezclar hotel/mes/eje.',
  };
}

function focusCatalogFromQuestion(userText, hotels) {
  const text = String(userText || '').trim();
  if (!text || !hotels || hotels.error || !Array.isArray(hotels.items)) return null;
  const t = foldEs(text);
  const catalogAsk =
    /hotel|pack|paquete|catalog|represent|trabaj|chile|argentin|piscina|pileta|terma|thermal|amenit|wifi|desayuno|mascota|pet.?friendly|spa|cuantos|cuántos/.test(
      t
    );
  if (!catalogAsk) return null;

  const includeInactive = /inactiv/.test(t);
  let rows = hotels.items.filter((h) => (includeInactive ? true : h.activo));

  const paisAliases = [
    ['Chile', /\bchile\b/],
    ['Argentina', /\bargentin/],
    ['Brasil', /\bbrasil|\bbrazil\b/],
    ['México', /\bmexico|\bmexico\b|\bmexic/],
    ['Uruguay', /\buruguay\b/],
    ['Perú', /\bperu\b/],
    ['Caribe', /\bcaribe\b/],
    ['Internacional', /\binternacional/],
  ];
  let pais = null;
  for (const [label, re] of paisAliases) {
    if (re.test(t)) {
      pais = label;
      break;
    }
  }
  if (pais) {
    const needle = foldEs(pais);
    rows = rows.filter((h) => foldEs(h.pais).includes(needle) || foldEs(h.pais) === needle);
  }

  const amenityChecks = [
    ['piscina', /piscina|pileta/, (h) => h.flags?.piscina],
    ['termas', /terma|thermal|aguas termales|aguas calientes/, (h) => h.flags?.termas],
    ['spa', /\bspa\b/, (h) => h.flags?.spa],
    ['wifi', /\bwifi\b|wi-fi/, (h) => h.flags?.wifi],
    ['desayuno', /desayuno/, (h) => h.flags?.desayuno],
    ['pet_friendly', /pet.?friendly|mascota/, (h) => h.flags?.pet_friendly],
  ];
  const amenities = [];
  for (const [key, re, pred] of amenityChecks) {
    if (!re.test(t)) continue;
    amenities.push(key);
    rows = rows.filter(pred);
  }

  const tipoPack = /paquete|pack/.test(t) && !/hotel/.test(t);
  const tipoHotel = /\bhoteles?\b/.test(t) && !/paquete|pack/.test(t);
  if (tipoPack) rows = rows.filter((h) => h.tipo === 'paquete');
  if (tipoHotel) rows = rows.filter((h) => h.tipo === 'hotel');

  if (!pais && !amenities.length && !tipoPack && !tipoHotel && !/cuantos|cuántos|catalog|represent|trabajamos/.test(t)) {
    return null;
  }

  return {
    ok: true,
    only_activos: !includeInactive,
    pais,
    amenities,
    tipo: tipoPack ? 'paquete' : tipoHotel ? 'hotel' : null,
    count: rows.length,
    names: rows.map((h) => h.name).slice(0, 80),
    note: 'Recorte del catálogo para esta pregunta. Usalo primero.',
  };
}

function compactSnapshot(snap, userText) {
  const sales = snap.modules?.dashboard?.sales;
  const florToday = snap.modules?.flor?.flor?.today;
  const florY = snap.modules?.flor?.flor?.yesterday;
  const visits = snap.modules?.web?.visits;
  return {
    ymd: snap.ymd,
    generated_at: snap.generated_at,
    ideas: snap.ideas,
    health: (snap.modules?.monitor?.checks || []).map((c) => ({
      name: c.name,
      ok: c.ok,
      ms: c.ms,
      issues: c.issues,
      meta: c.meta,
    })),
    sales: sales
      ? {
          currency: sales.currency || 'USD',
          range_from: sales.range_from,
          truncated: sales.truncated || false,
          today: sales.today,
          yesterday: sales.yesterday,
          month: sales.month,
          pending: sales.pending,
          weeks: sales.weeks,
          axes: sales.axes || null,
          by_month: sales.by_month || [],
          by_hotel_month: sales.by_hotel_month || [],
          recent: sales.recent,
          pending_cancel: sales.pending_cancel || [],
          pending_modify: sales.pending_modify || [],
          error: sales.error,
          sales_focus: focusSalesFromQuestion(userText, sales, snap),
        }
      : { error: snap.modules?.dashboard?.error || 'sin datos' },
    visits: visits || { error: snap.modules?.web?.error || 'sin datos' },
    flor: {
      source: snap.modules?.flor?.source || null,
      error: snap.modules?.flor?.error || null,
      today: florToday
        ? {
            ymd: florToday.ymd,
            new_chats_total: florToday.new_chats_total,
            inbound_messages_total: florToday.inbound_messages_total,
            active_chats_with_inbound: florToday.active_chats_with_inbound,
            handoffs_total: florToday.handoffs_total,
            funnel: florToday.funnel,
            abandon: florToday.abandon,
            ticket: florToday.ticket,
            top_hotels: florToday.top_hotels,
            lines: florToday.lines,
          }
        : null,
      yesterday: florY
        ? {
            ymd: florY.ymd,
            new_chats_total: florY.new_chats_total,
            inbound_messages_total: florY.inbound_messages_total,
            handoffs_total: florY.handoffs_total,
            funnel: florY.funnel,
            abandon: florY.abandon,
            lines: florY.lines,
          }
        : null,
    },
    hotels: snap.modules?.empresa?.hotels
      ? {
          error: snap.modules.empresa.hotels.error || null,
          count: snap.modules.empresa.hotels.count,
          count_activos: snap.modules.empresa.hotels.count_activos,
          count_inactivos: snap.modules.empresa.hotels.count_inactivos,
          by_pais: snap.modules.empresa.hotels.by_pais || {},
          by_pais_activos: snap.modules.empresa.hotels.by_pais_activos || {},
          by_tipo: snap.modules.empresa.hotels.by_tipo || {},
          by_region: snap.modules.empresa.hotels.by_region || {},
          by_amenity: snap.modules.empresa.hotels.by_amenity || {},
          items: (snap.modules.empresa.hotels.items || []).map((h) => ({
            name: h.name,
            pais: h.pais,
            region: h.region,
            ciudad: h.ciudad,
            location: h.location,
            status: h.status,
            activo: h.activo,
            tipo: h.tipo,
            amenities: h.amenities,
            flags: h.flags,
            description: h.description,
            precio_desde: h.precio_desde,
            elegido_del_mes: h.elegido_del_mes,
          })),
          catalog_focus: focusCatalogFromQuestion(userText, snap.modules.empresa.hotels),
        }
      : { error: snap.modules?.empresa?.error || 'sin datos' },
    promotions: snap.modules?.empresa?.promotions || { error: 'sin datos' },
    mail: snap.modules?.webmail?.mail
      ? {
          connected: snap.modules.webmail.connected,
          unseen: snap.modules.webmail.mail.unseen,
          urgent: snap.modules.webmail.mail.urgent,
          reason: snap.modules.webmail.reason || snap.modules.webmail.mail.reason,
          messages: (snap.modules.webmail.mail.messages || []).slice(0, 20).map((m) => ({
            uid: m.uid,
            from: m.from,
            subject: m.subject,
            date: m.date,
            unseen: m.unseen,
            priority: m.priority,
            summary: m.summary || '',
            preview: (m.preview || '').slice(0, 400),
          })),
        }
      : { connected: false, reason: snap.modules?.webmail?.reason || 'sin datos' },
    ads: {
      connected: Boolean(snap.modules?.ads?.connected),
      google: compactPlatform(snap.modules?.ads?.google),
      meta: compactPlatform(snap.modules?.ads?.meta),
      reason: snap.modules?.ads?.reason || null,
    },
    copilot: snap.modules?.copilot
      ? {
          connected: snap.modules.copilot.connected,
          google_calendar: snap.modules.copilot.google_calendar || null,
          counts: snap.modules.copilot.counts || null,
          p1: (snap.modules.copilot.p1 || []).slice(0, 12).map((t) => ({
            title: t.title,
            priority: t.priority,
            category: t.category,
            due_date: t.due_date,
            start_time: t.start_time,
            status: t.status,
          })),
          meetings_today: (snap.modules.copilot.meetings_today || []).slice(0, 8).map((t) => ({
            title: t.title,
            start_time: t.start_time,
          })),
          error: snap.modules.copilot.error || null,
        }
      : { connected: false },
    unavailable: {
      occupancy: snap.modules?.occupancy,
    },
  };
}

function geminiTextFrom(json) {
  return String(
    json?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') ||
      json?.candidates?.[0]?.content?.parts?.[0]?.text ||
      ''
  ).trim();
}

function normalizeAudioMime(raw) {
  const m = String(raw || '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  if (m === 'audio/webm' || m === 'video/webm') return 'audio/webm';
  if (m === 'audio/mp4' || m === 'video/mp4' || m === 'audio/m4a' || m === 'audio/x-m4a') return 'audio/mp4';
  if (m === 'audio/mpeg' || m === 'audio/mp3') return 'audio/mp3';
  if (m === 'audio/wav' || m === 'audio/x-wav' || m === 'audio/wave') return 'audio/wav';
  if (m === 'audio/ogg' || m === 'audio/opus') return 'audio/ogg';
  if (m === 'audio/aac' || m === 'audio/aacp') return 'audio/aac';
  return m || 'audio/webm';
}

function normalizeImageMime(raw) {
  const m = String(raw || '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  if (m === 'image/jpg') return 'image/jpeg';
  if (m === 'image/jpeg' || m === 'image/png' || m === 'image/webp' || m === 'image/gif') return m;
  return 'image/jpeg';
}

function stripDataUrl(b64) {
  const s = String(b64 || '').trim();
  const i = s.indexOf('base64,');
  return i >= 0 ? s.slice(i + 7) : s.replace(/\s/g, '');
}

async function transcribeAudio(base64, mimeType) {
  if (!GEMINI_API_KEY) throw new Error('Falta GEMINI_API_KEY para transcribir audio');
  const mime = normalizeAudioMime(mimeType);
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: {
        parts: [
          {
            text: 'Transcribí el audio al español rioplatense. Devolvé SOLO el texto hablado, sin comillas, sin título y sin comentarios. Si no se entiende, devolvé vacío.',
          },
        ],
      },
      contents: [
        {
          role: 'user',
          parts: [{ inline_data: { mime_type: mime, data: stripDataUrl(base64) } }],
        },
      ],
      generationConfig: { temperature: 0, maxOutputTokens: 2048 },
    }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json?.error?.message || `Gemini audio ${res.status}`);
  return geminiTextFrom(json);
}

async function extractImageNotes(base64, mimeType) {
  if (!GEMINI_API_KEY) throw new Error('Falta GEMINI_API_KEY para leer la imagen');
  const mime = normalizeImageMime(mimeType);
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: {
        parts: [
          {
            text:
              'Leé la imagen (stand, tarjeta, captura de WhatsApp, nota o foto de feria). Extraé nombres, empresa, fechas, horas, stand, teléfono, mail y cualquier pedido de reunión o tarea. Devolvé un párrafo en español listo para agendar, sin JSON, sin markdown. Si no hay texto útil, describí lo que se ve en una frase.',
          },
        ],
      },
      contents: [
        {
          role: 'user',
          parts: [{ inline_data: { mime_type: mime, data: stripDataUrl(base64) } }],
        },
      ],
      generationConfig: { temperature: 0, maxOutputTokens: 2048 },
    }),
    signal: AbortSignal.timeout(25000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json?.error?.message || `Gemini imagen ${res.status}`);
  return geminiTextFrom(json);
}

async function resolveCaptureInput(body) {
  const bits = [];
  const note = String(body?.text || body?.message || '').trim();
  if (note) bits.push(note);
  if (body?.audio) {
    const transcript = String(
      await transcribeAudio(body.audio, body?.mimeType || body?.mime || 'audio/webm')
    ).trim();
    if (transcript) bits.push('Audio: ' + transcript);
  }
  if (body?.image) {
    const vision = String(
      await extractImageNotes(body.image, body?.imageMime || body?.image_mime || 'image/jpeg')
    ).trim();
    if (vision) bits.push('Imagen: ' + vision);
  }
  const text = bits.join('\n\n').trim();
  if (!text) throw new Error('Falta texto, imagen o audio');
  return text;
}

async function callGemini({ userText, history, snapshot }) {
  if (!GEMINI_API_KEY) {
    return fallbackReply(snapshot, userText);
  }
  const compact = compactSnapshot(snapshot, userText);
  const contents = [];
  if (Array.isArray(history)) {
    for (const m of history.slice(-8)) {
      const role = m.role === 'assistant' || m.role === 'model' ? 'model' : 'user';
      const text = String(m.text || m.content || '').slice(0, 4000);
      if (!text) continue;
      contents.push({ role, parts: [{ text }] });
    }
  }
  contents.push({ role: 'user', parts: [{ text: String(userText || '').slice(0, 8000) }] });

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
  const body = {
    systemInstruction: {
      parts: [{ text: `${SYSTEM_PROMPT}\n\nSNAPSHOT:\n${JSON.stringify(compact)}` }],
    },
    contents,
    generationConfig: {
      temperature: compact.sales?.sales_focus?.ok || compact.hotels?.catalog_focus?.ok ? 0.1 : 0.3,
      maxOutputTokens: 4096,
    },
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => null);
  if (!res.ok) {
    const msg = json?.error?.message || `Gemini HTTP ${res.status}`;
    console.warn('ANA Gemini error:', msg);
    return fallbackReply(snapshot, userText, msg);
  }
  const text = geminiTextFrom(json);
  if (!text) return fallbackReply(snapshot, userText, 'Gemini devolvió vacío');
  return text;
}

function fallbackReply(snapshot, userText, geminiErr) {
  const c = compactSnapshot(snapshot, userText);
  const failed = (c.health || []).filter((h) => !h.ok);
  const lines = [];
  lines.push(`**Resumen ${c.ymd}** (sin modelo de IA${geminiErr ? `: ${geminiErr}` : ': falta GEMINI_API_KEY'}).`);
  lines.push('');
  lines.push(`- Ventas hoy: ${c.sales?.today?.count ?? 0} reservas · $${Number(c.sales?.today?.amount || 0).toLocaleString('es-AR')}`);
  lines.push(
    `- Mes: ${c.sales?.month?.count ?? 0} reservas cargadas · $${Number(c.sales?.month?.amount || 0).toLocaleString('es-AR')} · anuladas: ${c.sales?.month?.cancelled_count ?? 0}`
  );
  const focus = c.sales?.sales_focus;
  if (focus?.slices?.length) {
    lines.push('');
    lines.push('**Consulta filtrada:**');
    for (const slice of focus.slices) {
      lines.push(`- ${slice.topic} · ${(slice.hotels || []).join(', ')} · ${(slice.months || []).join(', ')}`);
      for (const [axis, tot] of Object.entries(slice.totals || {})) {
        lines.push(`  · ${axis}: ${tot.count} reservas · $${Number(tot.amount || 0).toLocaleString('es-AR')}`);
      }
    }
    if (Number.isFinite(focus.open_cancel)) {
      lines.push(`- Pedidos de anulación abiertos: ${focus.open_cancel}`);
    }
  }
  const cat = c.hotels?.catalog_focus;
  const chileN = c.hotels?.by_pais_activos?.Chile ?? c.hotels?.by_pais_activos?.chile;
  lines.push(
    `- Catálogo: ${c.hotels?.count_activos ?? 0} activos / ${c.hotels?.count ?? 0} total` +
      (chileN != null ? ` · Chile: ${chileN}` : '')
  );
  if (cat?.ok) {
    lines.push(`- Consulta catálogo: ${cat.count} · ${(cat.names || []).slice(0, 25).join(', ')}`);
  }
  lines.push(
    `- Flor hoy: ${c.flor?.today?.new_chats_total ?? 0} chats · ${c.flor?.today?.inbound_messages_total ?? 0} msgs · ${c.flor?.today?.handoffs_total ?? 0} hand-offs`
  );
  lines.push(`- Web hoy: ${c.visits?.today?.visitors ?? 0} personas · ${c.visits?.today?.pageviews ?? 0} vistas`);
  if (c.ads?.google?.connected) {
    lines.push(`- Google Ads 7d: ${c.ads.google.currency} ${c.ads.google.last_7d?.spend ?? 0}`);
  } else {
    lines.push(`- Google Ads: ${c.ads?.google?.reason || c.ads?.google?.error || 'sin conectar'}`);
  }
  if (c.ads?.meta?.connected) {
    lines.push(`- Meta Ads 7d: ${c.ads.meta.currency} ${c.ads.meta.last_7d?.spend ?? 0}`);
  }
  lines.push(`- Monitor: ${failed.length ? failed.map((f) => f.name).join(', ') : 'todo OK'}`);
  const pc = c.sales?.pending_cancel || [];
  const pm = c.sales?.pending_modify || [];
  if (pc.length || pm.length) {
    lines.push(
      `- Seguimiento hotel: ${pc.length} anulación(es) pedida(s) · ${pm.length} modificación(es) pedida(s)`
    );
  }
  lines.push('- Ads / ocupación / bandeja B2B: sin datos (no conectados).');
  if (c.ideas?.length) {
    lines.push('');
    lines.push('**Acción:** ' + c.ideas[0]);
  }
  if (userText) lines.push(`\nConsulta: ${String(userText).slice(0, 200)}`);
  return lines.join('\n');
}

app.post('/api/chat', requireAuth, async (req, res) => {
  let text = String(req.body?.text || req.body?.message || '').trim();
  let transcript = null;
  const audio = req.body?.audio;
  try {
    if (audio && !text) {
      transcript = await transcribeAudio(audio, req.body?.mimeType || req.body?.mime || 'audio/webm');
      text = String(transcript || '').trim();
      if (!text) {
        return res.status(400).json({ error: 'No pude entender el audio. Probá de nuevo más cerca del micrófono.' });
      }
    }
    if (!text) return res.status(400).json({ error: 'Falta text o audio' });
    if (looksLikeCopilot(text)) {
      try {
        const captured = await captureFromText({ text, source: 'web_dashboard' });
        return res.json({
          ok: true,
          reply: captured.reply,
          copilot: captured,
          ymd: (await getSnapshot()).ymd,
          gemini: Boolean(GEMINI_API_KEY),
          transcript: transcript || null,
        });
      } catch (e) {
        console.warn('ANA copiloto chat', e.message || e);
      }
    }
    const snapshot = await getSnapshot({ force: true });
    const intent = detectCommercialIntent(text);
    let artifact = null;
    if (intent === 'proposal') {
      artifact = await buildProposalFromPrompt(text, snapshot.ymd);
    } else if (intent === 'promo') {
      artifact = await buildPromoFromPrompt(text, snapshot.ymd);
    }
    const userText = artifact
      ? `${text}\n\n[ANA ya armó un ${artifact.kind}. Resumí esto, no inventes tarifas extra:]\n${artifact.summary}`
      : text;
    const reply = await callGemini({
      userText,
      history: Array.isArray(req.body?.history) ? req.body.history : [],
      snapshot,
    });
    res.json({
      ok: true,
      reply: artifact ? `${artifact.summary}\n\n${reply}` : reply,
      artifact: artifact
        ? {
            kind: artifact.kind,
            html: artifact.html,
            json: artifact.json || null,
            filename:
              artifact.kind === 'promo'
                ? `pack-${(artifact.hotel?.name || 'destino').replace(/\s+/g, '-')}.html`
                : `propuesta-${(artifact.hotel?.name || 'hotel').replace(/\s+/g, '-')}.html`,
          }
        : null,
      ymd: snapshot.ymd,
      gemini: Boolean(GEMINI_API_KEY),
      transcript: transcript || null,
    });
  } catch (e) {
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.get(['/', '/index.html'], (req, res) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.use(express.static(path.join(__dirname, 'public'), { index: false, extensions: ['html'] }));

app.listen(PORT, () => {
  console.log(`ANA escuchando en :${PORT}`);
  console.log(`  Auth: ${ANA_PASSWORD ? 'clave configurada' : 'FALTA ANA_PASSWORD'}`);
  console.log(`  Gemini: ${GEMINI_API_KEY ? GEMINI_MODEL : 'no configurado (fallback snapshot)'}`);
});
