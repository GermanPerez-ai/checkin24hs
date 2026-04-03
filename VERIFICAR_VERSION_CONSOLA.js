// Script para ejecutar en la consola del navegador para verificar la versión
// Copia y pega este código completo en la consola (F12)

console.log('==========================================');
console.log('🔍 DIAGNÓSTICO DE VERSIÓN DEL DASHBOARD');
console.log('==========================================');
console.log('');

// 1. Verificar versión actual en memoria
console.log('1️⃣ Versión en memoria (window):');
console.log('   DASHBOARD_VERSION:', window.DASHBOARD_VERSION);
console.log('   BUILD_TIMESTAMP:', window.BUILD_TIMESTAMP);
console.log('   DASHBOARD_VERSION_DATE:', window.DASHBOARD_VERSION_DATE);
console.log('');

// 2. Verificar versión esperada
const EXPECTED_BUILD = '2026-01-12T20:37:50Z';
const EXPECTED_VERSION = '2.1.0';
console.log('2️⃣ Versión esperada:');
console.log('   BUILD_TIMESTAMP esperado:', EXPECTED_BUILD);
console.log('   VERSION esperada:', EXPECTED_VERSION);
console.log('');

// 3. Comparar
console.log('3️⃣ Comparación:');
if (window.BUILD_TIMESTAMP === EXPECTED_BUILD) {
    console.log('   ✅ BUILD_TIMESTAMP es CORRECTO');
} else {
    console.log('   ❌ BUILD_TIMESTAMP es INCORRECTO');
    console.log('      Esperado:', EXPECTED_BUILD);
    console.log('      Actual:', window.BUILD_TIMESTAMP);
}

if (window.DASHBOARD_VERSION === EXPECTED_VERSION) {
    console.log('   ✅ VERSION es CORRECTA');
} else {
    console.log('   ❌ VERSION es INCORRECTA');
    console.log('      Esperado:', EXPECTED_VERSION);
    console.log('      Actual:', window.DASHBOARD_VERSION);
}
console.log('');

// 4. Verificar localStorage
console.log('4️⃣ Versión almacenada en localStorage:');
const storedVersion = localStorage.getItem('dashboard_version');
const storedTimestamp = localStorage.getItem('dashboard_build_timestamp');
console.log('   dashboard_version:', storedVersion);
console.log('   dashboard_build_timestamp:', storedTimestamp);

if (storedVersion && storedVersion !== window.DASHBOARD_VERSION) {
    console.log('   ⚠️ Versión almacenada DIFIERE de la actual');
}

if (storedTimestamp && storedTimestamp !== window.BUILD_TIMESTAMP) {
    console.log('   ⚠️ Timestamp almacenado DIFIERE del actual');
}
console.log('');

// 5. Verificar endpoint del servidor
console.log('5️⃣ Verificando versión del servidor (/api/version)...');
fetch('/api/version?t=' + Date.now())
    .then(response => response.json())
    .then(data => {
        console.log('   Respuesta del servidor:', data);
        console.log('');
        
        console.log('6️⃣ Comparación con servidor:');
        if (data.buildTimestamp === EXPECTED_BUILD) {
            console.log('   ✅ BUILD_TIMESTAMP del servidor es CORRECTO');
        } else {
            console.log('   ❌ BUILD_TIMESTAMP del servidor es INCORRECTO');
            console.log('      Esperado:', EXPECTED_BUILD);
            console.log('      Servidor:', data.buildTimestamp);
        }
        
        if (data.version === EXPECTED_VERSION) {
            console.log('   ✅ VERSION del servidor es CORRECTA');
        } else {
            console.log('   ❌ VERSION del servidor es INCORRECTA');
            console.log('      Esperado:', EXPECTED_VERSION);
            console.log('      Servidor:', data.version);
        }
        
        // Comparar con versión en memoria
        if (data.buildTimestamp !== window.BUILD_TIMESTAMP) {
            console.log('');
            console.log('   ⚠️ DIFERENCIA DETECTADA:');
            console.log('      Servidor tiene:', data.buildTimestamp);
            console.log('      Navegador tiene:', window.BUILD_TIMESTAMP);
            console.log('   💡 El navegador está usando una versión ANTIGUA en caché');
        }
        
        console.log('');
        console.log('==========================================');
        console.log('📋 RESUMEN');
        console.log('==========================================');
        console.log('');
        
        if (window.BUILD_TIMESTAMP !== EXPECTED_BUILD || data.buildTimestamp !== EXPECTED_BUILD) {
            console.log('❌ PROBLEMA DETECTADO: Versión incorrecta');
            console.log('');
            console.log('🔧 SOLUCIÓN:');
            console.log('   1. Limpia la caché del navegador:');
            console.log('      localStorage.clear();');
            console.log('      sessionStorage.clear();');
            console.log('   2. Recarga forzando caché:');
            console.log('      location.reload(true);');
            console.log('');
            console.log('   O ejecuta este comando completo:');
            console.log('   localStorage.clear(); sessionStorage.clear(); location.reload(true);');
        } else {
            console.log('✅ Versión correcta detectada');
        }
    })
    .catch(error => {
        console.error('   ❌ Error al verificar servidor:', error);
        console.log('');
        console.log('   ⚠️ No se pudo verificar la versión del servidor');
        console.log('   Esto puede indicar un problema de conectividad o que el endpoint no existe');
    });

// 7. Verificar si hay Service Workers
console.log('');
console.log('7️⃣ Verificando Service Workers...');
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(registrations => {
        if (registrations.length > 0) {
            console.log('   ⚠️ Service Workers encontrados:', registrations.length);
            registrations.forEach((reg, index) => {
                console.log(`   Service Worker ${index + 1}:`, reg.scope);
            });
            console.log('   💡 Los Service Workers pueden estar cacheando la versión antigua');
            console.log('   🔧 Para desregistrarlos, ejecuta:');
            console.log('   navigator.serviceWorker.getRegistrations().then(regs => regs.forEach(r => r.unregister()));');
        } else {
            console.log('   ✅ No hay Service Workers registrados');
        }
    });
} else {
    console.log('   ✅ Service Workers no están disponibles (normal)');
}

// 8. Verificar URL actual
console.log('');
console.log('8️⃣ URL actual:');
console.log('   URL completa:', window.location.href);
console.log('   Parámetros:', window.location.search);
console.log('   ¿Tiene parámetros de versión?', window.location.search.includes('v=') || window.location.search.includes('b='));

console.log('');
console.log('==========================================');
console.log('✅ Diagnóstico completado');
console.log('==========================================');
