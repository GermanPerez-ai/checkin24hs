#!/bin/bash
# 🔍 Diagnosticar por qué el servidor no está escuchando

echo "=============================================================="
echo "🔍 DIAGNÓSTICO: SERVIDOR NO ESTÁ ESCUCHANDO"
echo "=============================================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

# 1. Ver TODOS los logs desde el inicio del contenedor
echo "1️⃣  Logs completos desde el inicio:"
docker logs $CONTAINER_ID 2>&1 | grep -E "Servidor iniciado|Iniciando servidor|Error|error|exception|listen" | head -20
echo ""

# 2. Verificar si el servidor realmente inició
echo "2️⃣  Buscando mensaje 'Servidor iniciado':"
docker logs $CONTAINER_ID 2>&1 | grep "Servidor iniciado"
if [ $? -eq 0 ]; then
    echo "   ✅ Servidor inició correctamente"
else
    echo "   ❌ Servidor NO inició (no se encontró el mensaje)"
fi
echo ""

# 3. Verificar si hay errores al iniciar
echo "3️⃣  Errores al iniciar:"
docker logs $CONTAINER_ID 2>&1 | grep -iE "error|exception|failed" | head -10
echo ""

# 4. Verificar el código que se está ejecutando
echo "4️⃣  Verificando código en el contenedor (líneas alrededor de server.listen):"
docker exec $CONTAINER_ID sh -c "grep -n 'server.listen' /app/whatsapp-server-baileys.js" 2>/dev/null
docker exec $CONTAINER_ID sh -c "sed -n '1215,1230p' /app/whatsapp-server-baileys.js" 2>/dev/null
echo ""

# 5. Verificar si hay algún problema con el callback de server.listen
echo "5️⃣  Verificando si el callback de server.listen se ejecuta:"
docker logs $CONTAINER_ID 2>&1 | grep -E "Servidor iniciado|Instancia WhatsApp|Servidor escuchando"
echo ""

# 6. Verificar variables de entorno
echo "6️⃣  Variables de entorno:"
docker exec $CONTAINER_ID sh -c "env | grep -E 'PORT|INSTANCE_NUMBER'" 2>/dev/null
echo ""

# 7. Intentar ver si hay algún proceso escuchando
echo "7️⃣  Procesos y puertos:"
docker exec $CONTAINER_ID sh -c "netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || echo 'No se puede verificar puertos'" 2>/dev/null
echo ""

echo "=============================================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=============================================================="
echo ""
