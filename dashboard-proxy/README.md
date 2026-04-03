# 🔧 Servicio Proxy Nginx para Dashboard

Este servicio actúa como proxy para el dashboard, solucionando el problema del DNS cacheado.

## 📁 Estructura

- `Dockerfile`: Imagen nginx simple
- `nginx.conf`: Configuración de nginx (se actualiza automáticamente)
- `update-proxy-config.sh`: Script para actualizar la configuración con el nombre del contenedor actual

## 🚀 Despliegue

### Opción 1: Desplegar desde EasyPanel

1. Ve a EasyPanel → Servicios → Nuevo Servicio
2. Configura:
   - **Nombre**: `dashboard-proxy`
   - **Fuente**: GitHub
   - **Repositorio**: `GermanPerez-ai/checkin24hs`
   - **Rama**: `main`
   - **Build Path**: `/dashboard-proxy`
   - **Dockerfile**: `Dockerfile`
   - **Puerto interno**: `80`
   - **Comando**: (dejar vacío, usa el CMD del Dockerfile)
3. Conecta el servicio a la red `easypanel-checkin24hs`
4. Configura el dominio `dashboard.checkin24hs.com` para apuntar a `http://dashboard-proxy:80/`

### Opción 2: Desplegar Manualmente desde el Servidor

```bash
# 1. Ir al directorio del proxy
cd /path/to/checkin24hs/dashboard-proxy

# 2. Actualizar configuración con el contenedor actual
chmod +x update-proxy-config.sh
./update-proxy-config.sh

# 3. Construir la imagen
docker build -t dashboard-proxy:latest .

# 4. Crear el servicio en Docker Swarm
docker service create \
  --name dashboard-proxy \
  --network easypanel-checkin24hs \
  --publish published=80,target=80 \
  --mount type=bind,source=$(pwd)/nginx.conf,target=/etc/nginx/conf.d/default.conf \
  dashboard-proxy:latest
```

## 🔄 Actualizar Configuración

Cada vez que el contenedor del dashboard se recree, necesitas actualizar la configuración:

```bash
# Desde el servidor, ejecutar:
cd /path/to/checkin24hs/dashboard-proxy
./update-proxy-config.sh

# Luego recargar el servicio proxy
docker service update --force dashboard-proxy
```

### Automatizar Actualización

Puedes crear un cron job para actualizar automáticamente cada minuto:

```bash
# Agregar a crontab
* * * * * cd /path/to/checkin24hs/dashboard-proxy && ./update-proxy-config.sh && docker service update --force dashboard-proxy 2>&1 | logger
```

## ✅ Verificar Funcionamiento

```bash
# Ver logs del proxy
docker service logs dashboard-proxy

# Probar conexión
curl -I http://localhost:80/
```

## 🔧 Configuración del Dominio en EasyPanel

Después de desplegar el servicio proxy:

1. Ve a EasyPanel → Dominios
2. Edita `dashboard.checkin24hs.com`
3. Cambia el destino a: `http://dashboard-proxy:80/`

El proxy ahora actuará como intermediario y siempre apuntará al contenedor activo del dashboard.
