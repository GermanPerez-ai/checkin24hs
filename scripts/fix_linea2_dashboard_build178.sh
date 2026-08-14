#!/bin/bash
# Fix Línea 2 en dashboard + whatsapp_instance en chats + redeploy Build 178
# Uso en servidor: cd /root/checkin24hs && bash scripts/fix_linea2_dashboard_build178.sh

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

echo "=== 1. Parche whatsapp-server (whatsapp_instance en UPDATE de chat) ==="
python3 << 'PY'
from pathlib import Path
p = Path("whatsapp-server/whatsapp-server-baileys.js")
t = p.read_text(encoding="utf-8")
old = """        const updatePayload = {
            last_message: mensajePreview,
            last_message_time: new Date().toISOString(),
            unread_count: unreadCount,
            updated_at: new Date().toISOString()
        };"""
new = """        const updatePayload = {
            last_message: mensajePreview,
            last_message_time: new Date().toISOString(),
            unread_count: unreadCount,
            updated_at: new Date().toISOString(),
            whatsapp_instance: CONFIG.INSTANCE_NUMBER
        };"""
if old in t:
    t = t.replace(old, new, 1)
    p.write_text(t, encoding="utf-8")
    print("OK: updatePayload incluye whatsapp_instance")
elif "whatsapp_instance: CONFIG.INSTANCE_NUMBER" in t and "updatePayload" in t:
    print("OK: ya parcheado")
else:
    print("WARN: no se encontró updatePayload — revisar manualmente")
PY

echo ""
echo "=== 2. Dashboard Build 178 (copiar desde repo si existe deploy/) ==="
if [ -f deploy/dashboard-html/BUILD_ID ]; then
  echo 178 > deploy/dashboard-html/BUILD_ID
fi
# Si el HTML ya tiene enrichChatsInstanceFromMessages, no tocar
if ! grep -q 'enrichChatsInstanceFromMessages' deploy/dashboard.html 2>/dev/null; then
  echo "ERROR: deploy/dashboard.html sin parche Línea 2 — hacé git pull o copiá el archivo desde tu PC"
  exit 1
fi
grep -q 'DASHBOARD_BUILD_NUMBER = 178' deploy/dashboard.html || \
  sed -i 's/DASHBOARD_BUILD_NUMBER = [0-9]*/DASHBOARD_BUILD_NUMBER = 178/' deploy/dashboard.html

echo ""
echo "=== 3. Rebuild WhatsApp (L1 + L2) ==="
docker build --no-cache -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --force checkin24hs_whatsapp
docker service update --force checkin24hs_whatsapp2

echo ""
echo "=== 4. Rebuild Dashboard (Dockerfile correcto: dashboard-html, NO deploy/Dockerfile nginx) ==="
BUILD_ID=$(cat deploy/dashboard-html/BUILD_ID 2>/dev/null | tr -d '\r\n\t ' | grep -oE '^[0-9]+$' || echo "178")
echo "BUILD_ID=$BUILD_ID"
docker build -f deploy/dashboard-html/Dockerfile \
  --build-arg BUILD_ID="$BUILD_ID" \
  --build-arg BUILD_SOURCE="fix_linea2_dashboard_build178.sh" \
  --build-arg BUILD_TIME="$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --no-cache \
  -t "easypanel/checkin24hs/dashboard:${BUILD_ID}" \
  -t easypanel/checkin24hs/dashboard:latest \
  .
docker service update --force --image "easypanel/checkin24hs/dashboard:${BUILD_ID}" checkin24hs_dashboard

echo ""
echo "=== 5. Verificación ==="
sleep 12
curl -sf https://dashboard.checkin24hs.com/build_id.txt && echo ""
curl -sf https://dashboard.checkin24hs.com/dashboard.html | grep -o 'enrichChatsInstanceFromMessages' | head -1 || true
CID=$(docker ps -q -f name=checkin24hs_whatsapp2 | head -1)
docker exec "$CID" grep -c 'whatsapp_instance: CONFIG.INSTANCE_NUMBER' /app/whatsapp-server-baileys.js || true

echo ""
echo "=== 6. Flor: revisar logs (prompt + enabled) ==="
docker service logs checkin24hs_whatsapp2 --tail 30 2>&1 | grep -iE 'Flor: usando|flor_ai_config|deshabilitada|flor_general' || true
docker service logs checkin24hs_whatsapp --tail 15 2>&1 | grep -iE 'Flor: usando|deshabilitada' || true

echo ""
echo "Listo. Abrí Chats → Línea 2 y Actualizar (Ctrl+F5)."
echo "Si Flor no usa el prompt: Dashboard → Flor IA → activar 'IA habilitada' y Guardar todo."
