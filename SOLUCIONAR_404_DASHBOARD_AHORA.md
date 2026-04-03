# 404 en https://dashboard.checkin24hs.com/ — Qué hacer ahora

El 404 casi siempre significa: **Traefik no encuentra el servicio dashboard** (contenedor parado, dominio no configurado o puerto incorrecto).

---

## 1. En EasyPanel (empezar acá)

1. **Entrá a EasyPanel** (tu servidor).
2. **Buscá la app** donde está el dashboard (por ejemplo "checkin24hs" o el nombre del proyecto).
3. **Revisá el servicio "dashboard":**
   - ¿Está **Running** (verde)? Si está parado o en error, hacé **Start** o **Redeploy**.
   - **Dominio / Custom domain:** debe estar **dashboard.checkin24hs.com** (sin `https://`, solo el dominio).
   - **Puerto interno:** el contenedor del dashboard escucha en **3000**. Si EasyPanel te pide "puerto interno" o "target port", poné **3000** (no 80).
4. Si cambiaste algo, **guardá** y, si hace falta, **Redeploy** del servicio dashboard.
5. Esperá 1–2 minutos y probá de nuevo: **https://dashboard.checkin24hs.com/**

---

## 2. Si usás "Deploy from Compose"

Si la app se despliega con **docker-compose** (por ejemplo `docker-compose.easypanel.yml`):

- Asegurate de hacer **Redeploy** desde EasyPanel usando ese compose (para que Traefik vuelva a leer los labels).
- El compose ya tiene:
  - `Host(dashboard.checkin24hs.com)`
  - `entrypoints=websecure` (HTTPS)
  - `server.port=3000`

Si después del Redeploy sigue 404, en EasyPanel revisá si el servicio dashboard tiene una pestaña **"Domains"** o **"Routing"** y que figure **dashboard.checkin24hs.com** ahí también.

---

## 3. Si tenés SSH al servidor (opcional)

Para confirmar que el contenedor existe y responde:

```bash
# Servicios que tengan "dashboard"
docker ps -a | grep -i dashboard

# Si usás Docker Compose (nombre tipo checkin24hs-dashboard-1)
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -i dashboard
```

El contenedor del dashboard debe estar **Up** y escuchando en **3000**.  
Si el servicio se llama distinto (por ejemplo `checkin24hs-dashboard-1`), en EasyPanel el dominio tiene que estar asociado a **ese** servicio.

---

## 4. Resumen rápido

| Revisar | Valor correcto |
|--------|------------------|
| Estado del servicio dashboard | Running (verde) |
| Dominio | dashboard.checkin24hs.com |
| Puerto interno del contenedor | 3000 |
| HTTPS | Sí (websecure / LetsEncrypt) |

---

## 5. Mientras tanto: usar tu código local online

Si necesitás el dashboard ya y el 404 tarda en resolverse:

1. En la carpeta del repo ejecutá: **`node servir_dashboard_local.js`**
2. En otra terminal: **`npx ngrok http 3000`**
3. Usá la URL HTTPS que te da ngrok; esa URL sirve tu **dashboard.html** local.

Más detalles en **CORRER_DASHBOARD_LOCAL_ONLINE.md**.
