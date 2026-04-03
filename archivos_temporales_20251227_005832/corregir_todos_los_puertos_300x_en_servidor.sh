#!/bin/bash
# Script para corregir TODAS las referencias a puertos 3001-3004 en el dashboard del servidor

DASHBOARD_PATH="~/checkin24hs/dashboard.html"

echo "🔧 Corrigiendo TODAS las referencias a puertos 3001-3004..."

# 1. Corregir cálculos de puerto: 3001 + (instanceNumber - 1) → 4001 + (instanceNumber - 1)
ssh root@72.61.58.240 "cd ~/checkin24hs && \
cp dashboard.html dashboard.html.backup_antes_corregir_puertos && \
sed -i 's/3001 + (instanceNumber - 1)/4001 + (instanceNumber - 1)/g' dashboard.html && \
sed -i 's/3001+(instanceNumber-1)/4001+(instanceNumber-1)/g' dashboard.html && \
echo '✅ Cálculos de puerto corregidos'"

# 2. Corregir valores por defecto en URLs
ssh root@72.61.58.240 "cd ~/checkin24hs && \
sed -i \"s|'http://72.61.58.240:3001'|'http://72.61.58.240:4001'|g\" dashboard.html && \
sed -i 's|\"http://72.61.58.240:3001\"|\"http://72.61.58.240:4001\"|g' dashboard.html && \
sed -i 's|http://72.61.58.240:3001|http://72.61.58.240:4001|g' dashboard.html && \
sed -i 's|http://localhost:3001|http://localhost:4001|g' dashboard.html && \
echo '✅ URLs por defecto corregidas'"

# 3. Corregir puertos en atributos HTML (value="...")
ssh root@72.61.58.240 "cd ~/checkin24hs && \
sed -i 's|value=\"http://72.61.58.240:3001\"|value=\"http://72.61.58.240:4001\"|g' dashboard.html && \
sed -i 's|placeholder=\"http://tu-servidor:3001\"|placeholder=\"http://tu-servidor:4001\"|g' dashboard.html && \
echo '✅ Atributos HTML corregidos'"

# 4. Corregir cualquier referencia restante a puertos 3001-3004
ssh root@72.61.58.240 "cd ~/checkin24hs && \
sed -i 's/:3001/:4001/g' dashboard.html && \
sed -i 's/:3002/:4002/g' dashboard.html && \
sed -i 's/:3003/:4003/g' dashboard.html && \
sed -i 's/:3004/:4004/g' dashboard.html && \
echo '✅ Referencias restantes corregidas'"

# 5. Reiniciar dashboard
ssh root@72.61.58.240 "cd ~/checkin24hs && \
pm2 restart dashboard && \
echo '✅ Dashboard reiniciado'"

echo ""
echo "✅✅✅ CORRECCIÓN COMPLETA ✅✅✅"
echo ""
echo "Verificando que no queden referencias a puertos 3001-3004..."
ssh root@72.61.58.240 "cd ~/checkin24hs && grep -n '3001\|3002\|3003\|3004' dashboard.html | head -10 || echo '✅ No se encontraron más referencias a puertos 3001-3004'"

