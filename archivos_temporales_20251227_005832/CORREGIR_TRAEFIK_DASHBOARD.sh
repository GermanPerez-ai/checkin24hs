#!/bin/bash

echo "=========================================="
echo "Corregir Configuración Traefik"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor corriendo"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo ""

# 1. Obtener IP correcta del contenedor
echo "=== 1. Obtener IP del contenedor ==="
# Obtener todas las IPs
docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | tr ' ' '\n' | grep -v '^$'
echo ""

# Obtener IP de la red easypanel
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ ! -z "$EASYPANEL_NET" ]; then
    CONTAINER_IP=$(docker inspect $CONTAINER_ID --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$EASYPANEL_NET\"}}{{.IPAddress}}{{end}}{{end}}")
    echo "IP en red easypanel: $CONTAINER_IP"
else
    CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
    echo "IP del contenedor: $CONTAINER_IP"
fi
echo ""

# 2. Verificar etiquetas Traefik actuales
echo "=== 2. Etiquetas Traefik actuales ==="
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
echo ""

# 3. Verificar que el servicio está en la red correcta
echo "=== 3. Verificar redes del servicio ==="
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | xargs -I {} docker network inspect {} --format '{{.Name}}' 2>/dev/null
echo ""

# 4. Actualizar etiquetas Traefik para usar el nombre del servicio en vez de IP
echo "=== 4. Actualizar etiquetas Traefik ==="
echo "Actualizando servicio para usar nombre del servicio..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard 2>&1

echo ""
echo "Esperando 15 segundos..."
sleep 15

# 5. Verificar que Traefik detecta el servicio
echo ""
echo "=== 5. Verificar logs de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Logs de Traefik (últimas 10 líneas con 'dashboard'):"
    docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -i dashboard | tail -10
fi
echo ""

# 6. Probar acceso
echo "=== 6. Probar acceso ==="
echo "Probando http://dashboard.checkin24hs.com:"
curl -I --connect-timeout 5 http://dashboard.checkin24hs.com 2>&1 | head -10
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Si sigue dando 404, verifica:"
echo "1. Que Traefik está en la misma red que el servicio"
echo "2. Que el DNS apunta correctamente: dig dashboard.checkin24hs.com"
echo ""
