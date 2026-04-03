#!/bin/bash

# Script para crear serve-crm.js directamente en el servidor y aplicarlo
# Ejecutar directamente en el servidor: bash CREAR_Y_APLICAR_CRM_DIRECTO.sh

set -e

echo "=== Creando serve-crm.js en el servidor ==="

# Crear serve-crm.js
cat > /root/checkin24hs/serve-crm.js << 'EOF'
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3005;

// Prevenir caché para crm.html y archivos principales
app.use((req, res, next) => {
    if (req.path === '/' || req.path === '/crm.html' || req.path.endsWith('.html')) {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
    }
    next();
});

// Servir crm.html como página principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'crm.html'));
});

// Redirigir index.html a crm.html
app.get('/index.html', (req, res) => {
    res.redirect('/crm.html');
});

// Servir archivos estáticos desde la raíz del proyecto
app.use(express.static(__dirname, { index: false }));

// También servir crm.html directamente
app.get('/crm.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'crm.html'));
});

// Manejar rutas de React Router (si es necesario en el futuro)
app.get('*', (req, res) => {
    // Si la ruta no es un archivo estático, servir crm.html
    res.sendFile(path.join(__dirname, 'crm.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`CRM corriendo en http://0.0.0.0:${PORT}`);
    console.log(`Sirviendo archivos desde: ${__dirname}`);
});
EOF

echo "Archivo serve-crm.js creado"

# Verificar que el archivo se creó
ls -lh /root/checkin24hs/serve-crm.js

echo ""
echo "=== Buscando servicio CRM ==="

# Buscar servicio CRM
SERVICE_NAME="checkin24hs_crm"
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "ERROR: Servicio $SERVICE_NAME no encontrado"
    echo "Servicios disponibles:"
    docker service ls
    exit 1
fi

echo "Servicio encontrado: $SERVICE_NAME"

# Verificar estado del servicio
echo "Estado del servicio:"
docker service ps $SERVICE_NAME --no-trunc | head -5

echo ""
echo "=== Obteniendo contenedor ==="

# Obtener contenedor usando docker service ps
TASK_ID=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}" | head -1)

if [ -z "$TASK_ID" ]; then
    echo "No hay tareas corriendo. Intentando obtener cualquier tarea..."
    TASK_ID=$(docker service ps $SERVICE_NAME --format "{{.ID}}" | head -1)
fi

if [ -z "$TASK_ID" ]; then
    echo "ERROR: No se encontró ninguna tarea del servicio"
    exit 1
fi

echo "Task ID: $TASK_ID"

# Obtener nombre completo del contenedor
CONTAINER_NAME=$(docker service ps $SERVICE_NAME --filter "id=$TASK_ID" --format "{{.Name}}" | head -1)
echo "Container name: $CONTAINER_NAME"

# Obtener ID del contenedor
CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "ADVERTENCIA: No se encontró contenedor corriendo con ese nombre"
    echo "Intentando obtener contenedor de otra forma..."
    
    # Intentar obtener cualquier contenedor relacionado
    CONTAINER_ID=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
    
    if [ -z "$CONTAINER_ID" ]; then
        echo "ERROR: No se pudo obtener el ID del contenedor"
        echo "Contenedores disponibles:"
        docker ps -a | head -10
        exit 1
    fi
    
    echo "Contenedor encontrado (puede estar detenido): $CONTAINER_ID"
else
    echo "Contenedor encontrado: $CONTAINER_ID"
fi

# Verificar que el contenedor existe
if ! docker inspect $CONTAINER_ID > /dev/null 2>&1; then
    echo "ERROR: El contenedor $CONTAINER_ID no existe"
    exit 1
fi

echo ""
echo "=== Copiando archivo al contenedor ==="

# Copiar archivo
docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js

# Verificar que se copió
echo "Verificando que se copió:"
docker exec $CONTAINER_ID ls -lh /app/serve-crm.js

echo ""
echo "=== Reiniciando servicio ==="

# Reiniciar servicio
docker service update --force $SERVICE_NAME

echo "Esperando 30 segundos para que el servicio se reinicie..."
sleep 30

echo ""
echo "=== Verificando nuevo contenedor ==="

# Obtener nuevo contenedor
NEW_TASK_ID=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.ID}}" | head -1)
NEW_CONTAINER_NAME=$(docker service ps $SERVICE_NAME --filter "id=$NEW_TASK_ID" --format "{{.Name}}" | head -1)
NEW_CONTAINER_ID=$(docker ps --filter "name=$NEW_CONTAINER_NAME" --format "{{.ID}}" | head -1)

if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    
    # Copiar archivo al nuevo contenedor también
    echo "Copiando serve-crm.js al nuevo contenedor..."
    docker cp /root/checkin24hs/serve-crm.js $NEW_CONTAINER_ID:/app/serve-crm.js
    
    # Verificar proceso
    echo "Verificando proceso:"
    docker exec $NEW_CONTAINER_ID ps aux | grep node || echo "No se encontró proceso node"
    
    # Verificar logs
    echo ""
    echo "Últimos logs del servicio:"
    docker service logs $SERVICE_NAME --tail 20
else
    echo "ADVERTENCIA: No se encontró nuevo contenedor después del reinicio"
    echo "Estado del servicio:"
    docker service ps $SERVICE_NAME
fi

echo ""
echo "=== Proceso completado ==="
echo "Verifica los logs con: docker service logs $SERVICE_NAME --tail 50"

