#!/bin/bash
# Verificación completa y guía para configurar Traefik correctamente

echo "=========================================="
echo "🔍 Verificación completa de Traefik"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "1️⃣ Verificando estado del servicio dashboard..."
docker service ls | grep dashboard || echo "⚠️ Servicio dashboard no encontrado"

echo ""
echo "2️⃣ Verificando contenedores del dashboard..."
CONTAINERS=$(docker ps --filter "name=dashboard" --format "{{.ID}}")
if [ -z "$CONTAINERS" ]; then
    echo "⚠️ No se encontraron contenedores del dashboard"
else
    echo "✅ Contenedores encontrados:"
    for container in $CONTAINERS; do
        echo "   - $container"
    done
fi

echo ""
echo "3️⃣ Verificando etiquetas del servicio (método detallado)..."
SERVICE_INSPECT=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)

if [ -z "$SERVICE_INSPECT" ] || [ "$SERVICE_INSPECT" = "null" ] || [ "$SERVICE_INSPECT" = "{}" ]; then
    echo "❌ El servicio NO tiene etiquetas"
else
    echo "📋 Etiquetas encontradas:"
    echo "$SERVICE_INSPECT" | jq -r 'to_entries[] | "\(.key)=\(.value)"' 2>/dev/null || echo "$SERVICE_INSPECT"
    
    # Verificar específicamente etiquetas Traefik
    TRAEFIK_LABELS=$(echo "$SERVICE_INSPECT" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo ""
        echo "❌ No se encontraron etiquetas Traefik"
    else
        echo ""
        echo "✅ Etiquetas Traefik encontradas:"
        echo "$TRAEFIK_LABELS"
    fi
fi

echo ""
echo "4️⃣ Verificando red del servicio..."
NETWORKS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if [ -z "$NETWORKS" ]; then
    echo "⚠️ El servicio no tiene redes configuradas"
else
    echo "📋 Redes del servicio:"
    echo "$NETWORKS"
    
    # Verificar si está en la red easypanel
    if echo "$NETWORKS" | grep -q "easypanel"; then
        echo "✅ El servicio está en la red easypanel"
    else
        echo "⚠️ El servicio NO está en la red easypanel"
    fi
fi

echo ""
echo "5️⃣ Verificando logs de Traefik para conflictos..."
TRAEFIK_LOGS=$(docker service logs traefik --tail 50 2>&1 | grep -iE "(dashboard|error|router.*cannot)" | tail -10)
if [ -z "$TRAEFIK_LOGS" ]; then
    echo "✅ No se encontraron errores relevantes en los logs de Traefik"
else
    echo "⚠️ Errores encontrados en Traefik:"
    echo "$TRAEFIK_LOGS"
fi

echo ""
echo "6️⃣ Verificando si el servicio responde directamente..."
FIRST_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$FIRST_CONTAINER" ]; then
    echo "Probando acceso directo al contenedor $FIRST_CONTAINER..."
    docker exec "$FIRST_CONTAINER" node -e "
    const http = require('http');
    http.get('http://127.0.0.1:3000/', {family: 4}, (res) => {
        console.log('Status:', res.statusCode);
        process.exit(res.statusCode === 200 ? 0 : 1);
    }).on('error', (err) => {
        console.error('Error:', err.message);
        process.exit(1);
    });
    " 2>&1
else
    echo "⚠️ No se encontró contenedor para probar"
fi

echo ""
echo "=========================================="
echo "📋 DIAGNÓSTICO"
echo "=========================================="
echo ""

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ PROBLEMA: Las etiquetas Traefik NO se están aplicando"
    echo ""
    echo "🔍 CAUSA PROBABLE: EasyPanel está sobrescribiendo las etiquetas"
    echo ""
    echo "✅ SOLUCIÓN RECOMENDADA:"
    echo "   Configurar el dominio desde EasyPanel en lugar de aplicar etiquetas manualmente"
    echo ""
    echo "📋 PASOS EN EASYPANEL:"
    echo ""
    echo "   1. Ve a EasyPanel: http://72.61.58.240:3000"
    echo "   2. Ve al proyecto 'checkin24hs'"
    echo "   3. Ve al servicio 'dashboard' (o 'checkin24hs_dashboard')"
    echo "   4. Ve a la pestaña '🔗 Dominios' o 'Domains'"
    echo "   5. Haz clic en 'Agregar Dominio' o 'Add Domain'"
    echo "   6. Ingresa: dashboard.checkin24hs.com"
    echo "   7. Asegúrate de que:"
    echo "      - HTTPS esté activado"
    echo "      - Puerto destino: 3000"
    echo "      - Ruta destino: /"
    echo "   8. Guarda los cambios"
    echo "   9. Espera 1-2 minutos para que Traefik detecte el dominio"
    echo ""
    echo "   EasyPanel aplicará las etiquetas Traefik automáticamente"
    echo ""
else
    echo "✅ Las etiquetas Traefik están aplicadas"
    echo ""
    echo "⏳ Espera 1-2 minutos y prueba acceder a:"
    echo "   https://$DOMAIN"
    echo ""
    echo "Si aún no funciona, verifica:"
    echo "   1. Que el DNS apunte correctamente a este servidor"
    echo "   2. Que Traefik esté corriendo: docker service ls | grep traefik"
    echo "   3. Los logs de Traefik: docker service logs traefik --tail 50"
fi

echo ""
echo "=========================================="
echo "🔧 COMANDOS ÚTILES"
echo "=========================================="
echo ""
echo "Verificar estado del servicio:"
echo "  docker service ps $DASHBOARD_SERVICE"
echo ""
echo "Ver logs del dashboard:"
echo "  docker service logs $DASHBOARD_SERVICE --tail 20"
echo ""
echo "Ver logs de Traefik:"
echo "  docker service logs traefik --tail 50"
echo ""
echo "Verificar etiquetas del servicio:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq"
echo ""
