# 📋 Guía de Instalación del Proxy Dashboard

## 🎯 Objetivo

Crear un servicio proxy nginx estable que apunte siempre al contenedor activo del dashboard, resolviendo el problema del DNS cacheado.

## 📝 Pasos de Instalación

### Paso 1: Commit y Push de los Archivos del Proxy

Primero, necesitas hacer commit y push de los archivos del proxy al repositorio:

```bash
# Desde tu máquina local, en el directorio del proyecto
git add proxy-dashboard/
git commit -m "Add proxy nginx service for dashboard"
git push origin main
```

### Paso 2: Desplegar el Proxy en EasyPanel

1. Ve a EasyPanel → Servicios
2. Haz clic en **"Nuevo Servicio"** o **"Add Service"**
3. Configura el servicio:
   - **Nombre**: `dashboard-proxy`
   - **Fuente**: GitHub
   - **Repositorio**: `GermanPerez-ai/checkin24hs`
   - **Rama**: `main`
   - **Build Path**: `/proxy-dashboard`
   - **Dockerfile**: `Dockerfile` (o `proxy-dashboard/Dockerfile` si EasyPanel lo requiere)
   - **Puerto Interno**: `80`
   - **Comando**: (dejar vacío - nginx se inicia automáticamente)

4. Haz clic en **"Deploy"** o **"Implementar"**

5. Espera a que el servicio se construya y despliegue

### Paso 3: Actualizar la Configuración Inicial del Proxy

Una vez que el servicio esté desplegado, necesitas actualizar la configuración con el nombre del contenedor activo del dashboard:

```bash
# En el servidor (SSH), obtener el nombre del contenedor activo del dashboard
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=checkin24hs_dashboard" | head -1)

echo "Contenedor activo del dashboard: $DASHBOARD_CONTAINER"

# Obtener el ID del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=dashboard-proxy" --format "{{.ID}}" | head -1)

echo "Contenedor del proxy: $PROXY_CONTAINER_ID"

# Actualizar la configuración de nginx con el nombre del contenedor activo
docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream $DASHBOARD_CONTAINER;/" /etc/nginx/conf.d/default.conf

# Verificar la configuración
docker exec $PROXY_CONTAINER_ID nginx -t

# Recargar nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload

echo "✅ Configuración actualizada correctamente"
```

### Paso 4: Probar el Proxy

```bash
# Probar acceso al proxy desde dentro de la red
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard-proxy:80/

# Debería devolver HTTP/1.1 200 OK
```

### Paso 5: Configurar el Dominio en EasyPanel

1. Ve a EasyPanel → Dominios
2. Edita el dominio `dashboard.checkin24hs.com`
3. Cambia el destino de `http://dashboard:3000/` a `http://dashboard-proxy:80/`
4. Guarda los cambios

### Paso 6: Verificar que Funciona

1. Abre tu navegador
2. Ve a `https://dashboard.checkin24hs.com/`
3. Debería cargar el dashboard correctamente

## 🔄 Actualización Automática (Opcional)

Si el contenedor del dashboard cambia frecuentemente, puedes configurar un cron job para actualizar automáticamente:

```bash
# Copiar el script de actualización al servidor
scp proxy-dashboard/actualizar-proxy.sh root@srv1152402:/root/

# Dar permisos de ejecución
ssh root@srv1152402 chmod +x /root/actualizar-proxy.sh

# Configurar cron job (actualizar cada 5 minutos)
ssh root@srv1152402 "(crontab -l 2>/dev/null; echo '*/5 * * * * /root/actualizar-proxy.sh >> /var/log/proxy-update.log 2>&1') | crontab -"
```

## 🛠️ Solución de Problemas

### El proxy no responde

1. Verifica que el servicio esté corriendo:
   ```bash
   docker service ps dashboard-proxy
   docker ps | grep dashboard-proxy
   ```

2. Verifica los logs:
   ```bash
   docker service logs dashboard-proxy --tail 50
   ```

3. Verifica que la configuración tenga el nombre correcto:
   ```bash
   docker exec $(docker ps --filter "name=dashboard-proxy" --format "{{.ID}}" | head -1) cat /etc/nginx/conf.d/default.conf | grep backend_upstream
   ```

### El contenedor del dashboard cambió

Ejecuta nuevamente el Paso 3 para actualizar la configuración con el nuevo nombre del contenedor.

### El dominio sigue dando 404

1. Verifica que el dominio en EasyPanel apunte a `http://dashboard-proxy:80/`
2. Reinicia Traefik:
   ```bash
   docker service update --force traefik
   ```

## ✅ Listo

Una vez completados todos los pasos, el dashboard debería funcionar correctamente a través del proxy, resolviendo el problema del DNS cacheado.
