#!/bin/bash
# Script para diagnosticar y corregir conflictos de Traefik

echo "=========================================="
echo "🔍 Diagnosticando configuración Traefik"
echo "=========================================="
echo ""

# 1. Listar todos los servicios
echo "1️⃣ Servicios disponibles:"
docker service ls
echo ""

# 2. Verificar etiquetas de cada servicio relacionado
echo "2️⃣ Verificando etiquetas Traefik de servicios relacionados..."
echo ""

# Buscar servicios que puedan tener etiquetas Traefik
SERVICES=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard|crm|checkin24hs")

for SERVICE in $SERVICES; do
    echo "--- Servicio: $SERVICE ---"
    TRAEFIK_LABELS=$(docker service inspect "$SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
    
    if [ ! -z "$TRAEFIK_LABELS" ]; then
        echo "Etiquetas Traefik encontradas:"
        echo "$TRAEFIK_LABELS"
    else
        echo "No tiene etiquetas Traefik"
    fi
    echo ""
done

# 3. Identificar el servicio del dashboard
echo "3️⃣ Identificando servicio del dashboard..."
DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard" | grep -viE "crm" | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -iE "^checkin24hs_dashboard$|^checkin24hs-dashboard$" | head -1)
fi

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio del dashboard"
    echo ""
    echo "Por favor, especifica el nombre del servicio del dashboard:"
    read -p "Nombre del servicio: " DASHBOARD_SERVICE
else
    echo "✅ Servicio del dashboard encontrado: $DASHBOARD_SERVICE"
fi
echo ""

# 4. Identificar el servicio del CRM
echo "4️⃣ Identificando servicio del CRM..."
CRM_SERVICE=$(docker service ls --format "{{.Name}}" | grep -iE "crm" | head -1)

if [ ! -z "$CRM_SERVICE" ]; then
    echo "✅ Servicio del CRM encontrado: $CRM_SERVICE"
    
    # Verificar si el CRM tiene etiquetas con router "dashboard" (conflicto)
    CRM_DASHBOARD_ROUTER=$(docker service inspect "$CRM_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "traefik.http.routers.dashboard")
    
    if [ ! -z "$CRM_DASHBOARD_ROUTER" ]; then
        echo "⚠️  CONFLICTO DETECTADO: El CRM tiene etiquetas con router 'dashboard'"
        echo "   Esto causa el error en Traefik"
        echo ""
        echo "¿Deseas eliminar las etiquetas conflictivas del CRM? (s/n): "
        read -p "" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[SsYy]$ ]]; then
            echo "🗑️  Eliminando etiquetas conflictivas del CRM..."
            docker service update \
              --label-rm "traefik.http.routers.dashboard.rule" \
              --label-rm "traefik.http.routers.dashboard.entrypoints" \
              --label-rm "traefik.http.routers.dashboard.tls" \
              --label-rm "traefik.http.routers.dashboard.tls.certresolver" \
              --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
              "$CRM_SERVICE" 2>/dev/null || echo "No se pudieron eliminar algunas etiquetas"
            
            echo "✅ Etiquetas conflictivas eliminadas del CRM"
        fi
    fi
else
    echo "ℹ️  No se encontró servicio del CRM"
fi
echo ""

# 5. Configurar el dashboard correctamente
echo "5️⃣ Configurando el dashboard..."
echo ""

# Verificar si el dashboard ya tiene etiquetas
DASHBOARD_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "traefik.http.routers.dashboard")

if [ ! -z "$DASHBOARD_LABELS" ]; then
    echo "⚠️  El dashboard ya tiene etiquetas Traefik"
    echo "¿Deseas reemplazarlas? (s/n): "
    read -p "" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo "🗑️  Eliminando etiquetas antiguas..."
        docker service update \
          --label-rm "traefik.enable" \
          --label-rm "traefik.http.routers.dashboard.rule" \
          --label-rm "traefik.http.routers.dashboard.entrypoints" \
          --label-rm "traefik.http.routers.dashboard.tls" \
          --label-rm "traefik.http.routers.dashboard.tls.certresolver" \
          --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
          "$DASHBOARD_SERVICE" 2>/dev/null || echo "No se pudieron eliminar algunas etiquetas"
        
        sleep 5
    else
        echo "✅ Manteniendo etiquetas existentes"
        exit 0
    fi
fi

# Agregar etiquetas correctas al dashboard
echo "🔧 Agregando etiquetas Traefik al dashboard..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas Traefik agregadas correctamente al dashboard"
else
    echo "❌ Error al agregar etiquetas Traefik"
    exit 1
fi

# 6. Esperar y verificar
echo ""
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "7️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 50 | grep -iE "dashboard|error" | tail -10

echo ""
echo "=========================================="
echo "✅ Diagnóstico y corrección completados"
echo "=========================================="
echo ""
echo "Servicio dashboard: $DASHBOARD_SERVICE"
echo "Dominio: dashboard.checkin24hs.com"
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  https://dashboard.checkin24hs.com"
echo ""
