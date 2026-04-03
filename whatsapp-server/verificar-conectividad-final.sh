#!/bin/bash
# ✅ Verificación final de conectividad

echo "=============================================================="
echo "✅ VERIFICACIÓN FINAL DE CONECTIVIDAD"
echo "=============================================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

# 1. Intentar conexión a cada IP del contenedor
echo "1️⃣  Intentando conexión a las IPs del contenedor:"
CONTAINER_IPS=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{println}}{{end}}' 2>/dev/null)
for IP in $CONTAINER_IPS; do
    if [ -n "$IP" ] && [ "$IP" != "10.0.0.10" ]; then
        echo "   Probando IP: $IP"
        timeout 3 curl -s --max-time 2 http://$IP:3001/api/health && echo "   ✅ Responde en $IP" || echo "   ❌ No responde en $IP"
    fi
done
echo ""

# 2. Verificar mapeo de puertos del servicio
echo "2️⃣  Mapeo de puertos del servicio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool
echo ""

# 3. Verificar puerto desde el host
echo "3️⃣  Puerto escuchando en el host:"
ss -tuln | grep 3001
echo ""

# 4. Intentar conexión desde localhost
echo "4️⃣  Intentando conexión desde localhost:"
timeout 5 curl -v --max-time 3 http://localhost:3001/api/health 2>&1 | head -20
echo ""

# 5. Verificar red Docker Swarm
echo "5️⃣  Redes del contenedor:"
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{$value.IPAddress}}{{println}}{{end}}'
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
