#!/bin/bash
# Verificar estado del servicio después del reinicio

SERVICE_NAME="checkin24hs_dashboard"

echo "=========================================="
echo "🔍 VERIFICAR ESTADO DEL SERVICIO"
echo "=========================================="
echo ""

# Verificar estado del servicio
echo "=== Estado del servicio ==="
docker service ps "$SERVICE_NAME" --format "table {{.Name}}\t{{.CurrentState}}\t{{.Node}}" | head -5
echo ""

# Verificar contenedores
echo "=== Contenedores del servicio ==="
CONTAINER=$(docker service ps "$SERVICE_NAME" --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    echo "Estado: $(docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null || echo 'no disponible')"
    echo ""
    
    # Verificar si el contenedor está corriendo
    if docker ps | grep -q "$CONTAINER"; then
        echo "✅ Contenedor está corriendo"
        
        # Verificar logs recientes
        echo ""
        echo "=== Logs recientes (últimas 20 líneas) ==="
        docker logs "$CONTAINER" --tail 20 2>&1 | tail -20
    else
        echo "❌ Contenedor NO está corriendo"
        echo ""
        echo "=== Verificar por qué no está corriendo ==="
        docker ps -a | grep "$CONTAINER" | head -1
    fi
else
    echo "❌ No se encontró contenedor"
fi
echo ""

# Verificar puerto
echo "=== Verificar puerto 3000 ==="
if [ -n "$CONTAINER" ] && docker ps | grep -q "$CONTAINER"; then
    echo "Probando acceso directo al puerto 3000..."
    CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ]; then
        echo "IP del contenedor: $CONTAINER_IP"
        timeout 5 curl -s -o /dev/null -w "Status: %{http_code}\n" http://$CONTAINER_IP:3000 || echo "No responde"
    else
        echo "⚠️  No se pudo obtener IP del contenedor"
    fi
fi
echo ""

# Verificar Traefik
echo "=== Verificar Traefik ==="
TRAEFIK_SERVICE=$(docker service ls | grep -i "traefik" | awk '{print $1}' | head -1)
if [ -n "$TRAEFIK_SERVICE" ]; then
    echo "Traefik: $TRAEFIK_SERVICE"
    echo "Estado:"
    docker service ps "$TRAEFIK_SERVICE" --format "table {{.Name}}\t{{.CurrentState}}" | head -3
else
    echo "⚠️  Traefik no encontrado"
fi
echo ""

echo "=========================================="
echo "📋 RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Si el servicio está reiniciando:"
echo "  1. Espera 30-60 segundos"
echo "  2. Recarga la página"
echo ""
echo "Si el servicio no está corriendo:"
echo "  1. Verifica los logs: docker service logs $SERVICE_NAME --tail 50"
echo "  2. Verifica recursos del servidor: docker stats --no-stream"
echo ""
