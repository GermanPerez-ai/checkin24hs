# Agregar Etiquetas de Traefik Manualmente

## Problema Detectado

- ❌ El servicio `checkin24hs_dashboard` **NO tiene etiquetas de Traefik** (`"Labels": {}` está vacío)
- ❌ Traefik **NO detecta** el servicio dashboard
- ⚠️ Conflicto de puerto: `PORT=80` y `PORT=3000` en las variables de entorno

## Solución: Agregar Etiquetas de Traefik

EasyPanel debería agregar estas etiquetas automáticamente cuando configuras el dominio, pero como no lo hizo, podemos agregarlas manualmente.

### Paso 1: Verificar Redes

```bash
# Ver todas las redes
docker network ls

# Ver qué redes son esas IDs
docker network inspect xmv09tpxwryie79b0jv531623 | grep -i name
docker network inspect nvhtv52umzihypz8u7adejvpo | grep -i name

# Ver en qué red está Traefik
docker service inspect traefik | grep -A 10 Networks
```

### Paso 2: Identificar la Red de EasyPanel

El servicio debe estar en la misma red que Traefik. Busca la red llamada "easypanel":

```bash
docker network ls | grep easypanel
```

### Paso 3: Actualizar el Servicio con Etiquetas de Traefik

**IMPORTANTE**: No podemos actualizar etiquetas de un servicio existente directamente. Necesitamos recrearlo o usar EasyPanel.

#### Opción A: Usar EasyPanel (Recomendado)

1. Ve a EasyPanel: http://72.61.58.240:3000
2. Ve al servicio "dashboard"
3. Ve a la pestaña **"Dominios"**
4. **Elimina** el dominio `dashboard.checkin24hs.com` si existe
5. **Agrega** el dominio `dashboard.checkin24hs.com` de nuevo
6. **Guarda** los cambios
7. Espera 1-2 minutos

EasyPanel debería agregar automáticamente las etiquetas necesarias.

#### Opción B: Recrear el Servicio con Etiquetas (Si EasyPanel no funciona)

```bash
# 1. Obtener configuración actual
docker service inspect checkin24hs_dashboard > /tmp/dashboard-config.json

# 2. Ver la imagen exacta
docker service inspect checkin24hs_dashboard | grep Image

# 3. Ver el puerto interno del servicio
docker service inspect checkin24hs_dashboard | grep -A 5 Ports

# 4. Identificar la red easypanel
EASYPANEL_NET=$(docker network ls | grep easypanel | awk '{print $1}')

# 5. Eliminar el servicio actual
docker service rm checkin24hs_dashboard

# 6. Crear el servicio con etiquetas de Traefik
docker service create \
  --name checkin24hs_dashboard \
  --network $EASYPANEL_NET \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --env "PORT=3000" \
  --publish 3000:3000 \
  easypanel/checkin24hs/dashboard
```

**⚠️ ADVERTENCIA**: Esta opción puede causar problemas si EasyPanel gestiona el servicio. Es mejor usar EasyPanel.

### Paso 4: Verificar que Funciona

```bash
# Esperar 30 segundos
sleep 30

# Ver si Traefik detecta el servicio
docker service logs traefik --tail 100 | grep -i dashboard

# Ver etiquetas del servicio
docker service inspect checkin24hs_dashboard | grep -A 30 Labels

# Probar acceso
curl -I http://dashboard.checkin24hs.com
```

## Etiquetas Necesarias

Traefik necesita estas etiquetas para enrutar el tráfico:

```yaml
traefik.enable=true
traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`)
traefik.http.routers.dashboard.entrypoints=web
traefik.http.services.dashboard.loadbalancer.server.port=3000
```

## Verificar Configuración en EasyPanel

Si EasyPanel no está agregando las etiquetas automáticamente:

1. Ve a EasyPanel
2. Ve al servicio "dashboard"
3. Ve a "Dominios"
4. Verifica que el dominio esté configurado correctamente:
   - Dominio: `dashboard.checkin24hs.com`
   - Puerto destino: `3000`
   - Ruta: `/`
5. Guarda los cambios
6. Espera 1-2 minutos

## Resolver Conflicto de Puerto

El servicio tiene `PORT=80` y `PORT=3000` en las variables de entorno. Solo debería tener `PORT=3000`.

En EasyPanel:
1. Ve al servicio "dashboard"
2. Ve a "Variables de Entorno"
3. Elimina `PORT=80` si existe
4. Asegúrate de que solo esté `PORT=3000`
5. Guarda y redespliega


