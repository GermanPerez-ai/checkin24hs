# 🔍 Verificar Red del Proxy

## 📊 Problema

- ❌ Alias `checkin24hs-dashboard-proxy` no se resuelve
- ❌ Alias `dashboard-proxy` no se resuelve
- ⚠️ Necesitamos verificar la red del contenedor del proxy

## 🔍 Diagnóstico

### Paso 1: Verificar en qué red está el contenedor del proxy

```bash
# Obtener ID del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

# Ver redes del contenedor del proxy
docker inspect $PROXY_CONTAINER_ID | grep -A 20 "Networks"
```

### Paso 2: Obtener IP del contenedor del proxy

```bash
# Obtener IP del contenedor del proxy en la red easypanel-checkin24hs
PROXY_IP=$(docker inspect $PROXY_CONTAINER_ID | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address" | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del contenedor del proxy: $PROXY_IP"
```

### Paso 3: Probar acceso directo a la IP del proxy

```bash
# Probar acceso directo a la IP del proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://$PROXY_IP:80/
```

### Paso 4: Si el proxy no está en la red, agregarlo

Si el contenedor del proxy no está en la red `easypanel-checkin24hs`, necesitamos agregarlo:

```bash
# Conectar el contenedor a la red (si no está)
docker network connect easypanel-checkin24hs $PROXY_CONTAINER_ID
```

---

**Ejecuta primero los Pasos 1-3 para verificar la red y la IP del proxy.**
