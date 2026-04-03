#!/bin/bash
# Script maestro para el servidor
# Contiene todos los scripts necesarios para WhatsApp post-deploy
# Copiar este archivo al servidor y ejecutar las funciones necesarias

# ============================================
# CONFIGURACIÓN
# ============================================
SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"
ROUTER_NAME="whatsapp-main"

# ============================================
# FUNCIÓN: Verificación rápida
# ============================================
estado_rapido() {
    echo "🔍 Verificación rápida: WhatsApp"
    echo ""
    
    # Verificar servicio
    if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
        echo "✅ Servicio: OK"
    else
        echo "❌ Servicio: NO encontrado"
        return 1
    fi
    
    # Verificar red
    NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    # También verificar en las redes actuales del servicio
    CURRENT_NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.TaskTemplate.Networks}}{{$v.Target}} {{end}}' 2>/dev/null)
    if echo "$NETWORKS" | grep -q "easypanel" || echo "$CURRENT_NETWORKS" | grep -q "easypanel"; then
        echo "✅ Red easypanel: OK"
    else
        echo "❌ Red easypanel: FALTA"
    fi
    
    # Verificar etiquetas Traefik
    CURRENT_LABELS=$(docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s\n" $k}}{{end}}' 2>/dev/null)
    if echo "$CURRENT_LABELS" | grep -q "traefik.enable"; then
        echo "✅ Etiquetas Traefik: OK"
    else
        echo "❌ Etiquetas Traefik: FALTAN"
    fi
    
    # Verificar endpoint
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://${DOMAIN}/api/health" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Endpoint accesible: OK"
    else
        echo "⚠️  Endpoint: HTTP $HTTP_CODE"
    fi
    
    echo ""
    echo "🌐 Prueba: https://${DOMAIN}/qr"
}

# ============================================
# FUNCIÓN: Reaplicar Traefik (inteligente)
# ============================================
reaplicar_traefik() {
    echo "=========================================="
    echo "🔍 VERIFICAR Y REAPLICAR TRAEFIK"
    echo "=========================================="
    echo ""
    
    # Verificar si el servicio existe
    if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
        echo "❌ Servicio $SERVICE_NAME no encontrado"
        echo ""
        echo "Servicios disponibles:"
        docker service ls --format "{{.Name}}" | grep -i whatsapp || echo "   (ninguno encontrado)"
        return 1
    fi
    
    echo "✅ Servicio encontrado: $SERVICE_NAME"
    echo ""
    
    # Obtener todas las etiquetas actuales
    echo "📋 Verificando etiquetas Traefik existentes..."
    CURRENT_LABELS=$(docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>/dev/null)
    
    # Verificar cada etiqueta necesaria
    NEEDS_UPDATE=false
    
    # Etiquetas requeridas
    REQUIRED_LABELS=(
        "traefik.enable=true"
        "traefik.http.routers.${ROUTER_NAME}.rule=Host(\`${DOMAIN}\`)"
        "traefik.http.routers.${ROUTER_NAME}.entrypoints=websecure"
        "traefik.http.routers.${ROUTER_NAME}.tls=true"
        "traefik.http.routers.${ROUTER_NAME}.tls.certresolver=letsencrypt"
        "traefik.http.services.${ROUTER_NAME}.loadbalancer.server.port=${PORT}"
    )
    
    echo "🔍 Verificando etiquetas requeridas..."
    for label in "${REQUIRED_LABELS[@]}"; do
        label_key=$(echo "$label" | cut -d'=' -f1)
        label_value=$(echo "$label" | cut -d'=' -f2-)
        
        if echo "$CURRENT_LABELS" | grep -q "^${label_key}="; then
            current_value=$(echo "$CURRENT_LABELS" | grep "^${label_key}=" | cut -d'=' -f2-)
            if [ "$current_value" != "$label_value" ]; then
                echo "   ⚠️  Etiqueta incorrecta: $label_key"
                NEEDS_UPDATE=true
            else
                echo "   ✅ $label_key"
            fi
        else
            echo "   ❌ Falta: $label_key"
            NEEDS_UPDATE=true
        fi
    done
    
    echo ""
    
    # Verificar red easypanel
    echo "🌐 Verificando red easypanel..."
    NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ➕ Agregando a red easypanel..."
        docker service update --network-add easypanel $SERVICE_NAME
        sleep 3
        echo "   ✅ Agregado a red easypanel"
        NEEDS_UPDATE=true
    else
        echo "   ✅ Ya está en red easypanel"
    fi
    echo ""
    
    # Si no necesita actualización, salir
    if [ "$NEEDS_UPDATE" = false ]; then
        echo "=========================================="
        echo "✅ TODAS LAS ETIQUETAS ESTÁN CORRECTAS"
        echo "=========================================="
        echo ""
        echo "No se requiere ninguna acción."
        echo ""
        return 0
    fi
    
    # Si necesita actualización, aplicar las etiquetas
    echo "=========================================="
    echo "🔧 APLICANDO ETIQUETAS FALTANTES"
    echo "=========================================="
    echo ""
    
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.rule=Host(\`${DOMAIN}\`)" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.entrypoints=websecure" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.tls=true" \
      --label-add "traefik.http.routers.${ROUTER_NAME}.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.${ROUTER_NAME}.loadbalancer.server.port=${PORT}" \
      $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true
    
    echo ""
    echo "✅ Etiquetas aplicadas"
    echo ""
    
    # Verificar nuevamente
    echo "🔍 Verificando etiquetas después de la actualización..."
    echo "=========================================="
    docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep traefik
    echo ""
    
    # Esperar un momento para que Traefik detecte los cambios
    echo "⏳ Esperando 10 segundos para que Traefik detecte los cambios..."
    sleep 10
    
    echo ""
    echo "=========================================="
    echo "✅ PROCESO COMPLETADO"
    echo "=========================================="
    echo ""
    echo "🌐 Prueba acceder a:"
    echo "   https://${DOMAIN}/qr"
    echo "   https://${DOMAIN}/api/qr"
    echo "   https://${DOMAIN}/status"
    echo ""
}

# ============================================
# FUNCIÓN: Post-deploy completo
# ============================================
post_deploy() {
    echo "=========================================="
    echo "🚀 POST-DEPLOY: WHATSAPP"
    echo "=========================================="
    echo ""
    reaplicar_traefik
    echo ""
    echo "📋 Verificación rápida final..."
    echo ""
    estado_rapido
}

# ============================================
# FUNCIÓN: Ver logs
# ============================================
ver_logs() {
    echo "=========================================="
    echo "📋 LOGS DEL SERVICIO WHATSAPP"
    echo "=========================================="
    echo ""
    
    if [ "$2" = "live" ] || [ "$2" = "follow" ] || [ "$2" = "-f" ]; then
        echo "📺 Modo tiempo real (Ctrl+C para salir)"
        echo ""
        docker service logs -f $SERVICE_NAME
    else
        echo "🔍 Últimas 50 líneas:"
        echo "=========================================="
        docker service logs $SERVICE_NAME --tail 50 --no-trunc 2>&1
        echo ""
        echo "💡 Para ver logs en tiempo real: $0 logs live"
    fi
}

# ============================================
# FUNCIÓN: Diagnosticar problema de vinculación
# ============================================
diagnosticar() {
    echo "=========================================="
    echo "🔍 DIAGNÓSTICO: PROBLEMA DE VINCULACIÓN"
    echo "=========================================="
    echo ""
    
    # Ver logs recientes
    echo "📋 Últimas 100 líneas de logs:"
    echo "=========================================="
    docker service logs $SERVICE_NAME --tail 100 --no-trunc 2>&1 | tail -100
    echo ""
    
    # Buscar errores específicos
    echo "🔍 Buscando errores específicos..."
    echo "=========================================="
    
    echo "📌 Error 428 (Connection Terminated):"
    ERROR_428=$(docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -i "428\|Connection Terminated" | tail -3)
    if [ -n "$ERROR_428" ]; then
        echo "$ERROR_428"
        echo "   ⚠️  Error 428 es común durante autenticación"
    else
        echo "   ✅ No se encontraron errores 428 recientes"
    fi
    echo ""
    
    echo "📌 Errores de autenticación:"
    ERROR_AUTH=$(docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -iE "auth.*fail|device.*removed|conflict" | tail -3)
    if [ -n "$ERROR_AUTH" ]; then
        echo "$ERROR_AUTH"
    else
        echo "   ✅ No se encontraron errores de autenticación"
    fi
    echo ""
    
    echo "📌 Mensajes sobre QR:"
    QR_MESSAGES=$(docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -iE "qr|escaneado|scan" | tail -5)
    if [ -n "$QR_MESSAGES" ]; then
        echo "$QR_MESSAGES"
    else
        echo "   ⚠️  No se encontraron mensajes sobre QR"
    fi
    echo ""
    
    # Verificar estado actual
    echo "📊 Estado de conexión actual:"
    STATUS_RESPONSE=$(curl -s --max-time 5 "https://${DOMAIN}/api/status" 2>/dev/null)
    if echo "$STATUS_RESPONSE" | grep -q "connected"; then
        echo "   ✅ WhatsApp está conectado"
    elif echo "$STATUS_RESPONSE" | grep -q "waiting_scan"; then
        echo "   ⏳ Esperando escaneo de QR"
    else
        echo "   Estado: $(echo "$STATUS_RESPONSE" | head -c 100)"
    fi
    echo ""
    
    echo "💡 Si el problema persiste:"
    echo "   1. Limpia la sesión: $0 limpiar"
    echo "   2. Espera 2-3 minutos después de escanear el QR"
    echo "   3. Escanea el QR inmediatamente después de generarse"
}

# ============================================
# FUNCIÓN: Limpiar sesión
# ============================================
limpiar_sesion() {
    echo "=========================================="
    echo "🧹 LIMPIAR SESIÓN WHATSAPP"
    echo "=========================================="
    echo ""
    
    # Encontrar el contenedor
    CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)
    
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ No se encontró el contenedor del servicio"
        echo ""
        echo "💡 Ejecuta manualmente:"
        echo "   docker service update --force $SERVICE_NAME"
        return 1
    fi
    
    echo "✅ Contenedor encontrado: $CONTAINER_ID"
    echo ""
    
    # Limpiar archivos de autenticación
    AUTH_DIR="/app/auth_info_baileys_1"
    echo "🗑️  Eliminando archivos de autenticación..."
    docker exec $CONTAINER_ID rm -rf $AUTH_DIR 2>/dev/null
    echo "   ✅ Archivos eliminados"
    
    echo ""
    echo "🔄 Forzando reinicio del servicio..."
    docker service update --force $SERVICE_NAME
    
    echo ""
    echo "✅ Proceso completado"
    echo ""
    echo "⏳ Espera 30-60 segundos para que se genere un nuevo QR"
    echo "🌐 Luego accede a: https://${DOMAIN}/qr"
    echo ""
    echo "💡 IMPORTANTE: Escanea el QR inmediatamente después de generarse (dentro de 2 minutos)"
}

# ============================================
# MENÚ PRINCIPAL
# ============================================
if [ "$1" = "rapido" ] || [ "$1" = "estado" ]; then
    estado_rapido
elif [ "$1" = "traefik" ] || [ "$1" = "reaplicar" ]; then
    reaplicar_traefik
elif [ "$1" = "deploy" ] || [ "$1" = "post-deploy" ] || [ -z "$1" ]; then
    post_deploy
elif [ "$1" = "logs" ] || [ "$1" = "log" ]; then
    ver_logs "$@"
elif [ "$1" = "diagnosticar" ] || [ "$1" = "diagnostico" ] || [ "$1" = "diagnose" ]; then
    diagnosticar
elif [ "$1" = "limpiar" ] || [ "$1" = "clean" ] || [ "$1" = "reset" ]; then
    limpiar_sesion
else
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  rapido, estado      - Verificación rápida del estado"
    echo "  traefik, reaplicar  - Reaplicar etiquetas Traefik (inteligente)"
    echo "  deploy, post-deploy  - Post-deploy completo (por defecto)"
    echo "  logs [live]         - Ver logs (agregar 'live' para tiempo real)"
    echo "  diagnosticar        - Diagnosticar problemas de vinculación"
    echo "  limpiar             - Limpiar sesión y forzar nuevo QR"
    echo ""
    echo "Ejemplos:"
    echo "  $0                  # Post-deploy completo"
    echo "  $0 rapido           # Verificación rápida"
    echo "  $0 traefik          # Solo reaplicar Traefik"
    echo "  $0 logs             # Ver últimas 50 líneas de logs"
    echo "  $0 logs live        # Ver logs en tiempo real"
    echo "  $0 diagnosticar     # Diagnosticar problema de vinculación"
    echo "  $0 limpiar          # Limpiar sesión y generar nuevo QR"
fi
