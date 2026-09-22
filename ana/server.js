'use strict';

const path = require('path');
const crypto = require('crypto');
const express = require('express');
const { getSnapshot, supabaseSelect } = require('./collect');
const { fetchBody } = require('./mail');
const { runJob } = require('./jobs');
const { buildProposalFromPrompt, buildPromoFromPrompt } = require('./proposals');

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

## MÓDULOS
- Dashboard/Supabase: **ingresos de hoteles en USD** (campo total_amount). Nunca los trates como pesos ni los conviertas. Los gastos se cargan en ARS y luego se pasan a USD; el módulo de gastos aún no está en ANA, no inventes tipo de cambio.
- Para un hotel y un mes usá sales.by_hotel_month. created_* = reservas **cargadas** ese mes; checkin_* = reservas con **check-in** ese mes. Si preguntan "ingresos de agosto de Puyehue", filtrá hotel que contenga Puyehue y month=2026-08. Si no hay fila, decí 0 reservas en el recorte (desde sales.range_from), no que "no podés desglosar".
- Web: visitas (site_pageviews) y UTM.
- Ads: solo Google por ahora (customer Checkin24hs + cuenta publicitaria). Campañas/gasto/ROAS solo si google.token_ready=true. Meta no está configurada.
- Flor IA / WhatsApp: chats, hand-offs, SLA si viene en el snapshot, estado de L1–L4 (Monitor).
- Webmail: INBOX IMAP de reservas@. Usá summary/preview del cuerpo; no respondas solo con el asunto. Borradores, no envíes.
- Pedidos al hotel: sales.pending_cancel = anulaciones pedidas (y En gestión de anular). sales.pending_modify = modificaciones pedidas. hours_waiting = horas desde el último update. Tu tarea es el seguimiento: si llevan >18 h o el check-in está cerca, insistí en que ventas persiga al hotel o use los botones del dashboard. No marques Cancelada/Modificada vos: eso lo cierra el mail del hotel o ventas.
- Ocupación hotelera: no existe en nuestra base.
- Ads spend/clics: sin API. Nunca inventes Ad Spend Anomaly.
- Empresa: catálogo de hoteles representados en Supabase.
- Propuestas B2B y packs promocionales: si el usuario pide una propuesta de representación o contenido promocional, el sistema genera HTML/JSON aparte; vos resumí y no inventes tarifas que no estén en el snapshot.
- Alertas: flash 08:00, fricción Flor cada 2 h, QA semanal. No dispares envíos desde el chat.

Abajo tenés un SNAPSHOT JSON real. Basate solo en eso y en el mensaje del usuario.`;

const app = express();
app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(express.json({ limit: '8mb' }));

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

function compactSnapshot(snap) {
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
          by_hotel_month: sales.by_hotel_month || [],
          recent: sales.recent,
          pending_cancel: sales.pending_cancel || [],
          pending_modify: sales.pending_modify || [],
          error: sales.error,
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
      ? { count: snap.modules.empresa.hotels.count, items: snap.modules.empresa.hotels.items.slice(0, 25) }
      : { error: snap.modules?.empresa?.error || 'sin datos' },
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
    unavailable: {
      ads: snap.modules?.ads,
      webmail: snap.modules?.webmail,
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

async function callGemini({ userText, history, snapshot }) {
  if (!GEMINI_API_KEY) {
    return fallbackReply(snapshot, userText);
  }
  const compact = compactSnapshot(snapshot);
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
      temperature: 0.3,
      maxOutputTokens: 2048,
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
  const c = compactSnapshot(snapshot);
  const failed = (c.health || []).filter((h) => !h.ok);
  const lines = [];
  lines.push(`**Resumen ${c.ymd}** (sin modelo de IA${geminiErr ? `: ${geminiErr}` : ': falta GEMINI_API_KEY'}).`);
  lines.push('');
  lines.push(`- Ventas hoy: ${c.sales?.today?.count ?? 0} reservas · $${Number(c.sales?.today?.amount || 0).toLocaleString('es-AR')}`);
  lines.push(
    `- Mes: ${c.sales?.month?.count ?? 0} reservas · $${Number(c.sales?.month?.amount || 0).toLocaleString('es-AR')}`
  );
  lines.push(
    `- Flor hoy: ${c.flor?.today?.new_chats_total ?? 0} chats · ${c.flor?.today?.inbound_messages_total ?? 0} msgs · ${c.flor?.today?.handoffs_total ?? 0} hand-offs`
  );
  lines.push(`- Web hoy: ${c.visits?.today?.visitors ?? 0} personas · ${c.visits?.today?.pageviews ?? 0} vistas`);
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

app.use(express.static(path.join(__dirname, 'public'), { index: 'index.html', extensions: ['html'] }));

app.listen(PORT, () => {
  console.log(`ANA escuchando en :${PORT}`);
  console.log(`  Auth: ${ANA_PASSWORD ? 'clave configurada' : 'FALTA ANA_PASSWORD'}`);
  console.log(`  Gemini: ${GEMINI_API_KEY ? GEMINI_MODEL : 'no configurado (fallback snapshot)'}`);
});
