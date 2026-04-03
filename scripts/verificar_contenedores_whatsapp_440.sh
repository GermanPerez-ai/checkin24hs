#!/bin/bash
# Ver contenedores/servicios activos y parados, dejar 1 réplica de WhatsApp (evita 440)
# Ejecutar en el SERVIDOR por SSH: bash scripts/verificar_contenedores_whatsapp_440.sh

set -e

echo "=== 1. Servicios Docker Swarm (buscar whatsapp) ==="
docker service ls 2>/dev/null | grep -i whatsapp || echo "(ningún servicio whatsapp o no estás en Swarm)"

echo ""
echo "=== 2. CONTENEDORES CON 'whatsapp' — ACTIVOS Y PARADOS ==="
docker ps -a --filter "name=whatsapp" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null || true
COUNT_ALL=$(docker ps -a --filter "name=whatsapp" -q 2>/dev/null | wc -l)
COUNT_RUN=$(docker ps --filter "name=whatsapp" -q 2>/dev/null | wc -l)
echo "Total con 'whatsapp': $COUNT_ALL (en ejecución: $COUNT_RUN). Debe haber solo 1 en ejecución."

echo ""
echo "=== 3. Tareas del servicio checkin24hs_whatsapp (solo 1 debe estar Running) ==="
docker service ps checkin24hs_whatsapp --no-trunc 2>/dev/null | head -15 || echo "(servicio no existe)"

echo ""
echo "=== 4. Fijar 1 réplica (evita 440: dos contenedores, misma sesión) ==="
docker service scale checkin24hs_whatsapp=1 2>/dev/null || echo "No se pudo escalar (¿nombre del servicio distinto?)"

echo ""
echo "=== 5. Contenedores en ejecución con 'whatsapp' (debe ser 1) ==="
docker ps --filter "name=whatsapp" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

echo ""
echo "=== 6. Eliminar contenedores parados (opcional) ==="
docker container prune -f

echo ""
echo "=== 7. Verificación final ==="
sleep 2
RUNNING=$(docker service ps checkin24hs_whatsapp --filter "desired-state=running" --format "{{.Name}}" 2>/dev/null | wc -l)
echo "Tareas Running del servicio: $RUNNING"
docker service ps checkin24hs_whatsapp --no-trunc 2>/dev/null | head -6 || true

echo ""
echo "--- Resumen 440 ---"
echo "Si hay más de 1 contenedor con 'whatsapp' en ejecución, uno está usando la sesión y el otro recibe 440."
echo "Solución: scale=1 y esperar 90 segundos; o detener manualmente los que sobran:"
echo "  docker stop <nombre_contenedor>"
echo "Logs: docker service logs -f checkin24hs_whatsapp"
echo "QR (si tuviste que borrar auth): https://whatsapp.checkin24hs.com/qr"
