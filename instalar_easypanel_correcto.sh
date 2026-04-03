#!/bin/bash
# Script para instalar EasyPanel correctamente

echo "=========================================="
echo "INSTALACIÓN DE EASYPANEL"
echo "=========================================="
echo ""

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo "✅ Docker instalado"
fi

# Verificar si Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose no está instalado. Instalando..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose instalado"
fi

echo ""
echo "Intentando instalar EasyPanel..."
echo ""

# Método 1: Instalación oficial (si la URL cambió)
echo "Método 1: Instalación desde GitHub..."
curl -fsSL https://raw.githubusercontent.com/easypanel-io/easypanel/main/install.sh | bash

# Si falla, intentar método alternativo
if [ $? -ne 0 ]; then
    echo ""
    echo "Método 1 falló, intentando método alternativo..."
    echo ""
    
    # Método 2: Instalación manual con Docker
    echo "Método 2: Instalación manual con Docker..."
    
    # Crear red de Docker si no existe
    docker network create easypanel 2>/dev/null
    
    # Ejecutar EasyPanel con Docker
    docker run -d \
        --name easypanel \
        --restart unless-stopped \
        -p 3000:3000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v easypanel-data:/app/data \
        easypanel/easypanel:latest
    
    if [ $? -eq 0 ]; then
        echo "✅ EasyPanel instalado con Docker"
        echo ""
        echo "Esperando 10 segundos para que EasyPanel inicie..."
        sleep 10
        
        # Verificar que esté corriendo
        docker ps | grep easypanel
        echo ""
        echo "✅ EasyPanel debería estar disponible en: http://72.61.58.240:3000"
    else
        echo "❌ Error instalando EasyPanel con Docker"
        echo ""
        echo "Intenta instalar manualmente desde: https://easypanel.io/docs/installation"
    fi
fi

echo ""
echo "=========================================="
echo "VERIFICACIÓN"
echo "=========================================="
echo ""

# Verificar contenedores Docker
echo "Contenedores Docker corriendo:"
docker ps | grep -E "easypanel|NAME"

echo ""
echo "Puerto 3000:"
sudo lsof -i :3000

echo ""
echo "✅ Proceso completado"


