# Actualizar dashboard (server) para que /og-cotizar.jpg funcione

Tu dashboard en producción usa **bind mounts** desde `/root/checkin24hs/`:
- `server.js`
- `dashboard.html`
- `supabase-client.js`

Para que **https://dashboard.checkin24hs.com/og-cotizar.jpg** devuelva la imagen **antes** de actualizar el server:

---

## 1. Copiar la imagen al host

En el servidor (SSH), copia una imagen a la misma carpeta que el server:

```bash
# Si tenés hotel-images en el host (ej. /root/checkin24hs/hotel-images/):
cp /root/checkin24hs/hotel-images/hotel-1-puyehue/main.jpg /root/checkin24hs/og-cotizar.jpg
```

Si **no** tenés `hotel-images` en el host, subí desde tu PC una imagen (por ejemplo `checkin24hs-admin/public/og-cotizar.jpg` o `hotel-images/hotel-1-puyehue/main.jpg`) a `/root/checkin24hs/og-cotizar.jpg` (con scp, rsync o el método que uses).

---

## 2. Actualizar server.js en el host

El `server.js` que usa el dashboard debe tener la ruta `/og-cotizar.jpg` y **prioridad 0** para el archivo local `og-cotizar.jpg` en la misma carpeta.

- Si usás el de **deploy/dashboard-html/server.js**: ya está actualizado en el repo (prioridad: `og-cotizar.jpg` en rootDir, luego hotel-images).
- Copialo al host:

```bash
# Desde tu PC (en la carpeta del repo), subir server.js al servidor:
scp deploy/dashboard-html/server.js root@TU_SERVIDOR:/root/checkin24hs/server.js
```

O en el servidor, si clonás el repo:

```bash
cp /ruta/al/repo/deploy/dashboard-html/server.js /root/checkin24hs/server.js
```

---

## 3. Reiniciar el servicio

```bash
docker service update --force checkin24hs_dashboard
```

---

## 4. Verificar

Abrir en el navegador:

**https://dashboard.checkin24hs.com/og-cotizar.jpg**

Deberías ver la imagen (no el HTML del login).

---

## Resumen

| Paso | Acción |
|------|--------|
| 1 | Tener `og-cotizar.jpg` en `/root/checkin24hs/og-cotizar.jpg` en el host |
| 2 | Tener `server.js` actualizado en `/root/checkin24hs/server.js` (con prioridad local para og-cotizar.jpg) |
| 3 | `docker service update --force checkin24hs_dashboard` |
| 4 | Probar https://dashboard.checkin24hs.com/og-cotizar.jpg |

Para futuras actualizaciones del dashboard: actualizá los archivos en `/root/checkin24hs/` (server.js, dashboard.html, supabase-client.js y, si querés cambiar la imagen, og-cotizar.jpg) y reiniciá con `docker service update --force checkin24hs_dashboard`.
