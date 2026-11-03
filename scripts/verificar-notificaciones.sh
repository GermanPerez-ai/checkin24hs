#!/bin/bash
# Script de verificación rápida de sistemas de notificaciones
# Uso: bash scripts/verificar-notificaciones.sh

echo "=== VERIFICACIÓN RÁPIDA NOTIFICACIONES ==="
echo ""

echo "1. ANA:"
docker ps | grep ana > /dev/null && echo "   ✅ Container activo" || echo "   ❌ Container NO activo"
curl -sf https://ana.checkin24hs.com/ > /dev/null && echo "   ✅ Web responde" || echo "   ⚠️  Web no responde"

echo ""
echo "2. EMAIL MONITOR:"
[ -f /var/log/email-monitor.log ] && echo "   ✅ Log existe ($(ls -lh /var/log/email-monitor.log | awk '{print $5}'))" || echo "   ❌ Log no existe"
tail -1 /var/log/email-monitor.log 2>/dev/null | grep -q "Desconectado" && echo "   ✅ Última ejecución OK" || echo "   ⚠️  Ver logs"

echo ""
echo "3. NO STOP:"
docker ps | grep nostop > /dev/null && echo "   ✅ Container activo" || echo "   ❌ Container NO activo"
curl -sf https://nostop.site/ > /dev/null && echo "   ✅ Web responde" || echo "   ⚠️  Web no responde"

echo ""
echo "=== FIN ==="
echo ""
echo "📝 Para diagnóstico completo:"
echo "   bash scripts/diagnostico-notificaciones.sh"
