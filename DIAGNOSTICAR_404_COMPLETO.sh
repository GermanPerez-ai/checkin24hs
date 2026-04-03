#!/bin/bash
# Diagnosticar completamente el error 404

echo "=========================================="
echo "🔍 Diagnóstico completo del error 404"
echo "=========================================="
echo ""

echo "1️⃣ Verificando estado del servicio dashboard..."
docker service ps checkin24hs_dashboard --no-trunc | head -3

echo ""
echo "2️⃣ Verificando contenedores del dashboard..."
docker ps --filter "name=dashboard" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

echo ""
echo "3️⃣ Verificando si el servidor está respondiendo directamente..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Contenedor: $DASHBOARD_CONTAINER"
    echo ""
    echo "Probando acceso a la ruta raíz desde dentro del contenedor..."
    docker exec "$DASHBOARD_CONTAINER" node -e "
    const http = require('http');
    http.get('http://127.0.0.1:3000/', {family: 4}, (res) => {
        console.log('Status raíz:', res.statusCode);
        if (res.statusCode === 200) {
            console.log('✅ El servidor responde correctamente');
        } else {
            console.log('❌ El servidor no responde correctamente');
        }
        process.exit(res.statusCode === 200 ? 0 : 1);
    }).on('error', (err) => {
        console.error('Error:', err.message);
        process.exit(1);
    });
    " 2>&1
    
    echo ""
    echo "Probando acceso a /api/version desde dentro del contenedor..."
    docker exec "$DASHBOARD_CONTAINER" node -e "
    const http = require('http');
    http.get('http://127.0.0.1:3000/api/version', {family: 4}, (res) => {
        console.log('Status /api/version:', res.statusCode);
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
            if (res.statusCode === 200) {
                console.log('✅ Endpoint funciona:', data.substring(0, 50));
            } else {
                console.log('❌ Endpoint no funciona');
            }
        });
    }).on('error', (err) => {
        console.error('Error:', err.message);
    });
    " 2>&1
fi

echo ""
echo "4️⃣ Verificando configuración de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "Logs recientes de Traefik (últimas 20 líneas):"
    docker service logs traefik --tail 20 | tail -10
fi

echo ""
echo "5️⃣ Verificando etiquetas Traefik del dashboard..."
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "No hay etiquetas Traefik"

echo ""
echo "6️⃣ Verificando logs del dashboard..."
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Últimas 10 líneas de logs:"
    docker logs "$DASHBOARD_CONTAINER" --tail 10
fi

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Si el servidor responde directamente pero no a través de Traefik,"
echo "el problema está en la configuración de Traefik."
echo ""
echo "Si el servidor NO responde directamente, el problema está en el servidor."
echo ""
