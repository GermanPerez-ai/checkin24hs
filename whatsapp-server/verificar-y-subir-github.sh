#!/bin/bash
# 🔍 Verificar y subir cambios a GitHub

echo "=============================================================="
echo "🔍 VERIFICANDO REPOSITORIO GIT"
echo "=============================================================="
echo ""

# 1. Verificar si hay repositorio Git en /root/checkin24hs
echo "1️⃣  Verificando repositorio Git..."
cd /root/checkin24hs 2>/dev/null || {
    echo "   ⚠️  No se encontró /root/checkin24hs"
    echo "   Buscando repositorio Git..."
    find /root -name ".git" -type d 2>/dev/null | head -3
    exit 1
}

if [ -d ".git" ]; then
    echo "   ✅ Repositorio Git encontrado en: $(pwd)"
    echo ""
    echo "   📋 Estado del repositorio:"
    git status --short
    echo ""
    echo "   🔗 Remoto configurado:"
    git remote -v
else
    echo "   ⚠️  No hay repositorio Git aquí"
    echo "   Necesitas inicializar Git o clonar el repositorio"
    exit 1
fi

echo ""
echo "2️⃣  Verificando archivo whatsapp-server-baileys.js..."
echo "--------------------------------------------------------------"
if [ -f "whatsapp-server/whatsapp-server-baileys.js" ]; then
    echo "   ✅ Archivo encontrado: whatsapp-server/whatsapp-server-baileys.js"
    echo "   📏 Tamaño: $(wc -l < whatsapp-server/whatsapp-server-baileys.js) líneas"
    
    # Verificar si tiene el código actualizado (buscar "Iniciar servidor HTTP PRIMERO")
    if grep -q "Iniciar servidor HTTP PRIMERO" whatsapp-server/whatsapp-server-baileys.js; then
        echo "   ✅ El archivo YA tiene el código actualizado"
    else
        echo "   ⚠️  El archivo NO tiene el código actualizado"
        echo "   Necesitas copiar el código actualizado aquí"
    fi
else
    echo "   ⚠️  Archivo no encontrado en whatsapp-server/"
fi
echo ""

echo "=============================================================="
echo "📤 PARA SUBIR A GITHUB:"
echo "=============================================================="
echo ""
echo "Ejecuta estos comandos:"
echo ""
echo "cd /root/checkin24hs"
echo "git add whatsapp-server/whatsapp-server-baileys.js"
echo "git commit -m 'Fix: Iniciar servidor HTTP antes de conectar WhatsApp'"
echo "git push"
echo ""
echo "=============================================================="
echo ""
