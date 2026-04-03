#!/bin/bash
# Diagnóstico final completo

echo "=== DIAGNÓSTICO FINAL WHATSAPP ==="
echo ""

echo "1️⃣ Verificando si los servicios están escuchando en los puertos correctos:"
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (debería estar en puerto $PORT):"
    
    # Obtener ID del contenedor
    CONTAINER_ID=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "   Contenedor ID: $CONTAINER_ID"
        
        # Verificar qué puertos está escuchando el contenedor
        echo "   Puertos en uso dentro del contenedor:"
        docker exec $CONTAINER_ID netstat -tuln 2>/dev/null | grep LISTEN || docker exec $CONTAINER_ID ss -tuln 2>/dev/null | grep LISTEN || echo "   No se pudo verificar puertos"
        
        # Probar conectividad directa al contenedor
        echo "   Probando conexión directa al contenedor en puerto $PORT:"
        docker exec $CONTAINER_ID wget -qO- --timeout=3 http://localhost:$PORT 2>&1 | head -3 || echo "   ❌ No responde en puerto $PORT"
    else
        echo "   ❌ No se encontró contenedor activo"
    fi
    
    echo ""
done

echo "2️⃣ Verificando configuración de dominios en Docker:"
echo ""

for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s:"
    echo "   Puerto esperado: $PORT"
    
    # Verificar puerto publicado
    PUBLISHED_PORT=$(docker service inspect $s --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
    TARGET_PORT=$(docker service inspect $s --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null)
    
    echo "   Puerto publicado: $PUBLISHED_PORT"
    echo "   Puerto objetivo: $TARGET_PORT"
    
    # Verificar si Traefik puede conectarse
    echo "   Probando desde red easypanel:"
    docker run --rm --network easypanel alpine/curl:latest curl -I --max-time 5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ❌ No se puede conectar"
    
    echo ""
done

echo "3️⃣ Verificando logs recientes de whatsapp4:"
docker service logs checkin24hs_whatsapp4 --tail 20 2>&1 | tail -10
echo ""

echo "4️⃣ Verificando logs de Traefik relacionados con whatsapp:"
docker service logs traefik --tail 100 2>&1 | grep -iE "whatsapp|502|bad|gateway" | tail -15 || echo "   No se encontraron errores específicos"
echo ""

echo "=== FIN DEL DIAGNÓSTICO ==="






