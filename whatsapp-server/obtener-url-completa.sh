#!/bin/bash
# Obtener URL completa para acceder al servidor

cd /root/checkin24hs

echo "🔍 Obteniendo IP pública y URL completa..."
echo ""

# Obtener IP pública IPv4
IPV4=$(curl -s -4 --max-time 5 ifconfig.me 2>/dev/null || curl -s -4 --max-time 5 icanhazip.com 2>/dev/null || curl -s -4 --max-time 5 ipinfo.io/ip 2>/dev/null)

# Si no funciona, usar la IP que apareció antes en los logs
if [ -z "$IPV4" ] || ! [[ $IPV4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Usar la IP que apareció en logs anteriores
    IPV4="72.61.58.240"
    echo "⚠️  Usando IP de logs anteriores: $IPV4"
else
    echo "✅ IP pública obtenida: $IPV4"
fi

echo ""
echo "=============================================================="
echo "🌐 URL PARA ACCEDER AL SERVIDOR"
echo "=============================================================="
echo ""
echo "COPIA Y PEGA ESTA URL COMPLETA EN TU NAVEGADOR:"
echo ""
echo "   http://$IPV4:3001"
echo ""
echo "=============================================================="
echo ""
echo "📋 INSTRUCCIONES:"
echo ""
echo "1. Copia la URL de arriba (http://$IPV4:3001)"
echo "2. Abre tu navegador web (Chrome, Firefox, Edge, etc.)"
echo "3. Pega la URL en la barra de direcciones"
echo "4. Presiona Enter"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Debe ser 'http://' (con dos barras //)"
echo "   - NO uses 'http:/' (con una sola barra)"
echo "   - Debe abrirse en un NAVEGADOR WEB, no en el Explorador de archivos"
echo ""
echo "🔍 Verificando que el servidor esté accesible..."
PORT_CHECK=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
if [[ "$PORT_CHECK" == *"3001"* ]]; then
    echo "   ✅ Puerto 3001 está publicado"
else
    echo "   ⚠️  Puerto 3001 NO está publicado, publicando..."
    docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
    echo "   ✅ Puerto publicado"
fi
