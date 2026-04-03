#!/bin/bash
# Verificar qué archivo está sirviendo el contenedor del cotizador

echo "🔍 VERIFICAR ARCHIVO EN CONTENEDOR COTIZADOR"
echo "=============================================="
echo ""

# Buscar contenedor del cotizador
CONTAINER_ID=$(docker ps --format "{{.ID}}" --filter "name=checkin24hs_cotizador" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del cotizador"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar qué archivo está en index.html
echo "1️⃣ Verificando contenido de index.html..."
echo ""
INDEX_CONTENT=$(docker exec $CONTAINER_ID cat /usr/share/nginx/html/index.html 2>/dev/null | head -50)

if echo "$INDEX_CONTENT" | grep -q "TUS RESERVAS TIENEN BENEFICIOS"; then
    echo "❌ PROBLEMA: El contenedor está sirviendo index.html obsoleto"
    echo "   El archivo contiene 'TUS RESERVAS TIENEN BENEFICIOS'"
    echo ""
    echo "   Primeras líneas del archivo:"
    echo "$INDEX_CONTENT" | head -20
elif echo "$INDEX_CONTENT" | grep -q "Solicitar Cotización"; then
    echo "✅ El contenedor tiene el archivo correcto (cotizador-cliente.html)"
    echo ""
    echo "   Primeras líneas del archivo:"
    echo "$INDEX_CONTENT" | head -20
else
    echo "⚠️  No se pudo determinar el contenido"
    echo ""
    echo "   Primeras líneas del archivo:"
    echo "$INDEX_CONTENT" | head -20
fi

echo ""
echo "2️⃣ Verificando archivos en el contenedor..."
echo ""
docker exec $CONTAINER_ID ls -la /usr/share/nginx/html/ | head -20

echo ""
echo "3️⃣ Verificando si existe cotizador-cliente.html..."
if docker exec $CONTAINER_ID test -f /usr/share/nginx/html/cotizador-cliente.html 2>/dev/null; then
    echo "✅ cotizador-cliente.html existe en el contenedor"
else
    echo "❌ cotizador-cliente.html NO existe en el contenedor"
fi

echo ""
echo "=============================================="
echo "📋 CONCLUSIÓN"
echo "=============================================="
echo ""
echo "Si el contenedor está sirviendo index.html obsoleto, necesitas:"
echo "1. Reconstruir el servicio en EasyPanel"
echo "2. O verificar que el Dockerfile.cotizador esté copiando el archivo correcto"
echo ""
