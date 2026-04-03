#!/bin/bash
# Script para verificar e instalar EasyPanel si no está corriendo

echo "=========================================="
echo "VERIFICAR E INSTALAR EASYPANEL"
echo "=========================================="
echo ""

# 1. Verificar si hay un contenedor de EasyPanel
echo "1. Verificando contenedores de EasyPanel..."
EASYPANEL_CONTAINER=$(docker ps -a | grep -i easypanel | awk '{print $1}' | head -1)

if [ ! -z "$EASYPANEL_CONTAINER" ]; then
    echo "✅ Contenedor de EasyPanel encontrado: $EASYPANEL_CONTAINER"
    echo "   Estado:"
    docker ps -a | grep -i easypanel
    echo ""
    
    # Verificar si está corriendo
    if docker ps | grep -q "$EASYPANEL_CONTAINER"; then
        echo "✅ EasyPanel está corriendo"
        echo "   Puertos:"
        docker port $EASYPANEL_CONTAINER
    else
        echo "⚠️ EasyPanel está detenido"
        echo "   Iniciando EasyPanel..."
        docker start $EASYPANEL_CONTAINER
        sleep 5
        docker ps | grep -i easypanel
    fi
else
    echo "❌ No se encontró contenedor de EasyPanel"
    echo ""
    echo "2. Verificando si EasyPanel está instalado como servicio systemd..."
    systemctl list-units --type=service --all | grep -i easypanel || echo "No se encontró servicio systemd"
    echo ""
    
    echo "3. Verificando si hay un proceso EasyPanel corriendo..."
    ps aux | grep -i easypanel | grep -v grep || echo "No se encontró proceso EasyPanel"
    echo ""
    
    echo "=========================================="
    echo "EASYPANEL NO ESTÁ INSTALADO O CORRIENDO"
    echo "=========================================="
    echo ""
    echo "Opciones:"
    echo "  1. Instalar EasyPanel (recomendado)"
    echo "  2. Verificar si está en otro servidor"
    echo ""
    read -p "¿Deseas instalar EasyPanel? (s/n): " respuesta
    
    if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
        echo ""
        echo "Instalando EasyPanel..."
        echo ""
        
        # Crear red de Docker si no existe
        docker network create easypanel 2>/dev/null || echo "Red easypanel ya existe"
        
        # Instalar EasyPanel
        docker run -d \
            --name easypanel \
            --restart unless-stopped \
            --network easypanel \
            -p 8080:3000 \
            -v /etc/easypanel:/etc/easypanel \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            easypanel/easypanel:latest
        
        if [ $? -eq 0 ]; then
            echo "✅ EasyPanel instalado"
            echo ""
            echo "Esperando 15 segundos para que EasyPanel inicie..."
            sleep 15
            
            echo ""
            echo "Verificando estado..."
            docker ps | grep easypanel
            echo ""
            echo "✅ EasyPanel debería estar disponible en: http://72.61.58.240:8080"
            echo ""
            echo "Ahora actualiza la configuración de nginx para apuntar al puerto 8080:"
            echo "  sudo nano /etc/nginx/sites-available/easypanel-3006"
            echo "  Cambia: proxy_pass http://127.0.0.1:3000;"
            echo "  Por:    proxy_pass http://127.0.0.1:8080;"
        else
            echo "❌ Error instalando EasyPanel"
        fi
    else
        echo ""
        echo "EasyPanel no se instalará. Verifica si está corriendo en otro servidor o puerto."
    fi
fi

echo ""
echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
