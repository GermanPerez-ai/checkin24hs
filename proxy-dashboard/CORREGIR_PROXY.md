# 🔧 Corregir Problemas del Proxy

## Problemas detectados:
1. ❌ Health check falla (Connection refused)
2. ❌ No puede resolver el nombre del contenedor del dashboard
3. ⚠️ Múltiples contenedores del proxy activos

## Solución: Usar alias del servicio en lugar del nombre completo

El problema es que estamos usando el nombre completo del contenedor (`checkin24hs_dashboard.1.xxx`), pero deberíamos usar el alias del servicio que Docker Swarm crea automáticamente.

Ejecuta estos comandos:

```bash
# 1. Verificar qué alias tiene el servicio dashboard
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq

# 2. Obtener el ID del contenedor del proxy más reciente (el que actualizamos)
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
echo "Proxy ID: $PROXY_ID"

# 3. Verificar en qué red está el proxy
docker inspect $PROXY_ID | grep -A 20 "Networks" | grep -E "(easypanel|checkin24hs)"

# 4. Crear nueva configuración usando el alias del servicio
cat > /tmp/nginx.conf <<'EOF'
# Resolver DNS de Docker (127.0.0.11)
resolver 127.0.0.11 valid=10s ipv6=off;

server {
    listen 80;
    server_name localhost;

    location / {
        # Usar el alias del servicio (no el nombre completo del contenedor)
        set $backend_upstream checkin24hs_dashboard;
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
EOF

# 5. Copiar al contenedor
docker cp /tmp/nginx.conf $PROXY_ID:/etc/nginx/conf.d/default.conf

# 6. Verificar y recargar
docker exec $PROXY_ID nginx -t && docker exec $PROXY_ID nginx -s reload && echo "✅ Actualizado" || echo "❌ Error"

# 7. Probar
echo "🧪 Probando health check..."
docker exec $PROXY_ID wget -qO- http://localhost/health

echo ""
echo "🧪 Probando conexión al dashboard..."
docker exec $PROXY_ID wget -qO- http://checkin24hs_dashboard:3000/health

# 8. Limpiar
rm -f /tmp/nginx.conf
```
