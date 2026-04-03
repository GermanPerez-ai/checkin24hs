#!/bin/bash
PROBLEMA_CONTAINER="checkin24hs_dashboard.1.qs27okwhd2mu8ibay1q8qqc3e"

echo "Corrigiendo contenedor: $PROBLEMA_CONTAINER"
docker cp /root/checkin24hs/deploy/dashboard.html $PROBLEMA_CONTAINER:/app/dashboard.html

echo "Verificando..."
LINE_5150=$(docker exec $PROBLEMA_CONTAINER sed -n '5150p' /app/dashboard.html 2>/dev/null)
echo "Línea 5150: $LINE_5150"

SHOW_SECTION_LINE=$(docker exec $PROBLEMA_CONTAINER grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
echo "Funciones globales en línea: $SHOW_SECTION_LINE"

docker restart $PROBLEMA_CONTAINER
echo "Contenedor reiniciado"
