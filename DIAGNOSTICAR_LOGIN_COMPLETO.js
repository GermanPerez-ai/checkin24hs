// EJECUTAR EN LA CONSOLA DEL NAVEGADOR (F12)
// Script de diagnóstico completo para problemas de login

console.log('🔍 DIAGNÓSTICO DE LOGIN');
console.log('========================');

// 1. Verificar Build Number
console.log('\n📦 Build Number:');
console.log('  - window.DASHBOARD_BUILD_NUMBER:', window.DASHBOARD_BUILD_NUMBER);
console.log('  - window.DASHBOARD_VERSION:', window.DASHBOARD_VERSION);

// 2. Verificar localStorage
console.log('\n💾 localStorage:');
const authSession = localStorage.getItem('dashboard_auth_session');
const adminUsers = localStorage.getItem('dashboard_admin_users');
console.log('  - dashboard_auth_session:', authSession ? '✅ Existe' : '❌ No existe');
console.log('  - dashboard_admin_users:', adminUsers ? '✅ Existe' : '❌ No existe');

// 3. Verificar usuarios
if (adminUsers) {
    try {
        const users = JSON.parse(adminUsers);
        console.log('\n👥 Usuarios encontrados:', users.length);
        users.forEach(u => {
            console.log(`  - ${u.username} (${u.role}) - Status: ${u.status}`);
        });
    } catch (e) {
        console.error('❌ Error al parsear usuarios:', e);
    }
} else {
    console.log('\n⚠️  No hay usuarios en localStorage');
}

// 4. Verificar funciones
console.log('\n🔧 Funciones:');
console.log('  - initAdminUsers:', typeof initAdminUsers === 'function' ? '✅' : '❌');
console.log('  - handleLogin:', typeof handleLogin === 'function' ? '✅' : '❌');
console.log('  - getAdminUsers:', typeof getAdminUsers === 'function' ? '✅' : '❌');

// 5. Verificar elementos del DOM
console.log('\n📋 Elementos DOM:');
console.log('  - loginContainer:', document.getElementById('loginContainer') ? '✅' : '❌');
console.log('  - loginUsername:', document.getElementById('loginUsername') ? '✅' : '❌');
console.log('  - loginPassword:', document.getElementById('loginPassword') ? '✅' : '❌');
console.log('  - dashboardContent:', document.getElementById('dashboardContent') ? '✅' : '❌');

// 6. Recomendación
console.log('\n💡 RECOMENDACIONES:');
if (!adminUsers || JSON.parse(adminUsers || '[]').length === 0) {
    console.log('  1. Ejecutar script de inicialización de usuarios');
}
if (window.DASHBOARD_BUILD_NUMBER < 39) {
    console.log('  2. ⚠️  Build #' + window.DASHBOARD_BUILD_NUMBER + ' detectado - Actualizar servidor a Build #39');
}
if (authSession) {
    console.log('  3. Hay sesión activa - Limpiar con: localStorage.removeItem("dashboard_auth_session")');
}

console.log('\n✅ Diagnóstico completo');
