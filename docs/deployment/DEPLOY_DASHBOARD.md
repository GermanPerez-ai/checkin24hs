# Pasos para actualizar el dashboard en el servidor

**Proceso oficial** cada vez que quieras que **dashboard.checkin24hs.com** tenga los últimos cambios (HTML, JS, estructura, etc.).

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

3. **(Opcional)** Si querés una URL tipo `/v82/` para evitar caché del navegador:
   - En **`deploy/dashboard-html/server.js`** agregá el mismo patrón que para `/v81/` y `/v82/` pero para el nuevo número (ej. para 83: `else if (urlPath.startsWith('/v83'))` y el `replace` correspondiente).
   - En **EasyPanel** podés apuntar el dominio o una ruta a `/v82/` (o al número que uses).

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

- En el servidor:
  ```bash
  curl -s https://dashboard.checkin24hs.com/v81/build_id.txt
  curl -s https://dashboard.checkin24hs.com/v81/ | grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*"
  ```
  Deberían devolver el número de build que pusiste (ej. 82 si actualizaste a 82). Usá la ruta `/v82/` si configuraste esa versión.

- En el navegador: abrí **https://dashboard.checkin24hs.com/** o **/v81/** (o la ruta que uses) y recargá con **Ctrl+Shift+R**. En el sidebar debería verse **Build #82** (o el número que hayas puesto).

Si ves un build viejo, probá **borrar datos del sitio** solo para `dashboard.checkin24hs.com` o usar la URL con número de versión (ej. `/v82/` si la configuraste).

---

## Resumen rápido

| Dónde | Qué hacer |
|-------|-----------|
| **PC** | 1) Si editás `dashboard.html` en raíz → copiarlo a `deploy/dashboard.html`. 2) Subir BUILD_ID y DASHBOARD_BUILD_NUMBER en deploy. 3) `git add`, `commit`, `push`. |
| **Servidor** | `cd /root/checkin24hs` → `git pull` → `bash scripts/deploy_dashboard_servidor.sh` |
| **Navegador** | Recarga forzada (Ctrl+Shift+R) o borrar datos del sitio si sigue viendo build viejo. |

---

## 5. Si no se actualizó – diagnóstico (en el servidor)

Ejecutá esto en el servidor para ver por qué no ves los cambios:

```bash
# 1) ¿El repo tiene el dashboard actualizado?
cd /root/checkin24hs   # o la ruta donde esté el repo (puede ser /root/Checkin24hs)
grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*" deploy/dashboard.html
# Debe mostrar el número que pusiste (ej. 85).

# 2) ¿Existe el servicio dashboard y qué imagen usa?
docker service ls | grep -i dashboard
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'
# Debe ser algo como easypanel/checkin24hs/dashboard:85. Si el tag es viejo, el script no actualizó.

# 3) Si el nombre del servicio es otro (ej. checkin24hs_dashboard_xxx), listar todos:
docker service ls

# 4) ¿El build terminó bien? Al correr el script, si falla en "COPY" o "RUN", no llega a actualizar el servicio.
# Volvé a ejecutar y mirá si hay error:
bash scripts/deploy_dashboard_servidor.sh

# 5) ¿Qué responde el dashboard en vivo?
curl -sI https://dashboard.checkin24hs.com/
curl -s https://dashboard.checkin24hs.com/ | grep -o "DASHBOARD_BUILD_NUMBER = [0-9]*"
# Si sale el número nuevo (ej. 85), el servidor ya sirve la nueva versión; el problema es caché del navegador (Ctrl+Shift+R o borrar datos del sitio).
```

**Causas frecuentes:**

- **No hiciste push** desde la PC → en el servidor `git pull` no trae el nuevo `deploy/dashboard.html`.
- **Build falla** (ej. falta un archivo que copia el Dockerfile) → el script corta y no hace `docker service update`.
- **Nombre del servicio distinto** → el script usa `checkin24hs_dashboard`; si en tu servidor es otro, `docker service update` falla. Ajustá el nombre en `scripts/deploy_dashboard_servidor.sh` en la última línea.
- **Caché del navegador** → el servidor ya sirve el HTML nuevo pero el navegador muestra el viejo. Recarga forzada (Ctrl+Shift+R) o borrar datos del sitio para `dashboard.checkin24hs.com`.

---

## Importante

- **No uses "Implementar" / "Deploy" en EasyPanel** para este dashboard: el servicio queda fijado a la imagen con tag **:BUILD_ID** (ej. `:85`) para que no se pise con otra build automática.
- Si algo se ve viejo después del deploy: **build sin caché** ya lo hace el script; si el HTML sigue desactualizado, revisá que `deploy/dashboard.html` tenga los cambios y que hayas hecho push y pull antes de correr el script.
