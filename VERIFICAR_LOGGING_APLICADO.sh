#!/bin/bash
# Verificar que el logging mejorado se aplicó correctamente

echo "=========================================="
echo "VERIFICAR LOGGING MEJORADO APLICADO"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Verificar que el código tiene .select()
echo "=== 1. VERIFICAR CÓDIGO APLICADO ==="
echo ""
echo "Buscando .select() en el código:"
docker exec $CONTAINER_ID grep -A 5 "\.select()" /app/whatsapp-server-baileys.js | head -10
echo ""

echo "Buscando verificación de dataChat:"
docker exec $CONTAINER_ID grep -A 3 "dataChat.*length" /app/whatsapp-server-baileys.js | head -10
echo ""

# 2. Ver logs recientes (sin filtrar)
echo "=== 2. LOGS RECIENTES (últimos 50) ==="
echo ""
docker logs $CONTAINER_ID --tail 50 2>&1 | tail -30
echo ""

# 3. Esperar mensaje nuevo
echo "=== 3. ESPERANDO MENSAJE NUEVO ==="
echo ""
echo "Para ver el nuevo logging en acción:"
echo "1. Envía un mensaje de WhatsApp al bot"
echo "2. Luego ejecuta:"
echo "   docker logs $CONTAINER_ID --tail 50 | grep -E 'Error actualizando|Actualización.*no devolvió|Chat actualizado'"
echo ""

# 4. Monitorear en tiempo real
echo "=== 4. MONITOREAR EN TIEMPO REAL ==="
echo ""
echo "Para monitorear los logs en tiempo real, ejecuta:"
echo "   docker logs -f $CONTAINER_ID | grep -E 'Error actualizando|Actualización.*no devolvió|Chat actualizado|Mensaje guardado'"
echo ""
