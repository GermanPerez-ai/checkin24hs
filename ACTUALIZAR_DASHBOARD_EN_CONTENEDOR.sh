#!/bin/bash

echo "=========================================="
echo "Actualizar dashboard.html en Contenedor"
echo "=========================================="
echo ""

cd /root/checkin24hs

# Verificar que dashboard.html existe y está actualizado
if [ ! -f "dashboard.html" ]; then
    echo "❌ Error: dashboard.html no existe"
    exit 1
fi

echo "✅ Archivo encontrado:"
ls -lh dashboard.html
echo ""

# Verificar que tiene los cambios correctos
echo "=== Verificar cambios ==="
HAS_SHOW_SECTION=$(grep -c "window.showSection = function" dashboard.html)
HAS_EMOJIS=$(grep -c "🎫 Módulo Programa Flexi\|🤖 Módulo Flor IA\|✅ Conexión con Supabase\|💾 Los datos se guardarán" dashboard.html || echo "0")

echo "showSection definida: $HAS_SHOW_SECTION veces"
echo "Emojis encontrados: $HAS_EMOJIS"
echo ""

if [ "$HAS_EMOJIS" -gt 0 ]; then
    echo "⚠️  El archivo local TODAVÍA tiene emojis"
    echo "Necesitas subir el archivo corregido primero"
    exit 1
fi

# Obtener contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor corriendo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# Hacer backup del archivo actual
echo "=== Hacer backup ==="
docker exec $CONTAINER_ID cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>&1
echo "✅ Backup creado"
echo ""

# Copiar archivo actualizado
echo "=== Copiar dashboard.html actualizado ==="
docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
    echo ""
    
    # Verificar que se copió
    echo "=== Verificar archivo copiado ==="
    docker exec $CONTAINER_ID ls -lh /app/dashboard.html
    echo ""
    
    # Verificar que no tiene emojis
    echo "=== Verificar emojis ==="
    EMOJI_COUNT=$(docker exec $CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0")
    echo "Emojis encontrados: $EMOJI_COUNT"
    if [ "$EMOJI_COUNT" -eq "0" ]; then
        echo "✅ Sin emojis"
    else
        echo "⚠️  Todavía hay emojis"
    fi
    echo ""
    
    # Verificar showSection
    echo "=== Verificar showSection ==="
    docker exec $CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
    echo ""
    
    echo "=========================================="
    echo "✅ Dashboard actualizado"
    echo "=========================================="
    echo ""
    echo "IMPORTANTE:"
    echo "1. Recarga la pagina con Ctrl+F5 (recarga forzada)"
    echo "2. Abre DevTools (F12) → Console"
    echo "3. Verifica que NO aparezcan emojis en los console.log"
    echo "4. Verifica que NO aparezca 'window.showSection is not a function'"
    echo ""
    echo "NOTA: Si el contenedor se recrea, necesitarás copiar el archivo de nuevo"
    echo "Para una solución permanente, haz commit y push a GitHub y reconstruye la imagen"
    echo ""
else
    echo "❌ Error al copiar archivo"
    exit 1
fi




