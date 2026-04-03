#!/bin/bash
# 🔧 Script Completo para Solucionar Autenticación Fallida
# 
# Este script diagnostica y soluciona problemas de autenticación

INSTANCE="${1:-1}"
SERVICE_NAME="checkin24hs_whatsapp"

echo "=============================================================="
echo "🔧 SOLUCIÓN DE AUTENTICACIÓN FALLIDA - WHATSAPP"
echo "=============================================================="
echo ""
echo "📱 Instancia: ${INSTANCE}"
echo "🔌 Servicio: ${SERVICE_NAME}"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Verificar estado del servicio
echo -e "${CYAN}1️⃣  Verificando estado del servicio...${NC}"
echo "--------------------------------------------------------------"
SERVICE_STATUS=$(docker service ps ${SERVICE_NAME} --no-trunc --format "{{.CurrentState}}" 2>/dev/null | head -1)
if [ -n "$SERVICE_STATUS" ]; then
    echo -e "${GREEN}   ✅ Servicio encontrado${NC}"
    echo "   Estado: ${SERVICE_STATUS}"
else
    echo -e "${RED}   ❌ Servicio no encontrado${NC}"
    echo "   Verifica que el servicio se llame: ${SERVICE_NAME}"
    exit 1
fi
echo ""

# 2. Ver logs recientes
echo -e "${CYAN}2️⃣  Analizando logs recientes...${NC}"
echo "--------------------------------------------------------------"
RECENT_LOGS=$(docker service logs ${SERVICE_NAME} --tail 50 2>&1)

# Buscar indicadores de problemas
if echo "$RECENT_LOGS" | grep -qi "QR escaneado"; then
    echo -e "${YELLOW}   ⚠️  QR fue escaneado pero la autenticación no se completó${NC}"
    QR_SCANNED=true
else
    QR_SCANNED=false
fi

if echo "$RECENT_LOGS" | grep -qi "más de.*minutos"; then
    echo -e "${RED}   ❌ La autenticación lleva mucho tiempo${NC}"
    LONG_AUTH=true
else
    LONG_AUTH=false
fi

if echo "$RECENT_LOGS" | grep -qi "device_removed\|conflict"; then
    echo -e "${RED}   ❌ Sesión conflictiva detectada${NC}"
    CONFLICT=true
else
    CONFLICT=false
fi

if echo "$RECENT_LOGS" | grep -qi "conectado exitosamente"; then
    echo -e "${GREEN}   ✅ WhatsApp está conectado${NC}"
    CONNECTED=true
else
    CONNECTED=false
fi

echo ""

# 3. Verificar sesión en el contenedor
echo -e "${CYAN}3️⃣  Verificando sesión en el contenedor...${NC}"
echo "--------------------------------------------------------------"
CONTAINER_ID=$(docker ps | grep ${SERVICE_NAME} | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}   ❌ No se encontró contenedor corriendo${NC}"
    exit 1
fi

echo "   Contenedor: ${CONTAINER_ID}"

# Verificar si existe la carpeta de autenticación
AUTH_EXISTS=$(docker exec ${CONTAINER_ID} test -d /app/auth_info_baileys_${INSTANCE} && echo "yes" || echo "no")

if [ "$AUTH_EXISTS" = "yes" ]; then
    echo -e "${YELLOW}   ⚠️  Sesión encontrada en el contenedor${NC}"
    
    # Ver tamaño
    AUTH_SIZE=$(docker exec ${CONTAINER_ID} du -sh /app/auth_info_baileys_${INSTANCE} 2>/dev/null | cut -f1)
    echo "   Tamaño: ${AUTH_SIZE}"
    
    # Ver archivos
    AUTH_FILES=$(docker exec ${CONTAINER_ID} ls -la /app/auth_info_baileys_${INSTANCE} 2>/dev/null | wc -l)
    echo "   Archivos: $((AUTH_FILES - 3))"
    
    NEEDS_CLEANUP=true
else
    echo -e "${GREEN}   ✅ No hay sesión (esto es normal para primera conexión)${NC}"
    NEEDS_CLEANUP=false
fi
echo ""

# 4. Diagnóstico
echo -e "${CYAN}4️⃣  DIAGNÓSTICO${NC}"
echo "--------------------------------------------------------------"

if [ "$CONNECTED" = "true" ]; then
    echo -e "${GREEN}   ✅ WhatsApp está conectado. No hay problema.${NC}"
    exit 0
fi

if [ "$QR_SCANNED" = "true" ] && [ "$LONG_AUTH" = "true" ]; then
    echo -e "${RED}   ❌ PROBLEMA DETECTADO: Autenticación bloqueada${NC}"
    echo ""
    echo "   El QR fue escaneado pero la autenticación no se completa."
    echo "   Esto puede ser por:"
    echo "   1. Sesión conflictiva en el teléfono"
    echo "   2. Conexión de red muy lenta"
    echo "   3. Problemas con el servidor de WhatsApp"
    echo ""
    SOLUTION_NEEDED=true
elif [ "$CONFLICT" = "true" ]; then
    echo -e "${RED}   ❌ PROBLEMA DETECTADO: Sesión conflictiva${NC}"
    echo ""
    echo "   Hay una sesión conflictiva que está bloqueando la conexión."
    echo ""
    SOLUTION_NEEDED=true
else
    echo -e "${YELLOW}   ⚠️  Estado desconocido. Se recomienda limpiar y reiniciar.${NC}"
    SOLUTION_NEEDED=true
fi
echo ""

# 5. Solución
if [ "$SOLUTION_NEEDED" = "true" ]; then
    echo -e "${YELLOW}5️⃣  SOLUCIÓN${NC}"
    echo "--------------------------------------------------------------"
    echo ""
    echo "🔧 Pasos para solucionar:"
    echo ""
    
    echo -e "${CYAN}A. Limpiar sesión del servidor:${NC}"
    echo "   docker exec ${CONTAINER_ID} rm -rf /app/auth_info_baileys_${INSTANCE}"
    echo ""
    
    echo -e "${CYAN}B. Reiniciar el servicio:${NC}"
    echo "   docker service update --force ${SERVICE_NAME}"
    echo ""
    
    echo -e "${CYAN}C. En tu teléfono:${NC}"
    echo "   1. Abre WhatsApp"
    echo "   2. Ve a: Configuración → Dispositivos vinculados"
    echo "   3. Desconecta TODAS las sesiones de WhatsApp Web"
    echo "   4. Cierra completamente WhatsApp"
    echo "   5. Vuelve a abrir WhatsApp"
    echo ""
    
    echo -e "${CYAN}D. Escanear nuevo QR:${NC}"
    echo "   1. Espera 30-60 segundos después de reiniciar"
    echo "   2. Abre: http://api1.checkin24hs.com:3001"
    echo "   3. Escanea el QR INMEDIATAMENTE (expira en 2 minutos)"
    echo "   4. Si usas WiFi, prueba con DATOS MÓVILES"
    echo ""
    
    # Preguntar si quiere ejecutar la limpieza
    echo ""
    read -p "¿Quieres que ejecute la limpieza automáticamente? (s/N): " AUTO_CLEAN
    
    if [ "$AUTO_CLEAN" = "s" ] || [ "$AUTO_CLEAN" = "S" ]; then
        echo ""
        echo "🧹 Limpiando sesión..."
        
        # Limpiar sesión
        docker exec ${CONTAINER_ID} rm -rf /app/auth_info_baileys_${INSTANCE} 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   ✅ Sesión limpiada${NC}"
        else
            echo -e "${RED}   ❌ Error limpiando sesión${NC}"
        fi
        
        echo ""
        echo "🔄 Reiniciando servicio..."
        docker service update --force ${SERVICE_NAME} >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   ✅ Servicio reiniciado${NC}"
            echo ""
            echo "⏳ Espera 30-60 segundos y luego:"
            echo "   1. Abre: http://api1.checkin24hs.com:3001"
            echo "   2. Escanea el nuevo QR INMEDIATAMENTE"
            echo "   3. Asegúrate de desconectar todas las sesiones en tu teléfono primero"
        else
            echo -e "${RED}   ❌ Error reiniciando servicio${NC}"
        fi
    else
        echo ""
        echo "💡 Ejecuta los comandos manualmente siguiendo las instrucciones arriba."
    fi
fi

echo ""
echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
