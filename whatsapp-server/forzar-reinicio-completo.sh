#!/bin/bash
# 🔄 Forzar reinicio completo del servicio

echo "=============================================================="
echo "🔄 FORZANDO REINICIO COMPLETO"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Obtener contenedor actual
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "1️⃣  Contenedor actual: $CONTAINER_ID"
echo ""

# 2. Copiar archivo actualizado
echo "2️⃣  Copiando archivo actualizado..."
docker cp whatsapp-server/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "   ✅ Archivo copiado"
echo ""

# 3. Verificar que se copió
echo "3️⃣  Verificando archivo copiado..."
docker exec $CONTAINER_ID sh -c "grep -n 'let qrExpirationTimer' /app/whatsapp-server-baileys.js" && echo "   ✅ Variable encontrada" || echo "   ❌ Variable no encontrada"
echo ""

# 4. Forzar actualización del servicio (esto recreará el contenedor)
echo "4️⃣  Forzando actualización del servicio Docker Swarm..."
docker service update --force checkin24hs_whatsapp
echo "   ✅ Servicio actualizado"
echo ""

# 5. Esperar a que se recree el contenedor
echo "5️⃣  Esperando a que se recree el contenedor (60 segundos)..."
sleep 60
echo "   ✅ Espera completada"
echo ""

# 6. Obtener nuevo contenedor
echo "6️⃣  Obteniendo nuevo contenedor..."
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "   Nuevo contenedor: $NEW_CONTAINER_ID"
echo ""

# 7. Copiar archivo al nuevo contenedor
echo "7️⃣  Copiando archivo al nuevo contenedor..."
docker cp whatsapp-server/whatsapp-server-baileys.js $NEW_CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "   ✅ Archivo copiado"
echo ""

# 8. Reiniciar el nuevo contenedor
echo "8️⃣  Reiniciando contenedor..."
docker restart $NEW_CONTAINER_ID
echo "   ✅ Contenedor reiniciado"
echo ""

# 9. Esperar
echo "9️⃣  Esperando 30 segundos..."
sleep 30
echo ""

# 10. Verificar
echo "🔟 Verificando que funcione..."
timeout 10 curl -s --max-time 5 http://localhost:3001/api/health && echo "   ✅ Servidor responde" || echo "   ⚠️  Servidor no responde"
echo ""

# 11. Ver logs
echo "1️⃣1️⃣  Últimos logs..."
docker service logs checkin24hs_whatsapp --tail 15 | grep -E "Servidor iniciado|Error|error|qrExpirationTimer"
echo ""

echo "=============================================================="
echo "✅ PROCESO COMPLETADO"
echo "=============================================================="
echo ""
