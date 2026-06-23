#!/bin/bash
# Parche urgente: Supabase + Node 20 requiere ws (sin esto Flor no ve hoteles).
# Uso: cd /root/checkin24hs && bash scripts/patch_supabase_ws_servidor.sh

set -euo pipefail
cd "$(dirname "$0")/.."
FILE="whatsapp-server/whatsapp-server-baileys.js"

if [ ! -f "$FILE" ]; then
  echo "ERROR: no existe $FILE"
  exit 1
fi

python3 << 'PY'
from pathlib import Path
p = Path("whatsapp-server/whatsapp-server-baileys.js")
t = p.read_text(encoding="utf-8")

old = """try {
    supabase = createClient(CONFIG.SUPABASE.url, CONFIG.SUPABASE.anonKey);
    console.log('✅ Cliente de Supabase inicializado');"""

new = """try {
    const ws = require('ws');
    supabase = createClient(CONFIG.SUPABASE.url, CONFIG.SUPABASE.anonKey, {
        realtime: { transport: ws }
    });
    console.log('✅ Cliente de Supabase inicializado');"""

if "realtime: { transport: ws }" in t:
    print("OK: parche ws ya aplicado en repo local")
elif old in t:
    t = t.replace(old, new, 1)
    p.write_text(t, encoding="utf-8")
    print("OK: parche ws aplicado")
else:
    raise SystemExit("ERROR: no encontré bloque createClient — revisar manualmente")
PY

echo ""
echo "=== Verificar ws en package.json ==="
grep -q '"ws"' whatsapp-server/package.json && echo "OK: ws en package.json" || echo "WARN: falta ws en package.json"

echo ""
echo "=== Rebuild imagen WhatsApp (L1 + L2) ==="
docker build --no-cache -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --force checkin24hs_whatsapp
docker service update --force checkin24hs_whatsapp2

echo ""
echo "=== Esperar arranque y verificar ==="
sleep 20
CID=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)
docker exec "$CID" grep -A8 'CLIENTE DE SUPABASE' /app/whatsapp-server-baileys.js | head -10
echo ""
docker service logs checkin24hs_whatsapp --tail 25 2>&1 | grep -iE 'Supabase inicializado|Error inicializando|catálogo al arranque' || true

echo ""
echo "=== Test catálogo desde contenedor ==="
docker exec "$CID" node -e "
const ws = require('ws');
const { createClient } = require('@supabase/supabase-js');
const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, { realtime: { transport: ws } });
(async () => {
  const { data, error } = await sb.from('hotels').select('name,status').eq('status','Activo');
  if (error) { console.log('ERROR:', error.message); return; }
  console.log('Hoteles activos:', (data||[]).length, (data||[]).map(h=>h.name).join(', '));
})();
"

echo ""
echo "Listo. Probá WhatsApp: 'información de Corralco'"
