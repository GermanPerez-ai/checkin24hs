# Agregar Etiquetas de Traefik Manualmente

## Problema

- ❌ Las etiquetas siguen vacías después de configurar el dominio en EasyPanel
- ❌ Traefik responde pero devuelve 404 (no encuentra la ruta)
- ⚠️ EasyPanel no está agregando las etiquetas automáticamente

## Solución: Agregar Etiquetas Manualmente

Como EasyPanel no está agregando las etiquetas automáticamente, necesitamos agregarlas manualmente usando `docker service update`.

### Paso 1: Verificar Redes

```bash
# Ver todas las redes
docker network ls

# Ver qué redes son esas IDs
docker network inspect xmv09tpxwryie79b0jv531623 | grep -i name
docker network inspect nvhtv52umzihypz8u7adejvpo | grep -i name

# Ver en qué red está Traefik
docker service inspect traefik | grep -A 10 Networks

# Buscar la red easypanel
docker network ls | grep easypanel
```

### Paso 2: Agregar Etiquetas al Servicio

**IMPORTANTE**: No podemos actualizar etiquetas directamente con `docker service update`. Necesitamos recrear el servicio o usar `docker service update` con `--label-add`.

```bash
# Agregar etiquetas de Traefik al servicio existente
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard
```

### Paso 3: Verificar que las Etiquetas se Agregaron

```bash
# Esperar 10 segundos
sleep 10

# Ver etiquetas del servicio
docker service inspect checkin24hs_dashboard | grep -A 30 Labels
```

Deberías ver las etiquetas de Traefik ahora.

### Paso 4: Verificar que Traefik Detecta el Servicio

```bash
# Esperar 30 segundos más
sleep 30

# Ver logs de Traefik
docker service logs traefik --tail 100 | grep -i dashboard

# Ver todos los logs recientes
docker service logs traefik --tail 50
```

Deberías ver mensajes sobre el servicio dashboard.

### Paso 5: Probar Acceso

```bash
# Probar acceso HTTP
curl -I http://dashboard.checkin24hs.com

# Ver respuesta completa
curl -v http://dashboard.checkin24hs.com 2>&1 | head -20
```

Deberías recibir una respuesta HTTP 200 ahora.

## Si el Servicio No Está en la Red Correcta

Si el servicio no está en la misma red que Traefik, necesitas agregarlo:

```bash
# Obtener ID de la red easypanel
EASYPANEL_NET=$(docker network ls | grep easypanel | awk '{print $1}')

# Agregar el servicio a la red easypanel
docker service update --network-add $EASYPANEL_NET checkin24hs_dashboard
```

## Resolver Conflicto de Puerto

El servicio tiene `PORT=80` y `PORT=3000` en las variables de entorno. Solo debería tener `PORT=3000`.

```bash
# Ver variables de entorno actuales
docker service inspect checkin24hs_dashboard | grep -A 10 Env

# Actualizar para eliminar PORT=80 (si es necesario)
docker service update --env-rm "PORT=80" checkin24hs_dashboard
```

## Comando Completo (Todo en Uno)

```bash
# 1. Agregar etiquetas de Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard

# 2. Esperar 30 segundos
sleep 30

# 3. Verificar etiquetas
docker service inspect checkin24hs_dashboard | grep -A 30 Labels

# 4. Ver logs de Traefik
docker service logs traefik --tail 100 | grep -i dashboard

# 5. Probar acceso
curl -I http://dashboard.checkin24hs.com
```

## Notas

- `docker service update` puede causar un breve reinicio del servicio
- Las etiquetas se aplican inmediatamente, pero Traefik puede tardar unos segundos en detectarlas
- Si el servicio no está en la red correcta, Traefik no podrá acceder a él


