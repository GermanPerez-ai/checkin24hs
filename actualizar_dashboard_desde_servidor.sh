#!/bin/bash

# Script para actualizar dashboard.html directamente desde el servidor
# Este script descarga el código actualizado de GitHub y lo copia al contenedor

echo "🔄 Actualizando dashboard desde GitHub..."

# Obtener IP del contenedor del dashboard
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    exit 1
fi

echo "📦 Contenedor encontrado: $DASHBOARD_CONTAINER"

# Crear directorio temporal
TEMP_DIR="/tmp/dashboard_update_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "📥 Descargando código desde GitHub..."
# Clonar o actualizar el repositorio
if [ -d "Checkin24hs" ]; then
    cd Checkin24hs
    git pull origin main
else
    git clone https://github.com/GermanPerez-ai/checkin24hs.git Checkin24hs
    cd Checkin24hs
fi

echo "✅ Código descargado"

# Buscar el archivo dashboard.html en el contenedor
CONTAINER_DASHBOARD_PATH=$(docker exec "$DASHBOARD_CONTAINER" find / -name "dashboard.html" -type f 2>/dev/null | head -1)

if [ -z "$CONTAINER_DASHBOARD_PATH" ]; then
    echo "⚠️ No se encontró dashboard.html en el contenedor, intentando rutas comunes..."
    # Intentar rutas comunes
    for path in "/app/dashboard.html" "/usr/share/nginx/html/dashboard.html" "/var/www/html/dashboard.html" "/app/deploy/dashboard.html"; do
        if docker exec "$DASHBOARD_CONTAINER" test -f "$path" 2>/dev/null; then
            CONTAINER_DASHBOARD_PATH="$path"
            echo "✅ Encontrado en: $path"
            break
        fi
    done
fi

if [ -z "$CONTAINER_DASHBOARD_PATH" ]; then
    echo "❌ No se pudo encontrar dashboard.html en el contenedor"
    echo "📋 Listando archivos en /app:"
    docker exec "$DASHBOARD_CONTAINER" ls -la /app 2>/dev/null || echo "No se puede acceder a /app"
    exit 1
fi

echo "📁 Ruta del archivo en contenedor: $CONTAINER_DASHBOARD_PATH"

# Copiar el archivo actualizado al contenedor
echo "📤 Copiando dashboard.html actualizado al contenedor..."
docker cp "deploy/dashboard.html" "$DASHBOARD_CONTAINER:$CONTAINER_DASHBOARD_PATH"

if [ $? -eq 0 ]; then
    echo "✅ dashboard.html actualizado correctamente"
    
    # Verificar que el archivo se copió correctamente
    echo "🔍 Verificando que el archivo contiene el código actualizado..."
    docker exec "$DASHBOARD_CONTAINER" grep -q "checkWhatsAppConnection BLOQUEADO" "$CONTAINER_DASHBOARD_PATH" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Verificación exitosa: El código actualizado está en el contenedor"
    else
        echo "⚠️ Advertencia: No se pudo verificar el contenido del archivo"
    fi
    
    # Reiniciar el servicio si es necesario (opcional)
    echo ""
    echo "🔄 ¿Deseas reiniciar el contenedor para aplicar los cambios? (s/n)"
    read -r response
    if [[ "$response" =~ ^[Ss]$ ]]; then
        echo "🔄 Reiniciando contenedor..."
        docker restart "$DASHBOARD_CONTAINER"
        echo "✅ Contenedor reiniciado"
    else
        echo "ℹ️ No se reinició el contenedor. Los cambios pueden requerir un reinicio manual."
    fi
    
else
    echo "❌ Error al copiar el archivo"
    exit 1
fi

# Limpiar
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Proceso completado"
echo "🌐 Verifica el dashboard en: https://dashboard.checkin24hs.com"
echo ""
echo "💡 Para verificar que el código está actualizado, abre la consola del navegador (F12) y ejecuta:"
echo "   window.checkWhatsAppConnection.toString()"
echo "   Debería contener 'BLOQUEADO' y NO debería contener 'fetch'"

