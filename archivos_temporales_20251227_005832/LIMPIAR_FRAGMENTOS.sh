#!/bin/bash
# Limpiar fragmentos de código antiguo

cd ~/checkin24hs/whatsapp-server

echo "=== Restaurando backup ==="
cp whatsapp-server.js.backup.final whatsapp-server.js

echo "=== Buscando todas las líneas con código antiguo ==="
grep -n "Función para limpiar locks de Chrome/Puppeteer" whatsapp-server.js
grep -n "wwebjs_auth_instance" whatsapp-server.js

echo ""
echo "=== Ver contexto completo de la función antigua ==="
# Buscar desde el comentario hasta el final de la función
INICIO=$(grep -n "// Función para limpiar locks de Chrome/Puppeteer" whatsapp-server.js | head -1 | cut -d: -f1)
if [ -n "$INICIO" ]; then
    echo "Función antigua empieza en línea: $INICIO"
    sed -n "${INICIO},$((INICIO+50))p" whatsapp-server.js | head -60
fi

