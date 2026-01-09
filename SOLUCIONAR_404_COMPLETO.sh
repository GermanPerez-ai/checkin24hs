#!/bin/bash

echo "🔧 SOLUCIONANDO ERROR 404 DEL DASHBOARD"
echo "========================================"
echo ""

# 1. Encontrar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)
echo "✅ Servicio encontrado: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 2. Verificar labels de Traefik actuales
echo "2️⃣ Verificando labels de Traefik actuales..."
TRAEFIK_LABELS=$(docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}')

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ NO hay labels de Traefik configuradas"
    echo ""
    echo "🔧 Agregando labels de Traefik..."
    
    docker service update \
        --label-add "traefik.enable=true" \
        --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
        --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
        --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
        --label-add "traefik.http.routers.dashboard.tls=true" \
        --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
        $DASHBOARD_SERVICE
    
    if [ $? -eq 0 ]; then
        echo "✅ Labels agregadas correctamente"
    else
        echo "❌ Error al agregar labels"
        exit 1
    fi
    
    echo ""
    echo "⏳ Esperando 10 segundos..."
    sleep 10
    
    echo "Verificando labels después de agregar..."
    docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}'
else
    echo "✅ Labels de Traefik encontradas:"
    echo "$TRAEFIK_LABELS"
    echo ""
    echo "⚠️ Si el dominio aún no funciona, puede que necesites agregar labels adicionales"
fi
echo ""

# 3. Verificar red del servicio
echo "3️⃣ Verificando red del servicio..."
SERVICE_NETWORK=$(docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}')
echo "Red del servicio: $SERVICE_NETWORK"

# Buscar red de Traefik
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    TRAEFIK_NETWORK=$(docker service inspect $TRAEFIK_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>/dev/null)
    if [ ! -z "$TRAEFIK_NETWORK" ]; then
        echo "Red de Traefik: $TRAEFIK_NETWORK"
        if [ "$SERVICE_NETWORK" != "$TRAEFIK_NETWORK" ]; then
            echo "⚠️ El servicio NO está en la misma red que Traefik"
            echo "🔧 Agregando servicio a la red de Traefik..."
            docker service update --network-add $TRAEFIK_NETWORK $DASHBOARD_SERVICE
            echo "✅ Red agregada"
        else
            echo "✅ El servicio está en la misma red que Traefik"
        fi
    fi
fi
echo ""

# 4. Verificar que el contenedor responde
echo "4️⃣ Verificando que el contenedor responde en puerto 3000..."
CONTAINER_ID=$(docker ps --filter "name=$DASHBOARD_NAME" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Probando conexión local..."
    docker exec $CONTAINER_ID wget -qO- http://localhost:3000 2>&1 | head -3 || echo "⚠️ No responde en localhost:3000"
else
    echo "⚠️ No se encontró contenedor activo"
fi
echo ""

# 5. Verificar logs de Traefik
echo "5️⃣ Verificando logs de Traefik (últimas 30 líneas relacionadas con dashboard)..."
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    docker service logs $TRAEFIK_SERVICE --tail 100 2>&1 | grep -i "dashboard\|$DASHBOARD_NAME" | tail -30 || echo "No hay logs relacionados"
else
    echo "⚠️ No se encontró servicio Traefik"
fi
echo ""

# 6. Esperar y dar instrucciones
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "✅ Proceso de configuración completado"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Espera 1-2 minutos más para que Traefik detecte completamente los cambios"
echo "2. Prueba acceder a: https://dashboard.checkin24hs.com/"
echo "3. Si aún no funciona, verifica:"
echo "   - Que el DNS apunte correctamente al servidor"
echo "   - Que Traefik esté corriendo: docker service ps traefik"
echo "   - Los logs de Traefik: docker service logs traefik --tail 50"
echo ""
echo "💡 Si el problema persiste, puede que necesites reiniciar Traefik:"
echo "   docker service update --force traefik"
