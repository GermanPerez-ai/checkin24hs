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
   Mismo número en:
   - `window.DASHBOARD_BUILD_NUMBER = 178;` (obligatorio)
   - `<span id="build-number">178</span>` (opcional: el JS lo sobrescribe al cargar, pero conviene mantenerlo al día)

3. **(Opcional)** URL con versión para evitar caché del navegador: **`/v178/`** (cualquier `/vNNN/` funciona).  
   `server.js` ya acepta **cualquier** `/v(\d+)/` con regex genérico — **no hace falta** editar `server.js` por cada build nuevo.

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
git commit -m "Dashboard: actualización (Build 178)"
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
4. Actualiza el servicio Docker Swarm para usar esa imagen (ej. `:178`).

**Dockerfile correcto:** `deploy/dashboard-html/Dockerfile` (Node).  
**No uses** `deploy/Dockerfile` (nginx estático): no genera `build_id.txt` y no es el que corre en producción.

---

## 4. Verificar

- En el servidor (reemplazá `178` por tu BUILD_ID):
  ```bash
  curl -s https://dashboard.checkin24hs.com/build_id.txt
  curl -s https://dashboard.checkin24hs.com/v178/build_id.txt
  curl -s https://dashboard.checkin24hs.com/dashboard.html | grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*"
  curl -s https://dashboard.checkin24hs.com/dashboard.html | grep -o enrichChatsInstanceFromMessages | head -1
  ```
  Deberían devolver **178** (o el número que pusiste en BUILD_ID).

- En el navegador: **https://dashboard.checkin24hs.com/** o **/v178/** y recarga **Ctrl+Shift+R**. En el sidebar: **Build #178**.

Si ves un build viejo, probá **borrar datos del sitio** solo para `dashboard.checkin24hs.com` o usar la URL con número de versión (ej. `/v82/` si la configuraste).

---

## Resumen rápido

| Dónde | Qué hacer |
|------|-----------|
| **PC** | 1) Si editás `dashboard.html` en raíz → copiarlo a `deploy/dashboard.html`. 2) Subir BUILD_ID y DASHBOARD_BUILD_NUMBER en deploy. 3) `git add`, `commit`, `push`. |
| **Servidor** | `cd /root/checkin24hs` → `git pull` → `bash scripts/deploy_dashboard_servidor.sh` |
| **Navegador** | Recarga forzada (Ctrl+Shift+R) o borrar datos del sitio si sigue viendo build viejo. |

---

## Importante

- **No uses "Implementar" / "Deploy" en EasyPanel** para este dashboard: el servicio queda fijado a la imagen con tag **:BUILD_ID** (ej. `:178`) para que no se pise con otra build automática.
- **No construyas con** `docker build -f deploy/Dockerfile` — ese es nginx, no el dashboard en producción.
- Si algo se ve viejo después del deploy: **build sin caché** ya lo hace el script; si el HTML sigue desactualizado, revisá que `deploy/dashboard.html` tenga los cambios y que hayas hecho push y pull antes de correr el script.
