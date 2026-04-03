#!/bin/bash
# Verificar y comparar dashboard.html en servidor

echo "=== VERIFICACIÓN Y COMPARACIÓN ==="
echo ""

# 1. Verificar archivo local en servidor
if [ -f "deploy/dashboard.html" ]; then
    LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
    LOCAL_DATE=$(stat -c%y deploy/dashboard.html 2>/dev/null || stat -f%Sm deploy/dashboard.html 2>/dev/null)
    echo "📄 Archivo local en servidor:"
    echo "   Tamaño: $LOCAL_SIZE bytes"
    echo "   Fecha: $LOCAL_DATE"
    
    grep -q "whatsapp-config-button-main" deploy/dashboard.html && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
else
    echo "   ❌ No existe deploy/dashboard.html en el servidor"
fi
echo ""

# 2. Verificar archivo en contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    CONTAINER_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null || echo "0")
    CONTAINER_DATE=$(docker exec "$CONTAINER" stat -c%y /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%Sm /app/dashboard.html 2>/dev/null || echo "N/A")
    
    echo "📦 Archivo en contenedor:"
    echo "   Tamaño: $CONTAINER_SIZE bytes"
    echo "   Fecha: $CONTAINER_DATE"
    
    docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
    
    # Comparar tamaños
    if [ "$LOCAL_SIZE" = "$CONTAINER_SIZE" ]; then
        echo "   ✅ Tamaños coinciden"
    else
        echo "   ⚠️  Tamaños NO coinciden (local: $LOCAL_SIZE, contenedor: $CONTAINER_SIZE)"
    fi
fi
echo ""

# 3. Verificar contenido servido
echo "🌍 Contenido servido por HTTPS:"
SERVED_CONTENT=$(curl -s https://dashboard.checkin24hs.com 2>&1)
SERVED_SIZE=$(echo "$SERVED_CONTENT" | wc -c)
echo "   Tamaño servido: $SERVED_SIZE bytes"

echo "$SERVED_CONTENT" | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ Contiene botones" || \
    echo "   ❌ NO contiene botones"

# Comparar con archivo local
if [ "$LOCAL_SIZE" = "$SERVED_SIZE" ]; then
    echo "   ✅ Tamaño servido coincide con local"
else
    echo "   ⚠️  Tamaño servido NO coincide (local: $LOCAL_SIZE, servido: $SERVED_SIZE)"
fi
echo ""

# 4. Verificar hash MD5 para comparación exacta
echo "🔍 Comparando hashes MD5:"
if [ -f "deploy/dashboard.html" ] && [ -n "$CONTAINER" ]; then
    LOCAL_HASH=$(md5sum deploy/dashboard.html 2>/dev/null | cut -d' ' -f1 || md5 deploy/dashboard.html 2>/dev/null | cut -d' ' -f4)
    CONTAINER_HASH=$(docker exec "$CONTAINER" md5sum /app/dashboard.html 2>/dev/null | cut -d' ' -f1 || docker exec "$CONTAINER" md5 /app/dashboard.html 2>/dev/null | cut -d' ' -f4)
    
    echo "   Local: $LOCAL_HASH"
    echo "   Contenedor: $CONTAINER_HASH"
    
    if [ "$LOCAL_HASH" = "$CONTAINER_HASH" ]; then
        echo "   ✅ Hashes coinciden (archivos idénticos)"
    else
        echo "   ❌ Hashes NO coinciden (archivos diferentes)"
    fi
fi
echo ""

echo "=== FIN DE VERIFICACIÓN ==="





