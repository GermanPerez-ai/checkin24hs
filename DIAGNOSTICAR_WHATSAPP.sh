#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNÓSTICO DE SERVIDOR WHATSAPP"
echo "=========================================="
echo ""

# 1. Verificar contenedores
echo "1️⃣ CONTENEDORES DE WHATSAPP:"
echo "=========================================="
docker ps --filter "name=whatsapp" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 2. Verificar logs del contenedor principal
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "2️⃣ LOGS DEL CONTENEDOR PRINCIPAL ($CONTAINER):"
    echo "=========================================="
    echo "Últimas 20 líneas:"
    docker logs "$CONTAINER" --tail 20 2>&1
    echo ""
    
    echo "3️⃣ ERRORES RECIENTES:"
    echo "=========================================="
    docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "error\|failed\|exception\|502\|crash\|killed" | tail -10
    echo ""
    
    echo "4️⃣ ESTADO DE CONEXIÓN WHATSAPP:"
    echo "=========================================="
    docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "connected\|ready\|qr\|scan\|authenticated" | tail -10
    echo ""
    
    echo "5️⃣ VERIFICAR PROCESO DENTRO DEL CONTENEDOR:"
    echo "=========================================="
    docker exec "$CONTAINER" ps aux 2>/dev/null | head -10 || echo "No se pudo acceder al contenedor"
    echo ""
    
    echo "6️⃣ VERIFICAR PUERTO DEL SERVIDOR:"
    echo "=========================================="
    docker exec "$CONTAINER" netstat -tlnp 2>/dev/null | grep -E "3000|8080|80" || echo "No se pudo verificar puertos"
    echo ""
else
    echo "❌ No se encontró contenedor de WhatsApp 1"
fi

# 7. Verificar respuesta del servidor desde fuera
echo "7️⃣ VERIFICAR RESPUESTA DEL SERVIDOR:"
echo "=========================================="
echo "Probando https://api1.checkin24hs.com/api/status?card=1"
curl -I -k --max-time 5 https://api1.checkin24hs.com/api/status?card=1 2>&1 | head -5 || echo "❌ No se pudo conectar al servidor"
echo ""

echo "=========================================="
echo "📋 ACCIONES RECOMENDADAS:"
echo "=========================================="
echo ""
echo "Si el servidor está caído:"
echo "  1. Reiniciar contenedor: docker restart $CONTAINER"
echo "  2. Ver logs en tiempo real: docker logs $CONTAINER -f"
echo ""
echo "Si el servidor está corriendo pero no responde:"
echo "  1. Verificar configuración de nginx/proxy"
echo "  2. Verificar que el puerto esté expuesto correctamente"
echo "  3. Verificar firewall"
echo ""
