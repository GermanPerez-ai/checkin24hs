#!/bin/bash
# Aplicar etiquetas Traefik de forma forzada

echo "=========================================="
echo "🔧 Aplicando etiquetas Traefik de forma forzada"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando estado actual del servicio..."
docker service inspect "$DASHBOARD_SERVICE" --format '{{.Spec.Name}}' && echo "✅ Servicio existe" || exit 1

echo ""
echo "2️⃣ El problema puede ser que EasyPanel está gestionando el servicio"
echo "   y sobrescribiendo las etiquetas."
echo ""

echo "3️⃣ Intentando agregar etiquetas una por una..."
docker service update --label-add "traefik.enable=true" "$DASHBOARD_SERVICE"
sleep 3

docker service update --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" "$DASHBOARD_SERVICE"
sleep 3

docker service update --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=web" "$DASHBOARD_SERVICE"
sleep 3

docker service update --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" "$DASHBOARD_SERVICE"
sleep 3

docker service update --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" "$DASHBOARD_SERVICE"
sleep 3

docker service update --label-add "traefik.http.routers.dashboard-checkin24hs.tls=true" "$DASHBOARD_SERVICE"
sleep 3

docker service update --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" "$DASHBOARD_SERVICE"
sleep 5

echo ""
echo "4️⃣ Verificando etiquetas después de agregarlas..."
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "5️⃣ Si las etiquetas aún no aparecen, el problema es que EasyPanel"
echo "   está gestionando el servicio y sobrescribiendo las etiquetas."
echo ""
echo "   SOLUCIÓN: Configurar el dominio desde EasyPanel:"
echo "   1. Ve a EasyPanel → Servicio dashboard → Dominios"
echo "   2. Agrega: dashboard.checkin24hs.com → puerto 3000"
echo "   3. EasyPanel agregará las etiquetas automáticamente"
echo ""

echo "6️⃣ Verificando si hay un archivo de configuración de EasyPanel..."
echo "   (EasyPanel puede estar gestionando las etiquetas desde su configuración)"
echo ""

echo "=========================================="
echo "📋 Conclusión"
echo "=========================================="
echo ""
echo "Si las etiquetas no se aplican con docker service update,"
echo "es porque EasyPanel está gestionando el servicio."
echo ""
echo "La solución correcta es configurar el dominio desde EasyPanel,"
echo "que agregará las etiquetas Traefik automáticamente."
echo ""
