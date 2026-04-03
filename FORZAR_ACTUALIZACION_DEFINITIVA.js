// Script para forzar actualización definitiva del dashboard
// Copiar y pegar TODO este código en la consola del navegador (F12 → Console)

(function() {
    console.log('🔄 Iniciando limpieza agresiva de caché...');
    
    // 1. Limpiar localStorage
    try {
        localStorage.clear();
        console.log('✅ localStorage limpiado');
    } catch(e) {
        console.error('❌ Error limpiando localStorage:', e);
    }
    
    // 2. Limpiar sessionStorage
    try {
        sessionStorage.clear();
        console.log('✅ sessionStorage limpiado');
    } catch(e) {
        console.error('❌ Error limpiando sessionStorage:', e);
    }
    
    // 3. Limpiar IndexedDB
    if ('indexedDB' in window) {
        indexedDB.databases().then(dbs => {
            dbs.forEach(db => {
                if (db.name) {
                    indexedDB.deleteDatabase(db.name).then(() => {
                        console.log('✅ IndexedDB limpiado:', db.name);
                    }).catch(e => {
                        console.error('❌ Error limpiando IndexedDB:', db.name, e);
                    });
                }
            });
        }).catch(e => {
            console.error('❌ Error accediendo a IndexedDB:', e);
        });
    }
    
    // 4. Desregistrar Service Workers
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(regs => {
            regs.forEach(r => {
                r.unregister().then(() => {
                    console.log('✅ Service Worker desregistrado:', r.scope);
                }).catch(e => {
                    console.error('❌ Error desregistrando Service Worker:', e);
                });
            });
        }).catch(e => {
            console.error('❌ Error accediendo a Service Workers:', e);
        });
    }
    
    // 5. Limpiar caché de la API
    if ('caches' in window) {
        caches.keys().then(names => {
            names.forEach(name => {
                caches.delete(name).then(() => {
                    console.log('✅ Cache eliminado:', name);
                });
            });
        });
    }
    
    // 6. Esperar un momento y luego recargar
    setTimeout(() => {
        console.log('🔄 Recargando página con parámetros únicos...');
        
        // Construir URL con parámetros únicos
        const baseUrl = window.location.pathname;
        const uniqueId = Date.now() + '-' + Math.random().toString(36).substr(2, 9);
        const newUrl = baseUrl + '?v=2.1.0&t=' + Date.now() + '&b=' + encodeURIComponent('2026-01-13T00:13:43Z') + '&force=' + uniqueId + '&nocache=1&_=' + Math.random();
        
        console.log('📍 Nueva URL:', newUrl);
        
        // Usar replace para no agregar a historial
        window.location.replace(newUrl);
    }, 500);
})();
