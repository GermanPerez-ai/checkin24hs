# Servidor igual a local (Build #80)

## Qué se cambió

1. **Dockerfile**  
   Ahora la imagen usa **`deploy/dashboard.html`** en lugar de `dashboard.html` de la raíz. Así, lo que subís en `deploy/dashboard.html` es exactamente lo que se sirve en el servidor (igual que lo que ves en local).

2. **BUILD_ID = 80**  
   Se subió el build a **80** en todos los archivos para forzar una imagen nueva y evitar que el servidor siga usando caché vieja del #79.

## Pasos para que el servidor quede igual a tu local

### En tu PC (en la raíz del repo)

1. Revisá que `deploy/dashboard.html` tenga la versión que querés (la que ves en local).

2. Subir todo y hacer push:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
git add dashboard.html deploy/dashboard.html deploy/dashboard-html/BUILD_ID deploy/dashboard-html/Dockerfile deploy/dashboard-html/server.js supabase-client.js
git status
git commit -m "Dashboard Build #80: servidor usa deploy/dashboard.html (igual a local)"
git push
```

3. Opcional: si preferís usar el script que ya tenés:

```powershell
.\scripts\subir_dashboard_como_local.ps1
```

(Usa el mensaje que quieras; el script hace add, commit, push y te muestra el comando para el servidor.)

### En el servidor (SSH)

Conectate por SSH y ejecutá:

```bash
cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh
```

Eso hace: `git pull`, build con **BUILD_ID=80** (sin caché) y `docker service update --force checkin24hs_dashboard`.

### Después

- Abrí **https://dashboard.checkin24hs.com** y recargá con **Ctrl+Shift+R** (recarga forzada sin caché).
- Deberías ver **Build #80** y la misma interfaz que en local.
- Para comprobar: **https://dashboard.checkin24hs.com/build_id.txt** debe mostrar `80`.

## Si más adelante EasyPanel hace “Redeploy”

Si después de este flujo alguien (o un proceso) hace Redeploy desde EasyPanel, podría volver a construir con caché y servir algo viejo. En ese caso volvé a ejecutar en el servidor:

```bash
cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh
```

O subí el BUILD_ID a 81 (en `deploy/dashboard-html/BUILD_ID`, en `deploy/dashboard.html` y en `dashboard.html`), commit + push, y en el servidor el mismo comando. Así la nueva imagen siempre se construye con el contenido actual del repo.
