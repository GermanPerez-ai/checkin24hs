# Dashboard en EasyPanel: flujo Git → Redeploy (sin bind mounts)

Objetivo: que el dashboard se actualice **solo** con **push a Git** y **Redeploy** en EasyPanel, sin copiar archivos al host ni usar bind mounts.

---

## 1. Configurar el servicio dashboard en EasyPanel

### 1.1 Build desde Git (no desde imagen pre-construida)

En EasyPanel, en el servicio **checkin24hs_dashboard** (o "dashboard"):

1. **Source / Build:**
   - Tipo: **Build from Git** (o "Repository" / "Git").
   - Repo: tu repositorio (ej. `https://github.com/tu-usuario/Checkin24hs` o la URL que uses).
   - Branch: `main` (o la rama que uses).
   - **Dockerfile path:** `deploy/dashboard-html/Dockerfile`
   - **Build context:** `.` (punto = raíz del repo). No usar un subdirectorio; el Dockerfile espera estar en la raíz para hacer `COPY dashboard.html ./`, etc.

2. **Quitar bind mounts:**
   - En la sección **Volumes** / **Mounts**, **eliminá** todos los bind mounts que apunten a `/root/checkin24hs/` (server.js, dashboard.html, supabase-client.js, og-cotizar.jpg).
   - El contenedor debe usar **solo** lo que viene dentro de la imagen (construida desde Git).

3. **Resto de la configuración:**
   - Puerto interno: **3000** (como ya tenés).
   - Labels de Traefik para **dashboard.checkin24hs.com** (no los toques si ya funcionan).
   - Variables de entorno si las usás (opcional).

4. Guardar y hacer **Redeploy** (o **Build & Deploy**) para que EasyPanel construya la imagen desde el repo y levante el servicio sin montar nada del host.

---

## 2. Flujo de trabajo diario

### En tu PC (PowerShell)

1. Hacés los cambios en el dashboard (por ejemplo en `dashboard.html`, `supabase-client.js`, `deploy/dashboard-html/server.js`, o la imagen `hotel-images/hotel-images/og-preview.jpg`).
2. Subís a Git:

```powershell
cd c:\Users\German\Downloads\Checkin24hs
git add dashboard.html supabase-client.js deploy/
git add hotel-images/hotel-images/og-preview.jpg
git status
git commit -m "Dashboard: actualización de [lo que cambiaste]"
git push
```

### En EasyPanel

1. Entrás a EasyPanel (puerto 8090 en tu VPS).
2. Abrís el servicio **checkin24hs_dashboard**.
3. Clic en **Redeploy** (o **Build & Deploy** / **Rebuild**).
4. EasyPanel hace pull del repo, build con `deploy/dashboard-html/Dockerfile` y despliega la nueva imagen. No hace falta tocar el servidor por SSH ni copiar archivos.

---

## 3. Qué incluye la imagen (Dockerfile)

- `dashboard.html` (login Usuario + Contraseña)
- `supabase-client.js`
- `server.js` (deploy/dashboard-html/server.js)
- `logo.png`
- `hotel-images/` (para fotos de hoteles)
- **og-cotizar.jpg** (imagen promocional para WhatsApp / Open Graph), copiada desde `hotel-images/hotel-images/og-preview.jpg`

Todo eso queda **dentro de la imagen**; no depende de archivos en `/root/checkin24hs/`.

---

## 4. Si EasyPanel no tiene "Build from Git"

Algunas instalaciones de EasyPanel permiten solo "Deploy from image". En ese caso:

**Opción A – Build en tu PC o en el servidor y subir la imagen:**

Desde la raíz del repo (PowerShell o servidor):

```bash
docker build -f deploy/dashboard-html/Dockerfile -t easypanel/checkin24hs/dashboard:latest .
docker push easypanel/checkin24hs/dashboard:latest
```

Luego en EasyPanel: servicio dashboard → **Redeploy** (para que use la nueva imagen). El flujo sería: cambios en Git → build + push de imagen → Redeploy.

**Opción B – Build en el VPS por SSH después de un git pull:**

```bash
cd /root/checkin24hs
git pull
docker build -f deploy/dashboard-html/Dockerfile -t easypanel/checkin24hs/dashboard:latest .
docker service update --image easypanel/checkin24hs/dashboard:latest checkin24hs_dashboard
```

---

## 5. Resumen

| Paso | Dónde | Acción |
|------|--------|--------|
| 1 | EasyPanel | Configurar dashboard: Build from Git, Dockerfile `deploy/dashboard-html/Dockerfile`, context `.`, **sin bind mounts** |
| 2 | PowerShell | `git add` → `git commit` → `git push` |
| 3 | EasyPanel | **Redeploy** del servicio dashboard |
| 4 | Navegador | Probar https://dashboard.checkin24hs.com y https://dashboard.checkin24hs.com/og-cotizar.jpg |

Así el dashboard vuelve a un flujo normal: código en Git y redeploy en EasyPanel, sin depender de bind mounts ni de copiar archivos al host.
