// EJECUTAR EN LA CONSOLA DEL NAVEGADOR (F12)
// Corregir usuarios: copiar password_hash a password

console.log('🔧 CORRIGIENDO USUARIOS...');
const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');

let fixed = 0;
users.forEach(u => {
    if (u.password_hash && !u.password) {
        u.password = u.password_hash; // Copiar password_hash a password
        fixed++;
        console.log(`✅ ${u.username}: password agregado`);
    }
    if (!u.status) {
        u.status = 'active';
    }
});

if (fixed > 0) {
    localStorage.setItem('dashboard_admin_users', JSON.stringify(users));
    console.log(`\n✅ ${fixed} usuarios corregidos`);
    console.log('🔄 Recargando página...');
    location.reload();
} else {
    console.log('✅ Todos los usuarios ya están correctos');
}
