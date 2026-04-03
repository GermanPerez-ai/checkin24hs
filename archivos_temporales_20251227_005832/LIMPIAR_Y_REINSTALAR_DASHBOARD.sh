#!/bin/bash
cd /root/checkin24hs

echo "=== LIMPIEZA Y REINSTALACION DE DASHBOARD ==="
echo ""

# 1. Verificar archivo actual
echo "1. Verificando archivo actual..."
echo "Línea 5150:"
sed -n '5150p' deploy/dashboard.html
echo ""
echo "Funciones globales:"
grep -n "window.showSection = function" deploy/dashboard.html | head -1
grep -n "window.searchUsers = function" deploy/dashboard.html | head -1
echo ""

# 2. Crear backup del archivo actual
echo "2. Creando backup..."
cp deploy/dashboard.html deploy/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"
echo ""

# 3. Verificar que el archivo correcto existe
if [ ! -f "deploy/dashboard.html" ]; then
    echo "❌ ERROR: No se encuentra deploy/dashboard.html"
    exit 1
fi

# 4. Verificar tamaño del archivo (debe ser ~1.2MB)
SIZE=$(ls -lh deploy/dashboard.html | awk '{print $5}')
echo "3. Tamaño del archivo: $SIZE"
echo ""

# 5. Detener todos los contenedores de dashboard
echo "4. Deteniendo contenedores..."
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "  Deteniendo: $container"
    docker stop $container > /dev/null 2>&1
done
sleep 2
echo "✅ Contenedores detenidos"
echo ""

# 6. Eliminar contenedores antiguos (opcional, comentado por seguridad)
# echo "5. Eliminando contenedores antiguos..."
# for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
#     echo "  Eliminando: $container"
#     docker rm $container > /dev/null 2>&1
# done
# echo "✅ Contenedores eliminados"
# echo ""

# 7. Copiar archivo correcto a todos los contenedores
echo "5. Copiando archivo correcto a contenedores..."
for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "  Copiando a: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    if [ $? -eq 0 ]; then
        echo "    ✅ Archivo copiado"
    else
        echo "    ❌ Error copiando archivo"
    fi
done
echo ""

# 8. Reiniciar contenedores
echo "6. Reiniciando contenedores..."
for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "  Reiniciando: $container"
    docker start $container > /dev/null 2>&1
    sleep 1
done
echo "✅ Contenedores reiniciados"
echo ""

# 9. Verificar que los contenedores estén corriendo
echo "7. Verificando estado de contenedores..."
sleep 3
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    STATUS=$(docker inspect --format='{{.State.Status}}' $container)
    echo "  $container: $STATUS"
done
echo ""

echo "✅ PROCESO COMPLETADO"
echo ""
echo "INSTRUCCIONES:"
echo "1. Abre el dashboard en modo incognito (Ctrl+Shift+N)"
echo "2. Presiona Ctrl+Shift+R para hard refresh"
echo "3. Verifica que no haya errores en la consola"
echo ""
echo "Si aún hay errores, ejecuta EasyPanel y haz un 'Redeploy' del servicio dashboard"

