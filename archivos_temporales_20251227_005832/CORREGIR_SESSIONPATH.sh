#!/bin/bash
# Corregir error de sessionPath

cd ~/checkin24hs/whatsapp-server

echo "=== Ver línea 277 y contexto ==="
sed -n '270,285p' whatsapp-server.js

echo ""
echo "=== Buscar todas las referencias a sessionPath ==="
grep -n "sessionPath" whatsapp-server.js

echo ""
echo "=== Reemplazar sessionPath por sessionDataPath ==="
sed -i 's/sessionPath/sessionDataPath/g' whatsapp-server.js

echo ""
echo "=== Verificar que se reemplazó ==="
grep -n "sessionPath" whatsapp-server.js || echo "✅ Todas las referencias corregidas"

echo ""
echo "=== Verificar sintaxis ==="
node -c whatsapp-server.js && echo "✅ Sintaxis correcta" || echo "❌ Error de sintaxis"

