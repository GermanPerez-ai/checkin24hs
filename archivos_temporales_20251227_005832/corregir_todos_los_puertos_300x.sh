#!/bin/bash

# Script agresivo para corregir TODAS las referencias a puertos 3001-3004
# en dashboard.html

echo "=========================================="
echo "🔧 Corrección Agresiva de Puertos 3001-3004"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_FILE="$HOME/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Buscar TODAS las referencias
echo "🔍 Buscando referencias a puertos 3001-3004..."
echo ""

# Buscar en diferentes formatos
echo "1. Buscando ':3001', ':3002', etc. en URLs:"
grep -n ":\"3001\"\|:\"3002\"\|:\"3003\"\|:\"3004\"\|:'3001'\|:'3002'\|:'3003'\|:'3004'" "$DASHBOARD_PATH" | head -10
echo ""

echo "2. Buscando '3001', '3002', etc. en cálculos:"
grep -n "3001\|3002\|3003\|3004" "$DASHBOARD_PATH" | grep -E "instanceNumber|port|PORT" | grep -v "4001\|4002\|4003\|4004" | head -10
echo ""

echo "3. Buscando '3000 +' o '+ 3000':"
grep -n "3000.*+\|+.*3000" "$DASHBOARD_PATH" | head -10
echo ""

echo "=========================================="
echo "🔧 Aplicando correcciones..."
echo "=========================================="
echo ""

# Corregir URLs con puertos
sed -i 's/:3001/:4001/g' "$DASHBOARD_PATH"
sed -i 's/:3002/:4002/g' "$DASHBOARD_PATH"
sed -i 's/:3003/:4003/g' "$DASHBOARD_PATH"
sed -i 's/:3004/:4004/g' "$DASHBOARD_PATH"

# Corregir en strings
sed -i "s/'3001'/'4001'/g" "$DASHBOARD_PATH"
sed -i 's/"3001"/"4001"/g' "$DASHBOARD_PATH"
sed -i "s/'3002'/'4002'/g" "$DASHBOARD_PATH"
sed -i 's/"3002"/"4002"/g' "$DASHBOARD_PATH"
sed -i "s/'3003'/'4003'/g" "$DASHBOARD_PATH"
sed -i 's/"3003"/"4003"/g' "$DASHBOARD_PATH"
sed -i "s/'3004'/'4004'/g" "$DASHBOARD_PATH"
sed -i 's/"3004"/"4004"/g' "$DASHBOARD_PATH"

# Corregir cálculos
sed -i 's/3000 + instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/instanceNumber + 3000/instanceNumber + 4000/g' "$DASHBOARD_PATH"
sed -i 's/3000+instanceNumber/4000+instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/3000 \+ instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"

# Corregir en template strings
sed -i 's/\${3000 + instanceNumber}/\${4000 + instanceNumber}/g' "$DASHBOARD_PATH"
sed -i 's/\`3000 + instanceNumber\`/\`4000 + instanceNumber\`/g' "$DASHBOARD_PATH"
sed -i 's/\${3000+instanceNumber}/\${4000+instanceNumber}/g' "$DASHBOARD_PATH"

# Corregir en mensajes de error
sed -i 's/puerto 3001/puerto 4001/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3002/puerto 4002/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3003/puerto 4003/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3004/puerto 4004/g' "$DASHBOARD_PATH"

# Corregir en comentarios (opcional, pero por si acaso)
sed -i 's/3001-3004/4001-4004/g' "$DASHBOARD_PATH"
sed -i 's/3001, 3002, 3003, 3004/4001, 4002, 4003, 4004/g' "$DASHBOARD_PATH"

echo "✅ Correcciones aplicadas"
echo ""

# Verificar
echo "🔍 Verificando correcciones..."
echo ""
echo "Buscando puertos 4001-4004:"
grep -n ":4001\|:4002\|:4003\|:4004" "$DASHBOARD_PATH" | head -5
echo ""

echo "Buscando si quedan referencias a 3001-3004 (no deberían aparecer):"
grep -n ":\"3001\"\|:\"3002\"\|:\"3003\"\|:\"3004\"" "$DASHBOARD_PATH" | head -5 || echo "✅ No se encontraron referencias a puertos 3001-3004"
echo ""

echo "=========================================="
echo "🔄 Reiniciando dashboard..."
echo "=========================================="
pm2 restart dashboard
sleep 3

echo ""
echo "✅ Dashboard reiniciado"
echo ""
echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com"
echo ""

