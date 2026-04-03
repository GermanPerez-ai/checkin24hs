#!/bin/bash
cd /root/checkin24hs

echo "=== FORZAR COPIA CORRECTA DEL ARCHIVO ==="
echo ""

# 1. Verificar archivo en servidor
echo "1. Verificando archivo en servidor..."
echo "   Línea 5150:"
sed -n '5150p' deploy/dashboard.html
echo "   Tamaño:"
ls -lh deploy/dashboard.html | awk '{print $5}'
echo ""

# 2. Detener TODOS los contenedores
echo "2. Deteniendo TODOS los contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Contenedores detenidos"
echo ""

# 3. Copiar archivo a cada contenedor DETENIDO
echo "3. Copiando archivo a contenedores DETENIDOS..."
for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "   Copiando a: $container"
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    if [ $? -eq 0 ]; then
        echo "   ✅ Copiado"
        # Verificar que se copió correctamente
        LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
        if echo "$LINE_5150" | grep -q "const username\|return JSON.parse\|}"; then
            echo "   ✅ Verificado: línea 5150 correcta"
        else
            echo "   ⚠️  ADVERTENCIA: línea 5150 puede estar incorrecta: $LINE_5150"
        fi
    else
        echo "   ❌ Error copiando"
    fi
done
echo ""

# 4. Reiniciar contenedores
echo "4. Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") > /dev/null 2>&1
sleep 5
echo "✅ Contenedores reiniciados"
echo ""

# 5. Verificación final
echo "5. Verificación final en contenedores ACTIVOS..."
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    echo "   --- $container ---"
    LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    echo "   Línea 5150: $LINE_5150"
    HAS_SEARCH=$(docker exec $container grep -c "window.searchUsers = function" /app/dashboard.html 2>/dev/null)
    echo "   Funciones globales encontradas: $HAS_SEARCH"
done
echo ""

echo "✅ PROCESO COMPLETADO"
echo ""
echo "INSTRUCCIONES:"
echo "1. Cierra TODAS las ventanas del navegador"
echo "2. Abre una ventana NUEVA en modo incognito"
echo "3. Ve a dashboard.checkin24hs.com"
echo "4. Presiona Ctrl+Shift+R para hard refresh"
echo "5. Verifica la consola (F12)"
