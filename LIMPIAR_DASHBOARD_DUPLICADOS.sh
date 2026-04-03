#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🧹 LIMPIANDO CONTENEDORES DUPLICADOS DEL DASHBOARD"
echo "=========================================="
echo ""

# 1. Escalar el servicio a 1 réplica
echo "=== 1. Escalando servicio a 1 réplica ==="
docker service scale checkin24hs_dashboard=1
echo "⏳ Esperando 15 segundos..."
sleep 15
echo "✅ Servicio escalado"
echo ""

# 2. Obtener todos los contenedores del dashboard
echo "=== 2. Contenedores actuales del dashboard ==="
DASHBOARD_CONTAINERS=($(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | sort -r))
echo "Se encontraron ${#DASHBOARD_CONTAINERS[@]} contenedores:"
for container in "${DASHBOARD_CONTAINERS[@]}"; do
    echo "  - $container"
done
echo ""

# 3. Mantener solo el primero y detener/eliminar los demás
if [ ${#DASHBOARD_CONTAINERS[@]} -gt 1 ]; then
    echo "=== 3. Eliminando contenedores duplicados ==="
    for i in $(seq 1 $((${#DASHBOARD_CONTAINERS[@]} - 1))); do
        echo "Deteniendo y eliminando: ${DASHBOARD_CONTAINERS[$i]}"
        docker stop "${DASHBOARD_CONTAINERS[$i]}" 2>/dev/null || true
        docker rm -f "${DASHBOARD_CONTAINERS[$i]}" 2>/dev/null || true
    done
    echo "✅ Contenedores duplicados eliminados"
else
    echo "✅ Solo hay 1 contenedor, no se necesitan más acciones"
fi
echo ""

# 4. Verificar estado final
echo "=== 4. Estado final ==="
FINAL_CONTAINERS=($(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}"))
echo "Contenedores activos: ${#FINAL_CONTAINERS[@]}"
for container in "${FINAL_CONTAINERS[@]}"; do
    echo "  ✅ $container - $(docker ps --filter "name=$container" --format '{{.Status}}')"
done
echo ""

# 5. Verificar réplicas del servicio
echo "=== 5. Réplicas del servicio ==="
docker service ps checkin24hs_dashboard --no-trunc | head -10
echo ""

echo "=========================================="
echo "✅ LIMPIEZA COMPLETADA"
echo "=========================================="
echo ""
echo "Ahora debería haber solo 1 contenedor del dashboard activo."
echo ""


