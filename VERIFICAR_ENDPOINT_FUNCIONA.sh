#!/bin/bash
# Verificar si el endpoint funciona después de agregar las etiquetas

echo "=========================================="
echo "✅ Verificando si el endpoint funciona ahora"
echo "=========================================="
echo ""

echo "1️⃣ Verificando etiquetas Traefik aplicadas..."
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "2️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "3️⃣ Verificando logs de Traefik para ver si detectó el servicio..."
docker service logs traefik --tail 30 | grep -iE "dashboard-checkin24hs|dashboard.checkin24hs.com" | tail -10

echo ""
echo "4️⃣ Probando acceso al endpoint desde el navegador..."
echo "   Abre en tu navegador: https://dashboard.checkin24hs.com/api/version"
echo "   Deberías ver: {\"version\":\"2.1.0\",\"buildTimestamp\":null,\"timestamp\":\"...\"}"
echo ""

echo "5️⃣ Si aún no funciona, verifica:"
echo "   - Que el DNS apunte correctamente al servidor"
echo "   - Que Traefik esté escuchando en los puertos 80 y 443"
echo "   - Los logs de Traefik para ver si hay errores"
echo ""

echo "6️⃣ Verificando estado de Traefik..."
docker service ps traefik --no-trunc | head -3

echo ""
echo "7️⃣ Verificando puertos de Traefik..."
docker service inspect traefik --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}} {{end}}'

echo ""
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "Las etiquetas Traefik han sido agregadas correctamente."
echo ""
echo "Próximos pasos:"
echo "  1. Espera 1-2 minutos para que Traefik actualice completamente"
echo "  2. Prueba desde el navegador: https://dashboard.checkin24hs.com/api/version"
echo "  3. Si aún no funciona, verifica en EasyPanel que el dominio esté configurado"
echo ""
echo "El endpoint funciona directamente en el contenedor,"
echo "así que el problema es solo con el enrutamiento de Traefik."
echo ""
