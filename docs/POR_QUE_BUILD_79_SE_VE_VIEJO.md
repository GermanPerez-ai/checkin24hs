# Por qué Build #79 se ve “viejo” y qué revisar

## Tu resumen (correcto)

1. **Se subió lo que está en local al servidor** → Sí: `git push` sube al repo; en el servidor `git pull` baja ese mismo código.
2. **Se hizo el build para que el servidor tenga los cambios** → Sí: `docker build` crea una imagen con ese código; `docker service update --force` hace que el servicio use esa imagen.
3. **Al ejecutar el dashboard, aunque aparezca #79 se ve una versión antigua** → Aquí hay que aclarar qué es “viejo” (ver abajo).

---

## Tus conclusiones y qué puede estar pasando

### 1. “Algo que no se copia”

**Qué copia el Dockerfile hoy**

- `dashboard.html` (raíz del repo)
- `supabase-client.js`
- `deploy/dashboard-html/server.js`
- `deploy/dashboard-html/BUILD_ID`
- `hotel-images`, `deploy/logo.png`, `og-cotizar.jpg`

Todo lo que sirve el dashboard (HTML + JS + assets) viene de la imagen; no hay otro archivo “del dashboard” que se cargue desde fuera y no esté en el Dockerfile.

**Qué revisar**

- Si en el HTML hay rutas a **recursos externos** (otro dominio, CDN, otro servicio), esos sí pueden ser “viejos” aunque el HTML sea #79. En ese caso el problema no es “algo que no se copia” en la imagen, sino la URL de ese recurso.
- Si abrís **https://dashboard.checkin24hs.com/build_id.txt** y ves **79**, la imagen que está sirviendo es la que construiste (con ese build). Si ves otro número, entonces no es la imagen que construiste la que está en ejecución.

---

### 2. “Contenedores que no se escriben”

**Qué hace `docker service update --force`**

- Swarm **reemplaza** las tareas del servicio `checkin24hs_dashboard` por tareas nuevas que usan la imagen que indicás (por ejemplo `easypanel/checkin24hs/dashboard:latest`).
- Si solo hay 1 réplica (1/1), ese único contenedor pasa a ser uno nuevo con la imagen nueva.

**Qué puede pasar**

- **EasyPanel** puede tener su propia forma de desplegar (por ejemplo “Redeploy” o “Sync”). Si después de tu `docker service update --force` alguien (o un proceso) hace un redeploy desde EasyPanel, EasyPanel puede:
  - Volver a construir la imagen (con su caché, que puede ser vieja), o
  - Volver a desplegar desde un compose/imagen que tenga guardado (y que sea viejo).
- En ese caso **sí** tendrías “contenedores que se recrean con algo viejo”: no es que no se escriban, sino que **algo los vuelve a crear con una imagen antigua**.

**Qué revisar**

- En EasyPanel: ver si el servicio dashboard tiene **“Redeploy” automático**, **“Sync”** o algo que se ejecute después de tu deploy manual.
- En el servidor, después de hacer tu flujo (build + `docker service update --force`), comprobar qué imagen está usando el servicio:
  ```bash
  docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'
  ```
  Y la fecha de la imagen:
  ```bash
  docker images easypanel/checkin24hs/dashboard:latest --format "{{.CreatedAt}}"
  ```
  Si más tarde volvés a ejecutar eso y la imagen o la fecha cambió sin que vos hayas hecho otro build, algo (p. ej. EasyPanel) está redeployando.

---

### 3. “Después del build, algo recrea lo antiguo”

Es la hipótesis más coherente si **build_id.txt** muestra 79 pero la **interfaz** se ve vieja:

1. **EasyPanel redeploy**  
   Después de tu `docker service update --force`, EasyPanel hace un redeploy (manual o automático) y vuelve a poner una imagen antigua (por caché de build o por compose guardado).

2. **Caché de build en EasyPanel**  
   Si en EasyPanel se usa “Build from Git” y no se invalida la caché, puede estar construyendo con capas viejas y una versión antigua de `dashboard.html`.

3. **No es “algo que recrea” sino “versión desplegada = versión en Git”**  
   Si en Git el `dashboard.html` que se subió **ya tiene** Build #79 pero el resto del contenido (textos, secciones, estilos) es el que vos considerás “viejo”, entonces lo que ves en el dashboard **es** la versión desplegada: no hay un proceso que “recrea lo antiguo”, sino que la versión “nueva” en el repo es la que tiene esa UI. La diferencia con “local” sería que en tu PC tenés **cambios sin commitear** (por eso al abrir `file:///.../dashboard.html` ves algo más nuevo).

**Qué revisar**

- En tu PC: `git status` y `git diff dashboard.html`. Si hay cambios sin commitear en `dashboard.html`, entonces “lo nuevo” está solo en local y por eso el servidor “se ve viejo”.
- En el servidor: después de tu deploy, no usar “Redeploy” desde EasyPanel durante un rato; solo usar tu flujo (git pull → build → service update). Si en ese periodo el dashboard deja de verse “viejo”, el que “recrea lo antiguo” es muy probable que sea EasyPanel al redeploy.

---

## Resumen práctico

| Hipótesis | Qué comprobar |
|----------|----------------|
| Algo no se copia | Revisar que el Dockerfile copie todo lo que usa el dashboard; comprobar si hay recursos externos (URLs) que puedan estar desactualizados. |
| Contenedores que no se actualizan | `docker service inspect` y `docker images` para ver qué imagen usa el servicio y cuándo se creó; repetir después de un redeploy en EasyPanel. |
| Algo recrea lo antiguo | No usar Redeploy en EasyPanel tras tu deploy; ver si la UI se mantiene “nueva”. Revisar `git status` / `git diff` en local por cambios sin subir. |

Si **build_id.txt** muestra 79 y la **interfaz** sigue viéndose vieja, lo más probable es una de estas dos:

- EasyPanel está redeployando y volviendo a una imagen vieja, o  
- La versión en Git (y por tanto en el servidor) es la que tiene esa UI “vieja”, y lo “nuevo” está solo en cambios locales no commiteados.
