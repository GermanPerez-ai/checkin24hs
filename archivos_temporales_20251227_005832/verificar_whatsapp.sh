#!/bin/bash

echo "=== Verificar qué está usando el puerto 3001 ==="
lsof -i :3001 2>/dev/null || netstat -tulpn 2>/dev/null | grep ':3001 ' || ss -tulpn 2>/dev/null | grep ':3001 '

echo ""
echo "=== Estado actual de PM2 ==="
pm2 list

echo ""
echo "=== Verificar puertos activos ==="
for port in 3001 3002 3003 3004; do
    echo -n "Puerto $port: "
    if netstat -tulpn 2>/dev/null | grep -q ":$port " || ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo "✅ Activo"
        netstat -tulpn 2>/dev/null | grep ":$port " || ss -tulpn 2>/dev/null | grep ":$port "
    else
        echo "❌ Inactivo"
    fi
done

echo ""
echo "=== Probar acceso a los servicios ==="
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "IP del servidor: $HOST_IP"
echo ""

for port in 3001 3002 3003 3004; do
    echo -n "Probando puerto $port... "
    if curl -s --max-time 3 "http://$HOST_IP:$port/api/status" > /dev/null 2>&1; then
        echo "✅ Funciona"
        curl -s "http://$HOST_IP:$port/api/status" | head -3
    else
        echo "❌ No responde"
    fi
    echo ""
done

