#!/bin/bash
echo "=== VERIFICANDO LOGS DESDE EL INICIO (SIN FILTROS) ==="
echo ""

echo "Logs completos de whatsapp1 (últimas 200 líneas, sin QR):"
docker service logs checkin24hs_whatsapp1 --tail 200 2>&1 | grep -v "█" | tail -100

echo ""
echo "=== BUSCANDO MENSAJES ESPECÍFICOS ==="
echo "Mensaje 'Iniciando servidor':"
docker service logs checkin24hs_whatsapp1 2>&1 | grep "Iniciando servidor" | tail -3

echo ""
echo "Mensaje 'Dependencias cargadas':"
docker service logs checkin24hs_whatsapp1 2>&1 | grep "Dependencias cargadas" | tail -3

echo ""
echo "Mensaje 'Cliente de Supabase':"
docker service logs checkin24hs_whatsapp1 2>&1 | grep "Supabase" | tail -5

echo ""
echo "Mensaje 'Base de conocimiento':"
docker service logs checkin24hs_whatsapp1 2>&1 | grep -iE "conocimiento|hoteles cargados" | tail -5

echo ""
echo "Mensaje 'Servidor corriendo':"
docker service logs checkin24hs_whatsapp1 2>&1 | grep "Servidor corriendo" | tail -3

echo ""
echo "Mensaje 'Inicializando WhatsApp':"
docker service logs checkin24hs_whatsapp1 2>&1 | grep "Inicializando WhatsApp" | tail -3

echo ""
echo "=== VERIFICANDO CONTENEDOR ACTUAL ==="
CONTAINER=$(docker ps --filter "name=checkin24hs_whatsapp1" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    echo ""
    echo "Logs del contenedor actual (últimas 50 líneas, sin QR):"
    docker logs $CONTAINER --tail 50 2>&1 | grep -v "█" | tail -30
fi
