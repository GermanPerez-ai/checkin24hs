#!/bin/bash

echo "🔍 VERIFICANDO SI EL CÓDIGO ACTUALIZADO SE CARGÓ EN EL SERVIDOR"
echo "=================================================================="
echo ""

# 1. Encontrar contenedor del dashboard
echo "1️⃣ Buscando contenedor del dashboard..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo "Listando todos los contenedores:"
    docker ps | head -10
    exit 1
fi

echo "✅ Contenedor encontrado: $DASHBOARD_CONTAINER"
echo ""

# 2. Verificar si el archivo dashboard.html existe
echo "2️⃣ Verificando si dashboard.html existe en el contenedor..."
docker exec $DASHBOARD_CONTAINER test -f /app/dashboard.html && echo "✅ dashboard.html existe" || echo "❌ dashboard.html NO existe"
echo ""

# 3. Buscar la función loadExpensesTable simplificada
echo "3️⃣ Verificando si loadExpensesTable tiene la versión simplificada..."
docker exec $DASHBOARD_CONTAINER grep -A 5 "Cargar tabla de gastos - VERSIÓN SIMPLIFICADA" /app/dashboard.html > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Versión simplificada encontrada"
else
    echo "❌ Versión simplificada NO encontrada - el código NO se actualizó"
    echo ""
    echo "Buscando versión antigua..."
    docker exec $DASHBOARD_CONTAINER grep -A 5 "Iniciando loadExpensesTable" /app/dashboard.html | head -3
fi
echo ""

# 4. Verificar si tiene cssText (método simplificado)
echo "4️⃣ Verificando si usa cssText (método simplificado)..."
docker exec $DASHBOARD_CONTAINER grep -c "tableContainer.style.cssText" /app/dashboard.html > /dev/null 2>&1

if [ $? -eq 0 ]; then
    COUNT=$(docker exec $DASHBOARD_CONTAINER grep -c "tableContainer.style.cssText" /app/dashboard.html)
    echo "✅ cssText encontrado $COUNT veces"
else
    echo "❌ cssText NO encontrado - código antiguo"
fi
echo ""

# 5. Verificar versión de loadQuotesTable
echo "5️⃣ Verificando si loadQuotesTable tiene la versión simplificada..."
docker exec $DASHBOARD_CONTAINER grep -A 5 "Cargar tabla de cotizaciones - VERSIÓN SIMPLIFICADA" /app/dashboard.html > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Versión simplificada de loadQuotesTable encontrada"
else
    echo "❌ Versión simplificada NO encontrada"
fi
echo ""

# 6. Verificar CSS de table-container
echo "6️⃣ Verificando CSS de table-container..."
docker exec $DASHBOARD_CONTAINER grep -A 10 "#expenses-section .table-container," /app/dashboard.html | head -5
echo ""

# 7. Verificar tamaño del archivo (para comparar)
echo "7️⃣ Tamaño del archivo dashboard.html:"
docker exec $DASHBOARD_CONTAINER ls -lh /app/dashboard.html | awk '{print $5}'
echo ""

# 8. Verificar última modificación
echo "8️⃣ Última modificación del archivo:"
docker exec $DASHBOARD_CONTAINER stat -c %y /app/dashboard.html 2>/dev/null || docker exec $DASHBOARD_CONTAINER ls -l /app/dashboard.html | awk '{print $6, $7, $8}'
echo ""

# 9. Mostrar fragmento de la función loadExpensesTable
echo "9️⃣ Fragmento de loadExpensesTable (primeras 15 líneas):"
docker exec $DASHBOARD_CONTAINER grep -A 15 "async function loadExpensesTable" /app/dashboard.html | head -15
echo ""

echo "✅ Verificación completa"
echo ""
echo "📋 CONCLUSIÓN:"
echo "Si ves '❌' en alguna verificación, el código NO se actualizó correctamente."
echo "Necesitas hacer un nuevo deploy del servicio dashboard en EasyPanel."
