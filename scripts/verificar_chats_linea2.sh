#!/bin/bash
# Verifica que Línea 2 guarde whatsapp_instance=2 y que el dashboard tenga dedupe por línea.
set -euo pipefail

echo "=== 1. WhatsApp Línea 2 — env ==="
docker service inspect checkin24hs_whatsapp2 --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' \
  | grep -E 'INSTANCE_NUMBER|SUPABASE' || true

echo ""
echo "=== 2. Código servidor — buildConversationExternalId (fix L1/L2) ==="
CID=$(docker ps -q -f name=checkin24hs_whatsapp2 | head -1)
if [ -n "$CID" ]; then
  if docker exec "$CID" grep -q 'buildConversationExternalId' /app/whatsapp-server-baileys.js 2>/dev/null; then
    echo "OK: parche instancia en whatsapp-server-baileys.js"
  else
    echo "FALTA: rebuild whatsapp-server con buildConversationExternalId"
  fi
else
  echo "WARN: contenedor whatsapp2 no encontrado"
fi

echo ""
echo "=== 3. Dashboard — dedupe por línea (wa:1: / wa:2:) ==="
BUILD=$(curl -sS https://dashboard.checkin24hs.com/build_id.txt 2>/dev/null | tr -d '\r\n' || echo "?")
echo "Build servido: $BUILD (esperado >= 177 tras deploy)"
if curl -sS https://dashboard.checkin24hs.com/dashboard.html 2>/dev/null | grep -q "wa:' + inst + ':'"; then
  echo "OK: dashboard dedupe separa Línea 1 y Línea 2"
else
  echo "FALTA: bash scripts/deploy_dashboard_servidor.sh (deploy/dashboard.html Build 177+)"
fi

echo ""
echo "=== 4. Supabase — últimos mensajes (whatsapp_instance) ==="
KEY=$(docker service inspect checkin24hs_whatsapp2 --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' \
  | grep '^SUPABASE_ANON_KEY=' | head -1 | cut -d= -f2-)
URL="https://lmoeuyasuvoqhtvhkyia.supabase.co"
if [ -n "$KEY" ]; then
  curl -sS "${URL}/rest/v1/whatsapp_messages?select=phone,whatsapp_instance,is_from_me,created_at,message&order=created_at.desc&limit=8" \
    -H "apikey: ${KEY}" -H "Authorization: Bearer ${KEY}" \
    | python3 -c "
import json,sys
rows=json.load(sys.stdin)
print('phone | inst | from_me | preview')
for r in rows:
    m=(r.get('message') or '')[:40].replace('\n',' ')
    print(f\"{r.get('phone','?')[:20]} | {r.get('whatsapp_instance','?')} | {r.get('is_from_me')} | {m}\")
" 2>/dev/null || echo "(error leyendo mensajes)"
else
  echo "SKIP: no SUPABASE_ANON_KEY en servicio"
fi

echo ""
echo "=== 5. Chats recientes por instancia ==="
if [ -n "$KEY" ]; then
  curl -sS "${URL}/rest/v1/whatsapp_chats?select=phone,whatsapp_instance,last_message_time,name&order=last_message_time.desc&limit=10" \
    -H "apikey: ${KEY}" -H "Authorization: Bearer ${KEY}" \
    | python3 -c "
import json,sys
rows=json.load(sys.stdin)
for r in rows:
    print(f\"inst={r.get('whatsapp_instance','?')} phone={str(r.get('phone',''))[:22]} name={str(r.get('name',''))[:20]}\")
" 2>/dev/null || true
fi

echo ""
echo "=== Interpretación ==="
echo "- Mensajes nuevos al 0748 deben tener whatsapp_instance=2"
echo "- Si inst=1 en mensajes al bot 0748 → rebuild whatsapp2"
echo "- Si inst=2 pero dashboard en L1 → deploy dashboard Build 177+ y Ctrl+Shift+R"
