#!/bin/bash

echo "=== Verificar DNS del CRM ==="

# 1. Verificar resolución DNS
echo ""
echo "1. Resolución DNS de crm.checkin24hs.com:"
nslookup crm.checkin24hs.com 2>&1 | grep -A 5 "Name:"

# 2. Obtener IP del servidor
echo ""
echo "2. IP del servidor:"
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
echo "IP pública: $SERVER_IP"

# 3. Verificar si el DNS apunta al servidor correcto
echo ""
echo "3. Verificando si el DNS apunta al servidor:"
DNS_IP=$(nslookup crm.checkin24hs.com 2>&1 | grep -A 2 "Name:" | grep "Address:" | tail -1 | awk '{print $2}')
if [ ! -z "$DNS_IP" ]; then
    echo "DNS resuelve a: $DNS_IP"
    echo "Servidor está en: $SERVER_IP"
    if [ "$DNS_IP" = "$SERVER_IP" ]; then
        echo "✅ DNS configurado correctamente"
    else
        echo "⚠️  DNS no apunta al servidor correcto"
        echo "   Necesitas agregar un registro A en tu DNS:"
        echo "   Tipo: A"
        echo "   Nombre: crm"
        echo "   Valor: $SERVER_IP"
    fi
else
    echo "⚠️  No se pudo resolver el DNS"
    echo "   Necesitas agregar un registro A en tu DNS:"
    echo "   Tipo: A"
    echo "   Nombre: crm"
    echo "   Valor: $SERVER_IP"
fi

# 4. Probar conexión directa al puerto
echo ""
echo "4. Probando conexión al puerto 3005:"
timeout 3 bash -c "echo > /dev/tcp/localhost/3005" 2>/dev/null && echo "✅ Puerto 3005 está abierto" || echo "⚠️  Puerto 3005 no está accesible"

echo ""
echo "=== Verificación completada ==="






