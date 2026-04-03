#!/bin/bash
# Script para reiniciar Traefik y verificar que todo funcione correctamente

echo "=========================================="
echo "🔄 Reiniciando Traefik y verificando"
echo "=========================================="
echo ""

# 1. Verificar estado actual de Traefik
echo "1️⃣ Verificando estado actual de Traefik..."
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $1}')

if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró el servicio Traefik"
    exit 1
fi

echo "✅ Servicio Traefik encontrado: $TRAEFIK_SERVICE"
echo ""

# 2. Verificar estado del dashboard antes del reinicio
echo "2️⃣ Verificando estado del dashboard antes del reinicio..."
DASHBOARD_SERVICE=$(docker service ls | grep "checkin24hs_dashboard" | awk '{print $1}')

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "⚠️ No se encontró el servicio dashboard"
else
    echo "✅ Servicio dashboard encontrado: $DASHBOARD_SERVICE"
    
    # Obtener contenedor del dashboard
    DASHBOARD_CONTAINER=$(docker ps --format "{{.Names}}" | grep "checkin24hs_dashboard" | head -1)
    
    if [ ! -z "$DASHBOARD_CONTAINER" ]; then
        echo "✅ Contenedor dashboard encontrado: $DASHBOARD_CONTAINER"
        
        # Verificar que el servidor responde directamente
        echo "   Probando acceso directo al servidor..."
        STATUS=$(docker exec "$DASHBOARD_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null)
        if [ "$STATUS" = "200" ]; then
            echo "   ✅ El servidor responde correctamente (200)"
        else
            echo "   ⚠️ El servidor responde con código: $STATUS"
        fi
    fi
fi

echo ""

# 3. Verificar etiquetas Traefik del dashboard
echo "3️⃣ Verificando etiquetas Traefik del dashboard..."
if [ ! -z "$DASHBOARD_SERVICE" ]; then
    echo "   Etiquetas actuales:"
    docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Spec.Labels}}{{printf "%s=%s\n" .}}{{end}}' | grep -i traefik || echo "   ⚠️ No se encontraron etiquetas Traefik"
fi

echo ""

# 4. Reiniciar Traefik
echo "4️⃣ Reiniciando Traefik..."
docker service update --force "$TRAEFIK_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Comando de reinicio enviado correctamente"
else
    echo "❌ Error al reiniciar Traefik"
    exit 1
fi

echo ""
echo "⏳ Esperando 30 segundos para que Traefik se reinicie completamente..."
sleep 30

# 5. Verificar que Traefik se reinició correctamente
echo ""
echo "5️⃣ Verificando que Traefik se reinició correctamente..."
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep traefik | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "⚠️ No se encontró contenedor de Traefik después del reinicio"
else
    echo "✅ Contenedor Traefik encontrado: $TRAEFIK_CONTAINER"
    
    # Verificar logs recientes
    echo ""
    echo "   Últimas 10 líneas de logs de Traefik:"
    docker logs "$TRAEFIK_CONTAINER" --tail 10 2>&1 | grep -E "(error|Error|ERROR|warn|Warn|WARN|Starting|Started)" || echo "   (Sin errores o advertencias recientes)"
fi

echo ""

# 6. Verificar logs de Traefik para errores
echo "6️⃣ Verificando logs de Traefik para errores..."
docker service logs "$TRAEFIK_SERVICE" --tail 20 2>&1 | grep -iE "(error|404|not found|cannot be linked)" || echo "   ✅ No se encontraron errores recientes"

echo ""

# 7. Verificar acceso al dashboard a través de Traefik
echo "7️⃣ Verificando acceso al dashboard a través de Traefik..."
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    # Intentar acceder al dashboard a través de Traefik (desde dentro del contenedor)
    echo "   Probando acceso desde dentro del contenedor Traefik..."
    
    # Obtener IP del contenedor dashboard
    if [ ! -z "$DASHBOARD_CONTAINER" ]; then
        DASHBOARD_IP=$(docker inspect "$DASHBOARD_CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
        
        if [ ! -z "$DASHBOARD_IP" ]; then
            echo "   IP del dashboard: $DASHBOARD_IP"
            echo "   Probando acceso directo a la IP..."
            STATUS=$(docker exec "$TRAEFIK_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://$DASHBOARD_IP:3000/ 2>/dev/null)
            if [ "$STATUS" = "200" ]; then
                echo "   ✅ Traefik puede acceder al dashboard (200)"
            else
                echo "   ⚠️ Traefik no puede acceder al dashboard (código: $STATUS)"
            fi
        fi
    fi
fi

echo ""

# 8. Verificar configuración de red
echo "8️⃣ Verificando configuración de red..."
if [ ! -z "$DASHBOARD_SERVICE" ] && [ ! -z "$TRAEFIK_SERVICE" ]; then
    echo "   Verificando si ambos servicios están en la misma red..."
    
    DASHBOARD_NETWORKS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>/dev/null)
    TRAEFIK_NETWORKS=$(docker service inspect "$TRAEFIK_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>/dev/null)
    
    echo "   Redes del dashboard: $DASHBOARD_NETWORKS"
    echo "   Redes de Traefik: $TRAEFIK_NETWORKS"
    
    # Verificar si comparten alguna red
    SHARED_NETWORK=""
    for dash_net in $DASHBOARD_NETWORKS; do
        for traefik_net in $TRAEFIK_NETWORKS; do
            if [ "$dash_net" = "$traefik_net" ]; then
                SHARED_NETWORK="$dash_net"
                break
            fi
        done
        [ ! -z "$SHARED_NETWORK" ] && break
    done
    
    if [ ! -z "$SHARED_NETWORK" ]; then
        echo "   ✅ Ambos servicios están en la red compartida: $SHARED_NETWORK"
    else
        echo "   ⚠️ Los servicios NO están en la misma red"
        echo "   💡 Esto puede causar problemas de conectividad"
    fi
fi

echo ""

# 9. Resumen y recomendaciones
echo "=========================================="
echo "📋 Resumen"
echo "=========================================="
echo ""
echo "✅ Traefik reiniciado"
echo ""
echo "💡 Próximos pasos:"
echo ""
echo "1. Espera 1-2 minutos adicionales para que Traefik termine de reiniciarse"
echo ""
echo "2. Verifica el acceso al dashboard desde el navegador:"
echo "   https://dashboard.checkin24hs.com"
echo ""
echo "3. Si aún ves errores 404:"
echo "   a) Verifica las etiquetas Traefik del dashboard:"
echo "      docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.Labels}}{{printf \"%s=%s\\n\" .}}{{end}}' | grep traefik"
echo ""
echo "   b) Verifica los logs de Traefik:"
echo "      docker service logs $TRAEFIK_SERVICE --tail 50"
echo ""
echo "   c) Verifica que el dashboard esté en la red 'easypanel':"
echo "      docker service inspect $DASHBOARD_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'"
echo ""
echo "4. Si el problema persiste, ejecuta:"
echo "   curl -O https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/CORREGIR_TRAEFIK_404_DEFINITIVO.sh"
echo "   chmod +x CORREGIR_TRAEFIK_404_DEFINITIVO.sh"
echo "   ./CORREGIR_TRAEFIK_404_DEFINITIVO.sh"
echo ""
