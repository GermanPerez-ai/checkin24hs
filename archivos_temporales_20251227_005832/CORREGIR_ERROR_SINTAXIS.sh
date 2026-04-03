#!/bin/bash
# Corregir error de sintaxis

cd ~/checkin24hs/whatsapp-server

echo "=== Ver líneas alrededor del error (225-235) ==="
sed -n '220,240p' whatsapp-server.js

echo ""
echo "=== Ver qué hay antes (210-225) ==="
sed -n '210,230p' whatsapp-server.js

