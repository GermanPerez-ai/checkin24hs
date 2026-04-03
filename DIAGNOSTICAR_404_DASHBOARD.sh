#!/bin/bash
# Ejecutar EN EL SERVIDOR (SSH) para diagnosticar 404 en dashboard.checkin24hs.com
# Uso: ./DIAGNOSTICAR_404_DASHBOARD.sh

set -e
echo "=============================================="
echo "🔍 DIAGNÓSTICO 404 - dashboard.checkin24hs.com"
echo "=============================================="
echo ""

BASE="https://dashboard.checkin24hs.com"
echo "1️⃣ Probando HTTP (raíz /)..."
CODE_ROOT=$(curl -s -o /dev/null -w "%{http_code}" -L "$BASE/" 2>/dev/null || echo "err")
echo "   GET $BASE/ → $CODE_ROOT"
echo ""

echo "2️⃣ Probando /favicon.ico..."
CODE_FAV=$(curl -s -o /dev/null -w "%{http_code}" -L "$BASE/favicon.ico" 2>/dev/null || echo "err")
echo "   GET $BASE/favicon.ico → $CODE_FAV"
echo ""

echo "3️⃣ Probando /index..."
CODE_IDX=$(curl -s -o /dev/null -w "%{http_code}" -L "$BASE/index" 2>/dev/null || echo "err")
echo "   GET $BASE/index → $CODE_IDX"
echo ""

echo "4️⃣ Probando /api/version..."
CODE_API=$(curl -s -o /dev/null -w "%{http_code}" -L "$BASE/api/version" 2>/dev/null || echo "err")
echo "   GET $BASE/api/version → $CODE_API"
echo ""

echo "----------------------------------------------"
if [ "$CODE_FAV" = "200" ] && [ "$CODE_IDX" = "200" ]; then
    echo "✅ Favicon e /index responden 200. No hay 404 en servidor."
    echo "   Si ves 404 en el navegador: Ctrl+Shift+R o vacía caché."
    exit 0
fi

echo "⚠️ Se detectaron 404. Comprobando si el contenedor tiene server.js con rutas favicon..."
echo ""

SERVICE="checkin24hs_dashboard"
CID=$(docker ps --filter "name=${SERVICE}" --format "{{.ID}}" 2>/dev/null | head -1)
if [ -z "$CID" ]; then
    CID=$(docker ps -q --filter "label=com.docker.swarm.service.name=${SERVICE}" 2>/dev/null | head -1)
fi
if [ -z "$CID" ]; then
    echo "   ❌ No se encontró contenedor del dashboard. ¿Servicio en otro host?"
    echo ""
    echo "💡 Acción: Reconstruir imagen en EasyPanel (Implementar con 'No cache') y volver a desplegar."
    exit 1
fi

echo "   Contenedor: $CID"
if docker exec "$CID" grep -q "FAVICON_SVG" /app/server.js 2>/dev/null; then
    echo "   ✅ El server.js del contenedor SÍ tiene rutas favicon."
    echo "   → Traefik o proxy podría estar bloqueando. Revisar reglas."
else
    echo "   ❌ El server.js del contenedor NO tiene rutas favicon."
    echo ""
    echo "💡 El contenedor usa una imagen VIEJA. Hay que RECONSTRUIR la imagen:"
    echo "   1. En EasyPanel: Dashboard → servicio 'dashboard' → Implementar"
    echo "   2. Activar 'No cache' / 'Rebuild' si existe la opción"
    echo "   3. Luego en servidor: ./ACTUALIZAR_DASHBOARD_FINAL.sh"
fi
echo ""
echo "=============================================="
