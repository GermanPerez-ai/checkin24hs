# Por qué el dashboard se “actualiza solo” y vuelve a la estructura vieja

Vos no tocás EasyPanel ni hacés redeploy, pero el dashboard vuelve a la versión antigua. Eso puede pasar por **varias cosas que pasan en el servidor sin que vos hagas nada**.

---

## Qué puede estar pasando

### 1. **EasyPanel hace algo automático**

Aunque solo vos entrás y no tocás nada, EasyPanel puede tener:

- **“Sync” o “Redeploy from Git”** programado (cada X tiempo).
- **Webhook de GitHub**: al hacer `git push`, GitHub avisa a EasyPanel y EasyPanel hace **build desde Git**. Si ese build usa **caché**, a veces arma una imagen vieja y la pone como `latest`.
- **Health check** que reinicia el contenedor; al reiniciar usa la imagen `latest` que esté en el servidor en ese momento. Si antes algo ya había construido una imagen vieja y la guardó como `latest`, ves la versión vieja.

### 2. **Cron en el servidor**

Puede haber un **cron** (tuyo o de otro) que:

- hace `git pull` y `docker build` (a veces **con caché**),
- y después `docker service update` o reinicio.

Si ese build usa caché, la imagen nueva puede ser “vieja” y se guarda como `latest`. Cualquier reinicio del servicio después usa esa imagen.

### 3. **Reinicio del servidor o de Docker**

- **Reinicio del servidor** (actualizaciones del sistema, mantenimiento).
- **Reinicio del daemon de Docker**.

Al arrancar de nuevo, Swarm/Docker levanta el servicio con la imagen que tenga como `latest` **en ese momento**. Si antes algo (EasyPanel, cron, otro deploy) ya había pisado `latest` con una imagen vieja, después del reinicio ves la estructura vieja.

### 4. **Swarm / política de actualización**

El servicio puede tener una **política de actualización** (rolling update, etc.). Eso no explica por sí solo “versión vieja”, pero si además algo está construyendo imágenes viejas y guardándolas como `latest`, cada vez que Swarm “actualiza” o recrea tareas, usa esa `latest` vieja.

---

## Cómo investigar en el servidor

Conectate por SSH y revisá:

### ¿Hay algún cron que toque el repo o Docker?

```bash
crontab -l
sudo crontab -l
ls -la /etc/cron.d/
grep -r checkin24hs /etc/cron.d/ 2>/dev/null
grep -r docker /etc/cron.d/ 2>/dev/null
```

### ¿Qué imagen está usando el servicio ahora?

```bash
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'
```

Siempre va a ser algo como `easypanel/checkin24hs/dashboard:latest`. El tema no es el nombre, sino **qué contenido tiene esa imagen** (si se construyó con código viejo y caché).

### ¿Cuándo se creó la imagen “latest”?

```bash
docker images easypanel/checkin24hs/dashboard:latest --format "{{.CreatedAt}}"
```

Si después de que vos hiciste el deploy correcto aparece **otra** fecha más nueva, algo más construyó/actualizó la imagen después.

### EasyPanel

En la interfaz de EasyPanel (o en la documentación de tu hosting):

- Buscá si el proyecto/dashboard tiene **“Redeploy from Git”**, **“Sync”**, **“Auto deploy”** o **webhook**.
- Si hay algo así, puede ser lo que construye de nuevo la imagen y, con caché, a veces deja la versión vieja.

---

## Solución: fijar la versión con un tag (Build #81, #82, …)

Mientras el servicio use **`latest`**, cualquier proceso que construya una imagen vieja y la guarde como `latest` puede “robar” la versión correcta. Para que eso no te afecte:

- **Construir la imagen con un tag fijo** por build, por ejemplo: `easypanel/checkin24hs/dashboard:81`.
- **Hacer que el servicio use ese tag** (`:81`), no `:latest`.
- Así, aunque EasyPanel o un cron vuelvan a construir y pisen `latest`, el servicio **sigue usando** `:81` hasta que vos explícitamente lo pases a `:82`, etc.

### Cambio en el script de deploy

En el servidor, el script puede:

1. Leer el `BUILD_ID` del repo (ej. 81).
2. Construir:  
   `docker build ... -t easypanel/checkin24hs/dashboard:81 -t easypanel/checkin24hs/dashboard:latest ...`
3. Actualizar el servicio para que use **esa** versión:  
   `docker service update --image easypanel/checkin24hs/dashboard:81 checkin24hs_dashboard`

Así el servicio queda “clavado” en la imagen `:81`. Nada que solo pise `latest` va a cambiar lo que ves en el dashboard hasta que vos corras de nuevo el script (con Build 82, 83, etc.) y hagas `docker service update --image ...:82`.

---

## Resumen

| Pregunta | Respuesta breve |
|----------|-----------------|
| ¿Por qué se actualiza solo? | Algo en el servidor (EasyPanel, cron, reinicio) construye o usa una imagen vieja guardada como `latest`. |
| ¿El servidor “actualiza” solo? | No es que “actualice” a una versión nueva; suele ser que **reconstruye con caché** o **reinicia** y usa una `latest` que ya era vieja. |
| ¿Cómo evitarlo? | Dejar de depender de `latest`: usar tag por build (ej. `:81`) y que el servicio use ese tag; así nada que pise `latest` te cambia el dashboard. |

Si querés, el siguiente paso es adaptar tu `deploy_dashboard_servidor.sh` para que use siempre un tag numérico (BUILD_ID) y actualice el servicio con ese tag, como en la sección “Cambio en el script de deploy”.
