#!/bin/bash
# Diagnóstico: por qué Flor dice "no trabajamos con ese hotel"
# Uso: cd /root/checkin24hs && bash scripts/verificar_flor_hoteles_supabase.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== 1. Logs Flor (últimas consultas de catálogo) ==="
docker service logs checkin24hs_whatsapp --tail 80 2>&1 | grep -iE 'Flor: usando|consultarCatalogoHoteles|sin resultados|hotels devolvió 0|Flor/Supabase' | tail -20 || true
docker service logs checkin24hs_whatsapp2 --tail 40 2>&1 | grep -iE 'Flor: usando|consultarCatalogoHoteles|sin resultados|hotels devolvió 0' | tail -10 || true

echo ""
echo "=== 2. Supabase: hoteles activos (requiere SUPABASE_URL + SUPABASE_ANON_KEY en .env o contenedor) ==="
CID=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)
if [ -z "$CID" ]; then
  echo "WARN: contenedor whatsapp no encontrado"
  exit 0
fi

docker exec "$CID" node -e "
const ws = require('ws');
const { createClient } = require('@supabase/supabase-js');
const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;
if (!url || !key) { console.log('ERROR: SUPABASE_URL/ANON_KEY no configurados en contenedor'); process.exit(0); }
const sb = createClient(url, key, { realtime: { transport: ws } });
(async () => {
  const { data, error } = await sb.from('hotels').select('id,name,status,flor_info').order('name');
  if (error) { console.log('ERROR hotels:', error.message); return; }
  const list = data || [];
  const active = list.filter(h => !['inactivo','inactive'].includes(String(h.status||'').toLowerCase()));
  console.log('Total hoteles:', list.length, '| Activos:', active.length);
  active.forEach(h => {
    const alias = (h.flor_info && h.flor_info.alias_busqueda) || '';
    console.log(' -', h.name, '| status:', h.status || 'null', alias ? '| alias:' + alias : '');
  });
  const fut = active.filter(h => /futangue|futanque|furangue/i.test(h.name + ' ' + ((h.flor_info&&h.flor_info.alias_busqueda)||'')));
  if (!fut.length) console.log('\\n⚠️ NO hay Hotel Futangue activo en Supabase — Flor usará frase \"no trabajamos con ese hotel\"');
  else console.log('\\n✅ Futangue encontrado:', fut.map(h=>h.name).join(', '));

  const { data: cfg } = await sb.from('system_config').select('key,value').eq('key','flor_ai_config').maybeSingle();
  if (cfg && cfg.value) {
    const c = typeof cfg.value === 'string' ? JSON.parse(cfg.value) : cfg.value;
    console.log('\\nflor_ai_config.enabled =', c.enabled);
  }
  const { data: pg } = await sb.from('system_config').select('value').eq('key','flor_general_config').maybeSingle();
  if (pg && pg.value) {
    const g = typeof pg.value === 'string' ? JSON.parse(pg.value) : pg.value;
    const p = (g.promptGeneral || '').trim();
    console.log('flor_general_config.promptGeneral:', p ? p.length + ' chars, inicio: ' + p.slice(0,60) + '...' : 'VACÍO');
  }
})();
"

echo ""
echo "=== 3. Si Futangue falta: Dashboard → Hoteles → Hotel Futangue → Sincronizar con Supabase ==="
echo "    Y en flor_info agregar alias_busqueda: Futangue, futanque, furangue, Parque Futangue"
