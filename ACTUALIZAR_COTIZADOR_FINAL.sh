#!/bin/bash
# Script final para actualizar cotizador desde GitHub
# El bind mount ya está configurado, solo necesitamos actualizar los archivos en /root/checkin24hs/

clear
echo "=========================================="
echo "⚠️  ⚠️  ⚠️  RECORDATORIO IMPORTANTE  ⚠️  ⚠️  ⚠️"
echo "=========================================="
echo ""
echo "📋 ANTES DE EJECUTAR ESTE SCRIPT:"
echo ""
echo "1️⃣  ¿Ya subiste los cambios a GitHub?"
echo "    → Ejecuta primero: .\ACTUALIZAR_COTIZADOR_COMPLETO.ps1 (en tu PC)"
echo "    → O: git add, commit, push"
echo ""
echo "2️⃣  ¿Estás seguro de que los cambios están en GitHub?"
echo "    → Verifica en: https://github.com/GermanPerez-ai/checkin24hs"
echo ""
echo "=========================================="
echo ""
read -p "¿Ya subiste los cambios a GitHub? (s/n): " confirmacion

if [[ "$confirmacion" != "s" && "$confirmacion" != "S" ]]; then
    echo ""
    echo "❌ Por favor, primero sube los cambios a GitHub."
    echo "   Ejecuta: .\ACTUALIZAR_COTIZADOR_COMPLETO.ps1 (en tu PC)"
    echo ""
    exit 1
fi

echo ""
echo "=========================================="
echo "🔄 ACTUALIZAR COTIZADOR DESDE GITHUB"
echo "=========================================="
echo ""

cd /root/checkin24hs/

echo "📥 Descargando archivos desde GitHub..."
curl -L -o cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
curl -L -o supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
curl -L -o supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js

echo ""
echo "📋 Verificando descarga..."
FILE_SIZE=$(wc -c < cotizador-cliente.html)
echo "   Tamaño: $FILE_SIZE bytes"

if ! grep -q "showPromotionValidationModal" cotizador-cliente.html; then
    echo "   ❌ ERROR: showPromotionValidationModal NO encontrada"
    exit 1
fi

echo "   ✅ Archivo descargado correctamente"
echo ""

echo "📝 Actualizando index.html..."
cp cotizador-cliente.html index.html
echo "   ✅ index.html actualizado"
echo ""

echo "✅ Archivos actualizados en /root/checkin24hs/"
echo ""
echo "🌐 Los cambios se reflejarán automáticamente en:"
echo "   https://cotizar.checkin24hs.com/"
echo ""
echo "💡 Recuerda limpiar la caché del navegador (Ctrl+Shift+R)"
echo ""
