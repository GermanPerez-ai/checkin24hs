#!/bin/bash
# Script completo con TODOS los pasos necesarios después de cada deploy
# Ejecutar después de hacer deploy desde EasyPanel

SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "PASOS DESPUÉS DE DEPLOY"
echo "=========================================="
echo ""
echo "Este script ejecuta TODOS los pasos necesarios:"
echo "1. Actualizar dashboard.html en el servidor (desde GitHub)"
echo "2. Reiniciar el servicio"
echo "3. Reaplicar labels de Traefik"
echo "4. Verificar que todo funcione correctamente"
echo ""
read -p "Presiona Enter para continuar o Ctrl+C para cancelar..."
echo ""

# ==========================================
# PASO 1: Actualizar archivo en servidor
# ==========================================
echo "=========================================="
echo "PASO 1: ACTUALIZAR ARCHIVO EN SERVIDOR"
echo "=========================================="
echo ""

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_PATH="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== 1.1: Crear backup del archivo actual ==="
if [ -f "$DASHBOARD_PATH" ]; then
    cp "$DASHBOARD_PATH" "$BACKUP_PATH"
    echo "✅ Backup creado: $BACKUP_PATH"
else
    echo "⚠️ No hay archivo para hacer backup"
fi
echo ""

echo "=== 1.2: Descargar archivo correcto desde GitHub ==="
curl -s -o "$DASHBOARD_PATH" https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
if [ $? -eq 0 ]; then
    echo "✅ Archivo descargado"
    NEW_SIZE=$(stat -c%s "$DASHBOARD_PATH" 2>/dev/null || echo "0")
    echo "   Tamaño nuevo: $NEW_SIZE bytes"
else
    echo "❌ ERROR: No se pudo descargar el archivo"
    exit 1
fi
echo ""

echo "=== 1.3: Verificar Build Number ==="
BUILD_NUMBER=$(grep -oE "window\.DASHBOARD_BUILD_NUMBER\s*=\s*[0-9]+" "$DASHBOARD_PATH" 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "No encontrado")
echo "Build Number: #$BUILD_NUMBER"
if [ -n "$BUILD_NUMBER" ] && [ "$BUILD_NUMBER" != "No encontrado" ]; then
    echo "✅ OK: Archivo tiene Build #$BUILD_NUMBER"
else
    echo "❌ ERROR: No se pudo extraer Build Number"
    exit 1
fi
echo ""

echo "=== 1.4: Verificar permisos ==="
chmod 644 "$DASHBOARD_PATH"
echo "✅ Permisos actualizados"
echo ""

# ==========================================
# PASO 2: Reiniciar servicio
# ==========================================
echo "=========================================="
echo "PASO 2: REINICIAR SERVICIO"
echo "=========================================="
echo ""

echo "=== 2.1: Reiniciar servicio para que Node.js lea el archivo actualizado ==="
docker service update --force "$SERVICE_NAME"
if [ $? -eq 0 ]; then
    echo "✅ Servicio reiniciado"
    echo "   Esperando 20 segundos para que el servicio se inicie..."
    sleep 20
else
    echo "❌ ERROR: No se pudo reiniciar el servicio"
    exit 1
fi
echo ""

# ==========================================
# PASO 3: Reaplicar labels de Traefik
# ==========================================
echo "=========================================="
echo "PASO 3: REAPLICAR LABELS DE TRAEFIK"
echo "=========================================="
echo ""

echo "=== 3.1: Verificar labels actuales ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== 3.2: Agregar labels de Traefik ==="
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web,websecure" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --label-add "traefik.http.routers.dashboard-https.rule=Host(\`$DOMAIN\`)" \
  --label-add "traefik.http.routers.dashboard-https.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-https.service=dashboard" \
  --label-add "traefik.http.routers.dashboard-https.tls=true" \
  --label-add "traefik.http.routers.dashboard-https.tls.certresolver=letsencrypt" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Labels agregadas"
else
    echo "❌ ERROR: Error al agregar labels"
    exit 1
fi
echo ""

echo "=== 3.3: Verificar labels aplicadas ==="
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik | sort
echo ""

echo "=== 3.4: Esperar 20 segundos para Traefik ==="
sleep 20
echo ""

# ==========================================
# PASO 4: Verificar que todo funcione
# ==========================================
echo "=========================================="
echo "PASO 4: VERIFICAR QUE TODO FUNCIONE"
echo "=========================================="
echo ""

echo "=== 4.1: Buscar contenedor activo ==="
CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
if [ -z "$CONTAINER" ]; then
    echo "❌ ERROR: No se encontro contenedor"
    exit 1
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 4.2: Verificar Build Number en contenedor ==="
sleep 5
CONTAINER_BUILD_LINE=$(docker exec "$CONTAINER" grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html 2>/dev/null | head -1)
CONTAINER_BUILD=$(echo "$CONTAINER_BUILD_LINE" | grep -oE "[0-9]+" | head -1 || echo "")
CONTAINER_VERSION_LINE=$(docker exec "$CONTAINER" grep "DASHBOARD_VERSION = " /app/dashboard.html 2>/dev/null | head -1)
CONTAINER_VERSION=$(echo "$CONTAINER_VERSION_LINE" | grep -oE "'[^']+'" | head -1 | tr -d "'" || echo "")
echo "Version en contenedor: $CONTAINER_VERSION"
echo "Build Number en contenedor: #$CONTAINER_BUILD"
if [ "$CONTAINER_BUILD" = "$BUILD_NUMBER" ]; then
    echo "✅ OK: Contenedor tiene Build #$CONTAINER_BUILD (coincide con GitHub)"
else
    echo "⚠️ ADVERTENCIA: Build Number no coincide (contenedor: #$CONTAINER_BUILD, GitHub: #$BUILD_NUMBER)"
fi
echo ""

echo "=== 4.3: Verificar HTTP ==="
sleep 5
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" 2>/dev/null)
HTTP_RESPONSE=$(curl -s "http://$DOMAIN" 2>/dev/null)
echo "HTTP Status: $HTTP_STATUS"
if [ -n "$HTTP_RESPONSE" ]; then
    HTTP_BUILD_LINE=$(echo "$HTTP_RESPONSE" | grep "DASHBOARD_BUILD_NUMBER" | head -1)
    HTTP_BUILD=$(echo "$HTTP_BUILD_LINE" | grep -oE "[0-9]+" | head -1 || echo "")
    HTTP_VERSION_LINE=$(echo "$HTTP_RESPONSE" | grep "DASHBOARD_VERSION = " | head -1)
    HTTP_VERSION=$(echo "$HTTP_VERSION_LINE" | grep -oE "'[^']+'" | head -1 | tr -d "'" || echo "")
    echo "Version HTTP: $HTTP_VERSION"
    echo "Build HTTP: #$HTTP_BUILD"
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ OK: HTTP funciona (Status 200)"
    else
        echo "⚠️ ADVERTENCIA: HTTP Status: $HTTP_STATUS"
    fi
else
    echo "❌ ERROR: No se pudo obtener respuesta HTTP"
fi
echo ""

echo "=== 4.4: Verificar HTTPS ==="
sleep 5
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null)
HTTPS_RESPONSE=$(curl -s "https://$DOMAIN" 2>/dev/null)
echo "HTTPS Status: $HTTPS_STATUS"
if [ -n "$HTTPS_RESPONSE" ]; then
    HTTPS_BUILD_LINE=$(echo "$HTTPS_RESPONSE" | grep "DASHBOARD_BUILD_NUMBER" | head -1)
    HTTPS_BUILD=$(echo "$HTTPS_BUILD_LINE" | grep -oE "[0-9]+" | head -1 || echo "")
    HTTPS_VERSION_LINE=$(echo "$HTTPS_RESPONSE" | grep "DASHBOARD_VERSION = " | head -1)
    HTTPS_VERSION=$(echo "$HTTPS_VERSION_LINE" | grep -oE "'[^']+'" | head -1 | tr -d "'" || echo "")
    echo "Version HTTPS: $HTTPS_VERSION"
    echo "Build HTTPS: #$HTTPS_BUILD"
    if [ "$HTTPS_STATUS" = "200" ]; then
        echo "✅ OK: HTTPS funciona (Status 200)"
    else
        echo "⚠️ ADVERTENCIA: HTTPS Status: $HTTPS_STATUS"
    fi
else
    echo "❌ ERROR: No se pudo obtener respuesta HTTPS"
fi
echo ""

# ==========================================
# RESUMEN FINAL
# ==========================================
echo "=========================================="
echo "RESUMEN FINAL"
echo "=========================================="
echo ""
echo "Archivo en servidor:"
echo "  - Build: #$BUILD_NUMBER"
echo ""
echo "Contenedor:"
echo "  - Version: $CONTAINER_VERSION"
echo "  - Build: #$CONTAINER_BUILD"
echo ""
echo "HTTP (http://$DOMAIN):"
echo "  - Status: $HTTP_STATUS"
echo "  - Version: $HTTP_VERSION"
echo "  - Build: #$HTTP_BUILD"
echo ""
echo "HTTPS (https://$DOMAIN):"
echo "  - Status: $HTTPS_STATUS"
echo "  - Version: $HTTPS_VERSION"
echo "  - Build: #$HTTPS_BUILD"
echo ""

if [ "$HTTP_STATUS" = "200" ] && [ "$HTTPS_STATUS" = "200" ] && [ "$CONTAINER_BUILD" = "$BUILD_NUMBER" ]; then
    echo "✅ TODO CORRECTO"
    echo ""
    echo "El display de versión debería aparecer en el sidebar"
    echo "debajo de 'Checkin24hs Admin' mostrando:"
    echo "  - v$CONTAINER_VERSION"
    echo "  - Build #$CONTAINER_BUILD"
    echo ""
    echo "Si no aparece, recarga la página con Ctrl+F5"
else
    echo "⚠️ ADVERTENCIA: Algunos checks fallaron"
    echo "   Revisa los mensajes anteriores para más detalles"
fi
echo "=========================================="
echo ""
