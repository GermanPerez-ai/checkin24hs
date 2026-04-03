#!/bin/bash
# 🔍 Script de Diagnóstico del Servidor WhatsApp (Linux/Bash)
# 
# Este script verifica si el servidor está corriendo y accesible

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Parámetros por defecto
SERVER_URL="${1:-http://api1.checkin24hs.com}"
INSTANCE="${2:-1}"
PORT=$((3000 + INSTANCE))

FULL_URL="${SERVER_URL}:${PORT}"

echo ""
echo "=============================================================="
echo -e "${CYAN}🔍 DIAGNÓSTICO DEL SERVIDOR WHATSAPP${NC}"
echo "=============================================================="
echo ""
echo -e "${YELLOW}📡 URL: ${FULL_URL}${NC}"
echo -e "${YELLOW}📱 Instancia: ${INSTANCE}${NC}"
echo -e "${YELLOW}🔌 Puerto: ${PORT}${NC}"
echo ""

# Función para hacer request HTTP
test_server_connection() {
    local url=$1
    local timeout=${2:-5}
    
    echo -e "${CYAN}🔍 Probando conexión a ${url}...${NC}"
    
    response=$(curl -s -w "\n%{http_code}" --max-time $timeout "$url" 2>&1)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
        echo "{\"success\": true, \"statusCode\": $http_code, \"content\": $(echo "$body" | jq -c . 2>/dev/null || echo "\"$body\"")}"
    else
        # Determinar tipo de error
        if echo "$response" | grep -qi "timeout\|timed out"; then
            error_type="TIMEOUT"
        elif echo "$response" | grep -qi "refused\|connection refused"; then
            error_type="CONNECTION_REFUSED"
        elif echo "$response" | grep -qi "not found\|404"; then
            error_type="NOT_FOUND"
        elif echo "$response" | grep -qi "could not resolve\|DNS"; then
            error_type="DNS_ERROR"
        else
            error_type="UNKNOWN"
        fi
        
        echo "{\"success\": false, \"errorType\": \"$error_type\", \"errorMessage\": \"$response\"}"
    fi
}

# 1. Verificar si el servidor responde
echo -e "${YELLOW}1️⃣  Verificando si el servidor está accesible...${NC}"
echo "--------------------------------------------------------------"

result=$(test_server_connection "${FULL_URL}/api/health")
success=$(echo "$result" | jq -r '.success' 2>/dev/null)

if [ "$success" != "true" ]; then
    error_type=$(echo "$result" | jq -r '.errorType' 2>/dev/null)
    error_msg=$(echo "$result" | jq -r '.errorMessage' 2>/dev/null)
    
    echo -e "${RED}   ❌ El servidor NO está accesible${NC}"
    echo -e "${RED}   Error: ${error_type}${NC}"
    echo -e "${RED}   Detalles: ${error_msg}${NC}"
    echo ""
    
    # Diagnóstico específico según el tipo de error
    case "$error_type" in
        "TIMEOUT")
            echo -e "${YELLOW}   💡 El servidor no responde. Posibles causas:${NC}"
            echo "      - El servicio no está corriendo"
            echo "      - El puerto ${PORT} no está abierto en el firewall"
            echo "      - El servicio está en un contenedor Docker que no expone el puerto"
            echo "      - El servicio está escuchando solo en localhost (127.0.0.1)"
            ;;
        "CONNECTION_REFUSED")
            echo -e "${YELLOW}   💡 La conexión fue rechazada. Posibles causas:${NC}"
            echo "      - No hay ningún servicio escuchando en el puerto ${PORT}"
            echo "      - El servicio está detenido"
            echo "      - El puerto está bloqueado por un firewall"
            ;;
        "DNS_ERROR")
            echo -e "${YELLOW}   💡 Error de DNS. Posibles causas:${NC}"
            echo "      - El dominio ${SERVER_URL} no existe o no está configurado"
            echo "      - Problemas de resolución DNS"
            ;;
        *)
            echo -e "${YELLOW}   💡 Error desconocido. Verifica:${NC}"
            echo "      - Que el servidor esté corriendo"
            echo "      - Que el puerto ${PORT} esté abierto"
            echo "      - Que la URL sea correcta"
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}2️⃣  SOLUCIONES SUGERIDAS${NC}"
    echo "--------------------------------------------------------------"
    echo ""
    
    echo -e "${CYAN}   A. Verificar en EasyPanel:${NC}"
    echo "      1. Ve a EasyPanel (http://TU_IP:3000)"
    echo "      2. Busca el servicio 'whatsapp${INSTANCE}' o 'checkin24hs_whatsapp${INSTANCE}'"
    echo "      3. Verifica que esté en estado 'Running' (verde)"
    echo "      4. Si está detenido, haz clic en 'Start' o 'Iniciar'"
    echo ""
    
    echo -e "${CYAN}   B. Verificar puerto en EasyPanel:${NC}"
    echo "      1. Ve al servicio en EasyPanel"
    echo "      2. Ve a la sección 'Resources' o 'Recursos'"
    echo "      3. Verifica que el puerto esté configurado como: ${PORT}"
    echo "      4. Si no, cámbialo y reinicia el servicio"
    echo ""
    
    echo -e "${CYAN}   C. Verificar variables de entorno:${NC}"
    echo "      1. En EasyPanel, ve a 'Environment' o 'Variables de Entorno'"
    echo "      2. Verifica que exista: PORT=${PORT}"
    echo "      3. Verifica que exista: INSTANCE_NUMBER=${INSTANCE}"
    echo "      4. Si faltan, agréguelas y reinicia"
    echo ""
    
    echo -e "${CYAN}   D. Verificar logs del servicio:${NC}"
    echo "      1. En EasyPanel, ve a la pestaña 'Logs'"
    echo "      2. Busca errores o mensajes como:"
    echo "         - 'Servidor iniciado en puerto ${PORT}'"
    echo "         - 'Error iniciando servidor'"
    echo "         - 'Puerto ya en uso'"
    echo ""
    
    echo -e "${CYAN}   E. Verificar desde el servidor (SSH):${NC}"
    echo "      1. Verifica que el servicio esté corriendo:"
    echo "         docker ps | grep whatsapp"
    echo "         # O si usas servicios Docker Swarm:"
    echo "         docker service ls | grep whatsapp"
    echo ""
    echo "      2. Verifica que el puerto esté escuchando:"
    echo "         netstat -tulpn | grep ${PORT}"
    echo "         # O:"
    echo "         ss -tulpn | grep ${PORT}"
    echo ""
    echo "      3. Verifica logs del contenedor/servicio:"
    echo "         docker logs CONTAINER_ID"
    echo "         # O:"
    echo "         docker service logs SERVICE_NAME"
    echo ""
    
    exit 1
else
    status_code=$(echo "$result" | jq -r '.statusCode' 2>/dev/null)
    echo -e "${GREEN}   ✅ El servidor ESTÁ accesible${NC}"
    echo -e "${GREEN}   Status Code: ${status_code}${NC}"
fi

echo ""

# 2. Verificar endpoint de estado
echo -e "${YELLOW}2️⃣  Verificando endpoint /api/status...${NC}"
echo "--------------------------------------------------------------"

status_result=$(test_server_connection "${FULL_URL}/api/status")
status_success=$(echo "$status_result" | jq -r '.success' 2>/dev/null)

if [ "$status_success" = "true" ]; then
    status_content=$(echo "$status_result" | jq -r '.content' 2>/dev/null)
    if [ "$status_content" != "null" ] && [ -n "$status_content" ]; then
        echo -e "${GREEN}   ✅ Endpoint funcionando${NC}"
        whatsapp_status=$(echo "$status_content" | jq -r '.whatsapp' 2>/dev/null)
        connected=$(echo "$status_content" | jq -r '.connected' 2>/dev/null)
        phone=$(echo "$status_content" | jq -r '.phone' 2>/dev/null)
        
        echo -e "${CYAN}   📱 Estado WhatsApp: ${whatsapp_status}${NC}"
        if [ "$connected" = "true" ]; then
            echo -e "${GREEN}   🔌 Conexión: Conectado ✅${NC}"
        else
            echo -e "${YELLOW}   🔌 Conexión: Desconectado ❌${NC}"
        fi
        if [ "$phone" != "null" ] && [ -n "$phone" ]; then
            echo -e "${CYAN}   📞 Teléfono: ${phone}${NC}"
        fi
    else
        echo -e "${YELLOW}   ⚠️  Endpoint responde pero con formato incorrecto${NC}"
    fi
else
    echo -e "${RED}   ❌ Endpoint /api/status no disponible${NC}"
fi

echo ""

# 3. Verificar endpoint de QR
echo -e "${YELLOW}3️⃣  Verificando endpoint /api/qr...${NC}"
echo "--------------------------------------------------------------"

qr_result=$(test_server_connection "${FULL_URL}/api/qr")
qr_success=$(echo "$qr_result" | jq -r '.success' 2>/dev/null)

if [ "$qr_success" = "true" ]; then
    qr_content=$(echo "$qr_result" | jq -r '.content' 2>/dev/null)
    if [ "$qr_content" != "null" ] && [ -n "$qr_content" ]; then
        echo -e "${GREEN}   ✅ Endpoint funcionando${NC}"
        qr_status=$(echo "$qr_content" | jq -r '.status' 2>/dev/null)
        echo -e "${CYAN}   📊 Estado QR: ${qr_status}${NC}"
        
        case "$qr_status" in
            "waiting_scan")
                echo -e "${GREEN}   📱 QR disponible para escanear${NC}"
                ;;
            "expired")
                echo -e "${YELLOW}   ⚠️  QR expirado${NC}"
                ;;
            "connected")
                echo -e "${GREEN}   ✅ WhatsApp conectado${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}   ⚠️  Endpoint responde pero con formato incorrecto${NC}"
    fi
else
    echo -e "${RED}   ❌ Endpoint /api/qr no disponible${NC}"
fi

echo ""
echo "=============================================================="
echo -e "${GREEN}✅ DIAGNÓSTICO COMPLETADO${NC}"
echo "=============================================================="
echo ""

if [ "$success" = "true" ]; then
    echo -e "${GREEN}💡 El servidor está funcionando. Puedes acceder a:${NC}"
    echo -e "${CYAN}   - Panel Web: ${FULL_URL}${NC}"
    echo -e "${CYAN}   - Estado: ${FULL_URL}/api/status${NC}"
    echo -e "${CYAN}   - QR: ${FULL_URL}/api/qr${NC}"
    echo ""
    echo -e "${YELLOW}Si aún tienes problemas, verifica:${NC}"
    echo "   1. Que el QR no esté expirado (más de 2 minutos)"
    echo "   2. Que la sesión no esté corrupta"
    echo "   3. Los logs del servidor para errores específicos"
else
    echo -e "${YELLOW}⚠️  El servidor no está accesible. Sigue las soluciones sugeridas arriba.${NC}"
fi

echo ""
