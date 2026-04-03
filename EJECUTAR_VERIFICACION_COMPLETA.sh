#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICACIÓN COMPLETA DE SESIONES"
echo "=========================================="
echo ""

# 1. Actualizar código
echo "1️⃣ Actualizando código desde GitHub..."
echo "----------------------------------------"
cd ~/checkin24hs
git pull origin main 2>&1 | tail -5
echo ""

# 2. Dar permisos a los scripts
echo "2️⃣ Dando permisos a los scripts..."
echo "----------------------------------------"
chmod +x VERIFICAR_SESIONES_SERVIDOR.sh 2>/dev/null && echo "✅ VERIFICAR_SESIONES_SERVIDOR.sh" || echo "⚠️  VERIFICAR_SESIONES_SERVIDOR.sh no encontrado"
chmod +x LIMPIAR_TODAS_LAS_SESIONES.sh 2>/dev/null && echo "✅ LIMPIAR_TODAS_LAS_SESIONES.sh" || echo "⚠️  LIMPIAR_TODAS_LAS_SESIONES.sh no encontrado"
echo ""

# 3. Verificar sesiones
echo "3️⃣ Verificando sesiones en el servidor..."
echo "----------------------------------------"
if [ -f "VERIFICAR_SESIONES_SERVIDOR.sh" ]; then
    ./VERIFICAR_SESIONES_SERVIDOR.sh
else
    echo "❌ Script VERIFICAR_SESIONES_SERVIDOR.sh no encontrado"
    echo "   Ejecuta: git pull origin main"
fi

echo ""
echo "=========================================="
echo "💡 PRÓXIMOS PASOS"
echo "=========================================="
echo ""
echo "Si ves sesiones guardadas, ejecuta:"
echo "   ./LIMPIAR_TODAS_LAS_SESIONES.sh"
echo ""
