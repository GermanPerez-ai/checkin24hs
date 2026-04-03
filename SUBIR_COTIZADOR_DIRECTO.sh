#!/bin/bash
# Script para subir archivos del cotizador directamente al contenedor Docker
# Ejecutar EN EL SERVIDOR después de copiar los archivos

echo "=========================================="
echo "📤 Subiendo archivos del cotizador al contenedor"
echo "=========================================="
echo ""

# Buscar contenedor del cotizador
echo "🔍 Buscando contenedor del cotizador..."
CONTAINER_ID=$(docker ps --filter "name=cotizador" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor 'cotizador'"
    echo ""
    echo "Contenedores disponibles:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
    echo ""
    read -p "Ingresa el ID o nombre del contenedor: " CONTAINER_ID
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se especificó contenedor"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar que los archivos existan en el directorio actual
ARCHIVOS=("cotizador-cliente.html" "supabase-config.js" "supabase-client.js")

echo "🔍 Verificando archivos locales..."
for archivo in "${ARCHIVOS[@]}"; do
    if [ ! -f "$archivo" ]; then
        echo "⚠️ No se encuentra: $archivo"
        echo "   Asegúrate de estar en el directorio correcto o copia los archivos aquí primero"
    else
        echo "✅ Encontrado: $archivo"
    fi
done

echo ""
echo "📋 Rutas comunes donde pueden estar los archivos en el contenedor:"
echo "   1. /usr/share/nginx/html/"
echo "   2. /app/"
echo "   3. /var/www/html/"
echo "   4. /html/"
echo ""
read -p "Ingresa la ruta en el contenedor (o presiona Enter para /usr/share/nginx/html/): " CONTAINER_PATH

if [ -z "$CONTAINER_PATH" ]; then
    CONTAINER_PATH="/usr/share/nginx/html/"
fi

# Asegurar que termine con /
if [[ ! "$CONTAINER_PATH" == */ ]]; then
    CONTAINER_PATH="$CONTAINER_PATH/"
fi

echo ""
echo "📤 Copiando archivos a $CONTAINER_PATH en el contenedor $CONTAINER_ID..."
echo ""

for archivo in "${ARCHIVOS[@]}"; do
    if [ -f "$archivo" ]; then
        echo "   Copiando $archivo..."
        docker cp "$archivo" "$CONTAINER_ID:$CONTAINER_PATH$archivo"
        
        if [ $? -eq 0 ]; then
            echo "   ✅ $archivo copiado correctamente"
        else
            echo "   ❌ Error al copiar $archivo"
            echo "   Intentando verificar si el archivo existe en el contenedor..."
            docker exec "$CONTAINER_ID" ls -la "$CONTAINER_PATH" | head -10
        fi
    else
        echo "   ⚠️ Saltando $archivo (no encontrado localmente)"
    fi
done

echo ""
echo "✅ Proceso completado"
echo ""
echo "🔄 Si los cambios no se reflejan, puede ser necesario:"
echo "   1. Reiniciar el contenedor: docker restart $CONTAINER_ID"
echo "   2. O limpiar la caché del navegador (Ctrl+Shift+R)"
echo ""
echo "🌐 Prueba acceder a: https://cotizar.checkin24hs.com/"
