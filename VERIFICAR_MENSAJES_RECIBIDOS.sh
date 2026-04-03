#!/bin/bash
# Verificar si se están recibiendo mensajes de WhatsApp

CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor de WhatsApp"
    exit 1
fi

echo "=========================================="
echo "VERIFICAR MENSAJES RECIBIDOS"
echo "=========================================="
echo ""
echo "Contenedor: $CONTAINER_ID"
echo ""

# 1. Ver logs completos recientes (últimos 5 minutos)
echo "1. Logs completos (últimos 5 minutos)..."
echo ""
docker logs $CONTAINER_ID --since 5m | tail -50
echo ""

# 2. Buscar cualquier mención de mensaje
echo "2. Buscando menciones de mensajes..."
echo ""
docker logs $CONTAINER_ID --since 5m | grep -iE "message|mensaje|recib|recibido|incoming|handleMessage|update.*message" | tail -20
echo ""

# 3. Ver si hay eventos de actualización
echo "3. Buscando eventos de actualización..."
echo ""
docker logs $CONTAINER_ID --since 5m | grep -iE "update|event|notification" | tail -20
echo ""

# 4. Ver errores
echo "4. Errores recientes..."
echo ""
docker logs $CONTAINER_ID --since 5m | grep -iE "error|❌|⚠️|fail" | tail -20
echo ""

echo "=========================================="
echo "VERIFICACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📋 Si no ves mensajes recibidos, prueba enviar un mensaje ahora y ejecuta de nuevo."
echo ""
