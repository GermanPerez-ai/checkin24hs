// SOLUCIÓN COMPLETA PARA CREAR USUARIOS Y PROBAR LOGIN
// Ejecuta esto completo en la consola del navegador

console.log('🔧 Creando usuarios por defecto...');

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

// Guardar usuarios
localStorage.setItem('dashboard_admin_users', JSON.stringify(defaultUsers));
console.log('✅ Usuarios guardados:', defaultUsers.length);

// Verificar que se guardaron
const savedUsers = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
console.log('✅ Verificación: Se guardaron', savedUsers.length, 'usuarios');

// Probar búsqueda
console.log('\n🧪 Probando búsqueda de usuario...');
const testUser = savedUsers.find(u => u.username === 'admin' && u.password === 'admin123');
if (testUser) {
    console.log('✅ Búsqueda exitosa. Usuario encontrado:', testUser.username);
} else {
    console.error('❌ Error: Usuario no encontrado en la búsqueda');
    console.log('Usuarios guardados:', savedUsers);
}

// Mostrar usuarios disponibles
console.log('\n📋 Usuarios disponibles:');
savedUsers.forEach(u => {
    console.log(`  - ${u.username} / ${u.password} (${u.status})`);
});

alert('✅ Usuarios creados correctamente.\n\nAhora puedes iniciar sesión con:\n- Usuario: admin\n- Contraseña: admin123\n\nRecarga la página.');
location.reload();
