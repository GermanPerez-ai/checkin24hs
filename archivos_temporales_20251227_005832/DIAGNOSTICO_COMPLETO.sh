#!/bin/bash

echo "=========================================="
echo "Diagnóstico Completo del Servicio"
echo "=========================================="
echo ""

# 1. Verificar estado del servicio
echo "=== 1. Estado del servicio ==="
docker service ps checkin24hs_dashboard --no-trunc
echo ""

# 2. Verificar contenedores (todos)
echo "=== 2. Todos los contenedores ==="
docker ps -a | grep checkin24hs_dashboard
echo ""

# 3. Verificar contenedor corriendo
echo "=== 3. Contenedor corriendo ==="
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No hay contenedor corriendo"
    echo ""
    echo "Intentando reiniciar servicio..."
    docker service update --force checkin24hs_dashboard
    sleep 20
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ ! -z "$CONTAINER_ID" ]; then
    echo "✅ Contenedor: $CONTAINER_ID"
    echo ""
    
    # Verificar proceso
    echo "=== 4. Proceso corriendo ==="
    docker exec $CONTAINER_ID ps aux 2>&1
    echo ""
    
    # Verificar archivos en /app
    echo "=== 5. Archivos en /app ==="
    docker exec $CONTAINER_ID ls -lah /app/ 2>&1
    echo ""
    
    # Verificar qué archivo JS existe
    echo "=== 6. Archivos JavaScript ==="
    docker exec $CONTAINER_ID ls -lh /app/*.js 2>&1
    echo ""
    
    # Verificar logs
    echo "=== 7. Logs del contenedor (últimas 20 líneas) ==="
    docker logs $CONTAINER_ID --tail 20 2>&1
    echo ""
    
    # Probar acceso
    echo "=== 8. Probar acceso interno ==="
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:3000 2>&1 | head -10
    echo ""
    
    # Verificar puerto
    echo "=== 9. Verificar puerto 3000 ==="
    docker exec $CONTAINER_ID netstat -tlnp 2>&1 | grep 3000 || docker exec $CONTAINER_ID ss -tlnp 2>&1 | grep 3000
    echo ""
else
    echo "❌ No se pudo encontrar contenedor después de reiniciar"
    echo ""
    echo "=== Ver logs del servicio ==="
    docker service logs checkin24hs_dashboard --tail 30 2>&1 | tail -30
fi

# 10. Verificar configuración del servicio
echo "=== 10. Configuración del servicio ==="
docker service inspect checkin24hs_dashboard --format 'Comando: {{.Spec.TaskTemplate.ContainerSpec.Command}}' 2>&1
docker service inspect checkin24hs_dashboard --format 'Args: {{.Spec.TaskTemplate.ContainerSpec.Args}}' 2>&1
echo ""

# 11. Verificar acceso desde el host
echo "=== 11. Probar acceso desde el host ==="
curl -I --connect-timeout 5 http://localhost:3000 2>&1 | head -5
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
echo ""




