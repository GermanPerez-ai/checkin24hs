#!/bin/bash
# Ver y corregir configuración de Traefik

echo "=== 1. Ver configuración completa del dashboard ==="
grep -A 20 "checkin24hs_dashboard" /etc/easypanel/traefik/config/main.yaml

echo ""
echo "=== 2. Buscar servicio checkin24hs_dashboard-0 ==="
grep -A 10 "checkin24hs_dashboard-0" /etc/easypanel/traefik/config/main.yaml

echo ""
echo "=== 3. Ver toda la sección de servicios ==="
grep -A 5 "services:" /etc/easypanel/traefik/config/main.yaml | head -30

echo ""
echo "=== 4. Buscar 'easypanel:3000' ==="
grep -B 5 -A 5 "easypanel:3000" /etc/easypanel/traefik/config/main.yaml

