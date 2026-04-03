#!/bin/bash
# Corregir proxy del dashboard

echo "=== 1. Obtener IP correcta del host ==="
# Obtener IP del gateway de la red Docker
GATEWAY_IP=$(docker network inspect easypanel --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null)
echo "Gateway IP: $GATEWAY_IP"

# Obtener IP de la interfaz del host
HOST_IP=$(ip route | grep default | awk '{print $3}' | head -1)
echo "Host IP (default route): $HOST_IP"

# Obtener IP de eth0
ETH0_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "ETH0 IP: $ETH0_IP"

echo ""
echo "=== 2. Probar acceso al puerto 3000 desde el contenedor ==="
for IP in "$GATEWAY_IP" "$HOST_IP" "$ETH0_IP" "172.17.0.1"; do
    echo "Probando $IP:3000..."
    docker exec dashboard-nginx-proxy wget -qO- --timeout=2 http://$IP:3000 2>/dev/null | head -3 && echo "✅ Funciona con $IP" && break || echo "❌ No funciona con $IP"
done

echo ""
echo "=== 3. Si ninguna funciona, usar network host ==="
echo "O recrear el contenedor con network host"

