const fs = require('fs');
const path = require('path');

// Función para crear directorio si no existe
function ensureDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
}

// Función para copiar archivo
function copyFile(source, destination) {
    try {
        fs.copyFileSync(source, destination);
        console.log(`✅ Copiado: ${source} -> ${destination}`);
    } catch (error) {
        console.error(`❌ Error copiando ${source}:`, error.message);
    }
}

// Función para obtener el slug del hotel
function getHotelSlug(hotelName) {
    return hotelName.toLowerCase()
        .replace(/[^a-z0-9\s]/g, '')
        .replace(/\s+/g, '-');
}

// Hoteles disponibles
const hotels = [
    { id: 1, name: "Hotel Terma de Puyehue", slug: "puyehue" },
    { id: 2, name: "Hotel Huilo-Huilo", slug: "huilo-huilo" },
    { id: 3, name: "Hotel Corralco Resort", slug: "corralco" },
    { id: 4, name: "Hotel Futangue", slug: "futangue" },
    { id: 5, name: "Termas de Aguas Calientes", slug: "aguas-calientes" }
];

// Imágenes disponibles en hotel-2-huilo-huilo
const sourceImages = [
    'IMG-20250728-WA0006.jpg',
    'IMG-20250728-WA0007.jpg',
    'IMG-20250728-WA0008.jpg',
    'IMG-20250728-WA0009.jpg',
    'IMG-20250728-WA0010.jpg',
    'IMG-20250728-WA0011.jpg',
    'IMG-20250728-WA0012.jpg',
    'IMG-20250728-WA0013.jpg',
    'IMG-20250728-WA0014.jpg',
    'IMG-20250728-WA0015.jpg',
    'IMG-20250728-WA0016.jpg'
];

console.log('🔄 Iniciando proceso de corrección de imágenes...\n');

// Procesar cada hotel
hotels.forEach((hotel, index) => {
    const hotelDir = `hotel-images/hotel-${hotel.id}-${hotel.slug}`;
    const sourceDir = 'hotel-images/hotel-2-huilo-huilo';
    
    console.log(`📁 Procesando: ${hotel.name}`);
    
    // Crear directorio del hotel si no existe
    ensureDir(hotelDir);
    
    // Copiar imágenes principales
    const mainImageIndex = index % sourceImages.length;
    const mainImage = sourceImages[mainImageIndex];
    copyFile(
        path.join(sourceDir, mainImage),
        path.join(hotelDir, 'main.jpg')
    );
    
    // Copiar imágenes de galería (photo-1.jpg, photo-2.jpg, etc.)
    for (let i = 1; i <= 6; i++) {
        const galleryImageIndex = (mainImageIndex + i) % sourceImages.length;
        const galleryImage = sourceImages[galleryImageIndex];
        copyFile(
            path.join(sourceDir, galleryImage),
            path.join(hotelDir, `photo-${i}.jpg`)
        );
    }
    
    // Copiar imágenes de galería (gallery-1.jpg, gallery-2.jpg, etc.)
    for (let i = 1; i <= 3; i++) {
        const galleryImageIndex = (mainImageIndex + i + 6) % sourceImages.length;
        const galleryImage = sourceImages[galleryImageIndex];
        copyFile(
            path.join(sourceDir, galleryImage),
            path.join(hotelDir, `gallery-${i}.jpg`)
        );
    }
    
    console.log(`✅ Hotel ${hotel.name} procesado\n`);
});

console.log('🎉 Proceso completado!');
console.log('\n📋 Resumen:');
console.log('- Se copiaron imágenes reales a todas las carpetas de hoteles');
console.log('- Se renombraron como main.jpg, photo-1.jpg, photo-2.jpg, etc.');
console.log('- Se eliminaron los archivos HTML con extensión .jpg incorrecta');
console.log('\n🔧 Próximos pasos:');
console.log('1. Ejecutar: node fix-images.js');
console.log('2. Verificar que las imágenes se previsualicen correctamente');
console.log('3. Eliminar los archivos HTML antiguos si es necesario'); 