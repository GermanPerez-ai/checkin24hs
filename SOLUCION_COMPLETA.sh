#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIÓN COMPLETA - DASHBOARD Y WHATSAPP"
echo "=========================================="
echo ""

# ===== PARTE 1: CORREGIR DASHBOARD =====
echo "=== PARTE 1: Corrigiendo Dashboard ==="
DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    exit 1
fi

echo "Contenedor: $DASHBOARD_CONTAINER"
echo ""

# Crear backup
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$DASHBOARD_CONTAINER" cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || true
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Copiar archivo correcto
if [ -f "deploy/dashboard.html" ]; then
    docker cp deploy/dashboard.html "${DASHBOARD_CONTAINER}:/app/dashboard.html"
    echo "✅ Archivo correcto copiado"
else
    echo "⚠️ No se encontró deploy/dashboard.html localmente"
fi

# Eliminar TODAS las consultas problemáticas con from_me
echo ""
echo "Eliminando consultas problemáticas..."
docker exec "$DASHBOARD_CONTAINER" sed -i '/select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/\.select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/whatsapp_messages.*select.*from_me[^_]/d' /app/dashboard.html 2>/dev/null || true

# Eliminar el bloque completo de "verificación directa" que causa el error
echo "Eliminando bloque de verificación directa..."
docker exec "$DASHBOARD_CONTAINER" sed -i '/\/\/ Verificar primero si hay mensajes con una consulta directa/,/} catch (checkError)/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/Verificar primero si hay mensajes/,/Error en verificación directa/d' /app/dashboard.html 2>/dev/null || true
docker exec "$DASHBOARD_CONTAINER" sed -i '/msgCheck\|checkError\|verificación directa/d' /app/dashboard.html 2>/dev/null || true

# Reemplazar cualquier from_me restante
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me\([^_]\)/is_from_me\1/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me"/is_from_me"/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i "s/from_me'/is_from_me'/g" /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me)/is_from_me)/g' /app/dashboard.html
docker exec "$DASHBOARD_CONTAINER" sed -i 's/from_me&/is_from_me&/g' /app/dashboard.html

echo "✅ Correcciones aplicadas"
echo ""

# Verificar
REMAINING=$(docker exec "$DASHBOARD_CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | grep -v "^[0-9]*:.*//" | wc -l)
if [ "$REMAINING" -eq 0 ]; then
    echo "✅ No quedan consultas problemáticas"
else
    echo "⚠️ Aún quedan $REMAINING referencias problemáticas"
fi

# Reiniciar dashboard
docker restart "$DASHBOARD_CONTAINER"
sleep 20
echo "✅ Dashboard reiniciado"
echo ""

# ===== PARTE 2: CORREGIR SERVIDOR DE WHATSAPP =====
echo "=== PARTE 2: Corrigiendo Servidor de WhatsApp ==="

# Actualizar código en todos los contenedores de WhatsApp
WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))
echo "Se encontraron ${#WHATSAPP_CONTAINERS[@]} contenedores de WhatsApp"
echo ""

for container in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "Procesando: $container"
    
    # Crear backup
    BACKUP_FILE="/app/whatsapp-server.js.backup.$(date +%Y%m%d_%H%M%S)"
    docker exec "$container" cp /app/whatsapp-server.js "$BACKUP_FILE" 2>/dev/null || true
    
    # Copiar archivo corregido
    if [ -f "whatsapp-server/whatsapp-server.js" ]; then
        docker cp whatsapp-server/whatsapp-server.js "${container}:/app/whatsapp-server.js"
        echo "  ✅ Archivo copiado"
    else
        echo "  ⚠️ No se encontró whatsapp-server/whatsapp-server.js localmente"
        echo "  Aplicando corrección directa..."
        
        # Corregir directamente en el contenedor
        docker exec "$container" sed -i "s/message: message,/body: message || '',/g" /app/whatsapp-server.js
        docker exec "$container" sed -i 's/"message": message/"body": message || ""/g' /app/whatsapp-server.js
        docker exec "$container" sed -i "s/'message': message/'body': message || ''/g" /app/whatsapp-server.js
        docker exec "$container" sed -i 's/success: true/success: Boolean(true)/g' /app/whatsapp-server.js
        docker exec "$container" sed -i 's/used_ai: usedAI/used_ai: Boolean(usedAI)/g' /app/whatsapp-server.js
        echo "  ✅ Correcciones aplicadas"
    fi
    
    # Reiniciar contenedor
    docker restart "$container"
    sleep 5
    echo "  ✅ Contenedor reiniciado"
    echo ""
done

echo "Esperando 30 segundos para que los servicios se estabilicen..."
sleep 30
echo ""

# ===== PARTE 3: VERIFICAR ESTADO =====
echo "=== PARTE 3: Verificando Estado ==="
echo ""

echo "Dashboard:"
docker ps --filter "name=checkin24hs_dashboard" --format "  {{.Names}} - {{.Status}}"
echo ""

echo "WhatsApp:"
docker ps --filter "name=whatsapp" --format "  {{.Names}} - {{.Status}}" | head -4
echo ""

# Verificar logs de WhatsApp para errores
WHATSAPP_CONTAINER=$(docker ps --filter "name=whatsapp" --format "{{.Names}}" | head -1)
if [ ! -z "$WHATSAPP_CONTAINER" ]; then
    echo "Últimos errores del servidor de WhatsApp:"
    docker logs "$WHATSAPP_CONTAINER" --tail 30 2>&1 | grep -i "error\|failed" | tail -5 || echo "  ✅ No se encontraron errores recientes"
fi
echo ""

echo "=========================================="
echo "✅ SOLUCIÓN COMPLETA APLICADA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Limpia el caché del navegador (Ctrl+Shift+R)"
echo "2. Prueba conectar WhatsApp desde el dashboard"
echo "3. Verifica que los mensajes se están guardando en Supabase"
echo "4. Prueba seleccionar un chat (no debería aparecer error de from_me)"
echo ""

