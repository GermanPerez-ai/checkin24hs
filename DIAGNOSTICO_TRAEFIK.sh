#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNÓSTICO DE TRAEFIK"
echo "=========================================="
echo ""

# 1. Verificar contenedor de Traefik
echo "=== 1. CONTENEDOR TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep traefik | head -1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ No se encontró contenedor Traefik"
    exit 1
fi
echo "✅ Contenedor encontrado: $TRAEFIK_CONTAINER"
echo ""

# 2. Verificar configuración de Traefik (labels del contenedor dashboard)
echo "=== 2. CONFIGURACIÓN DEL DASHBOARD EN TRAEFIK ==="
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
if [ -n "$DASHBOARD_CONTAINER" ]; then
    echo "Contenedor dashboard: $DASHBOARD_CONTAINER"
    echo ""
    echo "Labels relacionados con Traefik:"
    docker inspect "$DASHBOARD_CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{printf "%s = %s\n" $key $value}}{{end}}' | grep -i traefik
else
    echo "❌ No se encontró contenedor del dashboard"
fi
echo ""

# 3. Verificar servicios de Traefik (docker service ls)
echo "=== 3. SERVICIOS DOCKER SWARM ==="
if docker service ls 2>/dev/null | grep -q dashboard; then
    echo "✅ Servicio dashboard encontrado en Docker Swarm:"
    docker service ls | grep dashboard
    echo ""
    echo "Labels del servicio:"
    docker service inspect $(docker service ls --format "{{.Name}}" | grep dashboard | head -1) --format '{{range $key, $value := .Spec.Labels}}{{printf "%s = %s\n" $key $value}}{{end}}' 2>/dev/null | grep -i traefik
else
    echo "⚠️  No se encontró servicio en Docker Swarm (es un contenedor normal)"
fi
echo ""

# 4. Verificar logs de Traefik recientes
echo "=== 4. LOGS RECIENTES DE TRAEFIK (últimas 20 líneas) ==="
docker logs "$TRAEFIK_CONTAINER" --tail 20 2>&1 | tail -20
echo ""

# 5. Verificar configuración estática de Traefik (si existe)
echo "=== 5. CONFIGURACIÓN ESTÁTICA DE TRAEFIK ==="
if docker exec "$TRAEFIK_CONTAINER" test -d /etc/traefik 2>/dev/null; then
    echo "✅ Directorio /etc/traefik existe"
    docker exec "$TRAEFIK_CONTAINER" find /etc/traefik -type f -name "*.toml" -o -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -10
else
    echo "⚠️  No se encontró directorio de configuración estática"
fi
echo ""

# 6. Verificar reglas de caché en Traefik
echo "=== 6. VERIFICAR REGLAS DE CACHÉ ==="
echo "Buscando headers de caché en las labels..."
docker inspect "$DASHBOARD_CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{printf "%s\n" $value}}{{end}}' 2>/dev/null | grep -i cache
echo ""

echo "=========================================="
echo "✅ Diagnóstico de Traefik completado"
echo "=========================================="
echo ""
echo "💡 POSIBLES SOLUCIONES:"
echo "1. Agregar labels para deshabilitar caché en Traefik"
echo "2. Verificar si Traefik tiene middlewares de caché activos"
echo "3. Verificar la configuración de headers en EasyPanel"
