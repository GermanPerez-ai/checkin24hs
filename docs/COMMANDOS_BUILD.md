# Comandos de build – Checkin24hs

## Dashboard (dashboard.checkin24hs.com)

### En tu PC (antes de subir)

1. **Sincronizar HTML a deploy** (si editás `dashboard.html` en la raíz):
   ```powershell
   Copy-Item -Path "dashboard.html" -Destination "deploy\dashboard.html" -Force
   ```
   En Linux/Mac:
   ```bash
   cp dashboard.html deploy/dashboard.html
   ```

2. **Subir número de build** (opcional pero recomendado):  
   Editá `deploy/dashboard-html/BUILD_ID` y poné un número nuevo (ej. `95`).  
   Si usás rutas por versión en el servidor, actualizá también `deploy/dashboard.html` (buscar `build-number`) y `deploy/dashboard-html/server.js` para la nueva ruta `/v95/`.

3. **Commit y push**:
   ```bash
   git add deploy/dashboard.html deploy/dashboard-html/BUILD_ID
   git commit -m "Dashboard: novedades slug único automático"
   git push origin main
   ```

### En el servidor (SSH)

```bash
cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh
```

Eso hace: pull del repo, build de la imagen sin caché con el `BUILD_ID` de `deploy/dashboard-html/BUILD_ID`, y actualiza el servicio `checkin24hs_dashboard`.

**Verificar:**  
https://dashboard.checkin24hs.com/build_id.txt debe mostrar el número de build.

---

## Web pública (checkin24hs.com / React + Vite)

### Build local

```bash
cd checkin24hs-web
npm install
npm run build
```

El build usa `tsc -b && vite build`. La salida queda en `checkin24hs-web/dist/`.

**Variables de entorno** (para build en servidor/EasyPanel):  
`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`.

### Preview local

```bash
cd checkin24hs-web
npm run dev
```

---

## Otros

| Qué | Comando |
|-----|--------|
| Cotización (raíz) | `npm start` o `node server.js` |
| Dashboard local (raíz) | `npm run dashboard` (si existe) |
| Flor API (Docker) | `docker compose -f docker-compose.easypanel.yml build --no-cache flor-api` |
| WhatsApp server | `cd whatsapp-server && npm install && node whatsapp-server-baileys.js` (o el que uses) |

---

## Resumen rápido – solo Dashboard

**PC:**  
`Copy-Item dashboard.html deploy\dashboard.html` → subir `BUILD_ID` si querés → `git add` / `commit` / `push`

**Servidor:**  
`cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh`

**Navegador:**  
Ctrl+Shift+R en dashboard.checkin24hs.com (o borrar datos del sitio si sigue en build viejo).
