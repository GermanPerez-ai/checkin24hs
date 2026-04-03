#!/bin/bash
# Obtener IP pública IPv4 de forma simple

cd /root/checkin24hs

echo "🔍 Obteniendo IP pública IPv4..."
echo ""

# Intentar múltiples servicios para obtener IPv4
IPV4=""

# Método 1: ifconfig.me
echo "Intentando método 1..."
IPV4=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null)
if [ ! -z "$IPV4" ] && [[ $IPV4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "✅ IP obtenida: $IPV4"
else
    echo "❌ Método 1 falló"
    IPV4=""
fi

# Método 2: icanhazip.com
if [ -z "$IPV4" ]; then
    echo "Intentando método 2..."
    IPV4=$(curl -s -4 --max-time 5 icanhazip.com 2>/dev/null)
    if [ ! -z "$IPV4" ] && [[ $IPV4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "✅ IP obtenida: $IPV4"
    else
        echo "❌ Método 2 falló"
        IPV4=""
    fi
fi

# Método 3: ipv4.icanhazip.com
if [ -z "$IPV4" ]; then
    echo "Intentando método 3..."
    IPV4=$(curl -s -4 --max-time 5 ipv4.icanhazip.com 2>/dev/null)
    if [ ! -z "$IPV4" ] && [[ $IPV4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "✅ IP obtenida: $IPV4"
    else
        echo "❌ Método 3 falló"
        IPV4=""
    fi
fi

# Método 4: ipinfo.io
if [ -z "$IPV4" ]; then
    echo "Intentando método 4..."
    IPV4=$(curl -s -4 --max-time 5 ipinfo.io/ip 2>/dev/null)
    if [ ! -z "$IPV4" ] && [[ $IPV4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "✅ IP obtenida: $IPV4"
    else
        echo "❌ Método 4 falló"
        IPV4=""
    fi
fi

# Método 5: Verificar IPs de las interfaces de red
if [ -z "$IPV4" ]; then
    echo "Intentando método 5 (interfaces locales)..."
    IPV4=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    if [ ! -z "$IPV4" ] && [[ $IPV4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "✅ IP local encontrada: $IPV4"
        echo "⚠️  Esta es una IP local, puede no ser accesible desde internet"
    else
        echo "❌ Método 5 falló"
        IPV4=""
    fi
fi

echo ""
echo "=============================================================="
echo "📊 RESULTADO"
echo "=============================================================="
echo ""

if [ ! -z "$IPV4" ]; then
    echo "✅ IP PÚBLICA IPv4: $IPV4"
    echo ""
    echo "🌐 URL PARA ACCEDER:"
    echo "   http://$IPV4:3001"
    echo ""
    echo "📋 Copia esta URL y ábrela en tu navegador:"
    echo "   http://$IPV4:3001"
    echo ""
    
    # Verificar que el puerto esté publicado
    echo "🔍 Verificando que el puerto 3001 esté publicado..."
    PORT_CHECK=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
    if [[ "$PORT_CHECK" == *"3001"* ]]; then
        echo "   ✅ Puerto 3001 está publicado"
    else
        echo "   ⚠️  Puerto 3001 NO está publicado"
        echo "   🔧 Publicando puerto..."
        docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
        echo "   ✅ Puerto publicado"
    fi
else
    echo "❌ No se pudo obtener IP pública IPv4"
    echo ""
    echo "💡 Soluciones:"
    echo "   1. Verifica tu conexión a internet"
    echo "   2. Verifica el firewall del servidor"
    echo "   3. Contacta a tu proveedor de hosting para obtener la IP pública"
fi
