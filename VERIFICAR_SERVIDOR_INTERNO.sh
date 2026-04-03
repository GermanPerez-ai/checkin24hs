#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO SERVIDOR INTERNO"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Verificar si el proceso Node.js está corriendo
echo "1️⃣ PROCESOS DENTRO DEL CONTENEDOR:"
echo "=========================================="
docker exec "$CONTAINER" ps aux | grep -E "node|npm" || echo "❌ No se encontró proceso Node.js"
echo ""

# Verificar puerto 3001 (puerto interno del contenedor)
echo "2️⃣ PUERTOS ESCUCHANDO:"
echo "=========================================="
docker exec "$CONTAINER" netstat -tlnp 2>/dev/null | grep -E "3001|3000|LISTEN" || echo "Verificando con otro método..."
docker exec "$CONTAINER" ss -tlnp 2>/dev/null | grep -E "3001|3000|LISTEN" || echo "No se pudo verificar puertos"
echo ""

# Verificar si el servidor responde usando wget o node
echo "3️⃣ PROBAR CONEXIÓN INTERNA:"
echo "=========================================="
# Intentar con wget
docker exec "$CONTAINER" wget -q -O- http://localhost:3001/api/status?card=1 2>&1 | head -5 || \
# Intentar con node
docker exec "$CONTAINER" node -e "const http = require('http'); http.get('http://localhost:3001/api/status?card=1', (res) => { let data = ''; res.on('data', (chunk) => { data += chunk; }); res.on('end', () => { console.log('✅ Servidor responde:', res.statusCode); console.log(data.substring(0, 200)); }); }).on('error', (e) => { console.error('❌ Error:', e.message); });" 2>&1 || \
echo "❌ No se pudo verificar la conexión"
echo ""

# Verificar logs de errores recientes
echo "4️⃣ ERRORES EN LOGS:"
echo "=========================================="
docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "error\|failed\|exception\|cannot\|eaddrinuse\|port.*in use" | tail -10
echo ""

# Verificar archivo del servidor
echo "5️⃣ VERIFICAR ARCHIVO DEL SERVIDOR:"
echo "=========================================="
docker exec "$CONTAINER" ls -la /app/whatsapp-server.js 2>/dev/null || echo "❌ Archivo no encontrado"
echo ""

# Verificar variables de entorno
echo "6️⃣ VARIABLES DE ENTORNO:"
echo "=========================================="
docker exec "$CONTAINER" env | grep -E "PORT|NODE|INSTANCE" | head -10
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO:"
echo "=========================================="
echo ""
echo "Si el proceso Node.js no está corriendo:"
echo "  - El servidor no se inició correctamente"
echo "  - Revisa los logs: docker logs $CONTAINER --tail 50"
echo ""
echo "Si el puerto no está escuchando:"
echo "  - El servidor no está escuchando en el puerto correcto"
echo "  - Verifica la configuración del puerto en whatsapp-server.js"
echo ""
echo "Si hay errores en los logs:"
echo "  - Revisa los errores específicos arriba"
echo "  - Puede ser un problema de dependencias o configuración"
echo ""



