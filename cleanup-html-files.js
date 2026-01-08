const fs = require('fs');
const path = require('path');

// Función para eliminar archivo
function deleteFile(filePath) {
    try {
        fs.unlinkSync(filePath);
        console.log(`🗑️ Eliminado: ${filePath}`);
    } catch (error) {
        console.error(`❌ Error eliminando ${filePath}:`, error.message);
    }
}

// Función para verificar si un archivo es HTML
function isHtmlFile(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        return content.trim().startsWith('<!DOCTYPE html>');
    } catch (error) {
        return false;
    }
}

console.log('🧹 Iniciando limpieza de archivos HTML...\n');

// Directorios de hoteles
const hotelDirs = [
    'hotel-images/hotel-1-puyehue',
    'hotel-images/hotel-2-huilo-huilo',
    'hotel-images/hotel-3-corralco',
    'hotel-images/hotel-4-futangue',
    'hotel-images/hotel-5-aguas-calientes'
];

let totalDeleted = 0;

hotelDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
        console.log(`📁 Procesando: ${dir}`);
        
        const files = fs.readdirSync(dir);
        files.forEach(file => {
            const filePath = path.join(dir, file);
            const stats = fs.statSync(filePath);
            
            if (stats.isFile() && file.endsWith('.jpg')) {
                if (isHtmlFile(filePath)) {
                    deleteFile(filePath);
                    totalDeleted++;
                }
            }
        });
        
        console.log(`✅ ${dir} procesado\n`);
    }
});

console.log(`🎉 Limpieza completada!`);
console.log(`📊 Total de archivos HTML eliminados: ${totalDeleted}`);
console.log('\n✅ Ahora solo quedan las imágenes reales en formato JPG');
console.log('🔍 Puedes verificar que las imágenes se previsualicen correctamente'); 