#!/usr/bin/env node
/**
 * Alinea flor_ai_config en Supabase con lo que ejecuta el servidor WhatsApp:
 *   model: gemini-3.1-flash-lite-preview
 *   maxTokens: 2048
 * Preserva enabled, temperature, imagen_cotizacion_url, etc.
 *
 * Uso: node scripts/update-flor-ai-config-supabase.js
 */
const SUPABASE_URL = 'https://lmoeuyasuvoqhtvhkyia.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4';

const TARGET = {
  model: 'gemini-3.1-flash-lite-preview',
  maxTokens: 2048,
  provider: 'gemini',
};

async function supabaseFetch(pathname, options = {}) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${pathname}`, {
    ...options,
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      ...(options.headers || {}),
    },
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!res.ok) {
    throw new Error(`Supabase ${res.status}: ${typeof data === 'string' ? data : JSON.stringify(data)}`);
  }
  return data;
}

async function main() {
  let existing = {};
  const rows = await supabaseFetch(
    'system_config?key=eq.flor_ai_config&select=key,value,updated_at'
  );
  if (rows && rows[0] && rows[0].value) {
    existing = typeof rows[0].value === 'string' ? JSON.parse(rows[0].value) : rows[0].value;
    console.log('📦 Antes:', JSON.stringify({
      model: existing.model,
      maxTokens: existing.maxTokens,
      temperature: existing.temperature,
      updated_at: rows[0].updated_at,
    }));
  }

  const config = {
    ...existing,
    enabled: existing.enabled !== false,
    provider: TARGET.provider,
    model: TARGET.model,
    maxTokens: TARGET.maxTokens,
    temperature: existing.temperature !== undefined ? existing.temperature : 0.3,
  };

  await supabaseFetch('system_config?on_conflict=key', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Prefer: 'resolution=merge-duplicates,return=representation',
    },
    body: JSON.stringify({
      key: 'flor_ai_config',
      value: JSON.stringify(config),
      updated_at: new Date().toISOString(),
    }),
  });

  const verify = await supabaseFetch(
    'system_config?key=eq.flor_ai_config&select=key,updated_at,value'
  );
  const saved =
    typeof verify[0].value === 'string' ? JSON.parse(verify[0].value) : verify[0].value;
  const ok = saved.model === TARGET.model && Number(saved.maxTokens) === TARGET.maxTokens;
  console.log(ok ? '✅ flor_ai_config alineado con servidor' : '❌ Verificación fallida');
  console.log('🕐 updated_at:', verify[0].updated_at);
  console.log('📋 Ahora:', JSON.stringify({
    model: saved.model,
    maxTokens: saved.maxTokens,
    temperature: saved.temperature,
    enabled: saved.enabled,
  }));
  console.log('ℹ️  Gobernanza: si EasyPanel tiene GEMINI_MODEL, ese env pisa flor_ai_config.model en runtime.');
  console.log('ℹ️  Piso de tokens en servidor: FLOR_MAX_OUTPUT_TOKENS_MIN (default 1500) evita cortes si alguien baja maxTokens.');
}

main().catch((e) => {
  console.error('❌ Error:', e.message);
  process.exit(1);
});
