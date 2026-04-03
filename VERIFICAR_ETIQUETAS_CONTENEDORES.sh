#!/bin/bash
# Verificar etiquetas Traefik en los contenedores directamente

echo "=========================================="
echo "🔍 Verificando etiquetas en contenedores"
echo "=========================================="
echo ""

# 1. Ver todos los contenedores
echo "1️⃣ Contenedores corriendo:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
echo ""

# 2. Verificar etiquetas Traefik en contenedores del dashboard
echo "2️⃣ Etiquetas Traefik en contenedores del dashboard:"
DASHBOARD_CONTAINERS=$(docker ps --filter "name=dashboard" --format "{{.ID}}")

if [ -z "$DASHBOARD_CONTAINERS" ]; then
    echo "⚠️  No se encontraron contenedores del dashboard"
else
    for CONTAINER in $DASHBOARD_CONTAINERS; do
        echo "--- Contenedor: $CONTAINER ---"
        docker inspect "$CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "No tiene etiquetas Traefik"
        echo ""
    done
fi

# 3. Verificar etiquetas Traefik en contenedores del CRM
echo "3️⃣ Etiquetas Traefik en contenedores del CRM:"
CRM_CONTAINERS=$(docker ps --filter "name=crm" --format "{{.ID}}")

if [ -z "$CRM_CONTAINERS" ]; then
    echo "⚠️  No se encontraron contenedores del CRM"
else
    for CONTAINER in $CRM_CONTAINERS; do
        echo "--- Contenedor: $CONTAINER ---"
        docker inspect "$CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "No tiene etiquetas Traefik"
        echo ""
    done
fi

# 4. Ver qué detecta Traefik
echo "4️⃣ Verificando qué detecta Traefik..."
echo "Buscando servicios con router 'dashboard' o 'crm' en logs de Traefik:"
docker service logs traefik --tail 200 | grep -iE "router.*dashboard|router.*crm|service.*dashboard|service.*crm" | tail -20
echo ""

# 5. Ver configuración dinámica de Traefik
echo "5️⃣ Verificando configuración dinámica de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "Intentando acceder a la API de Traefik para ver routers configurados..."
    docker exec "$TRAEFIK_CONTAINER" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | head -50 || echo "No se pudo acceder a la API de Traefik"
else
    echo "⚠️  No se encontró contenedor de Traefik"
fi

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
