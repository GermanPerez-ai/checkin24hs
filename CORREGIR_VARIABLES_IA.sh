#!/bin/bash
# Script para corregir las variables de entorno de IA en el servidor

echo "=========================================="
echo "CORREGIR VARIABLES DE IA"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar variables actuales
echo "=== VARIABLES ACTUALES ==="
docker exec $CONTAINER_ID env | grep -E "(AUTO_REPLY|FLOR_ENABLED|GEMINI_API_KEY)" | grep -v "PASSWORD\|SECRET"
echo ""

# Verificar si están configuradas en EasyPanel (Docker service)
echo "=== VERIFICANDO SERVICIO DOCKER ==="
SERVICE_NAME=$(docker inspect $CONTAINER_ID --format '{{.Name}}' | sed 's/\///')
echo "Servicio: $SERVICE_NAME"
echo ""

# Obtener información del servicio
echo "Variables de entorno del servicio:"
docker inspect $CONTAINER_ID --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E "(AUTO_REPLY|FLOR_ENABLED|GEMINI_API_KEY)" | grep -v "PASSWORD\|SECRET"
echo ""

echo "=========================================="
echo "INSTRUCCIONES"
echo "=========================================="
echo ""
echo "Si AUTO_REPLY o FLOR_ENABLED están en 'false' o '0', necesitas:"
echo ""
echo "1. Acceder a EasyPanel: http://72.61.58.240:3006"
echo "2. Ir al servicio de WhatsApp"
echo "3. Variables de entorno"
echo "4. Verificar/Agregar:"
echo "   - AUTO_REPLY=true (o 1)"
echo "   - FLOR_ENABLED=true (o 1)"
echo "   - GEMINI_API_KEY=tu_api_key"
echo "5. Reiniciar el servicio"
echo ""
