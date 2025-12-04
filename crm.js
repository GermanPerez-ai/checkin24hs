// CRM - Customer Relationship Management System
// Checkin24hs

// ===== NAVEGACIÓN =====
// Declarar showSection globalmente INMEDIATAMENTE (IIFE para ejecutar de inmediato)
(function() {
    'use strict';
    
    // Función showSection - debe estar disponible ANTES de que se ejecute el HTML
    window.showSection = function(sectionId, event) {
        console.log('[CRM] 🔄 Cambiando a sección:', sectionId);
        
        // Ocultar todas las secciones
        const sections = document.querySelectorAll('.section');
        if (sections.length > 0) {
            sections.forEach(section => {
                section.style.display = 'none';
            });
        }
        
        // Remover clase active de todos los items del menú
        const menuItems = document.querySelectorAll('.menu-item');
        if (menuItems.length > 0) {
            menuItems.forEach(item => {
                item.classList.remove('active');
            });
        }
        
        // Mostrar sección seleccionada
        const section = document.getElementById(sectionId + '-section');
        if (section) {
            section.style.display = 'block';
            console.log('[CRM] ✅ Sección mostrada:', sectionId);
            
            // Activar item del menú
            if (event && event.target) {
                const menuItem = event.target.closest('.menu-item');
                if (menuItem) {
                    menuItem.classList.add('active');
                }
            } else {
                // Si no hay evento, buscar el elemento del menú correspondiente
                const menuItem = document.querySelector(`.menu-item[onclick*="showSection('${sectionId}')"]`);
                if (menuItem) {
                    menuItem.classList.add('active');
                }
            }
            
            // Cargar datos específicos de la sección
            if (typeof loadSectionData === 'function') {
                loadSectionData(sectionId);
            }
        } else {
            console.error('[CRM] ❌ Sección no encontrada:', sectionId + '-section');
        }
    };
})();

// Declarar showSection también como función normal para compatibilidad
function showSection(sectionId, event) {
    console.log('[CRM] 🔄 Cambiando a sección:', sectionId);
    
    // Ocultar todas las secciones
    document.querySelectorAll('.section').forEach(section => {
        section.style.display = 'none';
    });
    
    // Remover clase active de todos los items del menú
    document.querySelectorAll('.menu-item').forEach(item => {
        item.classList.remove('active');
    });
    
    // Mostrar sección seleccionada
    const section = document.getElementById(sectionId + '-section');
    if (section) {
        section.style.display = 'block';
        console.log('[CRM] ✅ Sección mostrada:', sectionId);
        
        // Activar item del menú
        if (event && event.target) {
            const menuItem = event.target.closest('.menu-item');
            if (menuItem) {
                menuItem.classList.add('active');
            }
        } else {
            // Si no hay evento, buscar el elemento del menú correspondiente
            const menuItem = document.querySelector(`.menu-item[onclick*="showSection('${sectionId}')"]`);
            if (menuItem) {
                menuItem.classList.add('active');
            }
        }
        
        // Cargar datos específicos de la sección
        loadSectionData(sectionId);
    } else {
        console.error('[CRM] ❌ Sección no encontrada:', sectionId + '-section');
    }
}

// Función global para compatibilidad con onclick (declarar inmediatamente)
window.showSection = showSection;

// También declarar antes de DOMContentLoaded para que esté disponible inmediatamente
if (typeof window.showSection === 'undefined') {
    window.showSection = function(sectionId, event) {
        console.log('[CRM] 🔄 Cambiando a sección:', sectionId);
        
        // Ocultar todas las secciones
        document.querySelectorAll('.section').forEach(section => {
            section.style.display = 'none';
        });
        
        // Remover clase active de todos los items del menú
        document.querySelectorAll('.menu-item').forEach(item => {
            item.classList.remove('active');
        });
        
        // Mostrar sección seleccionada
        const section = document.getElementById(sectionId + '-section');
        if (section) {
            section.style.display = 'block';
            console.log('[CRM] ✅ Sección mostrada:', sectionId);
            
            // Activar item del menú
            if (event && event.target) {
                const menuItem = event.target.closest('.menu-item');
                if (menuItem) {
                    menuItem.classList.add('active');
                }
            } else {
                // Si no hay evento, buscar el elemento del menú correspondiente
                const menuItem = document.querySelector(`.menu-item[onclick*="showSection('${sectionId}')"]`);
                if (menuItem) {
                    menuItem.classList.add('active');
                }
            }
            
            // Cargar datos específicos de la sección
            if (typeof loadSectionData === 'function') {
                loadSectionData(sectionId);
            }
        } else {
            console.error('[CRM] ❌ Sección no encontrada:', sectionId + '-section');
        }
    };
}

// Inicialización del CRM
document.addEventListener('DOMContentLoaded', function() {
    initializeCRM();
    loadFlorConfiguration();
});

function loadSectionData(sectionId) {
    switch(sectionId) {
        case 'dashboard':
            loadDashboardData();
            break;
        case 'customers':
            loadCustomers();
            break;
        case 'reservations':
            loadReservations();
            break;
        case 'quotes':
            loadQuotes();
            break;
        case 'interactions':
            loadInteractions();
            break;
        case 'chats':
            loadChats();
            break;
        case 'agents':
            loadAgents();
            break;
        case 'flor-config':
            loadFlorConfiguration();
            break;
    }
}

// ===== DASHBOARD =====
function initializeCRM() {
    loadDashboardData();
}

function loadDashboardData() {
    // Cargar estadísticas
    const customers = getCustomers();
    const reservations = getReservations();
    const quotes = getQuotes();
    
    document.getElementById('totalCustomers').textContent = customers.length;
    document.getElementById('activeReservations').textContent = 
        reservations.filter(r => r.status === 'confirmed' || r.status === 'pending').length;
    document.getElementById('pendingQuotes').textContent = 
        quotes.filter(q => q.status === 'pending').length;
    
    // Calcular ingresos del mes
    const currentMonth = new Date().getMonth();
    const currentYear = new Date().getFullYear();
    const monthlyRevenue = reservations
        .filter(r => {
            const resDate = new Date(r.created_at);
            return resDate.getMonth() === currentMonth && 
                   resDate.getFullYear() === currentYear &&
                   (r.status === 'confirmed' || r.status === 'approved');
        })
        .reduce((sum, r) => sum + (parseFloat(r.total_price) || 0), 0);
    
    document.getElementById('monthlyRevenue').textContent = 
        '$' + monthlyRevenue.toLocaleString('es-AR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    
    // Cargar reservas recientes
    loadRecentReservations();
}

function loadRecentReservations() {
    const reservations = getReservations()
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
        .slice(0, 10);
    
    const tbody = document.getElementById('recentReservations');
    if (reservations.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 40px;">No hay reservas recientes</td></tr>';
        return;
    }
    
    tbody.innerHTML = reservations.map(reservation => {
        const customer = getCustomerById(reservation.customer_id);
        const hotel = getHotelById(reservation.hotel_id);
        const statusBadge = getStatusBadge(reservation.status);
        
        return `
            <tr>
                <td>${customer ? customer.name : 'N/A'}</td>
                <td>${hotel ? hotel.name : 'N/A'}</td>
                <td>${formatDate(reservation.check_in)}</td>
                <td>${formatDate(reservation.check_out)}</td>
                <td>${statusBadge}</td>
                <td>$${parseFloat(reservation.total_price || 0).toLocaleString('es-AR', { minimumFractionDigits: 2 })}</td>
            </tr>
        `;
    }).join('');
}

// ===== CLIENTES =====
function loadCustomers() {
    const customers = getCustomers();
    const tbody = document.getElementById('customersTable');
    
    if (customers.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 40px;">No hay clientes registrados</td></tr>';
        return;
    }
    
    tbody.innerHTML = customers.map(customer => {
        const reservationsCount = getReservations()
            .filter(r => r.customer_id === customer.id).length;
        const lastVisit = customer.last_visit ? formatDate(customer.last_visit) : 'Nunca';
        
        return `
            <tr>
                <td>${customer.name}</td>
                <td>${customer.email || 'N/A'}</td>
                <td>${customer.phone || 'N/A'}</td>
                <td>${reservationsCount}</td>
                <td>${lastVisit}</td>
                <td>
                    <button class="btn btn-primary" onclick="editCustomer(${customer.id})" style="padding: 6px 12px; font-size: 0.85rem;">
                        <span class="material-icons" style="font-size: 18px;">edit</span>
                    </button>
                    <button class="btn" onclick="deleteCustomer(${customer.id})" style="padding: 6px 12px; font-size: 0.85rem; background: #dc3545; color: white;">
                        <span class="material-icons" style="font-size: 18px;">delete</span>
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function getCustomers() {
    try {
        const stored = localStorage.getItem('crm_customers');
        if (stored) return JSON.parse(stored);
        
        // Cargar desde usersDB si existe
        const users = JSON.parse(localStorage.getItem('usersDB') || '[]');
        return users.map(user => ({
            id: user.id || Date.now(),
            name: user.name,
            email: user.email,
            phone: user.phone,
            created_at: user.created_at || new Date().toISOString(),
            last_visit: user.last_login
        }));
    } catch (error) {
        console.error('Error loading customers:', error);
        return [];
    }
}

function getCustomerById(id) {
    return getCustomers().find(c => c.id === id);
}

function filterCustomers() {
    const searchTerm = document.getElementById('customerSearch').value.toLowerCase();
    const customers = getCustomers();
    const filtered = customers.filter(c => 
        c.name.toLowerCase().includes(searchTerm) ||
        (c.email && c.email.toLowerCase().includes(searchTerm)) ||
        (c.phone && c.phone.includes(searchTerm))
    );
    
    // Actualizar tabla con resultados filtrados
    const tbody = document.getElementById('customersTable');
    // Similar a loadCustomers pero con filtered
}

// ===== RESERVAS =====
function loadReservations() {
    const reservations = getReservations();
    renderReservationsTable(reservations);
}

function getReservations() {
    try {
        const stored = localStorage.getItem('crm_reservations');
        if (stored) return JSON.parse(stored);
        
        // Cargar desde quotesDB si existe
        const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
        return quotes
            .filter(q => q.status === 'approved' || q.status === 'confirmed')
            .map(quote => ({
                id: quote.id || Date.now(),
                customer_id: quote.user_id || quote.customer_id,
                hotel_id: quote.hotel_id,
                check_in: quote.checkIn || quote.check_in_date,
                check_out: quote.checkOut || quote.check_out_date,
                guests: quote.travelers || quote.guests || 2,
                total_price: quote.finalTariff || quote.tariff || quote.totalAmount || 0,
                status: quote.status === 'approved' ? 'confirmed' : quote.status || 'pending',
                created_at: quote.timestamp || quote.created_at || new Date().toISOString()
            }));
    } catch (error) {
        console.error('Error loading reservations:', error);
        return [];
    }
}

function showReservationTab(status) {
    // Actualizar tabs activos
    document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
    event.target.classList.add('active');
    
    // Filtrar reservas
    let reservations = getReservations();
    if (status !== 'all') {
        reservations = reservations.filter(r => {
            if (status === 'pending') return r.status === 'pending';
            if (status === 'confirmed') return r.status === 'confirmed' || r.status === 'approved';
            if (status === 'cancelled') return r.status === 'cancelled';
            return true;
        });
    }
    
    renderReservationsTable(reservations);
}

function renderReservationsTable(reservations) {
    const tbody = document.getElementById('reservationsTable');
    
    if (reservations.length === 0) {
        tbody.innerHTML = '<tr><td colspan="9" style="text-align: center; padding: 40px;">No hay reservas</td></tr>';
        return;
    }
    
    tbody.innerHTML = reservations.map(reservation => {
        const customer = getCustomerById(reservation.customer_id);
        const hotel = getHotelById(reservation.hotel_id);
        const statusBadge = getStatusBadge(reservation.status);
        
        return `
            <tr>
                <td>#${reservation.id}</td>
                <td>${customer ? customer.name : 'N/A'}</td>
                <td>${hotel ? hotel.name : 'N/A'}</td>
                <td>${formatDate(reservation.check_in)}</td>
                <td>${formatDate(reservation.check_out)}</td>
                <td>${reservation.guests || 2}</td>
                <td>$${parseFloat(reservation.total_price || 0).toLocaleString('es-AR', { minimumFractionDigits: 2 })}</td>
                <td>${statusBadge}</td>
                <td>
                    <button class="btn btn-primary" onclick="viewReservation(${reservation.id})" style="padding: 6px 12px; font-size: 0.85rem;">
                        Ver
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function getHotelById(id) {
    const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
    return hotels.find(h => h.id === id || h.id === parseInt(id));
}

// ===== COTIZACIONES =====
function loadQuotes() {
    const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
    const tbody = document.getElementById('quotesTable');
    
    if (quotes.length === 0) {
        tbody.innerHTML = '<tr><td colspan="9" style="text-align: center; padding: 40px;">No hay cotizaciones</td></tr>';
        return;
    }
    
    tbody.innerHTML = quotes.map(quote => {
        const customer = getCustomerById(quote.user_id || quote.clientName);
        const hotel = getHotelById(quote.hotel_id || quote.hotel);
        const statusBadge = getStatusBadge(quote.status || 'pending');
        const dateRange = quote.dateRange || `${quote.checkIn} - ${quote.checkOut}`;
        
        return `
            <tr>
                <td>#${quote.id || Date.now()}</td>
                <td>${customer ? customer.name : (quote.clientName || 'N/A')}</td>
                <td>${hotel ? hotel.name : (quote.hotel || 'N/A')}</td>
                <td>${dateRange}</td>
                <td>${quote.travelers || quote.guests || 2}</td>
                <td>$${parseFloat(quote.finalTariff || quote.tariff || quote.totalAmount || 0).toLocaleString('es-AR', { minimumFractionDigits: 2 })}</td>
                <td>${statusBadge}</td>
                <td>${formatDate(quote.timestamp || quote.created_at)}</td>
                <td>
                    <button class="btn btn-primary" onclick="viewQuote(${quote.id})" style="padding: 6px 12px; font-size: 0.85rem;">
                        Ver
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function getQuotes() {
    return JSON.parse(localStorage.getItem('quotesDB') || '[]');
}

// ===== INTERACCIONES =====
function loadInteractions() {
    const tbody = document.getElementById('interactionsTable');
    if (!tbody) return;
    
    // Obtener interacciones del sistema antiguo
    const oldInteractions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
    
    // Obtener interacciones del sistema de aprendizaje
    let learningInteractions = [];
    if (typeof FlorLearningSystem !== 'undefined') {
        learningInteractions = FlorLearningSystem.getInteractions() || [];
    }
    
    // Convertir interacciones del sistema de aprendizaje al formato esperado
    const convertedInteractions = learningInteractions.map(inter => {
        // Agrupar interacciones por sesión (mismo timestamp o muy cercanas)
        return {
            id: inter.id,
            timestamp: inter.timestamp,
            customer_name: 'Usuario',
            message_count: 1, // Cada interacción es un mensaje
            escalated: false,
            resolved: inter.success !== false,
            intent: inter.intent || 'consulta_general',
            userMessage: inter.userMessage,
            botResponse: inter.botResponse,
            hotelId: inter.hotelId,
            usedAI: inter.usedAI || false
        };
    });
    
    // Combinar ambas fuentes
    const allInteractions = [...oldInteractions, ...convertedInteractions];
    
    // Agrupar interacciones por sesión (mismo día y usuario)
    const groupedInteractions = groupInteractionsBySession(allInteractions);
    
    if (groupedInteractions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 40px;">No hay interacciones registradas</td></tr>';
        return;
    }
    
    tbody.innerHTML = groupedInteractions
        .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
        .map(interaction => {
            const date = interaction.timestamp ? formatDateTime(interaction.timestamp) : 'N/A';
            const messageCount = interaction.message_count || interaction.messages?.length || 1;
            const resolved = interaction.resolved !== false;
            const escalated = interaction.escalated === true;
            
            return `
                <tr>
                    <td>${date}</td>
                    <td>${interaction.customer_name || 'Usuario'}</td>
                    <td>${messageCount} mensaje${messageCount !== 1 ? 's' : ''}</td>
                    <td>${escalated ? 'Humano' : 'Flor'}</td>
                    <td>${resolved ? '<span class="badge badge-approved">Resuelto</span>' : '<span class="badge badge-pending">Abierto</span>'}</td>
                    <td>
                        <button class="btn btn-primary" onclick="viewInteraction('${interaction.id}')" style="padding: 6px 12px; font-size: 0.85rem;">
                            Ver
                        </button>
                    </td>
                </tr>
            `;
        }).join('');
}

// Agrupar interacciones por sesión (mismo día, mismo usuario)
function groupInteractionsBySession(interactions) {
    const sessions = {};
    
    interactions.forEach(inter => {
        const date = new Date(inter.timestamp);
        const sessionKey = date.toDateString(); // Agrupar por día
        
        if (!sessions[sessionKey]) {
            sessions[sessionKey] = {
                id: 'session_' + sessionKey.replace(/\s+/g, '_'), // ID único para la sesión
                sessionKey: sessionKey, // Guardar la clave de sesión
                timestamp: inter.timestamp,
                customer_name: inter.customer_name || 'Usuario',
                message_count: 0,
                messages: [],
                allInteractions: [], // Guardar todas las interacciones de la sesión
                escalated: inter.escalated || false,
                resolved: inter.resolved !== false,
                intent: inter.intent || 'consulta_general'
            };
        }
        
        sessions[sessionKey].message_count++;
        sessions[sessionKey].allInteractions.push(inter); // Guardar la interacción completa
        
        if (inter.userMessage) {
            sessions[sessionKey].messages.push({
                role: 'user',
                content: inter.userMessage,
                timestamp: inter.timestamp
            });
            if (inter.botResponse) {
                sessions[sessionKey].messages.push({
                    role: 'bot',
                    content: inter.botResponse,
                    timestamp: inter.timestamp
                });
            }
        }
    });
    
    // Ordenar mensajes por timestamp dentro de cada sesión
    Object.values(sessions).forEach(session => {
        session.messages.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
    });
    
    return Object.values(sessions);
}

// Función global para escapar HTML
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ===== CHATS =====
let currentChatSession = null;

function loadChats() {
    const chatsList = document.getElementById('chatsList');
    if (!chatsList) return;
    
    // Obtener interacciones del sistema de aprendizaje
    let learningInteractions = [];
    if (typeof FlorLearningSystem !== 'undefined') {
        learningInteractions = FlorLearningSystem.getInteractions() || [];
    }
    
    // Convertir interacciones al formato esperado
    const convertedInteractions = learningInteractions.map(inter => {
        return {
            id: inter.id,
            timestamp: inter.timestamp,
            customer_name: 'Usuario',
            message_count: 1,
            escalated: false,
            resolved: inter.success !== false,
            intent: inter.intent || 'consulta_general',
            userMessage: inter.userMessage,
            botResponse: inter.botResponse,
            hotelId: inter.hotelId,
            usedAI: inter.usedAI || false
        };
    });
    
    // Agrupar interacciones por sesión
    const groupedSessions = groupInteractionsBySession(convertedInteractions);
    
    if (groupedSessions.length === 0) {
        chatsList.innerHTML = '<p style="text-align: center; color: #666; padding: 20px;">No hay chats disponibles</p>';
        return;
    }
    
    // Renderizar lista de chats
    chatsList.innerHTML = groupedSessions.map(session => {
        const date = new Date(session.timestamp);
        const formattedDate = date.toLocaleDateString('es-ES', { 
            day: '2-digit', 
            month: '2-digit', 
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        return `
            <div class="chat-item" onclick="openChat('${session.id}')" 
                 style="padding: 12px; border-bottom: 1px solid #e0e0e0; cursor: pointer; transition: background 0.2s;"
                 onmouseover="this.style.background='#f5f5f5'" 
                 onmouseout="this.style.background='white'">
                <div style="font-weight: 500; margin-bottom: 4px;">${session.customer_name}</div>
                <div style="font-size: 0.85rem; color: #666; margin-bottom: 4px;">${formattedDate}</div>
                <div style="font-size: 0.85rem; color: #999;">
                    <span class="material-icons" style="font-size: 14px; vertical-align: middle;">message</span>
                    ${session.message_count} mensajes
                </div>
            </div>
        `;
    }).join('');
}

function openChat(sessionId) {
    // Obtener todas las interacciones
    let learningInteractions = [];
    if (typeof FlorLearningSystem !== 'undefined') {
        learningInteractions = FlorLearningSystem.getInteractions() || [];
    }
    
    const convertedInteractions = learningInteractions.map(inter => {
        return {
            id: inter.id,
            timestamp: inter.timestamp,
            customer_name: 'Usuario',
            message_count: 1,
            escalated: false,
            resolved: inter.success !== false,
            intent: inter.intent || 'consulta_general',
            userMessage: inter.userMessage,
            botResponse: inter.botResponse,
            hotelId: inter.hotelId,
            usedAI: inter.usedAI || false
        };
    });
    
    // Agrupar por sesión
    const groupedSessions = groupInteractionsBySession(convertedInteractions);
    const session = groupedSessions.find(s => s.id === sessionId);
    
    if (!session) {
        console.error('Sesión no encontrada:', sessionId);
        return;
    }
    
    currentChatSession = session;
    
    // Actualizar header del chat
    const chatHeader = document.getElementById('chatHeader');
    const date = new Date(session.timestamp);
    const formattedDate = date.toLocaleDateString('es-ES', { 
        day: '2-digit', 
        month: '2-digit', 
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    if (chatHeader) {
        chatHeader.innerHTML = `
            <h3 style="margin: 0; font-size: 1.1rem;">${session.customer_name}</h3>
            <p style="margin: 4px 0 0 0; font-size: 0.85rem; color: #666;">${formattedDate} • ${session.message_count} mensajes</p>
        `;
    }
    
    // Mostrar mensajes
    const chatMessages = document.getElementById('chatMessages');
    if (chatMessages) {
        // Ordenar mensajes por timestamp
        const allMessages = [];
        
        session.allInteractions.forEach(inter => {
            if (inter.userMessage) {
                allMessages.push({
                    role: 'user',
                    content: inter.userMessage,
                    timestamp: inter.timestamp
                });
            }
            if (inter.botResponse) {
                allMessages.push({
                    role: 'bot',
                    content: inter.botResponse,
                    timestamp: inter.timestamp
                });
            }
        });
        
        // Ordenar por timestamp
        allMessages.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
        
        chatMessages.innerHTML = allMessages.map(msg => {
            const msgDate = new Date(msg.timestamp);
            const msgTime = msgDate.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
            
            if (msg.role === 'user') {
                return `
                    <div style="margin-bottom: 16px; display: flex; justify-content: flex-end;">
                        <div style="background: #1976d2; color: white; padding: 12px 16px; border-radius: 18px; max-width: 70%; word-wrap: break-word;">
                            <div style="margin-bottom: 4px;">${escapeHtml(msg.content)}</div>
                            <div style="font-size: 0.75rem; opacity: 0.8; text-align: right;">${msgTime}</div>
                        </div>
                    </div>
                `;
            } else {
                return `
                    <div style="margin-bottom: 16px; display: flex; justify-content: flex-start;">
                        <div style="background: white; color: #333; padding: 12px 16px; border-radius: 18px; max-width: 70%; word-wrap: break-word; border: 1px solid #e0e0e0;">
                            <div style="margin-bottom: 4px;"><strong>Flor:</strong> ${escapeHtml(msg.content)}</div>
                            <div style="font-size: 0.75rem; color: #666; text-align: right;">${msgTime}</div>
                        </div>
                    </div>
                `;
            }
        }).join('');
        
        // Scroll al final
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }
    
    // Mostrar input
    const chatInputContainer = document.getElementById('chatInputContainer');
    if (chatInputContainer) {
        chatInputContainer.style.display = 'block';
    }
    
    // Enfocar input
    const chatMessageInput = document.getElementById('chatMessageInput');
    if (chatMessageInput) {
        chatMessageInput.focus();
    }
}

function sendChatMessage() {
    const chatMessageInput = document.getElementById('chatMessageInput');
    if (!chatMessageInput || !currentChatSession) return;
    
    const message = chatMessageInput.value.trim();
    if (!message) return;
    
    // Agregar mensaje del agente al chat
    const chatMessages = document.getElementById('chatMessages');
    if (chatMessages) {
        const now = new Date();
        const msgTime = now.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
        
        const agentMessage = `
            <div style="margin-bottom: 16px; display: flex; justify-content: flex-end;">
                <div style="background: #4caf50; color: white; padding: 12px 16px; border-radius: 18px; max-width: 70%; word-wrap: break-word;">
                    <div style="margin-bottom: 4px;"><strong>Agente:</strong> ${escapeHtml(message)}</div>
                    <div style="font-size: 0.75rem; opacity: 0.8; text-align: right;">${msgTime}</div>
                </div>
            </div>
        `;
        
        chatMessages.innerHTML += agentMessage;
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }
    
    // Guardar respuesta del agente (opcional: guardar en localStorage)
    // Por ahora solo mostramos el mensaje en la interfaz
    
    // Limpiar input
    chatMessageInput.value = '';
    
    // Recargar chats para actualizar el contador
    setTimeout(() => {
        loadChats();
    }, 500);
}

// ===== AGENTES =====
function loadAgents() {
    const tbody = document.getElementById('agentsTable');
    if (!tbody) return;
    
    const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
    
    if (agents.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 40px;">No hay agentes registrados</td></tr>';
        return;
    }
    
    // Ordenar por fecha de creación (más recientes primero)
    const sortedAgents = agents.sort((a, b) => {
        const dateA = new Date(a.createdAt || 0);
        const dateB = new Date(b.createdAt || 0);
        return dateB - dateA;
    });
    
    tbody.innerHTML = sortedAgents.map(agent => {
        const createdDate = agent.createdAt ? new Date(agent.createdAt).toLocaleDateString('es-ES') : 'N/A';
        const isActive = agent.active !== false;
        
        // Contar reservas del agente
        const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
        const agentReservations = reservations.filter(r => r.agent === agent.name || r.agentName === agent.name).length;
        
        return `
            <tr>
                <td><strong>${escapeHtml(agent.code || 'N/A')}</strong></td>
                <td>${escapeHtml(agent.name || 'N/A')}</td>
                <td>${escapeHtml(agent.agency || 'N/A')}</td>
                <td>
                    <span class="badge ${isActive ? 'badge-success' : 'badge-danger'}">
                        ${isActive ? 'Activo' : 'Inactivo'}
                    </span>
                </td>
                <td style="text-align: center;">${agentReservations}</td>
                <td>${createdDate}</td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="editAgent('${agent.id}')" title="Editar">
                        <span class="material-icons" style="font-size: 16px;">edit</span>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="deleteAgent('${agent.id}')" title="Eliminar">
                        <span class="material-icons" style="font-size: 16px;">delete</span>
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function searchAgents() {
    const searchInput = document.getElementById('agentsSearchInput');
    const tbody = document.getElementById('agentsTable');
    if (!searchInput || !tbody) return;
    
    const searchTerm = searchInput.value.toLowerCase().trim();
    const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
    
    if (!searchTerm) {
        loadAgents();
        return;
    }
    
    const filteredAgents = agents.filter(agent => {
        const code = (agent.code || '').toLowerCase();
        const name = (agent.name || '').toLowerCase();
        const agency = (agent.agency || '').toLowerCase();
        return code.includes(searchTerm) || name.includes(searchTerm) || agency.includes(searchTerm);
    });
    
    if (filteredAgents.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 40px;">No se encontraron agentes</td></tr>';
        return;
    }
    
    const sortedAgents = filteredAgents.sort((a, b) => {
        const dateA = new Date(a.createdAt || 0);
        const dateB = new Date(b.createdAt || 0);
        return dateB - dateA;
    });
    
    tbody.innerHTML = sortedAgents.map(agent => {
        const createdDate = agent.createdAt ? new Date(agent.createdAt).toLocaleDateString('es-ES') : 'N/A';
        const isActive = agent.active !== false;
        
        const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
        const agentReservations = reservations.filter(r => r.agent === agent.name || r.agentName === agent.name).length;
        
        return `
            <tr>
                <td><strong>${escapeHtml(agent.code || 'N/A')}</strong></td>
                <td>${escapeHtml(agent.name || 'N/A')}</td>
                <td>${escapeHtml(agent.agency || 'N/A')}</td>
                <td>
                    <span class="badge ${isActive ? 'badge-success' : 'badge-danger'}">
                        ${isActive ? 'Activo' : 'Inactivo'}
                    </span>
                </td>
                <td style="text-align: center;">${agentReservations}</td>
                <td>${createdDate}</td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="editAgent('${agent.id}')" title="Editar">
                        <span class="material-icons" style="font-size: 16px;">edit</span>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="deleteAgent('${agent.id}')" title="Eliminar">
                        <span class="material-icons" style="font-size: 16px;">delete</span>
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function openNewAgentModal() {
    const modal = document.getElementById('agentModal');
    const form = document.getElementById('agentForm');
    const title = document.getElementById('agentModalTitle');
    
    if (!modal || !form || !title) return;
    
    // Limpiar formulario
    form.reset();
    document.getElementById('agentId').value = '';
    title.textContent = 'Nuevo Agente';
    
    // Generar código automático
    const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
    const year = new Date().getFullYear();
    const nextNumber = agents.length + 1;
    const agentCode = `AGT-${year}-${nextNumber.toString().padStart(3, '0')}`;
    document.getElementById('agentCode').value = agentCode;
    
    modal.style.display = 'flex';
}

function closeAgentModal() {
    const modal = document.getElementById('agentModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

function editAgent(agentId) {
    const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
    const agent = agents.find(a => a.id === agentId);
    
    if (!agent) {
        alert('Agente no encontrado');
        return;
    }
    
    const modal = document.getElementById('agentModal');
    const form = document.getElementById('agentForm');
    const title = document.getElementById('agentModalTitle');
    
    if (!modal || !form || !title) return;
    
    // Llenar formulario
    document.getElementById('agentId').value = agent.id;
    document.getElementById('agentCode').value = agent.code || '';
    document.getElementById('agentName').value = agent.name || '';
    document.getElementById('agentAgency').value = agent.agency || '';
    document.getElementById('agentActive').value = agent.active !== false ? 'true' : 'false';
    title.textContent = 'Editar Agente';
    
    modal.style.display = 'flex';
}

function saveAgent(event) {
    event.preventDefault();
    
    const agentId = document.getElementById('agentId').value;
    const code = document.getElementById('agentCode').value.trim();
    const name = document.getElementById('agentName').value.trim();
    const agency = document.getElementById('agentAgency').value.trim();
    const active = document.getElementById('agentActive').value === 'true';
    
    if (!code || !name || !agency) {
        alert('Por favor completa todos los campos requeridos');
        return;
    }
    
    const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
    
    if (agentId) {
        // Editar agente existente
        const agentIndex = agents.findIndex(a => a.id === agentId);
        if (agentIndex === -1) {
            alert('Agente no encontrado');
            return;
        }
        
        // Verificar si el código ya existe en otro agente
        const existingAgent = agents.find(a => a.code === code && a.id !== agentId);
        if (existingAgent) {
            alert('Ya existe un agente con este código');
            return;
        }
        
        agents[agentIndex] = {
            ...agents[agentIndex],
            code,
            name,
            agency,
            active,
            updatedAt: new Date().toISOString()
        };
    } else {
        // Nuevo agente
        // Verificar si el código ya existe
        const existingAgent = agents.find(a => a.code === code);
        if (existingAgent) {
            alert('Ya existe un agente con este código');
            return;
        }
        
        const newAgent = {
            id: 'agent-' + Date.now(),
            code,
            name,
            agency,
            active,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        agents.push(newAgent);
    }
    
    localStorage.setItem('agentsDB', JSON.stringify(agents));
    
    // Recargar lista
    loadAgents();
    
    // Cerrar modal
    closeAgentModal();
    
    alert(agentId ? 'Agente actualizado correctamente' : 'Agente creado correctamente');
}

function deleteAgent(agentId) {
    if (!confirm('¿Estás seguro de que deseas eliminar este agente?')) {
        return;
    }
    
    const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
    const filteredAgents = agents.filter(a => a.id !== agentId);
    
    if (filteredAgents.length === agents.length) {
        alert('Agente no encontrado');
        return;
    }
    
    localStorage.setItem('agentsDB', JSON.stringify(filteredAgents));
    
    // Recargar lista
    loadAgents();
    
    alert('Agente eliminado correctamente');
}

// ===== CONFIGURACIÓN DE FLOR =====
function showFlorTab(tabId) {
    // Si se muestra la pestaña de políticas, cargar el selector de hoteles
    if (tabId === 'policies') {
        loadPoliciesHotelSelector();
    }
    // Si se muestra la pestaña de aprendizaje, cargar los datos
    if (tabId === 'learning') {
        loadLearningData();
    }
    // Si se muestra la pestaña de WhatsApp, verificar conexión
    if (tabId === 'whatsapp') {
        loadWhatsAppConfig();
        checkWhatsAppConnection();
    }
    // Ocultar todos los tabs
    document.querySelectorAll('#flor-config-section .tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelectorAll('#flor-config-section .tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Mostrar tab seleccionado
    const tabContent = document.getElementById('flor-tab-' + tabId);
    if (tabContent) {
        tabContent.classList.add('active');
    }
    const tabButton = event && event.target ? event.target : document.querySelector(`.tab[onclick*="showFlorTab('${tabId}')"]`);
    if (tabButton) {
        tabButton.classList.add('active');
    }
}

function loadFlorConfiguration() {
    if (!FlorKnowledgeBase) return;
    
    const agent = FlorKnowledgeBase.agent;
    if (document.getElementById('flor-name')) {
        document.getElementById('flor-name').value = agent.name || 'Flor';
        document.getElementById('flor-role').value = agent.role || 'Asistente Virtual';
        document.getElementById('flor-greeting').value = agent.greeting || '';
        document.getElementById('flor-personality').value = agent.personality || '';
        
        // Cargar respuestas
        const responses = FlorKnowledgeBase.responses;
        document.getElementById('response-no-entendido').value = responses.no_entendido || '';
        document.getElementById('response-transferir').value = responses.transferir_humano || '';
        document.getElementById('response-despedida').value = responses.despedida || '';
        
        // Las políticas se cargan cuando se selecciona un hotel en la pestaña de políticas
        
        // Cargar hoteles (base de conocimiento)
        loadServicesList();
        
        // Cargar palabras clave
        loadIntentsList();
        
        // Cargar configuración de IA
        loadAIConfiguration();
        
        // Cargar analytics
        loadFlorAnalytics();
    }
}

// ===== CONFIGURACIÓN DE IA =====
function loadAIConfiguration() {
    if (typeof florAIService === 'undefined') {
        console.warn('[CRM] Servicio de IA no está disponible');
        return;
    }
    
    try {
        const config = florAIService.config;
        
        // Cargar valores en los campos si existen
        const enabledCheckbox = document.getElementById('ai-enabled');
        if (enabledCheckbox) {
            enabledCheckbox.checked = config.enabled || false;
            document.getElementById('ai-provider').value = config.provider || 'openai';
            document.getElementById('ai-api-key').value = config.apiKey || '';
            document.getElementById('ai-api-url').value = config.apiUrl || '';
            document.getElementById('ai-model').value = config.model || 'gpt-4o-mini';
            document.getElementById('ai-temperature').value = config.temperature || 0.7;
            document.getElementById('ai-max-tokens').value = config.maxTokens || 500;
            
            // Mostrar/ocultar campos según el estado
            toggleAIConfig();
            changeAIProvider();
        }
    } catch (e) {
        console.error('[CRM] Error al cargar configuración de IA:', e);
    }
}

function toggleAIConfig() {
    const enabledCheckbox = document.getElementById('ai-enabled');
    const fields = document.getElementById('ai-config-fields');
    
    if (enabledCheckbox && fields) {
        fields.style.display = enabledCheckbox.checked ? 'block' : 'none';
    }
}

function changeAIProvider() {
    const provider = document.getElementById('ai-provider');
    const urlGroup = document.getElementById('ai-api-url-group');
    const urlInput = document.getElementById('ai-api-url');
    const modelInput = document.getElementById('ai-model');
    
    if (provider && urlGroup && urlInput && modelInput) {
        if (provider.value === 'custom') {
            urlGroup.style.display = 'block';
            urlInput.required = true;
        } else {
            urlGroup.style.display = 'none';
            urlInput.required = false;
            
            // Cambiar automáticamente el modelo según el proveedor
            if (provider.value === 'openai') {
                urlInput.value = 'https://api.openai.com/v1/chat/completions';
                modelInput.value = 'gpt-4o-mini';
                modelInput.placeholder = 'gpt-4o-mini, gpt-4, gpt-3.5-turbo';
            } else if (provider.value === 'gemini') {
                urlInput.value = ''; // Gemini usa la API key en la URL
                modelInput.value = 'gemini-1.5-flash'; // Modelo por defecto (más actual)
                modelInput.placeholder = 'gemini-1.5-flash, gemini-1.5-pro, gemini-1.0-pro';
            } else if (provider.value === 'claude') {
                urlInput.value = 'https://api.anthropic.com/v1/messages';
                modelInput.value = 'claude-3-haiku-20240307';
                modelInput.placeholder = 'claude-3-haiku, claude-3-sonnet';
            }
        }
    }
}

function saveAIConfig() {
    if (typeof florAIService === 'undefined') {
        alert('❌ Servicio de IA no está disponible. Recarga la página.');
        return;
    }
    
    try {
        const provider = document.getElementById('ai-provider').value;
        const apiKey = document.getElementById('ai-api-key').value.trim();
        let apiUrl = document.getElementById('ai-api-url').value.trim();
        let model = document.getElementById('ai-model').value.trim();
        
        // Validar y establecer modelo por defecto según el proveedor
        if (provider === 'gemini') {
            // Validar que el modelo sea de Gemini
            if (!model || !model.startsWith('gemini-')) {
                alert('⚠️ Para Gemini debes usar un modelo válido (ej: gemini-1.5-flash). Cambiando automáticamente...');
                model = 'gemini-1.5-flash';
                document.getElementById('ai-model').value = model;
            }
        } else if (provider === 'openai') {
            if (!model) {
                model = 'gpt-4o-mini';
            }
        } else if (provider === 'claude') {
            if (!model) {
                model = 'claude-3-haiku-20240307';
            }
        }
        
        const config = {
            enabled: document.getElementById('ai-enabled').checked,
            provider: provider,
            apiKey: apiKey,
            apiUrl: apiUrl || null, // Para Gemini, la URL se construye dinámicamente
            model: model,
            temperature: parseFloat(document.getElementById('ai-temperature').value) || 0.7,
            maxTokens: parseInt(document.getElementById('ai-max-tokens').value) || 500
        };
        
        // Validar campos requeridos
        if (config.enabled && !config.apiKey) {
            alert('❌ Debes ingresar una API Key para habilitar la IA');
            return;
        }
        
        // Guardar configuración
        florAIService.configure(config);
        
        alert('✅ Configuración de IA guardada correctamente');
        console.log('[CRM] ✅ Configuración de IA guardada:', config);
        
    } catch (e) {
        console.error('[CRM] Error al guardar configuración de IA:', e);
        alert('❌ Error al guardar la configuración: ' + e.message);
    }
}

async function testAIConfig() {
    if (typeof florAIService === 'undefined') {
        alert('❌ Servicio de IA no está disponible');
        return;
    }
    
    try {
        const config = {
            enabled: document.getElementById('ai-enabled').checked,
            provider: document.getElementById('ai-provider').value,
            apiKey: document.getElementById('ai-api-key').value.trim(),
            apiUrl: document.getElementById('ai-api-url').value.trim() || null,
            model: document.getElementById('ai-model').value.trim(),
            temperature: parseFloat(document.getElementById('ai-temperature').value) || 0.7,
            maxTokens: parseInt(document.getElementById('ai-max-tokens').value) || 500
        };
        
        if (!config.apiKey) {
            alert('❌ Debes ingresar una API Key para probar');
            return;
        }
        
        // Configurar temporalmente
        florAIService.configure(config);
        
        // Probar con un mensaje simple
        alert('🔄 Probando conexión con la API...');
        const testResponse = await florAIService.generateAIResponse('Hola, ¿puedes responderme?', {});
        
        if (testResponse) {
            alert(`✅ Conexión exitosa!\n\nRespuesta de prueba:\n"${testResponse.substring(0, 100)}${testResponse.length > 100 ? '...' : ''}"`);
        } else {
            alert('⚠️ La conexión se estableció pero no se recibió respuesta');
        }
        
    } catch (e) {
        console.error('[CRM] Error al probar configuración de IA:', e);
        alert('❌ Error al probar la conexión: ' + e.message);
    }
}

function saveFlorGeneral() {
    if (!FlorKnowledgeBase) {
        alert('Error: FlorKnowledgeBase no está disponible');
        return;
    }
    
    FlorKnowledgeBase.agent.name = document.getElementById('flor-name').value;
    FlorKnowledgeBase.agent.role = document.getElementById('flor-role').value;
    FlorKnowledgeBase.agent.greeting = document.getElementById('flor-greeting').value;
    FlorKnowledgeBase.agent.personality = document.getElementById('flor-personality').value;
    
    // Guardar en localStorage
    localStorage.setItem('flor_config_agent', JSON.stringify(FlorKnowledgeBase.agent));
    
    alert('✅ Configuración general guardada correctamente');
}

function saveFlorResponses() {
    if (!FlorKnowledgeBase) return;
    
    FlorKnowledgeBase.responses.no_entendido = document.getElementById('response-no-entendido').value;
    FlorKnowledgeBase.responses.transferir_humano = document.getElementById('response-transferir').value;
    FlorKnowledgeBase.responses.despedida = document.getElementById('response-despedida').value;
    
    localStorage.setItem('flor_config_responses', JSON.stringify(FlorKnowledgeBase.responses));
    
    alert('✅ Respuestas guardadas correctamente');
}

// Cargar hoteles en el selector de políticas
function loadPoliciesHotelSelector() {
    const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
    const select = document.getElementById('policy-hotel-select');
    
    if (!select) return;
    
    // Limpiar opciones existentes (excepto la primera)
    select.innerHTML = '<option value="">-- Selecciona un hotel --</option>';
    
    // Agregar hoteles activos
    hotels.filter(h => h.is_active !== false).forEach(hotel => {
        const option = document.createElement('option');
        option.value = hotel.id;
        option.textContent = hotel.name;
        select.appendChild(option);
    });
}

// Cargar políticas del hotel seleccionado
function loadHotelPolicies() {
    const hotelId = document.getElementById('policy-hotel-select').value;
    const policiesForm = document.getElementById('hotel-policies-form');
    
    if (!hotelId) {
        policiesForm.style.display = 'none';
        return;
    }
    
    // Mostrar formulario
    policiesForm.style.display = 'block';
    
    // Obtener políticas del hotel desde la base de conocimiento
    const hotelKnowledge = FlorKnowledgeBase.getHotelKnowledge(hotelId);
    const policies = hotelKnowledge?.policies || {};
    
    // Cargar valores en los campos (formato simplificado)
    document.getElementById('policy-condiciones-reserva').value = policies.condiciones_reserva || '';
    document.getElementById('policy-cancelacion-modificacion').value = policies.cancelacion_modificacion || '';
}

function saveFlorPolicies() {
    if (!FlorKnowledgeBase) return;
    
    const hotelId = document.getElementById('policy-hotel-select').value;
    
    if (!hotelId) {
        alert('⚠️ Por favor, selecciona un hotel primero');
        return;
    }
    
    // Obtener valores del formulario (formato simplificado)
    const condicionesReserva = document.getElementById('policy-condiciones-reserva').value.trim();
    const cancelacionModificacion = document.getElementById('policy-cancelacion-modificacion').value.trim();
    
    // Crear objeto de políticas simplificado
    const policies = {
        condiciones_reserva: condicionesReserva,
        cancelacion_modificacion: cancelacionModificacion
    };
    
    // Obtener conocimiento actual del hotel
    const hotelKnowledge = FlorKnowledgeBase.getHotelKnowledge(hotelId) || {};
    
    // Actualizar políticas
    hotelKnowledge.policies = policies;
    hotelKnowledge.lastUpdated = new Date().toISOString();
    
    // Guardar conocimiento del hotel
    FlorKnowledgeBase.saveHotelKnowledge(hotelId, hotelKnowledge);
    
    // Obtener nombre del hotel para el mensaje
    const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
    const hotel = hotels.find(h => h.id == hotelId);
    const hotelName = hotel ? hotel.name : 'Hotel';
    
    alert(`✅ Políticas de ${hotelName} guardadas correctamente`);
    
    // Resetear el selector de hotel y ocultar el formulario
    const select = document.getElementById('policy-hotel-select');
    const policiesForm = document.getElementById('hotel-policies-form');
    
    if (select) {
        select.value = '';
    }
    if (policiesForm) {
        policiesForm.style.display = 'none';
    }
}

function loadServicesList() {
    // Cargar hoteles desde la base de datos
    const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
    const container = document.getElementById('hotels-knowledge-list');
    const selector = document.getElementById('knowledge-hotel-selector');
    
    if (!container) return; // Si no existe el contenedor, salir
    
    // Cargar selector de hoteles
    if (selector) {
        selector.innerHTML = '<option value="">-- Seleccione un hotel --</option>';
        const activeHotels = hotels.filter(h => h.is_active !== false);
        activeHotels.forEach(hotel => {
            const option = document.createElement('option');
            option.value = hotel.id;
            option.textContent = hotel.name;
            selector.appendChild(option);
        });
    }
    
    if (hotels.length === 0) {
        container.innerHTML = '<p style="text-align: center; padding: 40px; color: #666;">No hay hoteles registrados. Agrega hoteles primero desde la sección Hoteles del dashboard.</p>';
        return;
    }
    
    // Si no hay selección, mostrar mensaje
    container.innerHTML = '<p style="text-align: center; padding: 40px; color: #666; background: #f9f9f9; border-radius: 8px;">👆 Por favor, selecciona un hotel del menú desplegable para comenzar a configurar su información.</p>';
}

function loadSelectedHotelKnowledge() {
    const selector = document.getElementById('knowledge-hotel-selector');
    const container = document.getElementById('hotels-knowledge-list');
    
    if (!selector || !container) return;
    
    const selectedHotelId = selector.value;
    
    if (!selectedHotelId) {
        container.innerHTML = '<p style="text-align: center; padding: 40px; color: #666; background: #f9f9f9; border-radius: 8px;">👆 Por favor, selecciona un hotel del menú desplegable para comenzar a configurar su información.</p>';
        return;
    }
    
    // Cargar hoteles desde la base de datos
    const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
    const hotel = hotels.find(h => h.id == selectedHotelId);
    
    if (!hotel) {
        container.innerHTML = '<p style="text-align: center; padding: 40px; color: #d32f2f; background: #ffebee; border-radius: 8px;">❌ Hotel no encontrado. Por favor, recarga la página.</p>';
        return;
    }
    
    // Renderizar solo el hotel seleccionado
    container.innerHTML = renderHotelKnowledgeCard(hotel);
}

function renderHotelKnowledgeCard(hotel) {
    // Intentar cargar conocimiento con diferentes formatos de ID
    let hotelKnowledge = FlorKnowledgeBase.getHotelKnowledge(hotel.id) || {};
    
    // Si no se encuentra, intentar con formato 'hotel-{slug}'
    if (!hotelKnowledge || Object.keys(hotelKnowledge).length === 0) {
        const hotelSlug = hotel.name.toLowerCase()
            .replace(/^hotel\s+/i, '')
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .trim();
        const alternativeId = 'hotel-' + hotelSlug;
        const altKnowledge = FlorKnowledgeBase.getHotelKnowledge(alternativeId);
        if (altKnowledge && Object.keys(altKnowledge).length > 0) {
            hotelKnowledge = altKnowledge;
            console.log('[CRM] 🔄 Conocimiento encontrado con ID alternativo:', alternativeId, 'para hotel:', hotel.name);
            // Migrar el conocimiento al ID correcto (hotel.id) para futuras cargas
            if (hotel.id && hotel.id !== alternativeId) {
                FlorKnowledgeBase.saveHotelKnowledge(hotel.id, altKnowledge);
                console.log('[CRM] ✅ Conocimiento migrado al ID correcto:', hotel.id);
            }
        }
    }
    
    // También buscar en localStorage directamente con diferentes formatos
    if (!hotelKnowledge || Object.keys(hotelKnowledge).length === 0) {
        const hotelSlug = hotel.name.toLowerCase()
            .replace(/^hotel\s+/i, '')
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .trim();
        const possibleIds = [
            String(hotel.id),
            'hotel-' + hotelSlug,
            hotelSlug,
            hotel.name.toLowerCase().replace(/\s+/g, '-')
        ];
        
        for (const possibleId of possibleIds) {
            const stored = localStorage.getItem('flor_hotel_knowledge_' + possibleId);
            if (stored) {
                try {
                    const parsed = JSON.parse(stored);
                    if (parsed && Object.keys(parsed).length > 0) {
                        hotelKnowledge = parsed;
                        console.log('[CRM] 🔄 Conocimiento encontrado con ID:', possibleId, 'para hotel:', hotel.name);
                        // Migrar al ID correcto
                        if (hotel.id && String(hotel.id) !== possibleId) {
                            FlorKnowledgeBase.saveHotelKnowledge(hotel.id, parsed);
                            console.log('[CRM] ✅ Conocimiento migrado al ID correcto:', hotel.id);
                        }
                        break;
                    }
                } catch (e) {
                    console.warn('[CRM] ⚠️ Error al parsear conocimiento para ID:', possibleId, e);
                }
            }
        }
    }
    
    // Log para debugging
    if (hotelKnowledge && hotelKnowledge.specificIntegrations && hotelKnowledge.specificIntegrations.length > 0) {
        console.log('[CRM] 📋 Hotel ' + hotel.name + ' (ID: ' + hotel.id + ') tiene ' + hotelKnowledge.specificIntegrations.length + ' integraciones:', 
            hotelKnowledge.specificIntegrations.map(function(i) { return i.name || 'Sin nombre'; }));
    }
    
    return `
            <div class="hotel-knowledge-card" style="border: 2px solid #ddd; padding: 20px; border-radius: 12px; margin-bottom: 24px; background: #f9f9f9;">
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 20px;">
                    <div>
                        <h3 style="font-size: 1.3rem; color: #1976d2; margin-bottom: 8px;">🏨 ${hotel.name}</h3>
                        <p style="color: #666; font-size: 0.9rem;">📍 ${hotel.location}</p>
                        ${hotelKnowledge.description ? '' : '<p style="color: #d32f2f; font-size: 0.85rem; margin-top: 8px;">⚠️ Configuración incompleta - Flor derivará a humano</p>'}
                    </div>
                    <span class="badge ${hotelKnowledge.description ? 'badge-approved' : 'badge-pending'}" style="font-size: 0.85rem;">
                        ${hotelKnowledge.description ? '✓ Configurado' : 'Pendiente'}
                    </span>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Descripción Detallada del Hotel</label>
                    <textarea class="form-textarea hotel-desc-${hotel.id}" rows="3" 
                              placeholder="Descripción completa del hotel, características principales, ambiente...">${hotelKnowledge.description || hotel.description || ''}</textarea>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Dirección Completa</label>
                    <input type="text" class="form-input hotel-address-${hotel.id}" 
                           placeholder="Dirección exacta del hotel" 
                           value="${hotelKnowledge.address || hotel.address || ''}">
                </div>
                
                <div class="form-group">
                    <label class="form-label">Política de Precios</label>
                    <div style="padding: 16px; background: #e3f2fd; border-radius: 8px; border-left: 4px solid #1976d2; margin-top: 8px;">
                        <p style="margin: 0; color: #1976d2; line-height: 1.6; font-size: 0.95rem;">
                            <strong>💡 Información sobre Tarifas:</strong><br>
                            Las tarifas son dinámicas y varían según fecha, pueden variar en alta temporada o en baja temporada. 
                            Para una cotización precisa solicítela con: <strong>Fecha de Check-in</strong>, <strong>cantidad de noches</strong> y <strong>cantidad de personas</strong>. 
                            Las tarifas enviadas tienen validez de <strong>24 horas</strong>.
                        </p>
                    </div>
                    <p style="color: #666; font-size: 0.85rem; margin-top: 8px;">
                        Este mensaje se mostrará automáticamente cuando los clientes pregunten por precios.
                    </p>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Servicios y Amenidades</label>
                    <p style="color: #666; font-size: 0.85rem; margin-bottom: 12px;">
                        Lista los servicios con detalles. Indica cuáles están incluidos y cuáles tienen costo adicional.
                    </p>
                    <div id="hotel-services-${hotel.id}">
                        ${renderHotelServices(hotel.id, hotelKnowledge.servicesDetails || {})}
                    </div>
                    <button class="btn btn-success" onclick="addHotelService(${hotel.id})" style="margin-top: 12px; padding: 8px 16px; font-size: 0.9rem;">
                        <span class="material-icons" style="font-size: 18px;">add</span>
                        Agregar Servicio
                    </button>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Tipos de Habitaciones Disponibles</label>
                    <textarea class="form-textarea hotel-rooms-${hotel.id}" rows="3" 
                              placeholder="Ej: Suite Presidencial, Doble Premium, Junior Suite...">${(hotelKnowledge.roomTypes || []).join('\n')}</textarea>
                    <p style="color: #666; font-size: 0.85rem; margin-top: 8px;">Separar cada tipo de habitación en una nueva línea</p>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Políticas Específicas del Hotel</label>
                    <textarea class="form-textarea hotel-policies-${hotel.id}" rows="4" 
                              placeholder="Políticas especiales del hotel (check-in/check-out, mascotas, cancelación especial, etc.)">${hotelKnowledge.policies ? JSON.stringify(hotelKnowledge.policies, null, 2) : ''}</textarea>
                    <p style="color: #666; font-size: 0.85rem; margin-top: 8px;">Puede ser texto libre o JSON con políticas específicas</p>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Información Adicional</label>
                    <textarea class="form-textarea hotel-additional-${hotel.id}" rows="3" 
                              placeholder="Información adicional que Flor debe conocer sobre este hotel (puntos de interés cercanos, transporte, recomendaciones, etc.)">${hotelKnowledge.additionalInfo ? JSON.stringify(hotelKnowledge.additionalInfo, null, 2) : ''}</textarea>
                </div>
                
                <div class="form-group" style="border-top: 2px solid #ddd; padding-top: 20px; margin-top: 20px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                        <div>
                            <label class="form-label" style="font-size: 1.1rem; color: #1976d2; margin-bottom: 4px;">
                                🔗 Integraciones Específicas
                            </label>
                            <p style="color: #666; font-size: 0.85rem; margin: 0;">
                                Las integraciones específicas se activan según consultas puntuales del usuario. 
                                Cada integración tiene palabras clave que la activan cuando el usuario menciona esos términos.
                            </p>
                        </div>
                        <button class="btn" onclick="addHotelIntegration('${hotel.id}')" 
                                style="background: #28a745; color: white; padding: 10px 16px; border-radius: 6px; white-space: nowrap;">
                            <span class="material-icons" style="font-size: 18px; vertical-align: middle;">add</span>
                            Agregar Nueva
                        </button>
                    </div>
                    <div id="hotel-integrations-${hotel.id}" style="max-height: 600px; overflow-y: auto; padding-right: 8px;">
                        ${renderHotelIntegrations(hotel.id, hotelKnowledge.specificIntegrations || [])}
                    </div>
                </div>
                
                <button class="btn btn-primary" onclick="saveHotelKnowledge('${hotel.id}')" style="width: 100%; margin-top: 12px;">
                    <span class="material-icons" style="font-size: 18px;">save</span>
                    Guardar Información de ${hotel.name}
                </button>
            </div>
        `;
}

function renderHotelServices(hotelId, servicesDetails) {
    if (!servicesDetails || Object.keys(servicesDetails).length === 0) {
        return '<p style="color: #666; font-size: 0.9rem;">No hay servicios configurados. Agrega servicios específicos de este hotel.</p>';
    }
    
    // Inicializar contador para este hotel si no existe
    if (!hotelServicesCounters[hotelId]) {
        hotelServicesCounters[hotelId] = 0;
    }
    
    return Object.keys(servicesDetails).map((serviceKey, index) => {
        const service = servicesDetails[serviceKey];
        // Incrementar contador para IDs únicos
        hotelServicesCounters[hotelId] = Math.max(hotelServicesCounters[hotelId], index);
        const serviceIndex = index + 1;
        
        return `
            <div class="service-item" style="border: 1px solid #ddd; padding: 12px; border-radius: 8px; margin-bottom: 12px; background: white;">
                <div style="display: grid; grid-template-columns: 2fr 1fr auto; gap: 12px; align-items: start;">
                    <div>
                        <input type="text" class="form-input" placeholder="Nombre del servicio" 
                               value="${(service.name || serviceKey).replace(/"/g, '&quot;')}" 
                               id="service-name-${hotelId}-${serviceIndex}" 
                               style="margin-bottom: 8px;">
                        <textarea class="form-textarea" rows="2" placeholder="Descripción del servicio" 
                                  id="service-desc-${hotelId}-${serviceIndex}">${(service.description || '').replace(/"/g, '&quot;')}</textarea>
                    </div>
                    <div>
                        <label style="display: flex; align-items: center; gap: 8px; margin-bottom: 8px;">
                            <input type="checkbox" id="service-included-${hotelId}-${serviceIndex}" 
                                   ${service.included ? 'checked' : ''}
                                   onchange="toggleServiceCost(${hotelId}, ${serviceIndex})">
                            Incluido
                        </label>
                        <input type="number" class="form-input" placeholder="Costo adicional (USD)" 
                               value="${service.cost || ''}" 
                               id="service-cost-${hotelId}-${serviceIndex}"
                               ${service.included ? 'disabled' : ''}>
                    </div>
                    <button class="btn" onclick="removeHotelService(${hotelId}, ${serviceIndex})" 
                            style="background: #dc3545; color: white; padding: 8px;">
                        <span class="material-icons" style="font-size: 18px;">delete</span>
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

let hotelServicesCounters = {};

function addHotelService(hotelId) {
    const container = document.getElementById(`hotel-services-${hotelId}`);
    if (!container) return;
    
    if (!hotelServicesCounters[hotelId]) {
        hotelServicesCounters[hotelId] = 0;
    }
    hotelServicesCounters[hotelId]++;
    
    const index = hotelServicesCounters[hotelId];
    const serviceDiv = document.createElement('div');
    serviceDiv.className = 'service-item';
    serviceDiv.style.cssText = 'border: 1px solid #ddd; padding: 12px; border-radius: 8px; margin-bottom: 12px; background: white;';
    serviceDiv.innerHTML = `
        <div style="display: grid; grid-template-columns: 2fr 1fr auto; gap: 12px; align-items: start;">
            <div>
                <input type="text" class="form-input" placeholder="Nombre del servicio" 
                       id="service-name-${hotelId}-${index}" style="margin-bottom: 8px;">
                <textarea class="form-textarea" rows="2" placeholder="Descripción del servicio" 
                          id="service-desc-${hotelId}-${index}"></textarea>
            </div>
            <div>
                <label style="display: flex; align-items: center; gap: 8px; margin-bottom: 8px;">
                    <input type="checkbox" id="service-included-${hotelId}-${index}" 
                           onchange="toggleServiceCost(${hotelId}, ${index})">
                    Incluido
                </label>
                <input type="number" class="form-input" placeholder="Costo adicional (USD)" 
                       id="service-cost-${hotelId}-${index}">
            </div>
            <button class="btn" onclick="removeHotelService(${hotelId}, ${index})" 
                    style="background: #dc3545; color: white; padding: 8px;">
                <span class="material-icons" style="font-size: 18px;">delete</span>
            </button>
        </div>
    `;
    
    // Si hay un mensaje de "No hay servicios", eliminarlo
    if (container.innerHTML.includes('No hay servicios configurados')) {
        container.innerHTML = '';
    }
    
    container.appendChild(serviceDiv);
}

function removeHotelService(hotelId, index) {
    const serviceItem = event.target.closest('.service-item');
    if (serviceItem) {
        serviceItem.remove();
    }
}

function toggleServiceCost(hotelId, index) {
    const costInput = document.getElementById(`service-cost-${hotelId}-${index}`);
    const includedCheckbox = document.getElementById(`service-included-${hotelId}-${index}`);
    if (costInput) {
        costInput.disabled = includedCheckbox.checked;
        if (includedCheckbox.checked) {
            costInput.value = '';
        }
    }
}

// ===== FUNCIONES PARA INTEGRACIONES ESPECÍFICAS =====

function renderHotelIntegrations(hotelId, integrations) {
    try {
        // Función auxiliar para escapar HTML
        const escapeHtml = (text) => {
            if (!text) return '';
            return String(text)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#039;');
        };
        
        if (!integrations || integrations.length === 0) {
            return '<p style="color: #666; font-size: 0.9rem; padding: 12px; background: #f5f5f5; border-radius: 8px;">No hay integraciones configuradas. Las integraciones se activan cuando el usuario menciona palabras clave específicas en sus consultas.</p>';
        }
        
        // Selector de integraciones
        let html = '<div style="margin-bottom: 20px;">';
        html += '<label style="display: block; font-weight: bold; margin-bottom: 8px; font-size: 0.95rem; color: #1976d2;">';
        html += '📋 Seleccionar Integración para Editar o Eliminar:';
        html += '</label>';
        html += '<select id="integration-selector-' + hotelId + '" class="form-input" style="width: 100%; padding: 10px; font-size: 1rem; margin-bottom: 12px;" onchange="loadSelectedIntegration(\'' + hotelId + '\', this.value)">';
        html += '<option value="">-- Seleccione una integración --</option>';
        
        integrations.forEach((int, idx) => {
            const name = escapeHtml(int.name || 'Sin nombre');
            const integrationId = int.id || 'integration_' + hotelId + '_' + idx;
            html += '<option value="' + escapeHtml(integrationId) + '">' + (idx + 1) + '. ' + name + '</option>';
        });
        
        html += '</select>';
        html += '</div>';
        
        // Contenedor para mostrar la integración seleccionada
        html += '<div id="selected-integration-' + hotelId + '" style="display: none;">';
        html += '</div>';
        
        // Lista compacta de todas las integraciones (solo lectura)
        html += '<div style="background: #f9f9f9; border: 1px solid #ddd; border-radius: 8px; padding: 12px; margin-top: 16px;">';
        html += '<strong style="color: #666; font-size: 0.9rem; display: block; margin-bottom: 8px;">📋 Lista de Integraciones (' + integrations.length + '):</strong>';
        html += '<div style="max-height: 200px; overflow-y: auto;">';
        
        integrations.forEach((int, idx) => {
            const name = escapeHtml(int.name || 'Sin nombre');
            const keywords = (int.triggerKeywords || []).slice(0, 5).map(function(k) { return escapeHtml(k); }).join(', ');
            const more = (int.triggerKeywords || []).length > 5 ? '...' : '';
            const hasImage = int.sendImage ? ' 📸' : '';
            
            html += '<div style="padding: 8px; margin-bottom: 6px; background: white; border-radius: 4px; border-left: 3px solid #1976d2; font-size: 0.85rem;">';
            html += '<strong style="color: #1976d2;">' + (idx + 1) + '. ' + name + '</strong>' + hasImage;
            html += '<div style="color: #666; margin-top: 4px; font-size: 0.8rem;">Palabras clave: ' + keywords + more + '</div>';
            html += '</div>';
        });
        
        html += '</div></div>';
        
        // Guardar las integraciones en un atributo data para poder accederlas después
        html += '<div id="integrations-data-' + hotelId + '" data-integrations=\'' + JSON.stringify(integrations).replace(/'/g, '&#039;') + '\' style="display: none;"></div>';
        
        return html;
        
    } catch (error) {
        console.error('[CRM] Error al renderizar integraciones:', error);
        return '<p style="color: #d32f2f; padding: 12px; background: #ffebee; border-radius: 8px;">Error al cargar las integraciones. Por favor, recarga la página.</p>';
    }
}

function loadSelectedIntegration(hotelId, integrationId) {
    if (!integrationId) {
        const container = document.getElementById('selected-integration-' + hotelId);
        if (container) {
            container.style.display = 'none';
        }
        return;
    }
    
    // Obtener las integraciones guardadas
    const dataDiv = document.getElementById('integrations-data-' + hotelId);
    if (!dataDiv) return;
    
    let integrations = [];
    try {
        const dataAttr = dataDiv.getAttribute('data-integrations');
        if (dataAttr) {
            integrations = JSON.parse(dataAttr.replace(/&#039;/g, "'"));
        }
    } catch (e) {
        console.error('[CRM] Error al parsear integraciones:', e);
        return;
    }
    
    const integration = integrations.find(function(i) { return (i.id || '') === integrationId; });
    if (!integration) return;
    
    // Función auxiliar para escapar HTML
    const escapeHtml = (text) => {
        if (!text) return '';
        return String(text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    };
    
    const keywords = integration.triggerKeywords ? integration.triggerKeywords.join(', ') : '';
    const intName = escapeHtml(integration.name || 'Integración sin nombre');
    const intDesc = escapeHtml(integration.description || '');
    const intApi = escapeHtml(integration.apiEndpoint || '');
    const intContent = escapeHtml(integration.content || '');
    
    const container = document.getElementById('selected-integration-' + hotelId);
    if (!container) return;
    
    let html = '<div class="integration-item" style="border: 2px solid #1976d2; padding: 16px; border-radius: 8px; background: #f0f7ff; margin-bottom: 16px;">';
    
    // Header con nombre y botón eliminar
    html += '<div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 16px;">';
    html += '<div style="flex: 1;">';
    html += '<h4 style="margin: 0; color: #1976d2; font-size: 1.1rem; display: flex; align-items: center; gap: 8px;">';
    html += '✏️ Editando: ' + intName;
    html += '</h4>';
    if (integration.sendImage) {
        html += '<span style="background: #4caf50; color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.75rem; margin-left: 8px;">📸 Con imagen</span>';
    }
    html += '</div>';
    html += '<button class="btn" onclick="removeHotelIntegration(\'' + hotelId + '\', \'' + integrationId + '\')" ';
    html += 'style="background: #dc3545; color: white; padding: 8px 16px; font-size: 0.9rem; border-radius: 6px; cursor: pointer;" ';
    html += 'title="Eliminar esta integración">';
    html += '<span class="material-icons" style="font-size: 18px; vertical-align: middle;">delete</span> Eliminar';
    html += '</button>';
    html += '</div>';
    
    // Campos de edición
    html += '<div class="form-group" style="margin-bottom: 12px;">';
    html += '<label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9rem;">Nombre de la Integración:</label>';
    html += '<input type="text" class="form-input integration-name-' + hotelId + '-' + integrationId + '" ';
    html += 'placeholder="Ej: Disponibilidad en tiempo real, Menús del restaurante..." ';
    html += 'value="' + intName + '" ';
    html += 'style="border: 2px solid #1976d2; width: 100%; padding: 8px;">';
    html += '</div>';
    
    html += '<div class="form-group" style="margin-bottom: 12px;">';
    html += '<label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9rem;">Palabras Clave para Activar (separadas por comas):</label>';
    html += '<input type="text" class="form-input integration-keywords-' + hotelId + '-' + integrationId + '" ';
    html += 'placeholder="Ej: disponibilidad, habitaciones libres, menú, carta..." ';
    html += 'value="' + escapeHtml(keywords) + '" ';
    html += 'style="border: 2px solid #1976d2; width: 100%; padding: 8px;">';
    html += '<p style="color: #666; font-size: 0.8rem; margin-top: 4px;">Cuando el usuario mencione alguna de estas palabras, esta integración se activará.</p>';
    html += '</div>';
    
    html += '<div class="form-group" style="margin-bottom: 12px;">';
    html += '<label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9rem;">Descripción:</label>';
    html += '<textarea class="form-textarea integration-desc-' + hotelId + '-' + integrationId + '" rows="2" ';
    html += 'placeholder="Describe brevemente qué información proporciona esta integración">' + intDesc + '</textarea>';
    html += '</div>';
    
    html += '<div class="form-group" style="margin-bottom: 12px;">';
    html += '<label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9rem;">Contenido de la Integración:</label>';
    html += '<textarea class="form-textarea integration-content-' + hotelId + '-' + integrationId + '" rows="4" ';
    html += 'placeholder="Información detallada que se enviará cuando se active esta integración.">' + intContent + '</textarea>';
    html += '<p style="color: #666; font-size: 0.8rem; margin-top: 4px;">Esta información se agregará al contexto de Flor cuando la integración se active.</p>';
    html += '</div>';
    
    html += '<div class="form-group" style="margin-bottom: 12px;">';
    html += '<label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9rem;">Endpoint de API (opcional):</label>';
    html += '<input type="text" class="form-input integration-api-' + hotelId + '-' + integrationId + '" ';
    html += 'placeholder="Ej: https://api.ejemplo.com/disponibilidad" ';
    html += 'value="' + intApi + '">';
    html += '<p style="color: #666; font-size: 0.8rem; margin-top: 4px;">Si esta integración requiere consultar una API externa, especifica la URL aquí.</p>';
    html += '</div>';
    
    html += '<div class="form-group" style="margin-bottom: 12px; border-top: 1px solid #ddd; padding-top: 12px;">';
    html += '<label style="display: flex; align-items: center; gap: 8px; font-weight: bold; margin-bottom: 8px; font-size: 0.9rem;">';
    html += '<input type="checkbox" class="integration-send-image-' + hotelId + '-' + integrationId + '" ';
    if (integration.sendImage) html += 'checked ';
    html += 'onchange="toggleImageOptions(\'' + hotelId + '\', \'' + integrationId + '\')" ';
    html += 'style="width: 18px; height: 18px; cursor: pointer;">';
    html += '📸 Enviar imagen con esta integración';
    html += '</label>';
    html += '<div id="image-options-' + hotelId + '-' + integrationId + '" style="margin-left: 26px; ' + (integration.sendImage ? '' : 'display: none;') + '">';
    html += '<label style="display: block; font-weight: normal; margin-bottom: 4px; font-size: 0.85rem; margin-top: 8px;">Tipo de imagen:</label>';
    html += '<select class="form-input integration-image-type-' + hotelId + '-' + integrationId + '" style="width: 100%; padding: 6px; font-size: 0.9rem; margin-bottom: 8px;">';
    html += '<option value="main"' + (integration.imageType === 'main' ? ' selected' : '') + '>Imagen principal del hotel</option>';
    html += '<option value="gallery-1"' + (integration.imageType === 'gallery-1' ? ' selected' : '') + '>Galería 1</option>';
    html += '<option value="gallery-2"' + (integration.imageType === 'gallery-2' ? ' selected' : '') + '>Galería 2</option>';
    html += '<option value="gallery-3"' + (integration.imageType === 'gallery-3' ? ' selected' : '') + '>Galería 3</option>';
    html += '</select>';
    html += '<p style="color: #666; font-size: 0.75rem; margin-top: 4px;">Cuando esta integración se active, Flor enviará automáticamente la imagen seleccionada junto con la respuesta.</p>';
    html += '</div>';
    html += '</div>';
    
    html += '<input type="hidden" class="integration-id-' + hotelId + '-' + integrationId + '" value="' + escapeHtml(integrationId) + '">';
    html += '</div>';
    
    container.innerHTML = html;
    container.style.display = 'block';
}

function removeHotelIntegration(hotelId, integrationId) {
    if (!confirm('¿Estás seguro de que deseas eliminar esta integración?')) {
        return;
    }
    
    // Eliminar de la base de conocimiento
    if (typeof FlorKnowledgeBase !== 'undefined' && FlorKnowledgeBase.deleteHotelIntegration) {
        const deleted = FlorKnowledgeBase.deleteHotelIntegration(hotelId, integrationId);
        if (deleted) {
            // Recargar la visualización
            const hotelKnowledge = FlorKnowledgeBase.getHotelKnowledge(hotelId);
            const container = document.getElementById('hotel-integrations-' + hotelId);
            if (container) {
                container.innerHTML = renderHotelIntegrations(hotelId, hotelKnowledge.specificIntegrations || []);
            }
            alert('✅ Integración eliminada correctamente');
        } else {
            alert('❌ Error al eliminar la integración');
        }
    } else {
        alert('❌ Error: No se pudo acceder a la base de conocimiento');
    }
}

function addHotelIntegration(hotelId) {
    // Obtener las integraciones actuales
    const hotelKnowledge = FlorKnowledgeBase.getHotelKnowledge(hotelId) || {};
    const currentIntegrations = hotelKnowledge.specificIntegrations || [];
    
    // Crear nueva integración
    const newIntegration = {
        id: 'integration_' + hotelId + '_' + Date.now(),
        name: 'Nueva Integración',
        triggerKeywords: [],
        description: '',
        content: '',
        apiEndpoint: '',
        sendImage: false,
        imageType: 'main'
    };
    
    // Agregar a la lista
    currentIntegrations.push(newIntegration);
    hotelKnowledge.specificIntegrations = currentIntegrations;
    FlorKnowledgeBase.saveHotelKnowledge(hotelId, hotelKnowledge);
    
    // Recargar la visualización
    const container = document.getElementById('hotel-integrations-' + hotelId);
    if (container) {
        container.innerHTML = renderHotelIntegrations(hotelId, currentIntegrations);
        // Seleccionar automáticamente la nueva integración
        const selector = document.getElementById('integration-selector-' + hotelId);
        if (selector) {
            selector.value = newIntegration.id;
            loadSelectedIntegration(hotelId, newIntegration.id);
        }
    }
}

function removeHotelIntegration(hotelId, integrationId) {
    const integrationItem = event.target.closest('.integration-item');
    if (integrationItem) {
        integrationItem.remove();
    }
}

function toggleImageOptions(hotelId, integrationId) {
    const checkbox = document.querySelector(`.integration-send-image-${hotelId}-${integrationId}`);
    const optionsDiv = document.getElementById(`image-options-${hotelId}-${integrationId}`);
    
    if (checkbox && optionsDiv) {
        optionsDiv.style.display = checkbox.checked ? 'block' : 'none';
    }
}

function saveHotelKnowledge(hotelId) {
    try {
        // Asegurar que hotelId sea string para los selectores
        hotelId = String(hotelId);
        
        console.log('[CRM] 💾 Iniciando guardado de información del hotel:', hotelId);
        console.log('[CRM] 🔍 Tipo de hotelId:', typeof hotelId);
        
        // Verificar que FlorKnowledgeBase esté disponible
        if (typeof FlorKnowledgeBase === 'undefined') {
            console.error('[CRM] ❌ Error: FlorKnowledgeBase no está disponible');
            alert('Error: No se pudo cargar la base de conocimiento. Por favor, recarga la página.');
            return;
        }
        
        // Verificar que hotelId sea válido
        if (!hotelId || hotelId === 'undefined' || hotelId === 'null') {
            console.error('[CRM] ❌ Error: hotelId no válido:', hotelId);
            alert('Error: ID de hotel no válido');
            return;
        }
        
        // Obtener todos los datos del formulario
        const descElement = document.querySelector(`.hotel-desc-${hotelId}`);
        const addressElement = document.querySelector(`.hotel-address-${hotelId}`);
        const roomsElement = document.querySelector(`.hotel-rooms-${hotelId}`);
        const policiesElement = document.querySelector(`.hotel-policies-${hotelId}`);
        const additionalElement = document.querySelector(`.hotel-additional-${hotelId}`);
        
        console.log('[CRM] 🔍 Elementos encontrados:', {
            desc: !!descElement,
            address: !!addressElement,
            rooms: !!roomsElement,
            policies: !!policiesElement,
            additional: !!additionalElement
        });
        
        if (!descElement) {
            console.error('[CRM] ❌ Error: No se encontró el formulario del hotel con ID:', hotelId);
            alert('Error: No se encontró el formulario del hotel. Por favor, recarga la página.');
            return;
        }
        
        const description = descElement.value || '';
        const address = addressElement ? (addressElement.value || '') : '';
        const roomsText = roomsElement ? (roomsElement.value || '') : '';
        const policiesText = policiesElement ? (policiesElement.value || '') : '';
        const additionalText = additionalElement ? (additionalElement.value || '') : '';
        
        console.log('[CRM] 📝 Datos recolectados:', {
            description: description.substring(0, 50) + '...',
            address,
            roomsCount: roomsText.split('\n').filter(r => r.trim()).length,
            policiesLength: policiesText.length,
            additionalLength: additionalText.length
        });
        
        // Recolectar servicios
        const servicesContainer = document.getElementById(`hotel-services-${hotelId}`);
        const serviceItems = servicesContainer ? servicesContainer.querySelectorAll('.service-item') : [];
        const servicesDetails = {};
        
        console.log('[CRM] 🔧 Servicios encontrados:', serviceItems.length);
        
        serviceItems.forEach((item, index) => {
            // Buscar inputs dentro del item usando múltiples estrategias
            const nameInput = item.querySelector(`input[id^="service-name-${hotelId}-"]`) || 
                             item.querySelector('input[type="text"]') ||
                             item.querySelector('input[placeholder*="nombre"]');
            const descInput = item.querySelector(`textarea[id^="service-desc-${hotelId}-"]`) || 
                             item.querySelector('textarea');
            const includedCheckbox = item.querySelector(`input[id^="service-included-${hotelId}-"]`) || 
                                   item.querySelector('input[type="checkbox"]');
            const costInput = item.querySelector(`input[id^="service-cost-${hotelId}-"]`) || 
                             item.querySelector('input[type="number"]');
            
            if (nameInput && nameInput.value && nameInput.value.trim()) {
                const serviceKey = nameInput.value.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
                servicesDetails[serviceKey] = {
                    name: nameInput.value.trim(),
                    description: descInput ? (descInput.value || '').trim() : '',
                    included: includedCheckbox ? includedCheckbox.checked : false,
                    cost: costInput && includedCheckbox && !includedCheckbox.checked ? (parseFloat(costInput.value) || 0) : 0
                };
                console.log('[CRM] ✅ Servicio agregado:', serviceKey);
            }
        });
        
        // Procesar tipos de habitaciones
        const roomTypes = roomsText.split('\n').filter(r => r.trim()).map(r => r.trim());
        
        // Procesar políticas (intentar parsear como JSON o usar como texto)
        let policies = {};
        try {
            if (policiesText.trim()) {
                policies = JSON.parse(policiesText);
            }
        } catch (e) {
            policies = { custom: policiesText };
        }
        
        // Procesar información adicional (intentar parsear como JSON o usar como texto)
        let additionalInfo = {};
        try {
            if (additionalText.trim()) {
                additionalInfo = JSON.parse(additionalText);
            }
        } catch (e) {
            additionalInfo = { notes: additionalText };
        }
        
        // Recolectar integraciones específicas
        const specificIntegrations = [];
        
        // Obtener la integración seleccionada del contenedor de edición
        const selectedIntegrationContainer = document.getElementById('selected-integration-' + hotelId);
        if (selectedIntegrationContainer && selectedIntegrationContainer.style.display !== 'none') {
            const integrationItem = selectedIntegrationContainer.querySelector('.integration-item');
            if (integrationItem) {
                // Buscar el input hidden con el ID de la integración
                let idInput = integrationItem.querySelector('input[class*="integration-id"]');
                if (!idInput) {
                    const hiddenInputs = integrationItem.querySelectorAll('input[type="hidden"]');
                    idInput = Array.from(hiddenInputs).find(function(input) {
                        return input.className && input.className.includes('integration-id');
                    });
                }
                
                if (idInput) {
                    const integrationId = idInput.value;
                    console.log('[CRM] 📝 Procesando integración seleccionada:', integrationId);
                    
                    // Buscar todos los inputs
                    const nameInput = integrationItem.querySelector('input[class*="integration-name"]');
                    const keywordsInput = integrationItem.querySelector('input[class*="integration-keywords"]');
                    const descInput = integrationItem.querySelector('textarea[class*="integration-desc"]');
                    const contentInput = integrationItem.querySelector('textarea[class*="integration-content"]');
                    const apiInput = integrationItem.querySelector('input[class*="integration-api"]');
                    const sendImageCheckbox = integrationItem.querySelector('input[class*="integration-send-image"]');
                    const imageTypeSelect = integrationItem.querySelector('select[class*="integration-image-type"]');
                    
                    if (nameInput && keywordsInput) {
                        const name = nameInput.value.trim();
                        const keywordsStr = keywordsInput.value.trim();
                        
                        if (name && keywordsStr) {
                            const keywords = keywordsStr.split(',').map(function(k) { return k.trim(); }).filter(function(k) { return k.length > 0; });
                            
                            const integration = {
                                id: integrationId,
                                name: name,
                                triggerKeywords: keywords,
                                description: descInput ? descInput.value.trim() : '',
                                content: contentInput ? contentInput.value.trim() : '',
                                apiEndpoint: apiInput ? apiInput.value.trim() : '',
                                sendImage: sendImageCheckbox ? sendImageCheckbox.checked : false,
                                imageType: (sendImageCheckbox && sendImageCheckbox.checked && imageTypeSelect) ? imageTypeSelect.value : 'main'
                            };
                            
                            console.log('[CRM] ✅ Integración recolectada:', integration.name, 'con', integration.triggerKeywords.length, 'palabras clave');
                            specificIntegrations.push(integration);
                        }
                    }
                }
            }
        }
        
        // También obtener todas las integraciones existentes (para mantener las que no están siendo editadas)
        const existingHotelKnowledge = FlorKnowledgeBase.getHotelKnowledge(hotelId) || {};
        const existingIntegrations = existingHotelKnowledge.specificIntegrations || [];
        const selector = document.getElementById('integration-selector-' + hotelId);
        const selectedId = selector ? selector.value : null;
        
        // Agregar las integraciones existentes que no están siendo editadas
        existingIntegrations.forEach(function(existingIntegration) {
            if (existingIntegration.id !== selectedId) {
                // Verificar que no esté ya en la lista
                const alreadyAdded = specificIntegrations.find(function(int) {
                    return int.id === existingIntegration.id;
                });
                if (!alreadyAdded) {
                    specificIntegrations.push(existingIntegration);
                }
            }
        });
        
        console.log('[CRM] 📦 Total de integraciones recolectadas:', specificIntegrations.length);
        
        // Mensaje estándar para precios dinámicos
        const dynamicPriceMessage = "Las tarifas son dinámicas y varían según fecha, pueden variar en alta temporada o en baja temporada. Para una cotización precisa solicítela con: Fecha de Check-in, cantidad de noches y cantidad de personas. Las tarifas enviadas tienen validez de 24 horas.";
        
        // Crear objeto de conocimiento
        const hotelKnowledge = {
            hotelId: hotelId,
            description: description.trim(),
            address: address.trim(),
            priceInfo: {
                dynamic: true,
                message: dynamicPriceMessage,
                requiresQuote: true
            },
            servicesDetails: servicesDetails,
            roomTypes: roomTypes,
            policies: policies,
            additionalInfo: additionalInfo,
            specificIntegrations: specificIntegrations,
            lastUpdated: new Date().toISOString()
        };
        
        console.log('[CRM] 📦 Objeto de conocimiento creado:', hotelKnowledge);
        
        // Guardar usando la función de la base de conocimiento
        try {
            FlorKnowledgeBase.saveHotelKnowledge(hotelId, hotelKnowledge);
            console.log('[CRM] ✅ Información guardada en localStorage');
            
            // Verificar que se guardó correctamente
            const saved = FlorKnowledgeBase.getHotelKnowledge(hotelId);
            if (saved) {
                console.log('[CRM] ✅ Verificación: información guardada correctamente');
            } else {
                console.warn('[CRM] ⚠️ Advertencia: no se pudo verificar el guardado');
            }
        } catch (error) {
            console.error('[CRM] ❌ Error al guardar:', error);
            alert('Error al guardar la información: ' + error.message);
            return;
        }
        
        // Recargar la tarjeta del hotel para mostrar el estado actualizado
        if (typeof loadSelectedHotelKnowledge === 'function') {
            loadSelectedHotelKnowledge();
        } else if (typeof loadServicesList === 'function') {
            loadServicesList();
        }
        
        // Obtener nombre del hotel para el mensaje
        const hotelCard = descElement.closest('.hotel-knowledge-card');
        const hotelName = hotelCard ? hotelCard.querySelector('h3')?.textContent.replace('🏨 ', '') || 'Hotel' : 'Hotel';
        
        console.log('[CRM] ✅ Guardado completado exitosamente para:', hotelName);
        alert(`✅ Información de ${hotelName} guardada correctamente. Flor ahora puede responder sobre este hotel de forma autónoma.`);
        
    } catch (error) {
        console.error('[CRM] ❌ Error general en saveHotelKnowledge:', error);
        alert('Error inesperado al guardar: ' + error.message);
    }
}

// ===== SISTEMA DE APRENDIZAJE =====
function loadLearningData() {
    if (typeof FlorLearningSystem === 'undefined') {
        console.error('[CRM] Sistema de aprendizaje no disponible');
        const errorMsg = '<div style="padding: 16px; background: #ffebee; border-left: 4px solid #d32f2f; border-radius: 4px; color: #c62828;">';
        errorMsg += '<strong>❌ Error:</strong> El sistema de aprendizaje no está disponible. Verifica que el archivo flor-learning-system.js esté cargado correctamente.';
        errorMsg += '</div>';
        document.getElementById('learning-stats-grid').innerHTML = errorMsg;
        return;
    }

    console.log('[CRM] Cargando datos de aprendizaje...');
    console.log('[CRM] Sistema habilitado:', FlorLearningSystem.config.enabled);

    // Obtener todas las interacciones para verificar
    const allInteractions = FlorLearningSystem.getInteractions();
    console.log('[CRM] Total de interacciones encontradas:', allInteractions.length);

    // Cargar estadísticas
    const stats = FlorLearningSystem.getStatistics();
    console.log('[CRM] Estadísticas:', stats);
    
    if (stats && stats.totalInteractions > 0) {
        document.getElementById('learning-total-interactions').textContent = stats.totalInteractions || 0;
        document.getElementById('learning-success-rate').textContent = 
            (stats.successRate * 100).toFixed(1) + '%';
        
        // Obtener patrones de las estadísticas de aprendizaje
        const learningStats = JSON.parse(localStorage.getItem('flor_learning_stats') || '{}');
        document.getElementById('learning-patterns').textContent = learningStats.totalPatterns || 0;
        
        const lastUpdate = stats.lastInteraction 
            ? new Date(stats.lastInteraction).toLocaleString('es-ES')
            : 'Nunca';
        document.getElementById('learning-last-update').textContent = lastUpdate;
    } else {
        // Si no hay estadísticas, calcular desde las interacciones
        const totalInteractions = allInteractions.length;
        const successful = allInteractions.filter(inter => inter.success !== false).length;
        const successRate = totalInteractions > 0 ? (successful / totalInteractions) : 0;
        
        document.getElementById('learning-total-interactions').textContent = totalInteractions;
        document.getElementById('learning-success-rate').textContent = (successRate * 100).toFixed(1) + '%';
        document.getElementById('learning-patterns').textContent = '0';
        
        const lastInteraction = allInteractions.length > 0 
            ? allInteractions[allInteractions.length - 1].timestamp 
            : null;
        const lastUpdate = lastInteraction 
            ? new Date(lastInteraction).toLocaleString('es-ES')
            : 'Nunca';
        document.getElementById('learning-last-update').textContent = lastUpdate;
        
        // Crear estadísticas básicas si no existen
        if (totalInteractions > 0 && !stats) {
            const basicStats = {
                totalInteractions: totalInteractions,
                interactionsByIntent: {},
                interactionsByHotel: {},
                successRate: successRate,
                lastInteraction: lastInteraction
            };
            
            allInteractions.forEach(inter => {
                if (inter.intent) {
                    basicStats.interactionsByIntent[inter.intent] = 
                        (basicStats.interactionsByIntent[inter.intent] || 0) + 1;
                }
                if (inter.hotelId) {
                    basicStats.interactionsByHotel[inter.hotelId] = 
                        (basicStats.interactionsByHotel[inter.hotelId] || 0) + 1;
                }
            });
            
            localStorage.setItem('flor_learning_statistics', JSON.stringify(basicStats));
        }
    }

    // Cargar gráfico de intenciones
    loadLearningIntentsChart(stats || (allInteractions.length > 0 ? {
        totalInteractions: allInteractions.length,
        interactionsByIntent: {}
    } : null));

    // Cargar recomendaciones
    loadLearningRecommendations();

    // Cargar configuración
    loadLearningConfig();
}

function loadLearningIntentsChart(stats) {
    const container = document.getElementById('learning-intents-chart');
    
    if (!stats || !stats.interactionsByIntent || Object.keys(stats.interactionsByIntent).length === 0) {
        container.innerHTML = '<p style="color: #666; text-align: center;">No hay datos suficientes aún. Flor necesita más interacciones para generar estadísticas.</p>';
        return;
    }

    const intents = Object.entries(stats.interactionsByIntent)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10);

    let html = '<div style="display: flex; flex-direction: column; gap: 12px;">';
    
    intents.forEach(([intent, count]) => {
        const percentage = stats.totalInteractions > 0 
            ? (count / stats.totalInteractions * 100).toFixed(1)
            : 0;
        
        html += '<div style="padding: 12px; background: #f5f5f5; border-radius: 8px;">';
        html += '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">';
        html += '<span style="font-weight: 500; text-transform: capitalize;">' + intent.replace(/_/g, ' ') + '</span>';
        html += '<span style="color: #1976d2; font-weight: bold;">' + count + ' interacciones</span>';
        html += '</div>';
        html += '<div style="background: #e0e0e0; border-radius: 4px; height: 8px; overflow: hidden;">';
        html += '<div style="background: linear-gradient(90deg, #1976d2, #42a5f5); height: 100%; width: ' + percentage + '%; transition: width 0.3s;"></div>';
        html += '</div>';
        html += '<div style="font-size: 0.85rem; color: #666; margin-top: 4px;">' + percentage + '% del total</div>';
        html += '</div>';
    });
    
    html += '</div>';
    container.innerHTML = html;
}

function loadLearningRecommendations() {
    const container = document.getElementById('learning-recommendations');
    
    if (typeof FlorLearningSystem === 'undefined') {
        container.innerHTML = '<p style="color: #666; text-align: center;">Sistema de aprendizaje no disponible</p>';
        return;
    }

    const recommendations = FlorLearningSystem.getImprovementRecommendations();
    
    if (recommendations.length === 0) {
        container.innerHTML = '<div style="padding: 16px; background: #e8f5e9; border-left: 4px solid #4caf50; border-radius: 4px;">';
        container.innerHTML += '<strong style="color: #2e7d32;">✅ Todo está bien</strong>';
        container.innerHTML += '<p style="color: #666; margin-top: 8px; margin: 0;">No hay recomendaciones de mejora en este momento. Flor está funcionando correctamente.</p>';
        container.innerHTML += '</div>';
        return;
    }

    let html = '<div style="display: flex; flex-direction: column; gap: 12px;">';
    
    recommendations.forEach((rec, index) => {
        const icon = rec.type === 'low_success_rate' ? '⚠️' : rec.type === 'long_responses' ? '📏' : '📝';
        const color = rec.type === 'low_success_rate' ? '#f57c00' : '#1976d2';
        
        html += '<div style="padding: 16px; background: #fff3e0; border-left: 4px solid ' + color + '; border-radius: 4px;">';
        html += '<div style="display: flex; align-items: start; gap: 12px;">';
        html += '<span style="font-size: 1.5rem;">' + icon + '</span>';
        html += '<div style="flex: 1;">';
        html += '<strong style="color: ' + color + '; display: block; margin-bottom: 4px;">Recomendación ' + (index + 1) + '</strong>';
        html += '<p style="color: #666; margin: 0; line-height: 1.5;">' + rec.recommendation + '</p>';
        if (rec.intent) {
            html += '<p style="color: #666; margin-top: 8px; margin-bottom: 0; font-size: 0.9rem;"><strong>Intención:</strong> ' + rec.intent + ' | <strong>Tasa de éxito:</strong> ' + rec.successRate + '</p>';
        }
        html += '</div>';
        html += '</div>';
        html += '</div>';
    });
    
    html += '</div>';
    container.innerHTML = html;
}

function loadLearningConfig() {
    if (typeof FlorLearningSystem === 'undefined') return;

    const config = FlorLearningSystem.config;
    
    document.getElementById('learning-enabled').checked = config.enabled;
    document.getElementById('learning-min-interactions').value = config.minInteractionsForLearning || 3;
    document.getElementById('learning-threshold').value = config.learningThreshold || 0.7;
    document.getElementById('learning-auto-update').checked = config.autoUpdateKnowledge !== false;
}

function toggleLearningSystem() {
    if (typeof FlorLearningSystem === 'undefined') return;

    const enabled = document.getElementById('learning-enabled').checked;
    FlorLearningSystem.config.enabled = enabled;
    FlorLearningSystem.saveConfig();
    
    console.log('[CRM] Sistema de aprendizaje ' + (enabled ? 'activado' : 'desactivado'));
}

function updateLearningConfig() {
    if (typeof FlorLearningSystem === 'undefined') return;

    FlorLearningSystem.config.minInteractionsForLearning = 
        parseInt(document.getElementById('learning-min-interactions').value) || 3;
    FlorLearningSystem.config.learningThreshold = 
        parseFloat(document.getElementById('learning-threshold').value) || 0.7;
    FlorLearningSystem.config.autoUpdateKnowledge = 
        document.getElementById('learning-auto-update').checked;
    
    FlorLearningSystem.saveConfig();
    console.log('[CRM] Configuración de aprendizaje actualizada');
}

function cleanupLearningData() {
    if (typeof FlorLearningSystem === 'undefined') return;
    
    if (confirm('¿Estás seguro de que deseas eliminar las interacciones de más de 30 días? Esta acción no se puede deshacer.')) {
        FlorLearningSystem.cleanupOldData(30);
        alert('✅ Datos antiguos eliminados correctamente');
        loadLearningData(); // Recargar datos
    }
}

function loadIntentsList() {
    const intents = FlorKnowledgeBase.intents || {};
    const container = document.getElementById('intents-list');
    
    container.innerHTML = Object.keys(intents).map(intentKey => {
        const keywords = intents[intentKey] || [];
        return `
            <div class="form-group" style="border: 1px solid #ddd; padding: 16px; border-radius: 8px; margin-bottom: 16px;">
                <label class="form-label">${intentKey.replace(/_/g, ' ').toUpperCase()}</label>
                <input type="text" class="form-input" id="intent-${intentKey}" 
                       value="${keywords.join(', ')}" 
                       placeholder="Palabras clave separadas por comas">
            </div>
        `;
    }).join('');
}

function saveFlorIntents() {
    if (!FlorKnowledgeBase) return;
    
    const intents = FlorKnowledgeBase.intents || {};
    Object.keys(intents).forEach(intentKey => {
        const input = document.getElementById('intent-' + intentKey);
        if (input) {
            intents[intentKey] = input.value.split(',').map(s => s.trim()).filter(s => s);
        }
    });
    
    localStorage.setItem('flor_config_intents', JSON.stringify(intents));
    alert('✅ Palabras clave guardadas correctamente');
}

function saveFlorEscalation() {
    const escalation = {
        reservar: document.getElementById('escalate-reservar').checked,
        humano: document.getElementById('escalate-humano').checked,
        problema: document.getElementById('escalate-problema').checked,
        no_entendido: document.getElementById('escalate-no-entendido').checked
    };
    
    localStorage.setItem('flor_config_escalation', JSON.stringify(escalation));
    alert('✅ Reglas de escalación guardadas correctamente');
}

function loadFlorAnalytics() {
    const interactions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
    const total = interactions.length;
    const resolved = interactions.filter(i => i.resolved && !i.escalated).length;
    const escalated = interactions.filter(i => i.escalated).length;
    const satisfaction = total > 0 ? Math.round((resolved / total) * 100) : 0;
    
    document.getElementById('flor-total-conversations').textContent = total;
    document.getElementById('flor-resolved').textContent = resolved;
    document.getElementById('flor-escalated').textContent = escalated;
    document.getElementById('flor-satisfaction').textContent = satisfaction + '%';
}

// ===== UTILIDADES =====
function formatDate(dateString) {
    if (!dateString) return 'N/A';
    try {
        const date = new Date(dateString);
        return date.toLocaleDateString('es-AR');
    } catch {
        return dateString;
    }
}

function formatDateTime(dateString) {
    if (!dateString) return 'N/A';
    try {
        const date = new Date(dateString);
        return date.toLocaleString('es-AR');
    } catch {
        return dateString;
    }
}

function getStatusBadge(status) {
    const badges = {
        'pending': '<span class="badge badge-pending">Pendiente</span>',
        'approved': '<span class="badge badge-approved">Aprobado</span>',
        'confirmed': '<span class="badge badge-approved">Confirmado</span>',
        'cancelled': '<span class="badge badge-cancelled">Cancelado</span>',
        'rejected': '<span class="badge badge-cancelled">Rechazado</span>'
    };
    return badges[status] || `<span class="badge">${status}</span>`;
}

// Funciones placeholder
function openCustomerModal() { alert('Funcionalidad en desarrollo'); }
function openReservationModal() { alert('Funcionalidad en desarrollo'); }
function editCustomer(id) { alert('Funcionalidad en desarrollo'); }
function deleteCustomer(id) { 
    if (confirm('¿Estás seguro de eliminar este cliente?')) {
        // Implementar eliminación
        loadCustomers();
    }
}
function viewReservation(id) { alert('Funcionalidad en desarrollo - Reserva #' + id); }
function viewQuote(id) { 
    // Puede usar la función viewQuote del dashboard si está disponible
    if (typeof viewQuote === 'function') {
        viewQuote(id);
    } else {
        alert('Ver cotización #' + id);
    }
}
function viewInteraction(id) {
    // Verificar si es un ID de sesión
    let session = null;
    let allMessages = [];
    let interaction = null;
    
    // Si el ID comienza con "session_", es una sesión agrupada
    if (id.startsWith('session_')) {
        // Recargar las interacciones y buscar la sesión
        const oldInteractions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
        let learningInteractions = [];
        if (typeof FlorLearningSystem !== 'undefined') {
            learningInteractions = FlorLearningSystem.getInteractions() || [];
        }
        
        const convertedInteractions = learningInteractions.map(inter => ({
            id: inter.id,
            timestamp: inter.timestamp,
            customer_name: 'Usuario',
            message_count: 1,
            escalated: false,
            resolved: inter.success !== false,
            intent: inter.intent || 'consulta_general',
            userMessage: inter.userMessage,
            botResponse: inter.botResponse,
            hotelId: inter.hotelId,
            usedAI: inter.usedAI || false
        }));
        
        const allInteractions = [...oldInteractions, ...convertedInteractions];
        const groupedSessions = groupInteractionsBySession(allInteractions);
        
        session = groupedSessions.find(s => s.id === id);
        
        if (session) {
            allMessages = session.messages || [];
            interaction = {
                id: session.id,
                timestamp: session.timestamp,
                intent: session.intent,
                escalated: session.escalated,
                resolved: session.resolved,
                message_count: session.message_count
            };
        }
    } else {
        // Buscar la interacción individual en el sistema de aprendizaje
        if (typeof FlorLearningSystem !== 'undefined') {
            const learningInteractions = FlorLearningSystem.getInteractions();
            interaction = learningInteractions.find(inter => inter.id === id);
            
            if (interaction) {
                allMessages = [{
                    role: 'user',
                    content: interaction.userMessage,
                    timestamp: interaction.timestamp
                }, {
                    role: 'bot',
                    content: interaction.botResponse,
                    timestamp: interaction.timestamp
                }];
            }
        }
        
        // Si no se encuentra, buscar en el sistema antiguo
        if (!interaction) {
            const oldInteractions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
            interaction = oldInteractions.find(inter => inter.id === id);
            if (interaction && interaction.messages) {
                allMessages = interaction.messages;
            }
        }
    }
    
    if (!interaction && !session) {
        alert('Interacción no encontrada');
        return;
    }
    
    // Crear modal para mostrar la conversación
    const modal = document.createElement('div');
    modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 10000; display: flex; align-items: center; justify-content: center;';
    
    const modalContent = document.createElement('div');
    modalContent.style.cssText = 'background: white; border-radius: 8px; padding: 24px; max-width: 600px; max-height: 80vh; overflow-y: auto; width: 90%;';
    
    let html = '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">';
    html += '<h2 style="margin: 0;">Detalles de la Interacción</h2>';
    html += '<button id="close-interaction-modal" style="background: #dc3545; color: white; border: none; border-radius: 4px; padding: 8px 16px; cursor: pointer;">Cerrar</button>';
    html += '</div>';
    
    const displayData = session || interaction;
    
    html += '<div style="margin-bottom: 16px;">';
    html += '<strong>Fecha:</strong> ' + (displayData.timestamp ? formatDateTime(displayData.timestamp) : 'N/A') + '<br>';
    html += '<strong>Total de mensajes:</strong> ' + (allMessages.length || displayData.message_count || 0) + '<br>';
    html += '<strong>Intención:</strong> ' + (displayData.intent || 'consulta_general') + '<br>';
    html += '<strong>Resuelto por:</strong> ' + (displayData.escalated ? 'Humano' : 'Flor') + '<br>';
    html += '<strong>Estado:</strong> ' + (displayData.resolved !== false ? 'Resuelto' : 'Abierto') + '<br>';
    if (session) {
        html += '<strong>Tipo:</strong> Sesión de conversación (' + (displayData.message_count || allMessages.length) + ' interacciones)<br>';
    }
    html += '</div>';
    
    html += '<div style="border-top: 1px solid #ddd; padding-top: 16px;">';
    html += '<h3 style="margin-bottom: 12px;">Conversación:</h3>';
    
    // Función auxiliar para escapar HTML
    const escapeHtml = (text) => {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    };
    
    if (allMessages.length > 0) {
        allMessages.forEach(msg => {
            const isUser = msg.role === 'user';
            html += '<div style="margin-bottom: 12px; padding: 12px; background: ' + (isUser ? '#e3f2fd' : '#f5f5f5') + '; border-radius: 8px; border-left: 4px solid ' + (isUser ? '#1976d2' : '#666') + ';">';
            html += '<strong style="color: ' + (isUser ? '#1976d2' : '#666') + ';">' + (isUser ? 'Usuario' : 'Flor') + ':</strong><br>';
            html += '<div style="margin-top: 8px; white-space: pre-wrap;">' + escapeHtml(msg.content || '') + '</div>';
            if (msg.timestamp) {
                html += '<div style="font-size: 0.85rem; color: #999; margin-top: 4px;">' + escapeHtml(formatDateTime(msg.timestamp)) + '</div>';
            }
            html += '</div>';
        });
    } else {
        html += '<div style="padding: 12px; background: #f5f5f5; border-radius: 8px;">';
        html += '<strong>Usuario:</strong><br>';
        html += '<div style="margin-top: 8px;">' + escapeHtml(interaction.userMessage || 'N/A') + '</div>';
        html += '</div>';
        html += '<div style="padding: 12px; background: #e3f2fd; border-radius: 8px; margin-top: 12px;">';
        html += '<strong>Flor:</strong><br>';
        html += '<div style="margin-top: 8px;">' + escapeHtml(interaction.botResponse || 'N/A') + '</div>';
        html += '</div>';
    }
    
    html += '</div>';
    
    modalContent.innerHTML = html;
    modal.appendChild(modalContent);
    document.body.appendChild(modal);
    
    // Agregar evento al botón cerrar
    const closeBtn = modalContent.querySelector('#close-interaction-modal');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            modal.remove();
        });
    }
    
    // Cerrar al hacer clic fuera del modal
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.remove();
        }
    });
}

// ===== INTEGRACIÓN WHATSAPP =====

// Variable para almacenar el intervalo de verificación de estado
let whatsappStatusInterval = null;

// Cargar configuración de WhatsApp
function loadWhatsAppConfig() {
    console.log('📱 Cargando configuración de WhatsApp...');
    
    const config = JSON.parse(localStorage.getItem('whatsappConfig') || '{}');
    
    // URL del servidor
    const serverUrl = document.getElementById('whatsapp-server-url');
    if (serverUrl) {
        serverUrl.value = config.serverUrl || 'http://72.61.58.240:3001';
    }
    
    // Respuestas automáticas
    const autoReply = document.getElementById('whatsapp-auto-reply');
    if (autoReply) {
        autoReply.checked = config.autoReply !== false;
    }
    
    // Solo horario laboral
    const businessHours = document.getElementById('whatsapp-business-hours-only');
    if (businessHours) {
        businessHours.checked = config.businessHoursOnly || false;
    }
    
    // Mensaje fuera de horario
    const outOfHoursMsg = document.getElementById('whatsapp-out-of-hours-message');
    if (outOfHoursMsg) {
        outOfHoursMsg.value = config.outOfHoursMessage || 'Gracias por contactarnos. Nuestro horario de atención es de Lunes a Viernes de 9:00 a 18:00. Te responderemos a la brevedad.';
    }
    
    // Cargar estadísticas
    loadWhatsAppStats();
}

// Guardar configuración de WhatsApp
function saveWhatsAppConfig() {
    const config = {
        serverUrl: document.getElementById('whatsapp-server-url')?.value || 'http://72.61.58.240:3001',
        autoReply: document.getElementById('whatsapp-auto-reply')?.checked || false,
        businessHoursOnly: document.getElementById('whatsapp-business-hours-only')?.checked || false,
        outOfHoursMessage: document.getElementById('whatsapp-out-of-hours-message')?.value || ''
    };
    
    localStorage.setItem('whatsappConfig', JSON.stringify(config));
    
    // También enviar configuración al servidor
    sendWhatsAppConfigToServer(config);
    
    console.log('✅ Configuración de WhatsApp guardada');
    alert('Configuración de WhatsApp guardada correctamente');
}

// Enviar configuración al servidor
async function sendWhatsAppConfigToServer(config) {
    try {
        const serverUrl = config.serverUrl || 'http://72.61.58.240:3001';
        
        const response = await fetch(`${serverUrl}/api/config`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                autoReply: config.autoReply,
                businessHoursOnly: config.businessHoursOnly,
                outOfHoursMessage: config.outOfHoursMessage
            })
        });
        
        if (response.ok) {
            console.log('✅ Configuración enviada al servidor de WhatsApp');
        }
    } catch (error) {
        console.error('Error enviando configuración al servidor:', error);
    }
}

// Verificar conexión con WhatsApp
async function checkWhatsAppConnection() {
    console.log('🔄 Verificando conexión con WhatsApp...');
    
    const statusIndicator = document.getElementById('whatsapp-status-indicator');
    const statusText = document.getElementById('whatsapp-status-text');
    const statusDetail = document.getElementById('whatsapp-status-detail');
    const qrSection = document.getElementById('whatsapp-qr-section');
    const infoSection = document.getElementById('whatsapp-info-section');
    
    // Estado inicial: verificando
    if (statusIndicator) statusIndicator.style.background = '#ffc107';
    if (statusText) statusText.textContent = 'Verificando conexión...';
    if (statusDetail) statusDetail.textContent = 'Conectando con el servidor...';
    
    const serverUrl = document.getElementById('whatsapp-server-url')?.value || 'http://72.61.58.240:3001';
    
    try {
        const response = await fetch(`${serverUrl}/api/status`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error('Servidor no responde');
        }
        
        const data = await response.json();
        console.log('📱 Estado de WhatsApp:', data);
        
        if (data.connected) {
            // Conectado
            if (statusIndicator) statusIndicator.style.background = '#4caf50';
            if (statusText) statusText.textContent = '✅ WhatsApp Conectado';
            if (statusDetail) statusDetail.textContent = 'Listo para recibir y enviar mensajes';
            
            if (qrSection) qrSection.style.display = 'none';
            if (infoSection) {
                infoSection.style.display = 'block';
                document.getElementById('whatsapp-phone-number').textContent = data.phoneNumber || '-';
                document.getElementById('whatsapp-user-name').textContent = data.userName || '-';
                document.getElementById('whatsapp-last-activity').textContent = data.lastActivity || 'Ahora';
            }
            
            // Detener verificación periódica de QR
            if (whatsappStatusInterval) {
                clearInterval(whatsappStatusInterval);
                whatsappStatusInterval = null;
            }
        } else if (data.qrCode) {
            // Necesita escanear QR
            if (statusIndicator) statusIndicator.style.background = '#ff9800';
            if (statusText) statusText.textContent = '📲 Escanea el código QR';
            if (statusDetail) statusDetail.textContent = 'Abre WhatsApp en tu teléfono para vincular';
            
            if (infoSection) infoSection.style.display = 'none';
            if (qrSection) {
                qrSection.style.display = 'block';
                document.getElementById('whatsapp-qr-code').innerHTML = `<img src="${data.qrCode}" alt="QR Code" style="max-width: 300px;">`;
            }
            
            // Verificar periódicamente hasta que se conecte
            if (!whatsappStatusInterval) {
                whatsappStatusInterval = setInterval(checkWhatsAppConnection, 5000);
            }
        } else {
            // Desconectado, esperando QR
            if (statusIndicator) statusIndicator.style.background = '#ff9800';
            if (statusText) statusText.textContent = '⏳ Esperando código QR...';
            if (statusDetail) statusDetail.textContent = 'El servidor está generando el código QR';
            
            if (infoSection) infoSection.style.display = 'none';
            if (qrSection) qrSection.style.display = 'none';
            
            // Verificar periódicamente
            if (!whatsappStatusInterval) {
                whatsappStatusInterval = setInterval(checkWhatsAppConnection, 3000);
            }
        }
        
    } catch (error) {
        console.error('❌ Error conectando con servidor WhatsApp:', error);
        
        if (statusIndicator) statusIndicator.style.background = '#f44336';
        if (statusText) statusText.textContent = '❌ Error de conexión';
        if (statusDetail) statusDetail.textContent = 'No se puede conectar con el servidor. Verifica la URL y que el servidor esté corriendo.';
        
        if (qrSection) qrSection.style.display = 'none';
        if (infoSection) infoSection.style.display = 'none';
        
        // Detener verificación periódica
        if (whatsappStatusInterval) {
            clearInterval(whatsappStatusInterval);
            whatsappStatusInterval = null;
        }
    }
}

// Desconectar WhatsApp
async function disconnectWhatsApp() {
    if (!confirm('¿Estás seguro de desconectar WhatsApp? Tendrás que escanear el código QR nuevamente.')) {
        return;
    }
    
    const serverUrl = document.getElementById('whatsapp-server-url')?.value || 'http://72.61.58.240:3001';
    
    try {
        const response = await fetch(`${serverUrl}/api/logout`, {
            method: 'POST'
        });
        
        if (response.ok) {
            alert('WhatsApp desconectado correctamente');
            checkWhatsAppConnection();
        } else {
            alert('Error al desconectar WhatsApp');
        }
    } catch (error) {
        console.error('Error desconectando WhatsApp:', error);
        alert('Error al desconectar WhatsApp: ' + error.message);
    }
}

// Cargar estadísticas de WhatsApp
async function loadWhatsAppStats() {
    const serverUrl = document.getElementById('whatsapp-server-url')?.value || 'http://72.61.58.240:3001';
    
    try {
        const response = await fetch(`${serverUrl}/api/stats`);
        
        if (response.ok) {
            const stats = await response.json();
            
            document.getElementById('whatsapp-total-messages').textContent = stats.totalMessages || 0;
            document.getElementById('whatsapp-auto-replies').textContent = stats.autoReplies || 0;
            document.getElementById('whatsapp-unique-contacts').textContent = stats.uniqueContacts || 0;
            document.getElementById('whatsapp-avg-response').textContent = stats.avgResponseTime || '-';
        }
    } catch (error) {
        console.log('No se pudieron cargar estadísticas de WhatsApp');
    }
}

// Hacer funciones globales
window.loadWhatsAppConfig = loadWhatsAppConfig;
window.saveWhatsAppConfig = saveWhatsAppConfig;
window.checkWhatsAppConnection = checkWhatsAppConnection;
window.disconnectWhatsApp = disconnectWhatsApp;
window.loadWhatsAppStats = loadWhatsAppStats;

