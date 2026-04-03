#!/bin/bash
# Script guiado para cambiar la imagen de preview

echo "=========================================="
echo "🖼️  GUÍA PARA CAMBIAR IMAGEN DE PREVIEW"
echo "=========================================="
echo ""

# 1. Mostrar hoteles disponibles
echo "📋 Hoteles disponibles:"
echo ""
echo "  1) hotel-1-puyehue"
echo "  2) hotel-2-huilo-huilo"
echo "  3) hotel-3-corralco"
echo "  4) hotel-4-futangue"
echo "  5) hotel-5-aguas-calientes"
echo ""

# 2. Pedir selección
read -p "👉 Selecciona el número del hotel (1-5): " SELECTION

case "$SELECTION" in
    1) SELECTED_HOTEL="hotel-1-puyehue" ;;
    2) SELECTED_HOTEL="hotel-2-huilo-huilo" ;;
    3) SELECTED_HOTEL="hotel-3-corralco" ;;
    4) SELECTED_HOTEL="hotel-4-futangue" ;;
    5) SELECTED_HOTEL="hotel-5-aguas-calientes" ;;
    *)
        echo "❌ Opción no válida"
        exit 1
        ;;
esac

echo ""
echo "✅ Hotel seleccionado: $SELECTED_HOTEL"
echo ""

# 3. Verificar que existe
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
        echo ""
        ./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh "$SELECTED_HOTEL"
        ;;
    2)
        echo ""
        echo "📝 Cambiando código para hacerlo permanente..."
        echo ""
        
        # Cambiar el orden en server.js
        if [ -f "checkin24hs-admin/server.js" ]; then
            # Crear backup
            cp checkin24hs-admin/server.js checkin24hs-admin/server.js.backup
            
            # Cambiar el orden: poner el hotel seleccionado primero
            # Primero, reemplazar temporalmente el primero
            sed -i.tmp "s/'hotel-1-puyehue'/'HOTEL-TEMP-PLACEHOLDER'/g" checkin24hs-admin/server.js
            
            # Luego, reemplazar el seleccionado por el primero
            sed -i.tmp "s/'$SELECTED_HOTEL'/'hotel-1-puyehue'/g" checkin24hs-admin/server.js
            
            # Finalmente, reemplazar el placeholder por el seleccionado
            sed -i.tmp "s/'HOTEL-TEMP-PLACEHOLDER'/'$SELECTED_HOTEL'/g" checkin24hs-admin/server.js
            
            # Limpiar archivo temporal
            rm -f checkin24hs-admin/server.js.tmp
            
            echo "✅ server.js actualizado"
            echo ""
            echo "📋 Próximos pasos:"
            echo "   1. Revisa los cambios: git diff checkin24hs-admin/server.js"
            echo "   2. Haz commit: git add checkin24hs-admin/server.js"
            echo "   3. Haz push: git push origin main"
            echo "   4. Haz rebuild desde EasyPanel"
        else
            echo "❌ No se encontró checkin24hs-admin/server.js"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "🔄 Aplicando cambio temporal en el servidor..."
        echo ""
        ./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh "$SELECTED_HOTEL"
        echo ""
        echo "📝 Cambiando código para hacerlo permanente..."
        echo ""
        
        # Cambiar el orden en server.js
        if [ -f "checkin24hs-admin/server.js" ]; then
            # Crear backup
            cp checkin24hs-admin/server.js checkin24hs-admin/server.js.backup
            
            # Cambiar el orden
            sed -i.tmp "s/'hotel-1-puyehue'/'HOTEL-TEMP-PLACEHOLDER'/g" checkin24hs-admin/server.js
            sed -i.tmp "s/'$SELECTED_HOTEL'/'hotel-1-puyehue'/g" checkin24hs-admin/server.js
            sed -i.tmp "s/'HOTEL-TEMP-PLACEHOLDER'/'$SELECTED_HOTEL'/g" checkin24hs-admin/server.js
            rm -f checkin24hs-admin/server.js.tmp
            
            echo "✅ server.js actualizado"
            echo ""
            echo "📋 Próximos pasos:"
            echo "   1. Revisa los cambios: git diff checkin24hs-admin/server.js"
            echo "   2. Haz commit: git add checkin24hs-admin/server.js"
            echo "   3. Haz push: git push origin main"
            echo "   4. Haz rebuild desde EasyPanel"
        else
            echo "❌ No se encontró checkin24hs-admin/server.js"
        fi
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
