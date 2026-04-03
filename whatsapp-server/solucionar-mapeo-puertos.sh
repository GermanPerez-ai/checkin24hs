#!/bin/bash
# 🔧 Solucionar problema de mapeo de puertos

echo "=============================================================="
echo "🔧 SOLUCIONANDO MAPEO DE PUERTOS"
echo "=============================================================="
echo ""

# 1. Verificar mapeo actual
echo "1️⃣  Mapeo actual de puertos:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool
echo ""

# 2. Eliminar y volver a agregar el mapeo de puertos
echo "2️⃣  Reconfigurando mapeo de puertos..."
docker service update --publish-rm published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
sleep 5
docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
echo "   ✅ Mapeo reconfigurado"
echo ""

# 3. Esperar a que se actualice
echo "3️⃣  Esperando a que el servicio se actualice (30 segundos)..."
sleep 30
echo ""

# 4. Verificar nuevo mapeo
echo "4️⃣  Verificando nuevo mapeo:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool
echo ""

# 5. Verificar que el puerto esté escuchando
echo "5️⃣  Verificando puerto en el host:"
ss -tuln | grep 3001
echo ""

# 6. Probar conexión
echo "6️⃣  Probando conexión:"
timeout 5 curl -s --max-time 3 http://localhost:3001/api/health && echo "   ✅ Servidor responde" || echo "   ❌ Servidor aún no responde"
echo ""

# 7. Si no funciona, probar con modo host
echo "7️⃣  Si aún no funciona, probar con modo host (requiere detener el servicio primero):"
echo "   docker service update --publish-rm published=3001,target=3001,protocol=tcp checkin24hs_whatsapp"
echo "   docker service update --publish-add published=3001,target=3001,protocol=tcp,mode=host checkin24hs_whatsapp"
echo ""

echo "=============================================================="
echo "✅ PROCESO COMPLETADO"
echo "=============================================================="
echo ""
