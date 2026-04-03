# Pasos para actualizar el dashboard en el servidor

Flujo recomendado cada vez que quieras que **dashboard.checkin24hs.com** tenga los últimos cambios (HTML, JS, estructura, etc.).

---

## 1. En tu PC: dejar listo lo que se va a desplegar

### 1.1 Si editás `dashboard.html` en la **raíz** del repo

La imagen Docker usa **solo** `deploy/dashboard.html`. Para que el servidor tenga tus cambios, copiá la raíz a deploy:

```powershell
# En la raíz del repo (PowerShell)
Copy-Item -Path "dashboard.html" -Destination "deploy\dashboard.html" -Force
```

O en Git Bash / WSL:

```bash
cp dashboard.html deploy/dashboard.html
```

### 1.2 Subir el número de build (recomendado en cada deploy)

Así evitás caché y sabés qué versión está en producción.

1. **`deploy/dashboard-html/BUILD_ID`**  
   Cambiá el contenido a un número nuevo (ej. `82`). Ese número lo usa el script de deploy.

2. **`deploy/dashboard.html`**  
   Mismo número en dos lugares:
   - `window.DASHBOARD_BUILD_NUMBER = 82;`
   - `<span id="build-number">82</span>`

3. **(Opcional)** Si querés una URL tipo `/v87/` para evitar caché del navegador:
   - En **`deploy/dashboard-html/server.js`** ya están definidas las rutas `/v81/` … `/v87/`. Para un build nuevo (ej. 88) agregá: `else if (urlPath.startsWith('/v88')) { urlPath = urlPath.replace(/^\/v88\/?/, '/') || '/'; }`.
   - En **EasyPanel** podés apuntar el dominio o una ruta a la versión que uses (ej. `/v87/`).

### 1.3 Otros archivos que entran en la imagen

- **`supabase-client.js`** (raíz) → se copia al build.
- **`deploy/supabase-config.js`**, **`deploy/logo.png`**, **`deploy/dashboard-html/server.js`** → también se copian.  
Si tocaste alguno, asegurate de que esté guardado y commiteado.

---

## 2. Subir cambios a GitHub

En la raíz del repo:

```bash
git add deploy/dashboard.html deploy/dashboard-html/BUILD_ID
# Si tocaste otros archivos del dashboard:
# git add dashboard.html deploy/dashboard-html/server.js supabase-client.js deploy/supabase-config.js
git status
git commit -m "Dashboard: actualización (Build 82)"
git push origin main
```

---

## 3. En el servidor: actualizar y desplegar

Conectate por SSH al servidor y ejecutá:

```bash
cd /root/checkin24hs
git pull origin main
bash scripts/deploy_dashboard_servidor.sh
```

Ese script:

1. Hace `git fetch` + `git reset --hard origin/main` + `git pull`.
2. Lee **BUILD_ID** de `deploy/dashboard-html/BUILD_ID`.
3. Construye la imagen **sin caché** (`--no-cache`) con tag `easypanel/checkin24hs/dashboard:BUILD_ID` (y `:latest`).
4. Actualiza el servicio Docker Swarm para usar esa imagen (ej. `:82`).

---

## 4. Verificar

- En el servidor (reemplazá `v87` por el build que desplegaste, ej. `v82`, `v87`):
  ```bash
  curl -s https://dashboard.checkin24hs.com/v87/build_id.txt
  curl -s https://dashboard.checkin24hs.com/v87/ | grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*"
  ```
  Deberían devolver el número de build que pusiste (ej. 87 si actualizaste a 87).

- En el navegador: abrí **https://dashboard.checkin24hs.com/** o **/v87/** (o la ruta de tu build) y recargá con **Ctrl+Shift+R**. En el sidebar debería verse **Build #87** (o el número que hayas puesto).

Si ves un build viejo, probá **borrar datos del sitio** solo para `dashboard.checkin24hs.com` o usar la URL con número de versión (ej. `/v87/`).

---

## Resumen rápido

| Dónde | Qué hacer |
|------|-----------|
| **PC** | 1) Si editás `dashboard.html` en raíz → copiarlo a `deploy/dashboard.html`. 2) Subir BUILD_ID y DASHBOARD_BUILD_NUMBER en deploy. 3) `git add`, `commit`, `push`. |
| **Servidor** | `cd /root/checkin24hs` → `git pull` → `bash scripts/deploy_dashboard_servidor.sh` |
| **Navegador** | Recarga forzada (Ctrl+Shift+R) o borrar datos del sitio si sigue viendo build viejo. |

---

## Importante

- **No uses "Implementar" / "Deploy" en EasyPanel** para este dashboard: el servicio queda fijado a la imagen con tag **:BUILD_ID** (ej. `:82`) para que no se pise con otra build automática.
- Si algo se ve viejo después del deploy: **build sin caché** ya lo hace el script; si el HTML sigue desactualizado, revisá que `deploy/dashboard.html` tenga los cambios y que hayas hecho push y pull antes de correr el script.

---

## Deploy según servicio (resumen)

| Servicio | Qué incluye | Cómo actualizar |
|----------|-------------|-----------------|
| **Dashboard** | dashboard.html, flor-ai-service.js (Flor en chat web), supabase-client, etc. | `git pull` → `bash scripts/deploy_dashboard_servidor.sh` — **NO** usar Redeploy en EasyPanel |
| **WhatsApp** | Flor IA en WhatsApp (whatsapp-server-baileys.js) | EasyPanel → Servicio WhatsApp → **Redeploy** |
