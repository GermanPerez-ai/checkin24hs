# Evitar configurar Traefik a mano en cada redeploy (EasyPanel)

## Flujo automático (recomendado)

1. **Red:** El servicio de Traefik/EasyPanel debe usar la misma red **easypanel** (normalmente ya existe).
2. **Deploy from Compose:** En EasyPanel, para la app, usar siempre **Deploy / Redeploy from Compose** apuntando a **`docker-compose.easypanel.yml`** (o al repo con este compose). **No editar labels a mano** en la interfaz.
3. **Cada cambio de código:** `git push` → en EasyPanel hacés **Redeploy** → Traefik vuelve a leer los mismos labels del compose.

Los labels están en **`docker-compose.easypanel.yml`** (raíz del repo). Incluye:
- **dashboard.checkin24hs.com** (puerto 3000)
- **whatsapp.checkin24hs.com** (puerto 3001)
- **cotizar.checkin24hs.com** (puerto 80)
- **webmail.checkin24hs.com** (puerto 80)

Para **cotizador** el compose construye con `Dockerfile.cotizador`; para **webmail** usa `roundcube/roundcubemail:1.6.11-apache`. Si en EasyPanel usás otra imagen, reemplazá la línea `image:` (o el bloque `build`) por lo que corresponda.

---

## Cómo verificar qué imagen usa cada servicio

Conectate por **SSH al VPS** donde corre EasyPanel y ejecutá:

```bash
# Ver contenedores y la imagen que usa cada uno
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

Para filtrar solo los de checkin24hs (nombres suelen llevar "checkin24hs" o "cotizador", "webmail", etc.):

```bash
docker ps -a --format "table {{.Names}}\t{{.Image}}" | grep -E "cotizador|webmail|dashboard|whatsapp|checkin24hs"
```

Para listar **imágenes** que tengan "cotizador" o "webmail" en el nombre:

```bash
docker images | grep -E "cotizador|webmail|roundcube|checkin24hs"
```

Así ves el nombre exacto de la imagen que está usando cada contenedor; ese nombre es el que debe coincidir con el `image:` del `docker-compose.easypanel.yml` (o con lo que construye el compose).

---

## Si el dashboard vuelve a mostrar Build #5

El código en el repo tiene **Build #77**; si en el navegador ves otra vez **Build #5**, el servidor está sirviendo una imagen vieja o una réplica antigua. Hacé esto:

1. **Forzar reconstrucción en EasyPanel**  
   En la app **dashboard**: usá la opción **"Forzar reconstrucción"** / **"Rebuild"** / **"Build without cache"** (o similar) y después **Implementar** (Deploy). Así se construye una imagen nueva desde el Git actual (con Build #77).  
   **Plan B si no aparece esa opción:** en **Fuente**, editá **Ruta de compilación** (borrá `/`, guardá, volvé a poner `/`, guardá) o **Rama** (cambiala a otro valor, guardá, volvé a poner `main`, guardá). Eso suele hacer que EasyPanel vuelva a leer el repo; después **Implementar** (Deploy).

2. **No usar el truco de réplicas 0→1 en EasyPanel**  
   Si en EasyPanel ponés réplicas en 0, guardás, volvés a 1 y guardás, EasyPanel puede hacer **otro build** (con caché) y la imagen vuelve a ser la vieja (#5). Para forzar que el contenedor use la imagen nueva, hacelo **por SSH**:  
   `docker service update --force checkin24hs_dashboard`  
   Así no se dispara otro build en EasyPanel.

3. **Actualizar todas las réplicas a la vez (si hay varias)**  
   Si trabajan varias personas y necesitás varias réplicas:
   - **En el compose:** En `docker-compose.easypanel.yml` el dashboard tiene `deploy.update_config.parallelism: 10` para que, en cada redeploy, Swarm actualice hasta 10 réplicas a la vez. Usá siempre "Redeploy from Compose" para que aplique.
   - **Por SSH después de cada deploy:**  
     `docker service update --force checkin24hs_dashboard`  
     Así todas las réplicas usan la imagen que acabas de desplegar.

4. **No confiar en caché del navegador**  
   Después del redeploy, abrí el dashboard en **ventana de incógnito** o hacé **Ctrl+Shift+R** (recarga forzada). El servidor del dashboard ya envía cabeceras `Cache-Control: no-store` para el HTML, así que con una recarga deberías ver la versión nueva.

5. **Verificar en el servidor**  
   Por SSH: `docker ps --format "{{.Names}} {{.Image}}" | grep dashboard`  
   Todas las líneas deberían mostrar la misma imagen (`easypanel/checkin24hs/dashboard:latest`) y estar **Up**. Si alguna réplica usa una imagen por ID (ej. `abc123def`) en lugar del nombre, esa réplica es vieja.  
   **Ver qué build tiene el contenedor que está corriendo:**  
   `CID=$(docker ps -q --filter "name=checkin24hs_dashboard" | head -1); docker exec $CID grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' /app/dashboard.html`  
   Debería mostrar `DASHBOARD_BUILD_NUMBER = 77`. Si muestra `= 5`, el contenedor tiene la imagen vieja.

6. **Si el contenedor tiene #77 pero el navegador muestra #5 (incluso en incógnito)**  
   Algo está cacheando la respuesta (Traefik, CDN o proxy). Por SSH comprobá qué devuelve la URL pública:  
   `curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" https://dashboard.checkin24hs.com/ 2>/dev/null | grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*'`  
   - Si sale **77**: la URL pública está bien; el problema es caché en tu red o navegador (probá otro dispositivo/red o otro navegador).  
   - Si sale **5** o nada: algo delante del contenedor cachea. Si usás **Cloudflare** (u otro CDN): purgá la caché de ese dominio o desactivá caché para esa ruta.

7. **Si sigue volviendo a #5: comprobar bind mount**  
   En el pasado el dashboard podía tener un **bind mount** (ej. `/root/checkin24hs/dashboard.html` → `/app/dashboard.html`). Si sigue configurado, el contenedor usa el archivo del **host** (que puede ser viejo, #5) en lugar del de la imagen. Por SSH:  
   `docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'`  
   Si sale algo (ej. `bind /root/checkin24hs/... -> /app/...`), en **EasyPanel** → app dashboard → **Volúmenes / Mounts** eliminá ese bind mount, guardá y volvé a desplegar. Después: `docker service update --force checkin24hs_dashboard`.

---

## Si ves 404 en dashboard.checkin24hs.com

1. **Probar con HTTPS**  
   El compose define el dashboard solo en **websecure** (HTTPS). Entrá a **https://dashboard.checkin24hs.com** (con `https://`). Si entraste por `http://`, Traefik puede no tener ruta para ese host en el entrypoint HTTP y devolver 404.

2. **Verificar que el servicio tenga los labels de Traefik**  
   Por SSH:
   ```bash
   docker service inspect checkin24hs_dashboard --format '{{json .Spec.Labels}}' | head -20
   ```
   Deberías ver `traefik.enable=true`, `traefik.http.routers.dashboard.rule=Host(...)`, etc. Si no están, EasyPanel los borró en el último redeploy.

3. **Re-aplicar los labels (si faltan)**  
   Si no usaste "Deploy from Compose", aplicá los labels a mano después del redeploy. Comandos en **docs/TRAEFIK_DASHBOARD_WHATSAPP_COMANDOS.md** (sección "Dashboard"). O volvé a desplegar desde **docker-compose.easypanel.yml** con "Redeploy from Compose".

4. **Verificar que el contenedor esté Up y en la red easypanel**  
   ```bash
   docker ps --filter name=checkin24hs_dashboard --format "{{.Names}} {{.Status}}"
   docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.VirtualIPs}}{{.NetworkID}}{{end}}'
   ```
   Si el servicio no está en la red `easypanel`, Traefik no puede alcanzarlo:  
   `docker service update --network-add easypanel checkin24hs_dashboard`

---

Según el flujo que uses en EasyPanel, podés mantener los labels de Traefik de estas formas:

---

## Dónde suelen estar Labels / Traefik / Dominios en EasyPanel

Si no encontrás la sección de etiquetas, probá:

- **Dominios / Domains:** a veces los labels de Traefik se configuran al añadir un dominio (ej. `dashboard.checkin24hs.com`). Buscá "Dominios", "Domain" o "Añadir dominio".
- **Red / Network:** a veces hay opciones de red o "Conectar a Traefik" que aplican labels por detrás.
- **Avanzado / Advanced / Configuración:** pestaña o sección "Avanzado", "Advanced", "Config" o "Más opciones" donde figuren **Labels** o **Docker labels**.
- **Al crear la app:** si la app se creó desde "Git" o "Dockerfile" sin compose, puede que no haya pantalla de labels y haya que usar **Deploy from Compose** (apuntando a `docker-compose.easypanel.yml`) o pedir a soporte (Hostinger) que indiquen dónde se configuran.

**Fragmento para enviar a Hostinger:** ver **docs/FRAGMENTO_DOCKER_COMPOSE_PARA_HOSTINGER.md** (ahí está el bloque de labels para copiar/pegar).

---

## 1. Usar `docker-compose.easypanel.yml` del repo

En la **raíz del repo** está `docker-compose.easypanel.yml` con los labels de Traefik para dashboard, whatsapp, cotizador y webmail.

- **Si EasyPanel permite "Deploy from Compose" o "Redeploy from Compose":**  
  Apuntá al repo y a ese archivo. Cada redeploy usará el compose y **conservará** los labels.

- **Si EasyPanel no usa compose:**  
  Copiá los labels del compose al servicio en la UI de EasyPanel (Apps → tu app → Labels / Traefik). Así quedan guardados en la definición de la app y no se pierden al redeploy.

---

## Cómo hacer Redeploy from Compose en EasyPanel

**Opción A: App creada desde el repo (recomendada)**

1. En EasyPanel entrá a la **app** que corresponde al stack (dashboard, o la app que agrupa dashboard/whatsapp/cotizador/webmail).
2. Andá a **Settings** / **Config** / **Source** y asegurate de que esté configurada como **Git App** apuntando a:
   - Repo: `GermanPerez-ai/checkin24hs` (o tu fork).
   - Rama: `main`.
   - **Ruta del compose:** si EasyPanel pide “Compose file path” o “Build path”, poné **`docker-compose.easypanel.yml`** (está en la **raíz** del repo, no en `deploy/`).
3. Cada vez que hagas `git push`, en EasyPanel entrá a esa app y hacé clic en **Redeploy** / **Deploy latest** / **Implementar**. EasyPanel vuelve a leer el `docker-compose.easypanel.yml` y aplica los labels de Traefik automáticamente.

**Opción B: App creada pegando el YAML**

1. En EasyPanel: **Apps → New App → From Docker Compose** (o similar).
2. Pegá el contenido completo de **`docker-compose.easypanel.yml`** (el que está en la raíz del repo) y creá la app.
3. Para redeployar: entrá a esa app, abrí la sección donde está el **Docker Compose** (el YAML), actualizá el contenido si hiciste cambios (o dejalo igual), y hacé clic en **Save & Deploy** / **Redeploy**.

En ambos casos, mientras el YAML tenga los labels, no hace falta configurar Traefik a mano. Si tu app hoy se creó **por Git** con un solo Dockerfile (sin compose), no vas a tener “Redeploy from Compose” para ese stack; en ese caso tenés que crear una **nueva app** desde “From Docker Compose” (Opción B) apuntando al repo o pegando el YAML, o seguir aplicando los labels a mano después de cada deploy (comandos en **docs/TRAEFIK_DASHBOARD_WHATSAPP_COMANDOS.md**).

---

## 2. App Template en EasyPanel

1. Creá una app (Dashboard) con los labels de Traefik ya configurados (una vez a mano o desde el compose).
2. **Apps → New App → From Template** → guardar como plantilla propia.
3. La próxima vez que crees una app, elegís esa plantilla y solo cambiás imagen/variables; los labels de Traefik ya vienen.

---

## 3. Labels en la UI de EasyPanel (recomendado si no usás compose)

En el servicio **Dashboard** (y WhatsApp) en EasyPanel, en la sección **Labels** o **Traefik**, añadí de una vez estas claves/valores. EasyPanel las guarda en la app; en cada redeploy se mantienen.

**Dashboard:**

| Key | Value |
|-----|--------|
| `traefik.enable` | `true` |
| `traefik.docker.network` | `easypanel` |
| `traefik.http.routers.dashboard.rule` | `Host(\`dashboard.checkin24hs.com\`)` |
| `traefik.http.routers.dashboard.entrypoints` | `websecure` |
| `traefik.http.routers.dashboard.service` | `dashboard` |
| `traefik.http.routers.dashboard.tls` | `true` |
| `traefik.http.routers.dashboard.tls.certresolver` | `letsencrypt` |
| `traefik.http.services.dashboard.loadbalancer.server.port` | `3000` |

**WhatsApp:** (mismo esquema, router/service `whatsapp`, puerto `3001`, host `whatsapp.checkin24hs.com`).

---

## 4. Referencia completa

Comandos `docker service update` y tabla de labels: ver **docs/TRAEFIK_DASHBOARD_WHATSAPP_COMANDOS.md**.
