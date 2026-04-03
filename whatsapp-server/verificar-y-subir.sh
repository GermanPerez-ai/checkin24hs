#!/bin/bash
# ✅ Verificar cambios y subir a GitHub

cd /root/checkin24hs

echo "=============================================================="
echo "✅ VERIFICANDO CAMBIOS"
echo "=============================================================="
echo ""

# 1. Verificar que el cambio se aplicó
echo "1️⃣  Verificando que el archivo tiene el código actualizado..."
if grep -q "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js; then
    echo "   ✅ El archivo tiene el código actualizado"
else
    echo "   ❌ El archivo NO tiene el código actualizado"
    exit 1
fi
echo ""

# 2. Ver el estado de Git
echo "2️⃣  Estado de Git..."
git status whatsapp-server/whatsapp-server-baileys.js
echo ""

# 3. Ver diferencias
echo "3️⃣  Diferencias (primeras 30 líneas)..."
git diff whatsapp-server/whatsapp-server-baileys.js | head -30
echo ""

echo "=============================================================="
echo "📤 PARA SUBIR A GITHUB:"
echo "=============================================================="
echo ""
echo "Ejecuta estos comandos:"
echo ""
echo "git add whatsapp-server/whatsapp-server-baileys.js"
echo "git commit -m 'Fix: Iniciar servidor HTTP antes de conectar WhatsApp'"
echo "git push"
echo ""
echo "=============================================================="
echo ""
