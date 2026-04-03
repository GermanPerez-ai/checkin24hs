#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO: WEBMAIL BAD GATEWAY"
echo "=========================================="
echo ""

# 1. Verificar estado del servicio webmail
echo "=== 1. ESTADO DEL SERVICIO WEBMAIL ==="
docker service ls | grep webmail
echo ""

# 2. Verificar contenedores del webmail
echo "=== 2. CONTENEDORES DEL WEBMAIL ==="
docker ps | grep webmail
echo ""

# 3. Verificar logs recientes del webmail
echo "=== 3. LOGS RECIENTES DEL WEBMAIL (últimas 20 líneas) ==="
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "Contenedor encontrado: $WEBMAIL_CONTAINER"
    docker logs $WEBMAIL_CONTAINER --tail 20 2>&1
else
    echo "⚠️ No se encontró contenedor de webmail corriendo"
    echo "Buscando en servicios..."
    docker service ps checkin24hs_webmail --no-trunc 2>&1 | head -10
fi
echo ""

# 4. Verificar configuración de Traefik para webmail
echo "=== 4. CONFIGURACIÓN DE TRAEFIK PARA WEBMAIL ==="
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik || echo "⚠️ No se encontraron etiquetas de Traefik"
echo ""

# 5. Verificar redes del webmail
echo "=== 5. REDES DEL WEBMAIL ==="
docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1
echo ""

# 6. Verificar redes de Traefik
echo "=== 6. REDES DE TRAEFIK ==="
docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1
echo ""

# 7. Verificar si están en la misma red
echo "=== 7. VERIFICANDO CONECTIVIDAD DE RED ==="
WEBMAIL_NET=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1 | head -1)
TRAEFIK_NET=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1 | head -1)
echo "Red del webmail: $WEBMAIL_NET"
echo "Red de Traefik: $TRAEFIK_NET"
if [ "$WEBMAIL_NET" = "$TRAEFIK_NET" ]; then
    echo "✅ Están en la misma red"
else
    echo "❌ NO están en la misma red - ESTE ES EL PROBLEMA"
fi
echo ""

# 8. Verificar logs de Traefik relacionados con webmail
echo "=== 8. LOGS DE TRAEFIK RELACIONADOS CON WEBMAIL ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -i "webmail\|bad gateway\|502" | tail -10 || echo "No se encontraron errores específicos en los logs recientes"
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

# 9. Verificar puerto interno del webmail
echo "=== 9. PUERTO INTERNO DEL WEBMAIL ==="
docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.ContainerSpec.ExposedPorts}}{{.}}{{end}}' 2>&1
echo ""

# 10. Verificar si el dashboard tiene configuración que pueda afectar
echo "=== 10. VERIFICANDO CONFIGURACIÓN DEL DASHBOARD ==="
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
if [ -n "$DASHBOARD_CONTAINER" ]; then
    echo "✅ Contenedor del dashboard encontrado: $DASHBOARD_CONTAINER"
    DASHBOARD_LABELS=$(docker inspect $DASHBOARD_CONTAINER --format='{{range $k, $v := .Config.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik)
    if [ -n "$DASHBOARD_LABELS" ]; then
        echo "Etiquetas de Traefik del dashboard:"
        echo "$DASHBOARD_LABELS"
    else
        echo "⚠️ Dashboard no tiene etiquetas de Traefik"
    fi
else
    echo "⚠️ No se encontró contenedor del dashboard"
fi
echo ""

# 11. Verificar servicios en la red de EasyPanel
echo "=== 11. SERVICIOS EN LA RED EASYPANEL ==="
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -n "$EASYPANEL_NET" ]; then
    echo "Red EasyPanel: $EASYPANEL_NET"
    echo "Servicios conectados:"
    docker network inspect $EASYPANEL_NET --format='{{range .Containers}}{{.Name}} {{end}}' 2>&1 | tr ' ' '\n' | grep -E "webmail|traefik|dashboard" | head -10
else
    echo "⚠️ No se encontró red EasyPanel"
fi
echo ""

# 12. Resumen y recomendaciones
echo "=========================================="
echo "📊 RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

if [ "$WEBMAIL_NET" != "$TRAEFIK_NET" ]; then
    echo "❌ PROBLEMA ENCONTRADO: Webmail y Traefik NO están en la misma red"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   Ejecuta este comando para agregar webmail a la red de Traefik:"
    echo ""
    echo "   EASYPANEL_NET=\$(docker network ls | grep easypanel | head -1 | awk '{print \$1}')"
    echo "   docker service update --network-add \$EASYPANEL_NET checkin24hs_webmail"
    echo ""
fi

TRAEFIK_LABELS=$(docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | wc -l)
if [ "$TRAEFIK_LABELS" -eq "0" ]; then
    echo "❌ PROBLEMA ENCONTRADO: Webmail NO tiene etiquetas de Traefik"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   Ejecuta este comando para agregar etiquetas de Traefik:"
    echo ""
    echo "   docker service update \\"
    echo "     --label-add \"traefik.enable=true\" \\"
    echo "     --label-add \"traefik.http.routers.webmail.rule=Host(\\\`webmail.checkin24hs.com\\\`)\" \\"
    echo "     --label-add \"traefik.http.routers.webmail.entrypoints=web\" \\"
    echo "     --label-add \"traefik.http.services.webmail.loadbalancer.server.port=80\" \\"
    echo "     checkin24hs_webmail"
    echo ""
fi

echo "=========================================="

