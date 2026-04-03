# Flor en la web = misma que WhatsApp

Para que el chatbot de la web use **exactamente** la misma Flor que WhatsApp, la web debe llamar a **flor-api**, que hace proxy al servidor WhatsApp. Si algo falla en esa llamada, el chat usa un fallback local (Gemini/reglas) y **no** es la misma Flor.

## Causas habituales por las que la web no usa la Flor de WhatsApp

1. **Contenido mixto (mixed content)**  
   La web está en **HTTPS** (https://www.checkin24hs.com). Si `VITE_FLOR_API_URL` es **HTTP** (ej. `http://flor-api.checkin24hs.com:8081`), el navegador bloquea la petición y el chat usa el fallback local.

2. **flor-api sin Traefik**  
   Si el servicio `flor-api` no tiene labels de Traefik, `https://flor-api.checkin24hs.com` no llega a flor-api (404). Entonces se usa el puerto 8081 por HTTP → vuelve el problema de contenido mixto.

3. **flor-api no alcanza WhatsApp**  
   flor-api hace proxy a `WHATSAPP_URL` (por defecto `http://whatsapp:3001`). En Swarm el servicio puede llamarse `checkin24hs_whatsapp`; si el nombre es incorrecto, flor-api devuelve 502 y el chat usa fallback.

## Solución recomendada: Flor por HTTPS (sin puerto)

### 1. Que flor-api responda por HTTPS (Traefik)

En el servidor, si el servicio `flor-api` **no** tiene labels de Traefik (como pasó con la web), añadirlos:

```bash
docker service inspect checkin24hs_flor-api --format '{{json .Spec.Labels}}' | jq .
```

Si está vacío `{}`, añadir:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add 'traefik.http.routers.florapi.rule=Host(`flor-api.checkin24hs.com`)' \
  --label-add "traefik.http.routers.florapi.entrypoints=websecure" \
  --label-add "traefik.http.routers.florapi.service=flor-api" \
  --label-add "traefik.http.routers.florapi.tls=true" \
  --label-add "traefik.http.routers.florapi.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.flor-api.loadbalancer.server.port=8080" \
  checkin24hs_flor-api
```

Comprobar:

```bash
curl -sI -k -H "Host: flor-api.checkin24hs.com" https://127.0.0.1:443/health
```

Debe devolver 200 y JSON.

### 2. URL de la API en la web: HTTPS y sin puerto

En **EasyPanel** (app **appwebcheckin24hs**), en variables de entorno:

- **VITE_FLOR_API_URL** = `https://flor-api.checkin24hs.com`  
  (sin `:8081`, con **https**)

Guardar y **Implementar** (redeploy) para que el nuevo build use esa URL. Así la web (HTTPS) llama a flor-api por HTTPS y no hay contenido mixto.

### 3. Que flor-api alcance el servidor WhatsApp

flor-api usa la variable **WHATSAPP_URL** (por defecto `http://whatsapp:3001`). En Swarm, el nombre del servicio suele ser `checkin24hs_whatsapp`.

En EasyPanel (servicio **flor-api**), añadir o editar:

- **WHATSAPP_URL** = `http://checkin24hs_whatsapp:3001`  
  (solo si `http://whatsapp:3001` falla; probar antes con el valor por defecto)

Para probar desde dentro del contenedor flor-api (opcional):

```bash
docker run --rm --network easypanel curlimages/curl:latest curl -s -o /dev/null -w "%{http_code}" http://checkin24hs_whatsapp:3001/
```

Si devuelve 200 o 301, el nombre es correcto. Si no resuelve, usar el nombre que devuelva `docker service ls` para el servicio WhatsApp.

### 4. Comprobar en el navegador

1. Abrí https://www.checkin24hs.com y abrí el chat de Flor.
2. F12 → pestaña **Consola**. Deberías ver algo como:  
   `[Flor AI] 📡 Origen: intentando Flor API (WhatsApp)` y luego  
   `[Flor AI] 🌸 Respuesta desde Flor API (misma que WhatsApp)`.
3. Si aparece `Flor API no alcanzable` o errores de mixed content, la URL sigue siendo HTTP o no llega a flor-api.
4. Enviá un mensaje de prueba (ej. “info de Puyehue”). La respuesta debe ser la misma lógica que en WhatsApp.

## Resumen

| Qué | Valor |
|-----|--------|
| URL que debe usar la web | `https://flor-api.checkin24hs.com` (HTTPS, sin puerto) |
| Variable en la web (build) | `VITE_FLOR_API_URL=https://flor-api.checkin24hs.com` |
| flor-api (Traefik) | Labels para `Host(flor-api.checkin24hs.com)` en entrypoint websecure |
| flor-api → WhatsApp | `WHATSAPP_URL=http://whatsapp:3001` o `http://checkin24hs_whatsapp:3001` |

Así el chatbot de la web usa la **misma** Flor que WhatsApp (mismo `procesarConFlor` en el servidor WhatsApp).
