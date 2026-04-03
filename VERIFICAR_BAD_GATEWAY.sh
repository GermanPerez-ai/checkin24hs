#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 DIAGNÓSTICO DE BAD GATEWAY"
echo "=========================================="
echo ""

# 1. Verificar contenedor del dashboard
echo "=== 1. Estado del contenedor del dashboard ==="
DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard corriendo"
    echo "Contenedores disponibles:"
    docker ps -a --filter "name=checkin24hs_dashboard" --format "  {{.Names}} - {{.Status}}"
    exit 1
fi

echo "✅ Contenedor encontrado: $DASHBOARD_CONTAINER"
STATUS=$(docker inspect --format='{{.State.Status}}' "$DASHBOARD_CONTAINER" 2>/dev/null)
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$DASHBOARD_CONTAINER" 2>/dev/null || echo "no health check")
echo "  Estado: $STATUS"
echo "  Salud: $HEALTH"
echo ""

# 2. Verificar si el contenedor responde localmente
echo "=== 2. Probando respuesta local del contenedor ==="
echo "Probando http://localhost:3000/ ..."
RESPONSE=$(timeout 5 docker exec "$DASHBOARD_CONTAINER" wget -q -O- http://localhost:3000/ 2>/dev/null | head -5)
if [ ! -z "$RESPONSE" ]; then
    echo "✅ El contenedor responde localmente"
    echo "Primeras líneas de respuesta:"
    echo "$RESPONSE"
else
    echo "❌ El contenedor NO responde localmente"
fi
echo ""

# 3. Ver logs recientes
echo "=== 3. Logs recientes (últimas 30 líneas) ==="
docker logs "$DASHBOARD_CONTAINER" --tail 30 2>&1 | tail -30
echo ""

# 4. Verificar si hay errores en los logs
echo "=== 4. Buscando errores en los logs ==="
ERRORS=$(docker logs "$DASHBOARD_CONTAINER" --tail 100 2>&1 | grep -i "error\|failed\|exception" | tail -10)
if [ ! -z "$ERRORS" ]; then
    echo "⚠️ Se encontraron errores:"
    echo "$ERRORS"
else
    echo "✅ No se encontraron errores recientes"
fi
echo ""

# 5. Verificar configuración de Traefik
echo "=== 5. Verificando configuración de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Traefik encontrado: $TRAEFIK_CONTAINER"
    echo "Últimas 10 líneas de logs de Traefik:"
    docker logs "$TRAEFIK_CONTAINER" --tail 10 2>&1 | tail -10
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

# 6. Verificar etiquetas de Traefik en el servicio
echo "=== 6. Verificando etiquetas de Traefik ==="
docker inspect "$DASHBOARD_CONTAINER" --format='{{range $k, $v := .Config.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -10
echo ""

# 7. Reiniciar el contenedor si es necesario
echo "=== 7. ¿Reiniciar contenedor? ==="
read -p "¿Quieres reiniciar el contenedor del dashboard? (s/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Reiniciando contenedor..."
    docker restart "$DASHBOARD_CONTAINER"
    echo "⏳ Esperando 20 segundos..."
    sleep 20
    echo "✅ Contenedor reiniciado"
    echo ""
    echo "Verificando estado después del reinicio:"
    docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}} - {{.Status}}"
fi
echo ""

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Si el contenedor responde localmente pero Traefik da 'bad gateway',"
echo "puede ser un problema de configuración de Traefik o de red."
echo ""


