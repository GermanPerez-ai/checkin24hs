#!/bin/bash
# Corregir configuración de Traefik para que pase todas las rutas incluyendo /api/*

echo "=========================================="
echo "🔧 Corrigiendo Traefik para rutas /api/*"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando etiquetas actuales de Traefik..."
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "2️⃣ El problema es que Traefik puede no estar pasando las rutas /api/* al servicio"
echo "   Vamos a asegurarnos de que todas las rutas se pasen correctamente"
echo ""

echo "3️⃣ Actualizando etiquetas de Traefik para asegurar que todas las rutas se pasen..."
echo "   (Manteniendo las etiquetas existentes y asegurando que no haya restricciones)"
echo ""

# Obtener etiquetas actuales
CURRENT_RULE=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{if eq $key "traefik.http.routers.dashboard-checkin24hs.rule"}}{{$value}}{{end}}{{end}}')

if [ -z "$CURRENT_RULE" ]; then
    echo "⚠️  No se encontró regla de Traefik, creando una nueva..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=web" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.routers.dashboard-checkin24hs.tls=true" \
      --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" \
      "$DASHBOARD_SERVICE"
else
    echo "✅ Regla existente encontrada: $CURRENT_RULE"
    echo "   Las etiquetas ya están configuradas"
    echo ""
    echo "   El problema puede ser que Traefik necesita tiempo para actualizar"
    echo "   o que hay un problema con cómo Traefik está enrutando las peticiones"
fi

echo ""
echo "4️⃣ Esperando 30 segundos para que Traefik actualice..."
sleep 30

echo ""
echo "5️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 20 | grep -iE "dashboard|api|404" | tail -10

echo ""
echo "6️⃣ Probando acceso a través de Traefik..."
echo "   Desde el navegador, prueba: https://dashboard.checkin24hs.com/api/version"
echo "   O desde el servidor:"
echo ""

# Probar con curl si está disponible
if command -v curl &> /dev/null; then
    echo "Probando con curl..."
    curl -s -H "Host: dashboard.checkin24hs.com" "http://localhost/api/version" 2>/dev/null | head -3 || echo "⚠️  No responde (puede ser normal si Traefik requiere HTTPS)"
else
    echo "⚠️  curl no está disponible para probar"
fi

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "El endpoint funciona directamente en el contenedor."
echo "El problema es que Traefik no está pasando las rutas /api/* al servicio."
echo ""
echo "Posibles soluciones:"
echo "  1. Verificar en EasyPanel que el dominio esté configurado para pasar todas las rutas"
echo "  2. Esperar más tiempo para que Traefik actualice su configuración"
echo "  3. Reiniciar Traefik para forzar la actualización"
echo ""
echo "Si el problema persiste, puede ser necesario:"
echo "  - Configurar un middleware en Traefik para pasar todas las rutas"
echo "  - Verificar la configuración de EasyPanel para el dominio"
echo ""
