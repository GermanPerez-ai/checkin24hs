# 🔧 Corregir Servicio que se Reinicia

## Problema:
- ❌ Servicio con punto amarillo (reiniciando)
- ❌ Nginx se reinicia constantemente
- ❌ Error 404 al acceder al dominio

## Solución:

1. Verificar estado del servicio
2. Detener el servicio temporalmente
3. Actualizar el proxy con la IP correcta
4. Reiniciar el servicio

## Comandos:

```bash
# 1. Ver estado del servicio
echo "=== Estado del servicio dashboard-proxy ==="
docker service ps checkin24hs_dashboard-proxy

# 2. Ver si hay múltiples contenedores
echo ""
echo "=== Contenedores del proxy ==="
docker ps | grep dashboard-proxy

# 3. Escalar a 0 para detener
echo ""
echo "=== Deteniendo el servicio ==="
docker service scale checkin24hs_dashboard-proxy=0

# 4. Esperar 5 segundos
sleep 5

# 5. Escalar a 1 para reiniciar
echo ""
echo "=== Reiniciando el servicio ==="
docker service scale checkin24hs_dashboard-proxy=1

# 6. Esperar 10 segundos para que inicie
sleep 10

# 7. Actualizar el proxy con la IP correcta
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

# 8. Verificar estado final
echo ""
echo "=== Estado final del servicio ==="
docker service ps checkin24hs_dashboard-proxy
```
