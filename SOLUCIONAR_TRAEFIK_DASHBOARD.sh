#!/bin/bash
# =====================================================
# SOLUCIONAR CONFIGURACIÓN DE TRAEFIK PARA DASHBOARD
# =====================================================
# Este script muestra cómo configurar Traefik
# para el servicio dashboard
# =====================================================

echo "=========================================="
echo "🔧 SOLUCIONAR CONFIGURACIÓN DE TRAEFIK"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"
TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)
TRAEFIK_NETWORK=$(docker service inspect "${TRAEFIK_SERVICE}" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}' 2>/dev/null | head -1)

echo "📋 Información actual:"
echo "   - Servicio Dashboard: ${SERVICE_NAME}"
echo "   - Servicio Traefik: ${TRAEFIK_SERVICE}"
echo "   - Red de Traefik: ${TRAEFIK_NETWORK}"
echo ""

# Obtener nombre de la red de Traefik
if [ ! -z "${TRAEFIK_NETWORK}" ]; then
    TRAEFIK_NETWORK_NAME=$(docker network inspect "${TRAEFIK_NETWORK}" --format '{{.Name}}' 2>/dev/null || echo "${TRAEFIK_NETWORK}")
    echo "   - Nombre de red de Traefik: ${TRAEFIK_NETWORK_NAME}"
fi

echo ""

echo "=========================================="
echo "⚠️  PROBLEMAS DETECTADOS"
echo "=========================================="
echo ""
echo "1. ❌ No hay labels de Traefik en el servicio dashboard"
echo "2. ⚠️  Los servicios están en redes diferentes"
echo ""
echo "Esto causa el error 404 porque Traefik no puede enrutar las peticiones."
echo ""

echo "=========================================="
echo "✅ SOLUCIÓN: CONFIGURAR EN EASYPANEL"
echo "=========================================="
echo ""
echo "Sigue estos pasos en EasyPanel:"
echo ""
echo "1. Ve a EasyPanel → Servicio 'checkin24hs_dashboard'"
echo ""
echo "2. Busca la sección 'Labels' o 'Etiquetas' o 'Environment'"
echo ""
echo "3. Agrega las siguientes labels (ajusta el dominio):"
echo ""
echo "   traefik.enable=true"
echo "   traefik.http.routers.dashboard.rule=Host(\"tu-dominio.com\")"
echo "   traefik.http.routers.dashboard.entrypoints=websecure"
echo "   traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
echo "   traefik.http.services.dashboard.loadbalancer.server.port=3000"
echo ""
echo "   ⚠️  IMPORTANTE: Reemplaza 'tu-dominio.com' con tu dominio real"
echo "      Por ejemplo: 'dashboard.checkin24hs.com' o el dominio que uses"
echo ""
echo "4. Busca la sección 'Networks' o 'Redes'"
echo ""
if [ ! -z "${TRAEFIK_NETWORK_NAME}" ]; then
    echo "5. Asegúrate de que el servicio esté en la red: ${TRAEFIK_NETWORK_NAME}"
else
    echo "5. Asegúrate de que el servicio esté en la misma red que Traefik"
fi
echo ""
echo "6. Guarda y despliega los cambios"
echo ""
echo "7. Espera 30-60 segundos para que se apliquen los cambios"
echo ""

echo "=========================================="
echo "📝 EJEMPLO DE CONFIGURACIÓN"
echo "=========================================="
echo ""
echo "Si tu dominio es 'dashboard.checkin24hs.com', las labels serían:"
echo ""
echo "   traefik.enable=true"
echo "   traefik.http.routers.dashboard.rule=Host(\"dashboard.checkin24hs.com\")"
echo "   traefik.http.routers.dashboard.entrypoints=websecure"
echo "   traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
echo "   traefik.http.services.dashboard.loadbalancer.server.port=3000"
echo ""

echo "=========================================="
echo "🔍 VERIFICAR DESPUÉS DE CONFIGURAR"
echo "=========================================="
echo ""
echo "Después de configurar en EasyPanel, ejecuta:"
echo ""
echo "   curl -s -L \"https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/VERIFICAR_TRAEFIK_DASHBOARD.sh\" -o /tmp/VERIFICAR_TRAEFIK.sh"
echo "   chmod +x /tmp/VERIFICAR_TRAEFIK.sh"
echo "   /tmp/VERIFICAR_TRAEFIK.sh"
echo ""
echo "Deberías ver:"
echo "   ✅ Labels de Traefik: ✅ Configuradas"
echo "   ✅ Ambos servicios están en la misma red"
echo ""
