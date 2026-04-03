#!/bin/bash
# Verificar si el dashboard funciona directamente sin Traefik

echo "=========================================="
echo "🔍 Verificando acceso directo al dashboard"
echo "=========================================="
echo ""

# 1. Obtener IP del servidor
echo "1️⃣ Obteniendo IP del servidor..."
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
echo "IP del servidor: $SERVER_IP"
echo ""

# 2. Verificar puerto del dashboard
echo "2️⃣ Verificando puerto del dashboard..."
DASHBOARD_SERVICE="checkin24hs_dashboard"

# Ver puertos publicados
echo "Puertos publicados del servicio dashboard:"
docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}} {{end}}' 2>/dev/null

echo ""
echo "3️⃣ Verificando si el dashboard responde directamente..."
echo ""

# Intentar acceder directamente al puerto
DASHBOARD_PORT=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Endpoint.Ports}}{{if eq .TargetPort 3000}}{{.PublishedPort}}{{end}}{{end}}' 2>/dev/null)

if [ -z "$DASHBOARD_PORT" ]; then
    echo "⚠️  No se encontró puerto publicado para el dashboard"
    echo "   El dashboard puede estar solo accesible a través de Traefik"
    echo ""
    echo "   Verificando contenedores del dashboard..."
    DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
    if [ ! -z "$DASHBOARD_CONTAINER" ]; then
        echo "   Contenedor encontrado: $DASHBOARD_CONTAINER"
        echo "   Verificando puertos del contenedor:"
        docker port "$DASHBOARD_CONTAINER" 2>/dev/null || echo "   No hay puertos publicados directamente"
    fi
else
    echo "✅ Puerto encontrado: $DASHBOARD_PORT"
    echo ""
    echo "Probando acceso directo..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$DASHBOARD_PORT" --max-time 5)
    
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "304" ]; then
        echo "✅ El dashboard responde correctamente en el puerto $DASHBOARD_PORT"
        echo ""
        echo "Puedes acceder directamente a:"
        echo "  http://$SERVER_IP:$DASHBOARD_PORT"
        echo ""
        echo "O si el puerto está publicado externamente:"
        echo "  http://$SERVER_IP:$DASHBOARD_PORT"
    else
        echo "⚠️  El dashboard no responde en el puerto $DASHBOARD_PORT (código: $RESPONSE)"
    fi
fi

echo ""
echo "4️⃣ Verificando configuración de Traefik..."
echo ""

# Ver si Traefik puede acceder al dashboard
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "Verificando si Traefik puede resolver el servicio dashboard..."
    
    # Intentar hacer ping al servicio desde Traefik
    docker exec "$TRAEFIK_CONTAINER" ping -c 1 checkin24hs_dashboard 2>/dev/null && echo "✅ Traefik puede resolver el nombre del servicio" || echo "⚠️  Traefik no puede resolver el nombre del servicio"
    
    # Verificar si están en la misma red
    echo ""
    echo "Redes del dashboard:"
    docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}'
    
    echo ""
    echo "Redes de Traefik:"
    docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}'
fi

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Si el dashboard funciona directamente pero no a través de Traefik,"
echo "el problema está en la configuración de Traefik."
echo ""
echo "Si el dashboard NO funciona directamente, el problema está en el servicio mismo."
echo ""
