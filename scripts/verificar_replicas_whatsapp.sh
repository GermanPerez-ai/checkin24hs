#!/bin/bash
# Verificar que solo hay UNA réplica del servicio WhatsApp (evita conflict 440)
# Ejecutar en el servidor donde corre Docker Swarm

echo "=== Réplicas del servicio WhatsApp ==="
docker service ls 2>/dev/null | grep -i whatsapp || echo "(Servicio no encontrado o sin Docker Swarm)"

echo ""
echo "=== Detalle de tareas (debe ser 1 Running) ==="
docker service ps checkin24hs_whatsapp 2>/dev/null --no-trunc | head -20 || docker service ps whatsapp 2>/dev/null --no-trunc | head -20 || echo "(Ajustar nombre del servicio)"

echo ""
echo "=== Contenedores con 'whatsapp' (no debe haber duplicados) ==="
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | grep -i whatsapp || echo "(Ninguno)"

echo ""
echo "Si hay más de 1 réplica o contenedor duplicado, ejecutar:"
echo "  docker service scale checkin24hs_whatsapp=1"
echo "  docker stop checkin24hs-whatsapp-1 2>/dev/null; docker rm checkin24hs-whatsapp-1 2>/dev/null"
