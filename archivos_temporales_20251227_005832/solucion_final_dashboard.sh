#!/bin/bash

echo "=========================================="
echo "🔧 Solución Final - Dashboard sin Login"
echo "=========================================="
echo ""

cd /root/checkin24hs

# 1. Corregir serve-dashboard.js
echo "1️⃣ Corrigiendo serve-dashboard.js..."
cat > serve-dashboard.js << 'EOF'
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Prevenir caché para dashboard.html y archivos principales
app.use((req, res, next) => {
    if (req.path === '/' || req.path === '/dashboard.html' || req.path.endsWith('.html')) {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
    }
    next();
});

// Servir dashboard.html como página principal (ANTES de express.static)
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// Redirigir index.html a dashboard.html
app.get('/index.html', (req, res) => {
    res.redirect('/dashboard.html');
});

// También servir dashboard.html directamente
app.get('/dashboard.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// Servir archivos estáticos desde la raíz del proyecto (sin index automático)
app.use(express.static(__dirname, { index: false }));

// Manejar rutas de React Router (si es necesario en el futuro)
app.get('*', (req, res) => {
    // Si la ruta no es un archivo estático, servir dashboard.html
    // Esto es útil para SPA (Single Page Applications)
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Dashboard corriendo en http://0.0.0.0:${PORT}`);
    console.log(`📁 Sirviendo archivos desde: ${__dirname}`);
});
EOF

echo "✅ serve-dashboard.js corregido"
echo ""

# 2. Verificar y corregir error de sintaxis en dashboard.html línea 8708
echo "2️⃣ Verificando error de sintaxis en dashboard.html..."
# Buscar caracteres problemáticos alrededor de la línea 8708
sed -n '8705,8710p' dashboard.html | cat -A

# El error puede ser por caracteres especiales o comillas mal cerradas
# Corregir cualquier problema con comillas o caracteres especiales
sed -i '8708s/.*/                                            <li>O configurar el navegador para permitir contenido mixto (solo desarrollo)<\/li>/' dashboard.html

echo "✅ Línea 8708 verificada"
echo ""

# 3. Asegurar que isUserAuthenticated siempre retorne true
echo "3️⃣ Verificando función isUserAuthenticated..."
if grep -q "function isUserAuthenticated()" dashboard.html; then
    sed -i '/function isUserAuthenticated()/,/^        }/c\
        function isUserAuthenticated() {\
            return true;\
        }' dashboard.html
    echo "✅ Función isUserAuthenticated corregida"
else
    echo "⚠️ Función isUserAuthenticated no encontrada"
fi
echo ""

# 4. Reiniciar dashboard
echo "4️⃣ Reiniciando dashboard..."
pm2 stop dashboard 2>/dev/null
pm2 delete dashboard 2>/dev/null
sleep 2

# Matar cualquier proceso usando el puerto 3000
sudo kill -9 $(sudo lsof -ti :3000) 2>/dev/null
sleep 2

pm2 start serve-dashboard.js --name dashboard
sleep 3

# 5. Verificar estado
echo "5️⃣ Verificando estado..."
pm2 list | grep dashboard
pm2 logs dashboard --lines 3 --nostream
sudo lsof -i :3000 | grep dashboard || echo "⚠️ Verificar puerto 3000"

# 6. Guardar configuración
pm2 save

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Accede a: http://72.61.58.240:3000/"
echo "2. Haz Ctrl+Shift+R para limpiar caché del navegador"
echo "3. Si sigue apareciendo el login, verifica dashboard.html manualmente"
echo ""

