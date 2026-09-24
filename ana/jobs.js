'use strict';

const {
  getSnapshot,
  arYmd,
  addYmd,
  arDayBounds,
  supabaseSelect,
  supabaseInsert,
} = require('./collect');
const { dispatchAlert, sendWhatsAppDocument } = require('./notify');
const { generateSalesControlReport } = require('./sales-control');
const {
  morningBriefingExtras,
  runSlaAutoTasks,
  runHealthAutoTasks,
  runEveningWrap,
} = require('./copilot');

const GEMINI_API_KEY = String(process.env.GEMINI_API_KEY || '').trim();
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const DAILY_GOAL = Number(process.env.ANA_DAILY_SALES_GOAL_USD || '') || null;
const DROP_OFF_MAX = Number(process.env.ANA_FLOR_DROPOFF_MAX || '0.25') || 0.25;

async function geminiJson(system, user) {
  if (!GEMINI_API_KEY) throw new Error('Falta GEMINI_API_KEY');
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: system }] },
      contents: [{ role: 'user', parts: [{ text: user }] }],
      generationConfig: { temperature: 0.2, maxOutputTokens: 2500 },
    }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json?.error?.message || `Gemini ${res.status}`);
  const text = json?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
  const m = text.match(/\{[\s\S]*\}/);
  if (!m) return { text };
  try {
    return JSON.parse(m[0]);
  } catch {
    return { text };
  }
}

function usd(n) {
  return `USD ${Number(n || 0).toLocaleString('es-AR')}`;
}

function dropOffRate(florDay) {
  const a = florDay?.abandon;
  if (!a) return null;
  const active = Number(a.active_for_abandon || florDay.active_chats_with_inbound || 0);
  const dropped = Number(a.short_abandon || 0) + Number(a.long_abandon || 0);
  if (!active) return null;
  return dropped / active;
}

async function runMorningFlash() {
  const snap = await getSnapshot({ force: true });
  const ymd = snap.ymd;
  const sales = snap.modules?.dashboard?.sales || {};
  const y = sales.yesterday || { count: 0, amount: 0, ymd: addYmd(ymd, -1) };
  const flor = snap.modules?.flor?.flor?.yesterday;
  const mail = snap.modules?.webmail?.mail;
  const stale = (mail?.messages || []).filter((m) => {
    if (!m.unseen && m.priority !== 'urgent') return false;
    if (!m.date) return false;
    return Date.now() - new Date(m.date).getTime() > 12 * 3600 * 1000;
  });
  const goalLine = DAILY_GOAL
    ? `Meta diaria: ${usd(DAILY_GOAL)} · Desvío: ${usd(Number(y.amount || 0) - DAILY_GOAL)}`
    : 'Meta diaria: no configurada (ANA_DAILY_SALES_GOAL_USD)';
  const lines = [
    `☀️ *Flash ANA* ${y.ymd || addYmd(ymd, -1)}`,
    `Ventas ayer: *${y.count || 0}* reservas · *${usd(y.amount)}*`,
    goalLine,
    flor
      ? `Flor ayer: ${flor.new_chats_total} chats · ${flor.handoffs_total} hand-offs`
      : 'Flor ayer: sin datos',
    stale.length
      ? `Mails >12h sin leer/prioritarios: *${stale.length}* (p.ej. ${stale[0].subject})`
      : 'Mails críticos >12h: ninguno en el recorte IMAP',
    (() => {
      const pc = sales.pending_cancel || [];
      const pm = sales.pending_modify || [];
      if (!pc.length && !pm.length) return 'Pedidos al hotel: ninguno abierto.';
      const staleN = [...pc, ...pm].filter((r) => Number(r.hours_waiting) >= 18).length;
      return `Pedidos al hotel: *${pc.length}* anulación · *${pm.length}* modificación` +
        (staleN ? ` · *${staleN}* con >18 h` : '');
    })(),
    'Ocupación portafolio: *sin datos* (no hay PMS).',
    (() => {
      const g = snap.modules?.ads?.google;
      const m = snap.modules?.ads?.meta;
      if (g?.connected) {
        return `Google Ads 7d: *${g.currency || ''} ${g.last_7d?.spend ?? 0}* · ${g.last_7d?.clicks ?? 0} clics`;
      }
      if (m?.connected) {
        return `Meta Ads 7d: *${m.currency || ''} ${m.last_7d?.spend ?? 0}*`;
      }
      return 'Ads: APIs pendientes de env (no se estima gasto).';
    })(),
    '_ANA · 08:00 ART_',
  ];
  try {
    const extra = await morningBriefingExtras();
    if (extra?.text) lines.splice(lines.length - 1, 0, extra.text);
  } catch (_) {}
  return dispatchAlert({
    kind: 'morning_flash',
    fingerprint: `morning-flash:${y.ymd || ymd}`,
    text: lines.join('\n'),
    payload: { yesterday: y, stale_mail: stale.length, goal: DAILY_GOAL },
  });
}

async function runFlorFriction() {
  const snap = await getSnapshot({ force: true });
  const ymd = snap.ymd;
  const hour = new Date().toLocaleString('en-GB', {
    timeZone: 'America/Argentina/Buenos_Aires',
    hour: '2-digit',
    hour12: false,
  });
  const bucket = `${ymd}-h${String(Math.floor(Number(hour) / 2) * 2).padStart(2, '0')}`;
  const today = snap.modules?.flor?.flor?.today;
  const rate = dropOffRate(today);
  const results = [];

  if (rate != null && rate > DROP_OFF_MAX) {
    results.push(
      await dispatchAlert({
        kind: 'flor_dropoff',
        fingerprint: `flor-dropoff:${bucket}`,
        text: [
          `🚨 *ANA · Flor drop-off*`,
          `Tasa abandono hoy: *${Math.round(rate * 100)}%* (umbral ${Math.round(DROP_OFF_MAX * 100)}%)`,
          `Chats: ${today.new_chats_total} · hand-offs: ${today.handoffs_total}`,
          `Revisar cotización / hand-off humano.`,
        ].join('\n'),
        payload: { rate, abandon: today.abandon },
      })
    );
  }

  const fromIso = new Date(Date.now() - 2 * 3600 * 1000).toISOString();
  let quotes = { ok: false, data: [] };
  try {
    quotes = await supabaseSelect(
      'quotes',
      `select=id,customer_name,customer_phone,adults,hotel_name,status,total,created_at&created_at=gte.${encodeURIComponent(fromIso)}&order=created_at.desc&limit=50`
    );
    if (!quotes.ok) {
      quotes = await supabaseSelect(
        'quotes',
        `select=id,customer_name,customer_phone,adults,status,total,created_at&created_at=gte.${encodeURIComponent(fromIso)}&order=created_at.desc&limit=50`
      );
    }
  } catch (e) {
    results.push({ kind: 'quotes_lookup', ok: false, error: e.message });
  }
  const hot = (Array.isArray(quotes.data) ? quotes.data : []).filter((q) => {
    const adults = Number(q.adults || 0);
    const pending = /pendient|nueva|proceso|abiert/i.test(String(q.status || ''));
    const ageMin = (Date.now() - new Date(q.created_at).getTime()) / 60000;
    return pending && adults >= 5 && ageMin >= 15;
  });
  for (const q of hot.slice(0, 3)) {
    results.push(
      await dispatchAlert({
        kind: 'flor_high_value_idle',
        fingerprint: `quote-idle:${q.id}`,
        text: [
          `⚠️ *ANA · Lead alto valor desatendido*`,
          `${q.customer_name || 'Cliente'} · ${q.adults} pax · ${q.hotel_name || 'hotel n/d'}`,
          `Cotización en ${q.status} >15 min.`,
          `Intervenir humano.`,
        ].join('\n'),
        payload: { quote_id: q.id },
      })
    );
  }

  const adsG = snap.modules?.ads?.google;
  if (adsG?.connected && adsG.prev_7d?.spend > 50 && adsG.last_7d?.spend > adsG.prev_7d.spend * 2.5) {
    results.push(
      await dispatchAlert({
        kind: 'ads_anomaly',
        fingerprint: `ads-spend:${ymd}`,
        text: [
          `🚨 *ANA · Google Ads gasto*`,
          `Últimos 7 días: *${adsG.currency} ${adsG.last_7d.spend}*`,
          `7 días previos: ${adsG.currency} ${adsG.prev_7d.spend}`,
          `Superó 2.5×. Revisar campañas.`,
        ].join('\n'),
        payload: { last_7d: adsG.last_7d, prev_7d: adsG.prev_7d },
      })
    );
  } else if (!adsG?.connected && !snap.modules?.ads?.meta?.connected) {
    results.push({
      kind: 'ads_anomaly',
      skipped: true,
      reason: 'Google/Meta Ads API no conectada — no se dispara Ad Spend Anomaly',
    });
  }

  if (!results.length) {
    return { ok: true, skipped: true, reason: 'sin fricción Flor en esta ventana' };
  }
  return { ok: true, results };
}

async function runWeeklyQa() {
  const to = arYmd();
  const from = addYmd(to, -7);
  const bounds = arDayBounds(from);
  const toBounds = arDayBounds(to);
  let msgRes = await supabaseSelect(
    'whatsapp_messages',
    `select=chat_id,is_from_me,is_from_flor,message,sent_at&sent_at=gte.${encodeURIComponent(bounds.from)}&sent_at=lt.${encodeURIComponent(toBounds.to)}&order=sent_at.desc&limit=800`
  );
  if (!msgRes.ok) {
    msgRes = await supabaseSelect(
      'whatsapp_messages',
      `select=chat_id,is_from_me,message,sent_at&sent_at=gte.${encodeURIComponent(bounds.from)}&sent_at=lt.${encodeURIComponent(toBounds.to)}&order=sent_at.desc&limit=800`
    );
  }
  const rows = msgRes.ok && Array.isArray(msgRes.data) ? msgRes.data : [];
  const byChat = {};
  for (const m of rows) {
    const id = m.chat_id;
    if (!id) continue;
    if (!byChat[id]) byChat[id] = [];
    if (byChat[id].length < 10) {
      byChat[id].push({
        flor: Boolean(m.is_from_flor),
        me: Boolean(m.is_from_me),
        t: String(m.message || m.body || '').slice(0, 280),
      });
    }
  }
  const chats = Object.entries(byChat)
    .slice(0, 40)
    .map(([id, msgs]) => ({ id, msgs: msgs.reverse() }));
  const evasion = /no entend[ií]|te conecto|un agente|deriv|transfer|no pude entender|asesor/i;
  const heuristicGaps = [];
  for (const c of chats) {
    const lastFlor = [...c.msgs].reverse().find((m) => m.flor);
    if (lastFlor && evasion.test(lastFlor.t)) heuristicGaps.push(lastFlor.t.slice(0, 180));
  }

  let llm = {};
  try {
    llm = await geminiJson(
      'Eres ANA. Clasificá chats de Flor IA. Respondé SOLO JSON: {counts:{venta,info,humano,abandono},automation_pct:number,gaps:string[],prompt_suggestions:string}',
      JSON.stringify(chats).slice(0, 20000)
    );
  } catch (e) {
    llm = { error: e.message, gaps: heuristicGaps };
  }

  const metrics = {
    chats_sampled: chats.length,
    messages_scanned: rows.length,
    automation_pct: llm.automation_pct ?? null,
    counts: llm.counts || null,
    heuristic_evasion: heuristicGaps.length,
  };
  const gaps = Array.isArray(llm.gaps) ? llm.gaps : heuristicGaps;
  const prompt_suggestions =
    llm.prompt_suggestions ||
    (gaps.length
      ? `Agregar al prompt de Flor respuestas para: ${gaps.slice(0, 5).join(' | ')}`
      : 'Sin brechas evidentes en la muestra.');

  const ins = await supabaseInsert('ana_qa_flor_ia', {
    period_from: from,
    period_to: to,
    metrics,
    gaps,
    prompt_suggestions,
    raw: { llm_error: llm.error || null, sample: chats.length },
  });

  const text = [
    `📋 *ANA · Calidad Flor* ${from} → ${to}`,
    `Chats muestreados: *${chats.length}*`,
    metrics.automation_pct != null ? `% automatización (LLM): *${metrics.automation_pct}*` : 'Automatización: sin score LLM',
    `Evasiones heurísticas: ${heuristicGaps.length}`,
    `Sugerencia prompt: ${String(prompt_suggestions).slice(0, 400)}`,
  ].join('\n');

  const alert = await dispatchAlert({
    kind: 'weekly_flor_qa',
    fingerprint: `flor-qa:${from}:${to}`,
    text,
    payload: { metrics, qa_insert: ins.ok },
  });
  return { ok: true, qa: ins, alert };
}

const LIFECYCLE_STALE_H = Number(process.env.ANA_LIFECYCLE_STALE_HOURS || '18') || 18;

function ageLabel(hours) {
  const h = Number(hours);
  if (!Number.isFinite(h)) return 'tiempo n/d';
  if (h < 24) return `${h} h`;
  return `${Math.round(h / 24)} d`;
}

async function runLifecycleFollowup() {
  const snap = await getSnapshot({ force: true });
  const sales = snap.modules?.dashboard?.sales || {};
  const cancel = sales.pending_cancel || [];
  const modify = sales.pending_modify || [];
  const open = [
    ...cancel.map((r) => ({ ...r, track: 'anulación' })),
    ...modify.map((r) => ({ ...r, track: 'modificación' })),
  ];
  if (!open.length) {
    return { ok: true, skipped: true, reason: 'sin pedidos de anulación/modificación abiertos' };
  }
  const stale = open.filter((r) => Number(r.hours_waiting) >= LIFECYCLE_STALE_H);
  const soon = open.filter((r) => {
    const cin = String(r.check_in || '').slice(0, 10);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(cin)) return false;
    const days = (new Date(`${cin}T12:00:00-03:00`).getTime() - Date.now()) / 86400000;
    return days >= 0 && days <= 7;
  });
  const watch = [...new Map([...stale, ...soon].map((r) => [String(r.code), r])).values()];
  const results = [];
  for (const r of watch.slice(0, 8)) {
    results.push(
      await dispatchAlert({
        kind: 'lifecycle_followup',
        fingerprint: `lifecycle:${r.track}:${r.code}`,
        text: [
          `🔔 *ANA · Seguimiento hotel*`,
          `${r.hotel} · ${r.code} · ${r.customer || 'huésped n/d'}`,
          `Pedido de *${r.track}* · estado *${r.status}* · lleva ${ageLabel(r.hours_waiting)}`,
          r.check_in ? `Check-in: ${r.check_in}` : '',
          `Acción: insistir al hotel o, si ya respondió, cerrar en Dashboard → Reservas.`,
        ]
          .filter(Boolean)
          .join('\n'),
        payload: { code: r.code, status: r.status, track: r.track, hours_waiting: r.hours_waiting },
      })
    );
  }
  if (!watch.length) {
    return {
      ok: true,
      skipped: true,
      reason: `${open.length} pedido(s) abiertos, ninguno >${LIFECYCLE_STALE_H}h ni con check-in en 7 días`,
      open: open.length,
    };
  }
  return { ok: true, results, open: open.length, watch: watch.length };
}

async function runCopilotAuto() {
  const snap = await getSnapshot({ force: true });
  const sla = await runSlaAutoTasks(snap.modules?.dashboard?.sales || {});
  const health = await runHealthAutoTasks(snap.modules?.monitor?.checks || []);
  const made = [...sla, ...health].filter((x) => x && !x.skipped);
  if (made.length) {
    await dispatchAlert({
      kind: 'copilot_auto',
      fingerprint: `copilot-auto:${snap.ymd}:${made.length}`,
      text: [
        `📌 *ANA Copiloto · auto-tareas*`,
        ...made.slice(0, 6).map((x) => `• ${x.task?.title || x.title}`),
      ].join('\n'),
      payload: { count: made.length },
    });
  }
  return { ok: true, sla: sla.length, health: health.length, created: made.length };
}

async function runWeeklySalesControl() {
  const report = await generateSalesControlReport();
  const alert = await dispatchAlert({
    kind: 'weekly_sales_control',
    fingerprint: `sales-control:${report.from}:${report.to}`,
    text: report.whatsappText,
    payload: { kpis: report.kpis, filename: report.filename },
  });
  let media = { skipped: true };
  if (!alert.skipped) {
    media = await sendWhatsAppDocument({
      fileName: report.filename,
      mimetype: 'application/pdf',
      base64: report.pdfBuffer.toString('base64'),
      caption: report.whatsappText,
    });
  }
  return {
    ok: true,
    from: report.from,
    to: report.to,
    filename: report.filename,
    kpis: report.kpis,
    pdf_bytes: report.pdfBuffer.length,
    alert,
    media,
  };
}

async function runJob(name) {
  try {
    if (name === 'morning-flash' || name === 'morning_flash') return await runMorningFlash();
    if (name === 'flor-friction' || name === 'flor_friction') return await runFlorFriction();
    if (name === 'weekly-qa' || name === 'weekly_qa') return await runWeeklyQa();
    if (
      name === 'weekly-sales-control' ||
      name === 'weekly_sales_control' ||
      name === 'sales-control'
    ) {
      return await runWeeklySalesControl();
    }
    if (name === 'lifecycle-followup' || name === 'lifecycle_followup') return await runLifecycleFollowup();
    if (name === 'copilot-auto' || name === 'copilot_auto') return await runCopilotAuto();
    if (name === 'copilot-evening' || name === 'copilot_evening' || name === 'evening-wrap') {
      return await runEveningWrap();
    }
    return { ok: false, error: `job desconocido: ${name}` };
  } catch (e) {
    console.warn('ANA job error', name, e.message || e);
    return { ok: false, error: e.message || String(e), job: name };
  }
}

module.exports = {
  runJob,
  runMorningFlash,
  runFlorFriction,
  runWeeklyQa,
  runWeeklySalesControl,
  runLifecycleFollowup,
  runCopilotAuto,
  runEveningWrap,
};
