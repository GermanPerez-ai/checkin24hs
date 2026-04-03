# Ver qué se desplegó y si algo lo modifica (al instante o al minuto)

Ejecutar todo en el **servidor por SSH**. Sirve para ver qué imagen/contenido está corriendo y si algo lo cambia después.

---

## 1. Justo después de tu deploy (registrar “estado inicial”)

Después de hacer `docker service update --force checkin24hs_dashboard`, ejecutá **en seguida**:

```bash
echo "=== $(date) - Estado justo después del deploy ==="

# Imagen que usa el servicio
docker service inspect checkin24hs_dashboard --format 'Imagen: {{.Spec.TaskTemplate.ContainerSpec.Image}}'

# ID de la imagen (para comparar después)
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' | xargs docker images --no-trunc --format "ImageID: {{.ID}}"

# Qué BUILD_NUMBER tiene el HTML dentro de la imagen (sin ejecutar contenedor)
docker run --rm $(docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}') grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' /app/dashboard.html | head -1

# build_id.txt dentro de la imagen
docker run --rm $(docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}') cat /app/build_id.txt
```

Anotá o guardá la salida (sobre todo el ImageID y el BUILD_NUMBER).

---

## 2. Ver el contenedor que está realmente corriendo (tarea del servicio)

```bash
# ID de la tarea (contenedor) del servicio
TASK_ID=$(docker service ps checkin24hs_dashboard -q --no-trunc | head -1)
echo "Task ID: $TASK_ID"

# ID del contenedor (si existe)
CONTAINER_ID=$(docker inspect $TASK_ID --format '{{.Status.ContainerStatus.ContainerID}}' 2>/dev/null)
echo "Container ID: $CONTAINER_ID"

# Si hay contenedor, ver qué BUILD_NUMBER tiene el HTML que está sirviendo
if [ -n "$CONTAINER_ID" ]; then
  docker exec $CONTAINER_ID grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' /app/dashboard.html | head -1
  docker exec $CONTAINER_ID cat /app/build_id.txt
fi
```

Eso muestra qué está **realmente** escrito en el contenedor que está sirviendo tráfico.

---

## 3. Esperar 1–2 minutos y volver a comprobar

Esperá 1 o 2 minutos (o 5 si querés estar seguro). **No hagas Redeploy en EasyPanel.** Luego ejecutá de nuevo:

```bash
echo "=== $(date) - Estado después de 1-2 min ==="

# ¿Sigue siendo la misma imagen?
docker service inspect checkin24hs_dashboard --format 'Imagen: {{.Spec.TaskTemplate.ContainerSpec.Image}}'

# ¿El contenedor que corre sigue siendo el mismo?
docker service ps checkin24hs_dashboard --no-trunc

# Contenido dentro del contenedor que está corriendo ahora
CONTAINER_ID=$(docker service ps checkin24hs_dashboard -q --no-trunc | head -1 | xargs docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' 2>/dev/null)
if [ -n "$CONTAINER_ID" ]; then
  echo "BUILD_NUMBER en HTML:"
  docker exec $CONTAINER_ID grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' /app/dashboard.html | head -1
  echo "build_id.txt:"
  docker exec $CONTAINER_ID cat /app/build_id.txt
fi
```

Compará con lo que anotaste en el paso 1.

---

## 4. Cómo interpretar

| Si pasa esto | Significa |
|--------------|-----------|
| Mismo ImageID, mismo BUILD_NUMBER, mismo build_id.txt antes y después | Nada modificó el deploy; lo que escribiste sigue igual. |
| Mismo ImageID pero el *contenedor* es otro (nuevo ContainerID) | Swarm reemplazó la tarea pero con la **misma** imagen; normal si hubo un restart. |
| **Imagen distinta** o **BUILD_NUMBER/build_id.txt distinto** después de 1–2 min | Algo (p. ej. EasyPanel) volvió a desplegar y puso otra imagen/contenido. |
| Cambio al **instante** (segundos) | Probable redeploy automático o sync de EasyPanel en cuanto detecta cambios. |
| Cambio **al minuto** o después | Algún proceso periódico (cron, sync cada X minutos) está redeployando. |

---

## 5. Script todo junto (copiar y pegar)

Podés ejecutar esto en el servidor: primero el bloque “Ahora”, después esperar 1–2 minutos y ejecutar el bloque “Después”.

```bash
echo "========== AHORA (justo después de tu deploy) =========="
date
docker service inspect checkin24hs_dashboard --format 'Imagen: {{.Spec.TaskTemplate.ContainerSpec.Image}}'
IMG=$(docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
docker run --rm $IMG grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' /app/dashboard.html | head -1
docker run --rm $IMG cat /app/build_id.txt
echo ""

# Esperá 1-2 minutos, luego ejecutá el siguiente bloque:

echo "========== DESPUÉS (1-2 min más tarde) =========="
date
docker service inspect checkin24hs_dashboard --format 'Imagen: {{.Spec.TaskTemplate.ContainerSpec.Image}}'
docker run --rm $(docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}') grep -o 'DASHBOARD_BUILD_NUMBER = [0-9]*' /app/dashboard.html | head -1
docker run --rm $(docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}') cat /app/build_id.txt
```

Si en “AHORA” ves 79 y en “DESPUÉS” ves otro número (o otra imagen), algo está modificando el deploy al instante o al minuto.
