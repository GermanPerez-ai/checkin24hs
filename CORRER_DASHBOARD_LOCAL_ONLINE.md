# Cómo tener tu dashboard local disponible online (Plan B)

Si después de usar **SUBIR_DASHBOARD_ONLINE.ps1** y hacer Redeploy en EasyPanel el sitio sigue mostrando la versión vieja, podés **servir exactamente lo que tenés en tu PC** y exponerlo por internet. Así no dependés del caché del servidor.

---

## Opción A: Local + ngrok (rápido, sin tocar el servidor)

1. **Abrí una terminal en la carpeta del repo** (donde está `dashboard.html`).

2. **Iniciá el servidor local:**
   ```bash
   node servir_dashboard_local.js
   ```
   Deberías ver: `Dashboard LOCAL en: http://localhost:3000/`

3. **En otra terminal**, exponé el puerto 3000 a internet con ngrok:
   ```bash
   npx ngrok http 3000
   ```
   (La primera vez puede pedirte instalar ngrok; aceptá.)

4. **Copiá la URL HTTPS** que ngrok te muestra (ej. `https://abc123.ngrok.io`). Esa URL sirve **exactamente** tu `dashboard.html` local. Cualquiera con el link puede entrar (mientras ngrok esté corriendo).

5. Para cerrar: en la terminal del servidor `Ctrl+C`; en la de ngrok `Ctrl+C`.

**Ventaja:** Lo que ves es 100% tu código local.  
**Desventaja:** Ngrok es para pruebas; si cerras la terminal se corta. Para uso permanente seguí con el script principal y Redeploy sin caché.

---

## Opción B: Subir de verdad (lo que ya tenés)

1. **Ejecutá el script** (en PowerShell, desde la raíz del repo):
   ```powershell
   .\SUBIR_DASHBOARD_ONLINE.ps1
   ```

2. Hacé **git add**, **commit** y **push** de los archivos que te indique.

3. En **EasyPanel**: Redeploy del dashboard y, **si existe**, activá **"Build without cache"** o **"No cache"**.

4. Esperá 1–2 minutos, entrá a **https://dashboard.checkin24hs.com/** y hacé **Ctrl+Shift+R**.

---

## Resumen

| Querés… | Hacé esto |
|--------|------------|
| Probar tu código local online ya | `node servir_dashboard_local.js` + `npx ngrok http 3000` |
| Que dashboard.checkin24hs.com use tu código | `.\SUBIR_DASHBOARD_ONLINE.ps1` → push → Redeploy (sin caché) |
