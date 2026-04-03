#!/bin/bash
# Script para cambiar la imagen de preview del cotizador

echo "=========================================="
echo "🖼️  CAMBIAR IMAGEN DE PREVIEW"
echo "=========================================="
echo ""

# Lista de hoteles disponibles
echo "Hoteles disponibles:"
echo "  1) hotel-1-puyehue"
echo "  2) hotel-2-huilo-huilo"
echo "  3) hotel-3-corralco"
echo "  4) hotel-4-futangue"
echo "  5) hotel-5-aguas-calientes"
echo ""

# Si se pasa como argumento, usarlo
if [ ! -z "$1" ]; then
    SELECTED_HOTEL="$1"
else
    read -p "Selecciona el número del hotel (1-5) o el nombre: " SELECTION
    
    case "$SELECTION" in
        1) SELECTED_HOTEL="hotel-1-puyehue" ;;
        2) SELECTED_HOTEL="hotel-2-huilo-huilo" ;;
        3) SELECTED_HOTEL="hotel-3-corralco" ;;
        4) SELECTED_HOTEL="hotel-4-futangue" ;;
        5) SELECTED_HOTEL="hotel-5-aguas-calientes" ;;
        *) SELECTED_HOTEL="$SELECTION" ;;
    esac
fi

if [ -z "$SELECTED_HOTEL" ]; then
    echo "❌ Hotel no válido"
    exit 1
fi

echo ""
echo "✅ Hotel seleccionado: $SELECTED_HOTEL"
echo ""

# Verificar que el hotel existe
if [ ! -d "hotel-images/$SELECTED_HOTEL" ]; then
    echo "❌ El directorio hotel-images/$SELECTED_HOTEL no existe"
    exit 1
fi

if [ ! -f "hotel-images/$SELECTED_HOTEL/main.jpg" ]; then
    echo "❌ El archivo hotel-images/$SELECTED_HOTEL/main.jpg no existe"
    exit 1
fi

echo "✅ Imagen encontrada: hotel-images/$SELECTED_HOTEL/main.jpg"
echo ""

# Opción 1: Cambiar en el servidor (temporal)
echo "¿Cómo quieres aplicar el cambio?"
echo "  1) Solo en el servidor (temporal - se pierde al reiniciar)"
echo "  2) En el código (permanente - requiere rebuild)"
echo "  3) Ambos"
echo ""

read -p "Selecciona opción (1-3): " OPTION

case "$OPTION" in
    1)
        echo ""
        echo "🔄 Aplicando cambio temporal en el servidor..."
        ./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh "$SELECTED_HOTEL"
        ;;
    2)
        echo ""
        echo "📝 Cambiando orden en server.js..."
        # Cambiar el orden en server.js para poner el hotel seleccionado primero
        sed -i "s/hotel-1-puyehue/hotel-TEMP-PLACEHOLDER/g" checkin24hs-admin/server.js
        sed -i "s/$SELECTED_HOTEL/hotel-1-puyehue/g" checkin24hs-admin/server.js
        sed -i "s/hotel-TEMP-PLACEHOLDER/$SELECTED_HOTEL/g" checkin24hs-admin/server.js
        
        echo "✅ server.js actualizado"
        echo ""
        echo "📋 Próximos pasos:"
        echo "   1. Haz commit y push a GitHub"
        echo "   2. Haz rebuild desde EasyPanel"
        ;;
    3)
        echo ""
        echo "🔄 Aplicando cambio temporal en el servidor..."
        ./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh "$SELECTED_HOTEL"
        echo ""
        echo "📝 Cambiando orden en server.js..."
        sed -i "s/hotel-1-puyehue/hotel-TEMP-PLACEHOLDER/g" checkin24hs-admin/server.js
        sed -i "s/$SELECTED_HOTEL/hotel-1-puyehue/g" checkin24hs-admin/server.js
        sed -i "s/hotel-TEMP-PLACEHOLDER/$SELECTED_HOTEL/g" checkin24hs-admin/server.js
        echo "✅ server.js actualizado"
        echo ""
        echo "📋 Próximos pasos:"
        echo "   1. Haz commit y push a GitHub"
        echo "   2. Haz rebuild desde EasyPanel"
        ;;
    *)
        echo "❌ Opción no válida"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
