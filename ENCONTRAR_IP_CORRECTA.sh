#!/bin/bash
# Encontrar la IP correcta para acceder al host desde el contenedor

echo "=== 1. Ver IPs de la red Docker ==="
docker network inspect easypanel --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'

echo ""
echo "=== 2. Ver IP del host en la red Docker ==="
# Obtener la IP del host en la red Docker
HOST_IP_IN_DOCKER=$(docker network inspect easypanel --format '{{range .Containers}}{{.IPv4Address}}{{end}}' | grep -v "^$" | head -1 | cut -d/ -f1)
echo "Host IP en Docker: $HOST_IP_IN_DOCKER"

echo ""
echo "=== 3. Ver IPs de las interfaces del host ==="
ip addr show | grep "inet " | grep -v "127.0.0.1"

echo ""
echo "=== 4. Probar diferentes IPs ==="
# Probar con diferentes IPs
for IP in "10.11.0.1" "$HOST_IP_IN_DOCKER" "172.17.0.1" "host.docker.internal"; do
    echo -n "Probando $IP:3000... "
    docker exec dashboard-nginx-proxy wget -qO- --timeout=2 http://$IP:3000 2>&1 | head -1 && echo "✅ FUNCIONA" && CORRECT_IP=$IP && break || echo "❌"
done

echo ""
echo "=== 5. Si ninguna funciona, usar network host ==="
echo "O verificar firewall"

