#!/bin/bash
# 🔍 Verificar acceso externo al servidor

echo "=============================================================="
echo "🔍 VERIFICANDO ACCESO EXTERNO"
echo "=============================================================="
echo ""

# 1. Verificar mapeo de puertos del servicio
echo "1️⃣  Verificando mapeo de puertos del servicio Docker Swarm:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool 2>/dev/null || docker service inspect checkin24hs_whatsapp | grep -A 10 "Ports"
echo ""

# 2. Verificar puerto desde el host
echo "2️⃣  Verificando puerto 3001 desde el host:"
netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo "   ⚠️  No se encontró puerto 3001 escuchando"
echo ""

# 3. Verificar contenedor y sus puertos
echo "3️⃣  Verificando contenedor y puertos:"
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
docker port $CONTAINER_ID 2>/dev/null || echo "   ⚠️  No se encontraron puertos mapeados"
echo ""

# 4. Intentar conexión desde el host
echo "4️⃣  Intentando conexión desde el host (localhost:3001):"
timeout 5 curl -s --max-time 3 http://localhost:3001/api/health && echo "   ✅ Servidor responde desde localhost" || echo "   ❌ Servidor NO responde desde localhost"
echo ""

# 5. Intentar conexión desde dentro del contenedor
echo "5️⃣  Intentando conexión desde dentro del contenedor:"
docker exec $CONTAINER_ID sh -c "wget -qO- --timeout=3 http://localhost:3001/api/health 2>/dev/null || echo 'No responde'" && echo "   ✅ Servidor responde desde dentro del contenedor" || echo "   ⚠️  No se pudo verificar"
echo ""

# 6. Verificar IP del contenedor
echo "6️⃣  Verificando IP del contenedor:"
docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null
echo ""

# 7. Verificar firewall/iptables
echo "7️⃣  Verificando reglas de firewall (iptables para puerto 3001):"
iptables -L -n 2>/dev/null | grep 3001 || echo "   ℹ️  No se encontraron reglas específicas para 3001"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
