#!/bin/bash
# Script para reiniciar Traefik manualmente

echo "==========================================="
echo "🔄 Reiniciando Traefik"
echo "==========================================="
echo ""

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

# 1. Buscar el servicio Traefik
echo "1️⃣ Buscando servicio Traefik..."
TRAEFIK_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i "traefik" | head -1)

if [ -z "$TRAEFIK_SERVICE" ]; then
    print_error "No se encontró servicio Traefik"
    echo ""
    echo "Servicios disponibles:"
    docker service ls
    exit 1
fi

print_success "Servicio encontrado: $TRAEFIK_SERVICE"
echo ""

# 2. Verificar estado actual
echo "2️⃣ Verificando estado actual..."
CURRENT_STATE=$(docker service ps "$TRAEFIK_SERVICE" --format "{{.CurrentState}}" | head -1)
print_info "Estado actual: $CURRENT_STATE"
echo ""

# 3. Reiniciar Traefik
echo "3️⃣ Reiniciando Traefik..."
print_info "Ejecutando: docker service update --force $TRAEFIK_SERVICE"

if docker service update --force "$TRAEFIK_SERVICE" >/dev/null 2>&1; then
    print_success "Comando de reinicio ejecutado correctamente"
else
    print_error "Error al ejecutar el comando de reinicio"
    exit 1
fi

echo ""

# 4. Esperar a que se reinicie
echo "4️⃣ Esperando 30 segundos para que Traefik se reinicie completamente..."
for i in {30..1}; do
    echo -ne "\r   Esperando... ${i}s  "
    sleep 1
done
echo -ne "\r   Esperando... 0s  \n"
echo ""

# 5. Verificar estado después del reinicio
echo "5️⃣ Verificando estado después del reinicio..."
NEW_STATE=$(docker service ps "$TRAEFIK_SERVICE" --format "{{.CurrentState}}" | head -1)
print_info "Estado nuevo: $NEW_STATE"

if echo "$NEW_STATE" | grep -qi "running"; then
    print_success "Traefik está corriendo"
else
    print_warning "Traefik puede estar aún reiniciando: $NEW_STATE"
fi

echo ""

# 6. Verificar logs recientes
echo "6️⃣ Verificando logs recientes (últimas 15 líneas)..."
docker service logs "$TRAEFIK_SERVICE" --tail 15 2>&1 | tail -10 | sed 's/^/   /'
echo ""

# 7. Resumen
echo "==========================================="
echo "📋 Resumen"
echo "==========================================="
echo ""
print_success "Traefik reiniciado"
echo ""
echo "Servicio: $TRAEFIK_SERVICE"
echo "Estado: $NEW_STATE"
echo ""
print_info "Espera 1-2 minutos adicionales para que Traefik detecte todos los cambios"
echo ""
print_info "Para ver los logs en tiempo real:"
echo "  docker service logs -f $TRAEFIK_SERVICE"
echo ""
print_info "Para verificar que no hay errores:"
echo "  docker service logs $TRAEFIK_SERVICE --tail 50 | grep -i error"
echo ""
