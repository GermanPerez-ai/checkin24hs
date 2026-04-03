#!/bin/bash
# Diagnóstico completo de Traefik y servicios WhatsApp

echo "=== DIAGNÓSTICO COMPLETO BAD GATEWAY ==="
echo ""

echo "1️⃣ Verificando que los servicios están corriendo:"
docker service ls | grep whatsapp
echo ""

echo "2️⃣ Verificando conectividad desde Traefik a los servicios:"
EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep easypanel | head -1 | awk '{print $1}')

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 Probando $s en puerto $PORT desde red easypanel:"
    docker run --rm --network $EASYPANEL_NET alpine/curl:latest curl -I --max-time 5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ❌ No se puede conectar"
    echo ""
done

echo "3️⃣ Verificando configuración de dominios en Docker (etiquetas Traefik):"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik || echo "   ⚠️  No hay etiquetas Traefik (EasyPanel las gestiona automáticamente)"
    echo ""
done

echo "4️⃣ Verificando logs de Traefik (errores recientes):"
docker service logs traefik --tail 100 2>&1 | grep -iE "whatsapp|502|bad|gateway|error|failed" | tail -30 || echo "   No se encontraron errores específicos"
echo ""

echo "5️⃣ Verificando si Traefik detecta los servicios:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Verificando API de Traefik:"
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i whatsapp || echo "   No se encontraron routers de WhatsApp en la API de Traefik"
fi

echo ""
echo "=== VERIFICANDO CONFIGURACIÓN DE RED ==="
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    NETWORKS=$(docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    for net_id in $NETWORKS; do
        NET_NAME=$(docker network inspect $net_id --format '{{.Name}}' 2>/dev/null)
        echo "   Red: $NET_NAME ($net_id)"
        if echo "$NET_NAME" | grep -q easypanel; then
            echo "   ✅ Está en easypanel"
        fi
    done
    echo ""
done






