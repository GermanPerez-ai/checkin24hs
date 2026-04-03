# 🔧 Usar Alias del Servicio en lugar del Nombre del Contenedor

## Problema
El dominio está correcto, pero el proxy usa el nombre completo del contenedor que cambia cada vez.

## Solución: Usar el alias del servicio

El servicio `dashboard` tiene el alias `checkin24hs_dashboard` que es estable. Podemos actualizar el proxy para usar este alias.

### Actualizar proxy para usar el alias del servicio

```bash
# Obtener ID del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

# Crear nginx.conf usando el alias del servicio (más estable)
cat > /tmp/nginx.conf <<EOF
# Resolver DNS de Docker (127.0.0.11)
resolver 127.0.0.11 valid=10s ipv6=off;

server {
    listen 80;
    server_name localhost;

    location / {
        # Usar el alias del servicio (más estable que el nombre del contenedor)
        set \$backend_upstream checkin24hs_dashboard;
        
        # Proxy al contenedor del dashboard
        proxy_pass http://\$backend_upstream:3000;
        
        # Headers para el proxy
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
        
        # Manejo de errores
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_next_upstream_tries 1;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Copiar al contenedor
docker cp /tmp/nginx.conf $PROXY_CONTAINER_ID:/etc/nginx/conf.d/default.conf

# Verificar y recargar
docker exec $PROXY_CONTAINER_ID nginx -t && docker exec $PROXY_CONTAINER_ID nginx -s reload

echo "✅ Proxy actualizado para usar alias del servicio: checkin24hs_dashboard"
```

### Probar que funciona

```bash
# Probar desde el proxy
docker exec $PROXY_CONTAINER_ID curl -I http://localhost/
```

---

**Si el alias `checkin24hs_dashboard` no se resuelve desde el proxy, necesitaremos verificar que ambos servicios estén en la misma red Docker.**
