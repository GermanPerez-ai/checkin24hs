#!/bin/bash
# 🔍 Verificar si el servidor está bloqueado

echo "=============================================================="
echo "🔍 VERIFICANDO SI EL SERVIDOR ESTÁ BLOQUEADO"
echo "=============================================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

# 1. Verificar si el puerto está escuchando dentro del contenedor
echo "1️⃣  Verificando si el puerto 3001 está escuchando dentro del contenedor:"
docker exec $CONTAINER_ID sh -c "netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo 'Puerto no encontrado'" 2>/dev/null
echo ""

# 2. Verificar procesos Node.js y su estado
echo "2️⃣  Procesos Node.js:"
docker top $CONTAINER_ID 2>/dev/null | grep node
echo ""

# 3. Ver logs más recientes buscando errores
echo "3️⃣  Logs recientes (últimos 10):"
docker logs $CONTAINER_ID --tail 10 2>&1
echo ""

# 4. Verificar si el archivo en el contenedor es el correcto
echo "4️⃣  Verificando función start() en el contenedor:"
docker exec $CONTAINER_ID sh -c "grep -A 5 'Iniciar servidor HTTP PRIMERO' /app/whatsapp-server-baileys.js" 2>/dev/null | head -3
echo ""

# 5. Intentar ejecutar un comando simple dentro del contenedor para verificar conectividad
echo "5️⃣  Verificando conectividad básica del contenedor:"
docker exec $CONTAINER_ID sh -c "echo 'Contenedor responde'" 2>/dev/null && echo "   ✅ Contenedor responde" || echo "   ❌ Contenedor no responde"
echo ""

# 6. Verificar si hay algún proceso bloqueado
echo "6️⃣  Verificando si hay procesos bloqueados (usando lsof si está disponible):"
docker exec $CONTAINER_ID sh -c "lsof -i :3001 2>/dev/null || echo 'lsof no disponible'" 2>/dev/null
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
