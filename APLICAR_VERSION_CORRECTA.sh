#!/bin/bash
cd /root/checkin24hs

echo "=== APLICANDO VERSIÓN CORRECTA CON FILTRADO DE SPAM ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Verificar que el archivo local tiene el filtrado de spam
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ Archivo deploy/dashboard.html no existe"
    exit 1
fi

echo "1. Verificando archivo local..."
if grep -q "spamPatterns" deploy/dashboard.html; then
    echo "   ✅ Archivo local tiene filtrado de spam"
else
    echo "   ❌ Archivo local NO tiene filtrado de spam"
    exit 1
fi

if grep -q "is_from_me" deploy/dashboard.html; then
    echo "   ✅ Archivo local tiene is_from_me correcto"
else
    echo "   ⚠️ Archivo local NO tiene is_from_me"
fi
echo ""

# Paso 2: Verificar qué tiene el servidor actualmente
echo "2. Verificando versión en el servidor..."
if docker exec "$CONTAINER" grep -q "spamPatterns" /app/dashboard.html 2>/dev/null; then
    echo "   ⚠️ Servidor tiene filtrado de spam (pero puede estar desactualizado)"
else
    echo "   ❌ Servidor NO tiene filtrado de spam"
fi
echo ""

# Paso 3: Hacer backup
echo "3. Haciendo backup del archivo actual..."
docker exec "$CONTAINER" cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
echo "   ✅ Backup creado"
echo ""

# Paso 4: Copiar archivo correcto
echo "4. Copiando versión correcta desde deploy/dashboard.html..."
docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
echo "   ✅ Archivo copiado"
sleep 2

# Verificar que se copió correctamente
echo "   Verificando que se copió correctamente:"
if docker exec "$CONTAINER" grep -q "spamPatterns" /app/dashboard.html; then
    echo "   ✅ Servidor ahora tiene filtrado de spam"
else
    echo "   ❌ Servidor NO tiene filtrado de spam después de copiar"
    exit 1
fi

if docker exec "$CONTAINER" grep -q "is_from_me" /app/dashboard.html; then
    echo "   ✅ Servidor ahora tiene is_from_me correcto"
else
    echo "   ⚠️ Servidor NO tiene is_from_me después de copiar"
fi
echo ""

# Paso 5: Aplicar correcciones adicionales por si acaso
echo "5. Aplicando correcciones adicionales..."
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 6: Verificar resultado final
echo "6. Verificación final..."
echo "   Filtrado de spam:"
docker exec "$CONTAINER" grep -c "spamPatterns" /app/dashboard.html
echo "   is_from_me:"
docker exec "$CONTAINER" grep -c "is_from_me" /app/dashboard.html
echo ""

# Paso 7: Reiniciar contenedor completo
echo "7. Reiniciando contenedor completo..."
docker restart "$CONTAINER"
echo "   ✅ Contenedor reiniciado"
echo "   Esperando 15 segundos para que el contenedor se inicie completamente..."
sleep 15

# Verificar que el contenedor está corriendo
if docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | grep -q "$CONTAINER"; then
    echo "   ✅ Contenedor está corriendo"
    
    # Verificar que Node.js está corriendo
    sleep 5
    if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Node.js está corriendo"
    else
        echo "   ⚠️ Esperando más tiempo para Node.js..."
        sleep 10
        if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
            echo "   ✅ Node.js está corriendo ahora"
        else
            echo "   ❌ Node.js no está corriendo"
        fi
    fi
else
    echo "   ❌ Contenedor no está corriendo"
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "⚠️ IMPORTANTE - SIGUE ESTOS PASOS:"
echo ""
echo "1. Abre el dashboard en modo incógnito (Ctrl+Shift+N)"
echo "2. Presiona Ctrl+Shift+R para forzar recarga completa"
echo "3. Ve a la sección de Chats"
echo "4. Deberías ver:"
echo "   - ✅ Los chats spam están filtrados (no aparecen)"
echo "   - ✅ Los mensajes se cargan correctamente (sin error de from_me)"
echo ""
echo "Si todavía ves spam, verifica en la consola del navegador (F12):"
echo "   - Deberías ver mensajes '🚫 Chat spam excluido'"
echo "   - La URL de las peticiones debería tener 'is_from_me'"


