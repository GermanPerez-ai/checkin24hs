# Actualizar el dashboard solo por SSH (sin subir archivos desde tu PC)

Si **no usas scp** desde tu PC (o solo usas la **consola web** del panel), puedes actualizar el dashboard **directamente en el servidor**. El flujo usa **GitHub** como puente: subes los cambios a GitHub desde tu PC, luego en el servidor bajas desde GitHub y aplicas.

El dashboard se sirve desde **bind mount** en `/root/checkin24hs/dashboard.html`. Se actualiza ese archivo en el host y se reinicia el servicio.

---

## 1. Subir cambios a GitHub (en tu PC)

Desde la carpeta del proyecto (PowerShell o Git Bash):

```bash
git add dashboard.html supabase-client.js
git commit -m "Actualizar dashboard"
git push origin main
```

---

## 2. Conectarte al servidor

- **SSH:** `ssh root@TU_HOST` (o el usuario/host que uses).
- **Consola web del panel:** abre la terminal del panel (p. ej. `root@srv1152402`).

---

## 3. En el servidor: actualizar dashboard (bind mount)

Ejecuta estos **tres comandos** en la consola del servidor:

```bash
cd /root/checkin24hs
curl -sL -o dashboard.html "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"
docker service update --force checkin24hs_dashboard
```

- `curl` descarga el `dashboard.html` desde GitHub y lo guarda en `/root/checkin24hs/` (bind mount).
- `docker service update --force` reinicia el servicio para que sirva el archivo nuevo.

---

## 4. Comprobar

- Espera 30–60 segundos tras el reinicio.
- Abre: **https://dashboard.checkin24hs.com**
- Recarga con **Ctrl+Shift+R** (o ventana de incógnito) para evitar caché.
- Verifica que el build mostrado sea el actual (p. ej. Build #75).

---

## Resumen

| Paso | Dónde      | Qué haces |
|------|------------|-----------|
| 1    | Tu PC      | `git push` (subir a GitHub) |
| 2    | Tu PC      | Conectarte por SSH o consola web del panel |
| 3    | Servidor   | `cd /root/checkin24hs` → `curl -sL -o dashboard.html "..."` → `docker service update --force checkin24hs_dashboard` |

No hace falta **scp** ni **SUBIR_DASHBOARD_AL_SERVIDOR.ps1**; todo se hace en el servidor usando GitHub como fuente.

---

## Alternativa: script REVISAR_Y_ACTUALIZAR_DASHBOARD.sh

Si prefieres usar el script (revisa versiones, ofrece opciones, etc.):

```bash
cd /root/checkin24hs
curl -sL -o REVISAR_Y_ACTUALIZAR_DASHBOARD.sh "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/REVISAR_Y_ACTUALIZAR_DASHBOARD.sh"
chmod +x REVISAR_Y_ACTUALIZAR_DASHBOARD.sh
./REVISAR_Y_ACTUALIZAR_DASHBOARD.sh
```

Si el dashboard usa **bind mount** en `/root/checkin24hs`, la opción 1 del script puede dar *"device or resource busy"* al copiar al contenedor. En ese caso, usa directamente los tres comandos de la sección 3.
