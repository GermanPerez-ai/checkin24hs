#!/bin/bash
# Script para reiniciar el contenedor y verificar la corrección

echo "=========================================="
echo "REINICIAR CONTENEDOR Y VERIFICAR"
echo "=========================================="
echo ""

# Buscar contenedor (puede estar detenido)
CONTAINER_ID=$(docker ps -a | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar estado
echo "=== ESTADO ACTUAL ==="
echo ""
docker ps -a | grep $CONTAINER_ID
echo ""

# Verificar si está corriendo
STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER_ID)
if [ "$STATUS" != "running" ]; then
    echo "⚠️ Contenedor no está corriendo. Estado: $STATUS"
    echo ""
    echo "Iniciando contenedor..."
    docker start $CONTAINER_ID
    echo "✅ Contenedor iniciado"
    echo ""
    echo "Esperando 5 segundos para que inicie..."
    sleep 5
else
    echo "✅ Contenedor está corriendo"
    echo ""
fi

# Verificar que está corriendo ahora
echo "=== VERIFICAR ESTADO DESPUÉS DE INICIAR ==="
echo ""
docker ps | grep $CONTAINER_ID
echo ""

# Verificar código
echo "=== VERIFICAR CÓDIGO ==="
echo ""
echo "Buscando función obtenerOcrearChatId:"
docker exec $CONTAINER_ID grep -A 5 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | head -10
echo ""

# Verificar prioridad
echo "=== VERIFICAR PRIORIDAD ==="
echo ""
PRIORIDAD=$(docker exec $CONTAINER_ID grep -A 3 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | grep -iE "PRIMERO.*whatsapp_chats|PRIMERO.*whatsapp_conversations")
if [ -n "$PRIORIDAD" ]; then
    echo "Código encontrado:"
    echo "$PRIORIDAD"
    if echo "$PRIORIDAD" | grep -qi "whatsapp_chats"; then
        echo ""
        echo "✅ Corrección aplicada correctamente (prioriza whatsapp_chats)"
    else
        echo ""
        echo "❌ Aún prioriza whatsapp_conversations"
    fi
else
    echo "⚠️ No se encontró comentario de prioridad"
fi
echo ""

# Ver logs recientes
echo "=== LOGS RECIENTES ==="
echo ""
docker logs $CONTAINER_ID --tail 10
echo ""

echo "=========================================="
