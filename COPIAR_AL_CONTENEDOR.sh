#!/bin/bash

echo "=== COPIANDO ARCHIVO AL CONTENEDOR ==="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor: $CONTAINER"
echo ""

# Verificar que el archivo en el servidor tiene header-left
echo "1. Verificando archivo en el servidor..."
if grep -q "header-left" dashboard.html; then
    echo "   ✅ El archivo en el servidor tiene header-left"
else
    echo "   ❌ El archivo en el servidor NO tiene header-left"
    exit 1
fi
echo ""

# Copiar al contenedor
echo "2. Copiando dashboard.html al contenedor..."
docker cp dashboard.html "$CONTAINER:/app/dashboard.html"
if [ $? -eq 0 ]; then
    echo "   ✅ Archivo copiado exitosamente"
else
    echo "   ❌ Error al copiar el archivo"
    exit 1
fi
echo ""

# Verificar que se copió correctamente
echo "3. Verificando que header-left existe en el contenedor..."
if docker exec "$CONTAINER" grep -q "header-left" /app/dashboard.html 2>/dev/null; then
    echo "   ✅ header-left encontrado en el contenedor"
    docker exec "$CONTAINER" grep -n "header-left" /app/dashboard.html | head -3
else
    echo "   ❌ header-left NO encontrado en el contenedor"
    echo "   Esto significa que el archivo no se copió correctamente"
    exit 1
fi
echo ""

# Copiar serve-dashboard.js también
echo "4. Copiando serve-dashboard.js al contenedor..."
if [ -f "serve-dashboard.js" ]; then
    docker cp serve-dashboard.js "$CONTAINER:/app/serve-dashboard.js"
    echo "   ✅ serve-dashboard.js copiado"
else
    echo "   ⚠️  serve-dashboard.js no existe en el servidor"
fi
echo ""

# Reiniciar contenedor
echo "5. Reiniciando contenedor..."
docker restart "$CONTAINER"
echo "   ✅ Contenedor reiniciado"
echo ""

echo "=== VERIFICACIÓN FINAL ==="
echo "Esperando 3 segundos para que el contenedor inicie..."
sleep 3

echo "Estructura del header en el contenedor:"
docker exec "$CONTAINER" grep -A 5 'class="header"' /app/dashboard.html 2>/dev/null | head -8
echo ""

echo "✅ Proceso completado"
echo ""
echo "Ahora prueba en Chrome con Ctrl+F5 (hard refresh) o en modo incógnito"
