#!/bin/bash
# Corregir terminadores de línea del archivo CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh

echo "=== Corrigiendo terminadores de línea ==="

cd /root/checkin24hs

# Convertir Windows (CRLF) a Unix (LF)
if command -v dos2unix &> /dev/null; then
    dos2unix CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
elif command -v sed &> /dev/null; then
    sed -i 's/\r$//' CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
else
    # Usar tr como alternativa
    tr -d '\r' < CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh > CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh.tmp
    mv CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh.tmp CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
fi

chmod +x CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh

echo "✅ Archivo corregido"
echo ""
echo "Ahora puedes ejecutar:"
echo "  bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh"






