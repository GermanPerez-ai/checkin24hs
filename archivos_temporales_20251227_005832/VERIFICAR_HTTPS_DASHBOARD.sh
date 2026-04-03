#!/bin/bash
# Verificar acceso HTTPS al dashboard

echo "=== 1. Probar acceso HTTPS ==="
curl -I https://dashboard.checkin24hs.com 2>&1 | head -15

echo ""
echo "=== 2. Probar acceso HTTP (debería redirigir) ==="
curl -L http://dashboard.checkin24hs.com 2>&1 | head -10

echo ""
echo "=== 3. Verificar certificado SSL ==="
echo | openssl s_client -connect dashboard.checkin24hs.com:443 -servername dashboard.checkin24hs.com 2>/dev/null | grep -E "subject=|issuer=|Verify return code" || echo "No se pudo verificar certificado"

echo ""
echo "=== 4. Ver logs de Traefik para dashboard ==="
docker logs traefik.1.1qfkazdh5m0czg2hslan0ny0g --tail 20 | grep -i dashboard || echo "No hay logs recientes"

echo ""
echo "✅ Si HTTPS funciona, el dashboard está completamente configurado!"

