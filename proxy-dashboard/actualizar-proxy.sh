#!/bin/bash
# Script para actualizar la configuración del proxy cuando cambia el contenedor del dashboard
# Este script se ejecuta en el servidor host, NO dentro del contenedor

set -e

PROXY_CONTAINER="dashboard-proxy"
PROXY_CONFIG_FILE="/proxy-dashboard/nginx.conf"
PROXY_SERVICE="dashboard-proxy"

# Obtener el nombre del contenedor activo del dashboard
get_dashboard_container() {
    docker ps --format "{{.Names}}" --filter "name=checkin24hs_dashboard" | head -1
}

# Actualizar la configuración de nginx del proxy
update_proxy_config() {
    CONTAINER_NAME=$(get_dashboard_container)
    
    if [ -z "$CONTAINER_NAME" ]; then
        echo "⚠️  No se encontró contenedor activo del dashboard"
        return 1
    fi
    
    echo "✅ Contenedor activo encontrado: $CONTAINER_NAME"
    
    # Obtener el ID del contenedor del proxy
    PROXY_CONTAINER_ID=$(docker ps --filter "name=$PROXY_CONTAINER" --format "{{.ID}}" | head -1)
    
    if [ -z "$PROXY_CONTAINER_ID" ]; then
        echo "❌ No se encontró el contenedor del proxy"
        return 1
    fi
    
    echo "✅ Contenedor del proxy encontrado: $PROXY_CONTAINER_ID"
    
    # Copiar la configuración actualizada al contenedor
    # Actualizar la línea que contiene $backend_upstream
    docker exec $PROXY_CONTAINER_ID sed -i "s/set \$backend_upstream.*$/set \$backend_upstream $CONTAINER_NAME;/" /etc/nginx/conf.d/default.conf
    
    # Verificar la configuración
    if docker exec $PROXY_CONTAINER_ID nginx -t > /dev/null 2>&1; then
        # Recargar nginx
        docker exec $PROXY_CONTAINER_ID nginx -s reload
        echo "✅ Configuración del proxy actualizada y recargada"
        return 0
    else
        echo "❌ Error en la configuración de nginx"
        return 1
    fi
}

# Ejecutar actualización
update_proxy_config
