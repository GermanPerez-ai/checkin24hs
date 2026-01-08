// SOLUCIÓN SIMPLE: Abrir modal de imágenes
// Copia y pega esto en la consola del navegador (F12) para probar

function abrirModalImagenes() {
    console.log('🧪 TEST: Abriendo modal...');
    
    const modal = document.getElementById('imageManagerModal');
    console.log('Modal encontrado?', !!modal);
    
    if (!modal) {
        console.error('❌ Modal no existe');
        alert('Modal no encontrado');
        return;
    }
    
    console.log('✅ Abriendo modal...');
    modal.style.display = 'block';
    modal.style.zIndex = '10000';
    
    console.log('✅ Display:', modal.style.display);
    console.log('✅ Modal debería estar visible ahora');
    
    return modal;
}

// Ejecutar
abrirModalImagenes();

