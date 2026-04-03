# 🧹 Limpiar y Estabilizar

## Problemas detectados:
- ❌ Hay 3 contenedores del dashboard corriendo
- ❌ El servicio está configurado para 2 réplicas (debería ser 1)
- ❌ Error "Address already in use"
- ❌ Servicio dashboard-proxy está detenido (0/1)

## Solución:

```bash
# 1. Escalar el servicio dashboard a 1 réplica
echo "=== Escalando servicio dashboard a 1 réplica ==="
docker service scale checkin24hs_dashboard=1

# 2. Esperar y limpiar contenedores antiguos
sleep 10
echo ""
echo "=== Limpiando contenedores antiguos ==="
docker ps -a | grep "checkin24hs_dashboard.1" | grep -v "Up" | awk '{print $1}' | xargs -r docker rm -f

# 3. Verificar estado
echo ""
echo "=== Estado después de limpiar ==="
docker service ps checkin24hs_dashboard --no-trunc | head -3
docker ps | grep dashboard

# 4. Verificar etiquetas de Traefik
echo ""
echo "=== Verificando etiquetas de Traefik ==="
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
docker inspect $DASHBOARD_ID | grep -A 40 "Labels" | grep -i traefik | head -15

# 5. Si no hay etiquetas, agregarlas
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

# 6. Probar el dominio
echo ""
echo "=== Probando dominio ==="
curl -I https://dashboard.checkin24hs.com/ 2>&1 | head -10
```
