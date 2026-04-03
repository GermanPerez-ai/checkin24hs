#!/bin/bash
# ✅ Verificar que el puerto 3001 esté mapeado y funcionando

echo "=============================================================="
echo "✅ VERIFICACIÓN DE PUERTO 3001 MAPEADO"
echo "=============================================================="
echo ""

# 1. Verificar mapeo de puertos del servicio
echo "1️⃣  Mapeo de puertos del servicio:"
echo "--------------------------------------------------------------"
docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}' 2>/dev/null
echo ""

# 2. Verificar que el puerto esté escuchando
echo "2️⃣  Puerto 3001 escuchando:"
echo "--------------------------------------------------------------"
if netstat -tulpn 2>/dev/null | grep ":3001" || ss -tulpn 2>/dev/null | grep ":3001"; then
    echo "   ✅ Puerto 3001 está escuchando"
else
    echo "   ⚠️  Puerto 3001 no aparece en netstat/ss (puede ser normal con Docker Swarm)"
fi
echo ""

# 3. Probar conexión local
echo "3️⃣  Probando conexión local al puerto 3001:"
echo "--------------------------------------------------------------"
if curl -s --max-time 5 http://localhost:3001/api/health >/dev/null 2>&1; then
    echo "   ✅ Servidor responde en localhost:3001"
    curl -s http://localhost:3001/api/health | head -3
else
    echo "   ⚠️  Servidor no responde en localhost:3001 (espera unos segundos más)"
fi
echo ""

# 4. Verificar estado del servicio
echo "4️⃣  Estado del servicio:"
echo "--------------------------------------------------------------"
docker service ps checkin24hs_whatsapp --no-trunc | head -3
echo ""

# 5. Ver logs recientes
echo "5️⃣  Últimos 10 logs del servicio:"
echo "--------------------------------------------------------------"
docker service logs checkin24hs_whatsapp --tail 10 2>&1 | tail -10
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "💡 Ahora deberías poder acceder a:"
echo "   - http://api1.checkin24hs.com:3001"
echo "   - http://api1.checkin24hs.com:3001/api/status"
echo "   - http://api1.checkin24hs.com:3001/api/qr"
echo ""
echo "📱 Prueba desde tu navegador o ejecuta:"
echo "   curl http://api1.checkin24hs.com:3001/api/health"
echo ""
