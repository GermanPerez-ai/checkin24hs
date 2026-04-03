#!/bin/bash
# Buscar configuración de archivo en Traefik

echo "=== 1. Buscar archivos de configuración de Traefik ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g find /etc/traefik /traefik -name "*.yml" -o -name "*.yaml" -o -name "*.toml" 2>/dev/null

echo ""
echo "=== 2. Ver configuración de Traefik ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g cat /etc/traefik/traefik.yml 2>/dev/null | head -50

echo ""
echo "=== 3. Buscar referencias a 'easypanel' o 'dashboard' en configuración ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g grep -r "easypanel\|dashboard" /etc/traefik /traefik 2>/dev/null | head -10

echo ""
echo "=== 4. Ver routers en Traefik ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard

echo ""
echo "=== 5. Si hay configuración de archivo, necesitamos eliminarla o actualizarla ==="

