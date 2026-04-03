#!/bin/bash
# Script para verificar dashboard.html en el servidor
# Ejecutar en el servidor: bash verificar_dashboard_servidor.sh

FILE="/root/checkin24hs/deploy/dashboard.html"

echo "=========================================="
echo "Verificacion de dashboard.html"
echo "=========================================="
echo ""

# Verificar que el archivo existe
if [ ! -f "$FILE" ]; then
    echo "ERROR: El archivo no existe: $FILE"
    exit 1
fi

echo "Archivo encontrado: $FILE"
echo ""

# Contar tags HTML
HTML_COUNT=$(grep -c '<html' "$FILE" 2>/dev/null || echo "0")
HTML_CLOSE_COUNT=$(grep -c '</html>' "$FILE" 2>/dev/null || echo "0")

echo "Tags HTML:"
echo "  - <html>: $HTML_COUNT"
echo "  - </html>: $HTML_CLOSE_COUNT"
echo ""

# Verificar integridad
if [ "$HTML_COUNT" -eq 1 ] && [ "$HTML_CLOSE_COUNT" -eq 1 ]; then
    echo "Estado: CORRECTO (1 documento HTML completo)"
    STATUS="OK"
elif [ "$HTML_COUNT" -gt 1 ] || [ "$HTML_CLOSE_COUNT" -gt 1 ]; then
    echo "Estado: CORRUPTO (archivo duplicado/truncado)"
    STATUS="CORRUPTO"
    echo "  El archivo tiene $HTML_COUNT tags <html> y $HTML_CLOSE_COUNT tags </html>"
else
    echo "Estado: INCOMPLETO o ARCHIVO INVALIDO"
    STATUS="INCOMPLETO"
fi
echo ""

# Verificar elementos clave
WHATSAPP=$(grep -c 'whatsapp-server-url' "$FILE" 2>/dev/null || echo "0")
KNOWLEDGE=$(grep -c 'knowledge-hotel-selector' "$FILE" 2>/dev/null || echo "0")
FLOR_TAB=$(grep -c 'flor-tab-whatsapp' "$FILE" 2>/dev/null || echo "0")

echo "Elementos clave encontrados:"
echo "  - whatsapp-server-url: $WHATSAPP"
echo "  - knowledge-hotel-selector: $KNOWLEDGE"
echo "  - flor-tab-whatsapp: $FLOR_TAB"
echo ""

# Contar lineas
LINE_COUNT=$(wc -l < "$FILE" 2>/dev/null || echo "0")
FILE_SIZE=$(du -h "$FILE" 2>/dev/null | cut -f1 || echo "0")
echo "Tamanio: $FILE_SIZE ($LINE_COUNT lineas)"
echo ""

# Mostrar primeras lineas
echo "Primeras 5 lineas del archivo:"
head -5 "$FILE"
echo ""

# Mostrar ultimas 5 lineas
echo "Ultimas 5 lineas del archivo:"
tail -5 "$FILE"
echo ""

# Resumen final
echo "=========================================="
if [ "$STATUS" = "OK" ] && [ "$WHATSAPP" -gt 0 ] && [ "$KNOWLEDGE" -gt 0 ]; then
    echo "RESULTADO: Archivo CORRECTO y COMPLETO"
    echo "  - Estructura HTML: OK"
    echo "  - Elementos WhatsApp: OK"
    echo "  - Elementos Knowledge: OK"
    echo ""
    echo "El archivo esta listo para usar."
    exit 0
else
    echo "RESULTADO: Archivo con PROBLEMAS"
    if [ "$STATUS" != "OK" ]; then
        echo "  - Estructura HTML: PROBLEMA"
    fi
    if [ "$WHATSAPP" -eq 0 ]; then
        echo "  - Elementos WhatsApp: FALTANTE"
    fi
    if [ "$KNOWLEDGE" -eq 0 ]; then
        echo "  - Elementos Knowledge: FALTANTE"
    fi
    echo ""
    echo "Necesitas transferir el archivo correcto desde tu maquina local."
    exit 1
fi
