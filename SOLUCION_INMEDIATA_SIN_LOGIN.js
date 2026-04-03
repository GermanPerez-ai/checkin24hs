// SOLUCIÓN INMEDIATA: Bypass completo del login
// Ejecuta esto en la consola del navegador (F12 → Console)

// 1. Crear sesión válida automáticamente
const session = {
    username: 'admin',
    name: 'Administrador',
    role: 'admin_total',
    userId: 'admin-001',
    loginTime: Date.now(),
    expiresAt: Date.now() + (30 * 24 * 60 * 60 * 1000) // 30 días
};
localStorage.setItem('dashboard_auth_session', JSON.stringify(session));

// 2. Crear usuarios por defecto
const defaultUsers = [
    {
        id: 'admin-001',
        username: 'admin',
        password: 'admin123',
        password_hash: 'admin123',
        name: 'Administrador',
        role: 'admin_total',
        email: 'admin@checkin24hs.com',
        createdAt: new Date().toISOString(),
        status: 'active',
        lastLogin: null
    },
    {
        id: 'admin-002',
        username: 'German',
        password: '123456',
        password_hash: '123456',
        name: 'German Perez',
        role: 'admin_total',
        email: 'german@checkin24hs.com',
        createdAt: new Date().toISOString(),
        status: 'active',
        lastLogin: null
    },
    {
        id: 'admin-003',
        username: 'Axel',
        password: '123456',
        password_hash: '123456',
        name: 'Axel',
        role: 'admin_total',
        email: 'axel@checkin24hs.com',
        createdAt: new Date().toISOString(),
        status: 'active',
        lastLogin: null
    }
];
localStorage.setItem('dashboard_admin_users', JSON.stringify(defaultUsers));

// 3. Forzar mostrar dashboard
if (typeof showDashboard === 'function') {
    showDashboard();
} else {
    // Si showDashboard no está disponible, hacerlo manualmente
    const loginContainer = document.getElementById('loginContainer');
    const dashboardContent = document.getElementById('dashboardContent');
    const body = document.body;
    
    if (loginContainer) loginContainer.classList.add('hidden');
    if (dashboardContent) dashboardContent.classList.add('authenticated');
    if (body) body.classList.add('authenticated');
}

console.log('✅ Sesión y usuarios creados. Dashboard mostrado.');
alert('✅ Acceso permitido. Recarga la página si no ves el dashboard.');
