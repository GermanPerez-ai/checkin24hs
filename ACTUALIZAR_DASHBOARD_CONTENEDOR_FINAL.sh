#!/bin/bash

echo "=========================================="
echo "🔄 ACTUALIZAR DASHBOARD EN CONTENEDOR"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar archivo local
echo "=== 1. VERIFICAR ARCHIVO LOCAL ==="
if [ ! -f "dashboard.html" ]; then
    echo "❌ Error: No se encuentra dashboard.html en /root/checkin24hs"
    echo "   Por favor, sube el archivo primero desde tu computadora"
    exit 1
fi

echo "✅ Archivo local encontrado: dashboard.html"
echo ""

# Verificar que tiene los cambios correctos
echo "🔍 Verificando contenido local..."
if grep -q "header-left" dashboard.html; then
    echo "   ✅ Tiene 'header-left' (estructura correcta)"
else
    echo "   ❌ NO tiene 'header-left'"
    echo "   ⚠️  El archivo local también necesita actualizarse"
    exit 1
fi

if grep -q "??" dashboard.html; then
    echo "   ⚠️  AÚN tiene '??' (problema)"
    echo "   El archivo local también tiene problemas"
else
    echo "   ✅ No tiene '??' (correcto)"
fi
echo ""

# 2. Encontrar contenedor
echo "=== 2. ENCONTRAR CONTENEDOR ==="
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi
echo "✅ Contenedor: $CONTAINER"
echo ""

# 3. Buscar dashboard.html en el contenedor
echo "=== 3. BUSCAR ARCHIVO EN CONTENEDOR ==="
DASHBOARD_PATH=$(docker exec "$CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
if [ -z "$DASHBOARD_PATH" ]; then
    echo "❌ No se encontró dashboard.html en el contenedor"
    echo "   Buscando en rutas comunes..."
    for path in "/app/dashboard.html" "/usr/src/app/dashboard.html" "/root/checkin24hs/dashboard.html" "/dashboard.html"; do
        if docker exec "$CONTAINER" test -f "$path" 2>/dev/null; then
            DASHBOARD_PATH="$path"
            break
        fi
    done
fi

if [ -z "$DASHBOARD_PATH" ]; then
    echo "❌ No se pudo encontrar dashboard.html en el contenedor"
    exit 1
fi
echo "✅ Archivo encontrado: $DASHBOARD_PATH"
echo ""

# 4. Hacer backup
echo "=== 4. HACER BACKUP ==="
BACKUP_PATH="${DASHBOARD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER" cp "$DASHBOARD_PATH" "$BACKUP_PATH" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Backup creado: $BACKUP_PATH"
else
    echo "⚠️  No se pudo crear backup (continuando de todas formas)"
fi
echo ""

# 5. Copiar archivo
echo "=== 5. COPIAR ARCHIVO ==="
echo "Copiando dashboard.html al contenedor..."
docker cp dashboard.html "${CONTAINER}:${DASHBOARD_PATH}"
if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado exitosamente"
else
    echo "❌ Error al copiar archivo"
    exit 1
fi
echo ""

# 6. Verificar copia
echo "=== 6. VERIFICAR COPIA ==="
if docker exec "$CONTAINER" grep -q "header-left" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "✅ Verificación exitosa: El archivo tiene 'header-left'"
else
    echo "❌ ERROR: El archivo NO tiene 'header-left' después de copiar"
    echo "   Algo salió mal en la copia"
    exit 1
fi

if docker exec "$CONTAINER" grep -q "??" "$DASHBOARD_PATH" 2>/dev/null; then
    echo "⚠️  AÚN tiene '??' (puede ser normal si son caracteres válidos)"
else
    echo "✅ No tiene '??' problemáticos"
fi
echo ""

# 7. Reiniciar contenedor (si es necesario)
echo "=== 7. REINICIAR SERVICIO ==="
echo "⚠️  Para aplicar los cambios, es necesario reiniciar el contenedor"
echo "   ¿Deseas reiniciarlo ahora? (esto causará un breve downtime)"
echo ""
read -p "   Reiniciar contenedor? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo "🔄 Reiniciando contenedor..."
    docker restart "$CONTAINER"
    echo "✅ Contenedor reiniciado"
    echo ""
    echo "⏳ Esperando 10 segundos para que el servicio se levante..."
    sleep 10
    echo "✅ Servicio debería estar funcionando"
else
    echo "⏭️  Reinicio omitido"
    echo "   ⚠️  Recuerda reiniciar el contenedor manualmente:"
    echo "   docker restart $CONTAINER"
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Abre https://dashboard.checkin24hs.com"
echo "2. Presiona Ctrl+F5 (forzar recarga sin caché)"
echo "3. Verifica que el header está horizontal"
echo "4. Verifica que no hay '??' en los textos"
echo ""
