#!/bin/bash
# Solución final para el problema de Traefik

echo "=========================================="
echo "🔧 Solución Final para Traefik"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando etiquetas actuales del servicio..."
ALL_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}')

if [ -z "$ALL_LABELS" ]; then
    echo "❌ El servicio NO tiene etiquetas"
else
    echo "Etiquetas del servicio:"
    echo "$ALL_LABELS"
fi

echo ""
echo "2️⃣ Verificando específicamente etiquetas Traefik..."
TRAEFIK_LABELS=$(echo "$ALL_LABELS" | grep -i traefik)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ NO hay etiquetas Traefik configuradas"
    echo ""
    echo "3️⃣ Agregando etiquetas Traefik explícitas..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=web" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.tls=true" \
      --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" \
      "$DASHBOARD_SERVICE"
    
    if [ $? -eq 0 ]; then
        echo "✅ Etiquetas Traefik agregadas"
    else
        echo "❌ Error al agregar etiquetas"
        exit 1
    fi
else
    echo "✅ Etiquetas Traefik encontradas:"
    echo "$TRAEFIK_LABELS"
fi

echo ""
echo "4️⃣ Probando acceso al endpoint a través de Traefik..."
echo "   Esperando 10 segundos para que Traefik actualice..."
sleep 10

if command -v curl &> /dev/null; then
    echo "Probando: curl -H 'Host: dashboard.checkin24hs.com' http://localhost/api/version"
    RESPONSE=$(curl -s -H "Host: dashboard.checkin24hs.com" "http://localhost/api/version" 2>/dev/null)
    
    if [ ! -z "$RESPONSE" ]; then
        echo "✅ Respuesta recibida:"
        echo "$RESPONSE" | head -3
    else
        echo "❌ No se recibió respuesta"
        echo ""
        echo "5️⃣ Verificando si Traefik está escuchando..."
        docker service ps traefik --no-trunc | head -3
    fi
else
    echo "⚠️  curl no está disponible, no se puede probar"
fi

echo ""
echo "6️⃣ Verificando logs recientes de Traefik..."
docker service logs traefik --tail 20 | grep -iE "dashboard|api|404" | tail -5

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Si el endpoint aún no funciona:"
echo ""
echo "1. El problema puede ser que Traefik necesita más tiempo para actualizar"
echo "   Espera 2-3 minutos y prueba de nuevo desde el navegador:"
echo "   https://dashboard.checkin24hs.com/api/version"
echo ""
echo "2. Verifica en EasyPanel que el dominio esté configurado:"
echo "   - Ve a EasyPanel → Servicio dashboard → Dominios"
echo "   - Debe estar: dashboard.checkin24hs.com → puerto 3000"
echo ""
echo "3. Si el problema persiste, puede ser necesario:"
echo "   - Eliminar y recrear el servicio desde EasyPanel"
echo "   - O configurar Traefik manualmente para deshabilitar auto-detect"
echo ""
