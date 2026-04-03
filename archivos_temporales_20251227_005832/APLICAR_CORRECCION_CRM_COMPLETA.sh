#!/bin/bash

echo "=== Aplicar corrección completa del CRM ==="

# 1. Crear serve-crm.js correcto sin emojis
echo ""
echo "1. Creando serve-crm.js correcto..."
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

# 2. Obtener contenedor actual
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
    echo "No se encontró contenedor corriendo. El servicio puede estar reiniciándose."
    echo "Esperando 10 segundos..."
    sleep 10
    CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
fi

if [ ! -z "$CONTAINER_ID" ]; then
    echo ""
    echo "2. Contenedor encontrado: $CONTAINER_ID"
    echo ""
    echo "3. Copiando serve-crm.js corregido..."
    docker cp /tmp/serve-crm.js $CONTAINER_ID:/app/serve-crm.js
    
    echo ""
    echo "4. Verificando que se copió correctamente:"
    docker exec $CONTAINER_ID head -5 /app/serve-crm.js
else
    echo "No se pudo encontrar contenedor. Continuando con configuración de Traefik..."
fi

# 3. Configurar Traefik
echo ""
echo "5. Configurando etiquetas Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  checkin24hs_crm

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas Traefik configuradas"
else
    echo "⚠️  Error al configurar etiquetas Traefik"
fi

# 4. Reiniciar servicio para aplicar cambios
echo ""
echo "6. Reiniciando servicio para aplicar cambios..."
docker service update --force checkin24hs_crm

# 5. Esperar a que se reinicie
echo ""
echo "7. Esperando 25 segundos para que el servicio se reinicie..."
sleep 25

# 6. Verificar estado
echo ""
echo "8. Verificando estado del servicio:"
docker service ps checkin24hs_crm --no-trunc | head -3

# 7. Verificar logs
echo ""
echo "9. Logs del servicio (últimas 10 líneas):"
docker service logs checkin24hs_crm --tail 10

# 8. Verificar contenedor nuevo
NEW_CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$NEW_CONTAINER_ID" ]; then
    echo ""
    echo "10. Nuevo contenedor: $NEW_CONTAINER_ID"
    echo ""
    echo "11. Probando conexión interna:"
    docker exec $NEW_CONTAINER_ID wget -qO- --timeout=5 http://localhost:3005 2>&1 | head -5
fi

# 9. Verificar etiquetas Traefik
echo ""
echo "12. Verificando etiquetas Traefik configuradas:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 10. Esperar y verificar Traefik
echo ""
echo "13. Esperando 10 segundos para que Traefik detecte los cambios..."
sleep 10

echo ""
echo "14. Verificando logs de Traefik:"
docker service logs traefik --tail 30 | grep -iE "crm|checkin24hs_crm" | tail -10

echo ""
echo "=== Proceso completado ==="
echo ""
echo "Ahora prueba acceder a: http://crm.checkin24hs.com"
echo ""
echo "Si aún no funciona, verifica:"
echo "1. Que el DNS de crm.checkin24hs.com apunte a la IP del servidor"
echo "2. Que el servicio esté en la red 'easypanel' (ya está configurado)"
echo "3. Espera unos minutos para que Traefik propague los cambios"






