#!/bin/bash
# 📤 Subir cambios a GitHub

echo "=============================================================="
echo "📤 SUBIENDO CAMBIOS A GITHUB"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Verificar estado del repositorio
echo "1️⃣  Estado del repositorio:"
git status
echo ""

# 2. Verificar que el archivo tiene los cambios
echo "2️⃣  Verificando cambios en whatsapp-server-baileys.js:"
git diff whatsapp-server/whatsapp-server-baileys.js | head -30
echo ""

# 3. Agregar archivo
echo "3️⃣  Agregando archivo al staging:"
git add whatsapp-server/whatsapp-server-baileys.js
echo "   ✅ Archivo agregado"
echo ""

# 4. Verificar qué se va a commitear
echo "4️⃣  Archivos en staging:"
git status --short
echo ""

# 5. Hacer commit
echo "5️⃣  Haciendo commit..."
git commit -m "Fix: Corregir error qrExpirationTimer y reordenar inicio del servidor HTTP

- Agregada declaración de qrExpirationTimer en variables globales
- Reordenada función start() para iniciar servidor HTTP antes de conectar WhatsApp
- Servidor HTTP ahora inicia de forma no bloqueante
- Soluciona error 'ReferenceError: qrExpirationTimer is not defined'
- Soluciona problema de servidor HTTP no disponible durante conexión WhatsApp"
echo ""

# 6. Verificar remoto
echo "6️⃣  Verificando remoto:"
git remote -v
echo ""

# 7. Subir cambios
echo "7️⃣  Subiendo cambios a GitHub..."
git push
echo ""

echo "=============================================================="
echo "✅ CAMBIOS SUBIDOS A GITHUB"
echo "=============================================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Los cambios están ahora en GitHub"
echo "   2. En EasyPanel, puedes hacer 'Redeploy' para aplicar los cambios"
echo "   3. O esperar al próximo deployment automático"
echo ""
