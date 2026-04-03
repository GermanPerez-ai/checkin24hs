#!/bin/bash
# =====================================================
# VERIFICAR CONFIGURACIÓN DE TRAEFIK PARA DASHBOARD
# =====================================================
# Este script verifica la configuración de Traefik
# para el servicio dashboard
# =====================================================

echo "=========================================="
echo "🔍 VERIFICANDO CONFIGURACIÓN DE TRAEFIK"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"

# Verificar servicio Traefik
echo "=========================================="
echo "1. SERVICIO TRAEFIK"
echo "=========================================="
echo ""

TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)

if [ -z "${TRAEFIK_SERVICE}" ]; then
    echo "❌ No se encontró servicio Traefik"
    exit 1
fi

echo "✅ Servicio Traefik: ${TRAEFIK_SERVICE}"
echo ""

# Verificar estado de Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "${TRAEFIK_CONTAINER}" ]; then
    echo "✅ Contenedor Traefik: ${TRAEFIK_CONTAINER}"
else
    echo "⚠️  No se encontró contenedor Traefik en ejecución"
fi

echo ""

# Verificar labels de Traefik en el servicio dashboard
echo "=========================================="
echo "2. LABELS DE TRAEFIK EN DASHBOARD"
echo "=========================================="
echo ""

ALL_LABELS=$(docker service inspect "${SERVICE_NAME}" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null)

if [ -z "${ALL_LABELS}" ]; then
    echo "❌ No se encontraron labels en el servicio"
else
    echo "📋 Todas las labels del servicio:"
    echo "${ALL_LABELS}" | sort
    
    echo ""
    echo "🔍 Labels relacionadas con Traefik:"
    TRAEFIK_LABELS=$(echo "${ALL_LABELS}" | grep -i traefik || echo "(ninguna)")
    
    if [ "${TRAEFIK_LABELS}" = "(ninguna)" ]; then
        echo "❌ NO se encontraron labels de Traefik"
        echo ""
        echo "⚠️  PROBLEMA DETECTADO:"
        echo "   El servicio dashboard NO tiene configuración de Traefik"
        echo "   Por eso Traefik no puede enrutar las peticiones al servicio"
        echo ""
        echo "✅ SOLUCIÓN:"
        echo "   1. Ve a EasyPanel → Servicio checkin24hs_dashboard"
        echo "   2. Busca la sección 'Labels' o 'Etiquetas'"
        echo "   3. Agrega las siguientes labels de Traefik:"
        echo ""
        echo "   traefik.enable=true"
        echo "   traefik.http.routers.dashboard.rule=Host(\"tu-dominio.com\")"
        echo "   traefik.http.routers.dashboard.entrypoints=websecure"
        echo "   traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
        echo "   traefik.http.services.dashboard.loadbalancer.server.port=3000"
        echo ""
        echo "   (Reemplaza 'tu-dominio.com' con tu dominio real)"
    else
        echo "${TRAEFIK_LABELS}"
    fi
fi

echo ""

# Verificar routers de Traefik
echo "=========================================="
echo "3. ROUTERS DE TRAEFIK"
echo "=========================================="
echo ""

if [ ! -z "${TRAEFIK_CONTAINER}" ]; then
    echo "🔍 Buscando routers configurados en Traefik..."
    
    # Intentar acceder a la API de Traefik
    TRAEFIK_API=$(docker inspect "${TRAEFIK_CONTAINER}" --format '{{range .Config.Labels}}{{if eq . "traefik.api"}}{{.}}{{end}}{{end}}' 2>/dev/null || echo "")
    
    if [ ! -z "${TRAEFIK_API}" ]; then
        echo "   API de Traefik disponible"
    else
        echo "   (No se pudo acceder a la API de Traefik)"
    fi
else
    echo "⚠️  No se puede verificar routers sin contenedor de Traefik"
fi

echo ""

# Verificar red de Traefik
echo "=========================================="
echo "4. RED DE TRAEFIK"
echo "=========================================="
echo ""

TRAEFIK_NETWORK=$(docker service inspect "${TRAEFIK_SERVICE}" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}' 2>/dev/null | head -1)
DASHBOARD_NETWORK=$(docker service inspect "${SERVICE_NAME}" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}' 2>/dev/null | head -1)

echo "📋 Red de Traefik: ${TRAEFIK_NETWORK:-(no encontrada)}"
echo "📋 Red de Dashboard: ${DASHBOARD_NETWORK:-(no encontrada)}"

if [ ! -z "${TRAEFIK_NETWORK}" ] && [ ! -z "${DASHBOARD_NETWORK}" ]; then
    if [ "${TRAEFIK_NETWORK}" = "${DASHBOARD_NETWORK}" ]; then
        echo "✅ Ambos servicios están en la misma red"
    else
        echo "⚠️  Los servicios están en redes diferentes"
        echo "   Esto puede causar problemas de conectividad"
    fi
fi

echo ""

# Resumen
echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📝 Resumen:"
echo "   - Traefik: $( [ ! -z "${TRAEFIK_SERVICE}" ] && echo "✅ Activo" || echo "❌ No encontrado" )"
echo "   - Labels de Traefik: $( [ ! -z "${TRAEFIK_LABELS}" ] && [ "${TRAEFIK_LABELS}" != "(ninguna)" ] && echo "✅ Configuradas" || echo "❌ NO configuradas" )"
echo ""
echo "💡 Si las labels de Traefik NO están configuradas,"
echo "   ese es el problema. Configúralas en EasyPanel."
echo ""
