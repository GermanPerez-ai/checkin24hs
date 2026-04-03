#!/bin/bash
# Script para revisar el estado del dashboard y actualizarlo desde GitHub si es necesario
# Repositorio: https://github.com/GermanPerez-ai/checkin24hs

echo "=========================================="
echo "🔍 REVISIÓN Y ACTUALIZACIÓN DEL DASHBOARD"
echo "📦 Fuente: GitHub (GermanPerez-ai/checkin24hs)"
echo "=========================================="
echo ""

# Obtener versión desde GitHub (no hardcodear)
GITHUB_REPO="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"
EXPECTED_BUILD=$(curl -s -L "$GITHUB_REPO" 2>/dev/null | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
[ -z "$EXPECTED_BUILD" ] && EXPECTED_BUILD="0"

echo "📋 Build en GitHub: #$([ "$EXPECTED_BUILD" = "0" ] && echo "?" || echo "$EXPECTED_BUILD")"
echo "🔗 Repositorio: $GITHUB_REPO"
echo ""

# 1. Verificar servicio dashboard
echo "1️⃣ Verificando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i dashboard | grep -v proxy | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    echo ""
    echo "Servicios disponibles:"
    docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
    exit 1
fi

echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
echo ""

# 2. Verificar estado del servicio
echo "2️⃣ Verificando estado del servicio..."
SERVICE_STATUS=$(docker service ps "$DASHBOARD_SERVICE" --no-trunc --format "{{.CurrentState}}" | head -1)
echo "   Estado: $SERVICE_STATUS"

# Verificar si el estado contiene "Running" (puede ser "Running" o "Running X seconds ago")
if echo "$SERVICE_STATUS" | grep -q "Running"; then
    echo "✅ Servicio está corriendo"
else
    echo "⚠️ El servicio NO está corriendo"
    echo "   Estado actual: $SERVICE_STATUS"
    echo ""
    echo "📋 Tareas del servicio:"
    docker service ps "$DASHBOARD_SERVICE" --no-trunc | head -5
    echo ""
    echo "❓ ¿Deseas intentar reiniciar el servicio? (esto puede tardar varios minutos)"
    echo "   Ejecuta: docker service update --force $DASHBOARD_SERVICE"
    exit 1
fi

echo ""

# 3. Buscar contenedor activo
echo "3️⃣ Buscando contenedor activo..."
CONTAINER_ID=$(docker ps --filter "name=${DASHBOARD_SERVICE}" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    echo ""
    echo "Intentando método alternativo..."
    CONTAINER_ID=$(docker service ps "$DASHBOARD_SERVICE" --format "{{.Name}}" --no-trunc | head -1)
    if [ -n "$CONTAINER_ID" ]; then
        # Convertir nombre de tarea a ID de contenedor
        CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_ID" --format "{{.ID}}" | head -1)
    fi
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se pudo encontrar contenedor activo"
    echo ""
    echo "Contenedores relacionados:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | grep -i dashboard || echo "   Ninguno encontrado"
    exit 1
fi

CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format "{{.Names}}")
echo "✅ Contenedor encontrado: $CONTAINER_NAME ($CONTAINER_ID)"
echo ""

# 4. Buscar archivo dashboard.html en el contenedor
echo "4️⃣ Buscando archivo dashboard.html en el contenedor..."
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/var/www/html/dashboard.html"
    "/app/deploy/dashboard.html"
    "/app/index.html"
)

DASHBOARD_PATH=""
for path in "${DASHBOARD_PATHS[@]}"; do
    if docker exec "$CONTAINER_ID" test -f "$path" 2>/dev/null; then
        DASHBOARD_PATH="$path"
        echo "✅ Archivo encontrado en: $path"
        break
    fi
done

if [ -z "$DASHBOARD_PATH" ]; then
    echo "❌ No se encontró dashboard.html en el contenedor"
    echo ""
    echo "Estructura de /app:"
    docker exec "$CONTAINER_ID" ls -la /app 2>/dev/null | head -20
    exit 1
fi

echo ""

# 5. Verificar versión en el contenedor
echo "5️⃣ Verificando versión en el contenedor..."
CONTAINER_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$DASHBOARD_PATH" 2>/dev/null | head -1)

if [ -z "$CONTAINER_BUILD" ]; then
    echo "⚠️ No se pudo obtener BUILD_NUMBER del contenedor"
    CONTAINER_BUILD="unknown"
else
    echo "   Build encontrado: #$CONTAINER_BUILD"
fi

echo ""

# 6. Verificar versión en GitHub (para comparar)
echo "6️⃣ Verificando versión disponible en GitHub..."
GITHUB_BUILD=""
GITHUB_CONTENT=$(curl -s -L "$GITHUB_REPO" 2>/dev/null | head -200)

if [ -n "$GITHUB_CONTENT" ]; then
    GITHUB_BUILD=$(echo "$GITHUB_CONTENT" | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
    if [ -n "$GITHUB_BUILD" ]; then
        echo "   Build en GitHub: #$GITHUB_BUILD"
        # Actualizar EXPECTED_BUILD si GitHub tiene una versión más nueva
        if [ "$GITHUB_BUILD" -gt "$EXPECTED_BUILD" ]; then
            echo "   ⚠️ GitHub tiene una versión más nueva (#$GITHUB_BUILD vs #$EXPECTED_BUILD)"
            EXPECTED_BUILD=$GITHUB_BUILD
            echo "   📋 Usando Build #$EXPECTED_BUILD como versión esperada"
        fi
    else
        echo "   ⚠️ No se pudo obtener BUILD_NUMBER de GitHub"
    fi
else
    echo "   ⚠️ No se pudo conectar a GitHub"
fi

echo ""

# 7. Verificar qué se está sirviendo realmente
echo "7️⃣ Verificando qué se está sirviendo en https://dashboard.checkin24hs.com..."
SERVED_BUILD=""
SERVED_CONTENT=$(curl -s -k -L https://dashboard.checkin24hs.com 2>/dev/null | head -200)

if [ -n "$SERVED_CONTENT" ]; then
    SERVED_BUILD=$(echo "$SERVED_CONTENT" | grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" | head -1)
    if [ -n "$SERVED_BUILD" ]; then
        echo "   Build servido: #$SERVED_BUILD"
    else
        echo "   ⚠️ No se pudo obtener BUILD_NUMBER del contenido servido"
        SERVED_BUILD="unknown"
    fi
else
    echo "   ⚠️ No se pudo obtener contenido del servidor"
    SERVED_BUILD="unknown"
fi

echo ""

# 8. Resumen y diagnóstico
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "Versión en GitHub: Build #$([ -n "$GITHUB_BUILD" ] && echo "$GITHUB_BUILD" || echo "unknown")"
echo "Versión esperada: Build #$EXPECTED_BUILD"
echo "Versión en contenedor: Build #$CONTAINER_BUILD"
echo "Versión servida: Build #$SERVED_BUILD"
echo ""

# Determinar si hay problemas
HAS_PROBLEMS=false
NEEDS_UPDATE=false

if [ "$CONTAINER_BUILD" != "$EXPECTED_BUILD" ] && [ "$CONTAINER_BUILD" != "unknown" ]; then
    echo "⚠️ PROBLEMA: El contenedor tiene Build #$CONTAINER_BUILD, se espera #$EXPECTED_BUILD"
    HAS_PROBLEMS=true
    NEEDS_UPDATE=true
fi

if [ "$SERVED_BUILD" != "$EXPECTED_BUILD" ] && [ "$SERVED_BUILD" != "unknown" ]; then
    echo "⚠️ PROBLEMA: El servidor está sirviendo Build #$SERVED_BUILD, se espera #$EXPECTED_BUILD"
    HAS_PROBLEMS=true
    NEEDS_UPDATE=true
fi

if [ "$CONTAINER_BUILD" = "unknown" ]; then
    echo "⚠️ PROBLEMA: No se pudo verificar la versión en el contenedor"
    HAS_PROBLEMS=true
fi

if [ "$SERVED_BUILD" = "unknown" ]; then
    echo "⚠️ PROBLEMA: No se pudo verificar la versión servida"
    HAS_PROBLEMS=true
fi

echo ""

# 9. Si todo está bien
if [ "$HAS_PROBLEMS" = false ]; then
    echo "✅ TODO ESTÁ CORRECTO"
    echo ""
    echo "   - GitHub tiene Build #$([ -n "$GITHUB_BUILD" ] && echo "$GITHUB_BUILD" || echo "unknown")"
    echo "   - El contenedor tiene la versión correcta (Build #$CONTAINER_BUILD)"
    echo "   - El servidor está sirviendo la versión correcta (Build #$SERVED_BUILD)"
    echo ""
    echo "📋 Si aún ves problemas en el navegador:"
    echo "   1. Limpia la caché del navegador (Ctrl+Shift+R)"
    echo "   2. Abre en ventana de incógnito"
    echo "   3. Verifica la consola del navegador (F12)"
    exit 0
fi

# 10. Si hay problemas, ofrecer actualización
if [ "$NEEDS_UPDATE" = true ]; then
    echo "=========================================="
    echo "🔄 ACTUALIZACIÓN NECESARIA DESDE GITHUB"
    echo "=========================================="
    echo ""
    echo "Se detectó que el dashboard necesita actualizarse desde GitHub."
    echo ""
    echo "📋 Opciones de actualización:"
    echo "   1. Descargar desde GitHub y actualizar archivo en el contenedor (rápido, temporal)"
    echo "   2. Forzar actualización del servicio desde GitHub (lento, permanente)"
    echo ""
    echo "⚠️ NOTA: Ambas opciones descargan desde GitHub"
    echo "   Repositorio: https://github.com/GermanPerez-ai/checkin24hs"
    echo ""
    echo "¿Qué método deseas usar?"
    echo "   [1] Actualizar archivo directamente desde GitHub (recomendado para prueba rápida)"
    echo "   [2] Forzar actualización del servicio desde GitHub (recomendado para cambios permanentes)"
    echo "   [3] Cancelar"
    echo ""
    read -p "Opción (1/2/3): " OPTION
    
    case $OPTION in
        1)
            echo ""
            echo "🔄 Actualizando archivo directamente desde GitHub..."
            echo "📦 Repositorio: https://github.com/GermanPerez-ai/checkin24hs"
            echo ""
            
            # Crear backup
            echo "💾 Creando backup del archivo actual..."
            BACKUP_NAME="dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
            docker exec "$CONTAINER_ID" cp "$DASHBOARD_PATH" "${DASHBOARD_PATH}.${BACKUP_NAME}" 2>/dev/null && echo "✅ Backup creado" || echo "⚠️ No se pudo crear backup"
            echo ""
            
            # Descargar desde GitHub
            echo "📥 Descargando dashboard.html desde GitHub..."
            TEMP_FILE="/tmp/dashboard_new_$$.html"
            curl -s -L "$GITHUB_REPO" -o "$TEMP_FILE"
            
            if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
                echo "❌ Error al descargar desde GitHub"
                rm -f "$TEMP_FILE"
                exit 1
            fi
            
            FILE_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || stat -f%z "$TEMP_FILE" 2>/dev/null)
            echo "✅ Archivo descargado: $FILE_SIZE bytes"
            
            # Verificar que tiene el build correcto
            DOWNLOADED_BUILD=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$TEMP_FILE" | head -1)
            if [ "$DOWNLOADED_BUILD" != "$EXPECTED_BUILD" ]; then
                echo "⚠️ El archivo descargado tiene Build #$DOWNLOADED_BUILD, se espera #$EXPECTED_BUILD"
                echo "   Continuando de todas formas..."
            fi
            echo ""
            
            # Copiar al contenedor
            echo "📤 Copiando al contenedor..."
            docker cp "$TEMP_FILE" "${CONTAINER_ID}:${DASHBOARD_PATH}"
            
            if [ $? -eq 0 ]; then
                echo "✅ Archivo copiado"
                
                # Verificar
                sleep 2
                NEW_BUILD=$(docker exec "$CONTAINER_ID" grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" "$DASHBOARD_PATH" 2>/dev/null | head -1)
                if [ "$NEW_BUILD" = "$EXPECTED_BUILD" ]; then
                    echo "✅ Verificación: Build #$NEW_BUILD en el contenedor"
                else
                    echo "⚠️ Verificación: Build #$NEW_BUILD (esperado: #$EXPECTED_BUILD)"
                fi
                
                # Reiniciar contenedor
                echo ""
                echo "🔄 Reiniciando contenedor..."
                docker restart "$CONTAINER_ID"
                sleep 5
                
                if docker ps | grep -q "$CONTAINER_ID"; then
                    echo "✅ Contenedor reiniciado y corriendo"
                else
                    echo "⚠️ El contenedor no está corriendo, verifica los logs"
                fi
            else
                echo "❌ Error al copiar archivo"
                rm -f "$TEMP_FILE"
                exit 1
            fi
            
            # Limpiar
            rm -f "$TEMP_FILE"
            echo ""
            echo "✅ Actualización completada"
            echo ""
            echo "📋 Próximos pasos:"
            echo "   1. Espera 10-15 segundos para que el contenedor termine de iniciar"
            echo "   2. Limpia la caché del navegador (Ctrl+Shift+R)"
            echo "   3. Recarga el dashboard"
            echo ""
            echo "⚠️ NOTA: Esta actualización es TEMPORAL"
            echo "   Se perderá al hacer rebuild del servicio."
            echo "   Para hacerla permanente, usa la opción 2."
            ;;
        2)
            echo ""
            echo "🔄 Forzando actualización del servicio desde GitHub..."
            echo "📦 El servicio debe estar configurado para construir desde:"
            echo "   https://github.com/GermanPerez-ai/checkin24hs"
            echo ""
            echo "   Esto puede tardar varios minutos (reconstruye la imagen)..."
            echo ""
            
            # Verificar que el servicio está configurado para usar GitHub
            SERVICE_IMAGE=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null)
            echo "   Imagen actual: $SERVICE_IMAGE"
            echo ""
            
            docker service update --force --update-parallelism 1 --update-delay 10s "$DASHBOARD_SERVICE"
            
            if [ $? -eq 0 ]; then
                echo "✅ Actualización del servicio iniciada"
                echo ""
                echo "⏳ Monitoreando progreso..."
                for i in {1..30}; do
                    sleep 10
                    STATUS=$(docker service ps "$DASHBOARD_SERVICE" --no-trunc --format "{{.CurrentState}}" | head -1)
                    echo "   Intento $i/30: Estado = $STATUS"
                    
                    if [ "$STATUS" = "Running" ]; then
                        echo "✅ Servicio actualizado y corriendo"
                        break
                    fi
                done
                echo ""
                echo "📋 IMPORTANTE:"
                echo "   - El servicio se reconstruirá desde GitHub"
                echo "   - Después del reinicio, ejecuta este script nuevamente para verificar"
                echo "   - O ejecuta: ACTUALIZAR_DESPUES_REINICIO.sh"
                echo ""
                echo "⚠️ NOTA: Si el servicio no está configurado para construir desde GitHub,"
                echo "   necesitarás configurarlo en EasyPanel o actualizar manualmente."
            else
                echo "❌ Error al actualizar el servicio"
                exit 1
            fi
            ;;
        3)
            echo ""
            echo "❌ Actualización cancelada"
            exit 0
            ;;
        *)
            echo ""
            echo "❌ Opción inválida"
            exit 1
            ;;
    esac
else
    echo "⚠️ Se detectaron problemas pero no se puede determinar si se necesita actualización"
    echo ""
    echo "📋 Verificaciones manuales recomendadas:"
    echo "   1. Ver logs del servicio: docker service logs $DASHBOARD_SERVICE --tail 50"
    echo "   2. Verificar acceso: curl -I https://dashboard.checkin24hs.com"
    echo "   3. Verificar contenedor: docker logs $CONTAINER_ID --tail 50"
fi

echo ""
echo "=========================================="
echo "✅ Revisión completada"
echo "=========================================="
