#!/bin/bash
# 🔍 Diagnosticar por qué no se puede acceder externamente al puerto 3001

cd /root/checkin24hs

echo "=============================================================="
echo "🔍 DIAGNÓSTICO DE ACCESO EXTERNO"
echo "=============================================================="
echo ""

# 1. Verificar que el servidor responde internamente
echo "1️⃣  Verificando acceso interno (localhost)..."
HEALTH=$(timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ Servidor responde internamente: $HEALTH"
else
    echo "   ❌ Servidor NO responde internamente"
    echo "   ⚠️  El servidor puede no estar iniciado"
fi
echo ""

# 2. Verificar mapeo de puertos del servicio Docker Swarm
echo "2️⃣  Verificando mapeo de puertos Docker Swarm..."
docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}' 2>/dev/null
echo ""

# 3. Verificar si el puerto está escuchando en el host
echo "3️⃣  Verificando si el puerto 3001 está escuchando en el host..."
if netstat -tuln 2>/dev/null | grep ":3001" || ss -tuln 2>/dev/null | grep ":3001"; then
    echo "   ✅ Puerto 3001 está escuchando"
else
    echo "   ⚠️  Puerto 3001 NO aparece en netstat/ss"
    echo "   💡 Esto puede ser normal con Docker Swarm routing mesh"
fi
echo ""

# 4. Verificar IP pública del servidor
echo "4️⃣  Verificando IP pública del servidor..."
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "No se pudo obtener")
echo "   IP pública detectada: $PUBLIC_IP"
echo "   IP que intentas acceder: 72.61.58.240"
if [ "$PUBLIC_IP" = "72.61.58.240" ]; then
    echo "   ✅ La IP coincide"
else
    echo "   ⚠️  La IP NO coincide - verifica que estés usando la IP correcta"
fi
echo ""

# 5. Verificar contenedor y su IP
echo "5️⃣  Verificando contenedor y su IP..."
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
if [ -n "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    CONTAINER_IP=$(docker inspect $CONTAINER_ID | grep -A 20 "Networks" | grep "IPAddress" | head -1 | awk '{print $2}' | tr -d '",')
    echo "   IP del contenedor: $CONTAINER_IP"
    
    # Probar conexión desde dentro del contenedor
    echo "   Probando conexión desde dentro del contenedor..."
    docker exec $CONTAINER_ID sh -c "wget -q -O- http://localhost:3001/api/health 2>/dev/null || curl -s http://localhost:3001/api/health 2>/dev/null" | head -1
else
    echo "   ❌ No se encontró el contenedor"
fi
echo ""

# 6. Verificar firewall (si es posible)
echo "6️⃣  Verificando firewall..."
if command -v ufw >/dev/null 2>&1; then
    echo "   Estado UFW:"
    ufw status | grep 3001 || echo "   Puerto 3001 no mencionado en UFW"
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "   Estado firewalld:"
    firewall-cmd --list-ports 2>/dev/null | grep 3001 || echo "   Puerto 3001 no mencionado en firewalld"
else
    echo "   ⚠️  No se pudo verificar firewall (comandos no disponibles)"
fi
echo ""

# 7. Verificar logs del servicio
echo "7️⃣  Últimos logs del servicio (buscando errores)..."
docker service logs checkin24hs_whatsapp --tail 20 2>&1 | grep -iE "error|fail|listen|port|3001" | tail -5 || echo "   No se encontraron errores obvios"
echo ""

# 8. Verificar que el servidor está escuchando en 0.0.0.0
echo "8️⃣  Verificando que el servidor escucha en 0.0.0.0..."
docker service logs checkin24hs_whatsapp --tail 50 2>&1 | grep -i "escuchando\|listening\|0.0.0.0" | tail -3
echo ""

echo "=============================================================="
echo "📊 RESUMEN Y SOLUCIONES"
echo "=============================================================="
echo ""

# Verificar mapeo de puertos
PORT_MAPPED=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null | grep -q "3001" && echo "yes" || echo "no")

if [ "$PORT_MAPPED" = "no" ]; then
    echo "❌ PROBLEMA: El puerto 3001 NO está mapeado externamente"
    echo ""
    echo "💡 SOLUCIÓN: Mapear el puerto 3001"
    echo "   docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp"
    echo ""
elif [ -z "$HEALTH" ]; then
    echo "❌ PROBLEMA: El servidor NO responde internamente"
    echo ""
    echo "💡 SOLUCIÓN: Verificar logs del servicio"
    echo "   docker service logs checkin24hs_whatsapp --tail 50"
    echo ""
else
    echo "✅ El servidor responde internamente"
    echo ""
    if [ "$PUBLIC_IP" != "72.61.58.240" ]; then
        echo "⚠️  ADVERTENCIA: La IP pública no coincide"
        echo "   Usa la IP correcta: $PUBLIC_IP"
        echo ""
    fi
    echo "💡 Si el servidor responde internamente pero no externamente:"
    echo "   1. Verifica el firewall del servidor"
    echo "   2. Verifica el firewall de tu proveedor de hosting"
    echo "   3. Verifica que el puerto 3001 esté abierto en el panel de control"
    echo ""
fi

echo "=============================================================="
echo ""
