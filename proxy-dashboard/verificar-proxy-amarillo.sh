#!/bin/bash

# Script para verificar el estado del dashboard-proxy

echo "=== Estado del servicio dashboard-proxy ==="
docker service ps checkin24hs_dashboard-proxy --no-trunc | head -5

echo ""
echo "=== Logs recientes del proxy ==="
docker service logs checkin24hs_dashboard-proxy --tail 30

echo ""
echo "=== Contenedores del proxy ==="
docker ps | grep dashboard-proxy

echo ""
echo "=== Opciones ==="
echo "1. El dashboard funciona directamente, así que el proxy puede no ser necesario"
echo "2. Si quieres detener el proxy: docker service scale checkin24hs_dashboard-proxy=0"
echo "3. Si quieres arreglarlo, necesitamos ver los logs primero"
