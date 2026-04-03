#!/bin/bash
# Script para verificar y reaplicar etiquetas Traefik después de reiniciar Traefik

echo "==========================================="
echo "🔍 Verificando y Reaplicando Traefik"
echo "==========================================="
echo ""

DASHBOARD_SERVICE="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"
PORT="3000"
NETWORK="easypanel"

# Función para imprimir mensajes
print_success() {
    echo -e "\033[0;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[0;31m❌ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️  $1\033[0m"
}

print_info() {
    echo -e "ℹ️  $1"
}

# 1. Verificar etiquetas actuales
echo "1️⃣ Verificando etiquetas Traefik actuales..."
LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.Labels}}' 2>/dev/null | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -n "$LABELS" ]; then
    print_success "Etiquetas Traefik encontradas:"
    echo "$LABELS" | sed 's/^/   /'
    echo ""
    
    # Verificar si tiene las etiquetas esenciales
    HAS_ENABLE=$(echo "$LABELS" | grep -q "traefik.enable=true" && echo "yes" || echo "no")
    HAS_ROUTER=$(echo "$LABELS" | grep -q "traefik.http.routers" && echo "yes" || echo "no")
    
    if [ "$HAS_ENABLE" = "yes" ] && [ "$HAS_ROUTER" = "yes" ]; then
        print_success "Las etiquetas esenciales están presentes"
        echo ""
        print_info "Esperando 30 segundos para que Traefik detecte los cambios..."
        sleep 30
        echo ""
        print_success "Traefik debería estar funcionando ahora"
        echo ""
        print_info "Prueba acceder a: https://$DOMAIN"
        exit 0
    fi
else
    print_warning "No se encontraron etiquetas Traefik"
fi

echo ""

# 2. Aplicar etiquetas Traefik
echo "2️⃣ Aplicando etiquetas Traefik..."
ROUTER_NAME="dashboard-checkin24hs-$(date +%s)"

print_info "Configuración:"
print_info "  - Dominio: $DOMAIN"
print_info "  - Router: $ROUTER_NAME"
print_info "  - Puerto: $PORT"
print_info "  - Red: $NETWORK"
echo ""

docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.$ROUTER_NAME.rule=Host(\`$DOMAIN\`)" \
    --label-add "traefik.http.routers.$ROUTER_NAME.entrypoints=websecure" \
    --label-add "traefik.http.routers.$ROUTER_NAME.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.$ROUTER_NAME.service=$ROUTER_NAME" \
    --label-add "traefik.http.services.$ROUTER_NAME.loadbalancer.server.port=$PORT" \
    --label-add "traefik.docker.network=$NETWORK" \
    "$DASHBOARD_SERVICE" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    print_success "Etiquetas aplicadas correctamente"
else
    print_error "Error al aplicar las etiquetas"
    exit 1
fi

echo ""
sleep 5

# 3. Verificar que se aplicaron
echo "3️⃣ Verificando etiquetas aplicadas..."
NEW_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.Labels}}' 2>/dev/null | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null)

if [ -n "$NEW_LABELS" ]; then
    print_success "Etiquetas verificadas:"
    echo "$NEW_LABELS" | head -5 | sed 's/^/   /'
else
    print_error "No se encontraron etiquetas después de aplicar"
fi

echo ""

# 4. Esperar a que Traefik detecte los cambios
echo "4️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
for i in {30..1}; do
    echo -ne "\r   Esperando... ${i}s  "
    sleep 1
done
echo -ne "\r   Esperando... 0s  \n"
echo ""

# 5. Verificar logs de Traefik
echo "5️⃣ Verificando logs de Traefik (últimas 10 líneas relacionadas con dashboard)..."
TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i "traefik" | head -1)

if [ -n "$TRAEFIK_SERVICE" ]; then
    TRAEFIK_LOGS=$(docker service logs "$TRAEFIK_SERVICE" --tail 50 2>&1 | grep -iE "dashboard|$DOMAIN|error" | tail -10)
    if [ -n "$TRAEFIK_LOGS" ]; then
        echo "$TRAEFIK_LOGS" | sed 's/^/   /'
    else
        print_info "No se encontraron logs relevantes"
    fi
fi

echo ""
echo "==========================================="
echo "📋 Resumen"
echo "==========================================="
echo ""
print_success "Configuración completada"
echo ""
echo "Servicio: $DASHBOARD_SERVICE"
echo "Dominio: $DOMAIN"
echo "Router: $ROUTER_NAME"
echo ""
print_info "Espera 1-2 minutos y prueba acceder a:"
echo "  https://$DOMAIN"
echo ""
print_info "Si aún no funciona, verifica:"
echo "  1. Que el DNS apunte correctamente a tu servidor"
echo "  2. Los logs de Traefik: docker service logs $TRAEFIK_SERVICE --tail 50"
echo "  3. Que el servicio dashboard esté corriendo: docker service ps $DASHBOARD_SERVICE"
echo ""
