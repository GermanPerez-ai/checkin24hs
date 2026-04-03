#!/bin/bash
# Solución final para el servicio cotizador - Usar formato estándar de Traefik

echo "=== Solución final para cotizador ==="

# 1. Ver cómo están configurados otros servicios que funcionan
echo ""
echo "1. Ver etiquetas de Traefik de otros servicios (ejemplo webmail):"
docker service inspect checkin24hs_webmail --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | head -10

# 2. Limpiar todas las etiquetas del servicio cotizador
echo ""
echo "2. Limpiando etiquetas actuales..."
docker service update \
  --label-rm "traefik.http.services.cotizador-service.loadbalancer.servers[0].url" \
  cotizador

sleep 5

# 3. Usar el formato estándar: solo el puerto y dejar que Traefik resuelva el nombre
# Pero como "cotizador" no funciona, necesitamos usar el nombre del servicio en Docker Swarm
# En Docker Swarm, Traefik puede usar el nombre del servicio directamente si está en la misma red
echo ""
echo "3. Aplicando formato estándar de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.cotizador.entrypoints=web" \
  --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
  --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
  --label-add "traefik.docker.network=easypanel" \
  cotizador

# 4. Esperar 30 segundos
echo ""
echo "4. Esperando 30 segundos para que Traefik actualice..."
sleep 30

# 5. Verificar logs
echo ""
echo "5. Verificando logs de Traefik:"
docker service logs traefik --tail 50 | grep -i cotizar | tail -10

# 6. Verificar etiquetas finales
echo ""
echo "6. Etiquetas finales:"
docker service inspect cotizador --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | sort

echo ""
echo "✅ Configuración aplicada. Prueba acceder a: https://cotizar.checkin24hs.com"
