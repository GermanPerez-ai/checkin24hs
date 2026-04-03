# 🔧 Comandos para Ejecutar en el Servidor

## Paso 1: Actualizar el proxy con el contenedor activo

Ejecuta estos comandos uno por uno:

```bash
# 1. Obtener el nombre del contenedor más reciente del dashboard
DASHBOARD_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor dashboard: $DASHBOARD_NAME"

# 2. Obtener el ID del contenedor del proxy más reciente
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
echo "Contenedor proxy: $PROXY_ID"

# 3. Crear el archivo nginx.conf actualizado
cat > /tmp/nginx.conf <<'NGINX_EOF'
# Resolver DNS de Docker (127.0.0.11)
resolver 127.0.0.11 valid=10s ipv6=off;

server {
    listen 80;
    server_name localhost;

    location / {
        set $backend_upstream DASHBOARD_NAME_PLACEHOLDER;
        proxy_pass http://$backend_upstream:3000;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        proxy_buffering off;
        proxy_request_buffering off;
        
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_next_upstream_tries 1;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

# 4. Reemplazar el placeholder con el nombre real
sed -i "s/DASHBOARD_NAME_PLACEHOLDER/$DASHBOARD_NAME/g" /tmp/nginx.conf

# 5. Copiar al contenedor del proxy
docker cp /tmp/nginx.conf $PROXY_ID:/etc/nginx/conf.d/default.conf

# 6. Verificar sintaxis
docker exec $PROXY_ID nginx -t

# 7. Si la sintaxis es correcta, recargar Nginx
if [ $? -eq 0 ]; then
    docker exec $PROXY_ID nginx -s reload
    echo "✅ Proxy actualizado correctamente"
    echo "✅ Apunta a: $DASHBOARD_NAME"
else
    echo "❌ Error en la configuración de Nginx"
fi

# 8. Limpiar
rm -f /tmp/nginx.conf
```

## Paso 2: Verificar que funciona

```bash
# Probar desde dentro del contenedor del proxy
docker exec $PROXY_ID wget -qO- http://localhost/health
```

Debería devolver: `healthy`

## Paso 3: Verificar configuración del dominio en EasyPanel

1. Ve a EasyPanel → Servicios → `dashboard-proxy`
2. Verifica que el dominio `dashboard.checkin24hs.com` esté configurado
3. El destino debería ser: `http://checkin24hs_dashboard-proxy:80/`
