#!/bin/bash

echo "🔄 FORZANDO ACTUALIZACIÓN DEL DASHBOARD"
echo "========================================"
echo ""

# 1. Encontrar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $1}' | head -1)
DASHBOARD_NAME=$(docker service ls | grep -i dashboard | grep -v proxy | awk '{print $2}' | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "✅ Dashboard encontrado: $DASHBOARD_NAME ($DASHBOARD_SERVICE)"
echo ""

# 2. Verificar estado actual
echo "2️⃣ Estado actual del servicio..."
docker service ps $DASHBOARD_SERVICE --no-trunc | head -3
echo ""

# 3. Forzar actualización (esto debería hacer pull del código de GitHub)
echo "3️⃣ Forzando actualización del servicio (esto puede tardar varios minutos)..."
echo "   Esto hará que el servicio reconstruya la imagen desde GitHub"
echo ""

docker service update --force --update-parallelism 1 --update-delay 10s $DASHBOARD_SERVICE

if [ $? -eq 0 ]; then
    echo "✅ Actualización iniciada correctamente"
else
    echo "❌ Error al actualizar el servicio"
    exit 1
fi
echo ""

# 4. Monitorear el progreso
echo "4️⃣ Monitoreando progreso de la actualización..."
echo "   (Esto puede tardar 2-5 minutos dependiendo del tamaño del código)"
echo ""

for i in {1..30}; do
    sleep 10
    STATUS=$(docker service ps $DASHBOARD_SERVICE --no-trunc | head -2 | tail -1 | awk '{print $6}')
    echo "   Intento $i/30: Estado = $STATUS"
    
    if [ "$STATUS" = "Running" ]; then
        echo "✅ Servicio actualizado y corriendo"
        break
    fi
done

echo ""

# 5. Verificar estado final
echo "5️⃣ Estado final del servicio..."
docker service ps $DASHBOARD_SERVICE --no-trunc | head -5
echo ""

# 6. Ver logs recientes
echo "6️⃣ Últimos logs del servicio (últimas 20 líneas)..."
docker service logs $DASHBOARD_SERVICE --tail 20 2>&1 | tail -20
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "   1. Espera 1-2 minutos más para que el servicio se estabilice"
echo "   2. Recarga la página del dashboard (Ctrl+F5 para limpiar caché)"
echo "   3. Abre la consola del navegador (F12)"
echo "   4. Deberías ver estos logs al cargar:"
echo "      🔍 Verificando funciones de modales nuevos..."
echo "        - addNewExpenseNew: function"
echo "        - openQuoteModalNew: function"
echo "        - expenseModalNew: ✅ encontrado"
echo "        - quoteModalNew: ✅ encontrado"
echo ""
echo "💡 Si no aparecen los logs nuevos:"
echo "   - Limpia la caché del navegador (Ctrl+Shift+Delete)"
echo "   - O prueba en modo incógnito"
echo "   - Verifica que el código esté en GitHub: https://github.com/GermanPerez-ai/checkin24hs"
echo ""
