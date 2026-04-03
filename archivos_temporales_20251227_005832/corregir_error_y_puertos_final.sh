#!/bin/bash

# Script para corregir error de sintaxis y puertos dinámicos

echo "=========================================="
echo "🔧 Corrección de Error y Puertos Dinámicos"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_FILE="$HOME/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

echo "🔍 Buscando errores..."
echo ""

# Buscar el error de sintaxis
echo "1. Buscando console.Derror:"
grep -n "Derror\|console\.D" "$DASHBOARD_PATH" | head -5
echo ""

# Buscar código que genera puertos dinámicamente
echo "2. Buscando código que genera puertos 3001-3004:"
grep -n "3000.*instanceNumber\|instanceNumber.*3000\|3000.*+" "$DASHBOARD_PATH" | head -10
echo ""

echo "🔧 Aplicando correcciones..."
echo ""

# Corregir error de sintaxis
sed -i 's/console\.Derror/console.error/g' "$DASHBOARD_PATH"
sed -i 's/console\.D/console./g' "$DASHBOARD_PATH"

# Corregir TODAS las formas de puertos
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

# Corregir mensajes
sed -i 's/puerto 3001/puerto 4001/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3002/puerto 4002/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3003/puerto 4003/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3004/puerto 4004/g' "$DASHBOARD_PATH"

echo "✅ Correcciones aplicadas"
echo ""

# Verificar
echo "🔍 Verificando..."
echo ""
echo "Buscando console.Derror (no debería aparecer):"
grep -n "Derror\|console\.D" "$DASHBOARD_PATH" | head -3 || echo "✅ No se encontraron errores de sintaxis"
echo ""

echo "Buscando puertos 4001-4004:"
grep -c ":4001\|:4002\|:4003\|:4004" "$DASHBOARD_PATH" || echo "0"
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

