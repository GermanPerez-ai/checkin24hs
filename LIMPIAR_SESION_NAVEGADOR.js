// EJECUTAR EN LA CONSOLA DEL NAVEGADOR (F12)
// Esto limpiará la sesión guardada que está permitiendo entrar sin login

localStorage.removeItem('dashboard_auth_session');
console.log('✅ Sesión eliminada. Recarga la página (F5)');

// Recargar la página
location.reload();
