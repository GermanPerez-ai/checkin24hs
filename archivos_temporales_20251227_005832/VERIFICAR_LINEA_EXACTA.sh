#!/bin/bash
# Script para verificar la línea exacta 5150

cd /root/checkin24hs

echo "Verificando archivo en servidor..."
echo ""

echo "Líneas 5148-5154 en servidor:"
sed -n '5148,5154p' deploy/dashboard.html

echo ""
echo "Buscando 'var date = null' en el archivo:"
grep -n "var date = null" deploy/dashboard.html | head -3

echo ""
echo "Buscando 'if (!dateValue) return null' en el archivo:"
grep -n "if (!dateValue) return null" deploy/dashboard.html | head -3

echo ""
echo "Verificando función normalizeDate:"
grep -n "const normalizeDate = function" deploy/dashboard.html | head -1




