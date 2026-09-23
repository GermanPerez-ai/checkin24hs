'use strict';

const { supabaseSelect, supabaseInsert, supabasePatch, arYmd, addYmd } = require('./collect');
const { sendWhatsApp } = require('./notify');

const GEMINI_API_KEY = String(process.env.GEMINI_API_KEY || '').trim();
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const SLA_HOURS = Number(process.env.ANA_COPILOT_SLA_HOURS || '4') || 4;
const GOOGLE_CLIENT_ID = String(process.env.GOOGLE_OAUTH_CLIENT_ID || process.env.GOOGLE_ADS_CLIENT_ID || '').trim();
const GOOGLE_CLIENT_SECRET = String(
  process.env.GOOGLE_OAUTH_CLIENT_SECRET || process.env.GOOGLE_ADS_CLIENT_SECRET || ''
).trim();
const GOOGLE_CALENDAR_REFRESH_TOKEN = String(process.env.GOOGLE_CALENDAR_REFRESH_TOKEN || '').trim();
const GOOGLE_CALENDAR_ID = String(process.env.GOOGLE_CALENDAR_ID || 'primary').trim() || 'primary';

const CATEGORIES = ['b2b_hoteles', 'sistemas_code', 'marketing_ads', 'gestion_personal', 'operaciones'];
const PRIORITIES = ['P1', 'P2', 'P3'];
const STATUSES = ['pending', 'in_progress', 'completed', 'cancelled'];

let googleTokenCache = { access: '', exp: 0 };

function googleCalendarReady() {
  return Boolean(GOOGLE_CLIENT_ID && GOOGLE_CLIENT_SECRET && GOOGLE_CALENDAR_REFRESH_TOKEN);
}

function asCategory(value) {
  const v = String(value || '').trim();
  return CATEGORIES.includes(v) ? v : 'operaciones';
}

function asPriority(value) {
  const v = String(value || '').trim().toUpperCase();
  return PRIORITIES.includes(v) ? v : 'P2';
}

function asStatus(value) {
  const v = String(value || '').trim();
  return STATUSES.includes(v) ? v : 'pending';
}

function parseJsonLoose(raw) {
  const s = String(raw || '').trim();
  const fence = s.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const body = fence ? fence[1] : s;
  const start = body.indexOf('{');
  const end = body.lastIndexOf('}');
  if (start < 0 || end <= start) throw new Error('Gemini no devolvió JSON');
  return JSON.parse(body.slice(start, end + 1));
}

async function geminiJson(system, user) {
  if (!GEMINI_API_KEY) throw new Error('Falta GEMINI_API_KEY');
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: system }] },
      contents: [{ role: 'user', parts: [{ text: String(user || '').slice(0, 12000) }] }],
      generationConfig: { temperature: 0.1, maxOutputTokens: 2048 },
    }),
    signal: AbortSignal.timeout(20000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json?.error?.message || `Gemini ${res.status}`);
  const text = (json?.candidates?.[0]?.content?.parts || []).map((p) => p.text || '').join('');
  return parseJsonLoose(text);
}

async function googleAccessToken() {
  const now = Date.now();
  if (googleTokenCache.access && googleTokenCache.exp > now + 30_000) return googleTokenCache.access;
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: GOOGLE_CLIENT_ID,
      client_secret: GOOGLE_CLIENT_SECRET,
      refresh_token: GOOGLE_CALENDAR_REFRESH_TOKEN,
      grant_type: 'refresh_token',
    }),
    signal: AbortSignal.timeout(12000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || !json.access_token) {
    throw new Error(json.error_description || json.error || `OAuth Calendar ${res.status}`);
  }
  googleTokenCache = {
    access: json.access_token,
    exp: now + Math.max(60, Number(json.expires_in) || 3500) * 1000,
  };
  return googleTokenCache.access;
}

async function insertGoogleCalendar(parsed) {
  if (!googleCalendarReady() || !parsed.start_time) return { connected: false, skipped: true };
  const start = parsed.start_time;
  const end = parsed.end_time || new Date(new Date(start).getTime() + 45 * 60000).toISOString();
  const access = await googleAccessToken();
  const res = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(GOOGLE_CALENDAR_ID)}/events`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${access}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        summary: parsed.title,
        description: parsed.description || '',
        start: { dateTime: start, timeZone: 'America/Argentina/Buenos_Aires' },
        end: { dateTime: end, timeZone: 'America/Argentina/Buenos_Aires' },
        reminders: { useDefault: true },
      }),
      signal: AbortSignal.timeout(12000),
    }
  );
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.error?.message || `Calendar ${res.status}`);
  return { connected: true, event_id: json.id, html_link: json.htmlLink || null };
}

async function insertGoogleTask(parsed) {
  if (!googleCalendarReady() || parsed.start_time) return { skipped: true };
  const access = await googleAccessToken();
  const res = await fetch('https://tasks.googleapis.com/tasks/v1/lists/@default/tasks', {
    method: 'POST',
    headers: { Authorization: `Bearer ${access}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: parsed.title,
      notes: parsed.description || '',
      due: parsed.due_date ? `${parsed.due_date}T15:00:00.000Z` : undefined,
    }),
    signal: AbortSignal.timeout(12000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) return { skipped: false, error: json.error?.message || `Tasks ${res.status}` };
  return { skipped: false, task_id: json.id };
}

const PARSE_SYSTEM = `Sos el clasificador de agenda de ANA (Checkin24hs). Hoy es ${new Date().toLocaleString('sv-SE', { timeZone: 'America/Argentina/Buenos_Aires' })} ART.
Devolvé SOLO JSON:
{"type":"task"|"meeting"|"idea","title":"","description":"","category":"b2b_hoteles"|"sistemas_code"|"marketing_ads"|"gestion_personal"|"operaciones","priority":"P1"|"P2"|"P3","start_time":null|"ISO-8601 con offset -03:00","end_time":null|"ISO-8601","due_date":null|"YYYY-MM-DD","subtasks":["..."]}
Reglas: meeting si hay reunión/call/cita con horario. idea si es un pensamiento, proyecto a incubar o "anotá la idea". task en el resto. Horarios en America/Argentina/Buenos_Aires. Si no hay fecha, due_date=hoy para P1, null si es idea. category b2b_hoteles para hoteles/reservas/RateHawk; sistemas_code para WhatsApp/Flor/código; marketing_ads para ads; gestion_personal para lo personal.`;

async function parseCapture(text) {
  return geminiJson(PARSE_SYSTEM, text);
}

async function findOpenByRef(source, sourceRef) {
  if (!sourceRef) return null;
  const { ok, data } = await supabaseSelect(
    'executive_tasks',
    `select=id,title,status&source=eq.${encodeURIComponent(source)}&source_ref=eq.${encodeURIComponent(sourceRef)}&status=in.(pending,in_progress)&limit=1`
  );
  if (!ok || !Array.isArray(data) || !data[0]) return null;
  return data[0];
}

async function createTask(fields) {
  const row = {
    title: String(fields.title || 'Tarea').slice(0, 255),
    description: fields.description || null,
    category: asCategory(fields.category),
    priority: asPriority(fields.priority),
    status: asStatus(fields.status || 'pending'),
    is_meeting: Boolean(fields.is_meeting),
    start_time: fields.start_time || null,
    end_time: fields.end_time || null,
    due_date: fields.due_date || (fields.start_time ? String(fields.start_time).slice(0, 10) : null),
    source: fields.source || 'web_dashboard',
    source_ref: fields.source_ref || null,
    google_calendar_event_id: fields.google_calendar_event_id || null,
    google_task_id: fields.google_task_id || null,
  };
  const ins = await supabaseInsert('executive_tasks', row);
  if (!ins.ok) {
    const msg = typeof ins.data === 'string' ? ins.data : JSON.stringify(ins.data);
    throw new Error(msg.slice(0, 300));
  }
  return Array.isArray(ins.data) ? ins.data[0] : ins.data;
}

async function createIdea(fields) {
  const ins = await supabaseInsert('executive_ideas', {
    raw_prompt: String(fields.raw_prompt || '').slice(0, 8000),
    structured_plan: fields.structured_plan || null,
    category: asCategory(fields.category),
    status: fields.status || 'captured',
  });
  if (!ins.ok) {
    const msg = typeof ins.data === 'string' ? ins.data : JSON.stringify(ins.data);
    throw new Error(msg.slice(0, 300));
  }
  return Array.isArray(ins.data) ? ins.data[0] : ins.data;
}

async function captureFromText({ text, source = 'web_dashboard', confirmWhatsApp = false }) {
  const raw = String(text || '').trim();
  if (!raw) throw new Error('Falta texto');
  const parsed = await parseCapture(raw);
  const type = String(parsed.type || 'task').toLowerCase();
  const subtasks = Array.isArray(parsed.subtasks) ? parsed.subtasks.map((s) => String(s)).filter(Boolean).slice(0, 8) : [];

  if (type === 'idea') {
    const idea = await createIdea({
      raw_prompt: raw,
      category: parsed.category,
      structured_plan: { title: parsed.title, steps: subtasks.length ? subtasks : ['Definir alcance', 'Asignar dueño', 'Primer hito'] },
    });
    const reply = `Idea capturada: *${parsed.title || 'sin título'}*. Quedó en la Incubadora.`;
    if (confirmWhatsApp) await sendWhatsApp(reply).catch(() => null);
    return { ok: true, kind: 'idea', item: idea, reply, google: { connected: googleCalendarReady() } };
  }

  const isMeeting = type === 'meeting' || Boolean(parsed.start_time);
  let calendar = { connected: googleCalendarReady(), skipped: true };
  let gtask = { skipped: true };
  try {
    if (isMeeting && parsed.start_time) calendar = await insertGoogleCalendar(parsed);
    else gtask = await insertGoogleTask(parsed);
  } catch (e) {
    calendar = { connected: googleCalendarReady(), error: e.message };
  }

  const task = await createTask({
    title: parsed.title,
    description: [parsed.description, subtasks.length ? `Pasos: ${subtasks.join(' · ')}` : ''].filter(Boolean).join('\n'),
    category: parsed.category,
    priority: parsed.priority,
    is_meeting: isMeeting,
    start_time: parsed.start_time || null,
    end_time: parsed.end_time || null,
    due_date: parsed.due_date || null,
    source,
    google_calendar_event_id: calendar.event_id || null,
    google_task_id: gtask.task_id || null,
  });

  const when = parsed.start_time
    ? new Date(parsed.start_time).toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' })
    : parsed.due_date || 'sin horario';
  let reply = `${isMeeting ? 'Reunión' : 'Tarea'} *${parsed.title}* · ${parsed.priority} · ${when}`;
  if (calendar.html_link) reply += `\nCalendar: ${calendar.html_link}`;
  else if (calendar.error) reply += `\nCalendar: no se pudo sincronizar (${calendar.error})`;
  if (confirmWhatsApp) await sendWhatsApp(reply).catch(() => null);
  return { ok: true, kind: isMeeting ? 'meeting' : 'task', item: task, reply, google: calendar };
}

async function listTasks({ status, priority, category } = {}) {
  const filters = [];
  if (status) filters.push(`status=eq.${encodeURIComponent(status)}`);
  else filters.push('status=in.(pending,in_progress)');
  if (priority) filters.push(`priority=eq.${encodeURIComponent(priority)}`);
  if (category) filters.push(`category=eq.${encodeURIComponent(category)}`);
  const qs = `select=*&${filters.join('&')}&order=priority.asc,start_time.asc.nullslast,due_date.asc.nullslast,created_at.desc&limit=200`;
  const { ok, status: http, data } = await supabaseSelect('executive_tasks', qs);
  if (!ok) return { error: `Supabase tasks ${http}`, items: [] };
  return { error: null, items: Array.isArray(data) ? data : [] };
}

async function listIdeas() {
  const { ok, status, data } = await supabaseSelect(
    'executive_ideas',
    'select=*&status=neq.archived&order=created_at.desc&limit=80'
  );
  if (!ok) return { error: `Supabase ideas ${status}`, items: [] };
  return { error: null, items: Array.isArray(data) ? data : [] };
}

async function patchTask(id, patch) {
  const body = {};
  if (patch.title != null) body.title = String(patch.title).slice(0, 255);
  if (patch.description != null) body.description = patch.description;
  if (patch.category != null) body.category = asCategory(patch.category);
  if (patch.priority != null) body.priority = asPriority(patch.priority);
  if (patch.status != null) body.status = asStatus(patch.status);
  if (patch.due_date !== undefined) body.due_date = patch.due_date;
  body.updated_at = new Date().toISOString();
  const res = await supabasePatch('executive_tasks', `id=eq.${encodeURIComponent(id)}`, body);
  if (!res.ok) throw new Error(`No se pudo actualizar la tarea (${res.status})`);
  return Array.isArray(res.data) ? res.data[0] : res.data;
}

async function convertIdea(id) {
  const { ok, data } = await supabaseSelect('executive_ideas', `select=*&id=eq.${encodeURIComponent(id)}&limit=1`);
  if (!ok || !data?.[0]) throw new Error('Idea no encontrada');
  const idea = data[0];
  const plan = idea.structured_plan || {};
  const steps = Array.isArray(plan.steps) ? plan.steps : [];
  const task = await createTask({
    title: plan.title || String(idea.raw_prompt).slice(0, 80),
    description: [idea.raw_prompt, steps.length ? `Pasos: ${steps.join(' · ')}` : ''].filter(Boolean).join('\n'),
    category: idea.category,
    priority: 'P2',
    source: 'web_dashboard',
    source_ref: `idea:${idea.id}`,
  });
  await supabasePatch('executive_ideas', `id=eq.${encodeURIComponent(id)}`, {
    status: 'converted_to_project',
  });
  return { ok: true, task, idea_id: id };
}

async function boardSummary() {
  const today = arYmd();
  const [open, ideas] = await Promise.all([listTasks({}), listIdeas()]);
  const items = open.items || [];
  const p1 = items.filter((t) => t.priority === 'P1' && t.status !== 'completed');
  const meetingsToday = items.filter((t) => t.is_meeting && String(t.start_time || t.due_date || '').slice(0, 10) === today);
  return {
    error: open.error || ideas.error,
    google_calendar: { connected: googleCalendarReady(), calendar_id: GOOGLE_CALENDAR_ID },
    counts: {
      open: items.length,
      p1: p1.length,
      meetings_today: meetingsToday.length,
      ideas: (ideas.items || []).filter((i) => i.status !== 'converted_to_project').length,
    },
    p1,
    meetings_today: meetingsToday,
  };
}

async function upsertAutoTask(fields) {
  const existing = await findOpenByRef('auto_system', fields.source_ref);
  if (existing) return { ok: true, skipped: true, id: existing.id, title: existing.title };
  const task = await createTask({ ...fields, source: 'auto_system', priority: fields.priority || 'P1' });
  return { ok: true, skipped: false, task };
}

async function runSlaAutoTasks(sales) {
  const created = [];
  const rows = [...(sales?.pending_cancel || []), ...(sales?.pending_modify || [])];
  for (const r of rows) {
    if (Number(r.hours_waiting) < SLA_HOURS) continue;
    const track = /anul/i.test(String(r.status || r.track || '')) ? 'anulación' : 'modificación';
    const ref = `${track}:${r.code || r.id}`;
    const out = await upsertAutoTask({
      title: `Hotel ${track} sin cierre · ${r.hotel || ''} ${r.code || ''}`.trim(),
      description: `${r.customer || ''} · estado ${r.status} · lleva ${r.hours_waiting} h. Pedido al hotel; no marcar Cancelada hasta confirmación.`,
      category: 'b2b_hoteles',
      priority: 'P1',
      source_ref: ref,
      due_date: arYmd(),
    });
    created.push(out);
  }
  return created;
}

async function runHealthAutoTasks(checks) {
  const created = [];
  for (const c of checks || []) {
    if (!/^WhatsApp L[1-4]$/i.test(String(c.name || ''))) continue;
    if (c.ok) continue;
    const line = String(c.name).replace(/\s+/g, '');
    const out = await upsertAutoTask({
      title: `Caída ${c.name}`,
      description: (c.issues || []).join('; ') || 'Health check en rojo',
      category: 'sistemas_code',
      priority: 'P1',
      source_ref: `health:${line}`,
      due_date: arYmd(),
    });
    created.push(out);
  }
  return created;
}

async function morningBriefingExtras() {
  const board = await boardSummary();
  const p1 = (board.p1 || []).slice(0, 8).map((t) => `• ${t.title}`).join('\n');
  const meets = (board.meetings_today || [])
    .slice(0, 6)
    .map((t) => `• ${t.title}${t.start_time ? ' · ' + String(t.start_time).slice(11, 16) : ''}`)
    .join('\n');
  const lines = [
    board.counts.p1 ? `P1 pendientes: *${board.counts.p1}*\n${p1}` : 'P1 pendientes: ninguna',
    board.counts.meetings_today ? `Reuniones hoy:\n${meets}` : 'Reuniones hoy: ninguna',
    `Ideas en incubadora: ${board.counts.ideas}`,
  ];
  return { board, text: lines.join('\n') };
}

async function runEveningWrap() {
  const today = arYmd();
  const { items } = await listTasks({});
  const dueToday = (items || []).filter((t) => {
    const due = String(t.due_date || '').slice(0, 10);
    const start = String(t.start_time || '').slice(0, 10);
    return due === today || start === today;
  });
  const open = dueToday.filter((t) => t.status === 'pending' || t.status === 'in_progress');
  const done = dueToday.filter((t) => t.status === 'completed');
  const text = [
    `🌙 *ANA · Cierre de jornada* ${today}`,
    `Completadas hoy: *${done.length}*`,
    open.length
      ? `Siguen abiertas:\n${open.slice(0, 10).map((t, i) => `${i + 1}. ${t.title} (${t.priority})`).join('\n')}\nMarcalas en Agenda Executive o respondé acá: "listo 1,3".`
      : 'No quedan tareas de hoy abiertas.',
  ].join('\n');
  const wa = await sendWhatsApp(text);
  return { ok: wa.ok, open: open.length, done: done.length, wa };
}

function looksLikeCopilot(text) {
  const t = String(text || '').trim().toLowerCase();
  return /^(anot[áa]|recordame|agend[áa]|tarea:|idea:|anotar |agendar )/i.test(t) ||
    /\b(agendame|recordame|incubadora)\b/i.test(t);
}

module.exports = {
  googleCalendarReady,
  captureFromText,
  listTasks,
  listIdeas,
  patchTask,
  convertIdea,
  boardSummary,
  runSlaAutoTasks,
  runHealthAutoTasks,
  morningBriefingExtras,
  runEveningWrap,
  looksLikeCopilot,
  SLA_HOURS,
};
