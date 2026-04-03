#!/bin/bash
# Script para verificar dónde está corriendo EasyPanel

echo "=========================================="
echo "VERIFICAR DÓNDE ESTÁ CORRIENDO EASYPANEL"
echo "=========================================="
echo ""

# Verificar contenedores de Docker
echo "1. Contenedores de Docker relacionados con EasyPanel:"
docker ps | grep -i easypanel || echo "No se encontraron contenedores con 'easypanel'"
echo ""

# Verificar todos los contenedores
echo "2. Todos los contenedores de Docker:"
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}"
echo ""

# Verificar qué está escuchando en puerto 3000
echo "3. Qué está escuchando en puerto 3000:"
sudo lsof -i :3000 2>/dev/null || netstat -tulpn | grep :3000
echo ""

# Verificar qué está escuchando en puerto 3006
echo "4. Qué está escuchando en puerto 3006:"
sudo lsof -i :3006 2>/dev/null || netstat -tulpn | grep :3006
echo ""

# Verificar servicios de Docker Swarm
echo "5. Servicios de Docker Swarm:"
docker service ls 2>/dev/null | grep -i easypanel || echo "No se encontraron servicios con 'easypanel'"
echo ""

# Verificar procesos node que puedan ser EasyPanel
echo "6. Procesos Node.js corriendo:"
ps aux | grep -i node | grep -v grep | head -5
echo ""

# Verificar configuración actual de nginx
echo "7. Configuración actual de nginx para puerto 3006:"
cat /etc/nginx/sites-available/easypanel-3006
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Revisa los resultados arriba para identificar:"
echo "  - Dónde está corriendo EasyPanel realmente"
echo "  - En qué puerto está escuchando"
echo ""
