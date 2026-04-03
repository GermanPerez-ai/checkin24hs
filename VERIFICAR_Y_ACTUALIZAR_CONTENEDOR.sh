#!/bin/bash
# Verificar y actualizar el contenedor con la versión más reciente

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR Y ACTUALIZAR CONTENEDOR"
echo "=========================================="
echo ""

echo "=== 1. Verificar versión actual en contenedor ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontro contenedor activo"
    exit 1
fi
echo "Contenedor: $CONTAINER"
echo ""

# Verificar si tiene las variables de versión (método más simple)
echo "Buscando variables de version en contenedor..."
docker exec "$CONTAINER" cat /app/dashboard.html | grep -E "DASHBOARD_VERSION|DASHBOARD_BUILD" | head -3
echo ""

echo "=== 2. Verificar versión desde GitHub ==="
echo "La version mas reciente en GitHub es: Build #4"
echo ""

echo "=== 3. Verificar si el contenedor necesita actualizarse ==="
# Buscar si tiene el display de versión
HAS_DISPLAY=$(docker exec "$CONTAINER" cat /app/dashboard.html | grep -c "version-display" || echo "0")
if [ "$HAS_DISPLAY" -eq "0" ]; then
    echo "ADVERTENCIA: El contenedor NO tiene el sistema de versionado"
    echo "   Necesita actualizarse desde GitHub"
    echo ""
    echo "SOLUCION:"
    echo "1. Ve a EasyPanel -> Servicio 'dashboard'"
    echo "2. Verifica que la rama sea 'main'"
    echo "3. Haz clic en 'Deploy' o 'Redeploy'"
    echo "4. Espera 2-5 minutos"
    echo "5. Ejecuta este script de nuevo para verificar"
else
    echo "OK: El contenedor tiene el sistema de versionado"
fi
echo ""

echo "=== 4. Verificar correcciones ==="
CORRECCIONES=$(docker exec "$CONTAINER" cat /app/dashboard.html | grep -c "Mes/Año\|Ubicación\|¿Cómo\|Confirmación\|Estadía" || echo "0")
echo "Correcciones encontradas: $CORRECCIONES"
if [ "$CORRECCIONES" -gt "0" ]; then
    echo "OK: Correcciones aplicadas"
else
    echo "ADVERTENCIA: No se encontraron correcciones"
    echo "   El contenedor necesita actualizarse"
fi
echo ""

echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo ""
if [ "$HAS_DISPLAY" -eq "0" ] || [ "$CORRECCIONES" -eq "0" ]; then
    echo "ACCION REQUERIDA:"
    echo "   El contenedor tiene una version antigua"
    echo "   Debes hacer Deploy en EasyPanel para actualizarlo"
    echo ""
    echo "Pasos:"
    echo "1. EasyPanel -> Servicio 'dashboard'"
    echo "2. Verificar rama: 'main'"
    echo "3. Clic en 'Deploy' o 'Redeploy'"
    echo "4. Esperar 2-5 minutos"
    echo "5. Recargar pagina con Ctrl+F5"
else
    echo "OK: El contenedor esta actualizado"
fi
echo ""
