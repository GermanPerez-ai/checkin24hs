# Resolver el problema "Build #5" en el dashboard

## Qué pasaba

- El navegador mostraba **Build #5** aunque la versión esperada era #77/#79.
- No era solo caché del navegador (también pasaba en incógnito).
- Causas posibles: imagen Docker vieja en el servicio (caché de build) y/o algún proxy/Traefik cacheando el HTML.

## Qué hicimos para resolverlo de raíz

### 1. Forzar imagen nueva en cada deploy (BUILD_ID)

- **`docker-compose.easypanel.yml`**: el servicio `dashboard` tiene `args: BUILD_ID: "79"` (subir a 80, 81… en cada deploy).
- **`deploy/dashboard-html/Dockerfile`**: usa `ARG BUILD_ID` y escribe ese valor en `/app/build_id.txt`.
- **`deploy/dashboard-html/BUILD_ID`**: archivo con el número (79); al cambiarlo se invalida la caché de Docker si se construye desde Git.

Así cada deploy con un BUILD_ID nuevo obliga a construir una imagen nueva y evita que Swarm siga con la imagen antigua (#5).

### 2. Que nadie cachee el HTML

- **Servidor Node** (`deploy/dashboard-html/server.js`): el HTML (`dashboard.html`) y `/build_id.txt` se sirven con:
  - `Cache-Control: no-store, no-cache, must-revalidate, max-age=0`
  - `Pragma: no-cache`
  - `Expires: 0`
- **Traefik**: el router del dashboard usa el middleware `dashboard-nocache`, que añade esas mismas cabeceras a la respuesta. Así, aunque algo intermedio intente cachear, Traefik también indica “no cachear”.

### 3. Verificación después de cada deploy

1. Abrir **https://dashboard.checkin24hs.com/build_id.txt**  
   Debe mostrar el número nuevo (79, 80, etc.).
2. Si sigue saliendo 5 (o un número viejo), en el servidor:
   ```bash
   cd /root/Checkin24hs   # o la ruta de tu repo
   git pull
   docker build -f deploy/dashboard-html/Dockerfile --build-arg BUILD_ID=79 -t easypanel/checkin24hs/dashboard:latest .
   docker service update --force checkin24hs_dashboard
   ```
   Luego volver a comprobar `build_id.txt` y la página del dashboard.

## Flujo recomendado en cada actualización

1. En el repo (local): subir **BUILD_ID** en `docker-compose.easypanel.yml` y en `deploy/dashboard-html/BUILD_ID` (ej. 79 → 80).
2. `git add`, `git commit -m "Bump BUILD_ID to 80"`, `git push`.
3. En EasyPanel: **Deploy / Redeploy from Compose** (para que use el compose actualizado y los labels de Traefik se mantengan).
4. Comprobar **https://dashboard.checkin24hs.com/build_id.txt** (debe mostrar 80).
5. Si no se actualiza, usar el flujo manual del punto 3 anterior en el servidor.

Con esto el problema del Build #5 queda resuelto desde el build, el servicio y la caché (app + Traefik).
