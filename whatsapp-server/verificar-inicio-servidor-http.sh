#!/bin/bash
# 🔍 Verificar si el servidor HTTP inició correctamente

echo "=============================================================="
echo "🔍 VERIFICANDO INICIO DEL SERVIDOR HTTP"
echo "=============================================================="
echo ""

# 1. Buscar mensaje de inicio del servidor en todos los logs
echo "1️⃣  Buscando mensaje 'Servidor iniciado' en logs..."
docker service logs checkin24hs_whatsapp 2>&1 | grep -i "Servidor iniciado" | tail -5
if [ $? -eq 0 ]; then
    echo "   ✅ Se encontró mensaje de inicio"
else
    echo "   ❌ NO se encontró mensaje de inicio del servidor HTTP"
fi
echo ""

# 2. Ver logs desde el inicio del contenedor actual
echo "2️⃣  Verificando contenedor actual..."
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "   Contenedor: $CONTAINER_ID"
echo ""

# 3. Ver logs del contenedor actual desde su inicio
echo "3️⃣  Logs del contenedor actual (desde inicio):"
docker logs $CONTAINER_ID 2>&1 | head -30
echo ""

# 4. Buscar errores de inicio
echo "4️⃣  Buscando errores de inicio..."
docker logs $CONTAINER_ID 2>&1 | grep -iE "error|exception|failed|Servidor iniciado|Iniciando servidor" | head -10
echo ""

# 5. Verificar si hay un proceso escuchando en el puerto (desde el host)
echo "5️⃣  Verificando puerto 3001 desde el host:"
netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo "   ⚠️  Puerto 3001 no está escuchando en el host"
echo ""

# 6. Intentar conexión directa
echo "6️⃣  Intentando conexión directa al puerto 3001:"
timeout 5 bash -c "echo > /dev/tcp/localhost/3001" 2>/dev/null && echo "   ✅ Puerto 3001 está abierto" || echo "   ❌ Puerto 3001 no está accesible"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
