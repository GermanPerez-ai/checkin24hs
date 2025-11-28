// Dashboard Integration Script for Checkin24hs
// Este archivo permite la sincronización automática entre index.html y dashboard.html

class Checkin24hsDashboardIntegration {
    constructor() {
        this.init();
    }

    init() {
        console.log('🔄 Inicializando integración con Checkin24hs Dashboard...');
        
        // Escuchar eventos de autenticación
        this.setupEventListeners();
        
        // Verificar estado de autenticación al cargar
        this.checkAuthStatus();
        
        // Sincronizar datos cada 30 segundos
        setInterval(() => this.syncData(), 30000);
    }

    setupEventListeners() {
        // Usuario logueado
        window.addEventListener('userLoggedIn', (event) => {
            console.log('👤 Usuario logueado detectado:', event.detail.user);
            this.handleUserLogin(event.detail.user);
        });

        // Usuario deslogueado
        window.addEventListener('userLoggedOut', () => {
            console.log('🚪 Usuario deslogueado detectado');
            this.handleUserLogout();
        });

        // Usuario desactivado
        window.addEventListener('userDeactivated', (event) => {
            console.log('🗑️ Usuario desactivado detectado:', event.detail.user);
            this.handleUserDeactivation(event.detail.user);
        });

        // Cambios en localStorage
        window.addEventListener('storage', (event) => {
            if (event.key === 'checkin24hs_user' || event.key === 'dashboard_user_data') {
                console.log('💾 Cambio detectado en localStorage:', event.key);
                this.handleStorageChange(event);
            }
        });
    }

    checkAuthStatus() {
        const userData = localStorage.getItem('dashboard_user_data');
        const currentUser = localStorage.getItem('checkin24hs_user');
        
        if (userData && currentUser) {
            const user = JSON.parse(userData);
            console.log('✅ Usuario autenticado encontrado:', user);
            this.updateDashboardUI(user);
        } else {
            console.log('❌ No hay usuario autenticado');
            this.updateDashboardUI(null);
        }
    }

    handleUserLogin(user) {
        // Actualizar UI del dashboard
        this.updateDashboardUI(user);
        
        // Guardar en historial de sesiones
        this.saveSessionHistory(user, 'login');
        
        // Mostrar notificación
        this.showDashboardNotification(`Bienvenido, ${user.nombre} ${user.apellido}!`, 'success');
        
        // Actualizar estadísticas
        this.updateUserStatistics(user);
    }

    handleUserLogout() {
        // Limpiar UI del dashboard
        this.updateDashboardUI(null);
        
        // Guardar en historial
        const lastUser = JSON.parse(localStorage.getItem('dashboard_user_data') || '{}');
        if (lastUser.id) {
            this.saveSessionHistory(lastUser, 'logout');
        }
        
        // Mostrar notificación
        this.showDashboardNotification('Sesión cerrada correctamente', 'info');
    }

    handleUserDeactivation(user) {
        // Actualizar UI del dashboard
        this.updateDashboardUI(null);
        
        // Guardar en historial
        this.saveSessionHistory(user, 'deactivation');
        
        // Mostrar notificación
        this.showDashboardNotification(`Usuario ${user.nombre} ${user.apellido} desactivado`, 'warning');
        
        // Actualizar estadísticas
        this.updateUserStatistics(user, 'deactivation');
    }

    handleStorageChange(event) {
        if (event.newValue) {
            const user = JSON.parse(event.newValue);
            this.updateDashboardUI(user);
        } else {
            this.updateDashboardUI(null);
        }
    }

    updateDashboardUI(user) {
        // Buscar elementos del dashboard para actualizar
        const userInfoElements = document.querySelectorAll('[data-user-info]');
        const authElements = document.querySelectorAll('[data-auth-status]');
        
        if (user) {
            // Usuario autenticado
            userInfoElements.forEach(element => {
                const field = element.getAttribute('data-user-info');
                if (user[field]) {
                    element.textContent = user[field];
                }
            });
            
            authElements.forEach(element => {
                element.style.display = 'block';
                element.classList.add('authenticated');
            });
            
            // Actualizar contador de usuarios activos
            this.updateActiveUsersCount();
            
        } else {
            // Usuario no autenticado
            userInfoElements.forEach(element => {
                element.textContent = 'No autenticado';
            });
            
            authElements.forEach(element => {
                element.style.display = 'none';
                element.classList.remove('authenticated');
            });
        }
    }

    saveSessionHistory(user, action) {
        const history = JSON.parse(localStorage.getItem('dashboard_session_history') || '[]');
        const sessionRecord = {
            userId: user.id,
            userName: `${user.nombre} ${user.apellido}`,
            userEmail: user.email,
            action: action,
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
            ip: '127.0.0.1' // En producción se obtendría del servidor
        };
        
        history.push(sessionRecord);
        
        // Mantener solo los últimos 100 registros
        if (history.length > 100) {
            history.splice(0, history.length - 100);
        }
        
        localStorage.setItem('dashboard_session_history', JSON.stringify(history));
        console.log('📝 Historial de sesión actualizado:', sessionRecord);
    }

    updateUserStatistics(user, action = 'login') {
        const stats = JSON.parse(localStorage.getItem('dashboard_user_stats') || '{}');
        
        if (!stats[user.id]) {
            stats[user.id] = {
                userId: user.id,
                userName: `${user.nombre} ${user.apellido}`,
                userEmail: user.email,
                firstLogin: new Date().toISOString(),
                loginCount: 0,
                lastLogin: null,
                totalSessionTime: 0,
                status: 'active'
            };
        }
        
        if (action === 'login') {
            stats[user.id].loginCount++;
            stats[user.id].lastLogin = new Date().toISOString();
            stats[user.id].status = 'active';
        } else if (action === 'deactivation') {
            stats[user.id].status = 'inactive';
        }
        
        localStorage.setItem('dashboard_user_stats', JSON.stringify(stats));
        console.log('📊 Estadísticas de usuario actualizadas:', stats[user.id]);
    }

    updateActiveUsersCount() {
        const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        const activeUsers = users.filter(user => user.activo);
        
        // Actualizar contador en el dashboard si existe
        const activeUsersElement = document.getElementById('active-users-count');
        if (activeUsersElement) {
            activeUsersElement.textContent = activeUsers.length;
        }
        
        console.log('👥 Usuarios activos:', activeUsers.length);
    }

    syncData() {
        // Sincronizar datos con el servidor (simulado)
        const userData = localStorage.getItem('dashboard_user_data');
        if (userData) {
            console.log('🔄 Sincronizando datos...');
            // Aquí se enviarían los datos al servidor
        }
    }

    showDashboardNotification(message, type = 'info') {
        // Crear notificación para el dashboard
        const notification = document.createElement('div');
        notification.className = 'dashboard-notification';
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 8px;
            color: white;
            font-weight: 600;
            z-index: 10001;
            animation: slideIn 0.3s ease;
            max-width: 300px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        `;
        
        // Estilos según tipo
        switch (type) {
            case 'success':
                notification.style.backgroundColor = '#28a745';
                break;
            case 'error':
                notification.style.backgroundColor = '#dc3545';
                break;
            case 'warning':
                notification.style.backgroundColor = '#ffc107';
                notification.style.color = '#333';
                break;
            default:
                notification.style.backgroundColor = '#17a2b8';
        }
        
        notification.textContent = message;
        document.body.appendChild(notification);
        
        // Remover después de 4 segundos
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 4000);
    }

    // Métodos públicos para usar desde el dashboard
    getCurrentUser() {
        const userData = localStorage.getItem('dashboard_user_data');
        return userData ? JSON.parse(userData) : null;
    }

    getUserStatistics() {
        return JSON.parse(localStorage.getItem('dashboard_user_stats') || '{}');
    }

    getSessionHistory() {
        return JSON.parse(localStorage.getItem('dashboard_session_history') || '[]');
    }

    getAllUsers() {
        return JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
    }

    forceLogout(userId) {
        const users = this.getAllUsers();
        const userIndex = users.findIndex(u => u.id === userId);
        
        if (userIndex !== -1) {
            users[userIndex].activo = false;
            localStorage.setItem('checkin24hs_users', JSON.stringify(users));
            
            // Si es el usuario actual, cerrar sesión
            const currentUser = this.getCurrentUser();
            if (currentUser && currentUser.id === userId) {
                localStorage.removeItem('checkin24hs_user');
                localStorage.removeItem('checkin24hs_token');
                localStorage.removeItem('dashboard_user_data');
                
                this.handleUserLogout();
            }
            
            this.showDashboardNotification(`Usuario ${users[userIndex].nombre} desactivado por administrador`, 'warning');
            return true;
        }
        return false;
    }
}

// Inicializar integración cuando se carga el dashboard
if (typeof window !== 'undefined') {
    window.Checkin24hsDashboard = new Checkin24hsDashboardIntegration();
    
    // Hacer disponible globalmente
    window.checkin24hsAPI = {
        getCurrentUser: () => window.Checkin24hsDashboard.getCurrentUser(),
        getUserStatistics: () => window.Checkin24hsDashboard.getUserStatistics(),
        getSessionHistory: () => window.Checkin24hsDashboard.getSessionHistory(),
        getAllUsers: () => window.Checkin24hsDashboard.getAllUsers(),
        forceLogout: (userId) => window.Checkin24hsDashboard.forceLogout(userId)
    };
}

console.log('✅ Checkin24hs Dashboard Integration cargado');
