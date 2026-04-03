#!/bin/bash
# Script para actualizar cotizador-cliente desde GitHub
# Ejecutar en el servidor después de hacer push a GitHub

echo "=========================================="
echo "🔄 Actualizando cotizador desde GitHub"
echo "=========================================="
echo ""

# URLs de GitHub (ajusta el usuario/repo si es diferente)
GITHUB_USER="GermanPerez-ai"
GITHUB_REPO="checkin24hs"
GITHUB_BRANCH="main"
GITHUB_BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# Archivos a actualizar
ARCHIVOS=(
    "cotizador-cliente.html"
    "supabase-config.js"
    "supabase-client.js"
)

# Buscar contenedor o servicio del cotizador
echo "🔍 Buscando contenedor/servicio del cotizador..."

# Buscar primero por servicio (Docker Swarm)
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -i "cotizador\|cotizar" | head -1)

# Si no hay servicio, buscar contenedor
if [ -z "$SERVICE_NAME" ]; then
    CONTAINER_ID=$(docker ps --filter "name=cotizador" --format "{{.ID}}" | head -1)
else
    # Si hay servicio, obtener el contenedor del servicio
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        CONTAINER_ID=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
    fi
fi

if [ -z "$CONTAINER_ID" ] && [ -z "$SERVICE_NAME" ]; then
    echo "⚠️ No se encontró contenedor ni servicio del cotizador"
    echo ""
    echo "Contenedores disponibles:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}" | head -10
    echo ""
    echo "Servicios disponibles:"
    docker service ls --format "{{.Name}}" | head -10
    echo ""
    read -p "Ingresa el ID del contenedor o nombre del servicio: " INPUT
    
    if [[ "$INPUT" =~ ^[a-f0-9]+$ ]]; then
        CONTAINER_ID="$INPUT"
    else
        SERVICE_NAME="$INPUT"
    fi
fi

# Determinar ruta donde están los archivos
if [ ! -z "$CONTAINER_ID" ]; then
    echo "✅ Contenedor encontrado: $CONTAINER_ID"
    
    # Intentar encontrar la ruta automáticamente
    echo "🔍 Buscando ruta de archivos en el contenedor..."
    POSSIBLE_PATHS=(
        "/usr/share/nginx/html/"
        "/app/"
        "/var/www/html/"
        "/html/"
    )
    
    CONTAINER_PATH=""
    for path in "${POSSIBLE_PATHS[@]}"; do
        if docker exec "$CONTAINER_ID" test -d "$path" 2>/dev/null; then
            CONTAINER_PATH="$path"
            echo "✅ Ruta encontrada: $CONTAINER_PATH"
            break
        fi
    done
    
    if [ -z "$CONTAINER_PATH" ]; then
        echo "⚠️ No se pudo determinar la ruta automáticamente"
        read -p "Ingresa la ruta en el contenedor (ej: /usr/share/nginx/html/): " CONTAINER_PATH
    fi
    
    # Asegurar que termine con /
    if [[ ! "$CONTAINER_PATH" == */ ]]; then
        CONTAINER_PATH="$CONTAINER_PATH/"
    fi
    
    # Crear directorio temporal
    TEMP_DIR="/tmp/cotizador_update_$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    echo ""
    echo "📥 Descargando archivos desde GitHub..."
    echo ""
    
    for archivo in "${ARCHIVOS[@]}"; do
        echo "   Descargando $archivo..."
        curl -L -s -o "$archivo" "${GITHUB_BASE_URL}/${archivo}"
        
        if [ $? -eq 0 ] && [ -f "$archivo" ]; then
            # Verificar que el archivo no esté vacío
            if [ -s "$archivo" ]; then
                echo "   ✅ $archivo descargado correctamente"
                
                # Copiar al contenedor
                echo "   📤 Copiando al contenedor..."
                docker cp "$archivo" "$CONTAINER_ID:${CONTAINER_PATH}${archivo}"
                
                if [ $? -eq 0 ]; then
                    echo "   ✅ $archivo copiado al contenedor"
                    
                    # Si es cotizador-cliente.html, también copiarlo como index.html
                    if [ "$archivo" == "cotizador-cliente.html" ]; then
                        echo "   📤 Copiando también como index.html..."
                        docker cp "$archivo" "$CONTAINER_ID:${CONTAINER_PATH}index.html"
                        if [ $? -eq 0 ]; then
                            echo "   ✅ index.html actualizado"
                        fi
                    fi
                else
                    echo "   ❌ Error al copiar $archivo al contenedor"
                fi
            else
                echo "   ⚠️ $archivo está vacío, puede haber un error"
            fi
        else
            echo "   ❌ Error al descargar $archivo"
        fi
        echo ""
    done
    
    # Limpiar directorio temporal
    cd /
    rm -rf "$TEMP_DIR"
    
    echo "✅ Archivos actualizados en el contenedor"
    echo ""
    echo "🔄 Si los cambios no se reflejan, reinicia el contenedor:"
    echo "   docker restart $CONTAINER_ID"
    
elif [ ! -z "$SERVICE_NAME" ]; then
    echo "✅ Servicio encontrado: $SERVICE_NAME"
    echo ""
    
    # Intentar obtener el contenedor del servicio
    if [ -z "$CONTAINER_ID" ]; then
        echo "   Buscando contenedor del servicio..."
        CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.ID}}" | head -1)
    fi
    
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "   ✅ Contenedor encontrado: $CONTAINER_ID"
        echo ""
        echo "   Usando método de actualización directa al contenedor..."
        echo ""
        
        # Usar el mismo método que para contenedores normales
        CONTAINER_PATH="/usr/share/nginx/html/"
        
        # Crear directorio temporal
        TEMP_DIR="/tmp/cotizador_update_$$"
        mkdir -p "$TEMP_DIR"
        cd "$TEMP_DIR"
        
        echo "📥 Descargando archivos desde GitHub..."
        echo ""
        
        for archivo in "${ARCHIVOS[@]}"; do
            echo "   Descargando $archivo..."
            curl -L -s -o "$archivo" "${GITHUB_BASE_URL}/${archivo}"
            
            if [ $? -eq 0 ] && [ -f "$archivo" ]; then
                if [ -s "$archivo" ]; then
                    echo "   ✅ $archivo descargado correctamente"
                    
                    # Copiar al contenedor
                    echo "   📤 Copiando al contenedor..."
                    docker cp "$archivo" "$CONTAINER_ID:${CONTAINER_PATH}${archivo}"
                    
                    if [ $? -eq 0 ]; then
                        echo "   ✅ $archivo copiado al contenedor"
                        
                        # Si es cotizador-cliente.html, también copiarlo como index.html
                        if [ "$archivo" == "cotizador-cliente.html" ]; then
                            echo "   📤 Copiando también como index.html..."
                            docker cp "$archivo" "$CONTAINER_ID:${CONTAINER_PATH}index.html"
                            if [ $? -eq 0 ]; then
                                echo "   ✅ index.html actualizado"
                            fi
                        fi
                    else
                        echo "   ❌ Error al copiar $archivo al contenedor"
                    fi
                else
                    echo "   ⚠️ $archivo está vacío"
                fi
            else
                echo "   ❌ Error al descargar $archivo"
            fi
            echo ""
        done
        
        # Limpiar directorio temporal
        cd /
        rm -rf "$TEMP_DIR"
        
        echo "✅ Archivos actualizados en el contenedor"
        echo ""
        echo "🔄 Reiniciando servicio para aplicar cambios..."
        docker service update --force "$SERVICE_NAME"
        
        if [ $? -eq 0 ]; then
            echo "✅ Servicio reiniciado"
        else
            echo "⚠️ Error al reiniciar el servicio"
        fi
    else
        echo "   ⚠️ No se pudo encontrar contenedor del servicio"
        echo ""
        echo "📋 Para servicios Docker Swarm sin contenedor accesible, necesitas encontrar el volumen montado"
        echo ""
        echo "Configuración del servicio:"
        docker service inspect "$SERVICE_NAME" --pretty | grep -A 10 "Mounts" || echo "   (sin montajes visibles)"
        echo ""
        read -p "Ingresa la ruta del volumen en el servidor (ej: /root/checkin24hs/) o presiona Enter para cancelar: " VOLUME_PATH
        
        if [ ! -z "$VOLUME_PATH" ]; then
            # Asegurar que termine con /
            if [[ ! "$VOLUME_PATH" == */ ]]; then
                VOLUME_PATH="$VOLUME_PATH/"
            fi
            
            echo ""
            echo "📥 Descargando archivos desde GitHub a $VOLUME_PATH..."
            echo ""
            
            for archivo in "${ARCHIVOS[@]}"; do
                echo "   Descargando $archivo..."
                curl -L -s -o "${VOLUME_PATH}${archivo}" "${GITHUB_BASE_URL}/${archivo}"
                
                if [ $? -eq 0 ] && [ -f "${VOLUME_PATH}${archivo}" ]; then
                    if [ -s "${VOLUME_PATH}${archivo}" ]; then
                        echo "   ✅ $archivo descargado y guardado en $VOLUME_PATH"
                    else
                        echo "   ⚠️ $archivo está vacío"
                    fi
                else
                    echo "   ❌ Error al descargar $archivo"
                fi
                echo ""
            done
            
            echo "✅ Archivos actualizados en el volumen"
            echo ""
            echo "🔄 Reiniciando servicio para aplicar cambios..."
            docker service update --force "$SERVICE_NAME"
            
            if [ $? -eq 0 ]; then
                echo "✅ Servicio reiniciado"
            else
                echo "⚠️ Error al reiniciar el servicio"
            fi
        fi
    fi
else
    echo "❌ No se pudo determinar cómo actualizar"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "🌐 Prueba acceder a: https://cotizar.checkin24hs.com/"
echo "   Y verifica en la consola del navegador (F12) que aparezcan los nuevos logs"
