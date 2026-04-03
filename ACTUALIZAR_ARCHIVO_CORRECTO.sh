#!/bin/bash
# Actualizar el archivo correcto que está montado en el contenedor

echo "🔧 Actualizando archivo correcto..."
echo ""

# El contenedor monta /root/checkin24hs/dashboard.html
ARCHIVO_MONTADO="/root/checkin24hs/dashboard.html"

# 1. Descargar Build #39
echo "[1/3] Descargando Build #39 al archivo correcto..."
curl -L -o "$ARCHIVO_MONTADO" https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo descargado"
else
    echo "❌ Error al descargar"
    exit 1
fi

# 2. Verificar Build
echo ""
echo "[2/3] Verificando Build..."
BUILD_NUM=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$ARCHIVO_MONTADO" | head -1)
echo "Build Number: $BUILD_NUM"

if [ "$BUILD_NUM" = "39" ]; then
    echo "✅ Build #39 confirmado"
else
    echo "⚠️  Build es $BUILD_NUM, esperado 39"
fi

# 3. Reiniciar servicio
echo ""
echo "[3/3] Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

echo ""
echo "✅ Proceso completado"
echo ""
echo "Espera 10 segundos y luego:"
echo "1. Limpia caché del navegador"
echo "2. Recarga con Ctrl+Shift+R"
echo "3. Verifica: window.DASHBOARD_BUILD_NUMBER (debe ser 39)"
