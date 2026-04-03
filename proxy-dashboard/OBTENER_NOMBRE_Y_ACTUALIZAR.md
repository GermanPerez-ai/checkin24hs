# ✅ Obtener Nombre Completo y Actualizar Dominio

## 📊 Estado Actual

- ✅ Dominio `dashboard.checkin24hs.com` configurado en `dashboard-proxy`
- ❌ Destino apunta a `http://checkin24hs_dashboard-proxy:80/` (alias no se resuelve)
- ✅ Veo un segundo dominio con nombre completo: `checkin24hs_dashboard-proxy.1.tvz60wv...`

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

1. En el servicio `dashboard-proxy`, haz clic en el icono de **lápiz** del dominio `dashboard.checkin24hs.com` (el que tiene la estrella amarilla)
2. En el modal "Actualizar dominio":
   - **Host**: `dashboard.checkin24hs.com` (no cambies)
   - **Ruta (Host)**: `/`
   - **Destino**:
     - **Protocolo**: HTTP
     - **Puerto**: `80`
     - **Ruta**: `/`
   - **IMPORTANTE**: En el campo del destino, reemplaza `checkin24hs_dashboard-proxy` por el nombre completo obtenido en el Paso 1
   
   **Ejemplo**: Si el nombre completo es `checkin24hs_dashboard-proxy.1.tvz60wva...`, el destino debe ser:
   ```
   http://checkin24hs_dashboard-proxy.1.tvz60wva...:80/
   ```
3. Guarda los cambios

### Paso 4: Probar el dominio

1. Espera 30 segundos
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. Debería cargar el dashboard correctamente

---

**Ejecuta primero el Paso 1 para obtener el nombre completo. Luego actualiza el dominio en EasyPanel usando ese nombre completo en el destino.**
