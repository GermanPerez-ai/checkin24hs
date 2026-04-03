# Paso 1 – Ver qué carpeta está sirviendo el dashboard (Hostinger)

`build_id.txt` devuelve **81** pero la **página** muestra **80**. Hay que comprobar si es:
- **A)** Imagen Docker con archivos mezclados (mismo contenedor: `build_id.txt` = 81, `dashboard.html` = 80), o  
- **B)** Proxy/EasyPanel sirviendo `build_id.txt` de un sitio y el HTML de otro.

---

## Comandos a ejecutar por SSH en el VPS

Conectate por SSH al servidor y ejecutá **en este orden**:

### 1. Encontrar el contenedor del dashboard

```bash
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}" | grep -i dashboard
```

O si usás Docker Swarm:

```bash
docker service ps checkin24hs_dashboard --no-trunc 2>/dev/null | head -5
```

Anotá el **nombre o ID** del contenedor que corre el dashboard (ej. `checkin24hs_dashboard.1.xxxx`).

---

### 2. Dentro del contenedor: ruta de build_id.txt y contenido

**Opción A – Si usás Docker Swarm (servicio):**

```bash
# Obtener el ID del contenedor que está corriendo el dashboard
CONTAINER_ID=$(docker ps -q --filter "name=checkin24hs_dashboard" | head -1)
if [ -z "$CONTAINER_ID" ]; then CONTAINER_ID=$(docker ps -q --filter "name=dashboard" | head -1); fi
echo "Contenedor: $CONTAINER_ID"
docker exec $CONTAINER_ID cat /app/build_id.txt
docker exec $CONTAINER_ID grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*" /app/dashboard.html
```

**Opción B – Copiá y pegá todo de una vez:**

```bash
C=$(docker ps -q --filter "name=dashboard" | head -1)
echo "=== Contenedor: $C ==="
echo "=== /app/build_id.txt ==="
docker exec $C cat /app/build_id.txt 2>/dev/null || echo "(no encontrado)"
echo "=== DASHBOARD_BUILD_NUMBER en /app/dashboard.html ==="
docker exec $C grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*" /app/dashboard.html 2>/dev/null || echo "(no encontrado)"
```

---

### 3. Listar la carpeta que sirve el dashboard (document root del servicio)

En nuestro setup todo está en `/app` dentro del mismo contenedor:

```bash
docker exec $CONTAINER_ID ls -la /app/
```

---

## Cómo interpretar el resultado

| /app/build_id.txt | /app/dashboard.html (grep) | Conclusión |
|-------------------|----------------------------|------------|
| 81 | DASHBOARD_BUILD_NUMBER = 81 | El contenedor está bien. El HTML que ves en el navegador viene de **otro sitio** (proxy, otra ruta, otro servicio). Revisar EasyPanel: qué backend sirve `/v81/` y si hay otra “carpeta” o servicio para el HTML. |
| 81 | DASHBOARD_BUILD_NUMBER = 80 | **Archivos mezclados en la misma imagen**: `build_id.txt` se generó con BUILD_ID=81, pero se copió un `dashboard.html` viejo (caché de Docker o archivo equivocado). Solución: **rebuild sin caché** y asegurarse de que `dashboard.html` en la **raíz del repo** tenga 81 antes de construir. |

---

## Qué responderle a Hostinger (Paso 1)

Después de ejecutar los comandos, mandales:

1. **Ruta donde está el build_id.txt que devuelve 81**  
   Ejemplo: “Dentro del contenedor del dashboard, en `/app/build_id.txt`. El contenedor es el del servicio `checkin24hs_dashboard` (Docker Swarm) / contenedor `xxx`.”

2. **Resultado de** `grep DASHBOARD_BUILD_NUMBER` **en `/app/dashboard.html`** (dentro del mismo contenedor):  
   Si sale `DASHBOARD_BUILD_NUMBER = 80` → mismo contenedor, archivos mezclados.  
   Si sale `DASHBOARD_BUILD_NUMBER = 81` → el HTML que ve el usuario no viene de ese contenedor; revisar proxy/document root en EasyPanel/Traefik/Nginx.

3. **Ruta configurada como “document root” o backend del dashboard**  
   En EasyPanel: dominio `dashboard.checkin24hs.com`, rutas `/` y `/v81/` → ver a qué **servicio** y **puerto** apuntan (en nuestro caso es el mismo servicio Node que sirve desde `/app` dentro del contenedor; no hay carpeta en el host como “document root”).

---

## Si la conclusión es “archivos mezclados” (build_id 81, HTML 80 en /app)

1. En el repo, confirmar que **`dashboard.html` en la raíz** tenga `DASHBOARD_BUILD_NUMBER = 81` y el `<span id="build-number">81</span>`.
2. Reconstruir la imagen **sin caché** y volver a desplegar:
   ```bash
   docker build --no-cache -f deploy/dashboard-html/Dockerfile -t easypanel/checkin24hs/dashboard:81 .
   # Luego actualizar el servicio con esta imagen
   ```
3. Si el build lo hace EasyPanel desde Git: asegurarse de que en GitHub el `dashboard.html` de la raíz tenga 81 y hacer “Rebuild” con opción de **no cache** (si EasyPanel la ofrece).

---

## Prevención (Hostinger / Kodee)

Si vuelve a pasar algo parecido (build_id nuevo pero HTML viejo):

- **Siempre hacer un build limpio sin caché** (`docker build --no-cache ...`), o  
- **Cambiar el BUILD_ID / ARG** en el Dockerfile o en el archivo `BUILD_ID` para invalidar la capa y forzar que se copie de nuevo el `dashboard.html` actualizado.
