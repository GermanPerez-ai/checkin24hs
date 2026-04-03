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
echo "1️⃣  PRIMERO: Actualizar el build local (desde tu PC)"
echo "   - Abre PowerShell en la carpeta del proyecto"
echo "   - Ejecuta: .\actualizar_build_dashboard.ps1"
echo ""
echo "2️⃣  SEGUNDO: Subir cambios a GitHub (desde tu PC)"
echo "   - Ejecuta: .\ACTUALIZAR_DASHBOARD_COMPLETO.ps1"
echo "   - O manualmente: git add, commit, push"
echo ""
echo "3️⃣  TERCERO: Actualizar en el servidor"
echo "   - Conecta al servidor por SSH"
echo "   - Ejecuta: ./ACTUALIZAR_DASHBOARD_FINAL.sh"
echo ""
echo "4️⃣  CUARTO: Verificar"
echo "   - Limpia caché del navegador (Ctrl+Shift+R)"
echo "   - Abre: https://dashboard.checkin24hs.com/"
echo "   - Verifica: Build # = window.DASHBOARD_BUILD_NUMBER"
echo "   - Debe coincidir con dashboard.html local y con lo que muestra el script en servidor"
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
