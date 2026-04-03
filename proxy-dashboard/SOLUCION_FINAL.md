# 🔧 Solución Final - Agregar Etiquetas de Traefik

## Problemas detectados:
- ❌ Hay 2 contenedores del proxy corriendo (duplicados)
- ❌ No hay etiquetas de Traefik en el contenedor
- ❌ Traefik no detecta el servicio
- ❌ El dominio devuelve 404

## Solución:

1. Limpiar contenedores duplicados
2. Agregar etiquetas de Traefik al servicio
3. Verificar que Traefik detecte el servicio

## Comandos:

```bash
# 1. Limpiar contenedores duplicados (dejar solo 1 réplica)
echo "=== Limpiando contenedores duplicados ==="
docker service scale checkin24hs_dashboard-proxy=1
sleep 5

# 2. Verificar que solo hay 1 contenedor
echo ""
echo "=== Contenedores del proxy ==="
docker ps | grep dashboard-proxy

# 3. Agregar etiquetas de Traefik al servicio
echo ""
echo "=== Agregando etiquetas de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard-proxy.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard-proxy.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-proxy.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.dashboard-proxy.service=dashboard-proxy" \
  --label-add "traefik.http.services.dashboard-proxy.loadbalancer.server.port=80" \
  --label-add "traefik.docker.network=easypanel" \
  checkin24hs_dashboard-proxy

# 4. Esperar a que se actualice
echo ""
echo "⏳ Esperando 15 segundos para que se actualice..."
sleep 15

# 5. Verificar etiquetas
echo ""
echo "=== Verificando etiquetas agregadas ==="
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
docker inspect $PROXY_ID | grep -A 30 "Labels" | grep -i traefik | head -15

# 6. Verificar logs de Traefik
echo ""
echo "=== Verificando logs de Traefik ==="
docker service logs traefik --tail 30 | grep -i "dashboard" | tail -5

# 7. Probar el dominio
echo ""
echo "=== Probando el dominio ==="
curl -I https://dashboard.checkin24hs.com/ 2>&1 | head -5
```
