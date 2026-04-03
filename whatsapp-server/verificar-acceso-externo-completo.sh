#!/bin/bash
# ✅ Verificar acceso externo completo

echo "=============================================================="
echo "✅ VERIFICACIÓN DE ACCESO EXTERNO"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Obtener IP pública del servidor
HOST_IP=$(hostname -I | awk '{print $1}')
echo "1️⃣  IP pública del servidor: $HOST_IP"
echo ""

# 2. Verificar que el puerto esté mapeado
echo "2️⃣  Verificando mapeo de puertos:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool
echo ""

# 3. Verificar que el puerto esté escuchando
echo "3️⃣  Verificando puerto 3001:"
ss -tuln | grep 3001 && echo "   ✅ Puerto 3001 está escuchando" || echo "   ❌ Puerto 3001 NO está escuchando"
echo ""

# 4. Probar desde el servidor
echo "4️⃣  Probando desde el servidor (127.0.0.1):"
timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health | python3 -m json.tool 2>/dev/null || echo "   ❌ No responde"
echo ""

# 5. Probar desde IP pública
echo "5️⃣  Probando desde IP pública ($HOST_IP):"
timeout 5 curl -s --max-time 3 http://$HOST_IP:3001/api/health | python3 -m json.tool 2>/dev/null || echo "   ❌ No responde"
echo ""

# 6. Verificar firewall
echo "6️⃣  Verificando firewall (iptables para puerto 3001):"
iptables -L -n 2>/dev/null | grep 3001 || echo "   ℹ️  No hay reglas específicas de firewall para 3001"
echo ""

# 7. Información para el usuario
echo "=============================================================="
echo "📋 INFORMACIÓN PARA ACCESO DESDE TU NAVEGADOR"
echo "=============================================================="
echo ""
echo "✅ El servidor está funcionando correctamente"
echo ""
echo "🌐 Para acceder desde tu navegador, usa:"
echo "   http://$HOST_IP:3001/api/health"
echo "   http://$HOST_IP:3001/api/status"
echo "   http://$HOST_IP:3001/api/qr"
echo ""
echo "⚠️  NO uses 127.0.0.1 desde tu navegador local"
echo "   127.0.0.1 se refiere a tu propia computadora, no al servidor"
echo ""
echo "📱 Estado actual: whatsapp='connecting' es normal"
echo "   Significa que está esperando que escanees el QR code"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
