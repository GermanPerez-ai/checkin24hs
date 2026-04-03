# 🔧 Estabilizar Servicio

## Problema:
- El servicio se pone amarillo cuando hacemos cambios
- Necesitamos estabilizarlo primero

## Solución:

```bash
# 1. Ver estado actual
echo "=== Estado del servicio ==="
docker service ps checkin24hs_dashboard-proxy --no-trunc | head -3

# 2. Estabilizar el servicio
echo ""
echo "=== Estabilizando ==="
docker service scale checkin24hs_dashboard-proxy=0
sleep 5
docker service scale checkin24hs_dashboard-proxy=1
sleep 20

# 3. Verificar que está estable
echo ""
echo "=== Verificando estado ==="
docker service ps checkin24hs_dashboard-proxy --no-trunc | head -3
docker ps | grep dashboard-proxy

# 4. Actualizar el proxy con la IP correcta (por si cambió)
echo ""
echo "=== Actualizando proxy con IP correcta ==="
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
DASHBOARD_IP=$(docker inspect $DASHBOARD_ID | grep -A 5 '"easypanel"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

cat > /tmp/nginx.conf <<EOF
resolver 127.0.0.11 valid=10s ipv6=off;
server {
    listen 80;
    server_name localhost;
    location / {
        proxy_pass http://$DASHBOARD_IP:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
        proxy_request_buffering off;
    }
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

docker cp /tmp/nginx.conf $PROXY_ID:/etc/nginx/conf.d/default.conf
docker exec $PROXY_ID nginx -t && docker exec $PROXY_ID nginx -s reload && echo "✅ Proxy actualizado" || echo "❌ Error"
rm -f /tmp/nginx.conf
```
