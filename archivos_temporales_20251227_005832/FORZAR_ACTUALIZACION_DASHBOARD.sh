#!/bin/bash

echo "=========================================="
echo "FORZAR ACTUALIZACION DE DASHBOARD.HTML"
echo "=========================================="
echo ""

cd /root/checkin24hs

# Verificar archivo local
if [ ! -f "dashboard.html" ]; then
    echo "❌ Error: dashboard.html no existe en /root/checkin24hs"
    exit 1
fi

echo "✅ Archivo encontrado"
echo ""

# Verificar que el archivo tiene los cambios correctos
echo "=== Verificando cambios en archivo local ==="
HAS_SHOW_SECTION=$(grep -c "window.showSection = function" dashboard.html)
HAS_EMOJIS=$(grep -c "🎫 Módulo Programa Flexi\|🤖 Módulo Flor IA\|✅ Conexión con Supabase\|💾 Los datos se guardarán" dashboard.html || echo "0")

echo "showSection definida: $HAS_SHOW_SECTION veces"
echo "Emojis encontrados: $HAS_EMOJIS"

if [ "$HAS_EMOJIS" -gt 0 ]; then
    echo "⚠️  El archivo local TODAVÍA tiene emojis. Necesitas subir el archivo corregido primero."
    exit 1
fi

if [ "$HAS_SHOW_SECTION" -eq 0 ]; then
    echo "⚠️  El archivo local NO tiene showSection definida. Necesitas subir el archivo corregido primero."
    exit 1
fi

echo "✅ Archivo local tiene los cambios correctos"
echo ""

# Buscar TODOS los contenedores del servicio
echo "=== Buscando contenedores ==="
CONTAINERS=$(docker ps -a | grep checkin24hs_dashboard | awk '{print $1}')
if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores"
    exit 1
fi

echo "Contenedores encontrados:"
echo "$CONTAINERS"
echo ""

# Copiar archivo a TODOS los contenedores
echo "=== Copiando archivo a todos los contenedores ==="
for CONTAINER_ID in $CONTAINERS; do
    echo "Copiando a contenedor: $CONTAINER_ID"
    docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Copiado exitosamente"
        
        # Verificar que se copió
        echo "Verificando archivo en contenedor:"
        docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>&1 | head -1
        
        # Verificar que no tiene emojis
        echo "Verificando emojis:"
        docker exec $CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0 emojis encontrados ✅"
        
        # Verificar showSection
        echo "Verificando showSection:"
        docker exec $CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
    else
        echo "⚠️  Error al copiar (el contenedor puede estar detenido)"
    fi
    echo ""
done

# Reiniciar servicio para forzar recreación
echo "=== Reiniciando servicio ==="
docker service update --force checkin24hs_dashboard
echo "✅ Servicio reiniciado"
echo ""

# Esperar a que se cree el nuevo contenedor
echo "Esperando 30 segundos para que se cree el nuevo contenedor..."
sleep 30

# Copiar al nuevo contenedor
echo ""
echo "=== Copiando al nuevo contenedor ==="
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    docker cp dashboard.html $NEW_CONTAINER_ID:/app/dashboard.html
    echo "✅ Archivo copiado al nuevo contenedor"
    
    # Verificar
    echo ""
    echo "Verificando archivo en nuevo contenedor:"
    docker exec $NEW_CONTAINER_ID ls -lh /app/dashboard.html
    echo ""
    echo "Verificando que NO tiene emojis:"
    docker exec $NEW_CONTAINER_ID grep -c "🎫\|🤖\|✅\|💾" /app/dashboard.html 2>&1 || echo "0 emojis ✅"
    echo ""
    echo "Verificando showSection:"
    docker exec $NEW_CONTAINER_ID grep -n "window.showSection = function" /app/dashboard.html | head -3
else
    echo "⚠️  No se encontró nuevo contenedor"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "IMPORTANTE:"
echo "1. Recarga la pagina con Ctrl+F5 (recarga forzada)"
echo "2. Abre DevTools (F12) → Console"
echo "3. Verifica que NO aparezcan emojis en los console.log"
echo "4. Verifica que NO aparezca 'window.showSection is not a function'"
echo ""




