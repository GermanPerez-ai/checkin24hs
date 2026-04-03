// EJECUTAR EN LA CONSOLA DEL NAVEGADOR (F12)
// Verificar usuarios existentes y corregirlos si es necesario

console.log('🔍 VERIFICANDO USUARIOS...');
const usersStr = localStorage.getItem('dashboard_admin_users');
const users = JSON.parse(usersStr || '[]');

console.log('\n👥 Usuarios encontrados:', users.length);
users.forEach((u, i) => {
    console.log(`\n${i + 1}. Usuario:`);
    console.log('   - username:', u.username);
    console.log('   - password:', u.password ? '✅' : '❌ FALTA');
    console.log('   - password_hash:', u.password_hash ? '✅' : '❌ FALTA');
    console.log('   - role:', u.role);
    console.log('   - status:', u.status);
});

// Verificar si todos tienen password y password_hash
const usersWithIssues = users.filter(u => !u.password || !u.password_hash);
if (usersWithIssues.length > 0) {
    console.log('\n⚠️  Usuarios con problemas:', usersWithIssues.length);
    console.log('Corrigiendo...');
    
    users.forEach(u => {
        if (u.password && !u.password_hash) {
            u.password_hash = u.password;
        }
        if (!u.password && u.password_hash) {
            u.password = u.password_hash;
        }
        if (!u.status) {
            u.status = 'active';
        }
    });
    
    localStorage.setItem('dashboard_admin_users', JSON.stringify(users));
    console.log('✅ Usuarios corregidos');
    location.reload();
} else {
    console.log('\n✅ Todos los usuarios están bien configurados');
}
