#!/bin/bash
# Script para verificar la configuración actual de EasyPanel

echo "=========================================="
echo "VERIFICACIÓN DE CONFIGURACIÓN EASYPANEL"
echo "=========================================="
echo ""

# 1. Ver servicios de EasyPanel corriendo
echo "1. Servicios Docker de EasyPanel:"
docker ps | grep -E "easypanel|dashboard|checkin24hs"
echo ""

# 2. Ver configuración de servicios
echo "2. Servicios en EasyPanel:"
docker exec easypanel ls -la /app/data/services 2>/dev/null || echo "No se puede acceder a los datos de servicios"
echo ""

# 3. Ver puertos en uso
echo "3. Puertos en uso:"
sudo lsof -i :3000
sudo lsof -i :3001
sudo lsof -i :3002
echo ""

# 4. Ver logs de EasyPanel
echo "4. Últimos logs de EasyPanel:"
docker logs easypanel --tail 20 2>/dev/null
echo ""

# 5. Ver configuración de Traefik (proxy de EasyPanel)
echo "5. Configuración de Traefik:"
docker exec traefik cat /etc/traefik/traefik.yml 2>/dev/null | head -30 || echo "No se puede acceder a la configuración de Traefik"
echo ""

# 6. Ver servicios de Docker Swarm (si EasyPanel los usa)
echo "6. Servicios de Docker Swarm:"
docker service ls 2>/dev/null || echo "Docker Swarm no está activo o no hay servicios"
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="


