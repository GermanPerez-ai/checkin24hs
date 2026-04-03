#!/bin/bash

# Script para consultar conexiones activas de WhatsApp en el servidor
# Verifica el estado de todas las instancias de WhatsApp (1-4)

echo ""
echo "=== CONSULTANDO CONEXIONES ACTIVAS DE WHATSAPP ==="
echo ""

# Obtener IP del servidor
HOST_IP=$(hostname -I | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
    HOST_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
fi
if [ -z "$HOST_IP" ]; then
    HOST_IP="localhost"
fi

# Puertos de las instancias
PUERTOS=(3001 3002 3003 3004)
CONEXIONES_ACTIVAS=0
CONEXIONES_DESCONECTADAS=0

# Función para verificar estado
verificar_whatsapp() {
    local numero=$1
    local puerto=$2
    local url="http://${HOST_IP}:${puerto}/api/status"
    
    echo "📱 WhatsApp $numero (Puerto $puerto):"
    
    # Intentar obtener el estado
    response=$(curl -s --max-time 5 "$url" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        # Extraer información del JSON (requiere jq o usar grep/sed)
        if command -v jq &> /dev/null; then
            connected=$(echo "$response" | jq -r '.connected // false')
            phone=$(echo "$response" | jq -r '.phoneNumber // "-"')
            user=$(echo "$response" | jq -r '.userName // "-"')
            flor=$(echo "$response" | jq -r '.flor // "-"')
            auto_reply=$(echo "$response" | jq -r '.autoReply // false')
            last_activity=$(echo "$response" | jq -r '.lastActivity // "-"')
            qr_code=$(echo "$response" | jq -r '.qrCode // empty')
            
            if [ "$connected" = "true" ]; then
                echo "   ✅ Estado: CONECTADO"
                echo "   📞 Teléfono: $phone"
                echo "   👤 Usuario: $user"
                echo "   🤖 Flor IA: $flor"
                echo "   ⚙️  Auto-respuesta: $auto_reply"
                echo "   🕐 Última actividad: $last_activity"
                CONEXIONES_ACTIVAS=$((CONEXIONES_ACTIVAS + 1))
            elif [ ! -z "$qr_code" ]; then
                echo "   ⏳ Estado: ESPERANDO QR"
                echo "   📲 Código QR disponible para escanear"
                CONEXIONES_DESCONECTADAS=$((CONEXIONES_DESCONECTADAS + 1))
            else
                echo "   ❌ Estado: DESCONECTADO"
                whatsapp_status=$(echo "$response" | jq -r '.whatsapp // "-"')
                echo "   📝 WhatsApp: $whatsapp_status"
                CONEXIONES_DESCONECTADAS=$((CONEXIONES_DESCONECTADAS + 1))
            fi
        else
            # Sin jq, usar grep básico
            if echo "$response" | grep -q '"connected":true'; then
                echo "   ✅ Estado: CONECTADO"
                phone=$(echo "$response" | grep -o '"phoneNumber":"[^"]*"' | cut -d'"' -f4)
                user=$(echo "$response" | grep -o '"userName":"[^"]*"' | cut -d'"' -f4)
                echo "   📞 Teléfono: ${phone:--}"
                echo "   👤 Usuario: ${user:--}"
                CONEXIONES_ACTIVAS=$((CONEXIONES_ACTIVAS + 1))
            elif echo "$response" | grep -q '"qrCode"'; then
                echo "   ⏳ Estado: ESPERANDO QR"
                echo "   📲 Código QR disponible para escanear"
                CONEXIONES_DESCONECTADAS=$((CONEXIONES_DESCONECTADAS + 1))
            else
                echo "   ❌ Estado: DESCONECTADO"
                CONEXIONES_DESCONECTADAS=$((CONEXIONES_DESCONECTADAS + 1))
            fi
        fi
    else
        echo "   ❌ Estado: NO RESPONDE"
        echo "   ⚠️  El servidor no está disponible en el puerto $puerto"
        CONEXIONES_DESCONECTADAS=$((CONEXIONES_DESCONECTADAS + 1))
    fi
    
    echo ""
}

# Verificar cada instancia
for i in {0..3}; do
    numero=$((i + 1))
    puerto=${PUERTOS[$i]}
    verificar_whatsapp $numero $puerto
done

# Resumen
echo "=== RESUMEN ==="
echo "✅ Conexiones activas: $CONEXIONES_ACTIVAS"
echo "❌ Conexiones desconectadas/no disponibles: $CONEXIONES_DESCONECTADAS"
echo "📊 Total de instancias: 4"
echo ""

# Verificar procesos PM2
echo "=== PROCESOS PM2 ==="
if command -v pm2 &> /dev/null; then
    pm2 list | grep -E "whatsapp|name|status" || pm2 list
else
    echo "⚠️  PM2 no está instalado o no está en el PATH"
fi
echo ""

# Verificar puertos activos
echo "=== PUERTOS ACTIVOS ==="
for puerto in "${PUERTOS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$puerto " || ss -tuln 2>/dev/null | grep -q ":$puerto "; then
        echo "✅ Puerto $puerto: ACTIVO"
        netstat -tuln 2>/dev/null | grep ":$puerto " || ss -tuln 2>/dev/null | grep ":$puerto "
    else
        echo "❌ Puerto $puerto: INACTIVO"
    fi
done
echo ""




