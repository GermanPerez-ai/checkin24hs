#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNOSTICANDO PROBLEMA DE QR WHATSAPP"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp instancia 1
echo "1️⃣ Buscando contenedor de WhatsApp instancia 1..."
echo "----------------------------------------"
WHATSAPP_CONTAINER=$(docker ps --filter "name=whatsapp" --filter "label=com.docker.swarm.service.name=checkin24hs_whatsapp" --format "{{.ID}}\t{{.Names}}" | head -1)

if [ -z "$WHATSAPP_CONTAINER" ]; then
    WHATSAPP_CONTAINER=$(docker ps --filter "name=whatsapp" --format "{{.ID}}\t{{.Names}}" | head -1)
fi

if [ -z "$WHATSAPP_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

CONTAINER_ID=$(echo "$WHATSAPP_CONTAINER" | awk '{print $1}')
CONTAINER_NAME=$(echo "$WHATSAPP_CONTAINER" | awk '{print $2}')

echo "✅ Contenedor encontrado: $CONTAINER_NAME ($CONTAINER_ID)"
echo ""

# 2. Verificar estado del servicio
echo "2️⃣ Estado del servicio:"
echo "----------------------------------------"
docker service ps checkin24hs_whatsapp --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}" | head -5
echo ""

# 3. Verificar estado de conexión actual
echo "3️⃣ Estado de conexión actual:"
echo "----------------------------------------"
echo "📊 Verificando endpoint /api/status..."
STATUS_RESPONSE=$(docker exec "$CONTAINER_ID" curl -s http://localhost:3001/api/status 2>/dev/null || echo "{}")
echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
echo ""

# 4. Revisar logs de los últimos 10 minutos
echo "4️⃣ Logs de los últimos 10 minutos (eventos importantes):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 10m 2>&1 | grep -iE "qr|connecting|open|close|error|timeout|device_removed|428|401|515|autenticacion|sincronizacion|app state" | tail -50
echo ""

# 5. Timeline completo de eventos recientes
echo "5️⃣ Timeline completo de eventos (últimos 5 minutos):"
echo "----------------------------------------"
echo "📱 Eventos de QR:"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | grep -i "qr" | tail -10
echo ""

echo "🔄 Eventos de conexión:"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | grep -iE "connecting|open|close" | tail -10
echo ""

echo "❌ Errores:"
docker logs "$CONTAINER_ID" --since 5m 2>&1 | grep -iE "error|timeout|failed|device_removed|428|401|515" | tail -20
echo ""

# 6. Verificar si hay sesiones guardadas
echo "6️⃣ Verificando sesiones guardadas:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" ls -la /app/auth_info_baileys_1/ 2>/dev/null | head -10 || echo "   No se encontró directorio de sesión"
echo ""

# 7. Verificar errores específicos de autenticación
echo "7️⃣ Errores específicos de autenticación:"
echo "----------------------------------------"
echo "🔍 Buscando errores 428 (Connection Terminated):"
docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -i "428\|Connection Terminated" | tail -10
echo ""

echo "🔍 Buscando errores 401 (device_removed):"
docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -i "401\|device_removed" | tail -10
echo ""

echo "🔍 Buscando timeouts:"
docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -i "timeout\|Timed Out" | tail -10
echo ""

# 8. Verificar sincronización del app state
echo "8️⃣ Eventos de sincronización del app state:"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -iE "app state|syncing|resyncing" | tail -20
echo ""

# 9. Verificar tiempo transcurrido desde el último QR
echo "9️⃣ Tiempo desde el último QR:"
echo "----------------------------------------"
LAST_QR=$(docker logs "$CONTAINER_ID" --since 1h 2>&1 | grep -i "QR Code recibido\|QR Code generado" | tail -1)
if [ -n "$LAST_QR" ]; then
    echo "📱 Último QR:"
    echo "$LAST_QR"
    echo ""
    # Intentar extraer timestamp si está disponible
    QR_TIME=$(echo "$LAST_QR" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}" | head -1)
    if [ -n "$QR_TIME" ]; then
        echo "   Timestamp: $QR_TIME"
    fi
else
    echo "⚠️  No se encontró QR reciente"
fi
echo ""

# 10. Resumen y diagnóstico
echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""

# Contar errores
ERROR_428=$(docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -c "428\|Connection Terminated")
ERROR_401=$(docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -c "401\|device_removed")
ERROR_TIMEOUT=$(docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -c "timeout\|Timed Out")

if [ "$ERROR_428" -gt 0 ]; then
    echo "⚠️  Se encontraron $ERROR_428 errores 428 (Connection Terminated)"
    echo "   Esto indica que WhatsApp está cerrando la conexión durante la autenticación"
    echo "   Posibles causas:"
    echo "   - Demasiados intentos en poco tiempo"
    echo "   - La autenticación está tardando más de lo permitido"
    echo "   - Hay sesiones 'fantasma' activas en el teléfono"
fi

if [ "$ERROR_401" -gt 0 ]; then
    echo "⚠️  Se encontraron $ERROR_401 errores 401 (device_removed)"
    echo "   Esto indica que WhatsApp detecta múltiples sesiones"
    echo "   Solución: Limpiar todas las sesiones en el teléfono"
fi

if [ "$ERROR_TIMEOUT" -gt 0 ]; then
    echo "⚠️  Se encontraron $ERROR_TIMEOUT timeouts"
    echo "   Esto indica que la conexión está tardando demasiado"
fi

echo ""
echo "📋 Recomendaciones:"
echo "   1. Espera 20-30 minutos desde el último intento"
echo "   2. En el teléfono: WhatsApp → Dispositivos vinculados → Cerrar todas las sesiones"
echo "   3. Reinicia el teléfono"
echo "   4. Limpia la sesión del servidor: ./LIMPIAR_SESION_INSTANCIA_1.sh"
echo "   5. Espera otros 5 minutos"
echo "   6. Escanea el QR UNA SOLA VEZ y espera pacientemente (puede tardar 2-3 minutos)"
echo ""
