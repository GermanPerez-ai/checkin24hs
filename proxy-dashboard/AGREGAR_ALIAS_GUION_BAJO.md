# 🔧 Agregar Alias con Guión Bajo al Servicio Proxy

## Problema
EasyPanel genera `checkin24hs_dashboard-proxy` (con guión bajo) pero el servicio solo tiene `checkin24hs-dashboard-proxy` (con guión).

## Solución: Agregar el alias con guión bajo

Necesitamos agregar el alias `checkin24hs_dashboard-proxy` al servicio proxy para que coincida con lo que EasyPanel espera.

### Paso 1: Identificar la red del servicio

```bash
# Ver la red del servicio proxy
docker service inspect checkin24hs_dashboard-proxy | grep -A 5 "nvhtv52umzihypz8u7adejvpo" | head -10
```

### Paso 2: Agregar el alias con guión bajo

```bash
# Agregar el alias checkin24hs_dashboard-proxy a la red easypanel-checkin24hs
docker service update \
  --network-add name=nvhtv52umzihypz8u7adejvpo,alias=checkin24hs_dashboard-proxy \
  checkin24hs_dashboard-proxy
```

### Paso 3: Verificar que el alias funciona

```bash
# Esperar unos segundos
sleep 10

# Probar resolución
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest nslookup checkin24hs_dashboard-proxy

# Probar conexión
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest curl -I http://checkin24hs_dashboard-proxy:80/
```

---

**Si esto no funciona, necesitaremos usar el alias con guión (`checkin24hs-dashboard-proxy`) o cambiar la configuración del dominio en EasyPanel.**
