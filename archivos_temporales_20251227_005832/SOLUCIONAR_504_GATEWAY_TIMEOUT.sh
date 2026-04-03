#!/bin/bash

echo "=========================================="
echo "Solucionar Error 504 Gateway Timeout"
echo "=========================================="
echo ""

# 1. Verificar estado del servicio
echo "=== PASO 1: Verificar estado del servicio ==="
docker service ps checkin24hs_dashboard --no-trunc
echo ""

# 2. Verificar logs del servicio (últimas 30 líneas)
echo "=== PASO 2: Ver logs del servicio ==="
docker service logs checkin24hs_dashboard --tail 30 2>&1 | tail -30
echo ""

# 3. Verificar contenedores corriendo
echo "=== PASO 3: Verificar contenedores ==="
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedores corriendo"
    echo "Intentando reiniciar el servicio..."
    docker service update --force checkin24hs_dashboard
    sleep 10
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ ! -z "$CONTAINER_ID" ]; then
    echo "✅ Contenedor encontrado: $CONTAINER_ID"
    echo ""
    
    # Verificar estado del contenedor
    echo "Estado del contenedor:"
    docker ps | grep $CONTAINER_ID
    echo ""
    
    # Verificar procesos dentro del contenedor
    echo "Procesos dentro del contenedor:"
    docker exec $CONTAINER_ID ps aux 2>&1 | head -10
    echo ""
    
    # Verificar si el puerto 3000 está escuchando
    echo "Verificando puerto 3000:"
    docker exec $CONTAINER_ID netstat -tlnp 2>&1 | grep 3000 || docker exec $CONTAINER_ID ss -tlnp 2>&1 | grep 3000
    echo ""
    
    # Probar acceso interno
    echo "Probando http://localhost:3000 desde el contenedor:"
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -5
    echo ""
    
    # Verificar archivo dashboard.html existe
    echo "Verificando dashboard.html:"
    docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>&1
    echo ""
    
    # Verificar logs del contenedor
    echo "Logs del contenedor (últimas 20 líneas):"
    docker logs $CONTAINER_ID --tail 20 2>&1
else
    echo "❌ No se pudo encontrar contenedor después de reiniciar"
fi
echo ""

# 4. Verificar configuración de Traefik
echo "=== PASO 4: Verificar configuración Traefik ==="
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
echo ""

# 5. Verificar redes
echo "=== PASO 5: Verificar redes ==="
echo "Redes del servicio dashboard:"
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | xargs -I {} docker network inspect {} --format '{{.Name}}' 2>/dev/null
echo ""

# 6. Verificar que Traefik puede alcanzar el servicio
echo "=== PASO 6: Verificar conectividad desde Traefik ==="
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}' | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ] && [ ! -z "$CONTAINER_ID" ]; then
    CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
    echo "IP del contenedor dashboard: $CONTAINER_IP"
    echo "Probando desde Traefik:"
    docker exec $TRAEFIK_CONTAINER wget -qO- --timeout=5 http://$CONTAINER_IP:3000 2>&1 | head -5
fi
echo ""

# 7. Verificar logs de Traefik
echo "=== PASO 7: Ver logs de Traefik ==="
docker service logs traefik --tail 20 2>&1 | grep -i "dashboard\|504\|timeout" | tail -10
echo ""

# 8. Soluciones posibles
echo "=== PASO 8: Aplicar soluciones ==="
echo "1. Reiniciando servicio..."
docker service update --force checkin24hs_dashboard
echo "✅ Servicio reiniciado"
echo ""

echo "Esperando 20 segundos..."
sleep 20

echo ""
echo "2. Verificando nuevo estado..."
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    echo "Probando acceso:"
    docker exec $NEW_CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -3
fi
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
echo ""
echo "Si el problema persiste, verifica:"
echo "1. Que el servicio está corriendo: docker service ps checkin24hs_dashboard"
echo "2. Que el puerto 3000 está abierto: docker exec <container> netstat -tlnp | grep 3000"
echo "3. Que serve-dashboard.js está corriendo: docker exec <container> ps aux | grep node"
echo ""




