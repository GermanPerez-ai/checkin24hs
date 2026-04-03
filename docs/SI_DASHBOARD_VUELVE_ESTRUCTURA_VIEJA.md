# Si el dashboard vuelve a la estructura antigua

## Qué pasó

El servidor está mostrando la **estructura vieja** (por ejemplo sin la sección "Prompt General" en Flor IA, o con menú distinto) aunque diga Build #80 u otro número. Eso suele pasar cuando:

1. **EasyPanel** hace un "Redeploy" o "Sync" y reconstruye la imagen **con caché** → se usa una capa vieja con `dashboard.html` antiguo.
2. Alguien reinició el servicio y el contenedor arrancó con una **imagen vieja** que seguía en el servidor.
3. El servidor no tiene el último código (no se hizo `git pull` antes del build).

## Cómo volver a la versión correcta (Build #81)

El repo ya tiene **Build #81** y el Dockerfile usa **`dashboard.html` de la raíz** (la misma versión que abrís en local). Para que el servidor sirva esa versión:

### En tu PC

```powershell
cd C:\Users\German\Downloads\Checkin24hs
git add dashboard.html deploy/dashboard-html/BUILD_ID deploy/dashboard-html/Dockerfile
git commit -m "Dashboard Build #81: forzar imagen nueva (evitar caché que devuelve estructura vieja)"
git push
```

### En el servidor (SSH)

Ejecutá **siempre** el script de deploy (así se hace build **sin caché** y se actualiza el servicio):

```bash
cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh
```

Eso hace:

- `git pull` → trae el último código (dashboard.html de la raíz, Build #81).
- `docker build ... --no-cache` → construye una imagen nueva, sin usar capas viejas.
- `docker service update --force checkin24hs_dashboard` → el servicio usa la imagen nueva.

Después abrí **https://dashboard.checkin24hs.com** y recargá con **Ctrl+Shift+R**. Deberías ver **Build #81** y la estructura actual (Flor IA con 7 pestañas, Prompt General, etc.).

## Para que no vuelva a pasar

- **No uses "Redeploy" desde EasyPanel** para el dashboard; usá solo el flujo: push desde tu PC y en el servidor `git pull` + `scripts/deploy_dashboard_servidor.sh`.
- Si en EasyPanel hay algo tipo "Redeploy automático" o "Sync", desactivalo para el stack del dashboard, o después de cada redeploy ejecutá de nuevo el script en el servidor.
