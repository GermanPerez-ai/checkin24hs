#!/bin/bash
# Script para aplicar los cambios de Flor IA en el servidor
# Opción 1: Rebuild del servicio desde GitHub
# Opción 2: Actualizar archivo directamente en el contenedor

echo "🔧 APLICANDO CAMBIOS DE FLOR IA EN EL SERVIDOR"
echo "=============================================="
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

# 2. Buscar contenedor
echo "2️⃣ Buscando contenedor activo..."
CONTAINER_ID=$(docker ps --filter "name=${DASHBOARD_SERVICE}" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    docker service ps $DASHBOARD_SERVICE --no-trunc | head -5
    exit 1
fi

CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format "{{.Names}}")
DASHBOARD_FILE="/app/dashboard.html"
echo "✅ Contenedor: $CONTAINER_NAME"
echo "✅ Archivo: $DASHBOARD_FILE"
echo ""

# 3. Verificar si tenemos acceso a GitHub
echo "3️⃣ Verificando acceso a GitHub..."
GITHUB_AVAILABLE=$(curl -s --head https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html | head -1 | grep -c "200 OK" || echo "0")

if [ "$GITHUB_AVAILABLE" -eq "1" ]; then
    echo "✅ GitHub accesible"
    echo ""
    echo "🔧 OPCIÓN 1: Actualizar desde GitHub (RECOMENDADO)"
    echo "   Esto descargará el código nuevo y lo aplicará directamente"
    echo ""
    read -p "¿Descargar dashboard.html desde GitHub y actualizar? (s/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo ""
        echo "📥 Descargando dashboard.html desde GitHub..."
        
        # Crear backup del archivo actual
        echo "💾 Creando backup del archivo actual..."
        docker exec $CONTAINER_ID cp "$DASHBOARD_FILE" "${DASHBOARD_FILE}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        
        # Descargar el archivo nuevo
        TEMP_FILE="/tmp/dashboard_$(date +%s).html"
        curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html -o "$TEMP_FILE"
        
        if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
            echo "❌ Error al descargar desde GitHub"
            exit 1
        fi
        
        FILE_SIZE=$(stat -c %s "$TEMP_FILE" 2>/dev/null || wc -c < "$TEMP_FILE")
        echo "✅ Archivo descargado: $FILE_SIZE bytes"
        
        # Verificar que tiene los cambios
        if ! grep -q "saveWhatsAppConfig = async function" "$TEMP_FILE"; then
            echo "⚠️ El archivo descargado NO tiene los cambios de saveWhatsAppConfig"
            echo "   Verificando si GitHub tiene el código actualizado..."
            COMMIT_CHECK=$(curl -s https://api.github.com/repos/GermanPerez-ai/checkin24hs/commits/main | grep -o '"message":"[^"]*' | head -1)
            echo "   Último commit: $COMMIT_CHECK"
            echo ""
            read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Ss]$ ]]; then
                rm -f "$TEMP_FILE"
                exit 1
            fi
        else
            echo "✅ El archivo descargado tiene los cambios de saveWhatsAppConfig"
        fi
        
        # Copiar al contenedor
        echo "📋 Copiando archivo al contenedor..."
        docker cp "$TEMP_FILE" "$CONTAINER_ID:$DASHBOARD_FILE"
        
        if [ $? -eq 0 ]; then
            echo "✅ Archivo copiado correctamente"
            
            # Verificar que se copió
            VERIFY_SIZE=$(docker exec $CONTAINER_ID stat -c %s "$DASHBOARD_FILE" 2>/dev/null || echo "0")
            echo "   Tamaño en contenedor: $VERIFY_SIZE bytes"
            
            if [ "$VERIFY_SIZE" -gt "1000000" ]; then
                echo "✅ Archivo verificado correctamente"
                
                # Verificar cambios
                echo ""
                echo "🔍 Verificando cambios aplicados..."
                if docker exec $CONTAINER_ID grep -q "saveWhatsAppConfig = async function" "$DASHBOARD_FILE"; then
                    echo "✅ saveWhatsAppConfig tiene 'async function'"
                    if docker exec $CONTAINER_ID grep -q "system_config" "$DASHBOARD_FILE" && docker exec $CONTAINER_ID grep -A 20 "saveWhatsAppConfig = async function" "$DASHBOARD_FILE" | grep -q "system_config"; then
                        echo "✅ saveWhatsAppConfig tiene código de Supabase"
                        echo ""
                        echo "✅✅✅ CAMBIOS APLICADOS CORRECTAMENTE ✅✅✅"
                        echo ""
                        echo "⚠️ NOTA: Los cambios se perderán al hacer rebuild del servicio"
                        echo "   Para hacer los cambios permanentes, necesitas:"
                        echo "   1. Hacer rebuild del servicio en EasyPanel desde GitHub"
                        echo "   2. O configurar EasyPanel para usar el código de GitHub automáticamente"
                    else
                        echo "⚠️ saveWhatsAppConfig no tiene código de Supabase completo"
                    fi
                else
                    echo "❌ saveWhatsAppConfig aún no tiene los cambios"
                fi
            else
                echo "❌ Error: El archivo copiado no tiene el tamaño correcto"
            fi
            
            rm -f "$TEMP_FILE"
        else
            echo "❌ Error al copiar archivo al contenedor"
            rm -f "$TEMP_FILE"
            exit 1
        fi
    fi
else
    echo "⚠️ GitHub no accesible desde el servidor"
    echo ""
fi

echo ""
echo "=============================================="
echo "📋 PRÓXIMOS PASOS RECOMENDADOS"
echo "=============================================="
echo ""
echo "Para hacer los cambios PERMANENTES:"
echo ""
echo "1️⃣ OPCIÓN RECOMENDADA: Rebuild desde EasyPanel"
echo "   - Ve a EasyPanel → Servicios → $DASHBOARD_SERVICE"
echo "   - Haz clic en 'Rebuild' o 'Deploy'"
echo "   - Asegúrate que esté configurado para usar:"
echo "     https://github.com/GermanPerez-ai/checkin24hs"
echo "     Branch: main"
echo ""
echo "2️⃣ OPCIÓN ALTERNATIVA: Actualizar desde línea de comandos"
echo "   - Ejecuta este script y selecciona la opción de GitHub"
echo "   - O modifica el Dockerfile para hacer pull del código nuevo"
echo ""
echo "3️⃣ VERIFICAR después de aplicar:"
echo "   bash VERIFICAR_CAMBIOS_FLOR_IA_SERVIDOR.sh"
echo ""
