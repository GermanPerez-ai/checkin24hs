#!/bin/bash
# 🔍 Probar el servidor desde dentro del contenedor

echo "=============================================================="
echo "🔍 PROBANDO SERVIDOR DESDE DENTRO DEL CONTENEDOR"
echo "=============================================================="
echo ""

CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)

# 1. Intentar conexión usando wget o curl desde dentro del contenedor
echo "1️⃣  Intentando conexión desde dentro del contenedor:"
docker exec $CONTAINER_ID sh -c "wget -qO- --timeout=5 http://localhost:3001/api/health 2>&1 || wget -qO- --timeout=5 http://127.0.0.1:3001/api/health 2>&1 || echo 'wget no disponible'"
echo ""

# 2. Intentar con nc (netcat) para ver si el puerto responde
echo "2️⃣  Probando puerto con netcat:"
docker exec $CONTAINER_ID sh -c "echo 'GET /api/health HTTP/1.1\r\nHost: localhost\r\n\r\n' | nc localhost 3001 2>&1 | head -10 || echo 'nc no disponible'"
echo ""

# 3. Verificar si hay algún proceso escuchando específicamente en 0.0.0.0:3001
echo "3️⃣  Verificando procesos escuchando en puerto 3001:"
docker exec $CONTAINER_ID sh -c "lsof -i :3001 2>/dev/null || ss -tulpn 2>/dev/null | grep 3001 || netstat -tulpn 2>/dev/null | grep 3001 || echo 'No se puede verificar'"
echo ""

# 4. Verificar si el servidor está realmente procesando peticiones (ver logs en tiempo real)
echo "4️⃣  Iniciando monitoreo de logs mientras hacemos una petición..."
echo "   (Esto puede tardar unos segundos)"
timeout 10 bash -c "
    docker exec $CONTAINER_ID sh -c 'echo \"GET /api/health HTTP/1.0\r\n\r\n\" | nc localhost 3001' &
    sleep 2
    docker logs $CONTAINER_ID --tail 5 2>&1 | grep -E 'GET|POST|health|/api' || echo 'No se encontraron logs de peticiones'
" 2>/dev/null
echo ""

echo "=============================================================="
echo "✅ PRUEBA COMPLETADA"
echo "=============================================================="
echo ""
