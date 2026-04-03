#!/bin/bash
# 🔍 Diagnosticar por qué el servidor no responde

echo "=============================================================="
echo "🔍 DIAGNÓSTICO: SERVIDOR NO RESPONDE"
echo "=============================================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Ver logs más recientes
echo "1️⃣  Logs más recientes (últimos 20):"
docker logs $CONTAINER_ID --tail 20 2>&1
echo ""

# 2. Verificar si hay errores
echo "2️⃣  Buscando errores en logs:"
docker logs $CONTAINER_ID 2>&1 | grep -iE "error|exception|failed|Servidor iniciado" | tail -10
echo ""

# 3. Verificar estado del contenedor
echo "3️⃣  Estado del contenedor:"
docker inspect $CONTAINER_ID --format 'Estado: {{.State.Status}} - Desde: {{.State.StartedAt}}' 2>/dev/null
echo ""

# 4. Intentar conexión directa a la IP del contenedor
echo "4️⃣  Intentando conexión a la IP del contenedor:"
CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
if [ -n "$CONTAINER_IP" ]; then
    echo "   IP del contenedor: $CONTAINER_IP"
    timeout 5 curl -s --max-time 3 http://$CONTAINER_IP:3001/api/health && echo "   ✅ Responde desde IP del contenedor" || echo "   ❌ No responde desde IP del contenedor"
else
    echo "   ⚠️  No se pudo obtener IP del contenedor"
fi
echo ""

# 5. Verificar procesos dentro del contenedor
echo "5️⃣  Procesos dentro del contenedor:"
docker top $CONTAINER_ID 2>/dev/null | head -5 || echo "   ⚠️  No se pueden ver procesos"
echo ""

# 6. Verificar si el puerto está realmente escuchando dentro del contenedor
echo "6️⃣  Verificando puerto dentro del contenedor:"
docker exec $CONTAINER_ID sh -c "netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo 'Puerto no encontrado'" 2>/dev/null || echo "   ⚠️  No se puede verificar"
echo ""

# 7. Verificar variables de entorno
echo "7️⃣  Variables de entorno importantes:"
docker exec $CONTAINER_ID sh -c "env | grep -E 'PORT|INSTANCE_NUMBER'" 2>/dev/null || echo "   ⚠️  No se pueden ver variables"
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
