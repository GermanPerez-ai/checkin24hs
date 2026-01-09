# Proxy Nginx para Dashboard

Este servicio actúa como proxy entre el dominio público y el contenedor del dashboard, resolviendo el problema del DNS cacheado.

## Características

- ✅ Usa resolver DNS dinámico de Docker
- ✅ Actúa como intermediario estable con nombre fijo
- ✅ Se puede actualizar cuando cambia el contenedor del dashboard

## Cómo Funciona

El proxy nginx usa el resolver DNS de Docker (`127.0.0.11`) para resolver dinámicamente el nombre del contenedor del dashboard. Cuando el contenedor del dashboard cambia, puedes ejecutar el script `actualizar-proxy.sh` para actualizar la configuración.

## Instalación y Despliegue

### Paso 1: Desplegar el Proxy en EasyPanel

1. En EasyPanel, crea un **nuevo servicio**:
   - Nombre: `dashboard-proxy`
   - Fuente: GitHub
   - Repositorio: `GermanPerez-ai/checkin24hs`
   - Rama: `main`
   - Build Path: `/proxy-dashboard`
   - Dockerfile: `Dockerfile`
   - Puerto interno: `80`

2. **No configures dominio todavía** - primero necesitamos actualizar la configuración

### Paso 2: Actualizar la Configuración Inicial

Después de desplegar el proxy, necesitas actualizar la configuración con el nombre del contenedor activo:

```bash
# En el servidor, ejecuta el script de actualización
cd /ruta/a/proxy-dashboard
chmod +x actualizar-proxy.sh
./actualizar-proxy.sh
```

O manualmente:

```bash
# Obtener el nombre del contenedor activo del dashboard
DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=checkin24hs_dashboard" | head -1)

# Obtener el ID del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=dashboard-proxy" --format "{{.ID}}" | head -1)

# Actualizar la configuración
docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream $DASHBOARD_CONTAINER;/" /etc/nginx/conf.d/default.conf

# Recargar nginx
docker exec $PROXY_CONTAINER_ID nginx -s reload
```

### Paso 3: Configurar el Dominio en EasyPanel

1. Ve a EasyPanel → Dominios
2. Edita `dashboard.checkin24hs.com`
3. Cambia el destino a: `http://dashboard-proxy:80/`

### Paso 4: Verificar que Funciona

```bash
# Probar acceso al proxy
curl -I http://dashboard-proxy:80/

# Ver logs del proxy
docker service logs dashboard-proxy
```

## Actualización Automática (Opcional)

Si el contenedor del dashboard cambia frecuentemente, puedes configurar un cron job para actualizar automáticamente:

```bash
# Agregar al crontab (actualizar cada 5 minutos)
*/5 * * * * /ruta/a/proxy-dashboard/actualizar-proxy.sh >> /var/log/proxy-update.log 2>&1
```

## Solución de Problemas

### El proxy no funciona

1. Verifica que el servicio esté corriendo:
   ```bash
   docker service ps dashboard-proxy
   ```

2. Verifica los logs:
   ```bash
   docker service logs dashboard-proxy --tail 50
   ```

3. Verifica que la configuración tenga el nombre correcto del contenedor:
   ```bash
   docker exec $(docker ps --filter "name=dashboard-proxy" --format "{{.ID}}" | head -1) cat /etc/nginx/conf.d/default.conf | grep backend_upstream
   ```

### El contenedor del dashboard cambió

Ejecuta el script de actualización:
```bash
./actualizar-proxy.sh
```

O manualmente (ver Paso 2 arriba).

## Estructura de Archivos

```
proxy-dashboard/
├── Dockerfile              # Dockerfile para construir la imagen
├── nginx.conf              # Configuración de nginx
├── actualizar-proxy.sh     # Script para actualizar la configuración
└── README.md               # Este archivo
```
