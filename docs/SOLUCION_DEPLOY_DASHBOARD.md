# Solución: desplegar el dashboard (local → servidor)

## El problema que teníamos

- Build #5 en el navegador aunque el repo tenía #79.
- 404 por labels de Traefik que EasyPanel no aplicaba.
- Confusión: el **build** solo actualiza la imagen; los **contenedores** no se recrean solos.

## La solución (flujo que sí funciona)

Cada vez que quieras que el servidor sirva **exactamente** lo que tenés en local:

---

### En tu PC (local)

1. **Subir el código al repo**
   ```powershell
   cd C:\Users\German\Downloads\Checkin24hs
   .\scripts\subir_dashboard_como_local.ps1
   ```
   O a mano: `git add` (dashboard.html, etc.) → `git commit -m "..."` → `git push`.

---

### En el servidor (SSH)

2. **Actualizar el repo y construir la imagen**
   ```bash
   cd /root/checkin24hs
   git fetch origin
   git reset --hard origin/main
   git pull
   docker build -f deploy/dashboard-html/Dockerfile --build-arg BUILD_ID=79 -t easypanel/checkin24hs/dashboard:latest --no-cache .
   ```
   (Cambiá `BUILD_ID=79` por el número que uses; debe coincidir con el del compose y del HTML.)

3. **Recrear los contenedores con la imagen nueva** (obligatorio)
   ```bash
   docker service update --force checkin24hs_dashboard
   ```
   Sin este paso, el servicio sigue usando la imagen vieja; los contenedores **no** se recrean solo por hacer build.

4. **Comprobar**
   - https://dashboard.checkin24hs.com/build_id.txt → debe mostrar 79 (o el build que uses).
   - https://dashboard.checkin24hs.com → recarga con Ctrl+Shift+R.

---

## Resumen en una frase

**Solución:** después de cada `git push`, en el servidor hacé `git pull` → `docker build` → **`docker service update --force checkin24hs_dashboard`**. El último paso es el que hace que los contenedores se recreen con la imagen nueva.

---

## Si usás EasyPanel

- **Redeploy desde EasyPanel** puede usar caché de build o una imagen vieja, y a veces quita los labels de Traefik.
- Para el dashboard, lo más seguro es el flujo manual por SSH (pull + build + service update). Si hacés Redeploy en EasyPanel, después podés tener que volver a aplicar los labels con `docker service update --label-add ...` (ver `docs/DIAGNOSTICO_404_DASHBOARD.md`).

---

## Checklist rápido

| Paso | Dónde | Comando / acción |
|------|--------|-------------------|
| 1 | PC | `.\scripts\subir_dashboard_como_local.ps1` (o git add, commit, push) |
| 2 | Servidor | `cd /root/checkin24hs` → `git pull` |
| 3 | Servidor | `docker build -f deploy/dashboard-html/Dockerfile --build-arg BUILD_ID=79 -t easypanel/checkin24hs/dashboard:latest --no-cache .` |
| 4 | Servidor | **`docker service update --force checkin24hs_dashboard`** |
| 5 | Navegador | Abrir https://dashboard.checkin24hs.com y Ctrl+Shift+R |

Cuando subas de build (80, 81…), actualizá `BUILD_ID` en: `docker-compose.easypanel.yml`, `deploy/dashboard-html/BUILD_ID`, `deploy/dashboard-html/Dockerfile`, y el número en `dashboard.html` / `deploy/dashboard.html`.
