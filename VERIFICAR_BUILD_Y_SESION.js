// EJECUTAR EN LA CONSOLA DEL NAVEGADOR (F12)
// Verificar Build y sesión

console.log('🔍 VERIFICANDO...');
console.log('Build Number:', window.DASHBOARD_BUILD_NUMBER);
console.log('Versión:', window.DASHBOARD_VERSION);

const session = localStorage.getItem('dashboard_auth_session');
if (session) {
    console.log('⚠️  Hay sesión activa:', JSON.parse(session));
    console.log('\nPara limpiar, ejecuta:');
    console.log('localStorage.removeItem("dashboard_auth_session"); location.reload();');
} else {
    console.log('✅ No hay sesión activa');
}

// Verificar si el dashboard está visible sin autenticación
const dashboardContent = document.getElementById('dashboardContent');
const loginContainer = document.getElementById('loginContainer');

if (dashboardContent && !loginContainer?.classList.contains('hidden')) {
    console.log('⚠️  Dashboard visible pero login también visible');
} else if (dashboardContent?.classList.contains('authenticated')) {
    console.log('⚠️  Dashboard marcado como autenticado');
} else {
    console.log('✅ Estado normal');
}
