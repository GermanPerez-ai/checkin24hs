// ============================================
// SCRIPT PARA FORZAR VERSIÓN NUEVA DEL DASHBOARD
// ============================================
// Copia y pega este código COMPLETO en la consola del navegador (F12)
// Primero escribe: allow pasting
// Luego pega este código y presiona Enter

(function() {
    console.log('==========================================');
    console.log('🔄 FORZANDO ACTUALIZACIÓN A VERSIÓN NUEVA');
    console.log('==========================================');
    console.log('');
    
    const EXPECTED_BUILD = '2026-01-12T20:37:50Z';
    const EXPECTED_VERSION = '2.1.0';
    
    // 1. Verificar versión actual
    console.log('1️⃣ Verificando versión actual...');
    const currentBuild = window.BUILD_TIMESTAMP || 'NO DEFINIDO';
    const currentVersion = window.DASHBOARD_VERSION || 'NO DEFINIDO';
    
    console.log('   Versión actual:', currentVersion);
    console.log('   Build actual:', currentBuild);
    console.log('   Versión esperada:', EXPECTED_VERSION);
    console.log('   Build esperado:', EXPECTED_BUILD);
    console.log('');
    
    // 2. Limpiar TODO el almacenamiento
    console.log('2️⃣ Limpiando almacenamiento...');
    try {
        localStorage.clear();
        console.log('   ✅ localStorage limpiado');
    } catch (e) {
        console.error('   ❌ Error limpiando localStorage:', e);
    }
    
    try {
        sessionStorage.clear();
        console.log('   ✅ sessionStorage limpiado');
    } catch (e) {
        console.error('   ❌ Error limpiando sessionStorage:', e);
    }
    
    // Limpiar IndexedDB
    if ('indexedDB' in window) {
        try {
            indexedDB.databases().then(dbs => {
                dbs.forEach(db => {
                    if (db.name) {
                        indexedDB.deleteDatabase(db.name);
                        console.log('   ✅ IndexedDB eliminado:', db.name);
                    }
                });
            });
        } catch (e) {
            console.error('   ❌ Error limpiando IndexedDB:', e);
        }
    }
    
    // Desregistrar Service Workers
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(registrations => {
            registrations.forEach(reg => {
                reg.unregister();
                console.log('   ✅ Service Worker desregistrado:', reg.scope);
            });
        });
    }
    
    console.log('');
    
    // 3. Forzar recarga con parámetros únicos
    console.log('3️⃣ Forzando recarga con parámetros únicos...');
    const uniqueId = Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    const timestamp = Date.now();
    const newUrl = window.location.pathname + 
        '?v=' + EXPECTED_VERSION + 
        '&t=' + timestamp + 
        '&b=' + encodeURIComponent(EXPECTED_BUILD) + 
        '&force=' + uniqueId + 
        '&nocache=1' +
        '&_=' + Math.random();
    
    console.log('   Nueva URL:', newUrl);
    console.log('');
    console.log('🔄 Redirigiendo en 2 segundos...');
    console.log('');
    console.log('==========================================');
    console.log('✅ Después de la recarga, deberías ver:');
    console.log('   - "✅ VERIFICACIÓN TEMPRANA DE VERSIÓN DEL CÓDIGO"');
    console.log('   - Versión: 2.1.0');
    console.log('   - Build: 2026-01-12T20:37:50Z');
    console.log('==========================================');
    
    setTimeout(() => {
        window.location.replace(newUrl);
    }, 2000);
})();
