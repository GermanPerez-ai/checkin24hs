# 🔧 Restaurar Etiquetas de Traefik

## Problema:
- Después de implementar, el dominio devuelve 404
- Las etiquetas de Traefik pueden haberse perdido

## Solución:

```bash
# 1. Verificar si hay etiquetas de Traefik
echo "=== Verificando etiquetas de Traefik ==="
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
docker inspect $DASHBOARD_ID | grep -A 40 "Labels" | grep -i traefik | head -15

# 2. Si no hay etiquetas, agregarlas de nuevo
if [ -z "$(docker inspect $DASHBOARD_ID | grep -A 40 "Labels" | grep -i traefik)" ]; then
    echo ""
    echo "=== Agregando etiquetas de Traefik ==="
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
      --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.routers.dashboard.service=dashboard" \
      --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
      --label-add "traefik.docker.network=easypanel" \
      checkin24hs_dashboard
    echo "✅ Etiquetas agregadas, espera 20 segundos..."
    sleep 20
fi

# 3. Verificar estado del servicio
echo ""
echo "=== Estado del servicio ==="
docker service ps checkin24hs_dashboard --no-trunc | head -3

# 4. Probar el dominio
echo ""
echo "=== Probando dominio ==="
curl -I https://dashboard.checkin24hs.com/ 2>&1 | head -10
```
