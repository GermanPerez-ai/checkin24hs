const express = require('express');
const cors = require('cors');
const { getRealPuyehueQuote } = require('./puppeteer-real-cotizacion.js');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.')); // Servir archivos estáticos

// Ruta principal
app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

// Ruta para test-cotizacion
app.get('/test', (req, res) => {
    res.sendFile(__dirname + '/test-cotizacion.html');
});

// API para cotización de Puyehue
app.post('/api/puyehue-quote', async (req, res) => {
    try {
        console.log('📋 Recibida solicitud de cotización:', req.body);
        
        const quoteData = {
            checkIn: req.body.checkIn,
            checkOut: req.body.checkOut,
            adults: parseInt(req.body.adults) || 2,
            children: parseInt(req.body.children) || 0,
            nights: parseInt(req.body.nights) || 1,
            selectedProgram: req.body.selectedProgram || 'EXPERIENCIA'
        };
        
        console.log('🚀 Iniciando cotización con Puppeteer...');
        const result = await getRealPuyehueQuote(quoteData);
        
        console.log('✅ Resultado de la cotización:', result);
        res.json(result);
        
    } catch (error) {
        console.error('❌ Error en la API:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            message: 'Error interno del servidor'
        });
    }
});

// Ruta de salud
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'Servidor funcionando correctamente' });
});

// Manejo de errores
app.use((err, req, res, next) => {
    console.error('❌ Error no manejado:', err);
    res.status(500).json({
        success: false,
        error: 'Error interno del servidor',
        message: err.message
    });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`🚀 Servidor iniciado en http://localhost:${PORT}`);
    console.log(`📊 API disponible en http://localhost:${PORT}/api/puyehue-quote`);
    console.log(`🌐 Frontend disponible en http://localhost:${PORT}`);
});

module.exports = app; 