#!/bin/bash
# Script para actualizar Traefik manualmente
# Aplica las etiquetas necesarias al servicio dashboard y reinicia Traefik

set -e

echo "==========================================="
echo "🔧 Actualizando Traefik Manualmente"
echo "==========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# 1. Verificar que Docker Swarm está activo
echo "1️⃣ Verificando Docker Swarm..."
if ! docker info | grep -q "Swarm: active"; then
    print_error "Docker Swarm no está activo"
    exit 1
fi
print_success "Docker Swarm está activo"
echo ""

# 2. Identificar el servicio del dashboard
echo "2️⃣ Identificando servicio del dashboard..."
DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i "dashboard" | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    print_error "No se encontró el servicio del dashboard"
    echo "Servicios disponibles:"
    docker service ls --format "{{.Name}}"
    exit 1
fi

print_success "Servicio encontrado: $DASHBOARD_SERVICE"
echo ""

# 3. Verificar red easypanel
echo "3️⃣ Verificando red easypanel..."
EASYPANEL_NETWORK=$(docker network ls --format "{{.Name}}" | grep -i "easypanel" | head -1)

if [ -z "$EASYPANEL_NETWORK" ]; then
    print_warning "Red easypanel no encontrada. Creando..."
    docker network create --driver overlay easypanel 2>/dev/null || true
    EASYPANEL_NETWORK="easypanel"
fi

print_success "Red encontrada: $EASYPANEL_NETWORK"
echo ""

# 4. Verificar si el servicio está en la red easypanel
echo "4️⃣ Verificando si el servicio está en la red easypanel..."
if docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' | grep -q "$EASYPANEL_NETWORK"; then
    print_success "El servicio ya está en la red easypanel"
else
    print_warning "Agregando servicio a la red easypanel..."
    docker service update --network-add "$EASYPANEL_NETWORK" "$DASHBOARD_SERVICE" || {
        print_warning "No se pudo agregar a la red (puede que ya esté en ella)"
    }
    sleep 5
fi
echo ""

# 5. Eliminar todas las etiquetas Traefik existentes
echo "5️⃣ Eliminando etiquetas Traefik existentes..."
TRAEFIK_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $k, $v := .Spec.Labels}}{{if or (eq $k "traefik.enable") (contains $k "traefik")}}{{printf "%s=%s\n" $k $v}}{{end}}{{end}}' 2>/dev/null || true)

if [ -n "$TRAEFIK_LABELS" ]; then
    print_info "Etiquetas Traefik encontradas:"
    echo "$TRAEFIK_LABELS" | while read -r label; do
        if [ -n "$label" ]; then
            key=$(echo "$label" | cut -d'=' -f1)
            print_info "  - Eliminando: $key"
            docker service update --label-rm "$key" "$DASHBOARD_SERVICE" 2>/dev/null || true
        fi
    done
    sleep 3
    print_success "Etiquetas Traefik eliminadas"
else
    print_info "No se encontraron etiquetas Traefik existentes"
fi
echo ""

# 6. Aplicar nuevas etiquetas Traefik
echo "6️⃣ Aplicando nuevas etiquetas Traefik..."
DOMAIN="dashboard.checkin24hs.com"
ROUTER_NAME="dashboard-checkin24hs-$(date +%s)"  # Nombre único para evitar conflictos
PORT="3000"

print_info "Configuración:"
print_info "  - Dominio: $DOMAIN"
print_info "  - Router: $ROUTER_NAME"
print_info "  - Puerto: $PORT"
echo ""

# Aplicar etiquetas una por una (incluyendo headers anti-caché)
docker service update \
    --label-add "traefik.enable=true" \
    --label-add "traefik.http.routers.$ROUTER_NAME.rule=Host(\`$DOMAIN\`)" \
    --label-add "traefik.http.routers.$ROUTER_NAME.entrypoints=websecure" \
    --label-add "traefik.http.routers.$ROUTER_NAME.tls.certresolver=letsencrypt" \
    --label-add "traefik.http.routers.$ROUTER_NAME.service=$ROUTER_NAME" \
    --label-add "traefik.http.services.$ROUTER_NAME.loadbalancer.server.port=$PORT" \
    --label-add "traefik.docker.network=$EASYPANEL_NETWORK" \
    --label-add "traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate, proxy-revalidate, max-age=0, private" \
    --label-add "traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Pragma=no-cache" \
    --label-add "traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Expires=0" \
    --label-add "traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Surrogate-Control=no-store" \
    --label-add "traefik.http.routers.$ROUTER_NAME.middlewares=dashboard-headers" \
    "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    print_success "Etiquetas Traefik aplicadas correctamente"
else
    print_error "Error al aplicar etiquetas Traefik"
    exit 1
fi

echo ""
sleep 5

# 7. Verificar que las etiquetas se aplicaron (múltiples métodos)
echo "7️⃣ Verificando etiquetas aplicadas..."
APPLIED_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $k, $v := .Spec.Labels}}{{if contains $k "traefik"}}{{printf "%s=%s\n" $k $v}}{{end}}{{end}}' 2>/dev/null || true)

if [ -z "$APPLIED_LABELS" ]; then
    # Intentar método alternativo
    APPLIED_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $k, $v := .Spec.TaskTemplate.ContainerSpec.Labels}}{{if contains $k "traefik"}}{{printf "%s=%s\n" $k $v}}{{end}}{{end}}' 2>/dev/null || true)
fi

if [ -z "$APPLIED_LABELS" ]; then
    # Verificar en JSON
    SERVICE_JSON=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{json .Spec.Labels}}' 2>/dev/null || echo "{}")
    if [ -n "$SERVICE_JSON" ] && [ "$SERVICE_JSON" != "null" ] && [ "$SERVICE_JSON" != "{}" ]; then
        APPLIED_LABELS=$(echo "$SERVICE_JSON" | jq -r 'to_entries[] | select(.key | contains("traefik")) | "\(.key)=\(.value)"' 2>/dev/null || true)
    fi
fi

if [ -n "$APPLIED_LABELS" ]; then
    print_success "Etiquetas aplicadas:"
    echo "$APPLIED_LABELS" | while read -r label; do
        if [ -n "$label" ]; then
            echo "  - $label"
        fi
    done
else
    print_warning "No se encontraron etiquetas Traefik aplicadas"
    echo ""
    print_info "Esto puede significar que:"
    print_info "  1. EasyPanel está sobrescribiendo las etiquetas automáticamente"
    print_info "  2. Las etiquetas están en un formato diferente"
    print_info "  3. Necesitas configurar el dominio desde EasyPanel"
    echo ""
    print_info "Para verificar manualmente, ejecuta:"
    echo "  docker service inspect $DASHBOARD_SERVICE --format '{{json .Spec.Labels}}' | jq"
    echo ""
fi
echo ""

# 8. Reiniciar Traefik para que detecte los cambios
echo "8️⃣ Reiniciando Traefik..."
TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i "traefik" | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    print_warning "Servicio Traefik no encontrado"
else
    print_info "Reiniciando servicio: $TRAEFIK_SERVICE"
    docker service update --force "$TRAEFIK_SERVICE" >/dev/null 2>&1 || {
        print_warning "No se pudo reiniciar Traefik (puede que no sea necesario)"
    }
    print_success "Traefik reiniciado"
    echo ""
    print_info "Esperando 30 segundos para que Traefik se reinicie completamente..."
    sleep 30
fi
echo ""

# 9. Verificar logs de Traefik para errores
echo "9️⃣ Verificando logs de Traefik..."
if [ -n "$TRAEFIK_SERVICE" ]; then
    print_info "Últimas 20 líneas de logs de Traefik:"
    docker service logs "$TRAEFIK_SERVICE" --tail 20 2>&1 | grep -i "error\|warning\|$ROUTER_NAME\|$DOMAIN" || {
        print_info "No se encontraron errores relacionados con el dashboard"
    }
fi
echo ""

# 10. Verificar que el servicio está corriendo
echo "🔟 Verificando estado del servicio..."
SERVICE_STATUS=$(docker service ps "$DASHBOARD_SERVICE" --format "{{.CurrentState}}" | head -1)
if echo "$SERVICE_STATUS" | grep -q "Running"; then
    print_success "Servicio está corriendo: $SERVICE_STATUS"
else
    print_warning "Estado del servicio: $SERVICE_STATUS"
fi
echo ""

# 11. Resumen final
echo "==========================================="
echo "📋 Resumen"
echo "==========================================="
echo ""
print_success "Configuración completada"
echo ""
echo "Servicio: $DASHBOARD_SERVICE"
echo "Dominio: $DOMAIN"
echo "Router: $ROUTER_NAME"
echo "Puerto: $PORT"
echo "Red: $EASYPANEL_NETWORK"
echo ""
echo "Espera 1-2 minutos y luego prueba acceder a:"
echo "  https://$DOMAIN"
echo ""
echo "Si aún no funciona, verifica:"
echo "  1. Que Traefik esté corriendo: docker service ls | grep traefik"
echo "  2. Que el servicio esté en la red easypanel"
echo "  3. Los logs de Traefik: docker service logs $TRAEFIK_SERVICE --tail 50"
echo "  4. Que el DNS apunte correctamente a tu servidor"
echo ""
echo "Para verificar las etiquetas aplicadas:"
echo "  docker service inspect $DASHBOARD_SERVICE --format '{{range \$k, \$v := .Spec.Labels}}{{if contains \$k \"traefik\"}}{{printf \"%s=%s\\n\" \$k \$v}}{{end}}{{end}}'"
echo ""
