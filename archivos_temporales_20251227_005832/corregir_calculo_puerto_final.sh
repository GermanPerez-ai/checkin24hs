#!/bin/bash

# Script para corregir el cálculo de puertos que genera 3001-3004
# El problema está en: const instancePort = 3001 + (instanceNumber - 1);

echo "=========================================="
echo "🔧 Corrigiendo Cálculo de Puertos"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_FILE="$HOME/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

echo "🔍 Buscando cálculos de puertos problemáticos..."
echo ""

# Buscar el patrón específico
echo "1. Buscando '3001 + (instanceNumber - 1)':"
grep -n "3001.*instanceNumber\|instanceNumber.*3001" "$DASHBOARD_PATH" | head -10
echo ""

echo "2. Buscando '3000 + instanceNumber':"
grep -n "3000.*instanceNumber\|instanceNumber.*3000" "$DASHBOARD_PATH" | head -10
echo ""

echo "3. Buscando 'instancePort = 3001':"
grep -n "instancePort.*3001\|3001.*instancePort" "$DASHBOARD_PATH" | head -10
echo ""

echo "=========================================="
echo "🔧 Aplicando correcciones..."
echo ""

# CORRECCIÓN PRINCIPAL: Cambiar el cálculo de puerto
sed -i 's/3001 + (instanceNumber - 1)/4001 + (instanceNumber - 1)/g' "$DASHBOARD_PATH"
sed -i 's/3001 \+ (instanceNumber - 1)/4001 + (instanceNumber - 1)/g' "$DASHBOARD_PATH"
sed -i 's/3001+(instanceNumber-1)/4001+(instanceNumber-1)/g' "$DASHBOARD_PATH"

# Otras variaciones posibles
sed -i 's/3000 + instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/instanceNumber + 3000/instanceNumber + 4000/g' "$DASHBOARD_PATH"
sed -i 's/3000+instanceNumber/4000+instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/instanceNumber+3000/instanceNumber+4000/g' "$DASHBOARD_PATH"

# Corregir cualquier referencia directa a puertos 3001-3004 en cálculos
sed -i 's/const instancePort = 3001/const instancePort = 4001/g' "$DASHBOARD_PATH"
sed -i 's/let instancePort = 3001/let instancePort = 4001/g' "$DASHBOARD_PATH"
sed -i 's/var instancePort = 3001/var instancePort = 4001/g' "$DASHBOARD_PATH"

# Corregir en template strings
sed -i 's/\${3001/\${4001/g' "$DASHBOARD_PATH"
sed -i 's/\${3002/\${4002/g' "$DASHBOARD_PATH"
sed -i 's/\${3003/\${4003/g' "$DASHBOARD_PATH"
sed -i 's/\${3004/\${4004/g' "$DASHBOARD_PATH"

# Corregir cualquier puerto 3001-3004 que quede
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

# Corregir mensajes de error
sed -i 's/puerto 3001/puerto 4001/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3002/puerto 4002/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3003/puerto 4003/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3004/puerto 4004/g' "$DASHBOARD_PATH"

echo "✅ Correcciones aplicadas"
echo ""

echo "=========================================="
echo "🔍 Verificando correcciones..."
echo ""

# Verificar que no queden puertos 3001-3004
REMAINING=$(grep -c "3001\|3002\|3003\|3004" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$REMAINING" -gt 0 ]; then
    echo "⚠️  Aún quedan referencias a puertos 3001-3004:"
    grep -n "3001\|3002\|3003\|3004" "$DASHBOARD_PATH" | head -10
    echo ""
else
    echo "✅ No se encontraron más referencias a puertos 3001-3004"
    echo ""
fi

echo "=========================================="
echo "🔄 Reiniciando dashboard..."
echo "=========================================="
pm2 restart dashboard
sleep 3

echo ""
echo "✅ Dashboard reiniciado"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   1. Limpia la caché del navegador (Ctrl+Shift+R o Ctrl+F5)"
echo "   2. Cierra y vuelve a abrir el navegador"
echo "   3. Prueba acceder a: https://dashboard.checkin24hs.com"
echo ""

