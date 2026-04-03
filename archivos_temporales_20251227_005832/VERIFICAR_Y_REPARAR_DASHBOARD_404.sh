#!/bin/bash

echo "=========================================="
echo "Verificar y Reparar Dashboard 404"
echo "=========================================="
echo ""

# 1. Verificar servicios Docker
echo "=== PASO 1: Verificar servicios Docker ==="
docker service ls | grep dashboard
echo ""

# 2. Verificar contenedores corriendo
echo "=== PASO 2: Verificar contenedores ==="
docker ps | grep dashboard
echo ""

# 3. Verificar logs del servicio
echo "=== PASO 3: Ver logs del servicio (últimas 20 líneas) ==="
docker service logs checkin24hs_dashboard --tail 20 2>&1 | tail -20
echo ""

# 4. Verificar configuración de Traefik
echo "=== PASO 4: Verificar etiquetas Traefik del servicio ==="
docker service inspect checkin24hs_dashboard --format '{{json .Spec.Labels}}' | python3 -m json.tool 2>/dev/null || docker service inspect checkin24hs_dashboard | grep -A 10 Labels
echo ""

# 5. Verificar que Traefik detecta el servicio
echo "=== PASO 5: Verificar logs de Traefik (últimas 30 líneas) ==="
docker service logs traefik --tail 30 2>&1 | grep -i dashboard | tail -10
echo ""

# 6. Probar acceso interno al servicio
echo "=== PASO 6: Probar acceso interno al servicio ==="
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo "Probando http://localhost:3000 desde el contenedor:"
    docker exec $CONTAINER_ID wget -qO- http://localhost:3000 2>&1 | head -5
    echo ""
    echo "Probando desde el host:"
    curl -I http://localhost:3000 2>&1 | head -5
else
    echo "❌ No se encontró contenedor corriendo"
fi
echo ""

# 7. Verificar redes Docker
echo "=== PASO 7: Verificar redes Docker ==="
docker network ls | grep -E "easypanel|traefik|ingress"
echo ""

# 8. Verificar que Traefik y el servicio están en la misma red
echo "=== PASO 8: Verificar redes del servicio ==="
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | xargs -I {} docker network inspect {} --format '{{.Name}}' 2>/dev/null
echo ""

# 9. Verificar entrada de Traefik
echo "=== PASO 9: Verificar entrada de Traefik ==="
docker service inspect traefik --format '{{range .Endpoint.Ports}}{{.PublishedPort}} -> {{.TargetPort}} ({{.Protocol}}){{end}}'
echo ""

# 10. Probar acceso directo al dominio
echo "=== PASO 10: Probar acceso directo ==="
curl -I http://dashboard.checkin24hs.com 2>&1 | head -10
echo ""

echo "=========================================="
echo "Diagnóstico completado"
echo "=========================================="




