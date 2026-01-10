#!/bin/bash
# Script para verificar si los cambios de Flor IA están en el servidor

echo "🔍 VERIFICANDO CAMBIOS DE FLOR IA EN EL SERVIDOR"
echo "================================================"
echo ""

# 1. Buscar servicio dashboard
echo "1️⃣ Buscando servicio dashboard..."
DASHBOARD_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i dashboard | grep -v proxy | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    echo "❌ No se encontró servicio dashboard"
    docker service ls
    exit 1
fi

echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
echo ""

# 2. Buscar contenedor del dashboard
echo "2️⃣ Buscando contenedor activo..."
CONTAINER_ID=$(docker ps --filter "name=${DASHBOARD_SERVICE}" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    docker service ps $DASHBOARD_SERVICE --no-trunc | head -5
    exit 1
fi

CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format "{{.Names}}")
echo "✅ Contenedor encontrado: $CONTAINER_NAME ($CONTAINER_ID)"
echo ""

# 3. Verificar dashboard.html en el contenedor
echo "3️⃣ Verificando dashboard.html en el contenedor..."

# Buscar si existe dashboard.html
DASHBOARD_FILE=$(docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | head -1)

if [ -z "$DASHBOARD_FILE" ]; then
    echo "⚠️ No se encontró dashboard.html en el contenedor"
    echo "Buscando archivos HTML..."
    docker exec $CONTAINER_ID find / -name "*.html" -type f 2>/dev/null | head -5
    echo ""
    echo "Verificando estructura del contenedor..."
    docker exec $CONTAINER_ID ls -la /app /usr/src/app /var/www/html 2>/dev/null | head -10
    exit 1
fi

echo "✅ dashboard.html encontrado en: $DASHBOARD_FILE"
echo ""

# 4. Verificar cambios en saveWhatsAppConfig
echo "4️⃣ Verificando cambios en saveWhatsAppConfig..."
echo "Buscando función saveWhatsAppConfig..."

SAVEWHATSAPP_CHECK=$(docker exec $CONTAINER_ID grep -A 20 "window.saveWhatsAppConfig = async function" "$DASHBOARD_FILE" 2>/dev/null || \
                    docker exec $CONTAINER_ID grep -A 20 "saveWhatsAppConfig = async function" "$DASHBOARD_FILE" 2>/dev/null)

if [ -z "$SAVEWHATSAPP_CHECK" ]; then
    echo "❌ No se encontró la función saveWhatsAppConfig con 'async function'"
    echo "Buscando versión antigua (sin async)..."
    OLD_VERSION=$(docker exec $CONTAINER_ID grep -A 5 "window.saveWhatsAppConfig = function" "$DASHBOARD_FILE" 2>/dev/null | head -3)
    if [ ! -z "$OLD_VERSION" ]; then
        echo "⚠️ Se encontró versión ANTIGUA (sin async, sin Supabase):"
        echo "$OLD_VERSION"
        echo ""
        echo "❌ LOS CAMBIOS NO ESTÁN APLICADOS"
    else
        echo "❌ No se encontró la función saveWhatsAppConfig"
    fi
else
    echo "✅ Función saveWhatsAppConfig encontrada con 'async function'"
    
    # Verificar si tiene guardado en Supabase
    SUPABASE_CHECK=$(docker exec $CONTAINER_ID grep -A 20 "window.saveWhatsAppConfig = async function" "$DASHBOARD_FILE" 2>/dev/null | grep -i "supabase\|system_config\|whatsapp_server_config")
    
    if [ -z "$SUPABASE_CHECK" ]; then
        echo "⚠️ Función encontrada pero NO tiene código de Supabase"
        echo "❌ LOS CAMBIOS PARCIALMENTE APLICADOS (falta Supabase)"
    else
        echo "✅ Función tiene código para guardar en Supabase"
        echo "   Líneas encontradas:"
        docker exec $CONTAINER_ID grep -A 30 "window.saveWhatsAppConfig = async function" "$DASHBOARD_FILE" 2>/dev/null | grep -E "supabase|system_config|whatsapp_server_config|onConflict" | head -5
        echo ""
        echo "✅ CAMBIOS EN saveWhatsAppConfig ESTÁN APLICADOS"
    fi
fi
echo ""

# 5. Verificar cambios en flor-knowledge-base.js
echo "5️⃣ Verificando cambios en flor-knowledge-base.js..."

FLOR_KB_FILE=$(docker exec $CONTAINER_ID find / -name "flor-knowledge-base.js" -type f 2>/dev/null | head -1)

if [ -z "$FLOR_KB_FILE" ]; then
    echo "⚠️ No se encontró flor-knowledge-base.js en el contenedor"
    echo "   (Puede estar embebido en dashboard.html)"
else
    echo "✅ flor-knowledge-base.js encontrado en: $FLOR_KB_FILE"
    
    # Verificar si tiene onConflict
    ONCONFLICT_CHECK=$(docker exec $CONTAINER_ID grep -i "onConflict" "$FLOR_KB_FILE" 2>/dev/null)
    
    if [ -z "$ONCONFLICT_CHECK" ]; then
        echo "❌ No se encontró 'onConflict' en flor-knowledge-base.js"
        echo "   Verificando función saveHotelKnowledge..."
        docker exec $CONTAINER_ID grep -A 15 "saveHotelKnowledge:" "$FLOR_KB_FILE" 2>/dev/null | head -10
        echo ""
        echo "❌ CAMBIOS EN flor-knowledge-base.js NO ESTÁN APLICADOS"
    else
        echo "✅ Se encontró 'onConflict' en flor-knowledge-base.js"
        echo "   Líneas encontradas:"
        docker exec $CONTAINER_ID grep -B 2 -A 2 "onConflict" "$FLOR_KB_FILE" 2>/dev/null | head -5
        echo ""
        echo "✅ CAMBIOS EN flor-knowledge-base.js ESTÁN APLICADOS"
    fi
fi
echo ""

# 6. Verificar si está embebido en dashboard.html
echo "6️⃣ Verificando si flor-knowledge-base.js está embebido en dashboard.html..."
FLOR_KB_EMBEDDED=$(docker exec $CONTAINER_ID grep -c "FlorKnowledgeBase" "$DASHBOARD_FILE" 2>/dev/null || echo "0")

if [ "$FLOR_KB_EMBEDDED" -gt "0" ]; then
    echo "✅ FlorKnowledgeBase encontrado en dashboard.html ($FLOR_KB_EMBEDDED ocurrencias)"
    
    # Buscar saveHotelKnowledge embebido
    SAVE_HOTEL_KB=$(docker exec $CONTAINER_ID grep -A 20 "saveHotelKnowledge:" "$DASHBOARD_FILE" 2>/dev/null | grep -i "onConflict" | head -1)
    
    if [ -z "$SAVE_HOTEL_KB" ]; then
        echo "⚠️ FlorKnowledgeBase encontrado pero NO tiene 'onConflict' en saveHotelKnowledge"
        echo "   Verificando función completa..."
        docker exec $CONTAINER_ID grep -A 30 "saveHotelKnowledge:" "$DASHBOARD_FILE" 2>/dev/null | grep -A 20 "system_config" | head -10
        echo ""
        echo "❌ CAMBIOS EN saveHotelKnowledge (embebido) PARCIALMENTE APLICADOS"
    else
        echo "✅ saveHotelKnowledge (embebido) tiene 'onConflict'"
        echo ""
        echo "✅ CAMBIOS EN saveHotelKnowledge (embebido) ESTÁN APLICADOS"
    fi
else
    echo "ℹ️ FlorKnowledgeBase no está embebido en dashboard.html"
fi
echo ""

# 7. Verificar fecha de modificación del archivo
echo "7️⃣ Verificando fecha de modificación del archivo..."
MOD_DATE=$(docker exec $CONTAINER_ID stat -c %y "$DASHBOARD_FILE" 2>/dev/null || \
           docker exec $CONTAINER_ID ls -la "$DASHBOARD_FILE" 2>/dev/null | awk '{print $6, $7, $8}')
echo "Fecha de modificación: $MOD_DATE"
echo ""

# 8. Verificar tamaño del archivo (para detectar si es la versión actualizada)
echo "8️⃣ Verificando tamaño del archivo..."
FILE_SIZE=$(docker exec $CONTAINER_ID stat -c %s "$DASHBOARD_FILE" 2>/dev/null || \
            docker exec $CONTAINER_ID wc -c < "$DASHBOARD_FILE" 2>/dev/null)
echo "Tamaño del archivo: $FILE_SIZE bytes ($(echo "scale=2; $FILE_SIZE/1024/1024" | bc) MB)"
echo ""

# 9. Buscar timestamp de verificación en el código
echo "9️⃣ Buscando timestamps de verificación en el código..."
TIMESTAMP_CHECK=$(docker exec $CONTAINER_ID grep -i "VERSIÓN ACTUALIZADA\|CODIGO_ACTUALIZADO_2026" "$DASHBOARD_FILE" 2>/dev/null | head -3)
if [ ! -z "$TIMESTAMP_CHECK" ]; then
    echo "✅ Se encontraron timestamps de verificación:"
    echo "$TIMESTAMP_CHECK"
else
    echo "ℹ️ No se encontraron timestamps de verificación específicos"
fi
echo ""

# 10. Comparar con GitHub (último commit)
echo "🔟 Comparando con último commit de GitHub..."
echo "Último commit debería incluir: 'Corregir desconfiguración de Flor IA'"
echo ""
echo "Verificando hash del commit en el contenedor..."
COMMIT_HASH_LOCAL=$(docker exec $CONTAINER_ID sh -c "cd /app 2>/dev/null && git rev-parse HEAD 2>/dev/null || cd /usr/src/app 2>/dev/null && git rev-parse HEAD 2>/dev/null || echo 'No git repo'")
if [ "$COMMIT_HASH_LOCAL" != "No git repo" ]; then
    echo "Commit hash local: $COMMIT_HASH_LOCAL"
    echo "Último commit esperado: c5e0550 (o posterior)"
else
    echo "ℹ️ No se encontró repositorio git en el contenedor"
fi
echo ""

# 11. Resumen final
echo "================================================"
echo "📋 RESUMEN DE VERIFICACIÓN"
echo "================================================"
echo ""
echo "✅ Servicio: $DASHBOARD_SERVICE"
echo "✅ Contenedor: $CONTAINER_NAME"
echo "✅ Archivo: $DASHBOARD_FILE"
echo "✅ Tamaño: $FILE_SIZE bytes"
echo ""

# Determinar estado general
if [ ! -z "$SUPABASE_CHECK" ] && [ ! -z "$SAVE_HOTEL_KB" ]; then
    echo "✅✅✅ TODOS LOS CAMBIOS ESTÁN APLICADOS ✅✅✅"
    echo ""
    echo "Las correcciones de Flor IA están en el servidor:"
    echo "  ✅ saveWhatsAppConfig guarda en Supabase"
    echo "  ✅ saveHotelKnowledge usa onConflict"
    echo ""
    echo "🎉 El código está actualizado y listo para usar"
elif [ ! -z "$SUPABASE_CHECK" ]; then
    echo "⚠️ CAMBIOS PARCIALMENTE APLICADOS"
    echo ""
    echo "  ✅ saveWhatsAppConfig tiene Supabase"
    echo "  ⚠️ saveHotelKnowledge puede necesitar verificación"
    echo ""
    echo "💡 Considera hacer rebuild del servicio"
elif [ ! -z "$OLD_VERSION" ]; then
    echo "❌ LOS CAMBIOS NO ESTÁN APLICADOS"
    echo ""
    echo "El código en el servidor es la versión ANTIGUA:"
    echo "  ❌ saveWhatsAppConfig NO guarda en Supabase"
    echo "  ❌ Probablemente falta onConflict en saveHotelKnowledge"
    echo ""
    echo "🔧 ACCIÓN REQUERIDA:"
    echo "  1. Hacer rebuild del servicio en EasyPanel"
    echo "  2. O ejecutar: docker service update --force $DASHBOARD_SERVICE"
    echo "  3. O verificar que EasyPanel haya hecho pull del código de GitHub"
else
    echo "⚠️ NO SE PUDO DETERMINAR EL ESTADO"
    echo ""
    echo "Ejecuta manualmente para ver más detalles:"
    echo "  docker exec $CONTAINER_ID grep -A 30 'saveWhatsAppConfig' $DASHBOARD_FILE"
fi
echo ""
