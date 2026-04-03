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
    console.log(`🚀 CRM corriendo en http://0.0.0.0:${PORT}`);
    console.log(`📁 Sirviendo archivos desde: ${__dirname}`);
});

