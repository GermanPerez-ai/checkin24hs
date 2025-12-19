const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { getRealPuyehueQuote } = require('./puppeteer-real-cotizacion.js');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.')); // Servir archivos estáticos

// Ruta principal - Dashboard de administración
app.get('/', (req, res) => {
    res.sendFile(__dirname + '/dashboard.html');
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

// Función auxiliar para obtener slug del hotel
function getHotelSlug(hotelName) {
    // Remover la palabra "Hotel" del inicio si existe
    let cleanName = hotelName.replace(/^hotel\s+/i, '');
    
    return cleanName.toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim();
}

// Función auxiliar para buscar hotel por nombre
function findHotelByName(hotelName) {
    // Mapeo de nombres de hoteles a sus IDs y slugs
    const hotelMap = {
        'hotel terma de puyehue': { id: 1, slug: 'puyehue', name: 'Hotel Terma de Puyehue' },
        'termas de puyehue': { id: 1, slug: 'puyehue', name: 'Hotel Terma de Puyehue' },
        'puyehue': { id: 1, slug: 'puyehue', name: 'Hotel Terma de Puyehue' },
        'hotel huilo-huilo': { id: 2, slug: 'huilo-huilo', name: 'Hotel Huilo-Huilo' },
        'huilo huilo': { id: 2, slug: 'huilo-huilo', name: 'Hotel Huilo-Huilo' },
        'huilo-huilo': { id: 2, slug: 'huilo-huilo', name: 'Hotel Huilo-Huilo' },
        'hotel corralco': { id: 3, slug: 'corralco', name: 'Hotel Corralco Resort' },
        'corralco resort': { id: 3, slug: 'corralco', name: 'Hotel Corralco Resort' },
        'corralco': { id: 3, slug: 'corralco', name: 'Hotel Corralco Resort' },
        'hotel futangue': { id: 4, slug: 'futangue', name: 'Hotel Futangue' },
        'futangue': { id: 4, slug: 'futangue', name: 'Hotel Futangue' },
        'termas de aguas calientes': { id: 5, slug: 'aguas-calientes', name: 'Termas de Aguas Calientes' },
        'aguas calientes': { id: 5, slug: 'aguas-calientes', name: 'Termas de Aguas Calientes' },
        'aguas-calientes': { id: 5, slug: 'aguas-calientes', name: 'Termas de Aguas Calientes' }
    };

    const searchTerm = hotelName.toLowerCase().trim();
    
    // Buscar coincidencia exacta primero
    if (hotelMap[searchTerm]) {
        return hotelMap[searchTerm];
    }
    
    // Buscar coincidencia parcial
    for (const [key, value] of Object.entries(hotelMap)) {
        if (key.includes(searchTerm) || searchTerm.includes(key)) {
            return value;
        }
    }
    
    return null;
}

// Endpoint para obtener imagen de hotel
app.get('/api/hoteles/imagen/:nombre_hotel', (req, res) => {
    try {
        const nombreHotel = decodeURIComponent(req.params.nombre_hotel);
        const imageType = req.query.type || 'main'; // 'main', 'gallery-1', 'gallery-2', etc.
        
        console.log(`📸 Solicitud de imagen para: ${nombreHotel} (tipo: ${imageType})`);
        
        // Buscar el hotel
        const hotel = findHotelByName(nombreHotel);
        
        if (!hotel) {
            return res.status(404).json({
                success: false,
                error: 'Hotel no encontrado',
                message: `No se encontró el hotel "${nombreHotel}"`
            });
        }
        
        // Construir ruta de la imagen
        const imageDir = path.join(__dirname, 'hotel-images', `hotel-${hotel.id}-${hotel.slug}`);
        let imagePath;
        
        if (imageType === 'main') {
            imagePath = path.join(imageDir, 'main.jpg');
        } else if (imageType.startsWith('gallery-')) {
            const galleryNum = imageType.replace('gallery-', '');
            imagePath = path.join(imageDir, `gallery-${galleryNum}.jpg`);
        } else {
            imagePath = path.join(imageDir, `${imageType}.jpg`);
        }
        
        // Verificar si el archivo existe
        if (!fs.existsSync(imagePath)) {
            // Intentar con main.jpg como fallback
            const fallbackPath = path.join(imageDir, 'main.jpg');
            if (fs.existsSync(fallbackPath)) {
                imagePath = fallbackPath;
                console.log(`⚠️ Imagen ${imageType} no encontrada, usando main.jpg como fallback`);
            } else {
                return res.status(404).json({
                    success: false,
                    error: 'Imagen no encontrada',
                    message: `No se encontró la imagen para ${hotel.name}`
                });
            }
        }
        
        // Enviar la imagen
        const imageUrl = `/hotel-images/hotel-${hotel.id}-${hotel.slug}/${path.basename(imagePath)}`;
        
        console.log(`✅ Imagen encontrada: ${imageUrl}`);
        
        res.json({
            success: true,
            hotel: hotel.name,
            imageUrl: imageUrl,
            imagePath: imagePath,
            type: imageType
        });
        
    } catch (error) {
        console.error('❌ Error al obtener imagen de hotel:', error);
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
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor iniciado en http://0.0.0.0:${PORT}`);
    console.log(`📊 API disponible en http://0.0.0.0:${PORT}/api/puyehue-quote`);
    console.log(`🌐 Frontend disponible en http://0.0.0.0:${PORT}`);
});

module.exports = app; 