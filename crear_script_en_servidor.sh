#!/bin/bash
# Script para crear ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh directamente en el servidor

cat > /root/checkin24hs/ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh << 'EOFSCRIPT'
#!/bin/bash
# Script para actualizar checkin24hs-admin desde GitHub directamente en el servidor
# Esto actualiza los archivos del dashboard React sin pasar por EasyPanel

echo "=========================================="
echo "🔄 ACTUALIZANDO DASHBOARD ADMIN DESDE GITHUB"
echo "=========================================="
echo ""

# 1. Buscar servicio del dashboard
echo "1️⃣ Buscando servicio del dashboard..."
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|checkin24hs.*dashboard" | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio del dashboard"
    echo ""
    echo "Servicios disponibles:"
    docker service ls --format "{{.Name}}" | head -10
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Buscar contenedor del servicio
echo "2️⃣ Buscando contenedor del servicio..."
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    # Intentar otra forma de buscar
    CONTAINER_ID=$(docker ps --format "{{.ID}}\t{{.Names}}" | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    exit 1
fi

CONTAINER_NAME=$(docker ps --format "{{.Names}}" --filter "id=$CONTAINER_ID")
echo "✅ Contenedor encontrado: $CONTAINER_NAME ($CONTAINER_ID)"
echo ""

# 3. Crear directorio temporal y clonar/actualizar desde GitHub
echo "3️⃣ Descargando código desde GitHub..."
TEMP_DIR="/tmp/dashboard_admin_update_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

if [ -d "checkin24hs" ]; then
    cd checkin24hs
    git pull origin main
else
    git clone https://github.com/GermanPerez-ai/checkin24hs.git
    cd checkin24hs
fi

echo "✅ Código descargado"
echo ""

# 4. Buscar archivos a actualizar en el contenedor
echo "4️⃣ Buscando archivos en el contenedor..."
DASHBOARD_DIR=$(docker exec "$CONTAINER_ID" find / -type d -name "checkin24hs-admin" 2>/dev/null | head -1)

if [ -z "$DASHBOARD_DIR" ]; then
    # Intentar rutas comunes
    for path in "/app" "/app/build" "/usr/share/nginx/html"; do
        if docker exec "$CONTAINER_ID" test -d "$path" 2>/dev/null; then
            DASHBOARD_DIR="$path"
            break
        fi
    done
fi

if [ -z "$DASHBOARD_DIR" ]; then
    echo "⚠️  No se encontró directorio del dashboard, usando /app por defecto"
    DASHBOARD_DIR="/app"
else
    echo "✅ Directorio encontrado: $DASHBOARD_DIR"
fi
echo ""

# 5. Copiar server.js actualizado
echo "5️⃣ Copiando server.js actualizado..."
if [ -f "checkin24hs-admin/server.js" ]; then
    docker cp checkin24hs-admin/server.js "$CONTAINER_ID:$DASHBOARD_DIR/server.js"
    if [ $? -eq 0 ]; then
        echo "   ✅ server.js copiado"
    else
        echo "   ⚠️  Error al copiar server.js (puede que no exista en el contenedor)"
    fi
else
    echo "   ⚠️  checkin24hs-admin/server.js no encontrado en el repositorio"
fi
echo ""

# 6. Verificar que server.js tiene la ruta /og-cotizar.jpg
echo "6️⃣ Verificando que server.js tiene la ruta /og-cotizar.jpg..."
if docker exec "$CONTAINER_ID" grep -q "og-cotizar.jpg" "$DASHBOARD_DIR/server.js" 2>/dev/null; then
    echo "   ✅ Ruta /og-cotizar.jpg encontrada en server.js"
else
    echo "   ⚠️  Ruta /og-cotizar.jpg NO encontrada (puede que el archivo no se haya copiado correctamente)"
fi
echo ""

# 7. Reiniciar el servicio (para aplicar cambios)
echo "7️⃣ Reiniciando servicio para aplicar cambios..."
docker service update --force "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "   ✅ Servicio reiniciado"
    echo "   ⏳ Esperando 30 segundos para que el servicio se reinicie..."
    sleep 30
else
    echo "   ⚠️  Error al reiniciar el servicio"
fi
echo ""

# 8. Limpiar directorio temporal
echo "8️⃣ Limpiando archivos temporales..."
cd /
rm -rf "$TEMP_DIR"
echo "   ✅ Archivos temporales eliminados"
echo ""

echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Espera 1-2 minutos adicionales para que el servicio se estabilice"
echo "   2. Prueba acceder a: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo "   3. Debería mostrar una imagen de hotel"
echo ""
echo "📋 Para verificar manualmente:"
echo "   docker service ps $SERVICE_NAME"
echo "   curl -I https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
EOFSCRIPT

chmod +x /root/checkin24hs/ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh
echo "✅ Script creado en /root/checkin24hs/ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh"
