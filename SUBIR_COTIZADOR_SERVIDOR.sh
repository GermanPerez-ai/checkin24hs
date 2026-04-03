#!/bin/bash
# Script para subir archivos del cotizador-cliente al servidor
# Uso: ./SUBIR_COTIZADOR_SERVIDOR.sh

echo "=========================================="
echo "📤 Subiendo archivos del cotizador al servidor"
echo "=========================================="
echo ""

# Verificar que los archivos existan localmente
ARCHIVOS_LOCALES=(
    "cotizador-cliente.html"
    "supabase-config.js"
    "supabase-client.js"
)

echo "🔍 Verificando archivos locales..."
for archivo in "${ARCHIVOS_LOCALES[@]}"; do
    if [ ! -f "$archivo" ]; then
        echo "❌ Error: No se encuentra el archivo: $archivo"
        exit 1
    else
        echo "✅ Encontrado: $archivo"
    fi
done

echo ""
echo "🔍 Buscando contenedor del cotizador..."

# Buscar contenedor del cotizador
CONTAINER_ID=$(docker ps --filter "name=cotizador" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    # Intentar buscar por servicio
    echo "⚠️ No se encontró contenedor 'cotizador', buscando servicio..."
    SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -i "cotizador\|cotizar" | head -1)
    
    if [ -z "$SERVICE_NAME" ]; then
        echo "❌ No se encontró servicio del cotizador"
        echo ""
        echo "Servicios disponibles:"
        docker service ls --format "{{.Name}}"
        echo ""
        read -p "Ingresa el nombre del servicio del cotizador: " SERVICE_NAME
    fi
    
    if [ ! -z "$SERVICE_NAME" ]; then
        echo "✅ Servicio encontrado: $SERVICE_NAME"
        echo ""
        echo "📋 Para actualizar un servicio Docker Swarm, necesitas:"
        echo "   1. Copiar los archivos al volumen montado del servicio"
        echo "   2. O actualizar la imagen del servicio"
        echo ""
        echo "¿Quieres copiar los archivos directamente al volumen? (s/n)"
        read -p "> " respuesta
        
        if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
            # Buscar el volumen o ruta montada
            echo ""
            echo "🔍 Buscando configuración del servicio..."
            docker service inspect "$SERVICE_NAME" --pretty | grep -A 5 "Mounts"
            echo ""
            read -p "Ingresa la ruta donde están los archivos en el servidor (ej: /root/checkin24hs/): " SERVER_PATH
            
            if [ ! -z "$SERVER_PATH" ]; then
                echo ""
                echo "📤 Para subir los archivos, ejecuta estos comandos en el servidor:"
                echo ""
                echo "   # Opción 1: Usando scp desde tu máquina local"
                echo "   scp cotizador-cliente.html root@TU_SERVIDOR:$SERVER_PATH/"
                echo "   scp supabase-config.js root@TU_SERVIDOR:$SERVER_PATH/"
                echo "   scp supabase-client.js root@TU_SERVIDOR:$SERVER_PATH/"
                echo ""
                echo "   # Opción 2: Copiar manualmente al contenedor"
                echo "   docker cp cotizador-cliente.html \$(docker ps --filter name=cotizador -q):/ruta/en/contenedor/"
                echo ""
                echo "   # Opción 3: Reiniciar el servicio después de copiar"
                echo "   docker service update --force $SERVICE_NAME"
            fi
        fi
    fi
else
    echo "✅ Contenedor encontrado: $CONTAINER_ID"
    echo ""
    
    # Preguntar dónde están los archivos en el contenedor
    echo "¿Dónde están los archivos del cotizador en el contenedor?"
    echo "Ejemplos: /usr/share/nginx/html/ o /app/ o /var/www/html/"
    read -p "Ruta en el contenedor: " CONTAINER_PATH
    
    if [ -z "$CONTAINER_PATH" ]; then
        CONTAINER_PATH="/usr/share/nginx/html/"
        echo "⚠️ Usando ruta por defecto: $CONTAINER_PATH"
    fi
    
    echo ""
    echo "📤 Copiando archivos al contenedor..."
    
    for archivo in "${ARCHIVOS_LOCALES[@]}"; do
        echo "   Copiando $archivo..."
        docker cp "$archivo" "$CONTAINER_ID:$CONTAINER_PATH$archivo"
        
        if [ $? -eq 0 ]; then
            echo "   ✅ $archivo copiado correctamente"
        else
            echo "   ❌ Error al copiar $archivo"
        fi
    done
    
    echo ""
    echo "✅ Archivos copiados. El contenedor debería servir los archivos actualizados."
    echo "   Si no se actualizan, puede ser necesario reiniciar el contenedor:"
    echo "   docker restart $CONTAINER_ID"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
