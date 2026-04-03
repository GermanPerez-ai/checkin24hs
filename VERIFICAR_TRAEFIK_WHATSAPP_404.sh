#!/bin/bash
# Verificar por qué Traefik devuelve 404 para whatsapp.checkin24hs.com

echo "=== VERIFICANDO CONFIGURACIÓN TRAEFIK PARA WHATSAPP ==="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"

# 1. Verificar que el servicio existe y está corriendo
echo "1️⃣ Verificando servicio..."
if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "✅ Servicio encontrado: $SERVICE_NAME"
    
    # Ver estado del servicio
    echo ""
    echo "Estado del servicio:"
    docker service ls | grep "$SERVICE_NAME"
else
    echo "❌ Servicio $SERVICE_NAME no encontrado"
    echo ""
    echo "Servicios disponibles:"
    docker service ls | grep -i whatsapp
    exit 1
fi

echo ""
echo "2️⃣ Verificando labels de Traefik..."
echo "=========================================="
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{if or (contains $k "traefik") (contains $k "easypanel")}}{{$k}}={{$v}}{{"\n"}}{{end}}{{end}}' | grep -E "traefik|easypanel" || echo "   (sin labels traefik encontradas)"

echo ""
echo "3️⃣ Verificando red easypanel..."
echo "=========================================="
NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    echo "✅ Servicio está en red easypanel"
else
    echo "❌ Servicio NO está en red easypanel"
    echo "   Redes actuales:"
    echo "$NETWORKS"
fi

echo ""
echo "4️⃣ Verificando puerto del servicio..."
echo "=========================================="
PORT=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null | head -n 1)
if [ -n "$PORT" ] && [ "$PORT" != "0" ]; then
    echo "✅ Puerto detectado: $PORT"
else
    echo "⚠️  Puerto no detectado o es 0"
    echo "   Verificando configuración del servicio..."
    docker service inspect $SERVICE_NAME --format '{{json .Spec.TaskTemplate.ContainerSpec}}' | grep -i port || echo "   (no se encontró configuración de puerto)"
fi

echo ""
echo "5️⃣ Verificando si Traefik detecta el servicio..."
echo "=========================================="
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Contenedor Traefik encontrado: $TRAEFIK_CONTAINER"
    echo ""
    echo "Buscando rutas de Traefik para $DOMAIN..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i "whatsapp\|${DOMAIN}" || echo "   ❌ No se encontraron rutas para whatsapp o $DOMAIN"
    echo ""
    echo "Buscando servicios de Traefik..."
    docker exec $TRAEFIK_CONTAINER wget -qO- http://localhost:8080/api/http/services 2>/dev/null | grep -i "whatsapp" || echo "   ❌ No se encontraron servicios para whatsapp"
else
    echo "❌ Contenedor Traefik no encontrado"
fi

echo ""
echo "6️⃣ Verificando acceso directo al servicio (sin Traefik)..."
echo "=========================================="
# Obtener IP del contenedor
CONTAINER_IP=$(docker service ps $SERVICE_NAME --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER_IP" ]; then
    echo "Intentando acceder directamente al servicio..."
    # Esto puede no funcionar si el servicio no expone puertos directamente
    echo "   (Nota: Esto requiere acceso directo al contenedor)"
else
    echo "⚠️  No se pudo obtener información del contenedor"
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Si las labels de Traefik no están configuradas, ejecuta:"
echo ""
echo "docker service update \\"
echo "  --label-add 'traefik.enable=true' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.rule=Host(\`${DOMAIN}\`)' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.entrypoints=websecure' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.tls=true' \\"
echo "  --label-add 'traefik.http.routers.whatsapp.tls.certresolver=letsencrypt' \\"
echo "  --label-add 'traefik.http.services.whatsapp.loadbalancer.server.port=${PORT:-3001}' \\"
echo "  $SERVICE_NAME"
echo ""
echo "O verifica en EasyPanel:"
echo "  1. Ve al servicio 'whatsapp'"
echo "  2. Ve a la pestaña 'Dominios'"
echo "  3. Verifica que '$DOMAIN' esté configurado"
echo "  4. Si no está, agrégalo"
echo ""
