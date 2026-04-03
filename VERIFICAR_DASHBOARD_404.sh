#!/bin/bash

echo "🔍 Verificando estado del dashboard..."
echo ""

# Verificar servicios Docker Swarm
echo "=== Servicios Docker Swarm ==="
docker service ls | grep -i dashboard || echo "No se encontraron servicios de dashboard"
echo ""

# Verificar contenedores corriendo
echo "=== Contenedores corriendo ==="
docker ps | grep -i dashboard || echo "No se encontraron contenedores de dashboard corriendo"
echo ""

# Verificar contenedores (incluyendo detenidos)
echo "=== Todos los contenedores de dashboard ==="
docker ps -a | grep -i dashboard || echo "No se encontraron contenedores de dashboard"
echo ""

# Verificar si el puerto 3000 está escuchando
echo "=== Verificando puerto 3000 ==="
netstat -tulpn | grep ":3000" || ss -tulpn | grep ":3000" || echo "Puerto 3000 no está escuchando"
echo ""

# Verificar logs del servicio (si existe)
echo "=== Logs del servicio (últimas 20 líneas) ==="
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -i dashboard | head -1)
if [ -n "$SERVICE_NAME" ]; then
    echo "Servicio encontrado: $SERVICE_NAME"
    docker service logs --tail 20 $SERVICE_NAME 2>&1 | tail -20
else
    echo "No se encontró servicio de dashboard"
fi
echo ""

# Verificar logs de Traefik
echo "=== Logs de Traefik (últimas 20 líneas) ==="
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    docker logs --tail 20 $TRAEFIK_CONTAINER 2>&1 | grep -i dashboard | tail -20 || echo "No hay logs relacionados con dashboard"
else
    echo "No se encontró contenedor Traefik"
fi
echo ""

# Verificar configuración de Traefik para dashboard
echo "=== Verificando labels de Traefik ==="
docker service inspect $(docker service ls --format "{{.Name}}" | grep -i dashboard | head -1) --format '{{range .Spec.TaskTemplate.ContainerSpec.Labels}}{{.}}{{println}}{{end}}' 2>/dev/null | grep -i traefik || echo "No se encontraron labels de Traefik"
echo ""

# Probar acceso local al puerto 3000
echo "=== Probando acceso local al puerto 3000 ==="
curl -I http://localhost:3000 2>&1 | head -5 || echo "No se pudo conectar al puerto 3000"
echo ""

echo "✅ Verificación completada"








