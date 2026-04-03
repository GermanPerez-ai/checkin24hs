# Por qué sigue apareciendo la foto antigua en /og-cotizar.jpg

## 1. Probar caché del navegador

Abrí la URL con un parámetro para forzar que no use caché:

- **https://dashboard.checkin24hs.com/og-cotizar.jpg?v=4**

O abrí en **ventana de incógnito** (Ctrl+Shift+N) o hacé **recarga forzada** (Ctrl+Shift+R) en la misma URL.

Si con `?v=4` o en incógnito ves la imagen nueva, era caché. Si no, seguí abajo.

---

## 2. Ver si el contenedor ve el archivo

El server busca la imagen en **la misma carpeta que server.js** (`rootDir/og-cotizar.jpg`). Si el servicio monta **solo archivos** (server.js, dashboard.html, supabase-client.js) y **no** la carpeta entera, **og-cotizar.jpg no existe dentro del contenedor** y se usa la siguiente opción (hotel-images), que puede ser la foto antigua.

En el servidor (SSH):

```bash
# Ver que en el host sí está el archivo
ls -la /root/checkin24hs/og-cotizar.jpg

# Ver el ID del contenedor del dashboard
docker ps | grep dashboard

# Entrar al contenedor y ver si existe og-cotizar.jpg en la carpeta del server
docker exec -it <CONTAINER_ID> sh -c "ls -la /app/og-cotizar.jpg 2>/dev/null || ls -la ."
```

Si **no existe** `/app/og-cotizar.jpg` (o el path que use tu servicio) dentro del contenedor, el servidor está leyendo otra imagen (p. ej. de hotel-images) y por eso ves la foto antigua.

---

## 3. Solución: montar la carpeta entera o solo og-cotizar.jpg

Hay que hacer que el contenedor tenga acceso a `og-cotizar.jpg`.

### Opción A – Montar toda la carpeta (recomendado)

Si hoy montás algo así:

```yaml
# Ejemplo: montes por archivo
- /root/checkin24hs/server.js:/app/server.js
- /root/checkin24hs/dashboard.html:/app/dashboard.html
- /root/checkin24hs/supabase-client.js:/app/supabase-client.js
```

cambialo a **un solo montaje de carpeta**:

```yaml
- /root/checkin24hs:/app
```

Así todo lo que pongas en `/root/checkin24hs/` (incluido `og-cotizar.jpg`) estará en `/app/` dentro del contenedor.

En Docker Swarm (ejemplo):

```bash
docker service update checkin24hs_dashboard \
  --mount-add type=bind,source=/root/checkin24hs,target=/app
```

(O definirlo en el stack/docker-compose y hacer `docker stack deploy`.)

### Opción B – Montar solo og-cotizar.jpg

Si no querés montar toda la carpeta, añadí un montaje solo para la imagen:

```yaml
- /root/checkin24hs/og-cotizar.jpg:/app/og-cotizar.jpg
```

El path `/app` puede ser otro si tu servicio usa otro working dir; ajustalo según tu configuración.

---

## 4. Después de cambiar los montajes

1. Reiniciar el servicio:
   ```bash
   docker service update --force checkin24hs_dashboard
   ```
2. Probar de nuevo: **https://dashboard.checkin24hs.com/og-cotizar.jpg?v=5**

Si el contenedor ya ve `/app/og-cotizar.jpg` (por el montaje) y el archivo en el host es la imagen nueva, dejará de aparecer la foto antigua.
