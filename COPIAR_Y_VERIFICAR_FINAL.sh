#!/bin/bash

echo "=========================================="
echo "🔄 COPIAR Y VERIFICAR ARCHIVO"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

echo "📦 Contenedor: $CONTAINER"
echo ""

# 1. Verificar archivo local tiene header-left
echo "=== 1. VERIFICAR ARCHIVO LOCAL ==="
if grep -q "header-left" dashboard.html; then
    echo "✅ Archivo local tiene 'header-left'"
else
    echo "❌ Archivo local NO tiene 'header-left'"
    exit 1
fi
echo ""

# 2. Hacer backup del archivo en el contenedor
echo "=== 2. HACER BACKUP ==="
docker exec "$CONTAINER" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup creado"
echo ""

# 3. Copiar archivo
echo "=== 3. COPIAR ARCHIVO ==="
docker cp dashboard.html "${CONTAINER}:/app/dashboard.html"
if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado exitosamente"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi
echo ""

# 4. Verificar INMEDIATAMENTE después de copiar
echo "=== 4. VERIFICAR DESPUÉS DE COPIAR ==="
docker exec "$CONTAINER" grep -A 12 'class="header"' /app/dashboard.html 2>/dev/null | head -13
echo ""

# 5. Verificar que tiene header-left
if docker exec "$CONTAINER" grep -q 'class="header-left"' /app/dashboard.html 2>/dev/null; then
    echo "✅ El archivo en el contenedor TIENE 'header-left'"
else
    echo "❌ El archivo en el contenedor NO tiene 'header-left'"
    echo "⚠️  Algo está sobrescribiendo el archivo"
    exit 1
fi
echo ""

# 6. Reiniciar contenedor
echo "=== 5. REINICIAR CONTENEDOR ==="
docker restart "$CONTAINER"
echo "✅ Contenedor reiniciado"
echo "⏳ Esperando 10 segundos..."
sleep 10
echo ""

# 7. Verificar DESPUÉS del reinicio
echo "=== 6. VERIFICAR DESPUÉS DEL REINICIO ==="
docker exec "$CONTAINER" grep -A 12 'class="header"' /app/dashboard.html 2>/dev/null | head -13
echo ""

if docker exec "$CONTAINER" grep -q 'class="header-left"' /app/dashboard.html 2>/dev/null; then
    echo "✅ El archivo DESPUÉS del reinicio TIENE 'header-left'"
else
    echo "❌ El archivo DESPUÉS del reinicio NO tiene 'header-left'"
    echo "⚠️  El contenedor está restaurando el archivo desde algún lugar"
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
