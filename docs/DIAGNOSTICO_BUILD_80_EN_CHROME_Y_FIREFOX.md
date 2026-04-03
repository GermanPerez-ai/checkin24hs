# Build #80 en Chrome y Firefox (incluso en /v81/)

Si **ambos** Chrome y Firefox muestran Build #80 al abrir `https://dashboard.checkin24hs.com/v81/`, no es solo caché del navegador: puede ser caché de un proxy/CDN o que tu petición esté yendo a otro backend.

---

## 1. Comprobar qué sirve el servidor (desde tu PC)

En el **mismo** navegador donde ves Build #80, abrí en una pestaña nueva:

- **https://dashboard.checkin24hs.com/v81/build_id.txt**

Interpretación:

- **Si `build_id.txt` muestra `81`**  
  El contenedor que te está respondiendo es el correcto (Build 81). Entonces el **HTML de la página** está siendo cacheado por algo entre vos y el servidor (proxy, CDN, Traefik, etc.). Hay que purgar esa caché o desactivar caché para el HTML del dashboard.

- **Si `build_id.txt` muestra `80` o da 404**  
  Las peticiones a `dashboard.checkin24hs.com` (incluido `/v81/`) están llegando a un **backend viejo** (otra réplica, otro servicio, o una imagen antigua). Revisar en EasyPanel qué servicio está detrás del dominio y que use la imagen `easypanel/checkin24hs/dashboard:81` (o el tag correcto).

---

## 2. Comprobar desde el servidor (SSH)

En el servidor:

```bash
curl -s https://dashboard.checkin24hs.com/v81/build_id.txt
curl -s https://dashboard.checkin24hs.com/v81/ | grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*"
```

Si desde el servidor ves **81** pero desde tu navegador (Chrome/Firefox) ves **80** en la página y **81** en `build_id.txt`, entonces solo el HTML está cacheado (proxy/CDN). Si desde el servidor también ves 80, el contenedor que está sirviendo es viejo.

---

## 3. Qué hacer según el resultado

| build_id.txt (en tu navegador) | Página muestra | Qué hacer |
|--------------------------------|----------------|-----------|
| 81 | 80 | Caché intermedia (proxy/CDN). Purga de caché para el dominio o desactivar caché para el HTML. |
| 80 o 404 | 80 | Backend viejo. Revisar EasyPanel: servicio, imagen (`:81`), réplicas. |
| 81 | 81 | Todo correcto. |

---

## 4. Sincronización deploy/dashboard.html

El repo tiene dos archivos:

- `dashboard.html` (raíz) → usado por el Dockerfile para construir la imagen.
- `deploy/dashboard.html` → debe tener **el mismo** Build # que la raíz.

Si en algún flujo se usa `deploy/dashboard.html`, debe estar en Build #81 (ya sincronizado). El Dockerfile sigue copiando `dashboard.html` desde la **raíz**; mantener ambos con el mismo número evita confusiones.
