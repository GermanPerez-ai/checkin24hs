#!/bin/bash
# Script final para actualizar dashboard desde GitHub
# El bind mount ya está configurado, solo necesitamos actualizar el archivo en /root/checkin24hs/dashboard.html

clear
echo "=========================================="
echo "⚠️  ⚠️  ⚠️  RECORDATORIO IMPORTANTE  ⚠️  ⚠️  ⚠️"
echo "=========================================="
echo ""
echo "📋 ANTES DE EJECUTAR ESTE SCRIPT:"
echo ""
echo "1️⃣  ¿Ya subiste los cambios a GitHub?"
echo "    → Ejecuta primero: .\ACTUALIZAR_DASHBOARD_COMPLETO.ps1 (en tu PC)"
echo "    → O: git add, commit, push"
echo ""
echo "2️⃣  ¿Estás seguro de que los cambios están en GitHub?"
echo "    → Verifica en: https://github.com/GermanPerez-ai/checkin24hs"
echo ""
echo "3️⃣  ¿El build number fue actualizado?"
echo "    → Verifica que el build number en GitHub sea mayor al actual"
echo ""
echo "=========================================="
echo ""
read -p "¿Ya subiste los cambios a GitHub? (s/n): " confirmacion

if [[ "$confirmacion" != "s" && "$confirmacion" != "S" ]]; then
    echo ""
    echo "❌ Por favor, primero sube los cambios a GitHub."
    echo "   Ejecuta: .\ACTUALIZAR_DASHBOARD_COMPLETO.ps1 (en tu PC)"
    echo ""
    exit 1
fi

echo ""
echo "=========================================="
echo "🔄 ACTUALIZAR DASHBOARD DESDE GITHUB"
echo "=========================================="
echo ""

cd /root/checkin24hs/

# Ruta del bind mount
BIND_MOUNT_PATH="/root/checkin24hs/dashboard.html"
SERVICE_NAME="checkin24hs_dashboard"

# Verificar build number actual en el servidor
echo "📊 Verificando build number actual en el servidor..."
if [ -f "$BIND_MOUNT_PATH" ]; then
    CURRENT_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$BIND_MOUNT_PATH" 2>/dev/null | head -1)
    if [ -n "$CURRENT_BUILD" ]; then
        echo "   Build actual en servidor: #$CURRENT_BUILD"
    else
        echo "   ⚠️  No se pudo leer build number actual"
    fi
else
    echo "   ⚠️  Archivo no existe aún en el servidor"
fi

echo ""
echo "📥 Descargando dashboard.html desde GitHub..."
curl -L -o "$BIND_MOUNT_PATH" https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

if [ $? -ne 0 ]; then
    echo "   ❌ ERROR: No se pudo descargar el archivo desde GitHub"
    exit 1
fi

echo ""
echo "📋 Verificando descarga..."
FILE_SIZE=$(wc -c < "$BIND_MOUNT_PATH")
echo "   Tamaño: $FILE_SIZE bytes"

# Verificar que el archivo tiene contenido válido
if [ "$FILE_SIZE" -lt 10000 ]; then
    echo "   ❌ ERROR: Archivo demasiado pequeño (posible error de descarga)"
    exit 1
fi

# Verificar build number en el archivo descargado
NEW_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$BIND_MOUNT_PATH" 2>/dev/null | head -1)

if [ -z "$NEW_BUILD" ]; then
    echo "   ⚠️  ADVERTENCIA: No se pudo leer build number del archivo descargado"
else
    echo "   Build number descargado: #$NEW_BUILD"
    
    if [ -n "$CURRENT_BUILD" ]; then
        if [ "$NEW_BUILD" -gt "$CURRENT_BUILD" ]; then
            echo "   ✅ Build number incrementado correctamente ($CURRENT_BUILD → $NEW_BUILD)"
        elif [ "$NEW_BUILD" -eq "$CURRENT_BUILD" ]; then
            echo "   ⚠️  ADVERTENCIA: Build number no cambió (sigue siendo #$NEW_BUILD)"
            echo "   💡 Asegúrate de haber actualizado el build number antes de subir a GitHub"
        else
            echo "   ⚠️  ADVERTENCIA: Build number es menor al actual ($NEW_BUILD < $CURRENT_BUILD)"
        fi
    fi
fi

# Verificar que el archivo tiene contenido válido de dashboard
if ! grep -q "DASHBOARD_BUILD_NUMBER" "$BIND_MOUNT_PATH"; then
    echo "   ❌ ERROR: El archivo no parece ser un dashboard.html válido"
    exit 1
fi

echo "   ✅ Archivo descargado correctamente"
echo ""

# Verificar bind mount
echo "🔍 Verificando bind mount..."
if docker service inspect "$SERVICE_NAME" 2>/dev/null | grep -q "$BIND_MOUNT_PATH"; then
    echo "   ✅ Bind mount configurado correctamente"
else
    echo "   ⚠️  ADVERTENCIA: Bind mount puede no estar configurado"
    echo "   💡 El archivo se actualizó en $BIND_MOUNT_PATH"
    echo "   💡 Puede ser necesario reiniciar el servicio"
fi

echo ""
echo "🔄 Reiniciando servicio para aplicar cambios..."
docker service update --force "$SERVICE_NAME" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ Servicio reiniciado"
else
    echo "   ⚠️  No se pudo reiniciar el servicio automáticamente"
    echo "   💡 Reinicia manualmente: docker service update --force $SERVICE_NAME"
fi

echo ""
echo "✅ Dashboard actualizado en /root/checkin24hs/dashboard.html"
if [ -n "$NEW_BUILD" ]; then
    echo "   Build #$NEW_BUILD"
fi
echo ""
echo "📋 Verificando que build en vivo = build local/GitHub..."
echo "   Esperando 15 s a que el servicio sirva el HTML nuevo..."
sleep 15
LIVE_BUILD=$(curl -s -L "https://dashboard.checkin24hs.com/" 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
if [ -n "$LIVE_BUILD" ] && [ -n "$NEW_BUILD" ]; then
    if [ "$LIVE_BUILD" = "$NEW_BUILD" ]; then
        echo "   ✅ Build en vivo: #$LIVE_BUILD = Build local/GitHub (#$NEW_BUILD)"
    else
        echo "   ⚠️  Build en vivo: #$LIVE_BUILD | Esperado (GitHub): #$NEW_BUILD"
        echo "   💡 Haz Ctrl+Shift+R en el navegador o espera 30 s y vuelve a verificar"
    fi
else
    echo "   ⚠️  No se pudo leer build en vivo (curl o sin BUILD_NUMBER en HTML)"
fi
echo ""
echo "🌐 Dashboard: https://dashboard.checkin24hs.com/"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Limpia la caché del navegador (Ctrl+Shift+R)"
echo "   2. Verifica build: sidebar o consola → window.DASHBOARD_BUILD_NUMBER"
echo "   3. Debe coincidir con dashboard.html local y GitHub"
echo ""
