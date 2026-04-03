#!/bin/bash

echo "=========================================="
echo "VERIFICACION DE RUTA DEL DASHBOARD (MEJORADO)"
echo "=========================================="
echo ""

# 1. Verificar ruta local
echo "1. RUTA LOCAL DEL ARCHIVO"
echo ""
if [ -f "dashboard.html" ]; then
    echo "OK Archivo encontrado: $(pwd)/dashboard.html"
    echo "  Tamaño: $(du -h dashboard.html | cut -f1)"
else
    echo "ERROR: No se encontró dashboard.html"
fi
echo ""

# 2. Verificar GitHub
echo "2. CONFIGURACION DE GITHUB"
echo ""
if [ -d ".git" ]; then
    echo "OK Repositorio Git detectado:"
    git remote get-url origin 2>/dev/null | xargs echo "  Remote:"
    git branch --show-current 2>/dev/null | xargs echo "  Rama:"
    git rev-parse HEAD 2>/dev/null | cut -c1-8 | xargs echo "  Commit:"
else
    echo "ADVERTENCIA: No se detectó repositorio Git"
fi
echo ""

# 3. Verificar configuración del servidor
echo "3. CONFIGURACION DEL SERVIDOR"
echo ""
PORT="3000"
if [ -f "serve-dashboard.js" ]; then
    echo "OK Archivo serve-dashboard.js encontrado"
    PORT_FOUND=$(grep -E "PORT.*=.*[0-9]+" serve-dashboard.js 2>/dev/null | grep -oE "[0-9]+" | head -1)
    if [ ! -z "$PORT_FOUND" ]; then
        PORT="$PORT_FOUND"
    fi
    echo "  Puerto por defecto: $PORT"
else
    echo "ADVERTENCIA: serve-dashboard.js no encontrado"
fi
echo ""

# 4. Verificar contenedores Docker
echo "4. CONTENEDORES DOCKER"
echo ""

if command -v docker > /dev/null 2>&1; then
    DASHBOARD_CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -iE "(dashboard|checkin)" | head -5)
    
    if [ ! -z "$DASHBOARD_CONTAINERS" ]; then
        echo "OK Contenedores encontrados:"
        for CONTAINER in $DASHBOARD_CONTAINERS; do
            echo "  - $CONTAINER"
            DASHBOARD_PATHS=$(docker exec "$CONTAINER" find /app /usr/src/app -name "dashboard.html" -type f 2>/dev/null | head -3)
            if [ ! -z "$DASHBOARD_PATHS" ]; then
                echo "    Archivo dashboard.html encontrado:"
                echo "$DASHBOARD_PATHS" | sed 's/^/      /'
            fi
        done
    else
        echo "ADVERTENCIA: No se encontraron contenedores con 'dashboard' o 'checkin'"
    fi
    
    # Verificar servicios de Docker Swarm
    echo ""
    echo "5. SERVICIOS DOCKER SWARM (EASYPANEL)"
    echo ""
    
    if docker service ls > /dev/null 2>&1; then
        DASHBOARD_SERVICES=$(docker service ls --format "{{.Name}}" 2>/dev/null | grep -iE "(dashboard|checkin)" | head -5)
        
        if [ ! -z "$DASHBOARD_SERVICES" ]; then
            echo "OK Servicios encontrados:"
            for SERVICE in $DASHBOARD_SERVICES; do
                echo "  - $SERVICE"
                SERVICE_TASKS=$(docker service ps "$SERVICE" --format "{{.Name}}\t{{.CurrentState}}" 2>/dev/null | grep "Running" | head -1)
                if [ ! -z "$SERVICE_TASKS" ]; then
                    TASK_NAME=$(echo "$SERVICE_TASKS" | awk '{print $1}')
                    echo "    Tarea corriendo: $TASK_NAME"
                    TASK_CONTAINER=$(docker ps --filter "name=$TASK_NAME" --format "{{.Names}}" | head -1)
                    if [ ! -z "$TASK_CONTAINER" ]; then
                        echo "    Contenedor: $TASK_CONTAINER"
                        DASHBOARD_PATH=$(docker exec "$TASK_CONTAINER" find /app /usr/src/app -name "dashboard.html" -type f 2>/dev/null | head -1)
                        if [ ! -z "$DASHBOARD_PATH" ]; then
                            echo "    Ruta del archivo: $DASHBOARD_PATH"
                        fi
                    fi
                fi
            done
        else
            echo "ADVERTENCIA: No se encontraron servicios con 'dashboard' o 'checkin'"
        fi
    else
        echo "ADVERTENCIA: Docker Swarm no está disponible"
    fi
else
    echo "ADVERTENCIA: Docker no está instalado"
fi
echo ""

# 6. Resumen de rutas
echo "6. RESUMEN DE RUTAS"
echo ""
echo "RUTAS IDENTIFICADAS:"
echo ""
echo "  1. Ruta local en servidor:"
if [ -f "dashboard.html" ]; then
    echo "     $(pwd)/dashboard.html"
fi
echo ""
echo "  2. Ruta en GitHub:"
if [ -d ".git" ]; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)
    BRANCH=$(git branch --show-current 2>/dev/null)
    echo "     $REMOTE_URL (rama: $BRANCH)"
else
    echo "     https://github.com/GermanPerez-ai/checkin24hs.git"
fi
echo ""
echo "  3. Ruta en contenedor Docker/EasyPanel:"
if [ ! -z "$DASHBOARD_PATH" ]; then
    echo "     $DASHBOARD_PATH"
else
    echo "     /app/dashboard.html (ruta típica en EasyPanel)"
fi
echo ""
echo "  4. URL pública:"
echo "     https://dashboard.checkin24hs.com"
echo "     http://72.61.58.240:3000"
echo ""
echo "=========================================="
echo "Verificacion completada"
echo "=========================================="
