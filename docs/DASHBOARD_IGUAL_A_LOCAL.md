# Hacer que dashboard.checkin24hs.com muestre lo mismo que tu archivo local

Objetivo: que **https://dashboard.checkin24hs.com/** sea **idéntico** a **file:///C:/Users/German/Downloads/Checkin24hs/dashboard.html**.

---

## Flujo (2 pasos)

### 1. En tu PC (local)

Ejecutá el script que sube al repo lo que tenés en local:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
.\scripts\subir_dashboard_como_local.ps1
```

- Agrega `dashboard.html`, `deploy/dashboard.html`, `server.js`, `Dockerfile`, `BUILD_ID`, `docker-compose.easypanel.yml`, `supabase-client.js`.
- Te pide mensaje de commit (o usa "Dashboard: subir como local").
- Hace `git commit` y `git push`.

### 2. En el servidor (SSH)

Conectate y ejecutá **un solo comando** (el script hace pull, build y service update):

```bash
cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh
```

- El script lee el `BUILD_ID` del repo (`deploy/dashboard-html/BUILD_ID`), hace `git pull`, construye la imagen sin caché y ejecuta `docker service update --force checkin24hs_dashboard`.
- Cuando termine, recargá **https://dashboard.checkin24hs.com** (Ctrl+Shift+R).

---

## Resultado

Lo que está en tu **archivo local** (después del push) es lo que queda en el **repo** y, tras el script en el servidor, lo que sirve **dashboard.checkin24hs.com**. Mismo HTML, mismo Build #, misma UI.

---

## Si subís de build (80, 81…)

1. En tu PC: actualizá el número en `docker-compose.easypanel.yml` (args BUILD_ID), en `deploy/dashboard-html/BUILD_ID`, en el Dockerfile (ARG BUILD_ID) y en `dashboard.html` / `deploy/dashboard.html` (DASHBOARD_BUILD_NUMBER y el texto "Build #XX").
2. Ejecutá `.\scripts\subir_dashboard_como_local.ps1` y luego en el servidor `cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh`.

El script del servidor usa el `BUILD_ID` del repo, no hace falta editarlo en el servidor.
