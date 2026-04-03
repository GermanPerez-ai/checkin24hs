#!/bin/bash
# Script guiado para cambiar la imagen de preview (detecta hoteles dinámicamente)

echo "=========================================="
echo "🖼️  GUÍA PARA CAMBIAR IMAGEN DE PREVIEW"
echo "=========================================="
echo ""

# Función para encontrar todos los hoteles disponibles
find_hotels() {
    local base_dir="$1"
    local hotels=()
    
    if [ -d "$base_dir/hotel-images" ]; then
        for dir in "$base_dir/hotel-images"/hotel-*; do
            if [ -d "$dir" ] && [ -f "$dir/main.jpg" ]; then
                hotel_name=$(basename "$dir")
                hotels+=("$hotel_name")
            fi
        done
    fi
    
    printf '%s\n' "${hotels[@]}" | sort
}

# Buscar hoteles en el directorio actual y en el padre
CURRENT_DIR=$(pwd)
HOTELS=($(find_hotels "$CURRENT_DIR"))
if [ ${#HOTELS[@]} -eq 0 ]; then
    HOTELS=($(find_hotels "$CURRENT_DIR/.."))
fi

if [ ${#HOTELS[@]} -eq 0 ]; then
    echo "❌ No se encontraron hoteles con main.jpg"
    echo "   Asegúrate de estar en el directorio correcto"
    exit 1
fi

# 1. Mostrar hoteles disponibles
echo "📋 Hoteles disponibles (detectados automáticamente):"
echo ""

for i in "${!HOTELS[@]}"; do
    hotel="${HOTELS[$i]}"
    num=$((i + 1))
    echo "  $num) $hotel"
done

echo ""

# 2. Pedir selección
read -p "👉 Selecciona el número del hotel (1-${#HOTELS[@]}): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt ${#HOTELS[@]} ]; then
    echo "❌ Opción no válida"
    exit 1
fi

SELECTED_HOTEL="${HOTELS[$((SELECTION - 1))]}"

echo ""
echo "✅ Hotel seleccionado: $SELECTED_HOTEL"
echo ""

# 3. Verificar que existe
if [ ! -d "hotel-images/$SELECTED_HOTEL" ]; then
    # Intentar desde el directorio padre
    if [ -d "../hotel-images/$SELECTED_HOTEL" ]; then
        HOTEL_PATH="../hotel-images/$SELECTED_HOTEL"
    else
        echo "❌ El directorio hotel-images/$SELECTED_HOTEL no existe"
        exit 1
    fi
else
    HOTEL_PATH="hotel-images/$SELECTED_HOTEL"
fi

if [ ! -f "$HOTEL_PATH/main.jpg" ]; then
    echo "❌ El archivo $HOTEL_PATH/main.jpg no existe"
    exit 1
fi

echo "✅ Imagen encontrada: $HOTEL_PATH/main.jpg"
echo ""

# 4. Mostrar opciones de aplicación
echo "🔧 ¿Cómo quieres aplicar el cambio?"
echo ""
echo "  1) Solo en el servidor (temporal - se pierde al reiniciar)"
echo "  2) En el código (permanente - requiere commit y rebuild)"
echo "  3) Ambos (temporal ahora + permanente en código)"
echo ""

read -p "👉 Selecciona opción (1-3): " OPTION

case "$OPTION" in
    1)
        echo ""
        echo "🔄 Aplicando cambio temporal en el servidor..."
        if [ -f "APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh" ]; then
            ./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh "$SELECTED_HOTEL"
        else
            echo "❌ No se encontró APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh"
            echo "   Ejecuta este script desde el directorio correcto"
            exit 1
        fi
        ;;
    2)
        echo ""
        echo "📝 Para hacer el cambio permanente:"
        echo "   1. Edita checkin24hs-admin/server.js"
        echo "   2. Agrega la variable de entorno OG_COTIZAR_IMAGE=$SELECTED_HOTEL"
        echo "   3. O simplemente el sistema detectará automáticamente todos los hoteles"
        echo ""
        echo "   El código ya está configurado para detectar todos los hoteles dinámicamente."
        echo "   Si quieres forzar un hotel específico, usa la variable de entorno."
        echo ""
        echo "📋 Próximos pasos:"
        echo "   1. Haz commit y push a GitHub"
        echo "   2. Haz rebuild desde EasyPanel"
        echo "   3. (Opcional) Agrega variable de entorno OG_COTIZAR_IMAGE=$SELECTED_HOTEL en EasyPanel"
        ;;
    3)
        echo ""
        echo "🔄 Aplicando cambio temporal en el servidor..."
        if [ -f "APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh" ]; then
            ./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh "$SELECTED_HOTEL"
        else
            echo "⚠️  No se encontró APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh"
            echo "   Continuando solo con el cambio permanente..."
        fi
        echo ""
        echo "📝 Para hacer el cambio permanente:"
        echo "   1. Agrega variable de entorno OG_COTIZAR_IMAGE=$SELECTED_HOTEL en EasyPanel"
        echo "   2. O el sistema usará el primer hotel disponible"
        echo ""
        echo "📋 Próximos pasos:"
        echo "   1. Haz commit y push a GitHub (si hay cambios)"
        echo "   2. Haz rebuild desde EasyPanel"
        echo "   3. (Opcional) Agrega variable de entorno en EasyPanel"
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
echo ""
echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo "📱 Luego envía un mensaje de WhatsApp con: https://cotizar.checkin24hs.com/"
echo ""
echo "💡 Nota: El sistema ahora detecta automáticamente todos los hoteles."
echo "   Cuando agregues un nuevo hotel, estará disponible automáticamente."
echo ""
