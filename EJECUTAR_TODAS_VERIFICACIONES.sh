#!/bin/bash

# Script completo para verificar todas las conexiones de WhatsApp
# Ejecutar en el servidor: bash EJECUTAR_TODAS_VERIFICACIONES.sh

echo "=========================================="
echo "  VERIFICACION COMPLETA DE WHATSAPP"
echo "=========================================="
echo ""

# 1. Verificar procesos PM2
echo "=== 1. PROCESOS PM2 ==="
if command -v pm2 &> /dev/null; then
    pm2 list
    echo ""
    echo "Detalles de procesos WhatsApp:"
    pm2 list | grep -E "whatsapp|name|status|online|errored" || echo "No se encontraron procesos WhatsApp"
else
    echo "PM2 no está instalado"
fi
echo ""

# 2. Verificar puertos activos
echo "=== 2. PUERTOS ACTIVOS ==="
for port in 3001 3002 3003 3004 4001 4002 4003 4004; do
    echo -n "Puerto $port: "
    if netstat -tulpn 2>/dev/null | grep -q ":$port " || ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo "✅ ACTIVO"
        netstat -tulpn 2>/dev/null | grep ":$port " || ss -tulpn 2>/dev/null | grep ":$port "
    else
        echo "❌ INACTIVO"
    fi
done
echo ""

# 3. Verificar estado de cada instancia vía API (Puertos 3001-3004)
echo "=== 3. ESTADO DE INSTANCIAS - PUERTOS 3001-3004 (API) ==="
HOST_IP="localhost"
for i in {1..4}; do
    port=$((3000 + i))
    echo "📱 WhatsApp $i (Puerto $port):"
    
    response=$(curl -s --max-time 5 "http://${HOST_IP}:${port}/api/status" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        if command -v jq &> /dev/null; then
            connected=$(echo "$response" | jq -r '.connected // false')
            phone=$(echo "$response" | jq -r '.phoneNumber // "-"')
            user=$(echo "$response" | jq -r '.userName // "-"')
            flor=$(echo "$response" | jq -r '.flor // "-"')
            whatsapp_status=$(echo "$response" | jq -r '.whatsapp // "-"')
            qr_available=$(echo "$response" | jq -r '.qrCode // empty')
            
            if [ "$connected" = "true" ]; then
                echo "   ✅ Estado: CONECTADO"
                echo "   📞 Teléfono: $phone"
                echo "   👤 Usuario: $user"
                echo "   🤖 Flor IA: $flor"
            elif [ ! -z "$qr_available" ]; then
                echo "   ⏳ Estado: ESPERANDO QR"
                echo "   📲 Código QR disponible"
            else
                echo "   ❌ Estado: DESCONECTADO"
                echo "   📝 WhatsApp: $whatsapp_status"
            fi
        else
            # Sin jq, verificación básica
            if echo "$response" | grep -q '"connected":true'; then
                echo "   ✅ Estado: CONECTADO"
                phone=$(echo "$response" | grep -o '"phoneNumber":"[^"]*"' | cut -d'"' -f4)
                echo "   📞 Teléfono: ${phone:--}"
            elif echo "$response" | grep -q '"qrCode"'; then
                echo "   ⏳ Estado: ESPERANDO QR"
            else
                echo "   ❌ Estado: DESCONECTADO"
            fi
        fi
    else
        echo "   ❌ NO RESPONDE (servicio no disponible)"
    fi
    echo ""
done

# 3b. Verificar estado de cada instancia vía API (Puertos 4001-4004 - PM2)
echo "=== 3b. ESTADO DE INSTANCIAS - PUERTOS 4001-4004 (PM2) ==="
HOST_IP="localhost"
for i in {1..4}; do
    port=$((4000 + i))
    echo "📱 WhatsApp $i (Puerto $port):"
    
    response=$(curl -s --max-time 5 "http://${HOST_IP}:${port}/api/status" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        if command -v jq &> /dev/null; then
            connected=$(echo "$response" | jq -r '.connected // false')
            phone=$(echo "$response" | jq -r '.phoneNumber // "-"')
            user=$(echo "$response" | jq -r '.userName // "-"')
            flor=$(echo "$response" | jq -r '.flor // "-"')
            whatsapp_status=$(echo "$response" | jq -r '.whatsapp // "-"')
            qr_available=$(echo "$response" | jq -r '.qrCode // empty')
            
            if [ "$connected" = "true" ]; then
                echo "   ✅ Estado: CONECTADO"
                echo "   📞 Teléfono: $phone"
                echo "   👤 Usuario: $user"
                echo "   🤖 Flor IA: $flor"
            elif [ ! -z "$qr_available" ]; then
                echo "   ⏳ Estado: ESPERANDO QR"
                echo "   📲 Código QR disponible"
            else
                echo "   ❌ Estado: DESCONECTADO"
                echo "   📝 WhatsApp: $whatsapp_status"
            fi
        else
            # Sin jq, verificación básica
            if echo "$response" | grep -q '"connected":true'; then
                echo "   ✅ Estado: CONECTADO"
                phone=$(echo "$response" | grep -o '"phoneNumber":"[^"]*"' | cut -d'"' -f4)
                echo "   📞 Teléfono: ${phone:--}"
            elif echo "$response" | grep -q '"qrCode"'; then
                echo "   ⏳ Estado: ESPERANDO QR"
            else
                echo "   ❌ Estado: DESCONECTADO"
            fi
        fi
    else
        echo "   ❌ NO RESPONDE (servicio no disponible)"
    fi
    echo ""
done

# 4. Verificar logs recientes
echo "=== 4. LOGS RECIENTES (si PM2 está disponible) ==="
if command -v pm2 &> /dev/null; then
    for i in {1..4}; do
        process_name="whatsapp-$i"
        if pm2 describe "$process_name" &>/dev/null; then
            echo "📋 Logs de $process_name (últimas 5 líneas):"
            pm2 logs "$process_name" --lines 5 --nostream 2>/dev/null || echo "   No hay logs disponibles"
            echo ""
        fi
    done
else
    echo "PM2 no disponible para ver logs"
fi

# 5. Resumen final
echo "=== RESUMEN FINAL ==="
echo "Para más detalles, ejecuta:"
echo "  - pm2 logs whatsapp-1 (o whatsapp-2, whatsapp-3, whatsapp-4)"
echo "  - pm2 describe whatsapp-1"
echo "  - curl http://localhost:3001/api/status"
echo ""

