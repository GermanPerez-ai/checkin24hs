# Solución Rápida: Error 404 en Dashboard

## Problema
- ❌ `GET https://dashboard.checkin24hs.com/ 404 (Not Found)`
- Traefik no está enrutando correctamente al servicio dashboard

## Solución Rápida

Ejecuta estos comandos en el servidor (SSH):

```bash
# 1. Verificar nombre exacto del servicio
docker service ls | grep dashboard

# 2. Agregar etiquetas de Traefik (reemplaza 'checkin24hs_dashboard' con el nombre real)
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard

# 3. Esperar 30 segundos
sleep 30

# 4. Verificar que se agregaron las etiquetas
docker service inspect checkin24hs_dashboard | grep -A 30 Labels

# 5. Verificar logs de Traefik
docker service logs traefik --tail 50 | grep -i dashboard
```

## Si el servicio tiene otro nombre

Si el servicio se llama diferente (por ejemplo `dashboard` sin prefijo), reemplaza `checkin24hs_dashboard` con el nombre real que veas en `docker service ls`.

## Verificar que funcionó

Después de ejecutar los comandos, espera 1-2 minutos y prueba:
- https://dashboard.checkin24hs.com/

Deberías ver el dashboard en lugar del error 404.

## Alternativa: Usar EasyPanel

Si prefieres usar la interfaz de EasyPanel:

1. Ve a EasyPanel → Servicio "dashboard"
2. Ve a la pestaña "Dominios" o "Domains"
3. **Elimina** el dominio `dashboard.checkin24hs.com` si existe
4. **Agrega** el dominio `dashboard.checkin24hs.com` de nuevo
5. Configura:
   - Dominio: `dashboard.checkin24hs.com`
   - Puerto: `3000`
   - Ruta: `/`
6. **Guarda** y espera 1-2 minutos

EasyPanel debería agregar las etiquetas automáticamente.
