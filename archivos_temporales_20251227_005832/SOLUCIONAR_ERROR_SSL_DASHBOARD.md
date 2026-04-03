# Solucionar Error SSL en Dashboard

## Problema
Chrome muestra `NET::ERR_CERT_AUTHORITY_INVALID` al acceder a `https://dashboard.checkin24hs.com`

## Solución Temporal: Usar HTTP

**Accede usando HTTP en lugar de HTTPS:**
```
http://dashboard.checkin24hs.com
```

## Solución Permanente: Configurar Let's Encrypt en Traefik

### Opción 1: Configurar Let's Encrypt automáticamente en Traefik

1. **Verificar configuración actual de Traefik:**
```bash
docker service inspect traefik | grep -A 20 Args
```

2. **Recrear Traefik con Let's Encrypt:**
```bash
# Eliminar Traefik actual
docker service rm traefik

# Crear Traefik con Let's Encrypt
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --mount type=volume,source=traefik-certificates,target=/letsencrypt \
  traefik:v2.11 \
  --entrypoints.web.address=:80 \
  --entrypoints.websecure.address=:443 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --certificatesresolvers.letsencrypt.acme.tlschallenge=true \
  --certificatesresolvers.letsencrypt.acme.email=tu-email@ejemplo.com \
  --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json \
  --log.level=INFO

# Agregar Traefik a la red easypanel
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
docker service update --network-add $EASYPANEL_NET traefik
```

3. **Actualizar servicio dashboard con certificado SSL:**
```bash
docker service update \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  checkin24hs_dashboard
```

### Opción 2: Configurar SSL en EasyPanel

Si EasyPanel tiene soporte para SSL/Let's Encrypt:
1. Ve a la configuración del servicio `checkin24hs_dashboard` en EasyPanel
2. Busca la opción "SSL" o "Certificados"
3. Activa "Let's Encrypt" o "SSL automático"
4. Guarda y espera a que se genere el certificado

## Verificación

Después de configurar SSL:
1. Espera 2-5 minutos para que Let's Encrypt genere el certificado
2. Accede a `https://dashboard.checkin24hs.com`
3. Deberías ver el candado verde en Chrome

## Nota

- Let's Encrypt requiere que el dominio apunte correctamente al servidor
- El certificado se renueva automáticamente cada 90 días
- Si tienes problemas, verifica los logs: `docker service logs traefik`


