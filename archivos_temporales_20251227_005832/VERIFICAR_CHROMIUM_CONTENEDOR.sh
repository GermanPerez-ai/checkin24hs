#!/bin/bash
echo "=== VERIFICACIÓN DE CHROMIUM EN CONTENEDOR ==="
echo ""

CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp1" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor corriendo de whatsapp1"
    echo "Intentando obtener el último contenedor..."
    CONTAINER_ID=$(docker ps -a --filter "name=checkin24hs_whatsapp1" --format "{{.ID}}" | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ No se encontró ningún contenedor de whatsapp1"
        exit 1
    fi
    echo "✅ Usando contenedor: $CONTAINER_ID (detenido)"
else
    echo "✅ Contenedor activo: $CONTAINER_ID"
fi

echo ""
echo "1. Verificando si Chromium está instalado:"
docker exec $CONTAINER_ID which chromium 2>/dev/null || echo "  ❌ 'which chromium' no encontró Chromium"
docker exec $CONTAINER_ID which chromium-browser 2>/dev/null || echo "  ❌ 'which chromium-browser' no encontró Chromium"

echo ""
echo "2. Verificando ubicaciones comunes:"
docker exec $CONTAINER_ID ls -la /usr/bin/chromium 2>/dev/null || echo "  ❌ /usr/bin/chromium no existe"
docker exec $CONTAINER_ID ls -la /usr/bin/chromium-browser 2>/dev/null || echo "  ❌ /usr/bin/chromium-browser no existe"

echo ""
echo "3. Verificando si Chromium está en el PATH:"
docker exec $CONTAINER_ID sh -c "echo \$PATH" 2>/dev/null

echo ""
echo "4. Verificando paquetes instalados:"
docker exec $CONTAINER_ID dpkg -l | grep -i chromium 2>/dev/null || echo "  ❌ No se encontraron paquetes de Chromium instalados"

echo ""
echo "5. Verificando imagen Docker:"
docker inspect $CONTAINER_ID --format '{{.Config.Image}}' 2>/dev/null

echo ""
echo "=== VERIFICACIÓN COMPLETADA ==="

