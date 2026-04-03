#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🧹 LIMPIEZA Y ESTABILIZACIÓN DE SERVICIOS"
echo "=========================================="
echo ""

# 1. Limpiar contenedores "Created" (no iniciados)
echo "=== 1. Limpiando contenedores 'Created' ==="
CREATED_CONTAINERS=$(docker ps -a --filter "status=created" --format "{{.Names}}")
if [ ! -z "$CREATED_CONTAINERS" ]; then
    echo "$CREATED_CONTAINERS" | while read container; do
        echo "  Eliminando: $container"
        docker rm -f "$container" 2>/dev/null || true
    done
    echo "✅ Contenedores 'Created' eliminados"
else
    echo "✅ No hay contenedores 'Created'"
fi
echo ""

# 2. Escalar servicios a 1 réplica cada uno
echo "=== 2. Escalando servicios a 1 réplica ==="
docker service scale checkin24hs_dashboard=1 2>/dev/null || echo "⚠️ No es un servicio de Swarm"
docker service scale checkin24hs_whatsapp=1 2>/dev/null || echo "⚠️ No es un servicio de Swarm"
docker service scale checkin24hs_whatsapp2=1 2>/dev/null || echo "⚠️ No es un servicio de Swarm"
docker service scale checkin24hs_whatsapp3=1 2>/dev/null || echo "⚠️ No es un servicio de Swarm"
docker service scale checkin24hs_whatsapp4=1 2>/dev/null || echo "⚠️ No es un servicio de Swarm"
echo "✅ Servicios escalados"
echo ""

# 3. Detener contenedores duplicados del dashboard (dejar solo el más reciente)
echo "=== 3. Limpiando contenedores duplicados del dashboard ==="
DASHBOARD_CONTAINERS=($(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | sort))
if [ ${#DASHBOARD_CONTAINERS[@]} -gt 1 ]; then
    echo "  Se encontraron ${#DASHBOARD_CONTAINERS[@]} contenedores del dashboard"
    # Mantener solo el primero (más reciente) y detener los demás
    for i in $(seq 1 $((${#DASHBOARD_CONTAINERS[@]} - 1))); do
        echo "  Deteniendo: ${DASHBOARD_CONTAINERS[$i]}"
        docker stop "${DASHBOARD_CONTAINERS[$i]}" 2>/dev/null || true
        docker rm -f "${DASHBOARD_CONTAINERS[$i]}" 2>/dev/null || true
    done
    echo "✅ Contenedores duplicados eliminados"
else
    echo "✅ Solo hay 1 contenedor del dashboard"
fi
echo ""

# 4. Verificar estado final
echo "=== 4. Estado final de contenedores ==="
echo ""
echo "Dashboard:"
docker ps --filter "name=checkin24hs_dashboard" --format "  {{.Names}} - {{.Status}}"
echo ""
echo "WhatsApp:"
docker ps --filter "name=whatsapp" --format "  {{.Names}} - {{.Status}}" | head -4
echo ""

# 5. Verificar logs del dashboard activo
echo "=== 5. Verificando logs del dashboard ==="
ACTIVE_DASHBOARD=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ ! -z "$ACTIVE_DASHBOARD" ]; then
    echo "  Contenedor activo: $ACTIVE_DASHBOARD"
    echo "  Últimas 5 líneas de logs:"
    docker logs "$ACTIVE_DASHBOARD" --tail 5 2>&1 | tail -5
else
    echo "  ⚠️ No se encontró contenedor activo del dashboard"
fi
echo ""

# 6. Esperar un momento para que los servicios se estabilicen
echo "=== 6. Esperando estabilización (10 segundos) ==="
sleep 10
echo "✅ Completado"
echo ""

echo "=========================================="
echo "✅ LIMPIEZA COMPLETA"
echo "=========================================="
echo ""
echo "📋 Estado final:"
echo "  - Contenedores 'Created' eliminados"
echo "  - Servicios escalados a 1 réplica"
echo "  - Contenedores duplicados eliminados"
echo ""
echo "🔍 Prueba acceder al dashboard ahora."
echo ""


