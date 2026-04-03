#!/bin/bash
# Obtener URL/IP pública para acceder al servidor

cd /root/checkin24hs

echo "🔍 Buscando URL/IP pública para acceder al servidor..."
echo ""

# 1. IP pública IPv4
echo "1️⃣  IP pública IPv4:"
IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || curl -s -4 ipv4.icanhazip.com 2>/dev/null)
if [ ! -z "$IPV4" ]; then
    echo "   ✅ IPv4: $IPV4"
    echo "   🌐 URL: http://$IPV4:3001"
else
    echo "   ❌ No se pudo obtener IPv4"
fi
echo ""

# 2. IP pública IPv6
echo "2️⃣  IP pública IPv6:"
IPV6=$(curl -s -6 ifconfig.me 2>/dev/null || curl -s -6 icanhazip.com 2>/dev/null)
if [ ! -z "$IPV6" ]; then
    echo "   ✅ IPv6: $IPV6"
    echo "   🌐 URL: http://[$IPV6]:3001"
else
    echo "   ❌ No se pudo obtener IPv6"
fi
echo ""

# 3. Verificar Traefik y dominios configurados
echo "3️⃣  Verificando Traefik y dominios:"
TRAEFIK_CONTAINER=$(docker ps -q -f name=traefik | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "   ✅ Traefik encontrado"
    
    # Obtener routers de Traefik
    ROUTERS=$(docker exec "$TRAEFIK_CONTAINER" curl -s http://localhost:8080/api/http/routers 2>/dev/null)
    if [ ! -z "$ROUTERS" ]; then
        echo "   📋 Rutas configuradas:"
        echo "$ROUTERS" | grep -o '"rule":"[^"]*"' | sed 's/"rule":"Host(\([^)]*\))"/      - \1/' | head -10
    fi
    
    # Buscar específicamente checkin24hs
    CHECKIN_ROUTES=$(echo "$ROUTERS" | grep -i "checkin24hs" | grep -o '"rule":"[^"]*"' | sed 's/"rule":"Host(\([^)]*\))"/      - \1/')
    if [ ! -z "$CHECKIN_ROUTES" ]; then
        echo ""
        echo "   🎯 Rutas de checkin24hs encontradas:"
        echo "$CHECKIN_ROUTES"
    fi
else
    echo "   ⚠️  Traefik no encontrado"
fi
echo ""

# 4. Verificar variables de entorno del servicio
echo "4️⃣  Verificando configuración del servicio:"
BASE_URL=$(docker service inspect checkin24hs_whatsapp --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep -i "BASE_URL\|DOMAIN\|URL" | head -5)
if [ ! -z "$BASE_URL" ]; then
    echo "   📋 Variables de entorno relacionadas con URL:"
    echo "$BASE_URL"
else
    echo "   ⚠️  No se encontraron variables de entorno de URL"
fi
echo ""

# 5. Resumen
echo "=============================================================="
echo "📊 RESUMEN - URLs PARA ACCEDER"
echo "=============================================================="
echo ""

if [ ! -z "$IPV4" ]; then
    echo "✅ URL PRINCIPAL (IPv4):"
    echo "   http://$IPV4:3001"
    echo ""
fi

if [ ! -z "$IPV6" ]; then
    echo "✅ URL ALTERNATIVA (IPv6):"
    echo "   http://[$IPV6]:3001"
    echo ""
fi

if [ ! -z "$CHECKIN_ROUTES" ]; then
    echo "✅ URLs CON DOMINIO (si Traefik está configurado):"
    echo "$CHECKIN_ROUTES" | while read domain; do
        if [ ! -z "$domain" ]; then
            echo "   http://$domain"
        fi
    done
    echo ""
fi

echo "💡 Si ninguna URL funciona, verifica:"
echo "   1. Firewall del servidor (puerto 3001 debe estar abierto)"
echo "   2. Configuración de red del proveedor"
echo "   3. Si usas Traefik, verifica que esté configurado correctamente"
