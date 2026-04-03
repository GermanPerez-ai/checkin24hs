# Solución: Error de Certificado SSL

## Problema

Estás accediendo a `https://dashboard.checkin24hs.com` pero Traefik no tiene un certificado SSL válido configurado, por lo que el navegador muestra el error:

- **Error**: `NET::ERR_CERT_AUTHORITY_INVALID`
- **Mensaje**: "La conexión no es privada"

## Solución Rápida: Usar HTTP

Por ahora, accede usando **HTTP** en lugar de HTTPS:

**http://dashboard.checkin24hs.com**

El dashboard funcionará correctamente con HTTP. Solo verás una advertencia de "No seguro" en el navegador, pero funcionará.

## Solución Permanente: Configurar SSL con Let's Encrypt

Para tener HTTPS con un certificado válido, necesitas configurar Let's Encrypt en Traefik.

### Paso 1: Recrear Traefik con ACME (Let's Encrypt)

```bash
# Eliminar Traefik actual
docker service rm traefik

# Crear Traefik con Let's Encrypt
docker service create \
  --name traefik \
  --network xmv09tpxwryie79b0jv531623 \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  traefik:v2.11 \
  --entrypoints.web.address=:80 \
  --entrypoints.websecure.address=:443 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --certificatesresolvers.letsencrypt.acme.email=tu-email@ejemplo.com \
  --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json \
  --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web \
  --log.level=INFO
```

**⚠️ IMPORTANTE**: Reemplaza `tu-email@ejemplo.com` con tu email real.

### Paso 2: Agregar Etiquetas SSL al Servicio Dashboard

```bash
# Actualizar el servicio para usar HTTPS
docker service update \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  checkin24hs_dashboard
```

### Paso 3: Agregar Redirección HTTP a HTTPS (Opcional)

```bash
# Agregar redirección HTTP a HTTPS
docker service update \
  --label-add "traefik.http.routers.dashboard-redirect.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard-redirect.entrypoints=web" \
  --label-add "traefik.http.routers.dashboard-redirect.middlewares=dashboard-redirect" \
  --label-add "traefik.http.middlewares.dashboard-redirect.redirectscheme.scheme=https" \
  --label-add "traefik.http.middlewares.dashboard-redirect.redirectscheme.permanent=true" \
  checkin24hs_dashboard
```

### Paso 4: Verificar

```bash
# Esperar 1-2 minutos para que Let's Encrypt genere el certificado
sleep 60

# Ver logs de Traefik
docker service logs traefik --tail 50 | grep -i acme

# Probar acceso HTTPS
curl -I https://dashboard.checkin24hs.com
```

## Notas Importantes

1. **Let's Encrypt requiere**:
   - El dominio debe estar accesible públicamente (ya lo está)
   - El puerto 80 debe estar abierto (ya lo está)
   - Un email válido para notificaciones

2. **Primera vez**: Let's Encrypt puede tardar 1-2 minutos en generar el certificado

3. **Renovación automática**: Traefik renovará el certificado automáticamente antes de que expire

## Alternativa: Usar HTTP Temporalmente

Si no necesitas HTTPS inmediatamente, puedes usar HTTP:

- **http://dashboard.checkin24hs.com** (sin la 's')

El dashboard funcionará correctamente, solo verás una advertencia de "No seguro" en el navegador.

## Resumen

- ✅ **Solución rápida**: Usa `http://dashboard.checkin24hs.com` (sin HTTPS)
- ⏳ **Solución permanente**: Configurar Let's Encrypt en Traefik para HTTPS válido

Por ahora, simplemente usa **HTTP** y el dashboard funcionará correctamente.


