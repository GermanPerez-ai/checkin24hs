#!/bin/bash

# ============================================
# SCRIPT: Aplicar Cambio Azul Directamente en el Servidor
# ============================================
# Este script aplica el cambio de color azul directamente en el contenedor
# mientras se resuelve el problema del deploy en EasyPanel
#
# USO: Ejecutar en el servidor (SSH) como root

echo "🔵 Aplicando cambio de color azul directamente en el servidor..."
echo ""

# 1. Encontrar el contenedor del dashboard
echo "📋 Buscando contenedor del dashboard..."
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    echo "   Verifica que el servicio 'dashboard' esté corriendo en EasyPanel"
    exit 1
fi

echo "✅ Contenedor encontrado: $DASHBOARD_CONTAINER"
echo ""

# 2. Verificar el archivo actual
echo "📋 Verificando archivo actual..."
docker exec $DASHBOARD_CONTAINER sh -c "grep -A 2 '\.header h1' /app/dashboard.html | head -3" || echo "⚠️ No se pudo leer el archivo"
echo ""

# 3. Aplicar el cambio
echo "🔧 Aplicando cambio de color..."
docker exec $DASHBOARD_CONTAINER sh -c "sed -i 's/color: #333;/color: #1976d2; \/* Azul como el sidebar *\//g' /app/dashboard.html"

if [ $? -eq 0 ]; then
    echo "✅ Cambio aplicado exitosamente"
else
    echo "❌ Error al aplicar el cambio"
    exit 1
fi
echo ""

# 4. Verificar que se aplicó
echo "✅ Verificando que el cambio se aplicó..."
docker exec $DASHBOARD_CONTAINER sh -c "grep -A 2 '\.header h1' /app/dashboard.html | head -3"
echo ""

# 5. Reiniciar el contenedor
echo "🔄 Reiniciando contenedor..."
docker restart $DASHBOARD_CONTAINER

if [ $? -eq 0 ]; then
    echo "✅ Contenedor reiniciado exitosamente"
else
    echo "❌ Error al reiniciar el contenedor"
    exit 1
fi
echo ""

echo "============================================"
echo "✅ PROCESO COMPLETADO"
echo "============================================"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Espera 10-15 segundos para que el contenedor se reinicie"
echo "   2. Abre https://dashboard.checkin24hs.com"
echo "   3. Presiona Ctrl+F5 para forzar recarga (limpiar caché)"
echo "   4. 'Panel de Administración' debería ser AZUL"
echo ""
echo "⚠️ NOTA: Este cambio es TEMPORAL. Se perderá al reiniciar el servicio."
echo "   Para una solución permanente, sigue las instrucciones en:"
echo "   SOLUCION_DEPLOY_EASYPANEL.md"
echo ""

