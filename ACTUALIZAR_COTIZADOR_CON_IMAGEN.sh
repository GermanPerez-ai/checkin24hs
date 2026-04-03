#!/bin/bash
# Script para actualizar cotizador con la nueva URL de imagen

echo "=========================================="
echo "🔄 ACTUALIZANDO COTIZADOR CON IMAGEN"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_cotizador"
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor del cotizador"
    echo "   Buscando servicios disponibles..."
    docker service ls --format "{{.Name}}" | grep -i cotizador
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 1. Descargar código desde GitHub
echo "1️⃣ Descargando código desde GitHub..."
TEMP_DIR="/tmp/cotizador_update_$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

git clone --depth 1 https://github.com/GermanPerez-ai/checkin24hs.git 2>&1 | tail -3

if [ ! -f "checkin24hs/cotizador-cliente.html" ]; then
    echo "❌ No se encontró cotizador-cliente.html"
    exit 1
fi

echo "✅ Código descargado"
echo ""

# 2. Verificar que tiene el parámetro ?v=2
echo "2️⃣ Verificando que tiene parámetro ?v=2..."
if grep -q "og-cotizar.jpg?v=2" checkin24hs/cotizador-cliente.html; then
    echo "   ✅ Parámetro ?v=2 encontrado"
else
    echo "   ⚠️  Parámetro ?v=2 no encontrado"
fi
echo ""

# 3. Copiar al contenedor
echo "3️⃣ Copiando cotizador-cliente.html al contenedor..."
# El cotizador usa nginx y sirve index.html
docker cp checkin24hs/cotizador-cliente.html "$CONTAINER_ID:/usr/share/nginx/html/index.html"

if [ $? -eq 0 ]; then
    echo "   ✅ Archivo copiado"
else
    echo "   ❌ Error al copiar"
    exit 1
fi
echo ""

# 4. Reiniciar servicio
echo "4️⃣ Reiniciando servicio..."
docker service update --force "$SERVICE_NAME" > /dev/null 2>&1
echo "   ✅ Servicio reiniciado"
echo "   ⏳ Esperando 10 segundos..."
sleep 10
echo ""

# 5. Verificar
echo "5️⃣ Verificando..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://cotizar.checkin24hs.com/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Cotizador responde correctamente (HTTP $HTTP_CODE)"
    
    # Verificar que tiene el parámetro
    if curl -s https://cotizar.checkin24hs.com/ | grep -q "og-cotizar.jpg?v=2"; then
        echo "   ✅ URL de imagen con parámetro ?v=2 confirmada"
    else
        echo "   ⚠️  Parámetro ?v=2 no encontrado en el HTML"
    fi
else
    echo "   ⚠️  Cotizador responde con HTTP $HTTP_CODE"
fi
echo ""

# 6. Limpiar
cd /
rm -rf "$TEMP_DIR"
echo "✅ Limpieza completada"
echo ""

echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Espera 1-2 minutos para que el servicio se estabilice"
echo "   2. Prueba acceder a: https://cotizar.checkin24hs.com/"
echo "   3. Verifica el código fuente (Ctrl+U) y busca 'og-cotizar.jpg?v=2'"
echo "   4. Envía un mensaje de WhatsApp con el enlace"
echo ""
echo "💡 IMPORTANTE:"
echo "   - WhatsApp puede tardar varias horas en actualizar el cache"
echo "   - Si no aparece la imagen, espera o prueba desde otro dispositivo"
echo "   - El parámetro ?v=2 fuerza la actualización del cache"
echo ""
