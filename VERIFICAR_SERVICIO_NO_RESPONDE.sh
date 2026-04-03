#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR POR QUÉ EL SERVICIO NO RESPONDE"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor corriendo"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar proceso en el contenedor
echo "=== 1. PROCESOS EN EL CONTENEDOR ==="
docker exec "$CONTAINER" ps aux 2>/dev/null | head -10
echo ""

# 2. Ver logs del servicio
echo "=== 2. LOGS DEL SERVICIO (últimas 30 líneas) ==="
docker service logs checkin24hs_dashboard --tail 30 --no-trunc 2>&1 | tail -30
echo ""

# 3. Verificar puerto
echo "=== 3. PUERTO DEL CONTENEDOR ==="
docker port "$CONTAINER" 2>/dev/null
echo ""

# 4. Intentar conexión desde dentro del contenedor
echo "=== 4. PRUEBA DESDE DENTRO DEL CONTENEDOR ==="
docker exec "$CONTAINER" curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000" 2>/dev/null || echo "No se pudo conectar"
echo ""

# 5. Verificar red
echo "=== 5. RED DEL CONTENEDOR ==="
docker inspect "$CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}Red: {{$key}}, IP: {{$value.IPAddress}}{"\n"}}{{end}}' 2>/dev/null
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
