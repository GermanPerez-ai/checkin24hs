#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR BIND MOUNT DESPUÉS DE DEPLOY"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Esperar un momento para que el servicio se actualice
echo "⏳ Esperando 30 segundos para que el servicio se actualice..."
sleep 30
echo ""

# 2. Verificar servicio
echo "=== 1. VERIFICAR SERVICIO ==="
docker service ps checkin24hs_dashboard --no-trunc | head -5
echo ""

# 3. Obtener contenedor actual
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor corriendo"
    echo "Esperando 30 segundos más..."
    sleep 30
    CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
fi

if [ -z "$CONTAINER" ]; then
    echo "❌ Aún no hay contenedor corriendo"
    exit 1
fi

echo "📦 Contenedor: $CONTAINER"
echo ""

# 4. Verificar mounts del contenedor
echo "=== 2. VERIFICAR MOUNTS DEL CONTENEDOR ==="
MOUNTS=$(docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null)
echo "$MOUNTS"
echo ""

if echo "$MOUNTS" | grep -q "bind.*dashboard.html.*/app/dashboard.html"; then
    echo "✅ Bind mount está configurado correctamente"
else
    echo "⚠️  Bind mount NO aparece en el contenedor"
    echo "Puede que el servicio aún no se haya actualizado completamente"
fi
echo ""

# 5. Verificar mounts en el SERVICIO (más importante)
echo "=== 3. VERIFICAR MOUNTS EN EL SERVICIO ==="
SERVICE_MOUNTS=$(docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null)
echo "$SERVICE_MOUNTS"
echo ""

if echo "$SERVICE_MOUNTS" | grep -q "bind.*dashboard.html.*/app/dashboard.html"; then
    echo "✅ Bind mount está configurado en el SERVICIO"
else
    echo "❌ Bind mount NO está configurado en el servicio"
    echo "EasyPanel puede no haber aplicado el mount correctamente"
fi
echo ""

# 6. Verificar estructura del header en el contenedor
echo "=== 4. VERIFICAR ESTRUCTURA DEL HEADER ==="
docker exec "$CONTAINER" grep -A 8 'class="header"' /app/dashboard.html 2>/dev/null | head -9
echo ""

if docker exec "$CONTAINER" grep -q 'class="header-left"' /app/dashboard.html 2>/dev/null; then
    echo "✅ El archivo en el contenedor tiene 'header-left'"
else
    echo "❌ El archivo en el contenedor NO tiene 'header-left'"
fi
echo ""

# 7. Comparar con archivo local
echo "=== 5. COMPARAR CON ARCHIVO LOCAL ==="
if grep -q 'class="header-left"' dashboard.html; then
    echo "✅ El archivo local tiene 'header-left'"
else
    echo "❌ El archivo local NO tiene 'header-left'"
fi
echo ""

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
