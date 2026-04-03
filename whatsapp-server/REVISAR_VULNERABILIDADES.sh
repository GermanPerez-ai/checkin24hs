#!/bin/bash

# Script para revisar y corregir vulnerabilidades de seguridad en whatsapp-server
# Ejecutar desde el directorio whatsapp-server

echo "🔍 Revisando vulnerabilidades de seguridad..."
echo ""

# Ver detalles de las vulnerabilidades
npm audit

echo ""
echo "=========================================="
echo "  INTENTANDO CORREGIR AUTOMÁTICAMENTE"
echo "=========================================="
echo ""

# Intentar corregir automáticamente (solo parches compatibles)
npm audit fix

echo ""
echo "=========================================="
echo "  VERIFICACIÓN POST-CORRECCIÓN"
echo "=========================================="
echo ""

# Verificar si quedan vulnerabilidades
npm audit

echo ""
echo "=========================================="
echo "  RESUMEN"
echo "=========================================="
echo ""
echo "Si quedan vulnerabilidades después de 'npm audit fix':"
echo "1. Revisa 'npm audit' para ver detalles"
echo "2. Algunas pueden requerir actualizaciones manuales"
echo "3. Ejecuta 'npm audit fix --force' solo si es seguro (puede romper compatibilidad)"
echo ""
echo "✅ Para reiniciar el servidor después de las correcciones:"
echo "   pm2 restart whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4"
echo ""
