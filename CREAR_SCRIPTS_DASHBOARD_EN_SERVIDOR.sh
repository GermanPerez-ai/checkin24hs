#!/bin/bash
# Script para crear los scripts de actualización del dashboard directamente en el servidor

cd /root/checkin24hs/

echo "=========================================="
echo "📝 Creando scripts de actualización del dashboard..."
echo "=========================================="
echo ""

# Crear ACTUALIZAR_DASHBOARD_FINAL.sh
cat > ACTUALIZAR_DASHBOARD_FINAL.sh << 'SCRIPT_EOF'
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
echo "🌐 Los cambios se reflejarán automáticamente en:"
echo "   https://dashboard.checkin24hs.com/"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Limpia la caché del navegador (Ctrl+Shift+R)"
echo "   2. Verifica el build number en la consola: window.DASHBOARD_BUILD_NUMBER"
echo "   3. El build number también se muestra en el sidebar del dashboard"
echo ""
SCRIPT_EOF

chmod +x ACTUALIZAR_DASHBOARD_FINAL.sh
echo "✅ ACTUALIZAR_DASHBOARD_FINAL.sh creado"

# Crear RECORDATORIO_ACTUALIZAR_DASHBOARD.sh
cat > RECORDATORIO_ACTUALIZAR_DASHBOARD.sh << 'SCRIPT_EOF'
#!/bin/bash
# ⚠️ RECORDATORIO: Cómo actualizar el dashboard en el servidor
# Ejecuta este script para ver las instrucciones

clear
echo "=========================================="
echo "⚠️  RECORDATORIO: ACTUALIZAR DASHBOARD"
echo "=========================================="
echo ""
echo "📋 PASOS A SEGUIR:"
echo ""
echo "1️⃣  PRIMERO: Subir cambios a GitHub (desde tu PC)"
echo "   - Ejecuta: .\ACTUALIZAR_DASHBOARD_COMPLETO.ps1"
echo "   - O manualmente: git add, commit, push"
echo "   - IMPORTANTE: Actualiza el build number antes de subir"
echo ""
echo "2️⃣  SEGUNDO: Actualizar en el servidor"
echo "   - Conecta al servidor por SSH"
echo "   - Ejecuta: ./ACTUALIZAR_DASHBOARD_FINAL.sh"
echo ""
echo "3️⃣  TERCERO: Verificar"
echo "   - Limpia caché del navegador (Ctrl+Shift+R)"
echo "   - Abre: https://dashboard.checkin24hs.com/"
echo "   - Verifica build number: window.DASHBOARD_BUILD_NUMBER"
echo ""
echo "=========================================="
echo ""
read -p "¿Quieres ejecutar la actualización ahora? (s/n): " respuesta

if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
    echo ""
    echo "🔄 Ejecutando actualización..."
    echo ""
    cd /root/checkin24hs/
    ./ACTUALIZAR_DASHBOARD_FINAL.sh
else
    echo ""
    echo "✅ Instrucciones mostradas. Ejecuta ./ACTUALIZAR_DASHBOARD_FINAL.sh cuando estés listo."
    echo ""
fi
SCRIPT_EOF

chmod +x RECORDATORIO_ACTUALIZAR_DASHBOARD.sh
echo "✅ RECORDATORIO_ACTUALIZAR_DASHBOARD.sh creado"

echo ""
echo "=========================================="
echo "✅ Scripts creados correctamente"
echo "=========================================="
echo ""
echo "📋 Scripts disponibles:"
ls -lh ACTUALIZAR_DASHBOARD_FINAL.sh RECORDATORIO_ACTUALIZAR_DASHBOARD.sh
echo ""
