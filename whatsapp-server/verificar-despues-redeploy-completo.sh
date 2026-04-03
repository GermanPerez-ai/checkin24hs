#!/bin/bash
# 🔍 Verificación completa después del redeploy
# Verifica: código actualizado, sin fallos, conexiones y Traefik

cd /root/checkin24hs

echo "=============================================================="
echo "🔍 VERIFICACIÓN COMPLETA DESPUÉS DEL REDEPLOY"
echo "=============================================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de errores
ERRORS=0

# 1. Verificar que el servicio esté corriendo
echo "1️⃣  Verificando estado del servicio..."
SERVICE_STATUS=$(docker service ps checkin24hs_whatsapp --format "{{.CurrentState}}" --no-trunc | head -1)
if [[ "$SERVICE_STATUS" == *"Running"* ]]; then
    echo -e "${GREEN}✅ Servicio corriendo${NC}"
else
    echo -e "${RED}❌ Servicio NO está corriendo: $SERVICE_STATUS${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Obtener ID del contenedor
CONTAINER_ID=$(docker service ps checkin24hs_whatsapp --format "{{.Name}}.{{.ID}}" --no-trunc | head -1 | cut -d'.' -f2)
if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}❌ No se pudo obtener ID del contenedor${NC}"
    ERRORS=$((ERRORS + 1))
    exit 1
fi
echo "📦 ID del contenedor: $CONTAINER_ID"
echo ""

# 3. Verificar que el código esté actualizado (modo pasivo)
echo "2️⃣  Verificando código actualizado (modo pasivo)..."
FILE_IN_CONTAINER="/app/whatsapp-server/whatsapp-server-baileys.js"

# Verificar passive: true
if docker exec $(docker ps -q -f name=checkin24hs_whatsapp | head -1) grep -q "passive: true" "$FILE_IN_CONTAINER" 2>/dev/null; then
    echo -e "${GREEN}✅ passive: true encontrado${NC}"
else
    echo -e "${RED}❌ passive: true NO encontrado${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Verificar appStateSyncTimeoutMs: 0
if docker exec $(docker ps -q -f name=checkin24hs_whatsapp | head -1) grep -q "appStateSyncTimeoutMs: 0" "$FILE_IN_CONTAINER" 2>/dev/null; then
    echo -e "${GREEN}✅ appStateSyncTimeoutMs: 0 encontrado${NC}"
else
    echo -e "${RED}❌ appStateSyncTimeoutMs: 0 NO encontrado${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Verificar fireInitQueries: false
if docker exec $(docker ps -q -f name=checkin24hs_whatsapp | head -1) grep -q "fireInitQueries: false" "$FILE_IN_CONTAINER" 2>/dev/null; then
    echo -e "${GREEN}✅ fireInitQueries: false encontrado${NC}"
else
    echo -e "${RED}❌ fireInitQueries: false NO encontrado${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Verificar shouldSyncAppState: () => false
if docker exec $(docker ps -q -f name=checkin24hs_whatsapp | head -1) grep -q "shouldSyncAppState: () => false" "$FILE_IN_CONTAINER" 2>/dev/null; then
    echo -e "${GREEN}✅ shouldSyncAppState: () => false encontrado${NC}"
else
    echo -e "${RED}❌ shouldSyncAppState: () => false NO encontrado${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Verificar "MODO PASIVO: Emitir conexión inmediatamente"
if docker exec $(docker ps -q -f name=checkin24hs_whatsapp | head -1) grep -q "MODO PASIVO: Emitir conexión inmediatamente" "$FILE_IN_CONTAINER" 2>/dev/null; then
    echo -e "${GREEN}✅ Código de emisión inmediata encontrado${NC}"
else
    echo -e "${RED}❌ Código de emisión inmediata NO encontrado${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 4. Verificar logs recientes (últimos 2 minutos) para errores
echo "3️⃣  Verificando logs recientes (últimos 2 minutos)..."
RECENT_ERRORS=$(docker service logs checkin24hs_whatsapp --since 2m --tail 100 2>&1 | grep -iE "error|fatal|exception|crash|failed" | wc -l)
if [ "$RECENT_ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ No se encontraron errores recientes en los logs${NC}"
else
    echo -e "${YELLOW}⚠️  Se encontraron $RECENT_ERRORS posibles errores en los logs${NC}"
    echo "   Últimos errores:"
    docker service logs checkin24hs_whatsapp --since 2m --tail 100 2>&1 | grep -iE "error|fatal|exception|crash|failed" | tail -5
fi
echo ""

# 5. Verificar que el servidor esté respondiendo
echo "4️⃣  Verificando respuesta del servidor..."
CONTAINER_NAME=$(docker ps -q -f name=checkin24hs_whatsapp | head -1)
if [ -z "$CONTAINER_NAME" ]; then
    echo -e "${RED}❌ No se encontró contenedor corriendo${NC}"
    ERRORS=$((ERRORS + 1))
else
    # Verificar respuesta interna
    HTTP_RESPONSE=$(docker exec "$CONTAINER_NAME" curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/health 2>/dev/null || echo "000")
    if [ "$HTTP_RESPONSE" = "200" ] || [ "$HTTP_RESPONSE" = "404" ]; then
        echo -e "${GREEN}✅ Servidor respondiendo internamente (HTTP $HTTP_RESPONSE)${NC}"
    else
        echo -e "${RED}❌ Servidor NO responde internamente (HTTP $HTTP_RESPONSE)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# 6. Verificar puerto publicado
echo "5️⃣  Verificando puerto publicado..."
PORT_MAPPING=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{end}}' 2>/dev/null)
if [[ "$PORT_MAPPING" == *"3001"* ]]; then
    echo -e "${GREEN}✅ Puerto 3001 publicado: $PORT_MAPPING${NC}"
else
    echo -e "${RED}❌ Puerto 3001 NO está publicado${NC}"
    echo "   Mapeo actual: $PORT_MAPPING"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 7. Verificar acceso externo
echo "6️⃣  Verificando acceso externo..."
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "N/A")
echo "   IP pública: $PUBLIC_IP"

# Intentar conexión externa
EXTERNAL_RESPONSE=$(timeout 5 curl -s -o /dev/null -w "%{http_code}" "http://$PUBLIC_IP:3001/api/health" 2>/dev/null || echo "000")
if [ "$EXTERNAL_RESPONSE" = "200" ] || [ "$EXTERNAL_RESPONSE" = "404" ]; then
    echo -e "${GREEN}✅ Acceso externo funcionando (HTTP $EXTERNAL_RESPONSE)${NC}"
    echo "   URL: http://$PUBLIC_IP:3001"
else
    echo -e "${YELLOW}⚠️  Acceso externo no responde (HTTP $EXTERNAL_RESPONSE)${NC}"
    echo "   Esto puede ser normal si hay firewall o Traefik"
fi
echo ""

# 8. Verificar Traefik
echo "7️⃣  Verificando Traefik..."
TRAEFIK_CONTAINER=$(docker ps -q -f name=traefik | head -1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️  Contenedor Traefik no encontrado${NC}"
    echo "   (Esto puede ser normal si no usas Traefik)"
else
    echo -e "${GREEN}✅ Contenedor Traefik corriendo${NC}"
    
    # Verificar que Traefik esté respondiendo
    TRAEFIK_RESPONSE=$(docker exec "$TRAEFIK_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/overview 2>/dev/null || echo "000")
    if [ "$TRAEFIK_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✅ Traefik API respondiendo${NC}"
    else
        echo -e "${YELLOW}⚠️  Traefik API no responde (HTTP $TRAEFIK_RESPONSE)${NC}"
    fi
    
    # Verificar si el servicio está registrado en Traefik
    TRAEFIK_SERVICES=$(docker exec "$TRAEFIK_CONTAINER" curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -o "checkin24hs" | wc -l)
    if [ "$TRAEFIK_SERVICES" -gt 0 ]; then
        echo -e "${GREEN}✅ Servicio registrado en Traefik ($TRAEFIK_SERVICES rutas encontradas)${NC}"
    else
        echo -e "${YELLOW}⚠️  Servicio NO encontrado en Traefik${NC}"
    fi
fi
echo ""

# 9. Verificar estado de conexión WhatsApp
echo "8️⃣  Verificando estado de conexión WhatsApp..."
CONNECTION_STATUS=$(docker service logs checkin24hs_whatsapp --tail 50 2>&1 | grep -E "CONECTADO|conectado|QR|qr" | tail -3)
if [ -z "$CONNECTION_STATUS" ]; then
    echo -e "${YELLOW}⚠️  No se encontró información de conexión en logs recientes${NC}"
else
    echo "   Estado reciente:"
    echo "$CONNECTION_STATUS" | while read line; do
        if [[ "$line" == *"CONECTADO"* ]] || [[ "$line" == *"conectado"* ]]; then
            echo -e "   ${GREEN}✅ $line${NC}"
        elif [[ "$line" == *"QR"* ]] || [[ "$line" == *"qr"* ]]; then
            echo -e "   ${YELLOW}⚠️  $line${NC}"
        else
            echo "   $line"
        fi
    done
fi
echo ""

# 10. Verificar procesos Node.js
echo "9️⃣  Verificando procesos Node.js..."
NODE_PROCESSES=$(docker exec $(docker ps -q -f name=checkin24hs_whatsapp | head -1) ps aux | grep -E "node|npm" | grep -v grep | wc -l)
if [ "$NODE_PROCESSES" -gt 0 ]; then
    echo -e "${GREEN}✅ Procesos Node.js corriendo ($NODE_PROCESSES procesos)${NC}"
else
    echo -e "${RED}❌ No se encontraron procesos Node.js${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 11. Verificar uso de recursos
echo "🔟 Verificando uso de recursos..."
RESOURCE_USAGE=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps -q -f name=checkin24hs_whatsapp | head -1) 2>/dev/null)
if [ ! -z "$RESOURCE_USAGE" ]; then
    echo "$RESOURCE_USAGE"
else
    echo -e "${YELLOW}⚠️  No se pudo obtener información de recursos${NC}"
fi
echo ""

# Resumen final
echo "=============================================================="
echo "📊 RESUMEN"
echo "=============================================================="
echo ""

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las verificaciones pasaron correctamente${NC}"
    echo ""
    echo "🎉 El redeploy fue exitoso y todo está funcionando correctamente"
    echo ""
    echo "📝 Próximos pasos:"
    echo "   1. Acceder a http://$PUBLIC_IP:3001 para ver el QR"
    echo "   2. Escanear el QR con WhatsApp"
    echo "   3. Verificar que la conexión se complete sin errores"
    exit 0
else
    echo -e "${RED}❌ Se encontraron $ERRORS problemas${NC}"
    echo ""
    echo "🔧 Acciones recomendadas:"
    echo "   1. Revisar logs: docker service logs checkin24hs_whatsapp --tail 100"
    echo "   2. Verificar estado del servicio: docker service ps checkin24hs_whatsapp"
    echo "   3. Si el código no está actualizado, verificar que el redeploy usó la imagen correcta"
    echo "   4. Si hay problemas de conexión, verificar firewall y Traefik"
    exit 1
fi
