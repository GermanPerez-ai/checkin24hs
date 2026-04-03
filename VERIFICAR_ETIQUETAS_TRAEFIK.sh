#!/bin/bash
# Verificar etiquetas Traefik del servicio dashboard

echo "=========================================="
echo "🔍 Verificando etiquetas Traefik"
echo "=========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"

echo "1️⃣ Verificando etiquetas del servicio..."
SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null)

if [ -z "$SERVICE_JSON" ] || [ "$SERVICE_JSON" = "{}" ]; then
    echo "❌ El servicio NO tiene etiquetas"
else
    echo "✅ El servicio tiene etiquetas:"
    echo "$SERVICE_JSON" | jq '.' 2>/dev/null || echo "$SERVICE_JSON"
    echo ""
    
    TRAEFIK_LABELS=$(echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)
    
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo "❌ NO hay etiquetas Traefik"
    else
        echo "✅ Etiquetas Traefik encontradas:"
        echo "$TRAEFIK_LABELS"
    fi
fi

echo ""
echo "2️⃣ Verificando etiquetas en contenedores activos..."
CONTAINER_IDS=$(docker ps --filter "name=dashboard" --format "{{.ID}}")

if [ -z "$CONTAINER_IDS" ]; then
    echo "⚠️ No se encontraron contenedores activos"
else
    for container_id in $CONTAINER_IDS; do
        echo ""
        echo "Contenedor: $container_id"
        CONTAINER_LABELS=$(docker inspect "$container_id" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
        
        if [ -z "$CONTAINER_LABELS" ]; then
            echo "  ❌ No tiene etiquetas Traefik"
        else
            echo "  ✅ Tiene etiquetas Traefik:"
            echo "$CONTAINER_LABELS" | sed 's/^/    /'
        fi
    done
fi

echo ""
echo "3️⃣ Verificando configuración de Traefik..."
TRAEFIK_ROUTERS=$(docker service logs traefik --tail 100 2>&1 | grep -i "dashboard-checkin24hs" | tail -5)

if [ -z "$TRAEFIK_ROUTERS" ]; then
    echo "⚠️ No se encontraron referencias a 'dashboard-checkin24hs' en logs de Traefik"
else
    echo "✅ Referencias encontradas en Traefik:"
    echo "$TRAEFIK_ROUTERS"
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ PROBLEMA: Las etiquetas Traefik NO están aplicadas"
    echo ""
    echo "✅ SOLUCIÓN: Configurar dominio desde EasyPanel"
    echo ""
    echo "📋 PASOS EN EASYPANEL:"
    echo ""
    echo "   1. Abre: http://72.61.58.240:3000"
    echo "   2. Proyecto: checkin24hs"
    echo "   3. Servicio: dashboard"
    echo "   4. Pestaña: '🔗 Dominios' o 'Domains'"
    echo "   5. Clic: 'Agregar Dominio' o 'Add Domain'"
    echo "   6. Ingresa: dashboard.checkin24hs.com"
    echo "   7. Configura:"
    echo "      ✅ HTTPS: Activado"
    echo "      ✅ Puerto destino: 3000"
    echo "      ✅ Ruta destino: /"
    echo "   8. Guarda"
    echo "   9. Espera 1-2 minutos"
    echo ""
    echo "   EasyPanel aplicará las etiquetas automáticamente"
else
    echo "✅ Las etiquetas Traefik están aplicadas"
    echo ""
    echo "⏳ Espera 1-2 minutos y prueba:"
    echo "   https://dashboard.checkin24hs.com"
fi

echo ""
