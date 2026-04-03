#!/bin/bash

echo "=========================================="
echo "🔧 ACTUALIZANDO IP DE WEBMAIL EN TRAEFIK"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# 1. Obtener IP actual del contenedor
echo "1️⃣ Obteniendo IP actual del contenedor..."
echo "----------------------------------------"
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -z "$WEBMAIL_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de webmail"
    exit 1
fi

echo "✅ Contenedor encontrado: $WEBMAIL_CONTAINER"

# Obtener IP de la red de EasyPanel
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "❌ No se encontró la red de EasyPanel"
    exit 1
fi

echo "   Red de EasyPanel: $EASYPANEL_NET"

# Obtener el nombre de la red para buscar por nombre en lugar de ID
EASYPANEL_NET_NAME=$(docker network ls | grep easypanel | head -1 | awk '{print $2}')

# Intentar obtener IP de la red de EasyPanel por nombre
CONTAINER_IP=$(docker inspect "$WEBMAIL_CONTAINER" --format "{{range \$k, \$v := .NetworkSettings.Networks}}{{if eq \$k \"$EASYPANEL_NET_NAME\"}}{{\$v.IPAddress}}{{end}}{{end}}" 2>/dev/null)

# Si no se encontró por nombre, intentar por ID
if [ -z "$CONTAINER_IP" ]; then
    CONTAINER_IP=$(docker inspect "$WEBMAIL_CONTAINER" --format "{{range \$k, \$v := .NetworkSettings.Networks}}{{if eq \$v.NetworkID \"$EASYPANEL_NET\"}}{{\$v.IPAddress}}{{end}}{{end}}" 2>/dev/null)
fi

# Si aún no se encontró, obtener la primera IP de la lista de redes
if [ -z "$CONTAINER_IP" ]; then
    CONTAINER_IP=$(docker inspect "$WEBMAIL_CONTAINER" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}}{{println}}{{end}}' 2>/dev/null | grep -E '^10\.0\.' | head -1)
fi

# Si aún no se encontró, intentar método alternativo
if [ -z "$CONTAINER_IP" ]; then
    CONTAINER_IP=$(docker inspect "$WEBMAIL_CONTAINER" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}}{{println}}{{end}}' 2>/dev/null | head -1 | tr -d '[:space:]')
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
CURRENT_IP=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>/dev/null | cut -d: -f1)

if [ -n "$CURRENT_IP" ]; then
    echo "✅ IP actual en Traefik: $CURRENT_IP"
    if [ "$CURRENT_IP" = "$CONTAINER_IP" ]; then
        echo "✅ Las IPs coinciden - No se necesita actualizar"
        exit 0
    else
        echo "⚠️  Las IPs no coinciden - Se actualizará"
    fi
else
    echo "⚠️  No se encontró IP configurada en Traefik"
fi
echo ""

# 3. Actualizar IP en Traefik
echo "3️⃣ Actualizando IP en Traefik..."
echo "----------------------------------------"
docker service update \
  --label-rm "traefik.http.services.webmail.loadbalancer.server" \
  --label-add "traefik.http.services.webmail.loadbalancer.server=$CONTAINER_IP:80" \
  $SERVICE_NAME 2>&1 | grep -v "verify:"

echo ""
echo "✅ IP actualizada"
echo ""

# 4. Esperar a que se apliquen los cambios
echo "4️⃣ Esperando a que se apliquen los cambios..."
echo "----------------------------------------"
sleep 20
echo "✅ Cambios aplicados"
echo ""

# 5. Verificar configuración actualizada
echo "5️⃣ Verificando configuración actualizada..."
echo "----------------------------------------"
NEW_IP=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>/dev/null | cut -d: -f1)

if [ "$NEW_IP" = "$CONTAINER_IP" ]; then
    echo "✅ IP actualizada correctamente: $NEW_IP:80"
else
    echo "⚠️  La IP no se actualizó correctamente"
    echo "   IP esperada: $CONTAINER_IP"
    echo "   IP actual: $NEW_IP"
fi
echo ""

echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "💡 Próximos pasos:"
echo "   1. Espera 1-2 minutos para que Traefik detecte los cambios"
echo "   2. Prueba acceder a: https://$DOMAIN/"
echo ""
