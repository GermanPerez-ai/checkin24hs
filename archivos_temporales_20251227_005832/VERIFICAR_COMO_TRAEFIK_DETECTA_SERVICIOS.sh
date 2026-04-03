#!/bin/bash

echo "=== Verificar cómo Traefik detecta servicios ==="

# 1. Verificar API de Traefik para ver qué servicios detecta
echo ""
echo "1. Servicios detectados por Traefik (a través de la API):"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Intentando acceder a la API de Traefik..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | python3 -m json.tool 2>/dev/null | head -100 || docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | head -100
fi

# 2. Ver servicios HTTP detectados
echo ""
echo "2. Servicios HTTP detectados por Traefik:"
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/services 2>/dev/null | python3 -m json.tool 2>/dev/null | grep -iE "name|server" | head -30 || docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/services 2>/dev/null | head -50
fi

# 3. Ver logs de Traefik cuando detecta servicios
echo ""
echo "3. Logs de Traefik relacionados con detección de servicios:"
docker service logs traefik --tail 200 | grep -iE "dashboard|checkin24hs" | tail -30

# 4. Verificar configuración de EasyPanel para el Dashboard
echo ""
echo "4. Verificando si hay configuración en archivos de EasyPanel:"
find /etc/easypanel -name "*dashboard*" -o -name "*traefik*" 2>/dev/null | head -10

# 5. Verificar si Traefik está usando el nombre del servicio directamente
echo ""
echo "5. Verificando nombres de servicios:"
docker service ls --format "{{.Name}}"

# 6. Probar si Traefik responde al Dashboard usando el nombre del servicio
echo ""
echo "6. Probando acceso al Dashboard usando diferentes métodos:"
curl -I -H "Host: dashboard.checkin24hs.com" http://localhost 2>&1 | head -5
curl -I -H "Host: checkin24hs_dashboard" http://localhost 2>&1 | head -5

# 7. Verificar configuración de red
echo ""
echo "7. Verificando redes de los servicios:"
echo "Dashboard:"
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
echo "CRM:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

echo ""
echo "=== Verificación completada ==="






