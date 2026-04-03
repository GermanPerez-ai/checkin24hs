#!/bin/bash
# Verificar y corregir configuración de Traefik para WhatsApp

echo "=== VERIFICANDO Y CORRIGIENDO TRAEFIK PARA WHATSAPP ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"

# 1. Verificar labels actuales
echo "1️⃣ Labels actuales de Traefik..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik || echo "   ❌ No hay labels de Traefik"

echo ""
echo "2️⃣ Verificando red easypanel..."
echo "=========================================="
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
if echo "$NETWORKS" | grep -qi "easypanel"; then
    echo "✅ Servicio está en red easypanel"
else
    echo "⚠️  Agregando a red easypanel..."
    docker service update --network-add easypanel $SERVICE_NAME
    sleep 3
fi

echo ""
echo "3️⃣ Aplicando labels de Traefik..."
echo "=========================================="

# Remover labels antiguas si existen (opcional, para limpiar)
echo "   Limpiando labels antiguas..."
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}{{"\n"}}{{end}}' | grep "^traefik" | while read label; do
    if [ -n "$label" ]; then
        docker service update --label-rm "$label" $SERVICE_NAME 2>/dev/null || true
    fi
done

sleep 2

# Aplicar labels correctas
echo "   Aplicando labels nuevas..."
docker service update \
  --label-add 'traefik.enable=true' \
  --label-add 'traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)' \
  --label-add 'traefik.http.routers.whatsapp.entrypoints=websecure' \
  --label-add 'traefik.http.routers.whatsapp.tls=true' \
  --label-add 'traefik.http.routers.whatsapp.tls.certresolver=letsencrypt' \
  --label-add 'traefik.http.services.whatsapp.loadbalancer.server.port=3001' \
  $SERVICE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Labels aplicadas correctamente"
else
    echo "❌ Error al aplicar labels"
    exit 1
fi

echo ""
echo "4️⃣ Verificando labels aplicadas..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

echo ""
echo "5️⃣ Verificando si Traefik detecta el servicio..."
echo "=========================================="
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Traefik encontrado: $TRAEFIK_CONTAINER"
    echo ""
    echo "Esperando 10 segundos para que Traefik detecte los cambios..."
    sleep 10
    echo ""
    echo "Buscando rutas para $DOMAIN..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i "whatsapp\|${DOMAIN}" || echo "   ⚠️  Aún no aparece en Traefik (puede tardar más)"
else
    echo "❌ Contenedor Traefik no encontrado"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "⏳ Espera 30-60 segundos y luego prueba:"
echo "   https://whatsapp.checkin24hs.com/api/status"
echo "   https://whatsapp.checkin24hs.com/qr"
echo ""
echo "Si sigue dando 404, verifica en EasyPanel:"
echo "   1. Ve al servicio 'whatsapp'"
echo "   2. Ve a la pestaña 'Dominios'"
echo "   3. Verifica que 'whatsapp.checkin24hs.com' esté configurado"
echo ""
