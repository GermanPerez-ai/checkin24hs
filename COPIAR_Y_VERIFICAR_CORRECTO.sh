#!/bin/bash

echo "=========================================="
echo "🔄 COPIAR Y VERIFICAR CORRECTO"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar archivo LOCAL tiene header-left
echo "=== 1. VERIFICAR ARCHIVO LOCAL ==="
if grep -q 'class="header-left"' dashboard.html; then
    echo "✅ Archivo local tiene 'header-left'"
    echo "Estructura del header local:"
    grep -A 8 'class="header"' dashboard.html | head -9
else
    echo "❌ Archivo local NO tiene 'header-left'"
    exit 1
fi
echo ""

# 2. Hacer backup del archivo en el contenedor
echo "=== 2. BACKUP ==="
docker exec "$CONTAINER" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"
echo ""

# 3. Copiar archivo
echo "=== 3. COPIAR ARCHIVO ==="
docker cp dashboard.html "${CONTAINER}:/app/dashboard.html"
if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
else
    echo "❌ Error al copiar"
    exit 1
fi
echo ""

# 4. Verificar INMEDIATAMENTE después de copiar
echo "=== 4. VERIFICAR DESPUÉS DE COPIAR ==="
echo "Estructura del header en el contenedor:"
docker exec "$CONTAINER" grep -A 8 'class="header"' /app/dashboard.html 2>/dev/null | head -9
echo ""

if docker exec "$CONTAINER" grep -q 'class="header-left"' /app/dashboard.html 2>/dev/null; then
    echo "✅ El archivo TIENE 'header-left'"
else
    echo "❌ El archivo NO tiene 'header-left'"
    echo "⚠️  El archivo no se copió correctamente"
    exit 1
fi
echo ""

# 5. Verificar tamaño de archivos
echo "=== 5. VERIFICAR TAMAÑOS ==="
LOCAL_SIZE=$(wc -c < dashboard.html)
CONTAINER_SIZE=$(docker exec "$CONTAINER" wc -c < /app/dashboard.html 2>/dev/null)
echo "Archivo local: $LOCAL_SIZE bytes"
echo "Archivo contenedor: $CONTAINER_SIZE bytes"
if [ "$LOCAL_SIZE" = "$CONTAINER_SIZE" ]; then
    echo "✅ Los archivos tienen el mismo tamaño"
else
    echo "⚠️  Los archivos tienen tamaños diferentes"
fi
echo ""

# 6. Reiniciar contenedor
echo "=== 6. REINICIAR CONTENEDOR ==="
docker restart "$CONTAINER"
echo "✅ Contenedor reiniciado"
echo "⏳ Esperando 10 segundos..."
sleep 10
echo ""

# 7. Verificar DESPUÉS del reinicio
echo "=== 7. VERIFICAR DESPUÉS DEL REINICIO ==="
docker exec "$CONTAINER" grep -A 8 'class="header"' /app/dashboard.html 2>/dev/null | head -9
echo ""

if docker exec "$CONTAINER" grep -q 'class="header-left"' /app/dashboard.html 2>/dev/null; then
    echo "✅ DESPUÉS DEL REINICIO: El archivo TIENE 'header-left'"
else
    echo "❌ DESPUÉS DEL REINICIO: El archivo NO tiene 'header-left'"
    echo "⚠️  El contenedor está restaurando el archivo desde algún lugar"
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
