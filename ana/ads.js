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

function metaPurchaseValue(row) {
  const values = Array.isArray(row.action_values) ? row.action_values : [];
  const hit = values.find((a) => /purchase/i.test(String(a.action_type || '')));
  if (hit) return Number(hit.value) || 0;
  return 0;
}

function metaPurchases(row) {
  const actions = Array.isArray(row.actions) ? row.actions : [];
  const hit = actions.find((a) => /purchase/i.test(String(a.action_type || '')));
  return hit ? Number(hit.value) || 0 : 0;
}

function metaRowToTotals(row) {
  return withRates({
    spend: Number(row.spend || 0),
    impressions: Number(row.impressions || 0),
    clicks: Number(row.clicks || 0),
    conversions: metaPurchases(row),
    conversion_value: metaPurchaseValue(row),
  });
}

async function metaGet(path, search, accessToken) {
  const url = new URL(`https://graph.facebook.com/${META_GRAPH_VERSION}/${path}`);
  for (const [k, v] of Object.entries(search || {})) {
    if (v != null && v !== '') url.searchParams.set(k, String(v));
  }
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
    signal: AbortSignal.timeout(15000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json.error) {
    throw new Error(json.error?.message || `Meta Ads HTTP ${res.status}`);
  }
  return json;
}

async function fetchMetaAccount(accountId, accessToken) {
  const act = `act_${accountId}`;
  const insightFields =
    'spend,impressions,clicks,cpc,ctr,reach,actions,action_values,campaign_id,campaign_name';
  const [account, last7, last30, campaigns] = await Promise.all([
    metaGet(act, { fields: 'name,currency,account_status' }, accessToken),
    metaGet(
      `${act}/insights`,
      {
        fields: 'spend,impressions,clicks,actions,action_values',
        date_preset: 'last_7d',
        level: 'account',
      },
      accessToken
    ),
    metaGet(
      `${act}/insights`,
      {
        fields: 'spend,impressions,clicks,actions,action_values',
        date_preset: 'last_30d',
        level: 'account',
      },
      accessToken
    ),
    metaGet(
      `${act}/insights`,
      {
        fields: insightFields,
        date_preset: 'last_30d',
        level: 'campaign',
        limit: '25',
      },
      accessToken
    ),
  ]);
  const last7t = (last7.data || []).reduce((acc, row) => addTotals(acc, metaRowToTotals(row)), emptyTotals());
  const last30t = (last30.data || []).reduce((acc, row) => addTotals(acc, metaRowToTotals(row)), emptyTotals());
  const campaignRows = (campaigns.data || []).map((row) => ({
    id: String(row.campaign_id || ''),
    name: row.campaign_name || 'Campaña',
    account_id: accountId,
    account_name: account.name || act,
    status: '',
    ...metaRowToTotals(row),
  }));
  return {
    connected: true,
    account_id: accountId,
    act_id: act,
    name: account.name || 'Meta Ads',
    currency: account.currency || 'ARS',
    account_status: account.account_status,
    last_7d: last7t,
    last_30d: last30t,
    campaigns: campaignRows,
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
          last_7d: emptyTotals(),
          last_30d: emptyTotals(),
          campaigns: [],
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
          last_7d: emptyTotals(),
          last_30d: emptyTotals(),
          campaigns: [],
        };
      }
    })
  );
  const ok = parts.filter((p) => p.connected);
  const last7t = ok.reduce((acc, p) => addTotals(acc, p.last_7d), emptyTotals());
  const last30t = ok.reduce((acc, p) => addTotals(acc, p.last_30d), emptyTotals());
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
    last_30d: last30t,
    campaigns: campaignRows,
    accounts: parts.map((p) => ({
      account_id: p.account_id,
      act_id: p.act_id,
      name: p.name,
      currency: p.currency || null,
      connected: Boolean(p.connected),
      error: p.error || null,
      last_7d: p.last_7d,
      last_30d: p.last_30d,
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
      last_7d: a.last_7d || null,
    })),
    last_7d: p.last_7d || null,
    prev_7d: p.prev_7d || null,
    last_30d: p.last_30d || null,
    campaigns: (p.campaigns || []).slice(0, 15).map((c) => ({
      name: c.name,
      status: c.status || '',
      spend: c.spend,
      clicks: c.clicks,
      impressions: c.impressions,
      conversions: c.conversions,
      cpc: c.cpc,
      ctr: c.ctr,
      roas: c.roas,
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
