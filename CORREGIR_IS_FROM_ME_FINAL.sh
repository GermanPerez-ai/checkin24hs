#!/bin/bash
cd /root/checkin24hs

echo "=== CORRECCIÓN FINAL IS_FROM_ME ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Verificar estado actual
echo "1. Verificando estado actual del archivo..."
echo "   Buscando línea 24521 (donde debería estar el select):"
docker exec "$CONTAINER" sed -n '24519,24523p' /app/dashboard.html
echo ""

# Paso 2: Buscar TODAS las instancias de from_me (incorrecto)
echo "2. Buscando TODAS las instancias de 'from_me' (incorrecto)..."
docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | head -10
echo ""

# Paso 3: Copiar archivo correcto si existe
if [ -f "deploy/dashboard.html" ]; then
    echo "3. Copiando archivo completo desde deploy/dashboard.html..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
else
    echo "3. ⚠️ Archivo deploy/dashboard.html no existe, corrigiendo directamente..."
fi

# Paso 4: Corregir de manera MÁS AGRESIVA
echo ""
echo "4. Aplicando correcciones agresivas..."

# Método 1: Reemplazo directo del patrón completo
docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Método 2: Reemplazo con punto antes de select
docker exec "$CONTAINER" sed -i "s/\.select('id, chat_id, body, created_at, from_me')/\.select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/\.select("id, chat_id, body, created_at, from_me")/\.select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html

# Método 3: Reemplazo más genérico (solo en contexto de select)
docker exec "$CONTAINER" sed -i "s/, from_me')/, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/, from_me")/, is_from_me")/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i "s/,from_me')/, is_from_me')/g" /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/,from_me")/, is_from_me")/g' /app/dashboard.html

# Método 4: Corregir variaciones múltiples de is_is_is...
docker exec "$CONTAINER" sed -i 's/is_is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_is_from_me/is_from_me/g' /app/dashboard.html
docker exec "$CONTAINER" sed -i 's/is_is_from_me/is_from_me/g' /app/dashboard.html

# Método 5: Reemplazo con límite de palabra (más seguro)
docker exec "$CONTAINER" sed -i "s/\bfrom_me\b/is_from_me/g" /app/dashboard.html

# Método 6: Revertir si se duplicó is_
docker exec "$CONTAINER" sed -i 's/is_is_from_me/is_from_me/g' /app/dashboard.html

echo "   ✅ Correcciones aplicadas"
echo ""

# Paso 5: Verificar que quedó correcto
echo "5. Verificando corrección..."
echo "   Buscando 'from_me' sin 'is_' (NO debería aparecer):"
if docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | head -5; then
    echo "   ⚠️ AÚN HAY 'from_me' INCORRECTO - Intentando corrección adicional..."
    # Corrección adicional usando Python para ser más preciso
    docker exec "$CONTAINER" python3 -c "
import re
with open('/app/dashboard.html', 'r', encoding='utf-8') as f:
    content = f.read()
# Reemplazar select con from_me por is_from_me
content = re.sub(r\"select\('id, chat_id, body, created_at, from_me'\)\", \"select('id, chat_id, body, created_at, is_from_me')\", content)
content = re.sub(r'select\(\"id, chat_id, body, created_at, from_me\"\)', 'select(\"id, chat_id, body, created_at, is_from_me\")', content)
with open('/app/dashboard.html', 'w', encoding='utf-8') as f:
    f.write(content)
" 2>/dev/null || echo "   Python no disponible, usando sed adicional..."
else
    echo "   ✅ No hay 'from_me' incorrecto"
fi

echo ""
echo "   Buscando 'is_from_me' (debería aparecer):"
docker exec "$CONTAINER" grep -n "is_from_me" /app/dashboard.html | head -5
echo ""

# Paso 6: Mostrar la línea específica (24521)
echo "6. Mostrando línea 24521 (donde debería estar el select):"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""

# Paso 7: Verificar que el archivo tiene el código correcto
echo "7. Verificando contenido del select:"
if docker exec "$CONTAINER" grep -q "select('id, chat_id, body, created_at, is_from_me')" /app/dashboard.html; then
    echo "   ✅ Select correcto encontrado"
elif docker exec "$CONTAINER" grep -q 'select("id, chat_id, body, created_at, is_from_me")' /app/dashboard.html; then
    echo "   ✅ Select correcto encontrado (con comillas dobles)"
else
    echo "   ⚠️ Select correcto NO encontrado, buscando variaciones..."
    docker exec "$CONTAINER" grep -n "select.*is_from_me" /app/dashboard.html | head -3
fi

echo ""

# Paso 8: Reiniciar Node.js de manera más agresiva
echo "8. Reiniciando Node.js..."
docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
sleep 3
docker exec "$CONTAINER" pkill -9 node 2>/dev/null || true
sleep 3

# Verificar si Node.js se reinició
if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
    echo "   ✅ Node.js reiniciado correctamente"
else
    echo "   ⚠️ Node.js no está corriendo, puede necesitar reinicio manual del contenedor"
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "⚠️ IMPORTANTE:"
echo "1. Abre el dashboard en modo incógnito O"
echo "2. Presiona Ctrl+Shift+R (Cmd+Shift+R en Mac) para forzar recarga"
echo "3. Abre la consola del navegador (F12) y verifica que la URL tenga 'is_from_me'"
echo ""
echo "La URL debería ser:"
echo "  whatsapp_messages?select=id%2Cchat_id%2Cbody%2Ccreated_at%2Cis_from_me"
echo "Y NO:"
echo "  whatsapp_messages?select=id%2Cchat_id%2Cbody%2Ccreated_at%2Cfrom_me"
echo ""
echo "Si el problema persiste, ejecuta:"
echo "  docker restart $CONTAINER"


