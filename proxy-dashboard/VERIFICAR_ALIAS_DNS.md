# 🔍 Verificar Resolución del Alias

## Diagnosticar por qué el alias no funciona

```bash
# Verificar si el alias se resuelve desde el proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
docker exec $PROXY_CONTAINER_ID nslookup checkin24hs_dashboard

# Verificar si ambos servicios están en la misma red
docker service inspect checkin24hs_dashboard | grep -A 10 "Networks"
docker service inspect checkin24hs_dashboard-proxy | grep -A 10 "Networks"

# Verificar aliases del servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 5 "Aliases"
```

## Si el alias no funciona

Volver a usar el nombre completo del contenedor y crear un script que se ejecute automáticamente.
