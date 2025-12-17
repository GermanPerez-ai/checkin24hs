#!/bin/bash
# Script para limpiar sesión de WhatsApp en Docker

echo "🧹 Limpiando sesión de WhatsApp en Docker..."
echo ""

# Nombre del contenedor (ajusta según tu configuración)
CONTAINER_NAME="whatsapp-server"

# Verificar si el contenedor existe
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "⚠️  Contenedor '${CONTAINER_NAME}' no encontrado"
    echo "📋 Contenedores disponibles:"
    docker ps -a --format '{{.Names}}'
    echo ""
    read -p "Ingresa el nombre del contenedor: " CONTAINER_NAME
fi

# Detener el contenedor
echo "🛑 Deteniendo contenedor..."
docker stop ${CONTAINER_NAME}

# Eliminar la sesión
echo "🗑️  Eliminando sesión de WhatsApp..."
docker exec ${CONTAINER_NAME} rm -rf .wwebjs_auth 2>/dev/null || \
docker run --rm -v ${CONTAINER_NAME}:/data alpine sh -c "rm -rf /data/.wwebjs_auth" 2>/dev/null || \
echo "⚠️  No se pudo eliminar automáticamente. Ejecuta manualmente:"
echo "   docker exec ${CONTAINER_NAME} rm -rf .wwebjs_auth"

# Reiniciar el contenedor
echo "🔄 Reiniciando contenedor..."
docker start ${CONTAINER_NAME}

echo ""
echo "✅ Limpieza completada!"
echo "📱 El servidor debería mostrar el código QR al reiniciar"
echo ""

