#!/bin/bash
# Diagnóstico para error 404

echo "=== DIAGNÓSTICO 404 ==="
echo ""

echo "1️⃣ Verificando que los servicios están corriendo:"
docker service ls | grep whatsapp
echo ""

echo "2️⃣ Verificando configuración de dominios en EasyPanel (etiquetas Traefik):"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    DOMAIN="whatsapp${PORT: -1}.checkin24hs.com"
    
    echo "📋 $s:"
    echo "   Puerto esperado: $PORT"
    echo "   Dominio esperado: $DOMAIN"
    
    # Ver etiquetas Traefik
    docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | head -5 || echo "   ⚠️  No hay etiquetas Traefik (EasyPanel las gestiona)"
    echo ""
done

echo "3️⃣ Verificando si los servicios están escuchando:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    # Probar desde Traefik
    echo "   Probando desde Traefik:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ❌ No responde"
    
    # Verificar proceso
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER" ]; then
        echo "   Proceso Node.js:"
        docker exec $CONTAINER ps aux 2>/dev/null | grep "node whatsapp" | grep -v grep || echo "   ⚠️  No hay proceso"
        
        # Verificar puerto escuchando
        echo "   Puerto $PORT escuchando:"
        docker exec $CONTAINER netstat -tuln 2>/dev/null | grep ":$PORT " || docker exec $CONTAINER ss -tuln 2>/dev/null | grep ":$PORT " || echo "   ⚠️  No escucha en puerto $PORT"
    fi
    
    echo ""
done

echo "4️⃣ Verificando API de Traefik para ver routers configurados:"
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Routers de WhatsApp:"
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i whatsapp || echo "   No se encontraron routers de WhatsApp"
fi






