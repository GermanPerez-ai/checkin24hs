#!/bin/bash
# 📤 Subir fix de conflicto de sesión a GitHub

echo "=============================================================="
echo "📤 SUBIENDO FIX DE CONFLICTO DE SESIÓN"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Verificar cambios
echo "1️⃣  Verificando cambios:"
git status --short whatsapp-server/whatsapp-server-baileys.js
echo ""

# 2. Ver diferencias
echo "2️⃣  Diferencias en el archivo:"
git diff whatsapp-server/whatsapp-server-baileys.js | grep -A 5 -B 5 "Stream Errored" | head -20
echo ""

# 3. Agregar archivo
echo "3️⃣  Agregando archivo:"
git add whatsapp-server/whatsapp-server-baileys.js
echo "   ✅ Archivo agregado"
echo ""

# 4. Hacer commit
echo "4️⃣  Haciendo commit:"
git commit -m "Fix: Manejar error Stream Errored (conflict) limpiando sesión automáticamente

- Detecta error 'Stream Errored (conflict)' específicamente
- Limpia sesión conflictiva automáticamente
- Genera nuevo QR code automáticamente
- Reconecta sin intervención manual
- Soluciona problema de 'no se pudo iniciar la sesión' después de escanear QR"
echo ""

# 5. Subir a GitHub
echo "5️⃣  Subiendo a GitHub:"
git push
echo ""

echo "=============================================================="
echo "✅ CAMBIOS SUBIDOS A GITHUB"
echo "=============================================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Los cambios están ahora en GitHub"
echo "   2. El servidor ya tiene el fix aplicado (copiado al contenedor)"
echo "   3. En el próximo redeploy, el fix estará incluido automáticamente"
echo ""
echo "💡 Cuando aparezca el error 'Stream Errored (conflict)':"
echo "   - El servidor limpiará la sesión automáticamente"
echo "   - Generará un nuevo QR code"
echo "   - Podrás escanear el nuevo QR sin problemas"
echo ""
