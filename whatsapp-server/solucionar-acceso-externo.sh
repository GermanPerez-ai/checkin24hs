#!/bin/bash
# 🔧 Solucionar acceso externo al puerto 3001

cd /root/checkin24hs

echo "=============================================================="
echo "🔧 SOLUCIONANDO ACCESO EXTERNO"
echo "=============================================================="
echo ""

# 1. Verificar logs completos para ver si el servidor inició
echo "1️⃣  Verificando logs del servicio (últimos 50)..."
docker service logs checkin24hs_whatsapp --tail 50 | tail -20
echo ""

# 2. Verificar si el proceso Node.js está corriendo
echo "2️⃣  Verificando proceso Node.js en el contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
if [ -n "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    # Intentar ver procesos (puede que no tenga ps)
    docker exec $CONTAINER_ID sh -c "ps aux 2>/dev/null | grep node || echo 'ps no disponible'"
else
    echo "   ❌ No se encontró el contenedor"
    exit 1
fi
echo ""

# 3. Verificar mapeo de puertos actual
echo "3️⃣  Verificando mapeo de puertos actual..."
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool 2>/dev/null || docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}'
echo ""

# 4. Mapear el puerto 3001 si no está mapeado
echo "4️⃣  Mapeando puerto 3001..."
PORT_MAPPED=$(docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null | grep -q "3001" && echo "yes" || echo "no")

if [ "$PORT_MAPPED" = "no" ]; then
    echo "   ⚠️  Puerto 3001 NO está mapeado"
    echo "   🔧 Mapeando puerto 3001..."
    docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
    echo "   ✅ Comando de mapeo ejecutado"
    echo "   ⏳ Esperando 30 segundos para que se aplique..."
    sleep 30
else
    echo "   ✅ Puerto 3001 ya está mapeado"
fi
echo ""

# 5. Verificar que el servidor responde después del mapeo
echo "5️⃣  Verificando que el servidor responde..."
sleep 5
HEALTH=$(timeout 10 curl -s --max-time 5 http://127.0.0.1:3001/api/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ Servidor responde: $HEALTH"
else
    echo "   ❌ Servidor NO responde aún"
    echo "   💡 Verificando logs para ver si hay errores..."
    docker service logs checkin24hs_whatsapp --tail 20 | grep -iE "error|fail|exception" | tail -5
fi
echo ""

# 6. Verificar mapeo después de la actualización
echo "6️⃣  Verificando mapeo de puertos después de la actualización..."
docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}'
echo ""

# 7. Obtener IP pública IPv4
echo "7️⃣  Verificando IP pública IPv4..."
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 ipinfo.io/ip 2>/dev/null || echo "No se pudo obtener")
echo "   IP pública IPv4: $PUBLIC_IPV4"
echo "   IP que intentas acceder: 72.61.58.240"
if [ "$PUBLIC_IPV4" = "72.61.58.240" ]; then
    echo "   ✅ La IP coincide"
else
    echo "   ⚠️  La IP NO coincide"
    echo "   💡 Prueba acceder con: http://$PUBLIC_IPV4:3001"
fi
echo ""

echo "=============================================================="
echo "📊 RESUMEN"
echo "=============================================================="
echo ""

if [ -n "$HEALTH" ]; then
    echo "✅ Servidor responde internamente"
    if [ "$PORT_MAPPED" = "no" ]; then
        echo "✅ Puerto 3001 mapeado"
    fi
    echo ""
    echo "🌐 Prueba acceder desde el navegador:"
    if [ "$PUBLIC_IPV4" = "72.61.58.240" ]; then
        echo "   http://72.61.58.240:3001"
    else
        echo "   http://$PUBLIC_IPV4:3001"
        echo "   O"
        echo "   http://72.61.58.240:3001 (si es la IP correcta)"
    fi
else
    echo "❌ El servidor NO responde"
    echo ""
    echo "💡 Verifica los logs para ver qué está pasando:"
    echo "   docker service logs checkin24hs_whatsapp --tail 50"
fi

echo ""
echo "=============================================================="
echo ""
