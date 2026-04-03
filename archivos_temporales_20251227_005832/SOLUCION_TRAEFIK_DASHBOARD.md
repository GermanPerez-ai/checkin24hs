# Solución: Configurar Traefik para Dashboard en Puerto 3000

## Opción 1: Crear contenedor Nginx que haga proxy (Recomendado)

```bash
# Crear un contenedor Nginx que haga proxy al puerto 3000
docker run -d \
  --name dashboard-nginx-proxy \
  --network easypanel \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label "traefik.http.services.dashboard.loadbalancer.server.port=80" \
  --restart unless-stopped \
  nginx:alpine sh -c "echo 'server { listen 80; location / { proxy_pass http://host.docker.internal:3000; proxy_set_header Host \$host; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
```

## Opción 2: Usar network host (Más simple)

```bash
# Crear contenedor con network host
docker run -d \
  --name dashboard-proxy \
  --network host \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label "traefik.http.routers.dashboard.entrypoints=web" \
  --label "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --restart unless-stopped \
  nginx:alpine sh -c "echo 'server { listen 3000; location / { proxy_pass http://localhost:3000; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
```

## Opción 3: Configurar directamente en Traefik (Si tiene acceso a archivos)

Si puedes acceder a los archivos de Traefik, puedes crear un archivo de configuración estática.

