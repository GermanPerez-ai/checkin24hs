#!/bin/bash
# 🔧 Mapear puerto 3001 al servicio

echo "=============================================================="
echo "🔧 MAPEANDO PUERTO 3001"
echo "=============================================================="
echo ""

# Mapear puerto 3001
echo "1️⃣  Mapeando puerto 3001 al servicio..."
docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
echo ""

# Esperar a que se actualice
echo "2️⃣  Esperando a que el servicio se actualice (30 segundos)..."
sleep 30
echo ""

# Verificar mapeo
echo "3️⃣  Verificando mapeo de puertos..."
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool
echo ""

# Verificar que el puerto esté escuchando
echo "4️⃣  Verificando que el puerto esté escuchando..."
ss -tuln | grep 3001 && echo "   ✅ Puerto 3001 está escuchando" || echo "   ⚠️  Puerto 3001 aún no está escuchando"
echo ""

# Intentar conexión
echo "5️⃣  Intentando conexión..."
sleep 5
timeout 5 curl -s --max-time 3 http://localhost:3001/api/health && echo "   ✅ Servidor responde" || echo "   ⚠️  Servidor aún no responde (puede tardar unos segundos más)"
echo ""

echo "=============================================================="
echo "✅ PROCESO COMPLETADO"
echo "=============================================================="
echo ""
