// ============================================
// FORZAR ACTUALIZACIÓN - COPIAR Y PEGAR EN CONSOLA
// ============================================
// 1. Escribe: allow pasting
// 2. Pega este código completo y presiona Enter

console.log('🔄 FORZANDO ACTUALIZACIÓN...');

// Limpiar TODO
localStorage.clear();
sessionStorage.clear();

// Limpiar IndexedDB
if ('indexedDB' in window) {
    indexedDB.databases().then(dbs => dbs.forEach(db => indexedDB.deleteDatabase(db.name)));
}

// Desregistrar Service Workers
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(regs => regs.forEach(r => r.unregister()));
}

// Forzar recarga con parámetros únicos
const newUrl = window.location.pathname + 
    '?v=2.1.0&t=' + Date.now() + 
    '&b=' + encodeURIComponent('2026-01-12T20:54:51Z') + 
    '&force=' + Date.now() + 
    '&nocache=1&_=' + Math.random();

console.log('Redirigiendo a:', newUrl);
window.location.replace(newUrl);
