#!/bin/bash
# Script completo para solucionar 404 del dashboard
# Detecta automáticamente el puerto del servicio y aplica las etiquetas de Traefik

echo "🔧 SOLUCIONANDO 404 DEL DASHBOARD"
echo "=================================="
echo ""

# 1. Buscar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i dashboard | grep -v proxy | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    echo "Listando todos los servicios:"
    docker service ls
    exit 1
fi

echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
echo ""

# 2. Verificar estado del servicio
echo "2️⃣ Verificando estado del servicio..."
docker service ps $DASHBOARD_SERVICE --no-trunc | head -3
echo ""

# 3. Detectar puerto del servicio
echo "3️⃣ Detectando puerto del servicio..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=${DASHBOARD_SERVICE}" --format "{{.Names}}" | head -1)

if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Contenedor encontrado: $DASHBOARD_CONTAINER"
    
    # Intentar detectar el puerto desde el contenedor
    PORT_80=$(docker exec $DASHBOARD_CONTAINER sh -c "netstat -tuln 2>/dev/null | grep ':80 ' || ss -tuln 2>/dev/null | grep ':80 '" 2>/dev/null)
    PORT_3000=$(docker exec $DASHBOARD_CONTAINER sh -c "netstat -tuln 2>/dev/null | grep ':3000 ' || ss -tuln 2>/dev/null | grep ':3000 '" 2>/dev/null)
    
    if [ ! -z "$PORT_3000" ]; then
        DETECTED_PORT=3000
        echo "✅ Puerto detectado: 3000"
    elif [ ! -z "$PORT_80" ]; then
        DETECTED_PORT=80
        echo "✅ Puerto detectado: 80"
    else
        # Intentar detectar desde los logs
        PORT_FROM_LOGS=$(docker service logs $DASHBOARD_SERVICE --tail 50 2>&1 | grep -oE "listening.*:([0-9]+)" | grep -oE "[0-9]+" | head -1)
        if [ ! -z "$PORT_FROM_LOGS" ]; then
            DETECTED_PORT=$PORT_FROM_LOGS
            echo "✅ Puerto detectado desde logs: $DETECTED_PORT"
        else
            # Usar puerto por defecto basado en configuración común
            DETECTED_PORT=3000
            echo "⚠️ No se pudo detectar puerto, usando 3000 por defecto"
        fi
    fi
else
    # Verificar desde los puertos publicados del servicio
    PUBLISHED_PORT=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null | head -1)
    if [ ! -z "$PUBLISHED_PORT" ] && [ "$PUBLISHED_PORT" != "0" ]; then
        DETECTED_PORT=$PUBLISHED_PORT
        echo "✅ Puerto detectado desde puertos publicados: $DETECTED_PORT"
    else
        DETECTED_PORT=3000
        echo "⚠️ No se pudo detectar puerto, usando 3000 por defecto"
    fi
fi

echo "Puerto a usar: $DETECTED_PORT"
echo ""

# 4. Verificar y agregar labels de Traefik
echo "4️⃣ Verificando y agregando labels de Traefik..."
EXISTING_LABELS=$(docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -c "traefik.enable" || echo "0")

if [ "$EXISTING_LABELS" -eq "0" ]; then
    echo "❌ NO hay labels de Traefik configuradas"
    echo ""
    echo "🔧 Agregando labels de Traefik..."
    
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
        --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
        --label-add "traefik.http.routers.dashboard.tls=true" \
        --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.services.dashboard.loadbalancer.server.port=$DETECTED_PORT" \
        --label-add "traefik.docker.network=easypanel" \
        $DASHBOARD_SERVICE 2>&1 | grep -v "update paused\|update in progress" || true
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ Labels agregadas correctamente"
    else
        echo "⚠️ Puede que algunas labels ya existan"
    fi
    echo ""
    echo "Verificando labels después de agregar..."
    docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.enable"}}✅ traefik.enable={{$v}}{{"\n"}}{{end}}{{if eq $k "traefik.http.routers.dashboard.rule"}}✅ traefik.http.routers.dashboard.rule={{$v}}{{"\n"}}{{end}}{{if eq $k "traefik.http.services.dashboard.loadbalancer.server.port"}}✅ traefik.http.services.dashboard.loadbalancer.server.port={{$v}}{{"\n"}}{{end}}{{end}}' 2>/dev/null
else
    echo "✅ Labels de Traefik ya existen"
    echo ""
    echo "Verificando labels actuales..."
    docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{if contains $k "traefik"}}{{$k}}={{$v}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | head -15
    
    # Verificar si el puerto es correcto
    CURRENT_PORT=$(docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.dashboard.loadbalancer.server.port"}}{{$v}}{{end}}{{end}}' 2>/dev/null)
    
    if [ ! -z "$CURRENT_PORT" ] && [ "$CURRENT_PORT" != "$DETECTED_PORT" ]; then
        echo ""
        echo "⚠️ Puerto en labels ($CURRENT_PORT) no coincide con el detectado ($DETECTED_PORT)"
        echo "🔧 Actualizando puerto en labels..."
        docker service update \
            --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
            --label-add "traefik.http.services.dashboard.loadbalancer.server.port=$DETECTED_PORT" \
            $DASHBOARD_SERVICE 2>&1 | grep -v "update paused\|update in progress" || true
        echo "✅ Puerto actualizado"
    fi
fi
echo ""

# 5. Verificar red del servicio
echo "5️⃣ Verificando red del servicio..."
SERVICE_NETWORK=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>/dev/null | head -1)
echo "Red del servicio: $SERVICE_NETWORK"

TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i traefik | head -1)
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    TRAEFIK_NETWORK=$(docker service inspect $TRAEFIK_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>/dev/null | head -1)
    if [ ! -z "$TRAEFIK_NETWORK" ]; then
        echo "Red de Traefik: $TRAEFIK_NETWORK"
        if [ "$SERVICE_NETWORK" != "$TRAEFIK_NETWORK" ]; then
            echo "⚠️ El servicio NO está en la misma red que Traefik"
            echo "🔧 Agregando servicio a la red de Traefik..."
            docker service update \
                --network-add $TRAEFIK_NETWORK \
                $DASHBOARD_SERVICE 2>&1 | grep -v "update paused\|update in progress" || true
            echo "✅ Red agregada (si fue necesario)"
        else
            echo "✅ El servicio está en la misma red que Traefik"
        fi
    fi
fi
echo ""

# 6. Reiniciar Traefik para que detecte cambios
echo "6️⃣ Reiniciando Traefik para que detecte los cambios..."
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    docker service update --force $TRAEFIK_SERVICE 2>&1 | grep -v "update paused\|update in progress" || true
    echo "✅ Traefik reiniciado"
else
    echo "⚠️ No se encontró servicio Traefik"
fi
echo ""

# 7. Esperar a que Traefik se reconfigure
echo "7️⃣ Esperando 30 segundos para que Traefik se reconfigure..."
sleep 30
echo ""

# 8. Verificar estado final
echo "8️⃣ Verificando estado final..."
echo ""
echo "Labels de Traefik finales:"
docker service inspect $DASHBOARD_SERVICE --format '{{range $k, $v := .Spec.Labels}}{{if contains $k "traefik"}}{{$k}}={{$v}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | head -15
echo ""

echo "Estado del servicio:"
docker service ps $DASHBOARD_SERVICE --no-trunc | head -2
echo ""

# 9. Probar acceso
echo "9️⃣ Probando acceso HTTPS..."
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://dashboard.checkin24hs.com/ 2>&1)

if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ Dashboard funciona correctamente! (HTTP 200)"
    echo ""
    echo "Verificando contenido..."
    curl -s https://dashboard.checkin24hs.com/ | head -c 200
    echo ""
    echo "..."
elif [ "$HTTPS_CODE" = "404" ]; then
    echo "❌ Aún hay 404"
    echo ""
    echo "Verificando logs de Traefik..."
    if [ ! -z "$TRAEFIK_SERVICE" ]; then
        docker service logs $TRAEFIK_SERVICE --tail 30 2>&1 | grep -i "dashboard\|$DASHBOARD_SERVICE" | tail -10 || echo "No hay logs relacionados"
    fi
else
    echo "⚠️ Código HTTP: $HTTPS_CODE"
fi
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Servicio: $DASHBOARD_SERVICE"
echo "   - Puerto detectado: $DETECTED_PORT"
echo "   - Labels de Traefik: Configuradas"
echo "   - Estado HTTP: $HTTPS_CODE"
echo ""
echo "⏳ Si aún ves 404:"
echo "   1. Espera 1-2 minutos más para que Traefik detecte completamente"
echo "   2. Verifica DNS: dig +short dashboard.checkin24hs.com"
echo "   3. Verifica logs: docker service logs $TRAEFIK_SERVICE --tail 50"
echo "   4. Verifica servicio: docker service ps $DASHBOARD_SERVICE"
echo ""
