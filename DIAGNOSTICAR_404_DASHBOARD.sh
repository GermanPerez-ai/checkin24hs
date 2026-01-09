#!/bin/bash

echo "🔍 DIAGNÓSTICO COMPLETO DEL DASHBOARD 404"
echo "=========================================="
echo ""

echo "1️⃣ Verificando servicios dashboard..."
docker service ls | grep -i dashboard
echo ""

echo "2️⃣ Verificando estado del servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | awk '{print $1}' | head -1)
if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
else
    echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
    docker service ps $DASHBOARD_SERVICE --no-trunc
    echo ""
    
    echo "3️⃣ Verificando labels de Traefik del servicio dashboard..."
    docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.Labels}}' | python3 -m json.tool | grep -i traefik
    echo ""
    
    echo "4️⃣ Verificando contenedores del servicio..."
    docker ps | grep -i dashboard
    echo ""
    
    echo "5️⃣ Verificando red del servicio..."
    docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'
    echo ""
    
    echo "6️⃣ Verificando si el contenedor responde en puerto 3000..."
    CONTAINER_IP=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Endpoint.VirtualIPs}}{{.Addr}}{{end}}' | cut -d'/' -f1)
    if [ ! -z "$CONTAINER_IP" ]; then
        echo "IP del servicio: $CONTAINER_IP"
        echo "Probando conexión..."
        curl -I http://$CONTAINER_IP:3000 2>&1 | head -5
    fi
    echo ""
fi

echo "7️⃣ Verificando configuración de Traefik..."
docker service ls | grep -i traefik
echo ""

echo "8️⃣ Verificando logs recientes de Traefik (últimas 20 líneas)..."
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    docker service logs $TRAEFIK_SERVICE --tail 20 2>&1 | grep -i dashboard || echo "No hay logs relacionados con dashboard"
fi
echo ""

echo "9️⃣ Verificando si hay algún proxy intermedio..."
docker service ls | grep -i proxy
echo ""

echo "🔟 Verificando dominio en labels de Traefik..."
if [ ! -z "$DASHBOARD_SERVICE" ]; then
    docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if or (contains $key "traefik") (contains $key "domain") (contains $key "host")}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}'
fi
echo ""

echo "✅ Diagnóstico completo"
