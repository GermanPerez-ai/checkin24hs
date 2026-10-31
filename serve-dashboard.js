const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// ===== CONFIGURACIÓN DE PROXY WHATSAPP =====
const WHATSAPP_SERVER_URL = (process.env.WHATSAPP_API_URL || 'https://whatsapp.checkin24hs.com').replace(/\/$/, '');
const WHATSAPP_API_KEY = (process.env.WHATSAPP_API_KEY || '').trim();

if (!WHATSAPP_API_KEY) {
    console.warn('');
    console.warn('⚠️⚠️⚠️ ADVERTENCIA DE SEGURIDAD ⚠️⚠️⚠️');
    console.warn('WHATSAPP_API_KEY no configurada.');
    console.warn('El proxy del dashboard NO podrá comunicarse con el servidor WhatsApp.');
    console.warn('Configura WHATSAPP_API_KEY para habilitar la funcionalidad de WhatsApp.');
    console.warn('');
} else {
    console.log('🔒 Proxy WhatsApp habilitado con API key');
}

// Middleware para parsear JSON (necesario para los endpoints de proxy)
app.use(express.json({ limit: '30mb' }));

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

// ===== PROXY ENDPOINTS PARA WHATSAPP (protege la API key en el servidor) =====
// Los endpoints de proxy reenvían las peticiones al servidor WhatsApp agregando la API key

async function proxyToWhatsApp(req, res, endpoint, method = 'POST') {
    if (!WHATSAPP_API_KEY) {
        return res.status(503).json({
            error: 'Servicio no disponible',
            message: 'El servidor no está configurado para comunicarse con WhatsApp (falta WHATSAPP_API_KEY)'
        });
    }

    try {
        const url = `${WHATSAPP_SERVER_URL}${endpoint}`;
        const headers = {
            'Content-Type': 'application/json',
            'x-api-key': WHATSAPP_API_KEY
        };

        const fetchOptions = {
            method: method,
            headers: headers
        };

        if (method !== 'GET' && req.body) {
            fetchOptions.body = JSON.stringify(req.body);
        }

        const response = await fetch(url, fetchOptions);
        const data = await response.json();

        res.status(response.status).json(data);
    } catch (error) {
        console.error(`Error en proxy WhatsApp (${endpoint}):`, error);
        res.status(500).json({
            error: 'Error de proxy',
            message: error.message
        });
    }
}

app.post('/api/whatsapp-proxy/send', (req, res) => proxyToWhatsApp(req, res, '/api/send', 'POST'));
app.post('/api/whatsapp-proxy/send-audio', (req, res) => proxyToWhatsApp(req, res, '/api/send-audio', 'POST'));
app.post('/api/whatsapp-proxy/send-media', (req, res) => proxyToWhatsApp(req, res, '/api/send-media', 'POST'));
app.get('/api/whatsapp-proxy/status', (req, res) => proxyToWhatsApp(req, res, '/api/status', 'GET'));
app.get('/api/whatsapp-proxy/qr', (req, res) => proxyToWhatsApp(req, res, '/api/qr', 'GET'));

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

