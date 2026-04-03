# Resumen: situación actual del dashboard (Build #77)

## Qué pasa ahora

- **En el repo:** El dashboard tiene **Build #77** (`dashboard.html`, `deploy/dashboard.html`, `deploy/dashboard-html/BUILD_ID`, Dockerfile).
- **En el servidor:** El servicio `checkin24hs_dashboard` corre en Docker Swarm (EasyPanel). A veces el contenedor sirve **#77** y a veces **#5**.
- **En el navegador:** A veces ves **Build #77** y a veces **Build #5** (sobre todo si cerraste sesión y volvés a entrar, o si abrís en navegador normal).

---

## Por qué vuelve a #5

1. **EasyPanel hace otro build**  
   Cuando hacés algo en EasyPanel (guardar, réplicas 0→1, etc.), puede dispararse **otro build**. Ese build suele usar **caché** y genera una imagen vieja (Build #5). El servicio pasa a usar esa imagen y volvés a ver #5.

2. **No hay bind mount**  
   Ya comprobamos por SSH: el servicio **no** tiene bind mount. El contenedor usa solo la **imagen**. Si la imagen que usa el servicio es la vieja (#5), ves #5.

3. **Caché del navegador**  
   Si el servidor ya tiene #77 pero en el navegador normal ves #5, puede ser **caché**: el navegador guardó una versión vieja. En incógnito o después de borrar datos del sitio deberías ver #77.

---

## Qué hicimos para que funcione

1. **BUILD_ID**  
   En `deploy/dashboard-html/` agregamos el archivo `BUILD_ID` (número 77) y en el Dockerfile lo copiamos **antes** de `dashboard.html`. Así, cuando cambies el build (78, 79…), la caché de Docker se invalida y se vuelve a copiar el HTML correcto.

2. **No usar réplicas 0→1 en EasyPanel**  
   Si en EasyPanel ponés réplicas en 0, guardás, volvés a 1 y guardás, EasyPanel puede hacer **otro build** (con caché) y la imagen vuelve a #5. Para “refrescar” el contenedor hay que hacerlo **por SSH** con `docker service update --force`, no desde la UI.

3. **Cabeceras anti-caché**  
   El servidor del dashboard envía `Cache-Control: no-store` para el HTML y `supabase-client.js`, para que el navegador no guarde una versión vieja.

4. **Documentación**  
   En **docs/EASYPANEL_TRAEFIK_SIN_MANUAL.md** está el flujo: forzar reconstrucción (o truco Ruta de compilación), no usar 0→1 en EasyPanel, verificar build por SSH, comprobar bind mount si sigue volviendo a #5.

---

## BUILD_ID: forzar imagen nueva en cada deploy

Para que EasyPanel **siempre** construya una imagen nueva y no reutilice caché (#5):

- **Si desplegás desde el compose** (`docker-compose.easypanel.yml`): en el compose el dashboard tiene `build.args.BUILD_ID: "77"`. **Subí ese número en cada deploy** (78, 79, 80…), hacé `git commit` y `git push`. Así, aunque EasyPanel use caché, un ARG distinto obliga a construir una imagen nueva.
- **Si desplegás solo desde Git** (sin compose): subí el número en el archivo `deploy/dashboard-html/BUILD_ID` (77 → 78 → …) y en `dashboard.html` (`DASHBOARD_BUILD_NUMBER` y el texto "Build #77"), luego `git push`.

En ambos casos, **no** uses réplicas 0→1 en EasyPanel; para refrescar el contenedor usá por SSH: `docker service update --force checkin24hs_dashboard`.

---

## Qué hacer después de cada deploy del dashboard

1. **En EasyPanel**  
   Truco de **Ruta de compilación** (si querés forzar que tome el repo actual): borrá `/`, guardá, volvé a poner `/`, guardá. Después **Implementar** (Deploy). **No** cambies réplicas a 0 y de nuevo a 1.

2. **Cuando termine el build, por SSH** ejecutá estos dos comandos:
   ```bash
   # Labels de Traefik (para que no dé 404)
   docker service update --label-add "traefik.enable=true" --label-add "traefik.docker.network=easypanel" --label-add 'traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`)' --label-add "traefik.http.routers.dashboard.entrypoints=websecure" --label-add "traefik.http.routers.dashboard.service=dashboard" --label-add "traefik.http.routers.dashboard.tls=true" --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" checkin24hs_dashboard

   # Que el servicio use la imagen que acabas de construir (#77)
   docker service update --force checkin24hs_dashboard
   ```

3. **Comprobar**  
   Por SSH:  
   `CID=$(docker ps -q --filter "name=checkin24hs_dashboard" | head -1); docker exec $CID grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' /app/dashboard.html`  
   Debe mostrar **77**.  
   En el navegador: abrí **https://dashboard.checkin24hs.com** en **incógnito** y verificá que diga **Build #77**.

---

## Si ves #5 de nuevo

- **En incógnito también #5:** El contenedor volvió a la imagen vieja. Ejecutá por SSH los dos `docker service update` (labels + `--force`) de arriba.
- **En incógnito #77, en navegador normal #5:** Es **caché del navegador**. Borrá datos del sitio (candado/info en la barra de direcciones → Borrar datos) o **Ctrl+Shift+R** en la página del dashboard.
- **404 en dashboard.checkin24hs.com:** EasyPanel borró los labels de Traefik. Ejecutá por SSH el primer `docker service update` (el de los labels); está en **docs/TRAEFIK_DASHBOARD_WHATSAPP_COMANDOS.md**.

---

## Flujo recomendado por deploy (resumen Kodee)

1. Subís cambios de código.
2. **Si usás compose:** Subís `BUILD_ID` en `docker-compose.easypanel.yml` (ej. `"78"`) y, si querés que coincida el número visible, también en `dashboard.html` (DASHBOARD_BUILD_NUMBER y "Build #78") y en `deploy/dashboard-html/BUILD_ID`. **Si solo Git:** Subís el número en `deploy/dashboard-html/BUILD_ID` y en `dashboard.html`.
3. `git commit` y `git push`.
4. En EasyPanel → app dashboard → **Redeploy** (desde repo o desde compose). **No** toques réplicas.
5. En el servidor (opcional pero recomendado): `docker service update --force checkin24hs_dashboard`.
6. En el navegador: probá en **incógnito** o borrá datos del sitio `dashboard.checkin24hs.com`.

---

## Diagnóstico: ¿imagen o caché? (build_id.txt)

En la imagen del dashboard se escribe el **BUILD_ID** en `/app/build_id.txt` y el servidor lo sirve en **https://dashboard.checkin24hs.com/build_id.txt** (sin caché).

- **Nombre del servicio en Docker Swarm / EasyPanel:** `checkin24hs_dashboard` (EasyPanel suele prefijar con el proyecto, ej. checkin24hs_dashboard).
- Después de un deploy, abrí en el navegador: **https://dashboard.checkin24hs.com/build_id.txt**
  - Si ves el **número nuevo** (ej. 77, 78): la imagen/contenedor está bien; si la UI sigue mostrando Build #5, es **caché del front** (HTML/JS). Probá incógnito o borrar datos del sitio.
  - Si ves un **número viejo** o **404**: el problema es de imagen/contenedor (EasyPanel no usó la imagen nueva; hacé `docker service update --force checkin24hs_dashboard` por SSH).

---

## Referencias en el repo

- **docs/EASYPANEL_TRAEFIK_SIN_MANUAL.md** — Flujo EasyPanel, Build #77, 404, bind mount, Redeploy from Compose.
- **docs/TRAEFIK_DASHBOARD_WHATSAPP_COMANDOS.md** — Comandos `docker service update` para labels (dashboard y WhatsApp).
- **docs/EASYPANEL_DASHBOARD_GIT_FLUJO.md** — Dashboard desde Git sin bind mounts.
- **docker-compose.easypanel.yml** — Labels de Traefik, `update_config` y **build.args.BUILD_ID** del dashboard.
