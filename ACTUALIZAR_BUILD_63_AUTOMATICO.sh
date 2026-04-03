#!/bin/bash
# Script para actualizar automáticamente dashboard a Build #63 después de cada rebuild
# Ejecutar este script después de que EasyPanel complete un rebuild

echo "=========================================="
echo "🔄 ACTUALIZACIÓN AUTOMÁTICA A BUILD #63"
echo "=========================================="
echo ""

# Esperar a que el servicio esté completamente iniciado
echo "⏳ Esperando 30 segundos para que el servicio se inicie..."
sleep 30

# Buscar contenedor
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    echo "   Esperando 30 segundos más..."
    sleep 30
    CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
    
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ Aún no hay contenedor activo"
        echo "   Verifica el estado: docker service ps checkin24hs_dashboard"
        exit 1
    fi
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# Verificar Build actual
BUILD_LINE=$(docker exec "$CONTAINER_ID" grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html 2>/dev/null | head -1)
BUILD_NUM=$(echo "$BUILD_LINE" | sed -n 's/.*DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/p')

echo "Build actual en contenedor: #$BUILD_NUM"
echo ""

if [ "$BUILD_NUM" = "63" ]; then
    echo "✅ El contenedor ya tiene Build #63"
    echo ""
    echo "🔍 Verificando Build servido..."
    sleep 10
    
    EXTERNAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k https://dashboard.checkin24hs.com 2>/dev/null || echo "error")
    if [ "$EXTERNAL_CODE" = "200" ]; then
        SERVED_BUILD=$(curl -s -k -L https://dashboard.checkin24hs.com 2>/dev/null | grep "DASHBOARD_BUILD_NUMBER" | sed -n 's/.*DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/p')
        if [ "$SERVED_BUILD" = "63" ]; then
            echo "✅ ¡PERFECTO! Dashboard está sirviendo Build #63"
            exit 0
        fi
    fi
fi

echo "⚠️ El contenedor tiene Build #$BUILD_NUM, actualizando a #63..."
echo ""

# Descargar Build #63 desde GitHub
TEMP_FILE="/tmp/dashboard_build63_auto_$$.html"
curl -s -L "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html" -o "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
    echo "❌ Error al descargar desde GitHub"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Verificar que tiene Build #63
DOWNLOADED_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$TEMP_FILE" | head -1)

if [ "$DOWNLOADED_BUILD" != "63" ]; then
    echo "⚠️ El archivo descargado tiene Build #$DOWNLOADED_BUILD, no #63"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "✅ Archivo descargado tiene Build #63"
echo ""

# Crear backup
BACKUP_NAME="dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec "$CONTAINER_ID" cp /app/dashboard.html "/app/$BACKUP_NAME" 2>/dev/null && echo "✅ Backup creado: $BACKUP_NAME" || echo "⚠️ No se pudo crear backup"
echo ""

# Detener Node.js temporalmente
echo "🔄 Deteniendo Node.js temporalmente..."
docker exec "$CONTAINER_ID" pkill -f "node.*server.js" 2>/dev/null
sleep 5
echo ""

# Copiar archivo
echo "📤 Copiando archivo al contenedor..."
docker cp "$TEMP_FILE" "${CONTAINER_ID}:/app/dashboard.html"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado"
    echo ""
    
    # Verificar
    sleep 3
    NEW_BUILD_LINE=$(docker exec "$CONTAINER_ID" grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html 2>/dev/null | head -1)
    NEW_BUILD_NUM=$(echo "$NEW_BUILD_LINE" | sed -n 's/.*DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/p')
    
    if [ "$NEW_BUILD_NUM" = "63" ]; then
        echo "✅ Verificación: Build #$NEW_BUILD_NUM en el contenedor"
        echo ""
        echo "⏳ Esperando 20 segundos para que el servidor se reinicie..."
        sleep 20
        
        # Verificar acceso y Build servido
        EXTERNAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k https://dashboard.checkin24hs.com 2>/dev/null || echo "error")
        echo "   Acceso externo: HTTP $EXTERNAL_CODE"
        
        if [ "$EXTERNAL_CODE" = "200" ]; then
            SERVED_BUILD=$(curl -s -k -L https://dashboard.checkin24hs.com 2>/dev/null | grep "DASHBOARD_BUILD_NUMBER" | sed -n 's/.*DASHBOARD_BUILD_NUMBER = \([0-9]*\).*/\1/p')
            echo "   Build servido: #$SERVED_BUILD"
            
            if [ "$SERVED_BUILD" = "63" ]; then
                echo ""
                echo "✅ ¡PERFECTO! Dashboard actualizado a Build #63"
            else
                echo ""
                echo "⚠️ Build servido: #$SERVED_BUILD (esperado: #63)"
                echo "   Espera 15 segundos más y recarga el navegador"
            fi
        else
            echo "⚠️ Problema de acceso (HTTP $EXTERNAL_CODE)"
            echo "   Verificando labels de Traefik..."
            TRAEFIK_LABELS=$(docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | wc -l)
            if [ "$TRAEFIK_LABELS" -lt "6" ]; then
                echo "   Restaurando labels..."
                docker service update \
                  --label-add "traefik.enable=true" \
                  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
                  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
                  --label-add "traefik.http.routers.dashboard.tls=true" \
                  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
                  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
                  checkin24hs_dashboard
                echo "   ✅ Labels restauradas"
            fi
        fi
    else
        echo "⚠️ Verificación: Build #$NEW_BUILD_NUM (esperado: #63)"
    fi
else
    echo "❌ Error al copiar archivo"
    echo "   El archivo puede estar bloqueado"
fi

# Limpiar
rm -f "$TEMP_FILE"

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
