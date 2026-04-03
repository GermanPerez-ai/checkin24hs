# Para Kodee: ruta del backend y labels ajustados

## 1) Ruta exacta del backend (caso 2: POST /api/send)

En **whatsapp-server/whatsapp-server-baileys.js**:

```javascript
app.post('/api/send', async (req, res) => { ... });   // línea 2827
app.post('/api/send-audio', ...);                      // línea 2863
```

OPTIONS lo atiende un middleware CORS global (`if (req.method === 'OPTIONS') return res.status(204).end()`) y además `app.options('*', ...)`.

**Conclusión:** backend expone **POST /api/send** (y OPTIONS). No usamos stripPrefix; sí usamos **PathPrefix(`/api`)** en el router para que Traefik enrute correctamente.

---

## 2) Bloque de labels actual (tras ajuste con PathPrefix)

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=easypanel"
  # Router: Host + PathPrefix /api (Kodee: así Traefik encuentra el servicio para /api/send)
  - "traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`) && PathPrefix(`/api`)"
  - "traefik.http.routers.whatsapp.entrypoints=websecure"
  - "traefik.http.routers.whatsapp.service=whatsapp"
  - "traefik.http.routers.whatsapp.tls=true"
  - "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt"
  - "traefik.http.routers.whatsapp.middlewares=whatsapp-cors"
  # Router con nombre Swarm (stack_servicio)
  - "traefik.http.routers.checkin24hs_whatsapp.rule=Host(`whatsapp.checkin24hs.com`) && PathPrefix(`/api`)"
  - "traefik.http.routers.checkin24hs_whatsapp.entrypoints=websecure"
  - "traefik.http.routers.checkin24hs_whatsapp.service=whatsapp"
  - "traefik.http.routers.checkin24hs_whatsapp.tls=true"
  - "traefik.http.routers.checkin24hs_whatsapp.tls.certresolver=letsencrypt"
  - "traefik.http.routers.checkin24hs_whatsapp.middlewares=whatsapp-cors"
  # CORS
  - "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowmethods=GET,POST,OPTIONS"
  - "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolallowheaders=Content-Type,Authorization,Accept"
  - "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolalloworiginlist=https://dashboard.checkin24hs.com"
  - "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Origin=https://dashboard.checkin24hs.com"
  - "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Methods=GET, POST, OPTIONS"
  - "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Headers=Content-Type, Authorization, Accept"
  - "traefik.http.middlewares.whatsapp-cors.headers.customresponseheaders.Access-Control-Allow-Credentials=true"
  - "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolmaxage=86400"
  - "traefik.http.middlewares.whatsapp-cors.headers.addvaryheader=true"
  - "traefik.http.services.whatsapp.loadbalancer.server.port=3001"
```

---

## 3) Curl a ejecutar en el VPS (después de cambios)

```bash
# Debe dejar de devolver 404 (puede ser 405, 400, etc.)
curl -i "https://whatsapp.checkin24hs.com/api/send"
```

Resultado actual: Si hacés GET (curl sin -X), es normal ver "Cannot GET /api/send" (Express). La ruta es POST. Probá OPTIONS y POST para confirmar CORS y envío.

---

## Si sigue 404 después del redeploy

El mensaje `404 page not found` (text/plain) suele ser de **Traefik**: ningún router está coincidiendo con la petición. Eso puede ser porque:

1. **El redeploy no usó el compose actualizado** (sin PathPrefix y routers) o EasyPanel no leyó los labels.
2. **El dominio whatsapp.checkin24hs.com está asignado en EasyPanel a otra app/proxy** (no al stack que tiene este servicio WhatsApp), así que las peticiones no pasan por los labels de nuestro servicio.
3. **El nombre del servicio en Swarm es otro** (p. ej. no es `checkin24hs_whatsapp`).

**En el servidor, ejecutá:**

```bash
cd ~/checkin24hs   # o la ruta del repo
bash scripts/diagnostico_404_whatsapp.sh
```

Eso muestra qué servicios hay, qué labels Traefik tienen y qué revisar en EasyPanel.

**Para ver los labels del servicio a mano:**

```bash
docker service ls | grep -i whatsapp
docker service inspect checkin24hs_whatsapp --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}
{{end}}' | grep traefik
```

Si no aparece ningún label `traefik.http.routers.whatsapp.rule` (o similar), el servicio **no tiene** la config de Traefik (EasyPanel a veces no aplica los labels del compose). En ese caso aplicá los labels a mano en el servidor:

```bash
cd ~/checkin24hs
git pull origin main
bash scripts/aplicar_traefik_whatsapp_servidor.sh
```

Ese script aplica todos los labels (routers con PathPrefix `/api`, CORS, servicio puerto 3001). Si el repo no tiene el script, copiá el contenido de `scripts/aplicar_traefik_whatsapp_servidor.sh` del repo en tu PC y creá el archivo en el servidor, luego `chmod +x` y ejecutalo.

Después de ejecutarlo, esperá ~10 s y probá de nuevo: `curl -i "https://whatsapp.checkin24hs.com/api/send"` (debe dejar de dar 404).

---

## 4) Curl OPTIONS (después de que /api/send deje de dar 404)

```bash
curl -i -X OPTIONS "https://whatsapp.checkin24hs.com/api/send" \
  -H "Origin: https://dashboard.checkin24hs.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type, Authorization"
```

Objetivo: respuesta con HTTP/2 204 y cabeceras CORS (Allow-Origin, Allow-Methods, Allow-Headers, Allow-Credentials).
