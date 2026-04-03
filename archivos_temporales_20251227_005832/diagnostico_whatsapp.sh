#!/bin/bash

echo "=== DIAGNÓSTICO DE SERVICIOS WHATSAPP ==="
echo ""

echo "1. Estado de servicios PM2:"
pm2 list | grep whatsapp || echo "No hay servicios PM2 de WhatsApp"
echo ""

echo "2. Verificar puertos en uso:"
netstat -tulpn 2>/dev/null | grep -E ':(3001|3002|3003|3004)' || ss -tulpn 2>/dev/null | grep -E ':(3001|3002|3003|3004)' || echo "No se encontraron puertos en uso"
echo ""

echo "3. Probar acceso a puertos:"
for port in 3001 3002 3003 3004; do
    echo -n "Puerto $port: "
    curl -s --max-time 2 http://localhost:$port/api/status 2>&1 | head -1 || echo "No responde"
done
echo ""

echo "4. Logs recientes de WhatsApp-1 (últimas 20 líneas):"
pm2 logs whatsapp-1 --lines 20 --nostream 2>&1 | tail -20 || echo "No hay logs disponibles"
echo ""

echo "5. Verificar servicios de EasyPanel (Docker):"
docker ps | grep -i whatsapp || echo "No hay contenedores de WhatsApp"
echo ""

echo "6. Verificar servicios de EasyPanel (Docker Swarm):"
docker service ls | grep -i whatsapp || echo "No hay servicios Swarm de WhatsApp"
echo ""

echo "7. Verificar directorios de sesión:"
ls -la ~/checkin24hs/whatsapp-server/.wwebjs_auth_* 2>/dev/null | head -5 || echo "No se encontraron directorios de sesión"
echo ""

echo "=== FIN DEL DIAGNÓSTICO ==="

