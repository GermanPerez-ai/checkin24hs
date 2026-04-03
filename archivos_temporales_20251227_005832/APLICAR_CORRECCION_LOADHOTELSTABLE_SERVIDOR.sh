#!/bin/bash

# ============================================
# SCRIPT: Aplicar Corrección loadHotelsTable en Servidor
# ============================================
# Este script descarga el dashboard.html corregido desde GitHub
# y lo aplica directamente en el contenedor del servidor

echo "🔧 APLICANDO CORRECCIÓN: loadHotelsTable Duplicado"
echo "=========================================="
echo ""

# 1. Encontrar el contenedor del dashboard
echo "📋 Paso 1: Buscando contenedor del dashboard..."
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ ERROR: No se encontró el contenedor del dashboard"
    echo ""
    echo "💡 Intentando buscar por nombre de servicio..."
    DASHBOARD_CONTAINER=$(docker ps | grep -i "checkin24hs\|dashboard" | awk '{print $1}' | head -1)
    
    if [ -z "$DASHBOARD_CONTAINER" ]; then
        echo "❌ No se encontró ningún contenedor relacionado"
        echo ""
        echo "📋 Contenedores disponibles:"
        docker ps
        exit 1
    fi
fi

echo "✅ Contenedor encontrado: $DASHBOARD_CONTAINER"
echo ""

# 2. Hacer backup del archivo actual
echo "📋 Paso 2: Haciendo backup del dashboard.html actual..."
docker exec $DASHBOARD_CONTAINER cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || \
docker exec $DASHBOARD_CONTAINER cp dashboard.html dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || \
echo "⚠️  No se pudo hacer backup (continuando de todas formas)"
echo ""

# 3. Descargar el archivo corregido desde GitHub
echo "📋 Paso 3: Descargando dashboard.html corregido desde GitHub..."
TEMP_FILE="/tmp/dashboard_corregido_$(date +%Y%m%d_%H%M%S).html"

curl -s -o "$TEMP_FILE" "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"

if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
    echo "❌ ERROR: No se pudo descargar el archivo desde GitHub"
    exit 1
fi

echo "✅ Archivo descargado: $TEMP_FILE"
echo ""

# 4. Verificar que el archivo no tiene declaraciones duplicadas
echo "📋 Paso 4: Verificando que el archivo está corregido..."
DUPLICADOS=$(grep -c "async function loadHotelsTable\|function loadHotelsTable" "$TEMP_FILE" || echo "0")

if [ "$DUPLICADOS" -gt "1" ]; then
    echo "⚠️  ADVERTENCIA: El archivo descargado tiene $DUPLICADOS declaraciones de loadHotelsTable"
    echo "   Esto puede indicar que el archivo en GitHub aún no está actualizado"
    echo ""
    echo "💡 Verificando líneas específicas..."
    grep -n "async function loadHotelsTable\|function loadHotelsTable" "$TEMP_FILE"
    echo ""
    read -p "¿Continuar de todas formas? (s/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        rm -f "$TEMP_FILE"
        exit 1
    fi
else
    echo "✅ Archivo verificado: solo $DUPLICADOS declaración(es) de loadHotelsTable"
fi
echo ""

# 5. Copiar el archivo al contenedor
echo "📋 Paso 5: Copiando archivo corregido al contenedor..."

# Intentar diferentes rutas comunes
if docker cp "$TEMP_FILE" "$DASHBOARD_CONTAINER:/app/dashboard.html" 2>/dev/null; then
    echo "✅ Archivo copiado a /app/dashboard.html"
elif docker cp "$TEMP_FILE" "$DASHBOARD_CONTAINER:/dashboard.html" 2>/dev/null; then
    echo "✅ Archivo copiado a /dashboard.html"
elif docker cp "$TEMP_FILE" "$DASHBOARD_CONTAINER:./dashboard.html" 2>/dev/null; then
    echo "✅ Archivo copiado a ./dashboard.html"
else
    echo "❌ ERROR: No se pudo copiar el archivo al contenedor"
    echo ""
    echo "💡 Intentando método alternativo..."
    
    # Método alternativo: usar docker exec con cat
    docker exec -i $DASHBOARD_CONTAINER sh -c "cat > /app/dashboard.html" < "$TEMP_FILE" 2>/dev/null || \
    docker exec -i $DASHBOARD_CONTAINER sh -c "cat > dashboard.html" < "$TEMP_FILE" 2>/dev/null || {
        echo "❌ No se pudo copiar el archivo con ningún método"
        rm -f "$TEMP_FILE"
        exit 1
    }
    echo "✅ Archivo copiado usando método alternativo"
fi

rm -f "$TEMP_FILE"
echo ""

# 6. Reiniciar el contenedor
echo "📋 Paso 6: Reiniciando contenedor..."
docker restart $DASHBOARD_CONTAINER
echo "✅ Contenedor reiniciado"
echo ""

# 7. Esperar a que el servicio se inicie
echo "📋 Paso 7: Esperando a que el servicio se inicie..."
echo "   ⏳ Espera 15 segundos..."
sleep 15
echo ""

# 8. Verificar logs
echo "📋 Paso 8: Verificando logs del contenedor..."
docker logs $DASHBOARD_CONTAINER --tail 20
echo ""

echo "=========================================="
echo "✅ CORRECCIÓN APLICADA"
echo "=========================================="
echo ""
echo "📋 Resumen:"
echo "   - Contenedor: $DASHBOARD_CONTAINER"
echo "   - Archivo actualizado: dashboard.html"
echo "   - Contenedor reiniciado"
echo ""
echo "🔍 Próximos pasos:"
echo "   1. Abre https://dashboard.checkin24hs.com"
echo "   2. Presiona Ctrl+F5 (limpiar caché)"
echo "   3. Abre la consola (F12)"
echo "   4. Verifica que NO aparece: 'Identifier loadHotelsTable has already been declared'"
echo ""


