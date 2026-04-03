# 🔍 Verificar Redes y Aliases

## 📊 Estado Actual

- ✅ Traefik está en: `nvhtv52umzihypz8u7adejvpo` y `xmv09tpxwryie79b0jv531623`
- ✅ Dashboard está en las mismas redes
- ✅ Dashboard tiene alias `checkin24hs_dashboard` en `nvhtv52umzihypz8u7adejvpo`

## 🔍 Paso 1: Identificar nombres de las redes

```bash
# Ver nombres de las redes
docker network ls | grep -E "nvhtv52umzihypz8u7adejvpo|xmv09tpxwryie79b0jv531623"

# Ver detalles de cada red
docker network inspect nvhtv52umzihypz8u7adejvpo | grep -E "Name|easypanel"
docker network inspect xmv09tpxwryie79b0jv531623 | grep -E "Name|easypanel"
```

## 🔍 Paso 2: Probar si el alias funciona

```bash
# Probar resolución del alias checkin24hs_dashboard desde la red correcta
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest nslookup checkin24hs_dashboard

# Probar conexión
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest curl -I http://checkin24hs_dashboard:3000/
```

## 🔍 Paso 3: Verificar si el proxy puede resolver el alias

```bash
# Probar desde dentro del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
docker exec $PROXY_CONTAINER_ID nslookup checkin24hs_dashboard
docker exec $PROXY_CONTAINER_ID curl -I http://checkin24hs_dashboard:3000/
```

---

**Ejecuta estos 3 pasos. Si el alias funciona en el Paso 2 pero no en el Paso 3, el problema es que el proxy no está en la red correcta.**
