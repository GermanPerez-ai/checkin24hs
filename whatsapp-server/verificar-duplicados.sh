#!/bin/bash
# 🔍 Verificar funciones duplicadas

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

echo "=============================================================="
echo "🔍 VERIFICANDO FUNCIONES DUPLICADAS"
echo "=============================================================="
echo ""

# Buscar todas las funciones start
echo "1️⃣  Buscando todas las funciones start()..."
docker exec $CONTAINER_ID sh -c "grep -n 'async function start' /app/whatsapp-server-baileys.js"
echo ""

# Ver contexto alrededor de cada función start
echo "2️⃣  Contexto de cada función start..."
for line in $(docker exec $CONTAINER_ID sh -c "grep -n 'async function start' /app/whatsapp-server-baileys.js" | cut -d: -f1); do
    echo "   Función start() en línea $line:"
    docker exec $CONTAINER_ID sh -c "sed -n '$((line - 2)),$((line + 5))p' /app/whatsapp-server-baileys.js"
    echo ""
done

# Ver si hay código duplicado al final del archivo
echo "3️⃣  Últimas 20 líneas del archivo..."
docker exec $CONTAINER_ID sh -c "tail -20 /app/whatsapp-server-baileys.js"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
