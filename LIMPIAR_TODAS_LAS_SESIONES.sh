#!/bin/bash

echo "=========================================="
echo "🧹 LIMPIANDO TODAS LAS SESIONES DE WHATSAPP"
echo "=========================================="
echo ""

read -p "⚠️  Esto eliminará TODAS las sesiones de WhatsApp. ¿Continuar? (s/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Operación cancelada"
    exit 1
fi

echo ""

# 1. Encontrar todos los contenedores
CONTAINERS=$(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}")

if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores de WhatsApp"
    exit 1
fi

echo "✅ Contenedores encontrados:"
for CONTAINER_ID in $CONTAINERS; do
    echo "   - $CONTAINER_ID"
done
echo ""

# 2. Limpiar sesiones en cada contenedor
for CONTAINER_ID in $CONTAINERS; do
    echo "📦 Limpiando sesiones en contenedor: $CONTAINER_ID"
    
    # Encontrar todos los directorios de autenticación
    AUTH_DIRS=$(docker exec "$CONTAINER_ID" sh -c "ls -d /app/auth_info_baileys_* 2>/dev/null")
    
    if [ -z "$AUTH_DIRS" ]; then
        echo "   ⚠️  No se encontraron directorios de autenticación"
    else
        for AUTH_DIR in $AUTH_DIRS; do
            echo "   🗑️  Eliminando: $AUTH_DIR"
            docker exec "$CONTAINER_ID" sh -c "rm -rf $AUTH_DIR/* 2>/dev/null && echo '   ✅ Limpiado' || echo '   ⚠️  Error al limpiar'"
        done
    fi
    echo ""
done

# 3. Reiniciar servicios para aplicar cambios
echo "3️⃣ Reiniciando servicios para aplicar cambios:"
echo "----------------------------------------"
SERVICES=$(docker service ls --filter "name=checkin24hs_whatsapp" --format "{{.Name}}")

for SERVICE_NAME in $SERVICES; do
    echo "🔄 Reiniciando servicio: $SERVICE_NAME"
    docker service update --force "$SERVICE_NAME" 2>&1 | grep -E "(updated|converged)" || echo "   ⚠️  Error al reiniciar"
    echo ""
done

echo "⏳ Esperando 30 segundos para que los servicios se reinicien..."
sleep 30

# 4. Verificar que las sesiones fueron limpiadas
echo "4️⃣ Verificando que las sesiones fueron limpiadas:"
echo "----------------------------------------"
for CONTAINER_ID in $(docker ps --filter "name=checkin24hs_whatsapp" --format "{{.ID}}"); do
    echo "📦 Contenedor: $CONTAINER_ID"
    AUTH_DIRS=$(docker exec "$CONTAINER_ID" sh -c "ls -d /app/auth_info_baileys_* 2>/dev/null")
    if [ -z "$AUTH_DIRS" ]; then
        echo "   ✅ No hay directorios de autenticación (esperado después de limpiar)"
    else
        for AUTH_DIR in $AUTH_DIRS; do
            FILE_COUNT=$(docker exec "$CONTAINER_ID" sh -c "find $AUTH_DIR -type f 2>/dev/null | wc -l")
            if [ "$FILE_COUNT" -eq "0" ]; then
                echo "   ✅ $AUTH_DIR está vacío"
            else
                echo "   ⚠️  $AUTH_DIR todavía tiene $FILE_COUNT archivo(s)"
            fi
        done
    fi
    echo ""
done

echo "=========================================="
echo "✅ LIMPIEZA COMPLETA"
echo "=========================================="
echo ""
echo "✅ Todas las sesiones han sido limpiadas"
echo "✅ Los servicios han sido reiniciados"
echo ""
echo "💡 Ahora puedes:"
echo "   1. Esperar 30-60 segundos más"
echo "   2. Abrir https://api1.checkin24hs.com/"
echo "   3. Escanear el nuevo QR code"
echo "   4. Asegurarte de que NO hay WhatsApp Web abierto"
echo "   5. Asegurarte de que NO hay otros dispositivos vinculados"
echo ""
