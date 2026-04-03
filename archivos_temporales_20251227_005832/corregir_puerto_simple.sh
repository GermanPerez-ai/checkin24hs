#!/bin/bash
cd ~/checkin24hs
cp dashboard.html dashboard.html.backup_$(date +%Y%m%d_%H%M%S)

# Corregir el cálculo específico que encontramos
sed -i 's/3001 + (instanceNumber - 1)/4001 + (instanceNumber - 1)/g' dashboard.html
sed -i 's/3001+(instanceNumber-1)/4001+(instanceNumber-1)/g' dashboard.html
sed -i 's/3000 + instanceNumber/4000 + instanceNumber/g' dashboard.html

# Corregir cualquier puerto 3001-3004 que quede
sed -i 's/:3001/:4001/g' dashboard.html
sed -i 's/:3002/:4002/g' dashboard.html
sed -i 's/:3003/:4003/g' dashboard.html
sed -i 's/:3004/:4004/g' dashboard.html

pm2 restart dashboard
echo "✅ Corrección aplicada y dashboard reiniciado"

