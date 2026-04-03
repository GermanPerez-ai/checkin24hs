# 🔧 Hacer que el Alias del Proxy Funcione

## Problema
EasyPanel genera automáticamente el destino `http://checkin24hs_dashboard-proxy:80/` pero no funciona.

## Verificar si el alias se resuelve

```bash
# Verificar aliases del servicio proxy
docker service inspect checkin24hs_dashboard-proxy | grep -A 10 "Aliases"

# Probar resolución del alias desde la red correcta
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest nslookup checkin24hs_dashboard-proxy

# Probar conexión con el alias
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest curl -I http://checkin24hs_dashboard-proxy:80/
```

## Si el alias no se resuelve

Necesitamos agregar el alias manualmente al servicio o verificar que ambos servicios estén en la misma red.

### Opción 1: Verificar que ambos servicios están en la misma red

```bash
# Ver redes de ambos servicios
docker service inspect checkin24hs_dashboard-proxy | grep -A 10 "Networks"
docker service inspect traefik | grep -A 10 "Networks"
```

### Opción 2: Reiniciar el servicio proxy para forzar actualización de DNS

```bash
# Reiniciar el servicio proxy
docker service update --force checkin24hs_dashboard-proxy

# Esperar 30 segundos
sleep 30

# Verificar que el alias funciona
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest curl -I http://checkin24hs_dashboard-proxy:80/
```

---

**Si el alias funciona después de reiniciar, el problema era caché de DNS. Si no funciona, necesitaremos otra solución.**
