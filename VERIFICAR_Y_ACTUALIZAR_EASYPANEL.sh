#!/bin/bash
# Script para verificar el estado actual y preparar actualización en EasyPanel

echo "=========================================="
echo "🔍 VERIFICACIÓN DEL ESTADO ACTUAL"
echo "=========================================="
echo ""

# Buscar contenedor activo
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    echo "   Verificando servicios..."
    docker service ls | grep dashboard
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar versión actual
echo "1️⃣ Verificando versión actual en el contenedor..."
CURRENT_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" /app/dashboard.html 2>/dev/null | head -1)

if [ -z "$CURRENT_BUILD" ]; then
    echo "⚠️ No se pudo obtener BUILD_NUMBER"
    CURRENT_BUILD="unknown"
fi

echo "   Build actual: #$CURRENT_BUILD"
echo ""

# Verificar versión en GitHub
echo "2️⃣ Verificando versión en GitHub..."
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"
GITHUB_BUILD=$(curl -s -L "$GITHUB_REPO" 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)

if [ -n "$GITHUB_BUILD" ]; then
    echo "   Build en GitHub: #$GITHUB_BUILD"
else
    echo "   ⚠️ No se pudo obtener BUILD_NUMBER de GitHub"
    GITHUB_BUILD="unknown"
fi

echo ""

# Resumen
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "Versión actual en contenedor: Build #$CURRENT_BUILD"
echo "Versión en GitHub: Build #$GITHUB_BUILD"
echo ""

if [ "$CURRENT_BUILD" != "$GITHUB_BUILD" ] && [ "$GITHUB_BUILD" != "unknown" ]; then
    echo "⚠️ EL DASHBOARD NO ESTÁ ACTUALIZADO"
    echo ""
    echo "📋 Para actualizar permanentemente en EasyPanel:"
    echo ""
    echo "   1. Abre EasyPanel en tu navegador"
    echo "   2. Ve al proyecto 'checkin24hs'"
    echo "   3. Haz clic en el servicio 'dashboard'"
    echo "   4. Haz clic en el botón 'Implementar' o 'Rebuild'"
    echo "   5. Espera 5-10 minutos a que termine"
    echo ""
    echo "   ⚠️ IMPORTANTE: Asegúrate de que el servicio esté configurado"
    echo "      para construir desde GitHub:"
    echo "      https://github.com/GermanPerez-ai/checkin24hs"
    echo ""
    echo "   Si no está configurado, necesitarás:"
    echo "   - Configurar el Build Path en EasyPanel"
    echo "   - O usar el método de actualización directa (temporal)"
    echo ""
else
    echo "✅ El dashboard está actualizado"
    echo "   Versión: Build #$CURRENT_BUILD"
fi

echo ""
echo "=========================================="
