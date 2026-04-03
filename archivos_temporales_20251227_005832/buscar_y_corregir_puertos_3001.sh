#!/bin/bash

# Script para buscar y corregir TODAS las referencias a puertos 3001-3004
# en el dashboard.html

echo "=========================================="
echo "🔍 Buscando referencias a puertos 3001-3004"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_FILE="$HOME/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Buscar todas las referencias
echo "🔍 Buscando referencias..."
echo ""

echo "1. Buscando '3000 + instanceNumber' o similar:"
grep -n "3000.*instanceNumber\|instanceNumber.*3000\|3000.*\+" "$DASHBOARD_PATH" | head -10
echo ""

echo "2. Buscando '3001' hardcodeado:"
grep -n "3001" "$DASHBOARD_PATH" | grep -v "4001\|30010\|30011\|30012\|30013\|30014\|30015\|30016\|30017\|30018\|30019" | head -20
echo ""

echo "3. Buscando '3002' hardcodeado:"
grep -n "3002" "$DASHBOARD_PATH" | grep -v "4002\|30020\|30021\|30022\|30023\|30024\|30025\|30026\|30027\|30028\|30029" | head -10
echo ""

echo "4. Buscando '3003' hardcodeado:"
grep -n "3003" "$DASHBOARD_PATH" | grep -v "4003\|30030\|30031\|30032\|30033\|30034\|30035\|30036\|30037\|30038\|30039" | head -10
echo ""

echo "5. Buscando '3004' hardcodeado:"
grep -n "3004" "$DASHBOARD_PATH" | grep -v "4004\|30040\|30041\|30042\|30043\|30044\|30045\|30046\|30047\|30048\|30049" | head -10
echo ""

echo "=========================================="
echo "¿Quieres corregir automáticamente?"
echo "=========================================="
echo ""
echo "Esto reemplazará:"
echo "  - '3000 + instanceNumber' → '4000 + instanceNumber'"
echo "  - '3001' → '4001' (solo en contextos de puerto)"
echo "  - '3002' → '4002' (solo en contextos de puerto)"
echo "  - '3003' → '4003' (solo en contextos de puerto)"
echo "  - '3004' → '4004' (solo en contextos de puerto)"
echo ""
read -p "¿Continuar? (s/n): " respuesta

if [ "$respuesta" != "s" ] && [ "$respuesta" != "S" ]; then
    echo "❌ Cancelado"
    exit 0
fi

echo ""
echo "🔧 Corrigiendo..."

# Corregir cálculos de puerto
sed -i 's/3000 + instanceNumber/4000 + instanceNumber/g' "$DASHBOARD_PATH"
sed -i 's/instanceNumber + 3000/instanceNumber + 4000/g' "$DASHBOARD_PATH"
sed -i 's/3000+instanceNumber/4000+instanceNumber/g' "$DASHBOARD_PATH"

# Corregir puertos específicos (solo en contextos relevantes)
# Usar expresiones más específicas para evitar reemplazar números que no son puertos
sed -i 's/:3001/:4001/g' "$DASHBOARD_PATH"
sed -i 's/:3002/:4002/g' "$DASHBOARD_PATH"
sed -i 's/:3003/:4003/g' "$DASHBOARD_PATH"
sed -i 's/:3004/:4004/g' "$DASHBOARD_PATH"

# Corregir en mensajes de error
sed -i 's/puerto 3001/puerto 4001/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3002/puerto 4002/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3003/puerto 4003/g' "$DASHBOARD_PATH"
sed -i 's/puerto 3004/puerto 4004/g' "$DASHBOARD_PATH"

# Corregir en strings de URL
sed -i "s/'3001'/'4001'/g" "$DASHBOARD_PATH"
sed -i 's/"3001"/"4001"/g' "$DASHBOARD_PATH"
sed -i "s/'3002'/'4002'/g" "$DASHBOARD_PATH"
sed -i 's/"3002"/"4002"/g' "$DASHBOARD_PATH"
sed -i "s/'3003'/'4003'/g" "$DASHBOARD_PATH"
sed -i 's/"3003"/"4003"/g' "$DASHBOARD_PATH"
sed -i "s/'3004'/'4004'/g" "$DASHBOARD_PATH"
sed -i 's/"3004"/"4004"/g' "$DASHBOARD_PATH"

echo "✅ Correcciones aplicadas"
echo ""

# Verificar
echo "🔍 Verificando correcciones..."
echo ""
echo "Buscando '4000 + instanceNumber':"
grep -n "4000.*instanceNumber\|instanceNumber.*4000\|4000.*\+" "$DASHBOARD_PATH" | head -5
echo ""

echo "Buscando puertos 4001-4004:"
grep -n ":4001\|:4002\|:4003\|:4004" "$DASHBOARD_PATH" | head -10
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "🔄 Reiniciando dashboard..."
pm2 restart dashboard
sleep 3

echo ""
echo "✅ Dashboard reiniciado"
echo ""
echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com"
echo ""

