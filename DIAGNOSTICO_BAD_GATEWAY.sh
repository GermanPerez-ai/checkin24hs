#!/bin/bash

echo "=========================================="
echo "🔍 Diagnóstico de Bad Gateway - Dashboard"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar si el servicio está corriendo
echo "1. Verificando servicios de Docker/EasyPanel..."
echo ""

# Verificar contenedores de EasyPanel
if command -v docker &> /dev/null; then
    echo "📦 Contenedores relacionados con dashboard:"
    docker ps --filter "name=dashboard" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "⚠️  No se encontraron contenedores con 'dashboard'"
    echo ""
    
    echo "📦 Todos los contenedores corriendo:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
    echo ""
else
    echo "⚠️  Docker no está instalado o no está en el PATH"
    echo ""
fi

# 2. Verificar puerto 3000
echo "2. Verificando puerto 3000:"
if netstat -tlnp 2>/dev/null | grep -q ":3000"; then
    echo -e "${GREEN}✅ Puerto 3000 está escuchando${NC}"
    netstat -tlnp 2>/dev/null | grep ":3000"
elif ss -tlnp 2>/dev/null | grep -q ":3000"; then
    echo -e "${GREEN}✅ Puerto 3000 está escuchando${NC}"
    ss -tlnp 2>/dev/null | grep ":3000"
else
    echo -e "${RED}❌ Puerto 3000 NO está escuchando${NC}"
    echo "   Esto significa que el servicio del dashboard no está corriendo"
fi
echo ""

# 3. Verificar si el servicio responde localmente
echo "3. Probando conexión local al puerto 3000:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ El servicio responde en localhost:3000${NC}"
    echo "   Respuesta:"
    curl -s http://localhost:3000 | head -5
elif curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ El servicio responde en 127.0.0.1:3000${NC}"
else
    echo -e "${RED}❌ El servicio NO responde en localhost:3000${NC}"
    echo "   Esto confirma que el servicio no está corriendo o no está en el puerto 3000"
fi
echo ""

# 4. Verificar configuración de Traefik (si existe)
echo "4. Verificando configuración de Traefik:"
TRAEFIK_CONFIG="/etc/easypanel/traefik/config/main.yaml"
if [ -f "$TRAEFIK_CONFIG" ]; then
    if grep -q "dashboard.checkin24hs.com" "$TRAEFIK_CONFIG"; then
        echo -e "${GREEN}✅ Configuración encontrada para dashboard.checkin24hs.com:${NC}"
        grep -A 10 "dashboard.checkin24hs.com" "$TRAEFIK_CONFIG" | head -15
    else
        echo -e "${YELLOW}⚠️  No se encontró configuración para dashboard.checkin24hs.com${NC}"
    fi
else
    echo "⚠️  No se encontró el archivo de configuración de Traefik en $TRAEFIK_CONFIG"
fi
echo ""

# 5. Verificar logs de servicios (si es posible)
echo "5. Verificando logs recientes:"
if command -v docker &> /dev/null; then
    DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
    if [ ! -z "$DASHBOARD_CONTAINER" ]; then
        echo "📋 Últimas 10 líneas de logs del contenedor $DASHBOARD_CONTAINER:"
        docker logs --tail 10 "$DASHBOARD_CONTAINER" 2>&1 || echo "⚠️  No se pudieron obtener los logs"
    else
        echo "⚠️  No se encontró un contenedor de dashboard corriendo"
    fi
else
    echo "⚠️  Docker no está disponible para ver logs"
fi
echo ""

# 6. Verificar procesos Node.js
echo "6. Verificando procesos Node.js:"
if pgrep -f "node.*server.js" > /dev/null; then
    echo -e "${GREEN}✅ Hay procesos Node.js corriendo server.js:${NC}"
    ps aux | grep "node.*server.js" | grep -v grep
else
    echo -e "${RED}❌ No hay procesos Node.js corriendo server.js${NC}"
fi
echo ""

# 7. Verificar archivo server.js
echo "7. Verificando archivo server.js:"
if [ -f "/root/checkin24hs/server.js" ]; then
    echo -e "${GREEN}✅ Archivo encontrado en /root/checkin24hs/server.js${NC}"
elif [ -f "./server.js" ]; then
    echo -e "${GREEN}✅ Archivo encontrado en ./server.js${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró server.js en las rutas comunes${NC}"
    echo "   Buscando en otras ubicaciones..."
    find /root /home /var -name "server.js" -type f 2>/dev/null | head -5
fi
echo ""

# 8. Resumen y recomendaciones
echo "=========================================="
echo "📊 Resumen y Recomendaciones"
echo "=========================================="
echo ""

if netstat -tlnp 2>/dev/null | grep -q ":3000" || ss -tlnp 2>/dev/null | grep -q ":3000"; then
    echo -e "${GREEN}✅ El puerto 3000 está activo${NC}"
    echo "   → El servicio está corriendo"
    echo "   → Verifica la configuración del dominio en EasyPanel"
    echo "   → Verifica que Traefik/Nginx esté configurado correctamente"
else
    echo -e "${RED}❌ El puerto 3000 NO está activo${NC}"
    echo "   → El servicio del dashboard NO está corriendo"
    echo "   → Ve a EasyPanel y verifica:"
    echo "     1. Que el servicio esté en verde (Running)"
    echo "     2. Que el puerto interno sea 3000"
    echo "     3. Que la variable PORT=3000 esté configurada"
    echo "     4. Que el comando de inicio sea 'node server.js'"
    echo "     5. Revisa los logs del servicio para ver errores"
fi

echo ""
echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Revisa los resultados arriba"
echo "   2. Si el puerto 3000 NO está activo, ve a EasyPanel y verifica el servicio"
echo "   3. Si el puerto 3000 SÍ está activo, verifica la configuración del dominio"
echo "   4. Consulta SOLUCION_BAD_GATEWAY_DASHBOARD.md para más detalles"
echo ""

