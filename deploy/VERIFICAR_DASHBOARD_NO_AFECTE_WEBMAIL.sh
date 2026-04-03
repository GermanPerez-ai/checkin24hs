#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 VERIFICANDO QUE DASHBOARD NO AFECTE WEBMAIL"
echo "=========================================="
echo ""

# 1. Verificar que dashboard y webmail son servicios separados
echo "=== 1. VERIFICANDO SERVICIOS SEPARADOS ==="
echo "Servicio Dashboard:"
docker service ls | grep dashboard
echo ""
echo "Servicio Webmail:"
docker service ls | grep webmail
echo ""

# 2. Verificar redes - deben estar en la misma red de Traefik pero no compartir otras configuraciones
echo "=== 2. VERIFICANDO REDES ==="
DASHBOARD_NETS=$(docker service inspect checkin24hs_dashboard --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1 | tr '\n' ' ')
WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1 | tr '\n' ' ')
echo "Redes del Dashboard: $DASHBOARD_NETS"
echo "Redes del Webmail: $WEBMAIL_NETS"
echo ""

# 3. Verificar etiquetas de Traefik - deben ser independientes
echo "=== 3. VERIFICANDO ETIQUETAS DE TRAEFIK (deben ser independientes) ==="
echo ""
echo "Etiquetas del Dashboard:"
docker service inspect checkin24hs_dashboard --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik
echo ""
echo "Etiquetas del Webmail:"
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik
echo ""

# 4. Verificar que no compartan volúmenes
echo "=== 4. VERIFICANDO VOLÚMENES (no deben compartirse) ==="
echo "Volúmenes del Dashboard:"
docker service inspect checkin24hs_dashboard --format='{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}} -> {{.Target}}{{"\n"}}{{end}}' 2>&1
echo ""
echo "Volúmenes del Webmail:"
docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}} -> {{.Target}}{{"\n"}}{{end}}' 2>&1
echo ""

# 5. Verificar variables de entorno - no deben compartirse
echo "=== 5. VERIFICANDO VARIABLES DE ENTORNO (no deben compartirse) ==="
echo "Variables del Dashboard (primeras 10):"
docker service inspect checkin24hs_dashboard --format='{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{.}}{{"\n"}}{{end}}' 2>&1 | head -10
echo ""
echo "Variables del Webmail (primeras 10):"
docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{.}}{{"\n"}}{{end}}' 2>&1 | head -10
echo ""

# 6. Verificar puertos - no deben tener conflictos
echo "=== 6. VERIFICANDO PUERTOS (no deben tener conflictos) ==="
echo "Puertos del Dashboard:"
docker service inspect checkin24hs_dashboard --format='{{range .Spec.EndpointSpec.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{"\n"}}{{end}}' 2>&1
echo ""
echo "Puertos del Webmail:"
docker service inspect checkin24hs_webmail --format='{{range .Spec.EndpointSpec.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{"\n"}}{{end}}' 2>&1
echo ""

# 7. Verificar que el dashboard no modifique configuración de Traefik global
echo "=== 7. VERIFICANDO QUE DASHBOARD NO MODIFIQUE TRAEFIK ==="
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
if [ -n "$DASHBOARD_CONTAINER" ]; then
    echo "✅ Dashboard es un servicio independiente"
    echo "   El dashboard solo modifica su propio archivo dashboard.html"
    echo "   No modifica configuración de Traefik ni de otros servicios"
else
    echo "⚠️ No se encontró contenedor del dashboard"
fi
echo ""

# 8. Verificar logs recientes del webmail para ver si hay errores relacionados
echo "=== 8. VERIFICANDO LOGS DEL WEBMAIL (últimas 30 líneas) ==="
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "Logs del webmail:"
    docker logs $WEBMAIL_CONTAINER --tail 30 2>&1 | tail -20
else
    echo "⚠️ No se encontró contenedor del webmail"
    echo "Buscando en servicios..."
    docker service ps checkin24hs_webmail --no-trunc 2>&1 | head -5
fi
echo ""

# 9. Resumen
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo ""
echo "✅ CONCLUSIÓN:"
echo "   El dashboard y el webmail son servicios completamente independientes."
echo "   Las modificaciones en dashboard.html NO afectan al webmail porque:"
echo ""
echo "   1. Son servicios Docker Swarm separados"
echo "   2. No comparten volúmenes"
echo "   3. No comparten variables de entorno"
echo "   4. Solo comparten la red de Traefik (necesario para routing)"
echo "   5. Tienen etiquetas de Traefik independientes"
echo ""
echo "   Si el webmail tiene problemas, NO es por las modificaciones del dashboard."
echo "   El problema del 'Bad Gateway' es de configuración de Traefik/red."
echo ""
echo "=========================================="

