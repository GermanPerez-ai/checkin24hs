# Actualizar todo en el servidor

Pasos para subir los cambios recientes (validación teléfono cotizador, link con número, Flor personaliza link, editar promociones desde Supabase).

---

## Resumen de qué actualizar

| Componente | Archivos | Dónde corre |
|------------|----------|-------------|
| **Dashboard** | `dashboard.html`, `deploy/dashboard.html` | dashboard.checkin24hs.com |
| **Cotizador** | `cotizador-cliente.html` (+ `supabase-config.js`, `supabase-client.js` si los usas) | cotizar.checkin24hs.com |
| **WhatsApp / Flor** | `whatsapp-server/whatsapp-server-baileys.js` | Servicio checkin24hs_whatsapp |

---

## 1. En tu PC: preparar y subir a GitHub

### 1.1 Copiar dashboard a deploy (si editaste la raíz)

```powershell
Copy-Item -Path "dashboard.html" -Destination "deploy\dashboard.html" -Force
```

### 1.2 Subir el número de build del dashboard (recomendado en cada deploy)

La imagen Docker del dashboard usa **solo** `deploy/dashboard.html` y el **BUILD_ID**.

1. **`deploy/dashboard-html/BUILD_ID`** — Cambiá el contenido a un número nuevo (ej. `84`).
2. **`deploy/dashboard.html`** — Mismo número en dos lugares:
   - `window.DASHBOARD_BUILD_NUMBER = 84;`
   - `<span id="build-number">84</span>`

*(Opcional: si usás URL versionada `/v84/`, agregá el mismo patrón en `deploy/dashboard-html/server.js`.)*

### 1.3 Subir todo a GitHub

```powershell
cd C:\Users\German\Downloads\Checkin24hs

git add dashboard.html deploy/dashboard.html deploy/dashboard-html/BUILD_ID cotizador-cliente.html whatsapp-server/whatsapp-server-baileys.js
# Si tocaste otros archivos del dashboard:
# git add deploy/dashboard-html/server.js supabase-client.js deploy/supabase-config.js
git status
git commit -m "Dashboard Build 84: cotizador teléfono + Flor link personalizado + promociones Supabase"
git push origin main
```

*(Si el cotizador está en otra carpeta en el repo, incluye esa ruta en `git add`.)*

---

## 2. Actualizar el servidor WhatsApp (Flor)

Así el link que envía Flor lleva el número del usuario y el cotizador pre-llena el teléfono.

- **Si usás EasyPanel con GitHub:** Entrá al servicio **WhatsApp** → **Implementar** / **Redeploy**.
- **Si construís en el servidor por SSH:**

```bash
cd /root/checkin24hs
git pull origin main
cd whatsapp-server
docker build -t whatsapp-server:latest .
docker service update --force checkin24hs_whatsapp
```

Ver logs: `docker service logs checkin24hs_whatsapp --tail 50`

---

## 3. Actualizar el Dashboard

**No uses "Implementar" / "Deploy" en EasyPanel** para este dashboard: el servicio queda con la imagen por **tag :BUILD_ID** (ej. `:84`). El flujo correcto es por **script en el servidor**:

1. En el servidor (SSH):

```bash
cd /root/checkin24hs
git pull origin main
bash scripts/deploy_dashboard_servidor.sh
```

Ese script: hace `git fetch` + `git reset --hard origin/main` + `git pull`, lee **BUILD_ID** de `deploy/dashboard-html/BUILD_ID`, construye la imagen **sin caché** con tag `easypanel/checkin24hs/dashboard:BUILD_ID` (y `:latest`) y actualiza el servicio Docker Swarm.

2. Verificar en el servidor:

```bash
curl -s https://dashboard.checkin24hs.com/v83/build_id.txt
curl -s https://dashboard.checkin24hs.com/v83/ | grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*"
```

(Reemplazá `v83` por el número de build que hayas subido, ej. `v84`.)

3. En el navegador: abrí **https://dashboard.checkin24hs.com/** (o `/v84/` si usás ruta versionada) y recargá con **Ctrl+Shift+R**. En el sidebar debería verse **Build #84** (o el número que hayas puesto). Si ves build viejo, borrá datos del sitio solo para `dashboard.checkin24hs.com`.

Guía completa del dashboard: **`docs/ACTUALIZAR_DASHBOARD_POR_SERVIDOR.md`**.

---

## 4. Actualizar el Cotizador (cotizar.checkin24hs.com)

El cotizador suele ser un archivo estático o un bind mount. Opciones:

- **Si el dominio cotizar.checkin24hs.com sirve desde el mismo proyecto:** después de `git pull` en el servidor, los archivos ya están; si usa contenedor, reiniciar o volver a desplegar ese servicio.
- **Si tenés un script tipo `ACTUALIZAR_COTIZADOR_SERVIDOR.sh`:** ejecutarlo después del `git pull`.
- **Manual:** copiar `cotizador-cliente.html` (y `supabase-config.js` / `supabase-client.js` si aplica) a la ruta que sirve el dominio del cotizador.

---

## 5. Verificación rápida

1. **Flor:** Escribir por WhatsApp “quiero cotizar”; el link en la respuesta debe ser `https://cotizar.checkin24hs.com/?phone=56...` (con número). Abrirlo y comprobar que el campo Teléfono venga lleno.
2. **Cotizador:** En https://cotizar.checkin24hs.com/ poner un teléfono inválido (ej. 123) y enviar; debe mostrar error de validación.
3. **Dashboard:** En Hoteles → Promociones Activas → Editar en una promoción; debe cargar las promociones (desde Supabase) y permitir editar.

---

## Si algo falla

- **WhatsApp:** Ver `ACTUALIZAR_WHATSAPP_SERVIDOR.md`.
- **Dashboard:** Ver `docs/ACTUALIZAR_DASHBOARD_POR_SERVIDOR.md` o `COMO_ACTUALIZAR_DASHBOARD.md`.
- **Cotizador:** Ver `ACTUALIZAR_COTIZADOR_SERVIDOR.sh` o los scripts de cotizador en el repo.
