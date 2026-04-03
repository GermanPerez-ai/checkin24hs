#!/bin/bash

echo "=========================================="
echo "🔍 Diagnóstico: Bad Gateway (502)"
echo "=========================================="
echo ""

echo "=== 1. Estado del Dashboard en PM2 ==="
pm2 list | grep dashboard
echo ""

echo "=== 2. Verificar puerto 3010 ==="
if netstat -tulpn 2>/dev/null | grep -q ":3010 " || ss -tulpn 2>/dev/null | grep -q ":3010 "; then
    echo "✅ Puerto 3010 está activo"
    netstat -tulpn 2>/dev/null | grep ":3010 " || ss -tulpn 2>/dev/null | grep ":3010 "
else
    echo "❌ Puerto 3010 NO está activo"
fi
echo ""

echo "=== 3. Probar acceso directo al dashboard ==="
if curl -s --max-time 3 http://localhost:3010 > /dev/null 2>&1; then
    echo "✅ Dashboard responde en localhost:3010"
    curl -I http://localhost:3010 2>&1 | head -3
else
    echo "❌ Dashboard NO responde en localhost:3010"
fi
echo ""

echo "=== 4. Verificar configuración de Traefik ==="
if [ -f /etc/easypanel/traefik/config/main.yaml ]; then
    echo "Buscando configuración del dashboard:"
    grep -A 5 "checkin24hs_dashboard-1" /etc/easypanel/traefik/config/main.yaml | grep -A 3 "loadBalancer" || echo "No se encontró configuración"
else
    echo "❌ Archivo de configuración de Traefik no encontrado"
fi
echo ""

echo "=== 5. Verificar logs del dashboard ==="
pm2 logs dashboard --lines 10 --nostream 2>&1 | tail -10
echo ""

echo "=== 6. Verificar logs de Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    docker logs "$TRAEFIK_CONTAINER" --tail 20 2>&1 | grep -i "dashboard\|502\|bad gateway" || echo "No hay errores recientes relacionados"
else
    echo "❌ Contenedor de Traefik no encontrado"
fi
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="

