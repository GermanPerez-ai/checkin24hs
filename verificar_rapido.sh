#!/bin/bash
# Verificación rápida del dashboard.html

FILE="/root/checkin24hs/deploy/dashboard.html"

echo "🔍 Verificación rápida:"
echo ""

HTML_COUNT=$(grep -c '<html' "$FILE" 2>/dev/null || echo "0")
echo "Tags <html>: $HTML_COUNT"

if [ "$HTML_COUNT" -eq 1 ]; then
    echo "✅ Archivo CORRECTO"
elif [ "$HTML_COUNT" -gt 1 ]; then
    echo "❌ Archivo CORRUPTO (tiene $HTML_COUNT copias)"
    echo ""
    echo "📤 Para corregir, transfiere desde tu máquina Windows:"
    echo "   scp deploy\\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
else
    echo "❌ Archivo no encontrado o sin tags <html>"
fi

# Verificar elementos
WHATSAPP=$(grep -c 'whatsapp-server-url' "$FILE" 2>/dev/null || echo "0")
KNOWLEDGE=$(grep -c 'knowledge-hotel-selector' "$FILE" 2>/dev/null || echo "0")

echo ""
echo "Elementos encontrados:"
echo "  - whatsapp-server-url: $WHATSAPP"
echo "  - knowledge-hotel-selector: $KNOWLEDGE"

