#!/bin/bash

# Script para buscar y corregir código que genera URLs dinámicamente con puertos 3001-3004

echo "=========================================="
echo "🔍 Buscando Código que Genera URLs Dinámicamente"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_FILE="$HOME/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

echo "🔍 Buscando TODAS las formas de generar puertos 3001-3004..."
echo ""

# Buscar diferentes patrones
echo "1. Buscando '3000 + instanceNumber' o variaciones:"
grep -n "3000.*instanceNumber\|instanceNumber.*3000\|3000.*+" "$DASHBOARD_PATH" | head -10
echo ""

echo "2. Buscando construcción de URLs con puertos 3001-3004:"
grep -n "72.61.58.240.*300\|localhost.*300\|baseUrl.*300\|url.*300" "$DASHBOARD_PATH" | grep -v "4001\|4002\|4003\|4004" | head -10
echo ""

echo "3. Buscando template strings con puertos:"
grep -n "\`.*3001\|\`.*3002\|\`.*3003\|\`.*3004" "$DASHBOARD_PATH" | head -10
echo ""

echo "4. Buscando concatenación de strings:"
grep -n "'.*3001\|'.*3002\|'.*3003\|'.*3004\|"'.*3001\|"'.*3002\|"'.*3003\|"'.*3004" "$DASHBOARD_PATH" | head -10
echo ""

echo "=========================================="
read -p "¿Quieres aplicar correcciones automáticas? (s/n): " respuesta

if [ "$respuesta" != "s" ] && [ "$respuesta" != "S" ]; then
    echo "❌ Cancelado"
    exit 0
fi

echo ""
echo "🔧 Aplicando correcciones..."
echo ""

# Correcciones AGRESIVAS
sed -i 's/:3001/:4001/g' "$DASHBOARD_PATH"
sed -i 's/:3002/:4002/g' "$DASHBOARD_PATH"
sed -i 's/:3003/:4003/g' "$DASHBOARD_PATH"
sed -i 's/:3004/:4004/g' "$DASHBOARD_PATH"

# Corregir cálculos
sed -i 's/3000 + instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/instanceNumber + 3000/instanceNumber + 4000/g' "$DASHBOARD_PATH"
sed -i 's/3000+instanceNumber/4000+instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/3000 \+ instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"

# Corregir en strings
sed -i "s/'3001'/'4001'/g" "$DASHBOARD_PATH"
sed -i 's/"3001"/"4001"/g' "$DASHBOARD_PATH"
sed -i "s/'3002'/'4002'/g" "$DASHBOARD_PATH"
sed -i 's/"3002"/"4002"/g' "$DASHBOARD_PATH"
sed -i "s/'3003'/'4003'/g" "$DASHBOARD_PATH"
sed -i 's/"3003"/"4003"/g' "$DASHBOARD_PATH"
sed -i "s/'3004'/'4004'/g" "$DASHBOARD_PATH"
sed -i 's/"3004"/"4004"/g' "$DASHBOARD_PATH"

# Corregir concatenación
sed -i 's/+ 3001/+ 4001/g' "$DASHBOARD_PATH"
sed -i 's/+ 3002/+ 4002/g' "$DASHBOARD_PATH"
sed -i 's/+ 3003/+ 4003/g' "$DASHBOARD_PATH"
sed -i 's/+ 3004/+ 4004/g' "$DASHBOARD_PATH"
sed -i 's/+3001/+4001/g' "$DASHBOARD_PATH"
sed -i 's/+3002/+4002/g' "$DASHBOARD_PATH"
sed -i 's/+3003/+4003/g' "$DASHBOARD_PATH"
sed -i 's/+3004/+4004/g' "$DASHBOARD_PATH"

echo "✅ Correcciones aplicadas"
echo ""

echo "=========================================="
echo "🔄 Reiniciando dashboard..."
echo "=========================================="
pm2 restart dashboard
sleep 3

echo ""
echo "✅ Dashboard reiniciado"
echo ""
echo "⚠️  IMPORTANTE: Limpia la caché del navegador (Ctrl+Shift+R)"
echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com"
echo ""

