const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Prevenir caché para dashboard.html y archivos principales - HEADERS ULTRA AGRESIVOS
app.use((req, res, next) => {
    if (req.path === '/' || req.path === '/dashboard.html' || req.path.endsWith('.html') || req.path.endsWith('.js')) {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=0, private');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
        res.setHeader('Last-Modified', new Date().toUTCString());
        res.setHeader('ETag', `"${Date.now()}"`);
        // Agregar timestamp a la respuesta para forzar recarga
        if (req.path === '/' || req.path === '/dashboard.html') {
            res.setHeader('X-Content-Version', Date.now().toString());
        }
    }
    next();
});

// Rutas específicas ANTES de express.static para tener prioridad

// Endpoint para verificación de versión (cache busting)
app.get('/api/version', (req, res) => {
    const fs = require('fs');
    try {
        const dashboardContent = fs.readFileSync(path.join(__dirname, 'dashboard.html'), 'utf8');
        const buildTimestampMatch = dashboardContent.match(/window\.BUILD_TIMESTAMP = ['"]([^'"]+)['"]/);
        const versionMatch = dashboardContent.match(/window\.DASHBOARD_VERSION = ['"]([^'"]+)['"]/);
        
        res.json({
            version: versionMatch ? versionMatch[1] : '2.1.0',
            buildTimestamp: buildTimestampMatch ? buildTimestampMatch[1] : null,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.json({
            version: '2.1.0',
            buildTimestamp: null,
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Manejar favicon.ico para evitar error 404 (PRIMERO para evitar que express.static lo busque)
app.get('/favicon.ico', (req, res) => {
    res.status(204).end(); // 204 No Content - el navegador no mostrará error
});

// Servir dashboard.html como página principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// Servir dashboard.html cuando se solicite index.html (sin redirección)
app.get('/index.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// También servir dashboard.html directamente
app.get('/dashboard.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// Servir archivos estáticos desde la raíz del proyecto (DESPUÉS de las rutas específicas)
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

