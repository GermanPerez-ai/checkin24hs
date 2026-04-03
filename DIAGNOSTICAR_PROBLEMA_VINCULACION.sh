#!/bin/bash
# Diagnóstico completo para problemas de vinculación WhatsApp
# "Intente más tarde" o problemas al escanear QR

SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"

echo "=========================================="
echo "🔍 DIAGNÓSTICO: PROBLEMA DE VINCULACIÓN"
echo "=========================================="
echo ""

# 1. Verificar estado del servicio
echo "1️⃣  ESTADO DEL SERVICIO"
echo "=========================================="
SERVICE_STATUS=$(docker service ps $SERVICE_NAME --format "{{.CurrentState}}" --no-trunc | head -1)
echo "Estado: $SERVICE_STATUS"
echo ""

# 2. Ver logs recientes (últimas 100 líneas)
echo "2️⃣  LOGS RECIENTES (últimas 100 líneas)"
echo "=========================================="
docker service logs $SERVICE_NAME --tail 100 --no-trunc 2>&1 | tail -100
echo ""

# 3. Buscar errores específicos
echo "3️⃣  ERRORES ESPECÍFICOS"
echo "=========================================="

echo "📌 Error 428 (Connection Terminated):"
ERROR_428=$(docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -i "428\|Connection Terminated" | tail -5)
if [ -n "$ERROR_428" ]; then
    echo "$ERROR_428"
    echo ""
    echo "   ⚠️  Error 428 es común durante autenticación"
    echo "   💡 Si aparece muchas veces, puede indicar problemas de red o timeout"
else
    echo "   ✅ No se encontraron errores 428 recientes"
fi
echo ""

echo "📌 Errores de autenticación:"
ERROR_AUTH=$(docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -iE "auth.*fail|login.*fail|autenticación.*fall|device.*removed|conflict" | tail -5)
if [ -n "$ERROR_AUTH" ]; then
    echo "$ERROR_AUTH"
else
    echo "   ✅ No se encontraron errores de autenticación"
fi
echo ""

echo "📌 Timeouts:"
ERROR_TIMEOUT=$(docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -iE "timeout|timed.*out|expired" | tail -5)
if [ -n "$ERROR_TIMEOUT" ]; then
    echo "$ERROR_TIMEOUT"
else
    echo "   ✅ No se encontraron timeouts recientes"
fi
echo ""

echo "📌 Mensajes sobre QR:"
QR_MESSAGES=$(docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -iE "qr|escaneado|scan|waiting.*scan" | tail -10)
if [ -n "$QR_MESSAGES" ]; then
    echo "$QR_MESSAGES"
else
    echo "   ⚠️  No se encontraron mensajes sobre QR"
fi
echo ""

# 4. Verificar estado de conexión actual
echo "4️⃣  ESTADO DE CONEXIÓN ACTUAL"
echo "=========================================="
STATUS_RESPONSE=$(curl -s --max-time 5 "https://${DOMAIN}/api/status" 2>/dev/null)
if [ -n "$STATUS_RESPONSE" ]; then
    if echo "$STATUS_RESPONSE" | grep -q "connected"; then
        echo "✅ WhatsApp está conectado"
    elif echo "$STATUS_RESPONSE" | grep -q "waiting_scan"; then
        echo "⏳ Esperando escaneo de QR"
    else
        echo "Estado: $STATUS_RESPONSE"
    fi
else
    echo "❌ No se pudo obtener el estado"
fi
echo ""

# 5. Verificar si hay sesión guardada
echo "5️⃣  VERIFICAR SESIÓN GUARDADA"
echo "=========================================="
CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)
if [ -n "$CONTAINER_ID" ]; then
    AUTH_FILES=$(docker exec $CONTAINER_ID ls -la /app/auth_info_baileys_1 2>/dev/null | wc -l)
    if [ "$AUTH_FILES" -gt 3 ]; then
        echo "✅ Hay archivos de autenticación guardados"
        echo "   💡 Si el problema persiste, intenta limpiar la sesión:"
        echo "      docker exec $CONTAINER_ID rm -rf /app/auth_info_baileys_1"
        echo "      docker service update --force $SERVICE_NAME"
    else
        echo "⚠️  No hay archivos de autenticación guardados"
        echo "   💡 Esto es normal si nunca se ha escaneado el QR"
    fi
else
    echo "⚠️  No se pudo encontrar el contenedor"
fi
echo ""

# 6. Recomendaciones
echo "=========================================="
echo "💡 RECOMENDACIONES"
echo "=========================================="
echo ""

# Contar errores 428
ERROR_428_COUNT=$(docker service logs $SERVICE_NAME --tail 500 --no-trunc 2>&1 | grep -c "428\|Connection Terminated" || echo "0")

if [ "$ERROR_428_COUNT" -gt 10 ]; then
    echo "❌ PROBLEMA DETECTADO: Muchos errores 428"
    echo ""
    echo "Soluciones:"
    echo "1. Limpiar sesión y generar nuevo QR:"
    echo "   docker exec \$(docker ps --filter 'name=${SERVICE_NAME}' --format '{{.ID}}' | head -1) rm -rf /app/auth_info_baileys_1"
    echo "   docker service update --force $SERVICE_NAME"
    echo ""
    echo "2. Verificar conectividad de red:"
    echo "   ping -c 5 web.whatsapp.com"
    echo ""
    echo "3. Esperar 5-10 minutos y reintentar"
elif [ "$ERROR_428_COUNT" -gt 0 ]; then
    echo "⚠️  Se encontraron algunos errores 428 (normal durante autenticación)"
    echo ""
    echo "Si el problema persiste:"
    echo "1. Espera 2-3 minutos después de escanear el QR"
    echo "2. Si no conecta, limpia la sesión y genera un nuevo QR"
    echo "3. Escanea el QR inmediatamente después de generarse (dentro de 2 minutos)"
else
    echo "✅ No se encontraron errores críticos en los logs"
    echo ""
    echo "Si el problema persiste:"
    echo "1. Verifica que el QR no haya expirado (se regenera cada 2 minutos)"
    echo "2. Asegúrate de escanear el QR dentro de 2 minutos de generarse"
    echo "3. Verifica que no haya otra sesión activa en otro dispositivo"
fi

echo ""
echo "=========================================="
echo "📋 Para ver logs en tiempo real:"
echo "   docker service logs -f $SERVICE_NAME"
echo "=========================================="
