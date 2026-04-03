# Cómo actualizar el dashboard (y que no lo pisen otras versiones)

El dashboard online (**https://dashboard.checkin24hs.com/**) se actualiza **solo** con este flujo. Si usás otro (EasyPanel Redeploy, docker compose para el dashboard, etc.), se puede volver a servir una versión vieja del repo.

---

## Flujo único para el dashboard

1. **En tu PC** (PowerShell, carpeta del repo):
   ```powershell
   scp dashboard.html root@72.61.58.240:~/checkin24hs/
   ```

2. **En el servidor** (SSH):
   ```bash
   cd ~/checkin24hs
   ./BUILD_DASHBOARD_CON_LOGS.sh
   ```

3. Esperar 1–2 min y probar https://dashboard.checkin24hs.com/ (incógnito o Ctrl+Shift+R).

---

## Qué no hacer

- **No** redeployar el dashboard desde EasyPanel (Redeploy / Deploy from Compose para esta app si eso reconstruye el dashboard).
- **No** hacer `docker compose ... up --build` para actualizar el dashboard; ese build usa el repo del servidor y puede pisar la versión que subiste con scp.

Los otros servicios (whatsapp, cotizador, webmail) sí se pueden seguir actualizando por compose/EasyPanel si lo necesitás; solo el dashboard se actualiza con scp + script.

---

## Resumen

| Servicio  | Cómo actualizarlo |
|-----------|--------------------|
| **Dashboard** | Solo: scp dashboard.html al servidor + `./BUILD_DASHBOARD_CON_LOGS.sh` |
| Whatsapp, cotizador, webmail | Como antes (compose / EasyPanel si lo usás) |
