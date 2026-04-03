#!/bin/bash
cd /root/checkin24hs

echo "=== VERIFICACIÓN DEL ARCHIVO dashboard.html ==="
echo ""

# 1. Número de líneas
echo "1. Número de líneas:"
wc -l deploy/dashboard.html
echo ""

# 2. Tamaño del archivo
echo "2. Tamaño del archivo:"
ls -lh deploy/dashboard.html
echo ""

# 3. Contenido línea 5148-5152
echo "3. Contenido línea 5148-5152:"
sed -n '5148,5152p' deploy/dashboard.html
echo ""

# 4. Verificar función showWhatsAppConfig (debe ser async)
echo "4. Verificando función showWhatsAppConfig (debe ser async):"
grep -n "async function showWhatsAppConfig\|function showWhatsAppConfig" deploy/dashboard.html | head -1
echo ""

# 5. Verificar modal adminModal
echo "5. Verificando modal adminModal:"
grep -n "adminModal" deploy/dashboard.html | head -3
echo ""

# 6. Verificar línea 5150 específicamente
echo "6. Línea 5150 específicamente:"
sed -n '5150p' deploy/dashboard.html
echo ""

# 7. Verificar caracteres especiales alrededor de línea 5150
echo "7. Caracteres especiales alrededor de línea 5150:"
sed -n '5148,5152p' deploy/dashboard.html | cat -A
echo ""

# 8. Verificar que no hay errores de sintaxis obvios
echo "8. Verificando sintaxis básica (buscando problemas comunes):"
echo "   - Comillas no cerradas alrededor de línea 5150:"
sed -n '5145,5155p' deploy/dashboard.html | grep -o "'" | wc -l | xargs -I {} echo "   Comillas simples encontradas: {}"
echo ""

# 9. Comparar con archivo local (si existe)
if [ -f "/root/checkin24hs/deploy/dashboard.html.backup" ]; then
    echo "9. Comparando con backup:"
    diff -u deploy/dashboard.html.backup deploy/dashboard.html | head -20 || echo "   No hay diferencias significativas"
else
    echo "9. No hay backup para comparar"
fi
echo ""

echo "=== VERIFICACIÓN COMPLETA ==="










