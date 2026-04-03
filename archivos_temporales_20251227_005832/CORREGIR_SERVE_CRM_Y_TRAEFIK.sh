#!/bin/bash

echo "=== Corregir serve-crm.js y configurar Traefik ==="

# 1. Verificar contenido actual de serve-crm.js en el contenedor
echo ""
echo "1. Verificando serve-crm.js en el contenedor:"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo ""
    echo "Primeras 15 líneas de serve-crm.js:"
    docker exec $CONTAINER_ID head -15 /app/serve-crm.js
else
    echo "No se encontró contenedor corriendo"
    exit 1
fi

# 2. Crear serve-crm.js correcto
echo ""
echo "2. Creando serve-crm.js correcto..."
cat > /tmp/serve-crm.js << 'EOF'
const express = require('express');
const path = require('path');
const app = express();

// Forzar puerto 3005 para evitar conflicto con webmail (puerto 80)
// Si EasyPanel pasa PORT=80, lo cambiamos a 3005
const ENV_PORT = process.env.PORT || 3005;
const PORT = ENV_PORT === 80 || ENV_PORT === '80' ? 3005 : ENV_PORT;

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

# 3. Copiar al contenedor
echo ""
echo "3. Copiando serve-crm.js corregido al contenedor..."
docker cp /tmp/serve-crm.js $CONTAINER_ID:/app/serve-crm.js

# 4. Verificar que se copió correctamente
echo ""
echo "4. Verificando que se copió correctamente:"
docker exec $CONTAINER_ID head -10 /app/serve-crm.js

# 5. Reiniciar el servicio para aplicar cambios
echo ""
echo "5. Reiniciando servicio para aplicar cambios..."
docker service update --force checkin24hs_crm

# 6. Esperar a que el servicio se reinicie
echo ""
echo "6. Esperando 20 segundos para que el servicio se reinicie..."
sleep 20

# 7. Verificar que está corriendo correctamente
echo ""
echo "7. Verificando que el servicio está corriendo:"
NEW_CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER_ID"
    docker exec $NEW_CONTAINER_ID ps aux | grep node
    echo ""
    echo "Probando conexión interna:"
    docker exec $NEW_CONTAINER_ID wget -qO- --timeout=5 http://localhost:3005 2>&1 | head -5
fi

# 8. Verificar logs
echo ""
echo "8. Logs del servicio (últimas 10 líneas):"
docker service logs checkin24hs_crm --tail 10

# 9. Configurar Traefik
echo ""
echo "9. Configurando Traefik para el CRM..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  checkin24hs_crm

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas Traefik agregadas"
else
    echo "⚠️  Error al agregar etiquetas Traefik"
fi

# 10. Esperar y verificar Traefik
echo ""
echo "10. Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

echo ""
echo "11. Verificando logs de Traefik:"
docker service logs traefik --tail 50 | grep -i crm | tail -10

# 11. Verificar etiquetas
echo ""
echo "12. Verificando etiquetas Traefik:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "=== Proceso completado ==="
echo ""
echo "Ahora prueba acceder a: http://crm.checkin24hs.com"






