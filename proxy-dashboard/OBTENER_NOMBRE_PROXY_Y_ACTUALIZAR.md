# ✅ Obtener Nombre del Proxy y Actualizar Dominio

## 📊 Estado Actual

- ✅ Dominio `dashboard.checkin24hs.com` configurado en `dashboard-proxy`
- ❌ Destino apunta a `http://checkin24hs_dashboard-proxy:80/` (alias no se resuelve)
- ✅ Necesitamos usar el nombre completo del contenedor

## 🔧 Solución

### Paso 1: Obtener nombre completo del contenedor del proxy

```bash
# Obtener nombre completo del contenedor del proxy más reciente
PROXY_CONTAINER_NAME=$(docker ps --format "{{.Names}}" --filter "name=checkin24hs_dashboard-proxy" | head -1)
echo "Nombre completo del contenedor del proxy: $PROXY_CONTAINER_NAME"
```

### Paso 2: Probar que el nombre completo funciona

```bash
# Probar resolución DNS del nombre completo
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup $PROXY_CONTAINER_NAME

# Probar conexión
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://$PROXY_CONTAINER_NAME:80/
```

### Paso 3: Actualizar dominio en EasyPanel

1. En el servicio `dashboard-proxy`, haz clic en el icono de lápiz del dominio `dashboard.checkin24hs.com`
2. En "Destino", cambia a:
   - Protocolo: HTTP
   - Puerto: `80`
   - Ruta: `/`
3. En "Host" (arriba), NO cambies nada (debe seguir siendo `dashboard.checkin24hs.com`)
4. **IMPORTANTE**: El destino debe ser `http://$PROXY_CONTAINER_NAME:80/` (usa el nombre completo obtenido en el Paso 1)
5. Guarda

**NOTA**: Este nombre cambiará cuando el contenedor se recree, así que necesitarás actualizarlo manualmente.

---

**Ejecuta primero el Paso 1 para obtener el nombre completo del contenedor del proxy. Luego actualiza el dominio en EasyPanel con ese nombre en el campo "Destino".**
