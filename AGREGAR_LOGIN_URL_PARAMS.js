// Código para agregar al final de dashboard.html
// Permite login automático usando parámetros de URL: ?username=German&password=123456

(function() {
    'use strict';
    
    // Función para leer parámetros de URL
    function getURLParams() {
        const params = new URLSearchParams(window.location.search);
        return {
            username: params.get('username') || params.get('user'),
            password: params.get('password') || params.get('pass')
        };
    }
    
    // Función para inicializar usuarios admin si no existen
    function initAdminUsers() {
        const storedUsers = localStorage.getItem('dashboard_admin_users');
        if (!storedUsers) {
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
            return defaultUsers;
        }
        return JSON.parse(storedUsers);
    }
    
    // Función para obtener usuarios admin
    function getAdminUsers() {
        return JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
    }
    
    // Función para mostrar dashboard
    function showDashboard() {
        const loginContainer = document.getElementById('loginContainer');
        const dashboardContent = document.getElementById('dashboardContent');
        const body = document.body;
        
        if (loginContainer) {
            loginContainer.classList.add('hidden');
        }
        if (dashboardContent) {
            dashboardContent.classList.add('authenticated');
            dashboardContent.style.display = 'flex';
        }
        if (body) {
            body.classList.add('authenticated');
        }
        
        // Inicializar sincronización en tiempo real después de un pequeño delay
        setTimeout(function() {
            if (typeof initRealtimeSubscriptions === 'function') {
                initRealtimeSubscriptions();
            }
        }, 1000);
    }
    
    // Función para manejar login
    function handleLogin(event) {
        if (event) {
            event.preventDefault();
        }
        
        console.log('🔐 Intentando iniciar sesión...');
        
        const usernameInput = document.getElementById('loginUsername');
        const passwordInput = document.getElementById('loginPassword');
        const errorDiv = document.getElementById('loginError');
        const loginButton = document.getElementById('loginButton');
        
        if (!usernameInput || !passwordInput || !errorDiv || !loginButton) {
            console.error('❌ Elementos del formulario no encontrados');
            return false;
        }
        
        const username = usernameInput.value.trim();
        const password = passwordInput.value;
        
        // Limpiar error anterior
        if (errorDiv) {
            errorDiv.classList.remove('show');
            errorDiv.textContent = '';
        }
        
        // Validar que los campos no estén vacíos
        if (!username || !password) {
            if (errorDiv) {
                errorDiv.textContent = 'Por favor, completa todos los campos';
                errorDiv.classList.add('show');
            }
            return false;
        }
        
        // Deshabilitar botón mientras se procesa
        if (loginButton) {
            loginButton.disabled = true;
            loginButton.textContent = 'Iniciando sesión...';
        }
        
        // Autenticación - buscar en localStorage
        setTimeout(() => {
            let user = null;
            const adminUsers = getAdminUsers();
            
            // Buscar usuario
            user = adminUsers.find(u => 
                u.username === username && 
                (u.password === password || u.password_hash === password) &&
                u.status === 'active'
            );
            
            if (user) {
                // Actualizar último login
                user.lastLogin = new Date().toISOString();
                const updatedUsers = adminUsers.map(u => 
                    u.id === user.id ? user : u
                );
                localStorage.setItem('dashboard_admin_users', JSON.stringify(updatedUsers));
                
                // Login exitoso
                const session = {
                    username: user.username,
                    name: user.name,
                    role: user.role,
                    userId: user.id,
                    loginTime: Date.now(),
                    expiresAt: Date.now() + (24 * 60 * 60 * 1000) // 24 horas
                };
                
                localStorage.setItem('dashboard_auth_session', JSON.stringify(session));
                
                // Limpiar formulario
                if (usernameInput) usernameInput.value = '';
                if (passwordInput) passwordInput.value = '';
                
                // Mostrar dashboard
                showDashboard();
                
                console.log('✅ Login exitoso:', user.username, 'Rol:', user.role);
            } else {
                // Credenciales incorrectas
                if (errorDiv) {
                    errorDiv.textContent = 'Usuario o contraseña incorrectos';
                    errorDiv.classList.add('show');
                }
                if (loginButton) {
                    loginButton.disabled = false;
                    loginButton.textContent = 'Iniciar Sesión';
                }
                console.error('❌ Credenciales incorrectas');
            }
        }, 300);
        
        return false;
    }
    
    // Función para verificar autenticación
    function checkAuthStatus() {
        const authSession = localStorage.getItem('dashboard_auth_session');
        if (authSession) {
            try {
                const session = JSON.parse(authSession);
                const now = Date.now();
                if (session.expiresAt && now < session.expiresAt) {
                    console.log('✅ Sesión válida encontrada para:', session.username);
                    showDashboard();
                    return true;
                } else {
                    // Sesión expirada
                    console.log('⚠️ Sesión expirada, eliminando...');
                    localStorage.removeItem('dashboard_auth_session');
                }
            } catch (e) {
                console.error('❌ Error al verificar sesión:', e);
                localStorage.removeItem('dashboard_auth_session');
            }
        }
        return false;
    }
    
    // Función para login automático desde URL
    function autoLoginFromURL() {
        const params = getURLParams();
        
        if (params.username && params.password) {
            console.log('🔍 Parámetros de URL detectados, intentando login automático...');
            
            // Inicializar usuarios si no existen
            initAdminUsers();
            
            // Llenar campos del formulario
            const usernameInput = document.getElementById('loginUsername');
            const passwordInput = document.getElementById('loginPassword');
            
            if (usernameInput && passwordInput) {
                usernameInput.value = params.username;
                passwordInput.value = params.password;
                
                // Intentar login automático después de un pequeño delay
                setTimeout(() => {
                    // Crear un evento simulado
                    const fakeEvent = {
                        preventDefault: function() {}
                    };
                    handleLogin(fakeEvent);
                }, 500);
            } else {
                console.error('❌ Campos de login no encontrados');
            }
        }
    }
    
    // Hacer funciones disponibles globalmente
    window.handleLogin = handleLogin;
    window.checkAuthStatus = checkAuthStatus;
    window.initAdminUsers = initAdminUsers;
    window.getAdminUsers = getAdminUsers;
    window.showDashboard = showDashboard;
    
    // Ejecutar cuando el DOM esté listo
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            // Inicializar usuarios
            initAdminUsers();
            
            // Verificar sesión existente
            const hasSession = checkAuthStatus();
            
            // Si no hay sesión, intentar login desde URL
            if (!hasSession) {
                autoLoginFromURL();
            }
        });
    } else {
        // DOM ya está listo
        initAdminUsers();
        const hasSession = checkAuthStatus();
        if (!hasSession) {
            autoLoginFromURL();
        }
    }
})();
