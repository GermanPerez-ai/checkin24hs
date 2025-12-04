# 🗑️ Eliminar Usuarios de Prueba

## Método 1: Usando el botón del Dashboard (Recomendado)

1. Abre `dashboard.html` en tu navegador
2. Inicia sesión como administrador
3. Ve a la sección **"Usuarios"** en el menú lateral
4. Haz clic en el botón **"Eliminar Todos los Usuarios"** (botón rojo)
5. Confirma la eliminación

## Método 2: Usando la consola del navegador

1. Abre `dashboard.html` en tu navegador
2. Presiona `F12` para abrir la consola del desarrollador
3. Copia y pega el siguiente código:

```javascript
// Eliminar todos los usuarios de prueba
(async function() {
    if (confirm('⚠️ ¿Estás seguro de que quieres eliminar TODOS los usuarios de prueba?')) {
        try {
            const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
            const clientesDB = JSON.parse(localStorage.getItem('clientesDB') || '[]');
            
            console.log(`📊 Eliminando ${users.length} usuarios de checkin24hs_users y ${clientesDB.length} de clientesDB`);
            
            // Intentar eliminar de Supabase
            if (window.supabaseClient && window.supabaseClient.isInitialized()) {
                for (const user of users) {
                    try {
                        await window.supabaseClient.deleteUser(user.id);
                        console.log(`✅ Eliminado de Supabase: ${user.id}`);
                    } catch (e) {
                        console.warn(`⚠️ No encontrado en Supabase: ${user.id}`);
                    }
                }
            }
            
            // Eliminar de localStorage
            localStorage.removeItem('checkin24hs_users');
            localStorage.removeItem('clientesDB');
            localStorage.removeItem('currentUser');
            
            // Recargar tabla
            if (typeof loadUsersData === 'function') {
                loadUsersData();
            }
            if (typeof updateDashboardStats === 'function') {
                updateDashboardStats([]);
            }
            
            alert('✅ Todos los usuarios de prueba eliminados');
            console.log('✅ Proceso completado');
        } catch (error) {
            console.error('❌ Error:', error);
            alert('❌ Error: ' + error.message);
        }
    }
})();
```

4. Presiona `Enter` para ejecutar
5. Confirma la eliminación cuando se te solicite

## Método 3: Usando el script eliminar-usuarios-prueba.js

1. Abre `dashboard.html` en tu navegador
2. Presiona `F12` para abrir la consola
3. Copia el contenido de `eliminar-usuarios-prueba.js`
4. Pégalo en la consola y presiona `Enter`

## ⚠️ Advertencia

Esta acción **NO se puede deshacer**. Todos los usuarios serán eliminados de:
- `checkin24hs_users` (localStorage)
- `clientesDB` (localStorage)
- `system_users` (Supabase, si existen)
- `currentUser` (sesión actual)

## ✅ Verificación

Después de eliminar, verifica que:
- La tabla de usuarios esté vacía
- Las estadísticas muestren 0 usuarios
- No haya usuarios en la consola del navegador


