#!/bin/bash
# Corregir configuración de Traefik para que apunte al puerto 3000

HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Host IP: $HOST_IP"

echo ""
echo "=== 1. Hacer backup de la configuración ==="
cp /etc/easypanel/traefik/config/main.yaml /etc/easypanel/traefik/config/main.yaml.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"

echo ""
echo "=== 2. Actualizar configuración para que apunte a $HOST_IP:3000 ==="
# Reemplazar la URL del servicio checkin24hs_dashboard-1
sed -i 's|"url": "http://checkin24hs_dashboard:80/"|"url": "http://'$HOST_IP':3000"|g' /etc/easypanel/traefik/config/main.yaml

echo "✅ Configuración actualizada"

echo ""
echo "=== 3. Verificar el cambio ==="
grep -A 5 "checkin24hs_dashboard-1" /etc/easypanel/traefik/config/main.yaml | grep -A 3 "loadBalancer"

echo ""
echo "=== 4. Reiniciar Traefik para aplicar cambios ==="
docker service update --force traefik

echo ""
echo "=== 5. Esperar 10 segundos ==="
sleep 10

echo ""
echo "=== 6. Probar acceso al dashboard ==="
curl -I https://dashboard.checkin24hs.com 2>&1 | head -10

