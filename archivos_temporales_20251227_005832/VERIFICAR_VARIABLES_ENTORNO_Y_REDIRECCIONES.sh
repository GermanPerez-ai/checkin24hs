#!/bin/bash

echo "=== Verificar variables de entorno y redirecciones ==="

# 1. Ver variables de entorno del servicio CRM
echo ""
echo "1. Variables de entorno del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{.}}{{println}}{{end}}'

# 2. Ver variables de entorno del servicio Dashboard (para comparar)
echo ""
echo "2. Variables de entorno del servicio Dashboard (para comparar):"
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{.}}{{println}}{{end}}'

# 3. Ver variables de entorno del contenedor CRM actual
echo ""
echo "3. Variables de entorno del contenedor CRM actual:"
CRM_CONTAINER=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CRM_CONTAINER" ]; then
    docker inspect $CRM_CONTAINER --format '{{range .Config.Env}}{{.}}{{println}}{{end}}' | grep -iE "traefik|host|domain|url|redirect" || echo "No hay variables relacionadas con Traefik"
fi

# 4. Ver variables de entorno del contenedor Dashboard actual
echo ""
echo "4. Variables de entorno del contenedor Dashboard actual:"
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    docker inspect $DASHBOARD_CONTAINER --format '{{range .Config.Env}}{{.}}{{println}}{{end}}' | grep -iE "traefik|host|domain|url|redirect" || echo "No hay variables relacionadas con Traefik"
fi

# 5. Verificar configuración de Traefik (archivos de configuración)
echo ""
echo "5. Buscando archivos de configuración de Traefik:"
docker service inspect traefik --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'

# 6. Verificar si hay configuración de redirecciones en nginx o apache
echo ""
echo "6. Buscando configuración de nginx/apache:"
find /etc/nginx /etc/apache2 -name "*checkin24hs*" -o -name "*crm*" -o -name "*dashboard*" 2>/dev/null | head -10

# 7. Verificar configuración de EasyPanel
echo ""
echo "7. Buscando configuración de EasyPanel:"
find /etc/easypanel -type f -name "*.json" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | grep -iE "crm|dashboard|traefik" | head -10

# 8. Verificar si hay configuración de dominio en el servicio
echo ""
echo "8. Verificando configuración completa del servicio CRM:"
docker service inspect checkin24hs_crm --format '{{json .Spec}}' | python3 -m json.tool 2>/dev/null | grep -iE "domain|host|url|label|env" | head -30 || docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}'

# 9. Verificar configuración de redirecciones en Traefik (a través de la API si está disponible)
echo ""
echo "9. Intentando ver configuración de Traefik a través de la API:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    timeout 5 docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=3 http://localhost:8080/api/rawdata 2>/dev/null | python3 -m json.tool 2>/dev/null | grep -iE "crm|dashboard|checkin24hs" | head -20 || echo "No se puede acceder a la API de Traefik o no hay configuración"
fi

# 10. Verificar si hay algún proxy o redirección a nivel de sistema
echo ""
echo "10. Verificando configuración de redirecciones a nivel de sistema:"
grep -r "crm.checkin24hs.com" /etc/nginx /etc/apache2 /etc/traefik 2>/dev/null | head -10 || echo "No se encontraron redirecciones a nivel de sistema"

echo ""
echo "=== Verificación completada ==="






