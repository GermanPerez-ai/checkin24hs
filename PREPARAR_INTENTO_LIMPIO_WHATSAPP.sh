#!/bin/bash

echo "=========================================="
echo "🧹 PREPARANDO INTENTO LIMPIO DE WHATSAPP"
echo "=========================================="
echo ""

INSTANCE_NUMBER=1
SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar contenedor
echo "1️⃣ Verificando contenedor de WhatsApp instancia $INSTANCE_NUMBER..."
echo "----------------------------------------"
WHATSAPP_CONTAINER=$(docker ps --filter "name=whatsapp" --format "{{.ID}}\t{{.Names}}" | head -1)

if [ -z "$WHATSAPP_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

CONTAINER_ID=$(echo "$WHATSAPP_CONTAINER" | awk '{print $1}')
CONTAINER_NAME=$(echo "$WHATSAPP_CONTAINER" | awk '{print $2}')

echo "✅ Contenedor encontrado: $CONTAINER_NAME ($CONTAINER_ID)"
echo ""

# 2. Limpiar sesión
echo "2️⃣ Limpiando sesión de autenticación..."
echo "----------------------------------------"
AUTH_DIR="/app/auth_info_baileys_$INSTANCE_NUMBER"

if docker exec "$CONTAINER_ID" test -d "$AUTH_DIR" 2>/dev/null; then
    echo "📁 Directorio de sesión encontrado: $AUTH_DIR"
    
    # Contar archivos antes de limpiar
    FILE_COUNT=$(docker exec "$CONTAINER_ID" find "$AUTH_DIR" -type f 2>/dev/null | wc -l)
    echo "   Archivos encontrados: $FILE_COUNT"
    
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "   🗑️  Eliminando archivos de sesión..."
        docker exec "$CONTAINER_ID" rm -rf "$AUTH_DIR"/* 2>/dev/null
        docker exec "$CONTAINER_ID" rm -rf "$AUTH_DIR"/.* 2>/dev/null 2>&1 || true
        
        # Verificar que esté vacío
        REMAINING=$(docker exec "$CONTAINER_ID" find "$AUTH_DIR" -type f 2>/dev/null | wc -l)
        if [ "$REMAINING" -eq 0 ]; then
            echo "   ✅ Sesión limpiada correctamente"
        else
            echo "   ⚠️  Aún quedan $REMAINING archivos"
        fi
    else
        echo "   ✅ El directorio ya está vacío"
    fi
else
    echo "   ⚠️  No se encontró directorio de sesión (puede ser normal si es la primera vez)"
fi
echo ""

# 3. Verificar errores recientes
echo "3️⃣ Verificando errores recientes..."
echo "----------------------------------------"
ERROR_428=$(docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -c "428\|Connection Terminated")
ERROR_401=$(docker logs "$CONTAINER_ID" --since 30m 2>&1 | grep -c "401\|device_removed")

if [ "$ERROR_428" -gt 0 ]; then
    echo "⚠️  Se encontraron $ERROR_428 errores 428 en los últimos 30 minutos"
    echo "   WhatsApp está bloqueando temporalmente"
fi

if [ "$ERROR_401" -gt 0 ]; then
    echo "⚠️  Se encontraron $ERROR_401 errores 401 en los últimos 30 minutos"
    echo "   WhatsApp detecta múltiples sesiones"
fi

if [ "$ERROR_428" -eq 0 ] && [ "$ERROR_401" -eq 0 ]; then
    echo "✅ No se encontraron errores recientes"
fi
echo ""

# 4. Reiniciar servicio
echo "4️⃣ Reiniciando servicio para aplicar cambios..."
echo "----------------------------------------"
docker service update --force "$SERVICE_NAME" 2>&1 | grep -v "verify:"
echo ""
echo "⏳ Esperando 30 segundos para que el servicio se reinicie..."
sleep 30
echo "✅ Servicio reiniciado"
echo ""

# 5. Verificar nuevo contenedor
echo "5️⃣ Verificando nuevo contenedor..."
echo "----------------------------------------"
NEW_CONTAINER=$(docker ps --filter "name=whatsapp" --format "{{.ID}}\t{{.Names}}" | head -1)
NEW_CONTAINER_ID=$(echo "$NEW_CONTAINER" | awk '{print $1}')

if [ -n "$NEW_CONTAINER_ID" ]; then
    echo "✅ Nuevo contenedor: $NEW_CONTAINER_ID"
    
    # Verificar que la sesión esté limpia
    if docker exec "$NEW_CONTAINER_ID" test -d "$AUTH_DIR" 2>/dev/null; then
        REMAINING_FILES=$(docker exec "$NEW_CONTAINER_ID" find "$AUTH_DIR" -type f 2>/dev/null | wc -l)
        if [ "$REMAINING_FILES" -eq 0 ]; then
            echo "✅ Sesión limpia confirmada"
        else
            echo "⚠️  Aún quedan $REMAINING_FILES archivos en la sesión"
        fi
    fi
else
    echo "⚠️  No se pudo verificar el nuevo contenedor"
fi
echo ""

# 6. Verificar estado del servicio
echo "6️⃣ Estado del servicio:"
echo "----------------------------------------"
sleep 5
docker service ps "$SERVICE_NAME" --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}" | head -3
echo ""

echo "=========================================="
echo "✅ PREPARACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 PRÓXIMOS PASOS IMPORTANTES:"
echo ""
echo "1️⃣ ESPERA 20-30 MINUTOS desde ahora"
echo "   ⏰ WhatsApp necesita tiempo para desbloquear la cuenta"
echo "   ⏰ No intentes escanear el QR antes de este tiempo"
echo ""
echo "2️⃣ EN EL TELÉFONO (MUY IMPORTANTE):"
echo "   📱 Abre WhatsApp"
echo "   📱 Ve a: Configuración → Dispositivos vinculados"
echo "   📱 Cierra TODAS las sesiones (toca en cada una y 'Cerrar sesión')"
echo "   📱 Reinicia el teléfono completamente"
echo ""
echo "3️⃣ DESPUÉS DE ESPERAR 20-30 MINUTOS:"
echo "   🌐 Abre: https://api1.checkin24hs.com/"
echo "   📱 Escanea el QR UNA SOLA VEZ"
echo "   ⏳ Espera pacientemente 2-3 minutos (NO cierres la página)"
echo "   ⏳ NO escanees el QR de nuevo aunque tarde"
echo ""
echo "4️⃣ SI FALLA:"
echo "   ⏰ Espera otros 30 minutos"
echo "   🧹 Ejecuta este script de nuevo: ./PREPARAR_INTENTO_LIMPIO_WHATSAPP.sh"
echo "   📱 Verifica que NO haya sesiones activas en el teléfono"
echo ""
echo "💡 RECUERDA:"
echo "   - WhatsApp bloquea temporalmente por demasiados intentos"
echo "   - El tiempo de espera es CRÍTICO (20-30 minutos mínimo)"
echo "   - Solo UN intento después de esperar"
echo "   - La autenticación puede tardar 2-3 minutos"
echo ""
