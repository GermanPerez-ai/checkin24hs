#!/bin/bash
# Script para limpiar sesión de WhatsApp en Easypanel
# Ejecutar en el terminal de Easypanel

echo "🧹 Limpiando sesión de WhatsApp en Easypanel..."
echo ""

# Buscar la carpeta de sesión
SESSION_DIR=".wwebjs_auth"

# Intentar diferentes ubicaciones comunes
POSSIBLE_PATHS=(
    "/app/.wwebjs_auth"
    "/app/whatsapp-server/.wwebjs_auth"
    "$HOME/.wwebjs_auth"
    ".wwebjs_auth"
    "./.wwebjs_auth"
)

FOUND=false

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "✅ Encontrada sesión en: $path"
        echo "🗑️  Eliminando..."
        rm -rf "$path"
        echo "✅ Sesión eliminada correctamente"
        FOUND=true
        break
    fi
done

if [ "$FOUND" = false ]; then
    echo "⚠️  No se encontró la carpeta .wwebjs_auth"
    echo "🔍 Buscando en todo el sistema..."
    find /app -name ".wwebjs_auth" -type d 2>/dev/null | while read dir; do
        echo "   Encontrada en: $dir"
        echo "   ¿Eliminar? (s/n): "
        read -r response
        if [ "$response" = "s" ] || [ "$response" = "S" ]; then
            rm -rf "$dir"
            echo "✅ Eliminada: $dir"
        fi
    done
fi

echo ""
echo "✅ Limpieza completada!"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Ve a Easypanel > Services > Reinicia tu servicio de WhatsApp"
echo "   2. Ve a Logs para ver el código QR"
echo "   3. Escanea el QR con tu teléfono"
echo ""

