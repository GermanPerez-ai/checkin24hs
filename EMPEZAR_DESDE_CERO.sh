#!/bin/bash
echo "=== EMPEZANDO DESDE CERO ==="
echo ""

echo "1️⃣ Eliminando servicios de WhatsApp..."
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "   Eliminando $s..."
    docker service rm $s 2>/dev/null || echo "   $s no existe"
done

echo ""
echo "⏳ Esperando 10 segundos..."
sleep 10

echo ""
echo "2️⃣ Verificando que los servicios fueron eliminados:"
docker service ls | grep whatsapp || echo "   ✅ No hay servicios de WhatsApp"

echo ""
echo "3️⃣ Verificando puertos libres:"
for port in 3001 3002 3003 3004; do
    if netstat -tuln 2>/dev/null | grep ":$port " || ss -tuln 2>/dev/null | grep ":$port "; then
        echo "   ⚠️  Puerto $port está en uso"
    else
        echo "   ✅ Puerto $port está libre"
    fi
done

echo ""
echo "=== LISTO PARA RECREAR EN EASYPANEL ==="
echo ""
echo "Ahora ve a EasyPanel y:"
echo "1. Crea los 4 servicios de WhatsApp nuevamente"
echo "2. Configura los dominios:"
echo "   - whatsapp1.checkin24hs.com → puerto interno 3001"
echo "   - whatsapp2.checkin24hs.com → puerto interno 3002"
echo "   - whatsapp3.checkin24hs.com → puerto interno 3003"
echo "   - whatsapp4.checkin24hs.com → puerto interno 3004"
echo "3. Haz deploy de cada servicio para que use el código actualizado"
echo ""
echo "El código actualizado ya tiene:"
echo "✅ Fix de 0.0.0.0 aplicado"
echo "✅ Manejo de errores en el callback async"
echo "✅ Dockerfile simplificado"
