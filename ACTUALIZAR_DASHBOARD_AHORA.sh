#!/bin/bash

echo "🔄 FORZANDO ACTUALIZACIÓN DEL DASHBOARD DESDE GITHUB"
echo "====================================================="
echo ""

# 1. Encontrar servicio
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    echo "Listando servicios disponibles:"
    docker service ls
    exit 1
fi

DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)
echo "✅ Servicio encontrado: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 2. Verificar configuración actual
echo "2️⃣ Verificando configuración actual del servicio..."
echo "Imagen actual:"
docker service inspect $DASHBOARD_SERVICE --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null
echo ""

# 3. Forzar actualización
echo "3️⃣ Forzando actualización del servicio..."
echo "Esto hará que Docker Swarm descargue el código más reciente desde GitHub"
echo ""

docker service update --force $DASHBOARD_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Comando de actualización enviado correctamente"
else
    echo "❌ Error al actualizar el servicio"
    exit 1
fi

echo ""
echo "⏳ Esperando 30 segundos para que el servicio se actualice..."
sleep 30

# 4. Verificar estado
echo ""
echo "4️⃣ Verificando estado del servicio..."
docker service ps $DASHBOARD_SERVICE --no-trunc | head -5
echo ""

# 5. Verificar contenedor nuevo
echo "5️⃣ Esperando 30 segundos más para que el contenedor nuevo esté listo..."
sleep 30

NEW_CONTAINER=$(docker ps --filter "name=$DASHBOARD_NAME" --format "{{.ID}}" | head -1)
if [ ! -z "$NEW_CONTAINER" ]; then
    echo "✅ Contenedor nuevo encontrado: $NEW_CONTAINER"
    echo ""
    echo "6️⃣ Verificando código en el contenedor nuevo..."
    
    # Esperar un poco más para que el código se copie
    sleep 10
    
    docker exec $NEW_CONTAINER grep -A 5 "Cargar tabla de gastos - VERSIÓN SIMPLIFICADA" /app/dashboard.html > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Código actualizado encontrado en el contenedor nuevo"
    else
        echo "⚠️ Código aún no actualizado - puede que necesite más tiempo"
        echo "Verificando si el archivo existe..."
        docker exec $NEW_CONTAINER test -f /app/dashboard.html && echo "✅ dashboard.html existe" || echo "❌ dashboard.html NO existe"
    fi
else
    echo "⚠️ No se encontró contenedor nuevo aún - el servicio puede estar reiniciando"
fi

echo ""
echo "✅ Proceso de actualización completado"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Espera 1-2 minutos más para que el servicio termine de actualizarse"
echo "2. Verifica el código con: ./VERIFICAR_CODIGO_CARGADO_SERVIDOR.sh"
echo "3. Prueba acceder a: https://dashboard.checkin24hs.com/"
echo "4. Abre la consola del navegador (F12) y verifica los logs cuando vayas a la sección Gastos"
echo ""
echo "💡 Si el código aún no se actualiza, puede que necesites:"
echo "   - Verificar que EasyPanel esté configurado para usar GitHub"
echo "   - Hacer un deploy manual desde EasyPanel"
echo "   - Verificar que el repositorio GitHub tenga los últimos cambios"
