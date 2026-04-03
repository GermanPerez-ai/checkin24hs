#!/bin/bash
# Diagnosticar por qué Traefik no detecta el servicio

echo "=== DIAGNÓSTICO TRAEFIK Y DOCKER SWARM ==="
echo ""

TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ Traefik no encontrado"
    exit 1
fi

echo "✅ Traefik encontrado: $TRAEFIK_CONTAINER"
echo ""

# 1. Ver todos los routers en Traefik
echo "1️⃣ Todos los routers en Traefik..."
echo "=========================================="
docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | python3 -m json.tool 2>/dev/null | head -50 || \
docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | head -50

# 2. Ver configuración de Traefik
echo ""
echo "2️⃣ Verificando configuración de Traefik..."
echo "=========================================="
docker exec $TRAEFIK_CONTAINER cat /etc/traefik/traefik.yml 2>/dev/null | grep -A 10 -i "docker\|swarm" || echo "   (no se encontró configuración docker/swarm)"

# 3. Ver logs de Traefik
echo ""
echo "3️⃣ Logs recientes de Traefik..."
echo "=========================================="
docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | tail -20

# 4. Verificar si Traefik está en modo Docker Swarm
echo ""
echo "4️⃣ Verificando modo de Traefik..."
echo "=========================================="
docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/overview 2>/dev/null | python3 -m json.tool 2>/dev/null | grep -i "docker\|swarm" || \
docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/overview 2>/dev/null | grep -i "docker\|swarm"

# 5. Verificar redes de Traefik
echo ""
echo "5️⃣ Redes de Traefik..."
echo "=========================================="
docker inspect $TRAEFIK_CONTAINER --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{println}}{{end}}' | head -5

echo ""
echo "=========================================="
echo "📋 ANÁLISIS"
echo "=========================================="
echo ""
echo "Si Traefik no muestra routers de otros servicios:"
echo "   → Traefik puede no estar configurado para Docker Swarm"
echo ""
echo "Si Traefik muestra otros routers pero no el de WhatsApp:"
echo "   → El problema es específico de este servicio"
echo ""
