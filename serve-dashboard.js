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

// Servir archivos estáticos desde la raíz del proyecto
app.use(express.static(__dirname));

// Servir dashboard.html como página principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// También servir dashboard.html directamente
app.get('/dashboard.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

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

