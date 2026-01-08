// Base de datos simulada para Checkin24hs
class Checkin24hsDB {
    constructor() {
        this.users = this.loadUsers();
        this.hotels = this.loadHotels();
        this.quotes = this.loadQuotes();
        this.searchHistory = this.loadSearchHistory();
        this.rewards = this.loadRewards();
        this.sessions = [];
    }

    // ===== USUARIOS =====
    loadUsers() {
        const stored = localStorage.getItem('checkin24hs_users');
        if (stored) {
            return JSON.parse(stored);
        }
        
        // Datos iniciales
        return [
            {
                id: 1,
                name: 'Juan Pérez',
                email: 'juan.perez@email.com',
                password: 'password123', // En producción usar hash
                phone: '+34 612 345 678',
                avatar_url: null,
                rewards_points: 250,
                created_at: '2024-01-15T10:00:00Z',
                is_active: true,
                last_login: null
            },
            {
                id: 2,
                name: 'María García',
                email: 'maria.garcia@email.com',
                password: 'password123',
                phone: '+34 623 456 789',
                avatar_url: null,
                rewards_points: 180,
                created_at: '2024-01-20T14:30:00Z',
                is_active: true,
                last_login: null
            },
            {
                id: 3,
                name: 'Carlos López',
                email: 'carlos.lopez@email.com',
                password: 'password123',
                phone: '+34 634 567 890',
                avatar_url: null,
                rewards_points: 320,
                created_at: '2024-01-25T09:15:00Z',
                is_active: true,
                last_login: null
            }
        ];
    }

    saveUsers() {
        localStorage.setItem('checkin24hs_users', JSON.stringify(this.users));
    }

    // ===== HOTELES =====
    loadHotels() {
        const stored = localStorage.getItem('checkin24hs_hotels');
        if (stored) {
            return JSON.parse(stored);
        }
        
        return [
            {
                id: 1,
                name: 'Hotel Terma de Puyehue',
                description: 'Hotel de lujo en el corazón de las termas de Puyehue con vistas a los volcanes',
                location: 'Puyehue',
                address: 'Ruta 215 Km 76, Puyehue, Chile',
                rating: 4.8,
                image_url: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
                amenities: ['thermal_waters', 'spa', 'restaurant', 'gym', 'volcano_views'],
                is_active: true,
                created_at: '2024-01-01T00:00:00Z'
            },
            {
                id: 2,
                name: 'Hotel Huilo-Huilo',
                description: 'Resort de montaña con acceso directo al bosque nativo y piscina natural',
                location: 'Panguipulli',
                address: 'Camino Internacional Panguipulli, Chile',
                rating: 4.6,
                image_url: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400',
                amenities: ['native_forest', 'natural_pool', 'restaurant', 'bar', 'mountain_activities'],
                is_active: true,
                created_at: '2024-01-01T00:00:00Z'
            },
            {
                id: 3,
                name: 'Hotel Corralco Resort',
                description: 'Hotel boutique con encanto de montaña cerca de las pistas de esquí',
                location: 'Lonquimay',
                address: 'Camino Corralco, Lonquimay, Chile',
                rating: 4.7,
                image_url: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400',
                amenities: ['ski_slopes', 'mountain_views', 'breakfast', 'wifi', 'parking'],
                is_active: true,
                created_at: '2024-01-01T00:00:00Z'
            },
            {
                id: 4,
                name: 'Hotel Futangue',
                description: 'Hotel moderno ideal para viajes de aventura en el corazón de la naturaleza',
                location: 'Lago Ranco',
                address: 'Camino Futangue, Lago Ranco, Chile',
                rating: 4.5,
                image_url: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
                amenities: ['adventure_center', 'gym', 'restaurant', 'wifi', 'parking'],
                is_active: true,
                created_at: '2024-01-01T00:00:00Z'
            },
            {
                id: 5,
                name: 'Termas de Aguas Calientes',
                description: 'Históricas termas ubicadas en un edificio del siglo XIX',
                location: 'San José de Maipo',
                address: 'Camino al Volcán 1234, San José de Maipo, Chile',
                rating: 4.9,
                image_url: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400',
                amenities: ['thermal_waters', 'gourmet_restaurant', 'panoramic_views', 'tour_guide', 'spa'],
                is_active: true,
                created_at: '2024-01-01T00:00:00Z'
            }
        ];
    }

    saveHotels() {
        localStorage.setItem('checkin24hs_hotels', JSON.stringify(this.hotels));
    }

    // ===== COTIZACIONES =====
    loadQuotes() {
        const stored = localStorage.getItem('checkin24hs_quotes');
        if (stored) {
            return JSON.parse(stored);
        }
        
        return [
            {
                id: 1,
                user_id: 1,
                hotel_id: 1,
                check_in_date: '2024-02-15',
                check_out_date: '2024-02-18',
                guests: 2,
                total_price: 450.00,
                status: 'pending',
                special_requests: 'Habitación con vista a los volcanes',
                created_at: '2024-02-01T10:00:00Z'
            },
            {
                id: 2,
                user_id: 2,
                hotel_id: 2,
                check_in_date: '2024-02-20',
                check_out_date: '2024-02-23',
                guests: 1,
                total_price: 320.00,
                status: 'approved',
                special_requests: 'Check-in temprano si es posible',
                created_at: '2024-02-05T14:30:00Z'
            },
            {
                id: 3,
                user_id: 3,
                hotel_id: 3,
                check_in_date: '2024-03-01',
                check_out_date: '2024-03-05',
                guests: 3,
                total_price: 680.00,
                status: 'pending',
                special_requests: 'Cuna para bebé',
                created_at: '2024-02-10T09:15:00Z'
            }
        ];
    }

    saveQuotes() {
        localStorage.setItem('checkin24hs_quotes', JSON.stringify(this.quotes));
    }

    // ===== HISTORIAL DE BÚSQUEDAS =====
    loadSearchHistory() {
        const stored = localStorage.getItem('checkin24hs_search_history');
        if (stored) {
            return JSON.parse(stored);
        }
        
        return [
            {
                id: 1,
                user_id: 1,
                search_term: 'hotel madrid',
                location: 'Madrid',
                filters: { rating: '4.5', amenities: ['wifi', 'pool'] },
                created_at: '2024-02-01T10:00:00Z'
            },
            {
                id: 2,
                user_id: 1,
                search_term: 'hotel granada',
                location: 'Granada',
                filters: { rating: '4.0' },
                created_at: '2024-02-02T11:00:00Z'
            },
            {
                id: 3,
                user_id: 2,
                search_term: 'hotel barcelona',
                location: 'Barcelona',
                filters: { amenities: ['restaurant'] },
                created_at: '2024-02-03T12:00:00Z'
            }
        ];
    }

    saveSearchHistory() {
        localStorage.setItem('checkin24hs_search_history', JSON.stringify(this.searchHistory));
    }

    // ===== RECOMPENSAS =====
    loadRewards() {
        const stored = localStorage.getItem('checkin24hs_rewards');
        if (stored) {
            return JSON.parse(stored);
        }
        
        return [
            {
                id: 1,
                user_id: 1,
                points_earned: 100,
                points_spent: 0,
                activity_type: 'booking',
                description: 'Reserva en Hotel Terma de Puyehue',
                created_at: '2024-02-01T10:00:00Z'
            },
            {
                id: 2,
                user_id: 1,
                points_earned: 50,
                points_spent: 0,
                activity_type: 'review',
                description: 'Reseña del Hotel Granada Palace',
                created_at: '2024-02-02T11:00:00Z'
            },
            {
                id: 3,
                user_id: 2,
                points_earned: 75,
                points_spent: 0,
                activity_type: 'booking',
                description: 'Reserva en Hotel Granada Palace',
                created_at: '2024-02-05T14:30:00Z'
            }
        ];
    }

    saveRewards() {
        localStorage.setItem('checkin24hs_rewards', JSON.stringify(this.rewards));
    }

    // ===== MÉTODOS DE USUARIO =====
    createUser(userData) {
        const newUser = {
            id: this.users.length + 1,
            ...userData,
            rewards_points: 0,
            created_at: new Date().toISOString(),
            is_active: true,
            last_login: null
        };
        
        this.users.push(newUser);
        this.saveUsers();
        return newUser;
    }

    findUserByEmail(email) {
        return this.users.find(user => user.email === email);
    }

    authenticateUser(email, password) {
        const user = this.findUserByEmail(email);
        if (user && user.password === password) {
            user.last_login = new Date().toISOString();
            this.saveUsers();
            return user;
        }
        return null;
    }

    updateUser(userId, updates) {
        const userIndex = this.users.findIndex(user => user.id === userId);
        if (userIndex !== -1) {
            this.users[userIndex] = { ...this.users[userIndex], ...updates };
            this.saveUsers();
            return this.users[userIndex];
        }
        return null;
    }

    // ===== MÉTODOS DE HOTEL =====
    getAllHotels() {
        return this.hotels.filter(hotel => hotel.is_active);
    }

    getHotelById(id) {
        return this.hotels.find(hotel => hotel.id === id);
    }

    searchHotels(query, filters = {}) {
        let results = this.getAllHotels();
        
        if (query) {
            results = results.filter(hotel => 
                hotel.name.toLowerCase().includes(query.toLowerCase()) ||
                hotel.location.toLowerCase().includes(query.toLowerCase())
            );
        }
        
        if (filters.location) {
            results = results.filter(hotel => 
                hotel.location.toLowerCase() === filters.location.toLowerCase()
            );
        }
        
        if (filters.rating) {
            results = results.filter(hotel => 
                hotel.rating >= parseFloat(filters.rating)
            );
        }
        
        return results;
    }

    // ===== MÉTODOS DE COTIZACIONES =====
    createQuote(quoteData) {
        const newQuote = {
            id: this.quotes.length + 1,
            ...quoteData,
            status: 'pending',
            created_at: new Date().toISOString()
        };
        
        this.quotes.push(newQuote);
        this.saveQuotes();
        return newQuote;
    }

    getUserQuotes(userId) {
        return this.quotes.filter(quote => quote.user_id === userId);
    }

    updateQuoteStatus(quoteId, status) {
        const quoteIndex = this.quotes.findIndex(quote => quote.id === quoteId);
        if (quoteIndex !== -1) {
            this.quotes[quoteIndex].status = status;
            this.saveQuotes();
            return this.quotes[quoteIndex];
        }
        return null;
    }

    // ===== MÉTODOS DE HISTORIAL =====
    addSearchHistory(userId, searchData) {
        const newSearch = {
            id: this.searchHistory.length + 1,
            user_id: userId,
            ...searchData,
            created_at: new Date().toISOString()
        };
        
        this.searchHistory.push(newSearch);
        this.saveSearchHistory();
        return newSearch;
    }

    getUserSearchHistory(userId) {
        return this.searchHistory
            .filter(search => search.user_id === userId)
            .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    }

    // ===== MÉTODOS DE RECOMPENSAS =====
    addReward(userId, rewardData) {
        const newReward = {
            id: this.rewards.length + 1,
            user_id: userId,
            points_spent: 0,
            ...rewardData,
            created_at: new Date().toISOString()
        };
        
        this.rewards.push(newReward);
        
        // Actualizar puntos del usuario
        const user = this.users.find(u => u.id === userId);
        if (user) {
            user.rewards_points += rewardData.points_earned;
            this.saveUsers();
        }
        
        this.saveRewards();
        return newReward;
    }

    getUserRewards(userId) {
        return this.rewards.filter(reward => reward.user_id === userId);
    }

    // ===== MÉTODOS DE SESIÓN =====
    createSession(userId) {
        const sessionToken = this.generateToken();
        const session = {
            id: this.sessions.length + 1,
            user_id: userId,
            session_token: sessionToken,
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 horas
            created_at: new Date().toISOString()
        };
        
        this.sessions.push(session);
        return session;
    }

    validateSession(token) {
        const session = this.sessions.find(s => s.session_token === token);
        if (session && new Date(session.expires_at) > new Date()) {
            return session;
        }
        return null;
    }

    generateToken() {
        return Math.random().toString(36).substring(2) + Date.now().toString(36);
    }

    // ===== MÉTODOS DE ADMINISTRACIÓN =====
    getAdminStats() {
        return {
            total_users: this.users.length,
            active_hotels: this.hotels.filter(h => h.is_active).length,
            pending_quotes: this.quotes.filter(q => q.status === 'pending').length,
            total_rewards: this.rewards.reduce((sum, r) => sum + r.points_earned, 0)
        };
    }

    // ===== MÉTODOS DE PERSISTENCIA =====
    saveAll() {
        this.saveUsers();
        this.saveHotels();
        this.saveQuotes();
        this.saveSearchHistory();
        this.saveRewards();
    }

    resetDatabase() {
        localStorage.removeItem('checkin24hs_users');
        localStorage.removeItem('checkin24hs_hotels');
        localStorage.removeItem('checkin24hs_quotes');
        localStorage.removeItem('checkin24hs_search_history');
        localStorage.removeItem('checkin24hs_rewards');
        
        this.users = this.loadUsers();
        this.hotels = this.loadHotels();
        this.quotes = this.loadQuotes();
        this.searchHistory = this.loadSearchHistory();
        this.rewards = this.loadRewards();
    }
}

// Instancia global de la base de datos
const db = new Checkin24hsDB();

// Exportar para uso en otros archivos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { Checkin24hsDB, db };
} 