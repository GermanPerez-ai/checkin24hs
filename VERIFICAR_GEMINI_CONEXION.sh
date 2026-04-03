#!/bin/bash
# Script para verificar la configuración de conexión de Gemini

echo "🔍 VERIFICAR CONEXIÓN GEMINI"
echo "=============================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 1. Verificar servicios WhatsApp
echo "1️⃣ Verificando servicios WhatsApp..."
echo ""

SERVICIOS_WHATSAPP=("checkin24hs_whatsapp")

for servicio in "${SERVICIOS_WHATSAPP[@]}"; do
    echo "   Verificando: $servicio"
    
    # Verificar si el servicio existe
    if docker service ls --format "{{.Name}}" | grep -q "^${servicio}$"; then
        # Verificar variable GEMINI_API_KEY
        GEMINI_KEY=$(docker service inspect "$servicio" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "GEMINI_API_KEY=" | cut -d'=' -f2)
        
        if [ -n "$GEMINI_KEY" ] && [ "$GEMINI_KEY" != "" ]; then
            # Ocultar parte de la clave para seguridad
            KEY_PREVIEW="${GEMINI_KEY:0:10}...${GEMINI_KEY: -4}"
            echo -e "      ${GREEN}✅ GEMINI_API_KEY configurada: $KEY_PREVIEW${NC}"
            
            # Verificar modelo
            GEMINI_MODEL=$(docker service inspect "$servicio" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "GEMINI_MODEL=" | cut -d'=' -f2)
            if [ -n "$GEMINI_MODEL" ]; then
                echo -e "      ${GREEN}✅ GEMINI_MODEL: $GEMINI_MODEL${NC}"
            else
                echo -e "      ${YELLOW}⚠️  GEMINI_MODEL no configurado (usará default: gemini-2.5-flash)${NC}"
            fi
        else
            echo -e "      ${RED}❌ GEMINI_API_KEY NO configurada${NC}"
        fi
    else
        echo -e "      ${YELLOW}⚠️  Servicio no encontrado${NC}"
    fi
    echo ""
done

# 2. Verificar endpoint de la API
echo "2️⃣ Verificando endpoint de Gemini API..."
echo ""
echo "   URL base: https://generativelanguage.googleapis.com"
echo "   Versión: v1beta"
echo "   Endpoint: /models/{MODEL}:generateContent"
echo "   Método: POST"
echo "   Autenticación: API Key en query parameter (?key=...)"
echo ""

# 3. Verificar logs de conexión
echo "3️⃣ Verificando logs de conexión (últimos 50 logs)..."
echo ""

for servicio in "${SERVICIOS_WHATSAPP[@]}"; do
    if docker service ls --format "{{.Name}}" | grep -q "^${servicio}$"; then
        echo "   Logs de $servicio:"
        LOGS=$(docker service logs "$servicio" --tail 50 2>&1 | grep -iE "gemini|429|403|400|api.*key" | tail -5)
        if [ -n "$LOGS" ]; then
            echo "$LOGS" | sed 's/^/      /'
        else
            echo -e "      ${CYAN}ℹ️  No hay logs recientes de Gemini${NC}"
        fi
        echo ""
    fi
done

# 4. Verificar archivos de código
echo "4️⃣ Verificando archivos de código que usan Gemini..."
echo ""

ARCHIVOS_GEMINI=(
    "whatsapp-server/whatsapp-server-baileys.js"
    "server.js"
    "dashboard.html"
    "crm/flor-ai-service.js"
)

for archivo in "${ARCHIVOS_GEMINI[@]}"; do
    if [ -f "$archivo" ]; then
        # Buscar referencias a generativelanguage.googleapis.com
        REFERENCIAS=$(grep -n "generativelanguage.googleapis.com" "$archivo" 2>/dev/null | head -3)
        if [ -n "$REFERENCIAS" ]; then
            echo "   ✅ $archivo:"
            echo "$REFERENCIAS" | sed 's/^/      /'
            echo ""
        fi
    fi
done

# 5. Resumen
echo "=============================="
echo "📋 RESUMEN"
echo "=============================="
echo ""
echo "URL de conexión:"
echo "   https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={API_KEY}"
echo ""
echo "Modelos usados:"
echo "   - gemini-2.5-flash (principal)"
echo "   - gemini-2.0-flash (alternativo)"
echo ""
echo "Variables de entorno necesarias:"
echo "   - GEMINI_API_KEY (requerida)"
echo "   - GEMINI_MODEL (opcional, default: gemini-2.5-flash)"
echo ""
echo "=============================="
