#!/bin/bash

echo "=========================================="
echo "🔧 CORRIGIENDO IP DE WEBMAIL MANUALMENTE"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# 1. Obtener IP correcta del contenedor
echo "1️⃣ Obteniendo IP correcta del contenedor..."
echo "----------------------------------------"
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -z "$WEBMAIL_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de webmail"
    exit 1
fi

echo "✅ Contenedor: $WEBMAIL_CONTAINER"
echo ""

# Obtener todas las IPs del contenedor
echo "📋 Todas las IPs del contenedor:"
docker inspect "$WEBMAIL_CONTAINER" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{println}}{{end}}' 2>/dev/null
echo ""

# Obtener IP de la red de EasyPanel
EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')
echo "🔍 Buscando IP en la red: $EASYPANEL_NET_NAME"

CONTAINER_IP=$(docker inspect "$WEBMAIL_CONTAINER" --format "{{range \$k, \$v := .NetworkSettings.Networks}}{{if eq \$k \"$EASYPANEL_NET_NAME\"}}{{\$v.IPAddress}}{{end}}{{end}}" 2>/dev/null)

if [ -z "$CONTAINER_IP" ]; then
    # Intentar obtener la primera IP que empiece con 10.0.
    CONTAINER_IP=$(docker inspect "$WEBMAIL_CONTAINER" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}}{{println}}{{end}}' 2>/dev/null | grep -E '^10\.0\.' | head -1 | tr -d '[:space:]')
fi

if [ -z "$CONTAINER_IP" ]; then
    echo "❌ No se pudo obtener la IP del contenedor"
    exit 1
fi

echo "✅ IP del contenedor: $CONTAINER_IP"
echo ""

# 2. Verificar IP actual en Traefik
echo "2️⃣ Verificando IP actual en Traefik..."
echo "----------------------------------------"
CURRENT_CONFIG=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>/dev/null)

if [ -n "$CURRENT_CONFIG" ]; then
    CURRENT_IP=$(echo "$CURRENT_CONFIG" | cut -d: -f1)
    CURRENT_PORT=$(echo "$CURRENT_CONFIG" | cut -d: -f2)
    echo "📋 Configuración actual: $CURRENT_CONFIG"
    echo "   IP: $CURRENT_IP"
    echo "   Puerto: $CURRENT_PORT"
    
    # Verificar si la IP es válida
    if [[ ! "$CURRENT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "   ⚠️  IP inválida detectada - Se corregirá"
        NEEDS_UPDATE=true
    elif [ "$CURRENT_IP" != "$CONTAINER_IP" ]; then
        echo "   ⚠️  IP no coincide - Se actualizará"
        NEEDS_UPDATE=true
    else
        echo "   ✅ IP correcta"
        NEEDS_UPDATE=false
    fi
else
    echo "⚠️  No se encontró configuración de IP en Traefik"
    NEEDS_UPDATE=true
fi
echo ""

# 3. Actualizar IP si es necesario
if [ "$NEEDS_UPDATE" = true ]; then
    echo "3️⃣ Actualizando IP en Traefik..."
    echo "----------------------------------------"
    
    # Remover configuración antigua
    docker service update \
      --label-rm "traefik.http.services.webmail.loadbalancer.server" \
      $SERVICE_NAME 2>&1 | grep -v "verify:" > /dev/null
    
    # Agregar configuración nueva
    docker service update \
      --label-add "traefik.http.services.webmail.loadbalancer.server=$CONTAINER_IP:80" \
      $SERVICE_NAME 2>&1 | grep -v "verify:"
    
    echo ""
    echo "✅ IP actualizada a: $CONTAINER_IP:80"
    echo ""
    
    # Esperar a que se apliquen los cambios
    echo "⏳ Esperando 20 segundos para que se apliquen los cambios..."
    sleep 20
    echo "✅ Cambios aplicados"
    echo ""
    
    # Verificar
    NEW_CONFIG=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>/dev/null)
    NEW_IP=$(echo "$NEW_CONFIG" | cut -d: -f1)
    
    if [ "$NEW_IP" = "$CONTAINER_IP" ]; then
        echo "✅ IP actualizada correctamente: $NEW_CONFIG"
    else
        echo "⚠️  La IP no se actualizó correctamente"
        echo "   IP esperada: $CONTAINER_IP"
        echo "   IP actual: $NEW_IP"
    fi
else
    echo "✅ No se necesita actualizar - La IP ya es correcta"
fi
echo ""

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "💡 Próximos pasos:"
echo "   1. Espera 1-2 minutos para que Traefik detecte los cambios"
echo "   2. Prueba acceder a: https://$DOMAIN/"
echo "   3. Si hay problemas, ejecuta: ./VERIFICAR_WEBMAIL_COMPLETO.sh"
echo ""
