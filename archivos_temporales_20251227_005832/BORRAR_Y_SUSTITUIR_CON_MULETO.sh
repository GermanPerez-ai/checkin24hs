#!/bin/bash
cd /root/checkin24hs

echo "=== BORRAR ARCHIVO CORRUPTO Y SUSTITUIR CON MULETO.HTML ==="
echo ""

# 1. Crear backup del archivo corrupto (por seguridad)
echo "1. Creando backup del archivo actual..."
if [ -f "deploy/dashboard.html" ]; then
    cp deploy/dashboard.html deploy/dashboard.html.backup.corrupto.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup creado"
else
    echo "⚠️  No existe deploy/dashboard.html"
fi
echo ""

# 2. Verificar que el archivo nuevo existe (debe estar subido desde Windows)
echo "2. Verificando archivo nuevo..."
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ ERROR: No se encuentra deploy/dashboard.html"
    echo "   Necesitas subirlo primero con: scp desde Windows"
    exit 1
fi

# 3. Verificar que el archivo nuevo es correcto
echo "3. Verificando contenido del archivo nuevo..."
echo "   Línea 5150:"
sed -n '5150p' deploy/dashboard.html
echo ""
echo "   Funciones globales:"
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1
grep -n "window.showSection = function" deploy/dashboard.html | head -1
echo ""

# 4. Detener contenedores
echo "4. Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") > /dev/null 2>&1
sleep 2
echo "✅ Contenedores detenidos"
echo ""

# 5. Copiar archivo nuevo a todos los contenedores
echo "5. Copiando archivo nuevo a contenedores..."
for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "   Copiando a: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    if [ $? -eq 0 ]; then
        echo "   ✅ Archivo copiado"
    else
        echo "   ❌ Error copiando"
    fi
done
echo ""

# 6. Reiniciar contenedores
echo "6. Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") > /dev/null 2>&1
sleep 3
echo "✅ Contenedores reiniciados"
echo ""

# 7. Verificar estado
echo "7. Verificando estado final..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep checkin24hs_dashboard
echo ""

# 8. Verificar archivo en un contenedor
FIRST_CONTAINER=$(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1)
if [ ! -z "$FIRST_CONTAINER" ]; then
    echo "8. Verificando archivo en contenedor: $FIRST_CONTAINER"
    echo "   Línea 5150:"
    docker exec $FIRST_CONTAINER sed -n '5150p' /app/dashboard.html
    echo "   Funciones globales:"
    docker exec $FIRST_CONTAINER grep -n "window.searchUsers = function" /app/dashboard.html | head -1
fi
echo ""

echo "✅ PROCESO COMPLETADO"
echo ""
echo "INSTRUCCIONES:"
echo "1. Abre el dashboard en modo incognito (Ctrl+Shift+N)"
echo "2. Presiona Ctrl+Shift+R para hard refresh"
echo "3. Verifica que no haya errores en la consola"

