#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRIGIENDO 502 BAD GATEWAY EN WEBMAIL"
echo "=========================================="
echo ""

# 1. Verificar el nombre del servicio que Traefik debería usar
echo "=== 1. Verificando configuración del servicio ==="
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
echo ""

# 2. Obtener el VIP del servicio
echo "=== 2. VIP del servicio webmail ==="
docker service inspect checkin24hs_webmail --format='{{range .Endpoint.VirtualIPs}}{{.NetworkID}}={{.Addr}}{{"\n"}}{{end}}'
echo ""

# 3. Verificar el nombre del servicio en Docker Swarm
echo "=== 3. Nombre del servicio ==="
docker service ls | grep webmail
echo ""

# 4. Actualizar las etiquetas para usar el nombre correcto del servicio
echo "=== 4. Actualizando etiquetas de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.services.webmail.loadbalancer.server=checkin24hs_webmail:80" \
  --label-add "traefik.http.routers.webmail-secure.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail-secure.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail-secure.service=webmail" \
  --label-add "traefik.http.routers.webmail-secure.tls=true" \
  checkin24hs_webmail

echo "⏳ Esperando 20 segundos..."
sleep 20
echo ""

# 5. Verificar logs de Traefik para errores
echo "=== 5. Logs recientes de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
docker logs $TRAEFIK_CONTAINER --tail 50 | grep -i "webmail\|error\|502" | tail -10 || echo "No se encontraron errores específicos"
echo ""

# 6. Probar conectividad desde Traefik al servicio usando el nombre del servicio
echo "=== 6. Probando conectividad desde Traefik ==="
docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=5 "http://checkin24hs_webmail:80" 2>&1 | head -5 || echo "No se pudo conectar usando el nombre del servicio"
echo ""

echo "=========================================="
echo "✅ CORRECCIÓN APLICADA"
echo "=========================================="
echo ""
echo "Cambios realizados:"
echo "  - Actualizado traefik.http.services.webmail.loadbalancer.server a 'checkin24hs_webmail:80'"
echo "  - Esto le dice a Traefik que use el nombre del servicio de Docker Swarm"
echo ""
echo "Prueba acceder a: http://webmail.checkin24hs.com"
echo ""


