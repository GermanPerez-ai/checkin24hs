#!/bin/bash
# 🔍 Diagnosticar problema con routing mesh de Docker Swarm

echo "=============================================================="
echo "🔍 DIAGNÓSTICO: ROUTING MESH DOCKER SWARM"
echo "=============================================================="
echo ""

# 1. Verificar puerto en el host
echo "1️⃣  Puerto escuchando en el host:"
ss -tuln | grep 3001
echo ""

# 2. Verificar si hay algún proceso escuchando en el puerto
echo "2️⃣  Procesos escuchando en puerto 3001:"
lsof -i :3001 2>/dev/null || fuser 3001/tcp 2>/dev/null || echo "No se puede verificar procesos"
echo ""

# 3. Verificar red de Docker Swarm
echo "3️⃣  Redes de Docker Swarm:"
docker network ls | grep swarm
echo ""

# 4. Verificar configuración del servicio
echo "4️⃣  Configuración completa del servicio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}' | python3 -m json.tool
echo ""

# 5. Probar conexión usando diferentes métodos
echo "5️⃣  Probando diferentes métodos de conexión:"
echo "   a) localhost:3001"
timeout 3 curl -s --max-time 2 http://localhost:3001/api/health 2>&1 | head -1 || echo "   ❌ No responde"
echo "   b) 127.0.0.1:3001"
timeout 3 curl -s --max-time 2 http://127.0.0.1:3001/api/health 2>&1 | head -1 || echo "   ❌ No responde"
echo "   c) IP del host"
HOST_IP=$(hostname -I | awk '{print $1}')
echo "   Probando $HOST_IP:3001"
timeout 3 curl -s --max-time 2 http://$HOST_IP:3001/api/health 2>&1 | head -1 || echo "   ❌ No responde"
echo ""

# 6. Verificar iptables
echo "6️⃣  Reglas de iptables relacionadas con Docker:"
iptables -t nat -L -n 2>/dev/null | grep -E "3001|DOCKER" | head -5 || echo "No se pueden ver reglas de iptables"
echo ""

# 7. Verificar logs del servicio para ver si hay errores de red
echo "7️⃣  Últimos logs del servicio:"
docker service logs checkin24hs_whatsapp --tail 5 2>&1 | tail -3
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
