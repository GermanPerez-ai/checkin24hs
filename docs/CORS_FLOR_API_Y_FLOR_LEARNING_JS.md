# CORS flor-api y error response_length (flor-learning-system.js)

## Problemas

1. **CORS**: El navegador bloquea `POST https://flor-api.checkin24hs.com/api/flor/process` desde `https://www.checkin24hs.com` porque el preflight (OPTIONS) no recibe `Access-Control-Allow-Origin`.
2. **response_length**: Supabase devuelve 400: *"Could not find the 'response_length' column of 'flor_interactions'"* porque en tu proyecto Supabase la tabla no tiene esa columna (o el JS antiguo la envía).

### Arreglo rápido para response_length (sin tocar la web)

Ejecutá en Supabase (SQL Editor) la migración **031_flor_interactions_response_length_if_missing.sql**: añade la columna `response_length` si no existe. Así el JS antiguo (v=3.0.0) deja de dar 400 de inmediato.

## Soluciones aplicadas en el repo

### CORS flor-api

- En **flor-web-api/server.js** el middleware CORS ya está primero y responde OPTIONS con 204 y los headers.
- En **docker-compose.easypanel.yml** se añadió el middleware Traefik **florapi-cors** para que Traefik también envíe los headers CORS en las respuestas de flor-api (por si el preflight no llega al Node).

Para que Traefik use el nuevo middleware hay que **actualizar el servicio flor-api** con los labels. En el servidor:

```bash
docker service update \
  --label-add "traefik.http.routers.florapi.middlewares=florapi-cors" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolallowmethods=GET,POST,OPTIONS" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolallowheaders=Content-Type,Authorization,Accept" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolalloworiginlist=https://www.checkin24hs.com,https://checkin24hs.com" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.accesscontrolmaxage=86400" \
  --label-add "traefik.http.middlewares.florapi-cors.headers.addvaryheader=true" \
  checkin24hs_flor-api
```

O bien: en EasyPanel, redeploy del servicio **flor-api** desde el compose (tras `git pull`) para que tome los labels del `docker-compose.easypanel.yml`.

**Comprobar si el backend recibe OPTIONS:** desde tu PC o el servidor:
```bash
curl -sI -X OPTIONS -H "Origin: https://www.checkin24hs.com" https://flor-api.checkin24hs.com/api/flor/process
```
Si en la respuesta aparece **`Access-Control-Allow-Origin`** y **`X-Flor-API: 1`**, la petición llegó al Node (flor-web-api). Si no aparecen, OPTIONS no está llegando al backend (Traefik/proxy) o flor-api corre una imagen vieja sin CORS.

### response_length y flor-learning-system.js?v=3.0.1

- En el repo, **flor-learning-system.js** ya no inserta la columna `response_length` en Supabase (solo en `checkin24hs-web/public/flor-learning-system.js`).
- **flor-chatbot.html** carga el script con `?v=3.0.1` para forzar recarga.

Si en el navegador seguís viendo `flor-learning-system.js?v=3.0.0` y el error de `response_length`, es que **la web que sirve www.checkin24hs.com** sigue siendo un build antiguo.

En el servidor tenés dos servicios que pueden servir la web:

- **checkin24hs_web** (imagen `easypanel/checkin24hs/web:latest`)
- **checkin24hs_appwebcheckin24hs** (imagen `easypanel/checkin24hs/appwebcheckin24hs`)

Quien tenga los labels de Traefik para `www.checkin24hs.com` es el que responde. Para que se sirva el JS nuevo:

1. **Construir la imagen desde checkin24hs-web** (donde está el fix y `flor-chatbot.html` con v=3.0.1):
   ```bash
   cd ~/checkin24hs && git pull
   cd checkin24hs-web
   docker build -t easypanel/checkin24hs/web:latest .
   # Si en producción usás appwebcheckin24hs para www:
   # docker build -t easypanel/checkin24hs/appwebcheckin24hs:latest .
   ```

2. **Actualizar el servicio que sirve www** (el que tenga el router de www en Traefik):
   ```bash
   docker service update --image easypanel/checkin24hs/web:latest checkin24hs_web
   # o, si www va por appwebcheckin24hs:
   # docker service update --image easypanel/checkin24hs/appwebcheckin24hs:latest checkin24hs_appwebcheckin24hs
   ```

3. Probar en **ventana de incógnito** o con caché desactivada; el script debe cargarse como `flor-learning-system.js?v=3.0.1` y no debe aparecer el error de `response_length`.

## Script todo-en-uno (servidor)

Para aplicar CORS en flor-api y actualizar la web con el JS corregido en un solo paso:

```bash
cd ~/checkin24hs && git pull && bash scripts/arreglar_cors_y_flor_learning_servidor.sh
```

El script: aplica los labels CORS a `checkin24hs_flor-api`, construye la imagen `web` desde `checkin24hs-web` y actualiza `checkin24hs_web` y `checkin24hs_appwebcheckin24hs`. Si la web usa variables de entorno en el build (VITE_*), construí la imagen desde EasyPanel o pasando los ARG; en ese caso ejecutá solo el paso 1 (CORS) y el redeploy de la web desde EasyPanel.

## Resumen

| Qué | Dónde | Acción en servidor |
|-----|--------|---------------------|
| CORS flor-api | Traefik + Express | `docker service update` con labels de florapi-cors en `checkin24hs_flor-api`, o redeploy flor-api desde compose |
| response_length / JS 3.0.1 | Web (checkin24hs-web) | Build desde `checkin24hs-web`, actualizar imagen del servicio que sirve www (web o appwebcheckin24hs) |
