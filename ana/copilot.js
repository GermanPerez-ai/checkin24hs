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
const ART_TZ = 'America/Argentina/Buenos_Aires';

function artParts(iso) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: ART_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).formatToParts(d);
  const g = (t) => (parts.find((p) => p.type === t) || {}).value || '';
  return { y: g('year'), m: g('month'), d: g('day'), hh: g('hour'), mm: g('minute'), ss: g('second') };
}

function formatArtDateTime(iso) {
  const p = artParts(iso);
  if (!p) return String(iso || '');
  return `${p.d}/${p.m}/${p.y} ${p.hh}:${p.mm}`;
}

function artYmdFromIso(iso) {
  const p = artParts(iso);
  if (!p) return String(iso || '').slice(0, 10);
  return `${p.y}-${p.m}-${p.d}`;
}

function artWallClock(iso) {
  const p = artParts(iso);
  if (!p) return null;
  return `${p.y}-${p.m}-${p.d}T${p.hh}:${p.mm}:${p.ss}`;
}

/** Hora de feria/agenda = Argentina. Si Gemini manda hora naive o Z, la tratamos como -03:00. */
function normalizeArtDateTime(value) {
  if (!value) return null;
  const s = String(value).trim();
  if (!s) return null;
  const hasOffset = /[zZ]|[+-]\d{2}:?\d{2}$/.test(s);
  if (hasOffset && !/[zZ]$/.test(s)) return s;
  const naive = s.replace(/[zZ]$/, '').replace(/\.\d+$/, '');
  const base = naive.includes('T') ? naive : `${naive}T00:00:00`;
  const withSec = /T\d{2}:\d{2}:\d{2}$/.test(base) ? base : /T\d{2}:\d{2}$/.test(base) ? `${base}:00` : `${base}T00:00:00`;
  return `${withSec}-03:00`;
}

function normalizeStand(value) {
  const s = String(value || '').trim().toUpperCase();
  if (!s || s === '-' || s === 'N/A' || s === 'NA' || s === 'NULL') return '';
  const m = s.match(/\b(NAC|INT|NACIONAL|INTERNACIONAL)[-\s]?(\d{2,6})\b/);
  if (m) return `${m[1].startsWith('INT') ? 'INT' : 'NAC'}-${m[2]}`;
  const m2 = s.match(/\b([A-Z]{2,5})-(\d{2,6})\b/);
  if (m2) return `${m2[1]}-${m2[2]}`;
  const m3 = s.match(/N[UÚ]MERO DE STAND[:\s]+([A-Z0-9-]{3,20})/i);
  if (m3) return normalizeStand(m3[1]) || m3[1].toUpperCase();
  const cleaned = s.replace(/^STAND[:\s]+/i, '').trim();
  return /^[A-Z0-9-]{3,20}$/.test(cleaned) ? cleaned : '';
}

function extractStand(text) {
  return normalizeStand(text);
}

function parseFairScheduleLines(raw) {
  const lines = [];
  for (const line of String(raw || '').split(/\r?\n/)) {
    const cleaned = line.replace(/^Imagen:\s*/i, '').trim();
    const parts = cleaned.split('|').map((p) => p.trim());
    if (parts.length < 5) continue;
    const status = parts[0].toUpperCase();
    if (!/^(CONFIRMED|PENDING|REJECTED|FREE)/.test(status)) continue;
    const time = String(parts[2] || '').replace('.', ':');
    const hm = time.match(/^(\d{1,2}):(\d{2})/);
    if (!hm) continue;
    const stand = extractStand(parts[parts.length - 1]) || extractStand(cleaned);
    lines.push({
      status,
      date: parts[1],
      time: `${String(hm[1]).padStart(2, '0')}:${hm[2]}`,
      name: parts[3] || '',
      company: parts.slice(4, Math.max(5, parts.length - 1)).join(' | '),
      stand,
    });
  }
  return lines;
}

function foldName(s) {
  return String(s || '')
    .toUpperCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^A-Z0-9]+/g, ' ')
    .trim();
}

function namesOverlap(a, b) {
  const left = foldName(a).split(' ').filter((w) => w.length > 2);
  const right = new Set(foldName(b).split(' ').filter((w) => w.length > 2));
  if (!left.length || !right.size) return false;
  const hits = left.filter((w) => right.has(w)).length;
  return hits >= Math.min(2, left.length);
}

function standForItem(item, raw) {
  const direct = extractStand(item.stand) || extractStand(item.title) || extractStand(item.description);
  if (direct) return direct;
  const lines = parseFairScheduleLines(raw);
  if (!lines.length) return extractStand(raw) || '';
  const p = artParts(item.start_time);
  const hm = p ? `${p.hh}:${p.mm}` : '';
  const blob = `${item.title || ''} ${item.description || ''}`;
  const byTimeAndName = lines.find(
    (l) => l.stand && l.time === hm && (namesOverlap(blob, `${l.name} ${l.company}`) || namesOverlap(l.name, blob))
  );
  if (byTimeAndName) return byTimeAndName.stand;
  const byTime = lines.filter((l) => l.stand && l.time === hm);
  if (byTime.length === 1) return byTime[0].stand;
  return '';
}

function applyStandToItem(item, stand) {
  if (!item || !stand) return item;
  item.stand = stand;
  const title = String(item.title || '').trim();
  if (title && !extractStand(title)) item.title = `${title} · ${stand}`.slice(0, 255);
  const desc = String(item.description || '').trim();
  if (!extractStand(desc)) item.description = [`Stand ${stand}`, desc].filter(Boolean).join(' · ').slice(0, 2000);
  return item;
}

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

function jsonStartIndex(body) {
  const obj = body.indexOf('{');
  const arr = body.indexOf('[');
  if (obj < 0) return arr;
  if (arr < 0) return obj;
  return Math.min(obj, arr);
}

function repairTruncatedJson(raw) {
  let s = String(raw || '').trim().replace(/,\s*$/, '');
  let inStr = false;
  let esc = false;
  const stack = [];
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (inStr) {
      if (esc) {
        esc = false;
        continue;
      }
      if (c === '\\') {
        esc = true;
        continue;
      }
      if (c === '"') inStr = false;
      continue;
    }
    if (c === '"') {
      inStr = true;
      continue;
    }
    if (c === '{') stack.push('}');
    else if (c === '[') stack.push(']');
    else if (c === '}' || c === ']') stack.pop();
  }
  if (inStr) s += '"';
  s = s.replace(/,\s*$/, '');
  const lastObj = s.lastIndexOf('}');
  const lastArr = s.lastIndexOf(']');
  const lastCut = Math.max(lastObj, lastArr);
  if (lastCut > 0 && stack.length) {
    const trimmed = s.slice(0, lastCut + 1);
    try {
      return JSON.parse(trimmed);
    } catch (_) {
      /* close below */
    }
    s = trimmed;
  }
  while (stack.length) s += stack.pop();
  return JSON.parse(s);
}

function parseJsonLoose(raw) {
  const s = String(raw || '').trim();
  const fence = s.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const body = (fence ? fence[1] : s).trim();
  const start = jsonStartIndex(body);
  if (start < 0) throw new Error('Gemini no devolvió JSON');
  const slice = body.slice(start);
  try {
    return JSON.parse(slice);
  } catch (first) {
    try {
      return repairTruncatedJson(slice);
    } catch (_) {
      throw first;
    }
  }
}

function asCaptureItems(parsed) {
  if (!parsed) return [];
  if (Array.isArray(parsed)) return parsed;
  if (Array.isArray(parsed.items)) return parsed.items;
  return [parsed];
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
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
      },
    }),
    signal: AbortSignal.timeout(45000),
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
  const start = artWallClock(parsed.start_time) || parsed.start_time;
  const endIso = parsed.end_time || new Date(new Date(parsed.start_time).getTime() + 45 * 60000).toISOString();
  const end = artWallClock(endIso) || endIso;
  const access = await googleAccessToken();
  const res = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(GOOGLE_CALENDAR_ID)}/events`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${access}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        summary: parsed.title,
        description: parsed.description || '',
        location: parsed.stand ? `Stand ${parsed.stand}` : undefined,
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

function parseSystemPrompt() {
  const now = new Date().toLocaleString('sv-SE', { timeZone: 'America/Argentina/Buenos_Aires' });
  return `Sos el clasificador de agenda de ANA (Checkin24hs). Ahora es ${now} ART.
Devolvé SOLO JSON con este esquema:
{"items":[{"include":true,"type":"meeting","title":"","stand":"NAC-1150","description":"","category":"b2b_hoteles","priority":"P2","start_time":"2026-09-28T11:00:00-03:00","end_time":"2026-09-28T11:30:00-03:00","due_date":"2026-09-28"}]}
Reglas:
- Si hay VARIAS reuniones/citas (agenda de feria, lista, captura), un item por cada una. Máximo 20.
- include=true solo las que el usuario pidió agendar. Si dijo "confirmadas", include=true SOLO si el texto dice Confirmada / CONFIRMED. Rechazada, Disponible, Pendiente de confirmación → include=false.
- type=meeting si hay horario. idea si es pensamiento/incubadora. task el resto.
- stand OBLIGATORIO si la línea/imagen tiene NÚMERO DE STAND o el último campo STAND (ej. NAC-1150, INT-3250). Copiá el código tal cual. NUNCA lo omitas.
- title: "Nombre — Empresa · STAND" si hay stand. Si no hay stand, "Nombre — Empresa".
- description: "Stand NAC-1150 · estado". El stand también va en el campo stand.
- Horarios America/Argentina/Buenos_Aires. SIEMPRE ISO con offset -03:00 (ejemplo 11:00 → 2026-09-28T11:00:00-03:00). NUNCA uses Z ni UTC. 13:00 es 13 no 1.
- category b2b_hoteles para hoteles/OTA/stands de feria; sistemas_code código/Flor; marketing_ads ads; gestion_personal personal.
- Campos cortos. Sin markdown.`;
}

async function parseCapture(text) {
  return geminiJson(parseSystemPrompt(), text);
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
    start_time: normalizeArtDateTime(fields.start_time),
    end_time: normalizeArtDateTime(fields.end_time),
    due_date: fields.due_date || (fields.start_time ? artYmdFromIso(normalizeArtDateTime(fields.start_time) || fields.start_time) : null),
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

async function captureOneItem(parsed, { raw, source, confirmWhatsApp }) {
  parsed.start_time = normalizeArtDateTime(parsed.start_time);
  parsed.end_time = normalizeArtDateTime(parsed.end_time);
  applyStandToItem(parsed, standForItem(parsed, raw));
  const type = String(parsed.type || 'task').toLowerCase();
  const subtasks = Array.isArray(parsed.subtasks)
    ? parsed.subtasks.map((s) => String(s)).filter(Boolean).slice(0, 8)
    : [];

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
    priority: parsed.priority || (isMeeting ? 'P2' : 'P2'),
    is_meeting: isMeeting,
    start_time: normalizeArtDateTime(parsed.start_time),
    end_time: normalizeArtDateTime(parsed.end_time),
    due_date: parsed.due_date || (parsed.start_time ? artYmdFromIso(normalizeArtDateTime(parsed.start_time) || parsed.start_time) : null),
    source,
    google_calendar_event_id: calendar.event_id || null,
    google_task_id: gtask.task_id || null,
  });

  const when = parsed.start_time
    ? formatArtDateTime(normalizeArtDateTime(parsed.start_time) || parsed.start_time)
    : parsed.due_date || 'sin horario';
  let reply = `${isMeeting ? 'Reunión' : 'Tarea'} *${parsed.title}* · ${parsed.priority || 'P2'} · ${when}`;
  if (calendar.html_link) reply += `\nCalendar: ${calendar.html_link}`;
  else if (calendar.error) reply += `\nCalendar: no se pudo sincronizar (${calendar.error})`;
  return { ok: true, kind: isMeeting ? 'meeting' : 'task', item: task, reply, google: calendar };
}

async function captureFromText({ text, source = 'web_dashboard', confirmWhatsApp = false }) {
  const raw = String(text || '').trim();
  if (!raw) throw new Error('Falta texto');
  const parsed = await parseCapture(raw);
  const items = asCaptureItems(parsed)
    .filter((it) => it && it.include !== false && String(it.title || '').trim())
    .slice(0, 20);
  if (!items.length) {
    throw new Error('No encontré reuniones para agendar (si pediste confirmadas, en la imagen no había ninguna Confirmada).');
  }

  const created = [];
  const errors = [];
  for (const item of items) {
    try {
      created.push(await captureOneItem(item, { raw, source, confirmWhatsApp: false }));
    } catch (e) {
      errors.push(`${item.title || 'item'}: ${e.message || e}`);
    }
  }
  if (!created.length) throw new Error(errors[0] || 'No se pudo guardar ninguna reunión');

  const lines = created.map((c) => c.reply);
  let reply =
    created.length === 1
      ? created[0].reply
      : `Agendé ${created.length} reuniones:\n` + lines.map((l) => `• ${l}`).join('\n');
  if (errors.length) reply += `\nNo pude cargar ${errors.length}: ${errors.slice(0, 3).join(' · ')}`;
  if (confirmWhatsApp) await sendWhatsApp(reply).catch(() => null);
  return {
    ok: true,
    kind: created.length > 1 ? 'meetings' : created[0].kind,
    item: created[0].item,
    items: created.map((c) => c.item),
    reply,
    google: created[0].google,
  };
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
  const meetingsToday = items.filter((t) => t.is_meeting && artYmdFromIso(t.start_time || t.due_date) === today);
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
    .map((t) => `• ${t.title}${t.start_time ? ' · ' + formatArtDateTime(t.start_time) : ''}`)
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
    const start = artYmdFromIso(t.start_time);
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
