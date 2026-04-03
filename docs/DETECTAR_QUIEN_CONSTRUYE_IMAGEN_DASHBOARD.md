# Detectar qué imagen corre el dashboard y quién la construyó

## 1. Script rápido en el servidor

En el servidor (SSH):

```bash
cd /root/checkin24hs && bash scripts/detectar_quien_construyo_dashboard.sh
```

Ese script muestra:

- **Qué imagen** está usando el servicio `checkin24hs_dashboard`.
- **Labels de la imagen**: `checkin24hs.build_source` y `checkin24hs.build_time`.
  - Si la construyó **nuestro script** (`deploy_dashboard_servidor.sh`), verás algo como:
    - `checkin24hs.build_source=deploy_dashboard_servidor.sh`
    - `checkin24hs.build_time=2026-02-02T15:30:00+00:00`
  - Si **no** tiene esas labels (o tienen otro valor), la imagen la construyó **otro proceso** (EasyPanel, cron, etc.).
- **Build que sirve la URL**: hace `curl` a `https://dashboard.checkin24hs.com/build_id.txt` y lo compara con el BUILD_ID del repo. Si no coinciden, avisa que algo reemplazó la imagen.

Así podés ver **qué imagen está corriendo** y, por las labels, **si la construyó nuestro script o no**.

---

## 2. Ver quién construyó la imagen (a mano)

```bash
# Imagen que usa el servicio
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'

# Labels de esa imagen (quién/cuándo)
docker image inspect easypanel/checkin24hs/dashboard:81 --format '{{json .Config.Labels}}'
```

Si ves `"checkin24hs.build_source":"deploy_dashboard_servidor.sh"`, la construyó nuestro script. Si no existe esa label, la construyó otro (EasyPanel, build manual, etc.).

---

## 3. Detectar cuándo cambia la imagen (cron)

Para que el servidor **detecte solo** cuando el build en vivo no coincide con el esperado (y registre la hora):

Creá un cron que corra el script cada X minutos y, si hay diferencia, registre en un log. Ejemplo cada 5 minutos:

```bash
# En el servidor: crontab -e
*/5 * * * * BUILD_ID_ESPERADO=$(cat /root/checkin24hs/deploy/dashboard-html/BUILD_ID 2>/dev/null); LIVE=$(curl -sS --max-time 5 https://dashboard.checkin24hs.com/build_id.txt 2>/dev/null); [ -n "$LIVE" ] && [ "$LIVE" != "$BUILD_ID_ESPERADO" ] && echo "$(date -Iseconds) dashboard build reemplazado: vivo=$LIVE esperado=$BUILD_ID_ESPERADO" >> /root/checkin24hs/dashboard_reemplazado.log
```

Así no sabés “quién” construyó la imagen nueva, pero sí **cuándo** se reemplazó (cada línea del log es un momento en que el build en vivo dejó de coincidir con el del repo).

---

## 4. Ver eventos de Docker en tiempo real (quién dispara un build)

Docker no guarda “quién” ejecutó un `docker build`, pero podés **mirar en vivo** cuándo se crean/etiquetan imágenes:

```bash
docker events --filter type=image --filter event=tag
```

Dejalo corriendo (en una pantalla o sesión aparte). Cuando aparezca algo como:

```
... image tag easypanel/checkin24hs/dashboard:latest ...
```

es que en ese momento alguien etiquetó esa imagen. No dice el proceso, pero sabés **el instante**. Si en ese mismo momento revisás qué proceso está haciendo `docker build` (por ejemplo con `ps aux | grep docker`), podés correlacionar.

Para ver también “pull” y “build”:

```bash
docker events --filter type=image
```

---

## 5. Auditar quién ejecuta `docker build` (avanzado)

En Linux podés usar **auditd** para registrar cada vez que alguien ejecuta `docker build` (o `docker service update`) y con qué usuario/comando:

```bash
# Regla: registrar ejecución de docker cuando el argumento contiene "build" o "service update"
sudo auditctl -a always,exit -F arch=b64 -S execve -F exe=/usr/bin/docker -F key=docker_cmd
```

Luego los eventos se ven en `/var/log/audit/audit.log` (o con `ausearch -k docker_cmd`). Ahí sí podés ver **qué usuario** y **qué línea de comando** (por ejemplo si fue un cron o un proceso de EasyPanel) ejecutó ese `docker`.

---

## Resumen

| Pregunta | Cómo |
|----------|------|
| ¿Qué imagen está corriendo? | `docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'` |
| ¿Quién la construyó? | Labels `checkin24hs.build_source` / `checkin24hs.build_time`. Si existen y son `deploy_dashboard_servidor.sh` + fecha, fue nuestro script; si no, otro proceso. |
| ¿El build en vivo es el esperado? | `bash scripts/detectar_quien_construyo_dashboard.sh` (o `curl` a `.../build_id.txt` vs BUILD_ID del repo). |
| ¿Cuándo se reemplazó? | Cron que compare build en vivo vs repo y escriba en un log cuando difieran. |
| ¿Cuándo se etiqueta una imagen? | `docker events --filter type=image` en tiempo real. |
| ¿Qué proceso ejecutó docker build? | auditd registrando ejecuciones de `docker` (avanzado). |

Nuestro script de deploy ahora **marca** cada imagen que construye con `build_source` y `build_time`; el script `detectar_quien_construyo_dashboard.sh` usa eso para decirte si la imagen actual la construyó “nosotros” o no.
