'use strict';

function digitsOnly(value) {
  return String(value || '').replace(/\D/g, '');
}

function formatGoogleCid(digits) {
  const d = digitsOnly(digits);
  if (d.length === 10) return d.replace(/(\d{3})(\d{3})(\d{4})/, '$1-$2-$3');
  if (d.length === 12) return d.replace(/(\d{4})(\d{4})(\d{4})/, '$1-$2-$3');
  return d;
}

function round2(n) {
  const v = Number(n);
  if (!Number.isFinite(v)) return 0;
  return Math.round(v * 100) / 100;
}

function microsToAmount(raw) {
  const n = Number(raw);
  if (!Number.isFinite(n)) return 0;
  return round2(n / 1e6);
}

function redact(err) {
  return String(err || '')
    .replace(/ya29\.[A-Za-z0-9._-]+/g, '[token]')
    .replace(/EAA[A-Za-z0-9]+/g, '[token]')
    .replace(/Bearer\s+\S+/gi, 'Bearer [token]')
    .slice(0, 400);
}

function missingList(pairs) {
  return pairs.filter(([, v]) => !String(v || '').trim()).map(([k]) => k);
}

const GOOGLE_ADS_API_VERSION = process.env.GOOGLE_ADS_API_VERSION || 'v19';
const META_GRAPH_VERSION = process.env.META_ADS_API_VERSION || 'v21.0';
const GOOGLE_ADS_CUSTOMER_ID = digitsOnly(process.env.GOOGLE_ADS_CUSTOMER_ID || '2654092864');
const GOOGLE_ADS_ACCOUNT_NAME = String(process.env.GOOGLE_ADS_ACCOUNT_NAME || 'Checkin24hs').trim();
const GOOGLE_ADS_ADVERTISER_ID = digitsOnly(process.env.GOOGLE_ADS_ADVERTISER_ID || '505321673398');
const GOOGLE_ADS_LOGIN_CUSTOMER_ID = digitsOnly(process.env.GOOGLE_ADS_LOGIN_CUSTOMER_ID || '');
const GOOGLE_ADS_DEVELOPER_TOKEN = String(process.env.GOOGLE_ADS_DEVELOPER_TOKEN || '').trim();
const GOOGLE_ADS_CLIENT_ID = String(process.env.GOOGLE_ADS_CLIENT_ID || '').trim();
const GOOGLE_ADS_CLIENT_SECRET = String(process.env.GOOGLE_ADS_CLIENT_SECRET || '').trim();
const GOOGLE_ADS_REFRESH_TOKEN = String(process.env.GOOGLE_ADS_REFRESH_TOKEN || '').trim();
function parseIdList(raw, fallback) {
  const src = String(raw || '').trim() || String(fallback || '');
  return [...new Set(src.split(/[,\s]+/).map(digitsOnly).filter(Boolean))];
}

const META_AD_ACCOUNT_IDS = parseIdList(
  process.env.META_AD_ACCOUNT_IDS || process.env.META_AD_ACCOUNT_ID,
  '1118825316603711,1254251819602084,1607183710965099,706633807356464'
);

function loadMetaAccountConfigs() {
  const ids = [...META_AD_ACCOUNT_IDS];
  for (let i = 1; i <= 8; i += 1) {
    const extra = digitsOnly(process.env[`META_AD_ACCOUNT_${i}`] || '');
    if (extra && !ids.includes(extra)) ids.push(extra);
  }
  const shared = String(process.env.META_ADS_ACCESS_TOKEN || '').trim();
  const listed = String(process.env.META_ADS_ACCESS_TOKENS || '')
    .split('|')
    .map((s) => s.trim())
    .filter(Boolean);
  return ids.map((id, idx) => {
    const n = idx + 1;
    const token =
      String(process.env[`META_ADS_ACCESS_TOKEN_${id}`] || '').trim() ||
      String(process.env[`META_ADS_TOKEN_${id}`] || '').trim() ||
      String(process.env[`META_ADS_TOKEN_${n}`] || '').trim() ||
      String(process.env[`META_ADS_ACCESS_TOKEN_${n}`] || '').trim() ||
      listed[idx] ||
      shared;
    return {
      id,
      token,
      slot: n,
      tokenEnv: `META_ADS_TOKEN_${n}`,
    };
  });
}

function metaMissing() {
  const configs = loadMetaAccountConfigs();
  if (!configs.length) return ['META_AD_ACCOUNT_ID'];
  const missing = configs.filter((c) => !c.token).map((c) => c.tokenEnv);
  return missing;
}

let googleTokenCache = { access: '', exp: 0 };

function googleMissing() {
  return missingList([
    ['GOOGLE_ADS_DEVELOPER_TOKEN', GOOGLE_ADS_DEVELOPER_TOKEN],
    ['GOOGLE_ADS_CLIENT_ID', GOOGLE_ADS_CLIENT_ID],
    ['GOOGLE_ADS_CLIENT_SECRET', GOOGLE_ADS_CLIENT_SECRET],
    ['GOOGLE_ADS_REFRESH_TOKEN', GOOGLE_ADS_REFRESH_TOKEN],
  ]);
}

function emptyTotals() {
  return { spend: 0, impressions: 0, clicks: 0, conversions: 0, conversion_value: 0, cpc: 0, ctr: 0, roas: 0 };
}

function withRates(row) {
  const out = { ...emptyTotals(), ...row };
  out.spend = round2(out.spend);
  out.conversion_value = round2(out.conversion_value);
  out.cpc = out.clicks > 0 ? round2(out.spend / out.clicks) : 0;
  out.ctr = out.impressions > 0 ? round2((out.clicks / out.impressions) * 100) : 0;
  out.roas = out.spend > 0 ? round2(out.conversion_value / out.spend) : 0;
  return out;
}

function addTotals(a, b) {
  return withRates({
    spend: (a.spend || 0) + (b.spend || 0),
    impressions: (a.impressions || 0) + (b.impressions || 0),
    clicks: (a.clicks || 0) + (b.clicks || 0),
    conversions: (a.conversions || 0) + (b.conversions || 0),
    conversion_value: (a.conversion_value || 0) + (b.conversion_value || 0),
  });
}

async function googleAccessToken() {
  const now = Date.now();
  if (googleTokenCache.access && googleTokenCache.exp > now + 30_000) {
    return googleTokenCache.access;
  }
  const body = new URLSearchParams({
    client_id: GOOGLE_ADS_CLIENT_ID,
    client_secret: GOOGLE_ADS_CLIENT_SECRET,
    refresh_token: GOOGLE_ADS_REFRESH_TOKEN,
    grant_type: 'refresh_token',
  });
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
    signal: AbortSignal.timeout(12000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || !json.access_token) {
    throw new Error(json.error_description || json.error || `OAuth Google ${res.status}`);
  }
  googleTokenCache = {
    access: json.access_token,
    exp: now + Math.max(60, Number(json.expires_in) || 3500) * 1000,
  };
  return googleTokenCache.access;
}

function pickGoogleRow(row, path) {
  const camel = path.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
  const parts = path.split('.');
  let cur = row;
  for (const p of parts) {
    cur = cur?.[p];
  }
  if (cur != null) return cur;
  let alt = row;
  for (const p of camel.split('.')) alt = alt?.[p];
  return alt;
}

async function googleAdsSearch(query) {
  const access = await googleAccessToken();
  const cid = GOOGLE_ADS_CUSTOMER_ID;
  const url = `https://googleads.googleapis.com/${GOOGLE_ADS_API_VERSION}/customers/${cid}/googleAds:search`;
  const headers = {
    Authorization: `Bearer ${access}`,
    'developer-token': GOOGLE_ADS_DEVELOPER_TOKEN,
    'Content-Type': 'application/json',
  };
  if (GOOGLE_ADS_LOGIN_CUSTOMER_ID) {
    headers['login-customer-id'] = GOOGLE_ADS_LOGIN_CUSTOMER_ID;
  }
  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({ query }),
    signal: AbortSignal.timeout(15000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg =
      json?.error?.message ||
      json?.error?.details?.[0]?.errors?.[0]?.message ||
      `Google Ads HTTP ${res.status}`;
    throw new Error(msg);
  }
  return Array.isArray(json.results) ? json.results : [];
}

function googleMetricsFromRow(row) {
  const metrics = row.metrics || {};
  return withRates({
    spend: microsToAmount(metrics.costMicros ?? metrics.cost_micros),
    impressions: Number(metrics.impressions || 0),
    clicks: Number(metrics.clicks || 0),
    conversions: Number(metrics.conversions || 0),
    conversion_value: Number(metrics.conversionsValue ?? metrics.conversions_value ?? 0),
  });
}

async function fetchGoogleAds() {
  const missing = googleMissing();
  const base = {
    connected: false,
    platform: 'google',
    customer_id: GOOGLE_ADS_CUSTOMER_ID,
    display_id: formatGoogleCid(GOOGLE_ADS_CUSTOMER_ID),
    advertiser_id: GOOGLE_ADS_ADVERTISER_ID || null,
    advertiser_display_id: GOOGLE_ADS_ADVERTISER_ID ? formatGoogleCid(GOOGLE_ADS_ADVERTISER_ID) : null,
    name: GOOGLE_ADS_ACCOUNT_NAME,
    missing_env: missing,
    token_ready: missing.length === 0,
  };
  if (missing.length) {
    return { ...base, reason: `Faltan env: ${missing.join(', ')}` };
  }
  try {
    const [custRows, last7, prev7, last30, campaigns] = await Promise.all([
      googleAdsSearch(
        'SELECT customer.id, customer.descriptive_name, customer.currency_code FROM customer LIMIT 1'
      ),
      googleAdsSearch(
        'SELECT metrics.cost_micros, metrics.impressions, metrics.clicks, metrics.conversions, metrics.conversions_value FROM customer WHERE segments.date DURING LAST_7_DAYS'
      ),
      googleAdsSearch(
        'SELECT metrics.cost_micros, metrics.impressions, metrics.clicks, metrics.conversions, metrics.conversions_value FROM customer WHERE segments.date DURING LAST_14_DAYS'
      ),
      googleAdsSearch(
        'SELECT metrics.cost_micros, metrics.impressions, metrics.clicks, metrics.conversions, metrics.conversions_value FROM customer WHERE segments.date DURING LAST_30_DAYS'
      ),
      googleAdsSearch(
        `SELECT campaign.id, campaign.name, campaign.status, metrics.cost_micros, metrics.impressions, metrics.clicks, metrics.conversions, metrics.conversions_value
         FROM campaign
         WHERE segments.date DURING LAST_30_DAYS AND campaign.status != 'REMOVED'
         ORDER BY metrics.cost_micros DESC
         LIMIT 25`
      ),
    ]);
    const cust = custRows[0]?.customer || {};
    const last7t = last7.reduce((acc, row) => addTotals(acc, googleMetricsFromRow(row)), emptyTotals());
    const last14t = prev7.reduce((acc, row) => addTotals(acc, googleMetricsFromRow(row)), emptyTotals());
    const last30t = last30.reduce((acc, row) => addTotals(acc, googleMetricsFromRow(row)), emptyTotals());
    const prev7t = withRates({
      spend: Math.max(0, last14t.spend - last7t.spend),
      impressions: Math.max(0, last14t.impressions - last7t.impressions),
      clicks: Math.max(0, last14t.clicks - last7t.clicks),
      conversions: Math.max(0, last14t.conversions - last7t.conversions),
      conversion_value: Math.max(0, last14t.conversion_value - last7t.conversion_value),
    });
    const campaignMap = new Map();
    for (const row of campaigns) {
      const c = row.campaign || {};
      const id = String(c.id || pickGoogleRow(row, 'campaign.id') || c.name || '');
      const mapped = {
        id,
        name: c.name || 'Campaña',
        status: c.status || '',
        ...googleMetricsFromRow(row),
      };
      if (!campaignMap.has(id)) campaignMap.set(id, mapped);
      else {
        const prev = campaignMap.get(id);
        campaignMap.set(id, { ...prev, ...addTotals(prev, mapped), name: mapped.name, status: mapped.status });
      }
    }
    const campaignRows = [...campaignMap.values()].sort((a, b) => b.spend - a.spend).slice(0, 25);
    return {
      ...base,
      connected: true,
      reason: null,
      currency: cust.currencyCode || cust.currency_code || 'ARS',
      name: cust.descriptiveName || cust.descriptive_name || GOOGLE_ADS_ACCOUNT_NAME,
      last_7d: last7t,
      prev_7d: prev7t,
      last_30d: last30t,
      campaigns: campaignRows,
    };
  } catch (e) {
    return { ...base, connected: false, error: redact(e.message || e) };
  }
}

const MSG_ACTION_TYPES = [
  'onsite_conversion.messaging_conversation_started_7d',
  'onsite_conversion.messaging_first_reply',
  'onsite_conversion.total_messaging_connection',
  'onsite_conversion.click_to_whatsapp',
  'click_to_whatsapp',
  'onsite_conversion.messaging_user_subscribed',
];

const ACCOUNT_STATUS_LABEL = {
  1: 'ACTIVE',
  2: 'DISABLED',
  3: 'UNSETTLED',
  7: 'PENDING_RISK_REVIEW',
  8: 'PENDING_SETTLEMENT',
  9: 'IN_GRACE_PERIOD',
  100: 'PENDING_CLOSURE',
  101: 'CLOSED',
};

function actionValue(list, types) {
  if (!Array.isArray(list) || !types?.length) return 0;
  for (const t of types) {
    const hit = list.find((a) => String(a.action_type || '') === t);
    if (hit) return Number(hit.value) || 0;
  }
  return 0;
}

function actionValueFuzzy(list, re) {
  if (!Array.isArray(list)) return 0;
  const hit = list.find((a) => re.test(String(a.action_type || '')));
  return hit ? Number(hit.value) || 0 : 0;
}

function centsToAmount(raw) {
  const n = Number(raw);
  if (!Number.isFinite(n) || n === 0) return 0;
  return round2(n / 100);
}

function emptyMetaMetrics() {
  return {
    spend: 0,
    impressions: 0,
    reach: 0,
    frequency: 0,
    cpm: 0,
    clicks: 0,
    link_clicks: 0,
    ctr: 0,
    ctr_link: 0,
    cpc: 0,
    cpc_link: 0,
    landing_page_views: 0,
    cost_per_landing_view: 0,
    landing_vs_link_pct: 0,
    messaging_conversations: 0,
    cost_per_messaging: 0,
    conversions: 0,
    conversion_value: 0,
    roas: 0,
    cpp: 0,
  };
}

function deriveMetaRates(row) {
  const m = { ...emptyMetaMetrics(), ...row };
  m.spend = round2(m.spend);
  m.frequency = m.reach > 0 ? round2(m.impressions / m.reach) : Number(m.frequency || 0);
  m.cpm = m.impressions > 0 ? round2((m.spend / m.impressions) * 1000) : 0;
  m.cpp = m.reach > 0 ? round2((m.spend / m.reach) * 1000) : 0;
  m.ctr = m.impressions > 0 ? round2((m.clicks / m.impressions) * 100) : 0;
  m.ctr_link = m.impressions > 0 ? round2((m.link_clicks / m.impressions) * 100) : 0;
  m.cpc = m.clicks > 0 ? round2(m.spend / m.clicks) : 0;
  m.cpc_link = m.link_clicks > 0 ? round2(m.spend / m.link_clicks) : 0;
  m.cost_per_landing_view = m.landing_page_views > 0 ? round2(m.spend / m.landing_page_views) : 0;
  m.landing_vs_link_pct =
    m.link_clicks > 0 ? round2((m.landing_page_views / m.link_clicks) * 100) : 0;
  m.cost_per_messaging =
    m.messaging_conversations > 0 ? round2(m.spend / m.messaging_conversations) : 0;
  m.roas = m.spend > 0 ? round2(m.conversion_value / m.spend) : 0;
  return m;
}

function addMetaMetrics(a, b) {
  return deriveMetaRates({
    spend: (a.spend || 0) + (b.spend || 0),
    impressions: (a.impressions || 0) + (b.impressions || 0),
    reach: (a.reach || 0) + (b.reach || 0),
    clicks: (a.clicks || 0) + (b.clicks || 0),
    link_clicks: (a.link_clicks || 0) + (b.link_clicks || 0),
    landing_page_views: (a.landing_page_views || 0) + (b.landing_page_views || 0),
    messaging_conversations: (a.messaging_conversations || 0) + (b.messaging_conversations || 0),
    conversions: (a.conversions || 0) + (b.conversions || 0),
    conversion_value: (a.conversion_value || 0) + (b.conversion_value || 0),
  });
}

function metaInsightsFromRow(row) {
  const actions = row.actions || [];
  const costs = row.cost_per_action_type || [];
  const messaging =
    actionValue(actions, MSG_ACTION_TYPES) ||
    actionValueFuzzy(actions, /messaging_conversation_started|messaging_first_reply|click_to_whatsapp|total_messaging_connection/i);
  const cpaMsg =
    actionValue(costs, MSG_ACTION_TYPES) ||
    actionValueFuzzy(costs, /messaging_conversation_started|messaging_first_reply|click_to_whatsapp/i);
  const link_clicks =
    Number(row.inline_link_clicks || 0) || actionValue(actions, ['link_click']);
  const landing_page_views = actionValue(actions, ['landing_page_view', 'omni_landing_page_view']);
  const out = deriveMetaRates({
    spend: Number(row.spend || 0),
    impressions: Number(row.impressions || 0),
    reach: Number(row.reach || 0),
    frequency: Number(row.frequency || 0),
    clicks: Number(row.clicks || 0),
    link_clicks,
    landing_page_views,
    messaging_conversations: messaging,
    conversions: actionValueFuzzy(actions, /purchase/i),
    conversion_value: actionValueFuzzy(row.action_values, /purchase/i),
  });
  if (cpaMsg > 0 && out.messaging_conversations > 0) out.cost_per_messaging = round2(cpaMsg);
  return out;
}

function metaRowToTotals(row) {
  return metaInsightsFromRow(row);
}

function rankingScore(v) {
  const s = String(v || '').toUpperCase();
  if (s.includes('BELOW')) return 3;
  if (s === 'AVERAGE') return 2;
  if (s.includes('ABOVE')) return 1;
  return 0;
}

function worstRanking(values) {
  let best = '';
  let score = 0;
  for (const v of values) {
    const sc = rankingScore(v);
    if (sc > score) {
      score = sc;
      best = String(v);
    }
  }
  return best || null;
}

function pickBreakdownWinner(rows, keyFn) {
  if (!rows.length) return null;
  const scored = rows
    .map((r) => ({
      label: keyFn(r),
      spend: r.metrics.spend || 0,
      msgs: r.metrics.messaging_conversations || 0,
      cpm: r.metrics.cost_per_messaging || 0,
    }))
    .filter((r) => r.label);
  if (!scored.length) return null;
  scored.sort((a, b) => {
    if (b.msgs !== a.msgs) return b.msgs - a.msgs;
    if (a.msgs > 0 && b.msgs > 0) return a.cpm - b.cpm;
    return b.spend - a.spend;
  });
  return scored[0].label;
}

function pickBreakdownLoser(rows, keyFn) {
  const totalSpend = rows.reduce((n, r) => n + (r.metrics.spend || 0), 0);
  const scored = rows
    .map((r) => ({
      label: keyFn(r),
      spend: r.metrics.spend || 0,
      msgs: r.metrics.messaging_conversations || 0,
    }))
    .filter((r) => r.label && r.spend > 0 && r.spend >= totalSpend * 0.05);
  if (!scored.length) return null;
  scored.sort((a, b) => a.msgs - b.msgs || b.spend - a.spend);
  return scored[0].label;
}

async function metaGet(path, search, accessToken) {
  const url = new URL(`https://graph.facebook.com/${META_GRAPH_VERSION}/${path}`);
  for (const [k, v] of Object.entries(search || {})) {
    if (v != null && v !== '') url.searchParams.set(k, String(v));
  }
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
    signal: AbortSignal.timeout(20000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json.error) {
    throw new Error(json.error?.message || `Meta Ads HTTP ${res.status}`);
  }
  return json;
}

async function metaGetSafe(path, search, accessToken) {
  try {
    return await metaGet(path, search, accessToken);
  } catch (e) {
    return { data: [], error: redact(e.message || e) };
  }
}

const INSIGHT_CORE =
  'spend,impressions,reach,frequency,cpm,clicks,inline_link_clicks,ctr,actions,action_values,cost_per_action_type,campaign_id,campaign_name';
const INSIGHT_AD =
  `${INSIGHT_CORE},ad_id,ad_name,adset_name,quality_ranking,engagement_rate_ranking,conversion_rate_ranking`;

async function fetchMetaInsights(act, accessToken, extra) {
  const params = {
    fields: extra.fields || INSIGHT_CORE,
    level: extra.level || 'account',
    limit: extra.limit || '25',
  };
  if (extra.time_range) {
    params.time_range = JSON.stringify(extra.time_range);
  } else {
    params.date_preset = extra.date_preset || 'last_7d';
  }
  if (extra.breakdowns) params.breakdowns = extra.breakdowns;
  return metaGetSafe(`${act}/insights`, params, accessToken);
}

function artYmdDaysAgo(daysAgo) {
  const art = new Date(Date.now() - 3 * 3600 * 1000);
  art.setUTCDate(art.getUTCDate() - Number(daysAgo || 0));
  return art.toISOString().slice(0, 10);
}

function mapBreakdownRows(json, keys) {
  return (json.data || []).map((row) => ({
    dims: Object.fromEntries(keys.map((k) => [k, row[k] || ''])),
    metrics: metaInsightsFromRow(row),
  }));
}

async function fetchMetaAccount(accountId, accessToken) {
  const act = `act_${accountId}`;
  const [
    account,
    campStruct,
    last7,
    last30,
    prev7,
    camp7,
    camp30,
    ads7,
    place,
    device,
    demo,
    region,
  ] = await Promise.all([
    metaGet(
      act,
      { fields: 'name,currency,account_status,disable_reason,amount_spent' },
      accessToken
    ),
    metaGetSafe(
      `${act}/campaigns`,
      {
        fields:
          'id,name,status,effective_status,objective,daily_budget,lifetime_budget,budget_remaining,start_time,stop_time',
        limit: '50',
        effective_status: JSON.stringify([
          'ACTIVE',
          'PAUSED',
          'CAMPAIGN_PAUSED',
          'WITH_ISSUES',
          'IN_PROCESS',
          'PENDING_REVIEW',
        ]),
      },
      accessToken
    ),
    fetchMetaInsights(act, accessToken, { date_preset: 'last_7d', level: 'account' }),
    fetchMetaInsights(act, accessToken, { date_preset: 'last_30d', level: 'account' }),
    fetchMetaInsights(act, accessToken, {
      level: 'account',
      time_range: { since: artYmdDaysAgo(14), until: artYmdDaysAgo(8) },
    }),
    fetchMetaInsights(act, accessToken, { date_preset: 'last_7d', level: 'campaign', limit: '25' }),
    fetchMetaInsights(act, accessToken, { date_preset: 'last_30d', level: 'campaign', limit: '25' }),
    fetchMetaInsights(act, accessToken, {
      date_preset: 'last_7d',
      level: 'ad',
      fields: INSIGHT_AD,
      limit: '15',
    }),
    fetchMetaInsights(act, accessToken, {
      date_preset: 'last_7d',
      level: 'account',
      breakdowns: 'publisher_platform,platform_position',
    }),
    fetchMetaInsights(act, accessToken, {
      date_preset: 'last_7d',
      level: 'account',
      breakdowns: 'impression_device',
    }),
    fetchMetaInsights(act, accessToken, {
      date_preset: 'last_7d',
      level: 'account',
      breakdowns: 'age,gender',
    }),
    fetchMetaInsights(act, accessToken, {
      date_preset: 'last_7d',
      level: 'account',
      breakdowns: 'region',
    }),
  ]);

  const last7t = (last7.data || []).reduce((acc, row) => addMetaMetrics(acc, metaInsightsFromRow(row)), emptyMetaMetrics());
  const last30t = (last30.data || []).reduce((acc, row) => addMetaMetrics(acc, metaInsightsFromRow(row)), emptyMetaMetrics());
  const prev7t = (prev7.data || []).reduce((acc, row) => addMetaMetrics(acc, metaInsightsFromRow(row)), emptyMetaMetrics());
  const structById = new Map((campStruct.data || []).map((c) => [String(c.id), c]));
  const campaignRows = (camp30.data || []).map((row) => {
    const id = String(row.campaign_id || '');
    const st = structById.get(id) || {};
    return {
      id,
      name: row.campaign_name || st.name || 'Campaña',
      account_id: accountId,
      account_name: account.name || act,
      status: st.effective_status || st.status || '',
      objective: st.objective || '',
      daily_budget: centsToAmount(st.daily_budget),
      lifetime_budget: centsToAmount(st.lifetime_budget),
      start_time: st.start_time || null,
      stop_time: st.stop_time || null,
      last_7d: null,
      ...metaInsightsFromRow(row),
    };
  });
  const camp7ById = new Map(
    (camp7.data || []).map((row) => [String(row.campaign_id || ''), metaInsightsFromRow(row)])
  );
  for (const c of campaignRows) {
    if (camp7ById.has(c.id)) c.last_7d = camp7ById.get(c.id);
  }
  for (const [id, st] of structById) {
    if (campaignRows.some((c) => c.id === id)) continue;
    campaignRows.push({
      id,
      name: st.name || 'Campaña',
      account_id: accountId,
      account_name: account.name || act,
      status: st.effective_status || st.status || '',
      objective: st.objective || '',
      daily_budget: centsToAmount(st.daily_budget),
      lifetime_budget: centsToAmount(st.lifetime_budget),
      start_time: st.start_time || null,
      stop_time: st.stop_time || null,
      last_7d: camp7ById.get(id) || emptyMetaMetrics(),
      ...emptyMetaMetrics(),
    });
  }
  campaignRows.sort((a, b) => b.spend - a.spend);

  const ads = (ads7.data || []).map((row) => ({
    id: String(row.ad_id || ''),
    name: row.ad_name || 'Anuncio',
    campaign: row.campaign_name || '',
    adset: row.adset_name || '',
    quality_ranking: row.quality_ranking || null,
    engagement_rate_ranking: row.engagement_rate_ranking || null,
    conversion_rate_ranking: row.conversion_rate_ranking || null,
    ...metaInsightsFromRow(row),
  }));
  const quality_rankings = {
    quality: worstRanking(ads.map((a) => a.quality_ranking)) || null,
    engagement: worstRanking(ads.map((a) => a.engagement_rate_ranking)) || null,
    conversion: worstRanking(ads.map((a) => a.conversion_rate_ranking)) || null,
  };
  last7t.quality_rankings = quality_rankings;

  const placements = mapBreakdownRows(place, ['publisher_platform', 'platform_position']);
  const devices = mapBreakdownRows(device, ['impression_device']);
  const demos = mapBreakdownRows(demo, ['age', 'gender']);
  const regions = mapBreakdownRows(region, ['region']);
  const placeLabel = (r) =>
    [r.dims.publisher_platform, r.dims.platform_position].filter(Boolean).join('_') || null;
  const breakdown_highlights = {
    best_platform: pickBreakdownWinner(placements, placeLabel),
    worst_placement: pickBreakdownLoser(placements, placeLabel),
    top_device: pickBreakdownWinner(devices, (r) => r.dims.impression_device || null),
    top_region: pickBreakdownWinner(regions, (r) => r.dims.region || null),
    top_demo: pickBreakdownWinner(demos, (r) => [r.dims.age, r.dims.gender].filter(Boolean).join(' ') || null),
  };

  const statusCode = Number(account.account_status);
  return {
    connected: true,
    account_id: accountId,
    act_id: act,
    name: account.name || 'Meta Ads',
    currency: account.currency || 'ARS',
    account_status: ACCOUNT_STATUS_LABEL[statusCode] || String(account.account_status || ''),
    disable_reason: account.disable_reason || null,
    amount_spent_lifetime: centsToAmount(account.amount_spent),
    last_7d: last7t,
    prev_7d: prev7t,
    last_30d: last30t,
    campaigns: campaignRows.slice(0, 25),
    ads: ads.slice(0, 12),
    breakdowns: { placements, devices, demos, regions },
    breakdown_highlights,
    quality_rankings,
    metrics_summary: {
      date_preset: 'last_7d',
      ...last7t,
      quality_rankings,
    },
    insight_errors: [last7.error, last30.error, camp30.error, place.error, region.error].filter(Boolean),
  };
}

async function fetchMetaAds() {
  const configs = loadMetaAccountConfigs();
  const missing = metaMissing();
  const base = {
    connected: false,
    platform: 'meta',
    account_id: configs[0]?.id || null,
    act_id: configs[0]?.id ? `act_${configs[0].id}` : null,
    account_ids: configs.map((c) => c.id),
    accounts: configs.map((c) => ({ account_id: c.id, act_id: `act_${c.id}` })),
    missing_env: missing,
    token_ready: missing.length === 0,
  };
  if (!configs.length) {
    return { ...base, configured: false, reason: 'Faltan env: META_AD_ACCOUNT_ID' };
  }
  if (!configs.some((c) => c.token)) {
    return { ...base, configured: false, reason: `Faltan env: ${missing.join(', ')}` };
  }
  const parts = await Promise.all(
    configs.map(async (c) => {
      if (!c.token) {
        return {
          connected: false,
          account_id: c.id,
          act_id: `act_${c.id}`,
          name: `act_${c.id}`,
          error: `Falta ${c.tokenEnv}`,
          last_7d: emptyMetaMetrics(),
          prev_7d: emptyMetaMetrics(),
          last_30d: emptyMetaMetrics(),
          campaigns: [],
          breakdown_highlights: {},
        };
      }
      try {
        return await fetchMetaAccount(c.id, c.token);
      } catch (e) {
        return {
          connected: false,
          account_id: c.id,
          act_id: `act_${c.id}`,
          name: `act_${c.id}`,
          error: redact(e.message || e),
          last_7d: emptyMetaMetrics(),
          prev_7d: emptyMetaMetrics(),
          last_30d: emptyMetaMetrics(),
          campaigns: [],
          breakdown_highlights: {},
        };
      }
    })
  );
  const ok = parts.filter((p) => p.connected);
  const last7t = ok.reduce((acc, p) => addMetaMetrics(acc, p.last_7d || emptyMetaMetrics()), emptyMetaMetrics());
  const last30t = ok.reduce((acc, p) => addMetaMetrics(acc, p.last_30d || emptyMetaMetrics()), emptyMetaMetrics());
  const prev7t = ok.reduce((acc, p) => addMetaMetrics(acc, p.prev_7d || emptyMetaMetrics()), emptyMetaMetrics());
  const quality_rankings = {
    quality: worstRanking(ok.map((p) => p.quality_rankings?.quality)),
    engagement: worstRanking(ok.map((p) => p.quality_rankings?.engagement)),
    conversion: worstRanking(ok.map((p) => p.quality_rankings?.conversion)),
  };
  last7t.quality_rankings = quality_rankings;
  const placements = ok.flatMap((p) => p.breakdowns?.placements || []);
  const devices = ok.flatMap((p) => p.breakdowns?.devices || []);
  const demos = ok.flatMap((p) => p.breakdowns?.demos || []);
  const regions = ok.flatMap((p) => p.breakdowns?.regions || []);
  const placeLabel = (r) =>
    [r.dims?.publisher_platform, r.dims?.platform_position].filter(Boolean).join('_') || null;
  const breakdown_highlights = {
    best_platform: pickBreakdownWinner(placements, placeLabel),
    worst_placement: pickBreakdownLoser(placements, placeLabel),
    top_device: pickBreakdownWinner(devices, (r) => r.dims?.impression_device || null),
    top_region: pickBreakdownWinner(regions, (r) => r.dims?.region || null),
    top_demo: pickBreakdownWinner(demos, (r) => [r.dims?.age, r.dims?.gender].filter(Boolean).join(' ') || null),
  };
  const campaignRows = parts
    .flatMap((p) => p.campaigns || [])
    .sort((a, b) => b.spend - a.spend)
    .slice(0, 25);
  const currencies = [...new Set(ok.map((p) => p.currency).filter(Boolean))];
  const names = ok.map((p) => p.name).filter(Boolean);
  const errors = parts.filter((p) => p.error).map((p) => `${p.act_id}: ${p.error}`);
  return {
    ...base,
    configured: true,
    connected: ok.length > 0,
    reason: ok.length ? null : errors.join(' · ') || 'Ninguna cuenta Meta respondió',
    error: ok.length ? null : errors[0] || null,
    name: names.length ? names.join(' + ') : 'Meta Ads',
    currency: currencies[0] || 'ARS',
    currencies,
    account_status: ok.length === parts.length ? 'ok' : `${ok.length}/${parts.length} cuentas`,
    last_7d: last7t,
    prev_7d: prev7t,
    last_30d: last30t,
    campaigns: campaignRows,
    ads: ok.flatMap((p) => p.ads || []).slice(0, 20),
    breakdown_highlights,
    quality_rankings,
    metrics_summary: {
      date_preset: 'last_7d',
      ...last7t,
      quality_rankings,
    },
    accounts: parts.map((p) => ({
      account_id: p.account_id,
      act_id: p.act_id,
      name: p.name,
      currency: p.currency || null,
      connected: Boolean(p.connected),
      error: p.error || null,
      last_7d: p.last_7d,
      prev_7d: p.prev_7d || null,
      last_30d: p.last_30d,
      metrics_summary: p.metrics_summary || null,
      breakdown_highlights: p.breakdown_highlights || null,
      account_status: p.account_status || null,
    })),
    partial: ok.length > 0 && ok.length < parts.length,
    warnings: errors,
  };
}

function compactPlatform(p) {
  if (!p) return { connected: false };
  return {
    connected: Boolean(p.connected),
    platform: p.platform,
    name: p.name || null,
    currency: p.currency || null,
    display_id: p.display_id || p.act_id || p.account_id || null,
    account_ids: p.account_ids || p.accounts?.map((a) => a.account_id) || null,
    accounts: (p.accounts || []).map((a) => ({
      name: a.name,
      act_id: a.act_id,
      connected: a.connected,
      error: a.error || null,
      account_status: a.account_status || null,
      last_7d: a.last_7d
        ? {
            spend: a.last_7d.spend,
            messaging_conversations: a.last_7d.messaging_conversations,
            cost_per_messaging: a.last_7d.cost_per_messaging,
            frequency: a.last_7d.frequency,
            cpm: a.last_7d.cpm,
            ctr_link: a.last_7d.ctr_link,
            landing_vs_link_pct: a.last_7d.landing_vs_link_pct,
          }
        : null,
      breakdown_highlights: a.breakdown_highlights || null,
    })),
    last_7d: p.last_7d || null,
    prev_7d: p.prev_7d || null,
    last_30d: p.last_30d || null,
    metrics_summary: p.metrics_summary || null,
    breakdown_highlights: p.breakdown_highlights || null,
    quality_rankings: p.quality_rankings || null,
    ads: (p.ads || []).slice(0, 8).map((a) => ({
      name: a.name,
      campaign: a.campaign,
      spend: a.spend,
      messaging_conversations: a.messaging_conversations,
      cost_per_messaging: a.cost_per_messaging,
      quality_ranking: a.quality_ranking,
      engagement_rate_ranking: a.engagement_rate_ranking,
      conversion_rate_ranking: a.conversion_rate_ranking,
    })),
    campaigns: (p.campaigns || []).slice(0, 15).map((c) => ({
      name: c.name,
      status: c.status || '',
      objective: c.objective || '',
      spend: c.spend,
      clicks: c.clicks,
      impressions: c.impressions,
      conversions: c.conversions,
      messaging_conversations: c.messaging_conversations,
      cost_per_messaging: c.cost_per_messaging,
      frequency: c.frequency,
      landing_vs_link_pct: c.landing_vs_link_pct,
      cpc: c.cpc,
      ctr: c.ctr,
      roas: c.roas,
      last_7d: c.last_7d
        ? {
            spend: c.last_7d.spend,
            messaging_conversations: c.last_7d.messaging_conversations,
            cost_per_messaging: c.last_7d.cost_per_messaging,
          }
        : null,
    })),
    missing_env: p.missing_env || [],
    reason: p.reason || null,
    error: p.error || null,
  };
}

async function fetchAdsSnapshot() {
  const [google, meta] = await Promise.all([fetchGoogleAds(), fetchMetaAds()]);
  const connected = Boolean(google.connected || meta.connected);
  return {
    connected,
    google,
    meta,
    campaigns: [
      ...(google.campaigns || []).map((c) => ({ ...c, platform: 'google' })),
      ...(meta.campaigns || []).map((c) => ({ ...c, platform: 'meta' })),
    ]
      .sort((a, b) => b.spend - a.spend)
      .slice(0, 30),
    reason: connected
      ? null
      : [google.error || google.reason, meta.error || meta.reason].filter(Boolean).join(' · '),
  };
}

module.exports = {
  fetchAdsSnapshot,
  compactPlatform,
  googleMissing,
  metaMissing,
};
