# Cómo subir el BUILD_ID del dashboard (adaptado a este repo)

En este repo el compose se llama **`docker-compose.easypanel.yml`** (no `docker-compose.yml`). El servicio `dashboard` ya tiene `build.args.BUILD_ID`. Solo hay que cambiar el número y subir.

---

## A) Si trabajás con Cursor / VS Code en tu PC

1. **Abrir el proyecto**  
   File → Open Folder… → carpeta del proyecto checkin24hs.

2. **Buscar el archivo**  
   En la barra lateral, buscá **`docker-compose.easypanel.yml`** (está en la **raíz** del repo).

3. **Editar el BUILD_ID del dashboard**  
   Buscá la sección:
   ```yaml
   dashboard:
     build:
       context: .
       dockerfile: deploy/dashboard-html/Dockerfile
       args:
         BUILD_ID: "77"   # Subir a 78, 79, 80...
   ```
   Cambiá **`"77"`** por el número que quieras (ej. **`"79"`**).

4. **Guardar**  
   Ctrl+S (o Cmd+S en Mac).

5. **Commit y push**  
   En la terminal integrada (View → Terminal), en la carpeta del proyecto:
   ```powershell
   git status
   git add docker-compose.easypanel.yml
   git commit -m "Update dashboard BUILD_ID to 79"
   git push
   ```
   (Reemplazá `79` por el número que hayas puesto.)

---

## B) Si editás directo en GitHub en el navegador

1. Entrá al repo en GitHub (ej. `GermanPerez-ai/checkin24hs`).
2. En la lista de archivos, hacé clic en **`docker-compose.easypanel.yml`**.
3. Arriba a la derecha, clic en el **lápiz (✏️)** para editar.
4. Buscá la línea:
   ```yaml
   BUILD_ID: "77"
   ```
   y cambiá **`"77"`** por **`"79"`** (o el número que quieras).
5. Bajá hasta "Commit changes", poné un mensaje (ej. `Update dashboard BUILD_ID to 79`) y hacé clic en **Commit changes**.

---

## Después del push

- **Si usás Redeploy from Compose en EasyPanel:** hacé **Redeploy** del stack (así usa el compose con el nuevo BUILD_ID).
- **Si desplegás solo desde Git (Dockerfile):** el BUILD_ID del compose no aplica a ese deploy; en ese caso subí el número en **`deploy/dashboard-html/BUILD_ID`** y en **`dashboard.html`** (DASHBOARD_BUILD_NUMBER y "Build #79"), y después **Implementar** en EasyPanel.
- Por SSH (opcional): `docker service update --force checkin24hs_dashboard` para que use la imagen nueva.

---

**Resumen:** En este repo el archivo es **`docker-compose.easypanel.yml`**; cambiá solo el valor de **`BUILD_ID`** (ej. de `"77"` a `"79"`) y hacé commit + push.
