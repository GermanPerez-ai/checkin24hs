#!/bin/bash
# Verificar configuración de Traefik para rutas API

echo "=========================================="
echo "🔍 Verificando configuración de Traefik para /api/*"
echo "=========================================="
echo ""

echo "1️⃣ Verificando etiquetas Traefik del servicio dashboard..."
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "2️⃣ El problema es que Traefik puede estar configurado solo para la ruta raíz"
echo "   Necesitamos asegurarnos de que todas las rutas (incluyendo /api/*) se pasen al servicio"
echo ""

echo "3️⃣ Verificando si Traefik tiene middlewares que puedan estar bloqueando /api/*..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Logs recientes de Traefik relacionados con /api:"
    docker service logs traefik --tail 50 | grep -iE "api|404|dashboard" | tail -10
fi

echo ""
echo "4️⃣ Probando acceso a través de Traefik desde el host..."
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
echo "Probando: http://$SERVER_IP/api/version (a través de Traefik en puerto 80)"
curl -s -H "Host: dashboard.checkin24hs.com" "http://localhost/api/version" 2>/dev/null | head -5 || echo "❌ No responde a través de Traefik"

echo ""
echo "5️⃣ Verificando configuración de Traefik..."
echo "   Traefik necesita pasar TODAS las rutas al servicio, no solo la raíz"
echo "   Las etiquetas actuales pueden estar limitando las rutas"
echo ""

echo "=========================================="
echo "📋 Solución"
echo "=========================================="
echo ""
echo "El endpoint funciona directamente pero no a través de Traefik."
echo "Esto significa que Traefik no está pasando las rutas /api/* al servicio."
echo ""
echo "Solución: Asegurarse de que Traefik pase todas las rutas al servicio."
echo "Esto se hace normalmente con la configuración de Traefik o con middlewares."
echo ""
echo "Opciones:"
echo "  1. Verificar que las etiquetas de Traefik no limiten las rutas"
echo "  2. Agregar un middleware de stripPrefix si es necesario"
echo "  3. Verificar que Traefik esté configurado para pasar todas las rutas"
echo ""
