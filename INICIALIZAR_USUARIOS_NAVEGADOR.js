// EJECUTAR EN LA CONSOLA DEL NAVEGADOR (F12)
// Esto creará/restaurará los usuarios administradores por defecto

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
console.log('✅ Usuarios inicializados:');
console.log('- admin / admin123');
console.log('- German / 123456');
console.log('- Axel / 123456');
console.log('');
console.log('🔄 Recarga la página (F5) y prueba hacer login');

// Recargar la página
location.reload();
