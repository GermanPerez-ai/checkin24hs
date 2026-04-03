# ✅ Verificar que el Proxy Funciona

## Paso 1: Probar el proxy desde dentro del contenedor

```bash
# Probar que el proxy puede conectarse al dashboard
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
docker exec $PROXY_CONTAINER_ID curl -I http://localhost/
```

## Paso 2: Probar el proxy desde la red Docker

```bash
# Obtener IP del proxy
PROXY_IP=$(docker inspect $PROXY_CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "nvhtv52umzihypz8u7adejvpo"}}{{$value.IPAddress}}{{end}}{{end}}')
echo "IP del proxy: $PROXY_IP"

# Probar desde un contenedor en la misma red
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest curl -I http://$PROXY_IP:80/
```

## Paso 3: Verificar configuración del dominio en EasyPanel

1. Ve a EasyPanel → `dashboard-proxy` service
2. Ve a la pestaña "Dominios"
3. Verifica que `dashboard.checkin24hs.com` está configurado
4. Verifica que el destino interno es `http://checkin24hs_dashboard-proxy:80/` o similar

## Paso 4: Probar acceso público

```bash
# Probar desde el navegador o con curl
curl -I https://dashboard.checkin24hs.com/
```

---

**Si todo funciona, el dashboard debería estar accesible en `https://dashboard.checkin24hs.com/`**
