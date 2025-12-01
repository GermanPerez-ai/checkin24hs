// Script para eliminar todos los usuarios de prueba
// Ejecutar en la consola del navegador (F12) cuando estés en dashboard.html

(async function eliminarUsuariosPrueba() {
    console.log('🗑️ Iniciando eliminación de usuarios de prueba...');
    
    try {
        // Obtener usuarios actuales
        const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        const clientesDB = JSON.parse(localStorage.getItem('clientesDB') || '[]');
        
        console.log(`📊 Usuarios encontrados: ${users.length} en checkin24hs_users, ${clientesDB.length} en clientesDB`);
        
        // Intentar eliminar de Supabase si está inicializado
        if (window.supabaseClient && window.supabaseClient.isInitialized()) {
            console.log('☁️ Intentando eliminar de Supabase...');
            for (const user of users) {
                try {
                    await window.supabaseClient.deleteUser(user.id);
                    console.log(`✅ Usuario eliminado de Supabase: ${user.id} (${user.email || user.name})`);
                } catch (error) {
                    console.warn(`⚠️ Error al eliminar usuario de Supabase (continuando): ${user.id}`, error);
                }
            }
        }
        
        // Eliminar todos los usuarios de localStorage
        localStorage.removeItem('checkin24hs_users');
        localStorage.removeItem('clientesDB');
        localStorage.removeItem('currentUser');
        
        console.log('✅ Todos los usuarios de prueba eliminados de localStorage');
        
        // Recargar la página si estamos en el dashboard
        if (typeof loadUsersData === 'function') {
            loadUsersData();
            console.log('🔄 Tabla de usuarios recargada');
        }
        
        if (typeof updateDashboardStats === 'function') {
            updateDashboardStats([]);
            console.log('📊 Estadísticas actualizadas');
        }
        
        alert('✅ Todos los usuarios de prueba han sido eliminados correctamente');
        console.log('✅ Proceso completado');
        
    } catch (error) {
        console.error('❌ Error al eliminar usuarios de prueba:', error);
        alert('❌ Error al eliminar usuarios de prueba: ' + error.message);
    }
})();


