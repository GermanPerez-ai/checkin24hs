#!/bin/bash
# Buscar y corregir configuración en /etc/easypanel/traefik

echo "=== 1. Ver contenido de /etc/easypanel/traefik ==="
ls -la /etc/easypanel/traefik 2>/dev/null

echo ""
echo "=== 2. Buscar archivos de configuración ==="
find /etc/easypanel/traefik -type f 2>/dev/null | head -10

echo ""
echo "=== 3. Buscar referencias a dashboard o easypanel:3000 ==="
grep -r "dashboard\|easypanel.*3000" /etc/easypanel/traefik 2>/dev/null | head -10

echo ""
echo "=== 4. Ver archivos de configuración dinámica ==="
ls -la /etc/easypanel/traefik/dynamic/ 2>/dev/null || echo "No existe directorio dynamic"
ls -la /etc/easypanel/traefik/*.yml 2>/dev/null
ls -la /etc/easypanel/traefik/*.yaml 2>/dev/null
ls -la /etc/easypanel/traefik/*.toml 2>/dev/null

