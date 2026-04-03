#!/bin/bash
# ⚠️ RECORDATORIO: Cómo actualizar el cotizador en el servidor
# Ejecuta este script para ver las instrucciones

clear
echo "=========================================="
echo "⚠️  RECORDATORIO: ACTUALIZAR COTIZADOR"
echo "=========================================="
echo ""
echo "📋 PASOS A SEGUIR:"
echo ""
echo "1️⃣  PRIMERO: Subir cambios a GitHub (desde tu PC)"
echo "   - Ejecuta: .\ACTUALIZAR_COTIZADOR_COMPLETO.ps1"
echo "   - O manualmente: git add, commit, push"
echo ""
echo "2️⃣  SEGUNDO: Actualizar en el servidor"
echo "   - Conecta al servidor por SSH"
echo "   - Ejecuta: ./ACTUALIZAR_COTIZADOR_FINAL.sh"
echo ""
echo "3️⃣  TERCERO: Verificar"
echo "   - Limpia caché del navegador (Ctrl+Shift+R)"
echo "   - Abre: https://cotizar.checkin24hs.com/"
echo ""
echo "=========================================="
echo ""
read -p "¿Quieres ejecutar la actualización ahora? (s/n): " respuesta

if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
    echo ""
    echo "🔄 Ejecutando actualización..."
    echo ""
    cd /root/checkin24hs/
    ./ACTUALIZAR_COTIZADOR_FINAL.sh
else
    echo ""
    echo "✅ Instrucciones mostradas. Ejecuta ./ACTUALIZAR_COTIZADOR_FINAL.sh cuando estés listo."
    echo ""
fi
