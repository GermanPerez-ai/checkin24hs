#!/bin/bash

echo "=========================================="
echo "⚙️ ARREGLAR EASYPANEL - Redirección"
echo "=========================================="
echo ""

# 1. Verificar servicio EasyPanel
echo "1️⃣ Verificando servicio EasyPanel..."
EASYPANEL_CONTAINER=$(docker ps | grep easypanel | grep -v traefik | head -1 | awk '{print $1}')
EASYPANEL_NAME=$(docker ps | grep easypanel | grep -v traefik | head -1 | awk '{print $NF}')

if [ -z "$EASYPANEL_CONTAINER" ]; then
    echo "❌ No se encontró contenedor EasyPanel"
    echo ""
    echo "Buscando en Docker Swarm..."
    docker service ls | grep -i easypanel
    exit 1
fi

echo "✅ Contenedor encontrado: $EASYPANEL_NAME"
echo ""

# 2. Ver puertos
echo "2️⃣ Verificando puertos de EasyPanel..."
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -i easypanel | grep -v traefik
echo ""

# Obtener puerto interno
EASYPANEL_PORT=$(docker inspect "$EASYPANEL_CONTAINER" | grep -i '"exposedports"' -A 10 | grep -oP '\d+/tcp' | head -1 | cut -d'/' -f1)

if [ -z "$EASYPANEL_PORT" ]; then
    # Intentar obtener desde docker ps
    EASYPANEL_PORT=$(docker ps | grep easypanel | grep -v traefik | grep -oP '\d+->\d+' | head -1 | cut -d'>' -f2)
fi

echo "Puerto detectado: ${EASYPANEL_PORT:-NO_DETECTADO}"
echo ""

# 3. Verificar configuración Traefik
echo "3️⃣ Verificando configuración Traefik..."
TRAEFIK_CONFIG="/etc/easypanel/traefik/config/main.yaml"

if [ ! -f "$TRAEFIK_CONFIG" ]; then
    echo "❌ Archivo de configuración no encontrado: $TRAEFIK_CONFIG"
    exit 1
fi

echo "Buscando configuración relacionada con EasyPanel o puerto 3000..."
grep -B 5 -A 15 "easypanel\|3000" "$TRAEFIK_CONFIG" | head -40
echo ""

# 4. Verificar qué está en el puerto 3000
echo "4️⃣ Verificando qué está corriendo en puerto 3000..."
PORT_3000=$(netstat -tulpn 2>/dev/null | grep :3000 || ss -tulpn 2>/dev/null | grep :3000)
if [ -n "$PORT_3000" ]; then
    echo "$PORT_3000"
    echo ""
    echo "Este es el DASHBOARD, no EasyPanel"
else
    echo "⚠️ Nada corriendo en puerto 3000"
fi
echo ""

# 5. Verificar puerto 8080 (puerto común de EasyPanel)
echo "5️⃣ Verificando puerto 8080 (puerto común de EasyPanel)..."
PORT_8080=$(netstat -tulpn 2>/dev/null | grep :8080 || ss -tulpn 2>/dev/null | grep :8080)
if [ -n "$PORT_8080" ]; then
    echo "✅ Algo está corriendo en 8080:"
    echo "$PORT_8080"
else
    echo "⚠️ Nada corriendo en puerto 8080"
fi
echo ""

# 6. Probar acceso a EasyPanel
echo "6️⃣ Probando acceso a EasyPanel..."
if [ -n "$EASYPANEL_PORT" ]; then
    echo "Probando http://localhost:$EASYPANEL_PORT"
    curl -I http://localhost:$EASYPANEL_PORT 2>&1 | head -5
    echo ""
    
    echo "Probando desde dentro del contenedor..."
    docker exec "$EASYPANEL_CONTAINER" wget -qO- http://localhost:$EASYPANEL_PORT 2>&1 | head -3
fi
echo ""

# 7. Solución
echo "=========================================="
echo "🔧 SOLUCIÓN"
echo "=========================================="
echo ""
echo "El problema es que EasyPanel está redirigiendo al puerto 3000 (dashboard)"
echo "en lugar de su propio puerto."
echo ""
echo "Pasos para corregir:"
echo ""
echo "1. Hacer backup de la configuración:"
echo "   cp $TRAEFIK_CONFIG ${TRAEFIK_CONFIG}.backup.\$(date +%Y%m%d_%H%M%S)"
echo ""
echo "2. Editar la configuración:"
echo "   nano $TRAEFIK_CONFIG"
echo ""
echo "3. Buscar la sección que apunta a puerto 3000 para EasyPanel"
echo "   y cambiarla al puerto correcto de EasyPanel (probablemente 8080)"
echo ""
echo "4. Si EasyPanel corre en 8080, buscar y cambiar:"
echo "   De: url: \"http://72.61.58.240:3000\""
echo "   A: url: \"http://72.61.58.240:8080\""
echo ""
echo "5. Reiniciar Traefik:"
echo "   docker service update --force traefik"
echo ""
echo "6. Verificar:"
echo "   Ir a https://hpanel.hostinger.com/vps/1152402/overview"
echo "   Hacer clic en 'Gestionar panel'"
echo "   Debería llevarte a EasyPanel, no al dashboard"
echo ""

