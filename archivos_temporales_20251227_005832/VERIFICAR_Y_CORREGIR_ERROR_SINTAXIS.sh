#!/bin/bash

echo "=========================================="
echo "Verificar y Corregir Error de Sintaxis"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Verificar archivo local
echo "1. Verificando archivo local:"
if [ -f "dashboard.html" ]; then
    LOCAL_SIZE=$(ls -lh dashboard.html | awk '{print $5}')
    echo "   ✅ dashboard.html existe ($LOCAL_SIZE)"
else
    echo "   ❌ dashboard.html no existe"
    exit 1
fi
echo ""

# 2. Buscar contenedor
echo "2. Buscando contenedor:"
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "   ⚠️  No se encontró contenedor, esperando..."
    sleep 5
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "   ❌ No se encontró contenedor"
    exit 1
fi

echo "   ✅ Contenedor: $CONTAINER_ID"
echo ""

# 3. Verificar archivo en contenedor ANTES de copiar
echo "3. Archivo actual en el contenedor:"
CONTAINER_SIZE=$(docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null | awk '{print $5}')
echo "   Tamaño: $CONTAINER_SIZE"
echo ""

# 4. Copiar archivo
echo "4. Copiando dashboard.html al contenedor..."
docker cp dashboard.html $CONTAINER_ID:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "   ✅ Archivo copiado"
else
    echo "   ❌ Error al copiar"
    exit 1
fi

# 5. Verificar que se copió correctamente
echo ""
echo "5. Verificando archivo copiado:"
NEW_CONTAINER_SIZE=$(docker exec $CONTAINER_ID ls -lh /app/dashboard.html 2>/dev/null | awk '{print $5}')
echo "   Tamaño después de copiar: $NEW_CONTAINER_SIZE"

if [ "$LOCAL_SIZE" = "$NEW_CONTAINER_SIZE" ]; then
    echo "   ✅ Los tamaños coinciden"
else
    echo "   ⚠️  Los tamaños NO coinciden"
fi

# 6. Verificar línea 5150 específicamente
echo ""
echo "6. Verificando línea 5150 en el contenedor:"
LINE_5150=$(docker exec $CONTAINER_ID sed -n '5150p' /app/dashboard.html 2>/dev/null)
echo "   Línea 5150: $LINE_5150"

# 7. Verificar que showSection esté definida al inicio
echo ""
echo "7. Verificando definición de showSection al inicio del body:"
SHOW_SECTION_LINES=$(docker exec $CONTAINER_ID grep -n "showSection definida INMEDIATAMENTE" /app/dashboard.html 2>/dev/null | head -1)
if [ ! -z "$SHOW_SECTION_LINES" ]; then
    echo "   ✅ showSection encontrada en: $SHOW_SECTION_LINES"
else
    echo "   ⚠️  showSection no encontrada al inicio"
fi

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "Si los tamaños coinciden, el archivo se copió correctamente."
echo "Recarga la página con Ctrl+F5 para limpiar la caché."
echo ""

