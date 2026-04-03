#!/bin/bash
# Verificar configuración de Traefik para WhatsApp (versión simple)

echo "=== VERIFICANDO CONFIGURACIÓN TRAEFIK PARA WHATSAPP ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"

# 1. Ver todas las labels del servicio
echo "1️⃣ Labels del servicio (buscando traefik)..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -i traefik || echo "   ❌ No se encontraron labels de Traefik"

echo ""
echo "2️⃣ Redes del servicio..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'

echo ""
echo "3️⃣ Verificando si está en red easypanel..."
echo "=========================================="
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
if echo "$NETWORKS" | grep -qi "easypanel"; then
    echo "✅ Servicio está en red easypanel"
else
    echo "⚠️  No se encontró red 'easypanel' en las redes del servicio"
    echo "   Redes encontradas:"
    echo "$NETWORKS"
    echo ""
    echo "   Verificando si alguna de estas es la red easypanel..."
    for net in $NETWORKS; do
        net_name=$(docker network inspect $net --format '{{.Name}}' 2>/dev/null)
        if [ -n "$net_name" ]; then
            echo "   - $net -> $net_name"
            if echo "$net_name" | grep -qi "easypanel"; then
                echo "     ✅ Esta es la red easypanel"
            fi
        fi
    done
fi

echo ""
echo "4️⃣ Puerto del servicio..."
echo "=========================================="
PORT=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null | head -n 1)
if [ -n "$PORT" ] && [ "$PORT" != "0" ]; then
    echo "✅ Puerto: $PORT"
else
    echo "⚠️  Puerto no detectado"
    PORT="3001"
    echo "   Usando puerto por defecto: $PORT"
fi

echo ""
echo "5️⃣ Verificando contenedor Traefik..."
echo "=========================================="
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Traefik encontrado: $TRAEFIK_CONTAINER"
    echo ""
    echo "Buscando rutas para $DOMAIN..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | python3 -m json.tool 2>/dev/null | grep -A 5 -i "whatsapp\|${DOMAIN}" || \
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i "whatsapp\|${DOMAIN}" || \
    echo "   ❌ No se encontraron rutas"
else
    echo "❌ Contenedor Traefik no encontrado"
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Si NO hay labels de Traefik, ejecuta:"
echo ""
echo "docker service update \\"
echo "  --label-add 'traefik.enable=true' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.rule=Host(\`${DOMAIN}\`)' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.entrypoints=websecure' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.tls=true' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.tls.certresolver=letsencrypt' \\"
echo "  --label-add 'traefik.http.services.whatsapp.loadbalancer.server.port=${PORT}' \\"
echo "  $SERVICE_NAME"
echo ""
