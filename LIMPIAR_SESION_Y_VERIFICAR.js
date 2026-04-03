// EJECUTAR EN LA CONSOLA DEL NAVEGADOR (F12)
// Limpiar sesión y verificar build

console.log('🔍 Verificando...');
console.log('Build:', window.DASHBOARD_BUILD_NUMBER);

const session = localStorage.getItem('dashboard_auth_session');
if (session) {
    const sessionData = JSON.parse(session);
    console.log('⚠️  Sesión encontrada:', sessionData);
    console.log('Eliminando sesión...');
    localStorage.removeItem('dashboard_auth_session');
    console.log('✅ Sesión eliminada');
    console.log('🔄 Recargando página...');
    location.reload();
} else {
    console.log('✅ No hay sesión guardada');
    console.log('Si aún entras sin login, el servidor puede tener código antiguo.');
}
