# Resumen: Dashboard online (procedimiento cerrado)

## Qué quedó resuelto

- El dashboard en **https://dashboard.checkin24hs.com/** muestra la **misma versión** que tenés en tu PC.
- La actualización se hace **solo** con scp + script en el servidor; así no se pisa con versiones del repo.
- El dashboard **no está** en el compose de EasyPanel, así que un "Deploy from Compose" **no lo actualiza por error**.

---

## Procedimiento para actualizar el dashboard

Cada vez que cambies algo en `dashboard.html` y quieras verlo online:

### 1. En tu PC (PowerShell, carpeta del repo)

```powershell
scp dashboard.html root@72.61.58.240:~/checkin24hs/
```

(Te pide la contraseña de root.)

### 2. En el servidor (SSH)

```bash
cd ~/checkin24hs
./BUILD_DASHBOARD_CON_LOGS.sh
```

### 3. Probar

Esperar 1–2 minutos y abrir **https://dashboard.checkin24hs.com/** (incógnito o Ctrl+Shift+R).

---

## Qué no hacer

- **No** redeployar el dashboard desde EasyPanel.
- **No** usar "Deploy from Compose" para actualizar el dashboard (ya no está en el compose).
- **No** confiar en `git push` + `git pull` en el servidor para el dashboard; la fuente de verdad es tu archivo local + scp.

---

## Archivos de referencia

| Archivo | Para qué |
|--------|----------|
| **COMO_ACTUALIZAR_DASHBOARD.md** | Detalle del flujo y qué no hacer |
| **BUILD_DASHBOARD_CON_LOGS.sh** | Script en el servidor (logs + build + actualizar servicio) |
| **docker-compose.easypanel.yml** | Solo whatsapp, cotizador, webmail (dashboard fuera a propósito) |

---

## Resumen en una línea

**Actualizar dashboard:** `scp dashboard.html root@72.61.58.240:~/checkin24hs/` → en el servidor: `./BUILD_DASHBOARD_CON_LOGS.sh`.
