#!/bin/bash

echo "=========================================="
echo "FORZAR ACTUALIZACION DASHBOARD - FINAL"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar archivo local
echo "=== 1. Verificar archivo local ==="
if [ ! -f "dashboard.html" ]; then
    echo "❌ Error: dashboard.html no existe"
    exit 1
fi

FILE_SIZE=$(stat -c%s dashboard.html 2>/dev/null || stat -f%z dashboard.html 2>/dev/null)
echo "✅ Archivo encontrado: $(echo "scale=2; $FILE_SIZE/1024" | bc) KB"
echo ""

# Verificar que NO tiene emojis
EMOJIS_LOCAL=$(grep -c "🎫 Módulo Programa Flexi\|🤖 Módulo Flor IA\|✅ Conexión con Supabase\|💾 Los datos se guardarán" dashboard.html 2>&1 || echo "0")
if [ "$EMOJIS_LOCAL" -gt 0 ]; then
    echo "❌ El archivo local TODAVÍA tiene emojis"
    echo "Necesitas subir el archivo corregido primero"
    exit 1
fi

# Verificar que tiene showSection
SHOW_SECTION_LOCAL=$(grep -c "window.showSection = function" dashboard.html)
if [ "$SHOW_SECTION_LOCAL" -eq 0 ]; then
    echo "❌ El archivo local NO tiene showSection definida"
    exit 1
fi

echo "✅ Archivo local está correcto (sin emojis, con showSection)"
echo ""

# 2. Obtener contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor corriendo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 3. Verificar archivo actual en contenedor
echo "=== 2. Verificar archivo actual en contenedor ==="
CONTAINER_SIZE=$(docker exec $CONTAINER_ID stat -c%s /app/dashboard.html 2>/dev/null || docker exec $CONTAINER_ID stat -f%z /app/dashboard.html 2>/dev/null)
echo "Tamaño actual en contenedor: $(echo "scale=2; $CONTAINER_SIZE/1024" | bc) KB"
echo ""

EMOJIS_CONTAINER=$(docker exec $CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0")
echo "Emojis en contenedor: $EMOJIS_CONTAINER"
echo ""

# 4. Copiar archivo
echo "=== 3. Copiar archivo actualizado ==="
docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar"
    exit 1
fi

echo "✅ Archivo copiado"
echo ""

# 5. Verificar que se copió correctamente
echo "=== 4. Verificar archivo copiado ==="
NEW_SIZE=$(docker exec $CONTAINER_ID stat -c%s /app/dashboard.html 2>/dev/null || docker exec $CONTAINER_ID stat -f%z /app/dashboard.html 2>/dev/null)
echo "Nuevo tamaño: $(echo "scale=2; $NEW_SIZE/1024" | bc) KB"
echo ""

NEW_EMOJIS=$(docker exec $CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0")
echo "Emojis después de copiar: $NEW_EMOJIS"
if [ "$NEW_EMOJIS" -eq "0" ]; then
    echo "✅ Sin emojis"
else
    echo "⚠️  Todavía hay emojis"
fi
echo ""

SHOW_SECTION_CONTAINER=$(docker exec $CONTAINER_ID grep -c "window.showSection = function" /app/dashboard.html)
echo "showSection en contenedor: $SHOW_SECTION_CONTAINER veces"
if [ "$SHOW_SECTION_CONTAINER" -gt 0 ]; then
    echo "✅ showSection encontrada"
    docker exec $CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
else
    echo "❌ showSection NO encontrada"
fi
echo ""

# 6. Verificar línea 5150
echo "=== 5. Verificar línea 5150 ==="
docker exec $CONTAINER_ID sed -n '5150p' /app/dashboard.html
echo ""

# 7. Reiniciar servicio para limpiar caché
echo "=== 6. Reiniciar servicio (para limpiar caché) ==="
docker service update --force checkin24hs_dashboard
echo "✅ Servicio reiniciado"
echo ""

echo "Esperando 30 segundos..."
sleep 30

# 8. Copiar al nuevo contenedor
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ] && [ "$NEW_CONTAINER_ID" != "$CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    echo "Copiando archivo al nuevo contenedor..."
    docker cp dashboard.html $NEW_CONTAINER_ID:/app/dashboard.html
    echo "✅ Archivo copiado al nuevo contenedor"
    echo ""
    
    # Verificar
    docker exec $NEW_CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0 emojis ✅"
    docker exec $NEW_CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "IMPORTANTE:"
echo "1. Recarga la pagina con Ctrl+Shift+R (recarga forzada sin caché)"
echo "2. O abre en modo incógnito: Ctrl+Shift+N"
echo "3. Abre DevTools (F12) → Console"
echo "4. Verifica que NO aparezcan emojis"
echo "5. Verifica que NO aparezca 'window.showSection is not a function'"
echo ""




