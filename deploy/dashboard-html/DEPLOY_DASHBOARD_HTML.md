# Desplegar dashboard.html (Usuario + Contraseña) en dashboard.checkin24hs.com

Este despliegue sirve **dashboard.html** (login con **Usuario** y **Contraseña**, como en local) en lugar del React Admin (email + contraseña).

## Flujo recomendado: EasyPanel + Git (sin bind mounts)

Para actualizar solo con **push a Git** y **Redeploy** en EasyPanel, configurá el servicio dashboard así:

- **Build from Git**, Dockerfile path: `deploy/dashboard-html/Dockerfile`, Context: `.` (raíz del repo).
- **Sin bind mounts** (quitar montajes de /root/checkin24hs/).

Detalle completo: **docs/EASYPANEL_DASHBOARD_GIT_FLUJO.md**.

---

## Build manual (desde la raíz del repo)

```bash
cd ~/checkin24hs
docker build -f deploy/dashboard-html/Dockerfile -t checkin24hs-dashboard-html:latest .
```

## Actualizar el servicio dashboard

```bash
docker service update --image checkin24hs-dashboard-html:latest checkin24hs_dashboard
```

Espera a que converja y prueba **https://dashboard.checkin24hs.com/**.

Login: **Usuario** (ej. `German`, `admin`, `Axel`) + **Contraseña** (ej. `123456`, `admin123`). No uses email.

## Qué incluye

- **dashboard.html** en `/` e `/index.html`
- **supabase-client.js** en `/supabase-client.js`
- **logo.png** en `/logo.png` (opcional)
- **og-cotizar.jpg** desde `hotel-images` (cotizador / WhatsApp)
- Rutas no encontradas → `dashboard.html` (SPA / client-side routing)

## Traefik

No cambia. El servicio `checkin24hs_dashboard` sigue usando las mismas labels de Traefik y puerto 3000. Solo cambia la imagen.

## Volver al React Admin

Si quieres volver al dashboard React (email + contraseña):

```bash
cd ~/checkin24hs/checkin24hs-admin
docker build -t checkin24hs-dashboard:latest .
docker service update --image checkin24hs-dashboard:latest checkin24hs_dashboard
```
