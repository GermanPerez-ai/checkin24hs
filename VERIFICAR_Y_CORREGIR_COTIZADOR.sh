#!/bin/bash
# Script rápido para verificar y corregir el cotizador

echo "=========================================="
echo "🔍 VERIFICAR Y CORREGIR COTIZADOR"
echo "=========================================="
echo ""

# 1. Buscar el servicio/contenedor del cotizador
echo "1️⃣ Buscando servicio/contenedor del cotizador..."
CONTAINER_ID=$(docker ps --filter "name=cotizador" --format "{{.ID}}" | head -1)
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -i "cotizador\|cotizar" | head -1)

if [ -z "$CONTAINER_ID" ] && [ -z "$SERVICE_NAME" ]; then
    echo "   ⚠️  No se encontró servicio ni contenedor"
    echo ""
    echo "   Servicios disponibles:"
    docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}" | head -10
    echo ""
    echo "   Contenedores disponibles:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | head -10
    echo ""
    read -p "   Ingresa el nombre del servicio o ID del contenedor: " INPUT
    
    if [[ "$INPUT" =~ ^[a-f0-9]+$ ]]; then
        CONTAINER_ID="$INPUT"
    else
        SERVICE_NAME="$INPUT"
    fi
fi

# 2. Verificar archivos
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   ✅ Contenedor encontrado: $CONTAINER_ID"
    echo ""
    echo "2️⃣ Verificando archivos en el contenedor..."
    
    # Verificar index.html
    if docker exec "$CONTAINER_ID" test -f /usr/share/nginx/html/index.html 2>/dev/null; then
        echo "   ✅ index.html existe"
        docker exec "$CONTAINER_ID" head -1 /usr/share/nginx/html/index.html | sed 's/^/      /'
    else
        echo "   ❌ index.html NO existe"
        echo ""
        echo "   Verificando si existe cotizador-cliente.html..."
        if docker exec "$CONTAINER_ID" test -f /usr/share/nginx/html/cotizador-cliente.html 2>/dev/null; then
            echo "   ✅ cotizador-cliente.html existe, copiando como index.html..."
            docker exec "$CONTAINER_ID" cp /usr/share/nginx/html/cotizador-cliente.html /usr/share/nginx/html/index.html
            if [ $? -eq 0 ]; then
                echo "   ✅ index.html creado"
            else
                echo "   ❌ Error al crear index.html"
            fi
        else
            echo "   ❌ cotizador-cliente.html tampoco existe"
            echo ""
            echo "   Archivos en /usr/share/nginx/html/:"
            docker exec "$CONTAINER_ID" ls -la /usr/share/nginx/html/ 2>/dev/null | head -10
        fi
    fi
    
    echo ""
    echo "3️⃣ Verificando otros archivos necesarios..."
    for archivo in "supabase-config.js" "supabase-client.js"; do
        if docker exec "$CONTAINER_ID" test -f "/usr/share/nginx/html/$archivo" 2>/dev/null; then
            echo "   ✅ $archivo existe"
        else
            echo "   ⚠️  $archivo NO existe"
        fi
    done
    
elif [ ! -z "$SERVICE_NAME" ]; then
    echo "   ✅ Servicio encontrado: $SERVICE_NAME"
    echo ""
    echo "2️⃣ Para servicios Docker Swarm, necesitas verificar el volumen montado"
    echo ""
    echo "   Configuración del servicio:"
    docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}} -> {{.Target}}{{"\n"}}{{end}}' 2>/dev/null
    echo ""
    echo "   Para verificar archivos, necesitas acceder al volumen montado"
fi

echo ""
echo "4️⃣ Verificando configuración de Traefik..."
if [ ! -z "$SERVICE_NAME" ]; then
    TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep traefik)
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo "   ⚠️  No se encontraron etiquetas Traefik"
        echo ""
        echo "   ¿Deseas agregar configuración de Traefik? (S/N): "
        read -r ADD_TRAEFIK
        if [ "$ADD_TRAEFIK" = "S" ] || [ "$ADD_TRAEFIK" = "s" ]; then
            echo ""
            echo "   Configurando Traefik..."
            docker service update \
              --label-add "traefik.enable=true" \
              --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
              --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
              --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
              --label-add "traefik.http.services.cotizador.loadbalancer.server.port=80" \
              "$SERVICE_NAME"
            
            if [ $? -eq 0 ]; then
                echo "   ✅ Traefik configurado"
            else
                echo "   ❌ Error al configurar Traefik"
            fi
        fi
    else
        echo "   ✅ Etiquetas Traefik encontradas:"
        echo "$TRAEFIK_LABELS" | sed 's/^/      /'
    fi
fi

echo ""
echo "5️⃣ Verificando red easypanel..."
if [ ! -z "$SERVICE_NAME" ]; then
    NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ✅ Servicio está en la red easypanel"
    else
        echo "   ⚠️  Servicio NO está en la red easypanel"
        echo ""
        echo "   ¿Deseas agregarlo a la red easypanel? (S/N): "
        read -r ADD_NETWORK
        if [ "$ADD_NETWORK" = "S" ] || [ "$ADD_NETWORK" = "s" ]; then
            docker service update --network-add easypanel "$SERVICE_NAME"
            if [ $? -eq 0 ]; then
                echo "   ✅ Servicio agregado a la red easypanel"
            else
                echo "   ❌ Error al agregar a la red"
            fi
        fi
    fi
fi

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Espera 30-60 segundos para que Traefik detecte los cambios"
echo "   2. Prueba acceder a: https://cotizar.checkin24hs.com/"
echo "   3. Si aún no funciona, ejecuta: ./DIAGNOSTICAR_404_COTIZADOR.sh"
echo ""
