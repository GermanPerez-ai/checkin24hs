#!/bin/bash

# Script para probar Evolution API paso a paso
# Ejecuta: chmod +x probar-evolution-api.sh && ./probar-evolution-api.sh

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
API_KEY="${EVOLUTION_API_KEY:-checkin24hs-secret-key-2024}"
API_URL="${EVOLUTION_API_URL:-http://localhost:8080}"
ADAPTER_URL="${ADAPTER_URL:-http://localhost:3000}"

echo -e "${BLUE}🧪 PROBANDO EVOLUTION API - CHECKIN24HS${NC}"
echo "=========================================="
echo ""

# Función para verificar respuesta HTTP
check_http() {
    local url=$1
    local expected_status=${2:-200}
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" == "$expected_status" ]; then
        echo -e "${GREEN}✅${NC} $url (HTTP $response)"
        return 0
    else
        echo -e "${RED}❌${NC} $url (HTTP $response, esperado $expected_status)"
        return 1
    fi
}

# Función para hacer request y mostrar resultado
make_request() {
    local method=$1
    local url=$2
    local headers=$3
    local data=$4
    local description=$5
    
    echo -e "\n${YELLOW}📡 $description${NC}"
    echo "URL: $url"
    
    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$url" $headers)
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$url" $headers -d "$data")
    fi
    
    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✅ Éxito (HTTP $http_code)${NC}"
        echo "Respuesta: $body" | head -c 200
        echo ""
        return 0
    else
        echo -e "${RED}❌ Error (HTTP $http_code)${NC}"
        echo "Respuesta: $body"
        return 1
    fi
}

# ===== PASO 1: Verificar que Evolution API está corriendo =====
echo -e "\n${BLUE}📋 PASO 1: Verificar Evolution API${NC}"
echo "----------------------------------------"

if check_http "$API_URL" 200; then
    echo -e "${GREEN}✅ Evolution API está corriendo${NC}"
else
    echo -e "${RED}❌ Evolution API no está corriendo${NC}"
    echo "Ejecuta: docker-compose up -d"
    exit 1
fi

# ===== PASO 2: Verificar que el Adaptador está corriendo =====
echo -e "\n${BLUE}📋 PASO 2: Verificar Adaptador${NC}"
echo "----------------------------------------"

if check_http "$ADAPTER_URL/health" 200; then
    echo -e "${GREEN}✅ Adaptador está corriendo${NC}"
else
    echo -e "${YELLOW}⚠️ Adaptador no está corriendo (opcional)${NC}"
    echo "Ejecuta: cd evolution-api && npm install && npm start"
fi

# ===== PASO 3: Listar instancias existentes =====
echo -e "\n${BLUE}📋 PASO 3: Listar Instancias Existentes${NC}"
echo "----------------------------------------"

make_request "GET" "$API_URL/instance/fetchInstances" "-H \"apikey: $API_KEY\"" "" "Obtener lista de instancias"

# ===== PASO 4: Crear instancias si no existen =====
echo -e "\n${BLUE}📋 PASO 4: Crear Instancias (si no existen)${NC}"
echo "----------------------------------------"

for i in 1 2 3 4; do
    instance_name="whatsapp-$i"
    echo -e "\n${YELLOW}📱 Verificando instancia: $instance_name${NC}"
    
    # Verificar si existe
    check_response=$(curl -s "$API_URL/instance/fetchInstance/$instance_name" \
        -H "apikey: $API_KEY")
    
    if echo "$check_response" | grep -q "instanceName"; then
        echo -e "${GREEN}✅ Instancia $instance_name ya existe${NC}"
    else
        echo -e "${YELLOW}📝 Creando instancia $instance_name...${NC}"
        make_request "POST" "$API_URL/instance/create" \
            "-H \"apikey: $API_KEY\" -H \"Content-Type: application/json\"" \
            "{\"instanceName\": \"$instance_name\", \"qrcode\": true, \"integration\": \"WHATSAPP-BAILEYS\"}" \
            "Crear instancia $instance_name"
    fi
done

# ===== PASO 5: Obtener QR Codes =====
echo -e "\n${BLUE}📋 PASO 5: Obtener QR Codes${NC}"
echo "----------------------------------------"

for i in 1 2 3 4; do
    instance_name="whatsapp-$i"
    echo -e "\n${YELLOW}📱 QR Code para $instance_name:${NC}"
    
    if [ -n "$ADAPTER_URL" ] && check_http "$ADAPTER_URL/health" 200 2>/dev/null; then
        # Usar adaptador si está disponible
        qr_response=$(curl -s "$ADAPTER_URL/api/qr/$instance_name")
    else
        # Usar Evolution API directamente
        qr_response=$(curl -s "$API_URL/instance/connect/$instance_name" \
            -H "apikey: $API_KEY")
    fi
    
    # Extraer QR code
    qr_code=$(echo "$qr_response" | grep -o '"qrcode\.base64":"[^"]*"' | cut -d'"' -f4)
    qr_url=$(echo "$qr_response" | grep -o '"qrcode\.url":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$qr_code" ]; then
        echo -e "${GREEN}✅ QR Code disponible${NC}"
        echo "URL del QR: $qr_url"
        echo "Para ver el QR, abre: $qr_url"
    elif [ -n "$qr_url" ]; then
        echo -e "${GREEN}✅ QR Code disponible${NC}"
        echo "URL del QR: $qr_url"
    else
        # Verificar estado de conexión
        status_response=$(curl -s "$API_URL/instance/fetchInstance/$instance_name" \
            -H "apikey: $API_KEY")
        
        if echo "$status_response" | grep -q '"status":"open"'; then
            echo -e "${GREEN}✅ Instancia ya conectada (no necesita QR)${NC}"
        else
            echo -e "${YELLOW}⚠️ QR no disponible aún, intenta más tarde${NC}"
        fi
    fi
done

# ===== PASO 6: Verificar Estado de Conexión =====
echo -e "\n${BLUE}📋 PASO 6: Verificar Estado de Conexión${NC}"
echo "----------------------------------------"

for i in 1 2 3 4; do
    instance_name="whatsapp-$i"
    echo -e "\n${YELLOW}📱 Estado de $instance_name:${NC}"
    
    status_response=$(curl -s "$API_URL/instance/fetchInstance/$instance_name" \
        -H "apikey: $API_KEY")
    
    status=$(echo "$status_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    phone=$(echo "$status_response" | grep -o '"phoneNumber":"[^"]*"' | cut -d'"' -f4)
    
    case "$status" in
        "open")
            echo -e "${GREEN}✅ Conectado${NC}"
            if [ -n "$phone" ]; then
                echo "   Teléfono: $phone"
            fi
            ;;
        "close")
            echo -e "${RED}❌ Desconectado${NC}"
            echo "   Escanea el QR para conectar"
            ;;
        *)
            echo -e "${YELLOW}⚠️ Estado: $status${NC}"
            ;;
    esac
done

# ===== PASO 7: Probar Envío de Mensaje (si hay instancia conectada) =====
echo -e "\n${BLUE}📋 PASO 7: Probar Envío de Mensaje${NC}"
echo "----------------------------------------"

read -p "¿Quieres probar enviar un mensaje? (s/n): " probar_envio

if [ "$probar_envio" == "s" ] || [ "$probar_envio" == "S" ]; then
    read -p "Número de instancia (1-4): " num_instancia
    read -p "Número de teléfono (formato: 5491112345678): " numero
    read -p "Mensaje a enviar: " mensaje
    
    instance_name="whatsapp-$num_instancia"
    
    if [ -n "$ADAPTER_URL" ] && check_http "$ADAPTER_URL/health" 200 2>/dev/null; then
        # Usar adaptador
        make_request "POST" "$ADAPTER_URL/api/send/$instance_name" \
            "-H \"Content-Type: application/json\"" \
            "{\"number\": \"$numero\", \"text\": \"$mensaje\"}" \
            "Enviar mensaje desde $instance_name"
    else
        # Usar Evolution API directamente
        make_request "POST" "$API_URL/message/sendText/$instance_name" \
            "-H \"apikey: $API_KEY\" -H \"Content-Type: application/json\"" \
            "{\"number\": \"$numero\", \"text\": \"$mensaje\"}" \
            "Enviar mensaje desde $instance_name"
    fi
fi

# ===== RESUMEN =====
echo -e "\n${BLUE}📊 RESUMEN${NC}"
echo "=========================================="
echo -e "${GREEN}✅ Evolution API:${NC} $API_URL"
echo -e "${GREEN}✅ Adaptador:${NC} $ADAPTER_URL"
echo ""
echo "Para obtener QR codes manualmente:"
echo "  curl $API_URL/instance/connect/whatsapp-1 -H \"apikey: $API_KEY\""
echo ""
echo "Para enviar un mensaje:"
echo "  curl -X POST $API_URL/message/sendText/whatsapp-1 \\"
echo "    -H \"apikey: $API_KEY\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"number\": \"5491112345678\", \"text\": \"Hola!\"}'"
echo ""
echo -e "${GREEN}✅ Prueba completada!${NC}"


