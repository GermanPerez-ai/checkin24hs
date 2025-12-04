[1mdiff --git a/dashboard.html b/dashboard.html[m
[1mindex 367294993..5e5c6f6c4 100644[m
[1m--- a/dashboard.html[m
[1m+++ b/dashboard.html[m
[36m@@ -11299,10 +11299,36 @@[m [m${users.slice(0, 10).map(user => `- ${user.name} (${user.email}) - ${new Date(us[m
             }[m
         }[m
         [m
[31m-        // Función para eliminar todos los usuarios de index.html[m
[31m-        function deleteAllUsers() {[m
[32m+[m[32m        // Función para eliminar todos los usuarios[m
[32m+[m[32m        async function deleteAllUsers() {[m
             if (confirm('⚠️ ¿Estás seguro de que quieres eliminar TODOS los usuarios registrados?\n\nEsta acción eliminará todos los usuarios de la aplicación móvil (index.html) y no se puede deshacer.')) {[m
                 try {[m
[32m+[m[32m                    // Obtener usuarios antes de eliminar para intentar eliminarlos de Supabase[m
[32m+[m[32m                    const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');[m
[32m+[m[41m                    [m
[32m+[m[32m                    // Intentar eliminar de Supabase si está inicializado[m
[32m+[m[32m                    if (window.supabaseClient && window.supabaseClient.isInitialized() && users.length > 0) {[m
[32m+[m[32m                        console.log('🗑️ Eliminando usuarios de Supabase...');[m
[32m+[m[32m                        let deletedFromSupabase = 0;[m
[32m+[m[32m                        let errorsFromSupabase = 0;[m
[32m+[m[41m                        [m
[32m+[m[32m                        for (const user of users) {[m
[32m+[m[32m                            try {[m
[32m+[m[32m                                await window.supabaseClient.deleteUser(user.id);[m
[32m+[m[32m                                deletedFromSupabase++;[m
[32m+[m[32m                            } catch (error) {[m
[32m+[m[32m                                // Ignorar errores si el usuario no existe en Supabase[m
[32m+[m[32m                                errorsFromSupabase++;[m
[32m+[m[32m                                console.log(`ℹ️ Usuario ${user.id} no existe en Supabase o ya fue eliminado`);[m
[32m+[m[32m                            }[m
[32m+[m[32m                        }[m
[32m+[m[41m                        [m
[32m+[m[32m                        console.log(`✅ ${deletedFromSupabase} usuarios eliminados de Supabase`);[m
[32m+[m[32m                        if (errorsFromSupabase > 0) {[m
[32m+[m[32m                            console.log(`ℹ️ ${errorsFromSupabase} usuarios no encontrados en Supabase (probablemente solo en localStorage)`);[m
[32m+[m[32m                        }[m
[32m+[m[32m                    }[m
[32m+[m[41m                    [m
                     // Eliminar usuarios de checkin24hs_users (dashboard)[m
                     localStorage.removeItem('checkin24hs_users');[m
                     [m
