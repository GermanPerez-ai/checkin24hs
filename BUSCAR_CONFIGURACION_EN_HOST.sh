#!/bin/bash
# Buscar configuración de Traefik en el host

echo "=== 1. Buscar archivos de configuración de Traefik en el host ==="
find /etc/traefik /root -name "*traefik*" -o -name "*dashboard*" 2>/dev/null | head -10

echo ""
echo "=== 2. Ver volúmenes montados en Traefik ==="
docker inspect traefik.1.1qfkazdh5m0czg2hslan0ny0g --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'

echo ""
echo "=== 3. Buscar en directorios comunes de EasyPanel ==="
find /root /opt /var/lib -name "*easypanel*" -type d 2>/dev/null | head -5

echo ""
echo "=== 4. Ver si hay configuración en /etc/easypanel o similar ==="
ls -la /etc/easypanel 2>/dev/null || echo "No existe /etc/easypanel"
ls -la /root/.easypanel 2>/dev/null || echo "No existe /root/.easypanel"

echo ""
echo "=== 5. La configuración probablemente está en EasyPanel ==="
echo "Necesitamos acceder a EasyPanel para actualizar la configuración del dashboard"

