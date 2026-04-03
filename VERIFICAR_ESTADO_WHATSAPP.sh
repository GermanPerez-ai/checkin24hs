#!/bin/bash
# Verificar estado completo del servicio WhatsApp
# Diagnóstico completo: servicio, Traefik, endpoints, conexión

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO: WHATSAPP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"
ROUTER_NAME="whatsapp-main"

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir estado
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ===== 1. VERIFICAR SERVICIO DOCKER =====
echo "1️⃣  VERIFICANDO SERVICIO DOCKER"
echo "=========================================="

if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    print_status 0 "Servicio encontrado: $SERVICE_NAME"
    
    # Estado del servicio
    SERVICE_STATUS=$(docker service ps $SERVICE_NAME --format "{{.CurrentState}}" --no-trunc | head -1)
    echo "   Estado: $SERVICE_STATUS"
    
    # Réplicas
    REPLICAS=$(docker service ls --format "{{.Replicas}}" | grep "$SERVICE_NAME" | head -1)
    echo "   Réplicas: $REPLICAS"
    
    # Puerto
    PUBLISHED_PORT=$(docker service inspect $SERVICE_NAME --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
    if [ -n "$PUBLISHED_PORT" ] && [ "$PUBLISHED_PORT" != "0" ]; then
        echo "   Puerto publicado: $PUBLISHED_PORT"
    else
        echo "   Puerto publicado: (ninguno - solo interno)"
    fi
else
    print_status 1 "Servicio NO encontrado: $SERVICE_NAME"
    echo ""
    echo "Servicios disponibles:"
    docker service ls --format "{{.Name}}" | grep -i whatsapp || echo "   (ninguno encontrado)"
    exit 1
fi
echo ""

# ===== 2. VERIFICAR RED EASYPANEL =====
echo "2️⃣  VERIFICANDO RED EASYPANEL"
echo "=========================================="

NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    print_status 0 "Servicio está en red easypanel"
    echo "   Redes: $(echo "$NETWORKS" | tr '\n' ' ')"
else
    print_status 1 "Servicio NO está en red easypanel"
    print_warning "Ejecuta: docker service update --network-add easypanel $SERVICE_NAME"
fi
echo ""

# ===== 3. VERIFICAR ETIQUETAS TRAEFIK =====
echo "3️⃣  VERIFICANDO ETIQUETAS TRAEFIK"
echo "=========================================="

CURRENT_LABELS=$(docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>/dev/null)

REQUIRED_LABELS=(
    "traefik.enable=true"
    "traefik.http.routers.${ROUTER_NAME}.rule=Host(\`${DOMAIN}\`)"
    "traefik.http.routers.${ROUTER_NAME}.entrypoints=websecure"
    "traefik.http.routers.${ROUTER_NAME}.tls=true"
    "traefik.http.routers.${ROUTER_NAME}.tls.certresolver=letsencrypt"
    "traefik.http.services.${ROUTER_NAME}.loadbalancer.server.port=${PORT}"
)

ALL_LABELS_OK=true
for label in "${REQUIRED_LABELS[@]}"; do
    label_key=$(echo "$label" | cut -d'=' -f1)
    label_value=$(echo "$label" | cut -d'=' -f2-)
    
    if echo "$CURRENT_LABELS" | grep -q "^${label_key}="; then
        current_value=$(echo "$CURRENT_LABELS" | grep "^${label_key}=" | cut -d'=' -f2-)
        if [ "$current_value" = "$label_value" ]; then
            echo "   ✅ $label_key"
        else
            echo "   ⚠️  $label_key (valor incorrecto)"
            echo "      Actual: $current_value"
            echo "      Esperado: $label_value"
            ALL_LABELS_OK=false
        fi
    else
        echo "   ❌ Falta: $label_key"
        ALL_LABELS_OK=false
    fi
done

if [ "$ALL_LABELS_OK" = true ]; then
    print_status 0 "Todas las etiquetas Traefik están correctas"
else
    print_status 1 "Faltan o hay etiquetas incorrectas"
    print_warning "Ejecuta: bash VERIFICAR_Y_REAPLICAR_TRAEFIK.sh"
fi
echo ""

# ===== 4. VERIFICAR ACCESIBILIDAD DE ENDPOINTS =====
echo "4️⃣  VERIFICANDO ACCESIBILIDAD DE ENDPOINTS"
echo "=========================================="

ENDPOINTS=(
    "https://${DOMAIN}/health"
    "https://${DOMAIN}/api/health"
    "https://${DOMAIN}/qr"
    "https://${DOMAIN}/api/qr"
    "https://${DOMAIN}/status"
    "https://${DOMAIN}/api/status"
)

for endpoint in "${ENDPOINTS[@]}"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$endpoint" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        print_status 0 "$endpoint"
    elif [ "$HTTP_CODE" = "000" ]; then
        print_warning "$endpoint (sin conexión o timeout)"
    elif [ "$HTTP_CODE" = "404" ]; then
        print_status 1 "$endpoint (404 - No encontrado)"
    else
        print_warning "$endpoint (HTTP $HTTP_CODE)"
    fi
done
echo ""

# ===== 5. VERIFICAR LOGS RECIENTES =====
echo "5️⃣  LOGS RECIENTES (últimas 10 líneas)"
echo "=========================================="
docker service logs $SERVICE_NAME --tail 10 --no-trunc 2>&1 | tail -10
echo ""

# ===== 6. VERIFICAR ESTADO DE CONEXIÓN WHATSAPP =====
echo "6️⃣  VERIFICANDO ESTADO DE CONEXIÓN WHATSAPP"
echo "=========================================="

STATUS_RESPONSE=$(curl -s --max-time 5 "https://${DOMAIN}/api/status" 2>/dev/null)
if [ -n "$STATUS_RESPONSE" ]; then
    # Intentar parsear JSON (básico)
    if echo "$STATUS_RESPONSE" | grep -q "whatsapp"; then
        WHATSAPP_STATUS=$(echo "$STATUS_RESPONSE" | grep -o '"whatsapp":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
        echo "   Estado WhatsApp: $WHATSAPP_STATUS"
        
        if [ "$WHATSAPP_STATUS" = "connected" ]; then
            print_status 0 "WhatsApp está conectado"
        elif [ "$WHATSAPP_STATUS" = "waiting_scan" ]; then
            print_warning "WhatsApp esperando escaneo de QR"
        else
            print_warning "WhatsApp estado: $WHATSAPP_STATUS"
        fi
    else
        echo "   Respuesta recibida pero formato inesperado"
        echo "   (Puede ser HTML en lugar de JSON)"
    fi
else
    print_status 1 "No se pudo obtener el estado (endpoint no accesible)"
fi
echo ""

# ===== RESUMEN FINAL =====
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo ""

# Contar problemas
ISSUES=0

if ! echo "$NETWORKS" | grep -q "easypanel"; then
    ISSUES=$((ISSUES + 1))
fi

if [ "$ALL_LABELS_OK" = false ]; then
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    print_status 0 "Todo parece estar configurado correctamente"
    echo ""
    echo "🌐 Prueba acceder a:"
    echo "   https://${DOMAIN}/qr"
    echo "   https://${DOMAIN}/status"
else
    print_warning "Se encontraron $ISSUES problema(s)"
    echo ""
    echo "💡 Soluciones:"
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   - Agregar a red easypanel: docker service update --network-add easypanel $SERVICE_NAME"
    fi
    if [ "$ALL_LABELS_OK" = false ]; then
        echo "   - Reaplicar etiquetas Traefik: bash VERIFICAR_Y_REAPLICAR_TRAEFIK.sh"
    fi
fi
echo ""
