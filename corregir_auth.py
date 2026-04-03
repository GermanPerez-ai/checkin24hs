import re

with open('dashboard.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Reemplazar la sección de verificación de autenticación en DOMContentLoaded
pattern1 = r'// Verificar si hay sesión válida usando la función helper\s+const isAuthenticated = isUserAuthenticated\(\);\s+// Solo inicializar el dashboard si el usuario está autenticado\s+if \(isAuthenticated\) \{.*?console\.log\(\x27✅ Dashboard inicializado correctamente\x27\);\s+\} else \{.*?if \(dashboardContent\) dashboardContent\.style\.display = \x27flex\x27;\s+\}'

replacement1 = '''// ELIMINADO: Verificación de autenticación - Dashboard siempre visible
            console.log('✅ Inicializando dashboard sin autenticación...');
            
            // Mostrar dashboard siempre
            const dashboardContent = document.getElementById('dashboardContent');
            if (dashboardContent) {
                dashboardContent.style.display = 'flex';
                dashboardContent.style.visibility = 'visible';
            }
            document.body.classList.add('authenticated');
            
            // Inicializar dashboard
            if (typeof initializeDashboard === 'function') {
                initializeDashboard();
            }
            
            // Configurar sincronización automática
            if (typeof setupAutoSync === 'function') {
                setupAutoSync();
            }
            
            console.log('✅ Dashboard inicializado correctamente');'''

content = re.sub(pattern1, replacement1, content, flags=re.DOTALL)

# Reemplazar verificación en WhatsApp
pattern2 = r'if \(!isUserAuthenticated\(\)\) \{\s+console\.log\(\x27🔒 Usuario no autenticado, NO cargando WhatsApp\x27\);\s+return; // Salir temprano si no hay sesión\s+\}'

replacement2 = '''// ELIMINADO: Verificación de autenticación - WhatsApp siempre disponible'''

content = re.sub(pattern2, replacement2, content, flags=re.DOTALL)

with open('dashboard.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correcciones aplicadas")
