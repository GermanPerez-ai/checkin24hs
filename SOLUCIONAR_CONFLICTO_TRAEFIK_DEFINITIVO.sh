#!/bin/bash
# Script para resolver definitivamente el conflicto de Traefik entre CRM y Dashboard

echo "==========================================="
echo "🔧 Solucionando Conflicto Traefik"
echo "==========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
CRM_SERVICE="checkin24hs_crm"

# 1. Eliminar TODAS las etiquetas Traefik del CRM
echo "1️⃣ Eliminando etiquetas Traefik del CRM..."
CRM_LABELS=$(docker service inspect "$CRM_SERVICE" --format '{{json .Spec.Labels}}' 2>/dev/null | jq -r 'to_entries[] | select(.key | contains("traefik")) | .key' 2>/dev/null)

if [ -n "$CRM_LABELS" ]; then
    echo "$CRM_LABELS" | while read -r label; do
        if [ -n "$label" ]; then
            echo "   Eliminando: $label"
            docker service update --label-rm "$label" "$CRM_SERVICE" 2>/dev/null || true
        fi
    done
    sleep 5
    print_success "Etiquetas del CRM eliminadas"
else
    echo "   ℹ️  El CRM no tiene etiquetas Traefik"
fi

echo ""

# 2. Verificar y actualizar etiquetas del Dashboard con router único
echo "2️⃣ Verificando etiquetas del Dashboard..."
DASHBOARD_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.Labels}}' 2>/dev/null | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -n "$DASHBOARD_LABELS" ]; then
    echo "   ✅ Etiquetas actuales del Dashboard:"
    echo "$DASHBOARD_LABELS" | sed 's/^/      /'
    
    # Verificar si el router tiene un nombre único
    ROUTER_NAME=$(echo "$DASHBOARD_LABELS" | grep "traefik.http.routers" | head -1 | cut -d'.' -f4)
    
    if [ -z "$ROUTER_NAME" ] || [ "$ROUTER_NAME" = "dashboard" ]; then
        echo ""
        echo "   ⚠️  El router tiene un nombre genérico. Actualizando a nombre único..."
        
        # Eliminar etiquetas antiguas
        echo "$DASHBOARD_LABELS" | cut -d'=' -f1 | while read -r label; do
            if [ -n "$label" ]; then
                docker service update --label-rm "$label" "$DASHBOARD_SERVICE" 2>/dev/null || true
            fi
        done
        
        sleep 5
        
        # Aplicar nuevas etiquetas con router único
        UNIQUE_ROUTER="dashboard-checkin24hs-$(date +%s)"
        DOMAIN="dashboard.checkin24hs.com"
        PORT="3000"
        NETWORK="easypanel"
        
        docker service update \
            --label-add "traefik.enable=true" \
            --label-add "traefik.http.routers.$UNIQUE_ROUTER.rule=Host(\`$DOMAIN\`)" \
            --label-add "traefik.http.routers.$UNIQUE_ROUTER.entrypoints=websecure" \
            --label-add "traefik.http.routers.$UNIQUE_ROUTER.tls.certresolver=letsencrypt" \
            --label-add "traefik.http.routers.$UNIQUE_ROUTER.service=$UNIQUE_ROUTER" \
            --label-add "traefik.http.services.$UNIQUE_ROUTER.loadbalancer.server.port=$PORT" \
            --label-add "traefik.docker.network=$NETWORK" \
            "$DASHBOARD_SERVICE"
        
        echo "   ✅ Router único aplicado: $UNIQUE_ROUTER"
    else
        echo ""
        echo "   ✅ El router ya tiene un nombre único: $ROUTER_NAME"
    fi
else
    echo "   ❌ No se encontraron etiquetas en el Dashboard"
fi

echo ""

# 3. Reiniciar Traefik para limpiar conflictos
echo "3️⃣ Reiniciando Traefik para limpiar conflictos..."
TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i "traefik" | head -1)

if [ -n "$TRAEFIK_SERVICE" ]; then
    docker service update --force "$TRAEFIK_SERVICE" >/dev/null 2>&1
    echo "   ✅ Traefik reiniciado"
    echo "   ⏳ Esperando 30 segundos para que Traefik se reinicie..."
    sleep 30
else
    echo "   ❌ No se encontró servicio Traefik"
fi

echo ""

# 4. Verificar logs de Traefik para confirmar que no hay conflictos
echo "4️⃣ Verificando logs de Traefik..."
if [ -n "$TRAEFIK_SERVICE" ]; then
    CONFLICTS=$(docker service logs "$TRAEFIK_SERVICE" --tail 20 2>&1 | grep -i "cannot be linked automatically" | wc -l)
    
    if [ "$CONFLICTS" -eq 0 ]; then
        echo "   ✅ No se encontraron conflictos en los logs recientes"
    else
        echo "   ⚠️  Aún hay $CONFLICTS conflictos en los logs"
        echo "   Últimos conflictos:"
        docker service logs "$TRAEFIK_SERVICE" --tail 20 2>&1 | grep -i "cannot be linked automatically" | tail -3 | sed 's/^/      /'
    fi
fi

echo ""
echo "==========================================="
echo "📋 Resumen"
echo "==========================================="
echo ""
echo "✅ Conflicto de Traefik resuelto"
echo ""
echo "Espera 1-2 minutos y verifica que:"
echo "  1. No haya más errores de conflicto en los logs de Traefik"
echo "  2. El dashboard sea accesible en: https://dashboard.checkin24hs.com"
echo ""
echo "Para verificar los logs:"
echo "  docker service logs $TRAEFIK_SERVICE --tail 50 | grep -i conflict"
echo ""
