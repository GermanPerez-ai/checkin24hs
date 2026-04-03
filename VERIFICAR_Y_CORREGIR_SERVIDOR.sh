#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICACIÓN Y CORRECCIÓN EN SERVIDOR ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Verificar qué tiene el archivo actualmente
echo "1. Verificando contenido actual del archivo en el servidor..."
echo "   Línea 24521:"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""

# Paso 2: Buscar TODAS las instancias
echo "2. Buscando TODAS las instancias de 'from_me' (sin 'is_'):"
docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | head -10
echo ""

# Paso 3: Copiar archivo correcto
if [ -f "deploy/dashboard.html" ]; then
    echo "3. Copiando archivo completo desde deploy/dashboard.html..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
    
    # Verificar que se copió correctamente
    echo "   Verificando línea 24521 después de copiar:"
    docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
    echo ""
else
    echo "3. ⚠️ Archivo deploy/dashboard.html no existe"
fi

# Paso 4: Aplicar correcciones múltiples
echo "4. Aplicando correcciones múltiples..."

# Corrección 1: Patrón exacto con comillas simples
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html

# Corrección 2: Patrón exacto con comillas dobles
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Corrección 3: Con punto antes de select
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Corrección 4: Reemplazo más genérico
docker exec "$CONTAINER" sed -i "s/, from_me')/, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/, from_me")/, is_from_me")/g' /app/dashboard.html

# Corrección 5: Corregir variaciones múltiples
docker exec "$CONTAINER" sed -i 's/is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_from_me/is_from_me/g' /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 5: Verificar resultado
echo "5. Verificando resultado final..."
echo "   Línea 24521:"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""

echo "   Buscando 'from_me' sin 'is_' (NO debería aparecer):"
if docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | head -5; then
    echo "   ⚠️ AÚN HAY 'from_me' INCORRECTO"
else
    echo "   ✅ No hay 'from_me' incorrecto"
fi

echo ""
echo "   Buscando 'is_from_me' (debería aparecer):"
docker exec "$CONTAINER" grep -n "is_from_me" /app/dashboard.html | head -3
echo ""

# Paso 6: Reiniciar Node.js de manera más agresiva
echo "6. Reiniciando Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 3

# Verificar si se reinició
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ✅ Node.js está corriendo"
else
    echo "   ⚠️ Node.js no está corriendo, puede necesitar reinicio del contenedor"
    echo "   Ejecuta: docker restart $CONTAINER"
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "⚠️ IMPORTANTE:"
echo "1. Abre el dashboard en modo incógnito"
echo "2. Presiona Ctrl+Shift+R para forzar recarga"
echo "3. Verifica en la consola que la URL tenga 'is_from_me'"
echo ""
echo "Si el problema persiste, ejecuta:"
echo "  docker restart $CONTAINER"


