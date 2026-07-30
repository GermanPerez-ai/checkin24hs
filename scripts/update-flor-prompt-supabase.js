#!/usr/bin/env node
/**
 * Actualiza promptGeneral en system_config.flor_general_config (Supabase).
 * Uso: node scripts/update-flor-prompt-supabase.js
 */
const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://lmoeuyasuvoqhtvhkyia.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4';

const PROMPT_PATH = path.join(__dirname, '..', 'docs', 'flor-prompt-v41.txt');

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
  const promptGeneral = fs.readFileSync(PROMPT_PATH, 'utf8').trim();
  console.log(`📋 Prompt V4.1: ${promptGeneral.length} caracteres`);

  let existing = {};
  try {
    const rows = await supabaseFetch(
      'system_config?key=eq.flor_general_config&select=key,value,updated_at'
    );
    if (rows && rows[0] && rows[0].value) {
      existing = typeof rows[0].value === 'string' ? JSON.parse(rows[0].value) : rows[0].value;
      console.log('📦 Config existente encontrada; se preservan name, greeting, multimodal, etc.');
    }
  } catch (e) {
    console.warn('⚠️ No se pudo leer config previa (se creará nueva):', e.message);
  }

  const config = {
    name: existing.name || 'Flor IA 🌸',
    role: existing.role || 'Agente Multimodal de Conversación',
    greeting: existing.greeting || '',
    personality: existing.personality || '',
    promptGeneral,
    multimodal: existing.multimodal || {
      audio: { enabled: true, maxDuration: 45 },
      imageInput: { enabled: true },
      imageOutput: {
        enabled: true,
        apiEndpoint: '/api/hoteles/imagen/{nombre_hotel}',
      },
    },
  };

  const payload = {
    key: 'flor_general_config',
    value: JSON.stringify(config),
    updated_at: new Date().toISOString(),
  };

  await supabaseFetch('system_config?on_conflict=key', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Prefer: 'resolution=merge-duplicates,return=representation',
    },
    body: JSON.stringify(payload),
  });

  const verify = await supabaseFetch(
    'system_config?key=eq.flor_general_config&select=key,updated_at,value'
  );
  const saved = verify[0];
  const savedPrompt =
    typeof saved.value === 'string'
      ? JSON.parse(saved.value).promptGeneral
      : saved.value.promptGeneral;

  const ok =
    savedPrompt &&
    savedPrompt.includes('ASESORÍA Y DESTINOS') &&
    savedPrompt.includes('V.4.1');
  console.log(ok ? '✅ Prompt V4.1 guardado en Supabase (flor_general_config)' : '❌ Verificación fallida');
  console.log('🕐 updated_at:', saved.updated_at);
  console.log('🔤 Inicio:', savedPrompt.slice(0, 90).replace(/\n/g, ' ') + '...');
}

main().catch((e) => {
  console.error('❌ Error:', e.message);
  process.exit(1);
});
