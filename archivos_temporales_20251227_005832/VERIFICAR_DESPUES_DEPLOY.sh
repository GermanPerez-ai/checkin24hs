#!/bin/bash
echo "=== VERIFICACIÓN DESPUÉS DEL DEPLOY ==="
echo ""

echo "1️⃣ Estado de los servicios:"
docker service ls | grep whatsapp
echo ""

echo "2️⃣ Esperando 30 segundos para que los servicios inicien completamente..."
sleep 30
echo ""

echo "3️⃣ Verificando que los servicios escuchan en 0.0.0.0:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    
    echo "📋 $s (puerto $PORT):"
    
    CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
    
    if [ ! -z "$CONTAINER" ]; then
        # Verificar si tiene el fix
        CURRENT=$(docker exec $CONTAINER grep "server.listen" /app/whatsapp-server.js 2>/dev/null | head -1)
        if echo "$CURRENT" | grep -q "0.0.0.0"; then
            echo "   ✅ Tiene fix 0.0.0.0"
        else
            echo "   ❌ NO tiene fix - aplicando manualmente..."
            docker exec $CONTAINER sed -i "s/server.listen(CONFIG.PORT, async/server.listen(CONFIG.PORT, '0.0.0.0', async/g" /app/whatsapp-server.js 2>/dev/null
            docker exec $CONTAINER pkill -f "node whatsapp-server.js" 2>/dev/null || true
            sleep 5
        fi
        
        # Verificar puertos escuchando
        LISTENING=$(docker exec $CONTAINER netstat -tuln 2>/dev/null | grep ":$PORT " || docker exec $CONTAINER ss -tuln 2>/dev/null | grep ":$PORT ")
        if [ ! -z "$LISTENING" ]; then
            echo "   ✅ Escuchando en puerto $PORT"
            echo "   $LISTENING"
        else
            echo "   ⚠️  No escucha en puerto $PORT"
        fi
        
        # Verificar logs recientes
        echo "   Logs (últimas 3 líneas):"
        docker service logs $s --tail 3 2>&1 | tail -3 | sed 's/^/      /'
    else
        echo "   ⚠️  Sin contenedor activo"
    fi
    echo ""
done

echo "4️⃣ Verificando conectividad desde Traefik:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
EASYPANEL_NET=$(docker network ls --format "{{.ID}}\t{{.Name}}" | grep "^easypanel$" | awk '{print $1}')

if [ ! -z "$TRAEFIK_CONTAINER" ] && [ ! -z "$EASYPANEL_NET" ]; then
    for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
        PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
        PORT=$((PORT + 3000))
        
        CONTAINER=$(docker ps --filter "name=$s" --format "{{.ID}}" | head -1)
        if [ ! -z "$CONTAINER" ]; then
            CONTAINER_IP=$(docker inspect $CONTAINER --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$EASYPANEL_NET\"}}{{.IPAddress}}{{end}}{{end}}" 2>/dev/null)
            
            if [ ! -z "$CONTAINER_IP" ] && [ "$CONTAINER_IP" != "<no value>" ]; then
                echo "📋 $s (IP: $CONTAINER_IP, Puerto: $PORT):"
                RESPONSE=$(docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://$CONTAINER_IP:$PORT 2>&1 | head -1)
                if [ ! -z "$RESPONSE" ] && [ "$RESPONSE" != "wget: can't connect" ]; then
                    echo "   ✅ Traefik puede conectarse"
                else
                    echo "   ❌ Traefik NO puede conectarse"
                fi
            fi
        fi
    done
else
    echo "   ⚠️  No se encontró Traefik o red easypanel"
fi

echo ""
echo "5️⃣ Verificando dominios (desde el servidor):"
for i in 1 2 3 4; do
    echo "📋 whatsapp$i.checkin24hs.com:"
    curl -I --max-time 5 https://whatsapp$i.checkin24hs.com 2>&1 | head -3 || echo "   ⚠️  No responde"
    echo ""
done

echo "=== VERIFICACIÓN COMPLETADA ==="






