# 🔧 Solución: Service Update Paused

## ⚠️ Problema

El comando `docker service update --force` se pausó con el mensaje:
```
service update paused: update paused due to failure or early termination of task
```

## 🔍 Diagnóstico

Primero, verifica el estado del servicio y los contenedores:

```bash
# Ver estado del servicio
docker service ps checkin24hs_dashboard

# Ver logs del servicio
docker service logs --tail 50 checkin24hs_dashboard

# Ver contenedores corriendo
docker ps | grep dashboard
```

---

## ✅ Soluciones

### Opción 1: Forzar Update Nuevamente

```bash
# Reiniciar el servicio forzando
docker service update --force checkin24hs_dashboard

# Esperar a que termine
docker service ps checkin24hs_dashboard
```

### Opción 2: Escalar a 0 y luego a 1

```bash
# Escalar a 0 (detener todos los contenedores)
docker service scale checkin24hs_dashboard=0

# Esperar un momento
sleep 5

# Escalar a 1 (reiniciar)
docker service scale checkin24hs_dashboard=1

# Verificar estado
docker service ps checkin24hs_dashboard
```

### Opción 3: Reiniciar Contenedor Directo (Si hay bind mount)

```bash
# Verificar bind mount
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
docker inspect ${CONTAINER_ID} --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'

# Si el bind mount es /root/checkin24hs/dashboard.html, el archivo ya está actualizado
# Solo necesitas reiniciar el contenedor
docker restart ${CONTAINER_ID}
```

### Opción 4: Verificar y Re-aplicar Labels de Traefik (Si es necesario)

```bash
# Si necesitas re-aplicar las labels de Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard
```

---

## 🔍 Verificación Final

Después de cualquier solución, verifica:

```bash
# 1. Ver estado del servicio
docker service ps checkin24hs_dashboard

# 2. Verificar que el contenedor esté corriendo
docker ps | grep dashboard

# 3. Ver logs para verificar que no hay errores
docker service logs --tail 20 checkin24hs_dashboard

# 4. Verificar Build Number en el archivo montado
grep "DASHBOARD_BUILD_NUMBER" /root/checkin24hs/dashboard.html | head -1
# Debe mostrar: window.DASHBOARD_BUILD_NUMBER = 40;
```

---

## 💡 Recomendación

**Intenta primero la Opción 3** (reiniciar contenedor directo), ya que el archivo ya está actualizado en `/root/checkin24hs/dashboard.html` y ese es el bind mount.

---

**Si el problema persiste, comparte los logs del servicio para diagnosticar mejor.**
