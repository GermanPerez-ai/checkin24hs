// PARCHE TEMPORAL - Forzar creación de usuarios
// Ejecuta esto en la consola del navegador ANTES de intentar login

console.log('🔧 Aplicando parche de usuarios...');

// 1. Crear usuarios si no existen
const currentUsers = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
if (!currentUsers || currentUsers.length === 0) {
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
    console.log('✅ Usuarios por defecto creados:', defaultUsers.length);
}

// 2. Sobrescribir getAdminUsers para asegurar que siempre devuelva usuarios
if (typeof getAdminUsers === 'function') {
    const originalGetAdminUsers = getAdminUsers;
    window.getAdminUsers = function() {
        let users = originalGetAdminUsers();
        if (!users || users.length === 0) {
            const defaultUsers = [
                {id:'admin-001',username:'admin',password:'admin123',password_hash:'admin123',name:'Administrador',role:'admin_total',email:'admin@checkin24hs.com',createdAt:new Date().toISOString(),status:'active',lastLogin:null},
                {id:'admin-002',username:'German',password:'123456',password_hash:'123456',name:'German Perez',role:'admin_total',email:'german@checkin24hs.com',createdAt:new Date().toISOString(),status:'active',lastLogin:null},
                {id:'admin-003',username:'Axel',password:'123456',password_hash:'123456',name:'Axel',role:'admin_total',email:'axel@checkin24hs.com',createdAt:new Date().toISOString(),status:'active',lastLogin:null}
            ];
            localStorage.setItem('dashboard_admin_users', JSON.stringify(defaultUsers));
            return defaultUsers;
        }
        return users;
    };
    console.log('✅ Función getAdminUsers parcheada');
}

// 3. Verificar
const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
console.log('📋 Usuarios disponibles:', users.length);
users.forEach(u => console.log(`  - ${u.username} / ${u.password}`));

// 4. Probar búsqueda
const testUser = users.find(u => u.username === 'admin' && u.password === 'admin123');
console.log('🧪 Test búsqueda admin:', testUser ? '✅ OK' : '❌ FALLO');

alert('✅ Parche aplicado. Usuarios listos.\n\nUsa: admin / admin123\n\nAhora intenta iniciar sesión.');
