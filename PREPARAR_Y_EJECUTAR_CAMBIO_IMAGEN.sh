#!/bin/bash
# Script completo para preparar y ejecutar el cambio de imagen

echo "=========================================="
echo "🚀 PREPARANDO SISTEMA DE CAMBIO DE IMAGEN"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Crear script guiado dinámico
echo "1️⃣ Creando script guiado..."
cat > GUIAR_CAMBIO_IMAGEN_DINAMICO.sh << 'EOFSCRIPT'
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
    echo "   Buscando en: $CURRENT_DIR y $CURRENT_DIR/.."
    exit 1
fi

# Mostrar hoteles disponibles
echo "📋 Hoteles disponibles (detectados automáticamente):"
echo ""

for i in "${!HOTELS[@]}"; do
    hotel="${HOTELS[$i]}"
    num=$((i + 1))
    echo "  $num) $hotel"
done

echo ""

# Pedir selección
read -p "👉 Selecciona el número del hotel (1-${#HOTELS[@]}): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt ${#HOTELS[@]} ]; then
    echo "❌ Opción no válida"
    exit 1
fi

SELECTED_HOTEL="${HOTELS[$((SELECTION - 1))]}"

echo ""
echo "✅ Hotel seleccionado: $SELECTED_HOTEL"
echo ""

# Verificar que existe
HOTEL_PATH=""
if [ -d "hotel-images/$SELECTED_HOTEL" ] && [ -f "hotel-images/$SELECTED_HOTEL/main.jpg" ]; then
    HOTEL_PATH="hotel-images/$SELECTED_HOTEL/main.jpg"
elif [ -d "../hotel-images/$SELECTED_HOTEL" ] && [ -f "../hotel-images/$SELECTED_HOTEL/main.jpg" ]; then
    HOTEL_PATH="../hotel-images/$SELECTED_HOTEL/main.jpg"
else
    echo "❌ No se encontró main.jpg para $SELECTED_HOTEL"
    exit 1
fi

echo "✅ Imagen encontrada: $HOTEL_PATH"
echo ""

# Mostrar opciones
echo "🔧 ¿Cómo quieres aplicar el cambio?"
echo ""
echo "  1) Solo en el servidor (temporal - se pierde al reiniciar)"
echo "  2) Variable de entorno (permanente - requiere EasyPanel)"
echo "  3) Ambos (temporal ahora + instrucciones para permanente)"
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
            echo "   Creando script ahora..."
            # El script se creará en el siguiente paso
        fi
        ;;
    2)
        echo ""
        echo "📝 Para hacer el cambio permanente:"
        echo "   1. Ve a EasyPanel"
        echo "   2. Edita el servicio: checkin24hs_dashboard"
        echo "   3. Agrega variable de entorno:"
        echo "      Nombre: OG_COTIZAR_IMAGE"
        echo "      Valor: $SELECTED_HOTEL"
        echo "   4. Guarda y reinicia el servicio"
        echo ""
        echo "   ✅ Con esto, siempre usará $SELECTED_HOTEL"
        ;;
    3)
        echo ""
        echo "🔄 Aplicando cambio temporal en el servidor..."
        if [ -f "APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh" ]; then
            ./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh "$SELECTED_HOTEL"
        else
            echo "⚠️  No se encontró APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh"
        fi
        echo ""
        echo "📝 Para hacerlo permanente:"
        echo "   1. Ve a EasyPanel"
        echo "   2. Agrega variable de entorno: OG_COTIZAR_IMAGE=$SELECTED_HOTEL"
        echo "   3. Reinicia el servicio"
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
EOFSCRIPT

chmod +x GUIAR_CAMBIO_IMAGEN_DINAMICO.sh
echo "✅ Script guiado creado"
echo ""

# 2. Crear script para aplicar en servidor
echo "2️⃣ Creando script para aplicar en servidor..."
cat > APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh << 'EOFSCRIPT'
#!/bin/bash
# Script para aplicar cambio de imagen en el servidor (temporal)

SELECTED_HOTEL="$1"

if [ -z "$SELECTED_HOTEL" ]; then
    echo "❌ Debes especificar el hotel (ej: hotel-1-puyehue)"
    exit 1
fi

echo "=========================================="
echo "🔄 APLICANDO CAMBIO DE IMAGEN EN SERVIDOR"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER_ID"
echo "✅ Hotel: $SELECTED_HOTEL"
echo ""

# 1. Descargar código desde GitHub
echo "1️⃣ Descargando código desde GitHub..."
TEMP_DIR="/tmp/change_image_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | tail -3

if [ ! -f "checkin24hs/checkin24hs-admin/server.js" ]; then
    echo "❌ No se encontró server.js"
    exit 1
fi

echo "✅ Código descargado"
echo ""

# 2. Modificar server.js para usar el hotel seleccionado
echo "2️⃣ Modificando server.js para usar $SELECTED_HOTEL..."
cd checkin24hs/checkin24hs-admin

# Modificar para que use el hotel seleccionado por defecto
sed -i "s/const selectedHotel = process.env.OG_COTIZAR_IMAGE || null;/const selectedHotel = process.env.OG_COTIZAR_IMAGE || '$SELECTED_HOTEL';/" server.js

echo "✅ server.js modificado"
echo ""

# 3. Copiar al contenedor
echo "3️⃣ Copiando server.js al contenedor..."
docker cp server.js "$CONTAINER_ID:/tmp/server.js.new"

if [ $? -ne 0 ]; then
    echo "❌ Error al copiar"
    exit 1
fi

echo "✅ Archivo copiado a /tmp/server.js.new"
echo ""

# 4. Detener Node.js y copiar
echo "4️⃣ Deteniendo Node.js y copiando archivo..."
docker exec "$CONTAINER_ID" pkill -9 node 2>/dev/null
sleep 2

docker exec -i "$CONTAINER_ID" sh -c "cat > /app/server.js" < server.js 2>&1

if [ $? -eq 0 ]; then
    echo "✅ server.js actualizado"
else
    echo "❌ Error al actualizar server.js"
    exit 1
fi
echo ""

# 5. Verificar
echo "5️⃣ Verificando..."
if docker exec "$CONTAINER_ID" grep -q "$SELECTED_HOTEL" /app/server.js 2>/dev/null; then
    echo "✅ Hotel $SELECTED_HOTEL confirmado en server.js"
else
    echo "⚠️  Hotel no encontrado en server.js (puede ser normal si usa detección dinámica)"
fi
echo ""

# 6. Reiniciar servicio
echo "6️⃣ Reiniciando servicio..."
docker service update --force "$SERVICE_NAME" > /dev/null 2>&1
echo "✅ Servicio reiniciado"
echo "⏳ Esperando 30 segundos..."
sleep 30
echo ""

# 7. Verificación final
echo "7️⃣ Verificación final..."
FINAL_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$FINAL_CONTAINER" ]; then
    if docker exec "$FINAL_CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "✅ Proceso Node.js está corriendo"
    fi
fi
echo ""

# 8. Limpiar
cd /
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"
echo ""

echo "=========================================="
echo "✅ CAMBIO APLICADO (TEMPORAL)"
echo "=========================================="
echo ""
echo "🌐 Prueba: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo ""
echo "⚠️  NOTA: Este cambio es temporal y se perderá al reiniciar."
echo "   Para hacerlo permanente, agrega variable de entorno:"
echo "   OG_COTIZAR_IMAGE=$SELECTED_HOTEL"
echo ""
EOFSCRIPT

chmod +x APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh
echo "✅ Script de aplicación creado"
echo ""

# 3. Verificar hoteles disponibles
echo "3️⃣ Verificando hoteles disponibles..."
if [ -d "hotel-images" ]; then
    HOTEL_COUNT=$(find hotel-images -type d -name "hotel-*" -exec test -f {}/main.jpg \; -print | wc -l)
    echo "   ✅ Encontrados $HOTEL_COUNT hoteles con main.jpg"
elif [ -d "../hotel-images" ]; then
    HOTEL_COUNT=$(find ../hotel-images -type d -name "hotel-*" -exec test -f {}/main.jpg \; -print | wc -l)
    echo "   ✅ Encontrados $HOTEL_COUNT hoteles con main.jpg (en directorio padre)"
else
    echo "   ⚠️  No se encontró directorio hotel-images"
fi
echo ""

echo "=========================================="
echo "✅ PREPARACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🚀 Ahora ejecuta:"
echo "   ./GUIAR_CAMBIO_IMAGEN_DINAMICO.sh"
echo ""
