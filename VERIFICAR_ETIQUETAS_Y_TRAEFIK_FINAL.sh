#!/bin/bash
# Verificación final de etiquetas y configuración de Traefik

echo "=========================================="
echo "🔍 Verificación final de Traefik"
echo "=========================================="
echo ""

echo "1️⃣ Etiquetas actuales del servicio dashboard:"
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "2️⃣ El problema es que Traefik está detectando automáticamente servicios"
echo "   y creando routers 'dashboard' y 'crm' basándose en los nombres de los servicios."
echo ""

echo "3️⃣ Verificando qué servicios Traefik está detectando automáticamente..."
echo "   (Esto puede requerir acceso a la API de Traefik)"
echo ""

TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Intentando acceder a la API de Traefik para ver routers configurados..."
    docker exec "$TRAEFIK_CONTAINER" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | head -100 || echo "No se puede acceder a la API de Traefik (puede no estar habilitada)"
fi

echo ""
echo "4️⃣ El problema real es que Traefik está en modo 'auto-detect'"
echo "   y está creando routers automáticamente basándose en los nombres de los servicios."
echo ""
echo "   Solución: Necesitamos deshabilitar la detección automática o"
echo "   asegurarnos de que solo use servicios con traefik.enable=true explícitamente."
echo ""

echo "5️⃣ Verificando si podemos acceder al endpoint a través de Traefik desde el host..."
echo "   Probando con el dominio configurado..."
if command -v curl &> /dev/null; then
    echo "Probando: curl -H 'Host: dashboard.checkin24hs.com' http://localhost/api/version"
    curl -s -H "Host: dashboard.checkin24hs.com" "http://localhost/api/version" 2>/dev/null | head -3 || echo "❌ No responde"
else
    echo "⚠️  curl no está disponible"
fi

echo ""
echo "=========================================="
echo "📋 Resumen y Recomendación"
echo "=========================================="
echo ""
echo "El endpoint funciona directamente en el contenedor."
echo "El problema es que Traefik tiene conflictos de routers automáticos."
echo ""
echo "Opciones para solucionarlo:"
echo ""
echo "1. Configurar Traefik para que solo detecte servicios con traefik.enable=true"
echo "   (Esto requiere modificar la configuración de Traefik)"
echo ""
echo "2. Usar EasyPanel para configurar el dominio correctamente"
echo "   - Ve a EasyPanel"
echo "   - Ve al servicio dashboard"
echo "   - Ve a la pestaña 'Dominios'"
echo "   - Elimina y vuelve a agregar el dominio dashboard.checkin24hs.com"
echo "   - Asegúrate de que el puerto destino sea 3000"
echo ""
echo "3. Acceder directamente al dashboard sin Traefik (temporal)"
echo "   - Obtener IP del contenedor y acceder directamente"
echo ""
echo "¿Quieres que verifiquemos la configuración de EasyPanel?"
echo ""
