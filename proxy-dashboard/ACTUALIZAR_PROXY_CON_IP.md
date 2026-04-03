# ✅ Actualizar Proxy con IP Directa

## 📊 Estado Actual

- ✅ IP del contenedor del dashboard: `10.0.2.134`

## 🔧 Pasos

### Paso 1: Probar conexión directa a la IP

```bash
# Probar conexión directa a la IP del dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://10.0.2.134:3000/
```

### Paso 2: Actualizar configuración del proxy con IP directa

```bash
# Obtener ID del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

# Actualizar configuración con la IP directa
docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream 10.0.2.134;/" /etc/nginx/conf.d/default.conf

# Verificar la configuración
docker exec $PROXY_CONTAINER_ID nginx -t

# Recargar nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload
```

### Paso 3: Probar el proxy

```bash
# Probar acceso al proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard-proxy:80/

# Debería devolver HTTP/1.1 200 OK
```

### Paso 4: Si funciona, configurar dominio en EasyPanel

1. Ve a EasyPanel → Servicios → `dashboard`
2. Edita el dominio `dashboard.checkin24hs.com`
3. Cambia el destino a: `http://checkin24hs_dashboard-proxy:80/` o `http://dashboard-proxy:80/`
4. Guarda

---

**Ejecuta los Pasos 1-3. Si el proxy funciona, configura el dominio en EasyPanel (Paso 4).**
