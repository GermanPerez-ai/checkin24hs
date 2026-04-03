# 🔍 Encontrar Contenedor Activo del Dashboard

## Problema
El alias `checkin24hs_dashboard` se resuelve pero apunta a IPs que no responden (contenedores antiguos).

## Solución: Encontrar el contenedor activo

```bash
# 1. Ver todos los contenedores del dashboard (activos y detenidos)
docker ps -a | grep dashboard

# 2. Ver solo los contenedores ACTIVOS del dashboard
docker ps | grep dashboard

# 3. Ver la IP del contenedor activo más reciente
ACTIVE_DASHBOARD=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
echo "Contenedor activo: $ACTIVE_DASHBOARD"
docker inspect $ACTIVE_DASHBOARD | grep -A 5 "IPAddress"

# 4. Probar conexión directa a esa IP
ACTIVE_IP=$(docker inspect $ACTIVE_DASHBOARD --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
echo "IP activa: $ACTIVE_IP"
curl -I http://$ACTIVE_IP:3000/
```

## Si la conexión directa funciona

Actualizar el proxy para usar la IP directa o el nombre completo del contenedor.
