#!/bin/bash

# Script para verificar qué puertos están en uso
# Útil para verificar conflictos antes de configurar servicios WhatsApp

echo "🔍 Verificando puertos en uso..."
echo "=================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Puertos a verificar
PORTS=(3001 3002 3003 3004 80 443 8080)

echo "📊 Estado de puertos:"
echo ""

for PORT in "${PORTS[@]}"; do
    # Verificar si el puerto está en uso
    if command -v netstat &> /dev/null; then
        RESULT=$(netstat -tuln | grep ":$PORT " || true)
    elif command -v ss &> /dev/null; then
        RESULT=$(ss -tuln | grep ":$PORT " || true)
    elif command -v lsof &> /dev/null; then
        RESULT=$(lsof -i :$PORT 2>/dev/null || true)
    else
        echo -e "${YELLOW}⚠️  No se encontró herramienta para verificar puertos${NC}"
        break
    fi
    
    if [ -n "$RESULT" ]; then
        echo -e "${RED}❌ Puerto $PORT: EN USO${NC}"
        echo "   Detalles: $RESULT"
    else
        echo -e "${GREEN}✅ Puerto $PORT: DISPONIBLE${NC}"
    fi
done

echo ""
echo "=================================="
echo "📋 Verificando servicios Docker:"
echo ""

# Verificar servicios Docker
if command -v docker &> /dev/null; then
    echo "Servicios Docker activos:"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004|80|443" || echo "No hay servicios usando estos puertos"
else
    echo -e "${YELLOW}⚠️  Docker no está disponible${NC}"
fi

echo ""
echo "=================================="
echo "📋 Verificando servicios Docker Swarm:"
echo ""

# Verificar servicios Docker Swarm
if command -v docker &> /dev/null; then
    echo "Servicios Docker Swarm:"
    docker service ls --format "table {{.Name}}\t{{.Ports}}" | grep -E "whatsapp|3001|3002|3003|3004" || echo "No hay servicios WhatsApp en Swarm"
else
    echo -e "${YELLOW}⚠️  Docker no está disponible${NC}"
fi

echo ""
echo "=================================="
echo "✅ Verificación completada"
echo ""
echo "💡 Recomendaciones:"
echo "   - Los puertos 3001-3004 deben estar DISPONIBLES para WhatsApp"
echo "   - El puerto 80 puede estar en uso por otros servicios (normal)"
echo "   - Si un puerto está en uso, detén el servicio que lo usa o usa otro puerto"

