# Diagnóstico: por qué la web no muestra los cambios

Ejecutá estos comandos **en el servidor** (SSH) y guardá la salida.

## 1. ¿El repo en el servidor tiene el código nuevo?

```bash
cd /root/checkin24hs
git log -1 --oneline
grep -l "carouselTrack\|carrusel" checkin24hs-web/src/components/Novedades.tsx checkin24hs-web/src/components/Novedades.module.css 2>/dev/null && echo "OK: archivos con carrusel" || echo "FALTA: no están los archivos del carrusel"
```

Si sale "FALTA", hacé `git pull origin main` y volvé a probar.

---

## 2. ¿La imagen que usa el servicio tiene el código nuevo?

Después de correr `deploy_web_servidor.sh`, ejecutá:

```bash
# Ver qué imagen está usando el servicio que suele tener el dominio (EasyPanel)
docker service inspect checkin24hs_appwebcheckin24hs --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'

# Crear un contenedor temporal con esa imagen y buscar "carrusel" en los estáticos
IMG=$(docker service inspect checkin24hs_appwebcheckin24hs --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
docker run --rm "$IMG" grep -r "carrusel" /usr/share/nginx/html/ 2>/dev/null | head -5 || echo "No se encontró 'carrusel' en la imagen"
```

Si sale "No se encontró 'carrusel'", la imagen que está en producción **no** incluye el código nuevo.

---

## 3. ¿Qué servicio atiende www.checkin24hs.com?

En el servidor, si tenés curl:

```bash
curl -sI https://www.checkin24hs.com | head -5
```

En Traefik/EasyPanel, revisá qué servicio tiene la regla `Host(\`www.checkin24hs.com\`)`.

---

## 3b. ¿La web en vivo devuelve el código nuevo? (si sigue igual)

Ejecutá en el servidor. Si sale "NO tiene carrusel", el tráfico de www no viene de nuestra imagen nueva (otro servicio, CDN o caché).

```bash
curl -sL https://www.checkin24hs.com -o /tmp/home.html
JSURL=$(grep -oE 'src="/assets/[^"]+\.js"' /tmp/home.html | head -1 | sed 's/src="//;s/"//')
echo "JS: $JSURL"
if [ -n "$JSURL" ]; then
  curl -sL "https://www.checkin24hs.com$JSURL" | grep -q "carrusel" && echo "SI: el JS en vivo tiene carrusel" || echo "NO: el JS en vivo NO tiene carrusel"
else
  echo "No se encontro script en el HTML"
fi
```

---

## 3c. Qué servicio tiene la RUTA (router) de www (no CORS)

Solo el router rule importa. Ejecutar y ver cual tiene "routers.*.rule" con www:

```bash
for s in checkin24hs_web checkin24hs_appwebcheckin24hs; do
  echo "=== $s ==="
  docker service inspect "$s" --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep "router.*rule"
done
```

## 3d. Contenido que sirven los contenedores (sin pasar por Traefik)

Si los contenedores sirven el JS nuevo pero la web en vivo no, el problema es cache o Traefik.

**Nota:** Desde otro contenedor, el nombre de servicio (`checkin24hs_web`) a veces devuelve HTTP 000 (fallo de red/VIP en Swarm). Para comprobar el contenido, usar la IP del contenedor o ejecutar desde dentro del mismo:

```bash
# Obtener IP del task de checkin24hs_web y pedir el HTML + JS
CID=$(docker ps -q --filter "name=checkin24hs_web.1")
IP=$(docker inspect "$CID" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "Contenedor web: $IP"
docker run --rm --network easypanel curlimages/curl:latest sh -c '
  HTML=$(curl -sL --compressed "http://'"$IP"'/")
  JSURL=$(echo "$HTML" | grep -oE "/assets/index-[^\"]+\.js" | head -1)
  [ -n "$JSURL" ] && curl -sL --compressed "http://'"$IP"'$JSURL" | grep -q "carrusel" && echo "SI carrusel" || echo "NO carrusel"
'
# Alternativa: desde dentro del contenedor web
docker exec "$CID" wget -qO- http://127.0.0.1/ 2>/dev/null | grep -oE "index-[^\"]+\.js" | head -1
docker exec "$CID" wget -qO- http://127.0.0.1/assets/index-*.js 2>/dev/null | grep -q "carrusel" && echo "Desde dentro: SI carrusel" || echo "Desde dentro: NO"
```

---

## 4. Build manual paso a paso (para ver si falla)

```bash
cd /root/checkin24hs
git pull origin main
cd checkin24hs-web
docker build --no-cache -t test-web:local .
```

Si acá falla (por ejemplo en `npm run build`), copiá el error. Suele faltar `VITE_SUPABASE_URL` o `VITE_SUPABASE_ANON_KEY`.

---

## 5. Variables de build

La web necesita estas variables en el build. Si no están, el build puede fallar o EasyPanel puede estar usando otra configuración:

- VITE_SUPABASE_URL
- VITE_SUPABASE_ANON_KEY

En el servidor, si usás el compose:

```bash
cd /root/checkin24hs
grep -E "VITE_|SUPABASE" .env 2>/dev/null || echo "No hay .env con VITE_"
```

Si el build de la web se hace desde EasyPanel, las variables tienen que estar en el panel de esa app. Si el build termina bien pero el sitio no cambia: probar en incognito o Ctrl+Shift+R; si sigue igual, en EasyPanel revisar que la app de www use la imagen easypanel/checkin24hs/web:latest o el mismo repo que el servidor.
