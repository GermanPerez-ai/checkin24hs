// Script para diagnosticar el problema de login
// Ejecuta esto en la consola del navegador

console.log('🔍 DIAGNÓSTICO DE LOGIN');
console.log('========================');

// 1. Ver usuarios guardados
const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
console.log('📋 Usuarios en localStorage:', users.length);
if (users.length > 0) {
    console.table(users.map(u => ({
        Usuario: u.username,
        Nombre: u.name,
        Estado: u.status,
        'Tiene password': !!u.password,
        'Tiene password_hash': !!u.password_hash
    })));
} else {
    console.warn('⚠️ No hay usuarios guardados en localStorage');
}

// 2. Verificar función getAdminUsers
if (typeof getAdminUsers === 'function') {
    const adminUsers = getAdminUsers();
    console.log('✅ Función getAdminUsers existe. Devuelve:', adminUsers.length, 'usuarios');
} else {
    console.error('❌ Función getAdminUsers NO existe');
}

// 3. Probar búsqueda
console.log('\n🔎 Prueba de búsqueda:');
const testUsername = 'admin';
const testPassword = 'admin123';
const adminUsers = getAdminUsers();
const foundUser = adminUsers.find(u => u.username === testUsername && u.password === testPassword);
console.log(`Buscando: ${testUsername} / ${testPassword}`);
console.log('Resultado:', foundUser ? '✅ ENCONTRADO' : '❌ NO ENCONTRADO');
if (foundUser) {
    console.log('Usuario encontrado:', foundUser);
}

// 4. Mostrar comparación exacta
console.log('\n📊 Comparación exacta de strings:');
if (adminUsers.length > 0) {
    const firstUser = adminUsers[0];
    console.log('Usuario guardado:', JSON.stringify(firstUser.username));
    console.log('Password guardado:', JSON.stringify(firstUser.password));
    console.log('Buscar usuario:', JSON.stringify(testUsername));
    console.log('Buscar password:', JSON.stringify(testPassword));
    console.log('Coincide usuario?', firstUser.username === testUsername);
    console.log('Coincide password?', firstUser.password === testPassword);
}
