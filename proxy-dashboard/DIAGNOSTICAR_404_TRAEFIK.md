# 🔍 Diagnosticar 404 desde Traefik

## Problema
El proxy funciona localmente pero el dominio público devuelve 404.

## Diagnóstico

### Paso 1: Verificar que Traefik puede acceder al proxy

```bash
# Obtener un contenedor de Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
echo "Contenedor Traefik: $TRAEFIK_CONTAINER"

# Probar acceso desde Traefik al proxy usando el alias
docker exec $TRAEFIK_CONTAINER curl -I http://checkin24hs_dashboard-proxy:80/

# Probar con el nombre completo del contenedor del proxy
PROXY_FULL_NAME=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.Names}}" | head -1)
echo "Nombre completo del proxy: $PROXY_FULL_NAME"
docker exec $TRAEFIK_CONTAINER curl -I http://$PROXY_FULL_NAME:80/
```

### Paso 2: Verificar logs de Traefik

```bash
# Ver logs recientes de Traefik
docker logs $TRAEFIK_CONTAINER --tail 50 | grep -i dashboard
```

### Paso 3: Verificar configuración del dominio en EasyPanel

En EasyPanel, verifica que:
1. El dominio `dashboard.checkin24hs.com` está en el servicio `dashboard-proxy`
2. El destino interno es `http://checkin24hs_dashboard-proxy:80/` o `http://checkin24hs-dashboard-proxy:80/`
3. El dominio está marcado como primario (estrella amarilla)

### Paso 4: Verificar alias del proxy

```bash
# Verificar aliases del servicio proxy
docker service inspect checkin24hs_dashboard-proxy | grep -A 5 "Aliases"
```

---

**Si Traefik no puede acceder al proxy, necesitaremos usar el nombre completo del contenedor del proxy en la configuración del dominio.**
