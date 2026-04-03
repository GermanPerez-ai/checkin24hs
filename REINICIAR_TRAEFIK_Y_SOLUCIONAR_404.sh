#!/bin/bash

echo "🔄 REINICIANDO TRAEFIK Y SOLUCIONANDO 404"
echo "=========================================="
echo ""

# 1. Encontrar servicio Traefik
echo "1️⃣ Buscando servicio Traefik..."
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
TRAEFIK_NAME=$(docker service ls | grep -i traefik | awk '{print $2}' | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró servicio Traefik"
    echo "📋 Servicios disponibles:"
    docker service ls
    exit 1
fi

echo "✅ Traefik encontrado: $TRAEFIK_NAME ($TRAEFIK_SERVICE)"
echo ""

# 2. Encontrar servicio dashboard
echo "2️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)
DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "✅ Dashboard encontrado: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 3. Verificar y agregar labels de Traefik al dashboard
echo "3️⃣ Verificando y agregando labels de Traefik al dashboard..."
docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
    --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
    --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.dashboard.tls=true" \
    --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
    --label-add "traefik.docker.network=easypanel" \
    $DASHBOARD_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Labels de Traefik agregadas al dashboard"
else
    echo "❌ Error al agregar labels"
    exit 1
fi
echo ""

# 4. Verificar labels agregadas
echo "4️⃣ Verificando labels agregadas..."
docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}'
echo ""

# 5. Reiniciar Traefik
echo "5️⃣ Reiniciando Traefik para que detecte los cambios..."
docker service update --force $TRAEFIK_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Traefik reiniciado"
else
    echo "❌ Error al reiniciar Traefik"
    exit 1
fi
echo ""

# 6. Esperar a que Traefik se reinicie
echo "6️⃣ Esperando 30 segundos para que Traefik se reinicie completamente..."
sleep 30

# 7. Verificar estado de Traefik
echo "7️⃣ Verificando estado de Traefik..."
docker service ps $TRAEFIK_SERVICE --no-trunc | head -5
echo ""

# 8. Ver logs de Traefik
echo "8️⃣ Últimos logs de Traefik (últimas 20 líneas)..."
docker service logs $TRAEFIK_SERVICE --tail 20 2>&1 | tail -20
echo ""

# 9. Verificar que el dashboard tiene las labels
echo "9️⃣ Verificando que el dashboard tiene las labels de Traefik..."
TRAEFIK_LABELS_COUNT=$(docker service inspect $DASHBOARD_SERVICE --format '{{range $key, $value := .Spec.Labels}}{{if contains $key "traefik"}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}' | wc -l)
echo "Labels de Traefik encontradas: $TRAEFIK_LABELS_COUNT"
echo ""

# 10. Resumen final
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Traefik: $TRAEFIK_NAME (reiniciado)"
echo "   - Dashboard: $DASHBOARD_NAME (labels aplicadas)"
echo "   - Labels de Traefik: $TRAEFIK_LABELS_COUNT"
echo ""
echo "⏳ PRÓXIMOS PASOS:"
echo "   1. Espera 1-2 minutos más para que Traefik detecte completamente los cambios"
echo "   2. Prueba acceder a: https://dashboard.checkin24hs.com/"
echo "   3. Si aún ves 404, verifica:"
echo "      - DNS: nslookup dashboard.checkin24hs.com"
echo "      - Logs de Traefik: docker service logs $TRAEFIK_NAME --tail 50"
echo "      - Estado del dashboard: docker service ps $DASHBOARD_NAME"
echo ""
echo "💡 Si el problema persiste después de 2 minutos:"
echo "   - Verifica en EasyPanel que el dominio esté configurado"
echo "   - Revisa los logs de Traefik para errores"
echo ""
