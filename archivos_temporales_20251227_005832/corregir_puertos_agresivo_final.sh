#!/bin/bash

# Script FINAL y AGRESIVO para corregir TODAS las referencias a puertos 3001-3004
# Incluye corrección de código que genera puertos dinámicamente

echo "=========================================="
echo "🔧 Corrección FINAL y AGRESIVA de Puertos"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_FILE="$HOME/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

echo "🔧 Aplicando correcciones AGRESIVAS..."
echo ""

# 1. Corregir TODAS las URLs con puertos (más agresivo)
sed -i 's/:3001/:4001/g' "$DASHBOARD_PATH"
sed -i 's/:3002/:4002/g' "$DASHBOARD_PATH"
sed -i 's/:3003/:4003/g' "$DASHBOARD_PATH"
sed -i 's/:3004/:4004/g' "$DASHBOARD_PATH"

# 2. Corregir strings con puertos (todas las formas)
sed -i "s/'3001'/'4001'/g" "$DASHBOARD_PATH"
sed -i 's/"3001"/"4001"/g' "$DASHBOARD_PATH"
sed -i "s/'3002'/'4002'/g" "$DASHBOARD_PATH"
sed -i 's/"3002"/"4002"/g' "$DASHBOARD_PATH"
sed -i "s/'3003'/'4003'/g" "$DASHBOARD_PATH"
sed -i 's/"3003"/"4003"/g' "$DASHBOARD_PATH"
sed -i "s/'3004'/'4004'/g" "$DASHBOARD_PATH"
sed -i 's/"3004"/"4004"/g' "$DASHBOARD_PATH"

# 3. Corregir cálculos de puerto (todas las variaciones)
sed -i 's/3000 + instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/instanceNumber + 3000/instanceNumber + 4000/g' "$DASHBOARD_PATH"
sed -i 's/3000+instanceNumber/4000+instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/3000 \+ instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/3000+ instanceNumber/4000+ instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/3000 +instanceNumber/4000 +instanceNumber/g' "$DASHBOARD_PATH"

# 4. Corregir en template strings
sed -i 's/\${3000 + instanceNumber}/\${4000 + instanceNumber}/g' "$DASHBOARD_PATH"
sed -i 's/\`3000 + instanceNumber\`/\`4000 + instanceNumber\`/g' "$DASHBOARD_PATH"
sed -i 's/\${3000+instanceNumber}/\${4000+instanceNumber}/g' "$DASHBOARD_PATH"

# 5. Corregir concatenación de strings con puertos
sed -i 's/+ 3001/+ 4001/g' "$DASHBOARD_PATH"
sed -i 's/+ 3002/+ 4002/g' "$DASHBOARD_PATH"
sed -i 's/+ 3003/+ 4003/g' "$DASHBOARD_PATH"
sed -i 's/+ 3004/+ 4004/g' "$DASHBOARD_PATH"
sed -i 's/+3001/+4001/g' "$DASHBOARD_PATH"
sed -i 's/+3002/+4002/g' "$DASHBOARD_PATH"
sed -i 's/+3003/+4003/g' "$DASHBOARD_PATH"
sed -i 's/+3004/+4004/g' "$DASHBOARD_PATH"

# 6. Corregir en mensajes
sed -i 's/puerto 3001/puerto 4001/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3002/puerto 4002/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3003/puerto 4003/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3004/puerto 4004/g' "$DASHBOARD_PATH"

# 7. Corregir números directos en código (más agresivo - solo si están en contexto de puerto)
# Buscar patrones como: port = 3001, PORT: 3001, etc.
sed -i 's/port.*=.*3001/port = 4001/g' "$DASHBOARD_PATH"
sed -i 's/port.*=.*3002/port = 4002/g' "$DASHBOARD_PATH"
sed -i 's/port.*=.*3003/port = 4003/g' "$DASHBOARD_PATH"
sed -i 's/port.*=.*3004/port = 4004/g' "$DASHBOARD_PATH"

# 8. Corregir en objetos/arrays
sed -i 's/3001,/4001,/g' "$DASHBOARD_PATH"
sed -i 's/3002,/4002,/g' "$DASHBOARD_PATH"
sed -i 's/3003,/4003,/g' "$DASHBOARD_PATH"
sed -i 's/3004,/4004,/g' "$DASHBOARD_PATH"

echo "✅ Correcciones aplicadas"
echo ""

# Verificar
echo "🔍 Verificando..."
echo ""
echo "Buscando puertos 4001-4004:"
grep -c ":4001\|:4002\|:4003\|:4004" "$DASHBOARD_PATH" || echo "0"
echo ""

echo "Buscando si quedan referencias a 3001-3004 en URLs:"
grep -n ":\"3001\"\|:\"3002\"\|:\"3003\"\|:\"3004\"" "$DASHBOARD_PATH" | head -3 || echo "✅ No se encontraron"
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

