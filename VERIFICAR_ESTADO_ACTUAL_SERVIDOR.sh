#!/bin/bash
# Script para verificar el estado actual del código en el servidor
# y diagnosticar el problema de dimensiones 0x0

echo "🔍 VERIFICANDO ESTADO ACTUAL DEL SERVIDOR"
echo "=========================================="
echo ""

# 1. Buscar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i dashboard | grep -v proxy | head -1)
if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi
echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
echo ""

# 2. Buscar contenedor del dashboard
echo "2️⃣ Buscando contenedor activo..."
CONTAINER_ID=$(docker ps --filter "name=${DASHBOARD_SERVICE}" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    docker service ps $DASHBOARD_SERVICE --no-trunc | head -5
    exit 1
fi
CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format "{{.Names}}")
echo "✅ Contenedor encontrado: $CONTAINER_NAME ($CONTAINER_ID)"
echo ""

# 3. Verificar dashboard.html en el contenedor
echo "3️⃣ Verificando dashboard.html en el contenedor..."
DASHBOARD_FILE="/app/dashboard.html"
if docker exec $CONTAINER_ID test -f $DASHBOARD_FILE; then
    echo "✅ dashboard.html encontrado en: $DASHBOARD_FILE"
    
    # Verificar tamaño
    FILE_SIZE=$(docker exec $CONTAINER_ID stat -c%s $DASHBOARD_FILE)
    echo "📏 Tamaño del archivo: $FILE_SIZE bytes"
    
    # Verificar fecha de modificación
    MOD_DATE=$(docker exec $CONTAINER_ID stat -c%y $DASHBOARD_FILE)
    echo "📅 Fecha de modificación: $MOD_DATE"
    echo ""
    
    # Verificar cambios recientes
    echo "4️⃣ Verificando cambios recientes..."
    
    # Verificar si tiene el código de position absolute
    if docker exec $CONTAINER_ID grep -q "Último intento de emergencia: usando position absolute" $DASHBOARD_FILE; then
        echo "✅ Código de position absolute encontrado"
    else
        echo "❌ Código de position absolute NO encontrado"
    fi
    
    # Verificar si tiene el código de verificación de expenses-section
    if docker exec $CONTAINER_ID grep -q "expenses-section tiene 0px, forzando dimensiones de nuevo" $DASHBOARD_FILE; then
        echo "✅ Código de verificación de expenses-section encontrado"
    else
        echo "❌ Código de verificación de expenses-section NO encontrado"
    fi
    
    # Verificar si tiene el cálculo desde viewport
    if docker exec $CONTAINER_ID grep -q "Calculando dimensiones desde viewport" $DASHBOARD_FILE; then
        echo "✅ Código de cálculo desde viewport encontrado"
    else
        echo "❌ Código de cálculo desde viewport NO encontrado"
    fi
    
    echo ""
    
    # Verificar estructura HTML de expenses-section
    echo "5️⃣ Verificando estructura HTML de expenses-section..."
    if docker exec $CONTAINER_ID grep -q 'id="expenses-section"' $DASHBOARD_FILE; then
        echo "✅ expenses-section encontrado en HTML"
        
        # Mostrar contexto alrededor de expenses-section
        echo ""
        echo "📋 Contexto de expenses-section:"
        docker exec $CONTAINER_ID grep -A 5 'id="expenses-section"' $DASHBOARD_FILE | head -10
    else
        echo "❌ expenses-section NO encontrado en HTML"
    fi
    
    echo ""
    
    # Verificar estructura HTML de table-container
    echo "6️⃣ Verificando estructura HTML de table-container..."
    if docker exec $CONTAINER_ID grep -q 'class="table-container"' $DASHBOARD_FILE; then
        echo "✅ table-container encontrado en HTML"
        
        # Contar cuántos table-container hay
        COUNT=$(docker exec $CONTAINER_ID grep -c 'class="table-container"' $DASHBOARD_FILE)
        echo "📊 Número de table-container encontrados: $COUNT"
        
        # Mostrar contexto alrededor del table-container en expenses-section
        echo ""
        echo "📋 Contexto de table-container en expenses-section:"
        docker exec $CONTAINER_ID grep -B 2 -A 5 'expenses-section.*table-container\|table-container.*expenses-section' $DASHBOARD_FILE | head -15
    else
        echo "❌ table-container NO encontrado en HTML"
    fi
    
else
    echo "❌ dashboard.html NO encontrado en $DASHBOARD_FILE"
    echo "🔍 Buscando en otras ubicaciones..."
    docker exec $CONTAINER_ID find / -name "dashboard.html" 2>/dev/null | head -5
fi

echo ""
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo "✅ Servicio: $DASHBOARD_SERVICE"
echo "✅ Contenedor: $CONTAINER_NAME"
echo "✅ Archivo: $DASHBOARD_FILE"
echo ""
echo "🔧 PRÓXIMOS PASOS:"
echo "1. Si el código no está actualizado, ejecutar el script de actualización"
echo "2. Revisar la estructura HTML en el navegador (DevTools > Elements)"
echo "3. Verificar si hay CSS que esté ocultando los elementos"
