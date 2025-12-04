// ============================================
// CLIENTE DE SUPABASE PARA CHECKIN24HS
// ============================================
// Este archivo contiene todas las funciones para interactuar con Supabase

class SupabaseClient {
    constructor() {
        // Cargar configuración
        const config = window.SUPABASE_CONFIG || {};
        
        if (!config.url || !config.anonKey || config.url.includes('TU_SUPABASE')) {
            console.error('❌ Error: Configura Supabase en supabase-config.js primero');
            this.initialized = false;
            return;
        }
        
        // Crear cliente de Supabase
        if (typeof supabase !== 'undefined') {
            this.client = supabase.createClient(config.url, config.anonKey);
            this.initialized = true;
            console.log('✅ Cliente de Supabase inicializado correctamente');
        } else {
            console.error('❌ Error: La biblioteca de Supabase no está cargada. Asegúrate de incluir el script de Supabase antes de este archivo.');
            this.initialized = false;
        }
    }

    // Verificar si está inicializado
    isInitialized() {
        return this.initialized && this.client;
    }

    // ============================================
    // HOTELES
    // ============================================
    
    async getHotels() {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, usando localStorage como fallback');
            return JSON.parse(localStorage.getItem('hotelsDB') || '[]');
        }

        try {
            const { data, error } = await this.client
                .from('hotels')
                .select('*')
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            
            // Sincronizar con localStorage como backup
            if (data && data.length > 0) {
                localStorage.setItem('hotelsDB', JSON.stringify(data));
            }
            
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo hoteles:', error);
            // Fallback a localStorage
            return JSON.parse(localStorage.getItem('hotelsDB') || '[]');
        }
    }

    async createHotel(hotel) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, guardando en localStorage');
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            hotel.id = hotel.id || 'hotel-' + Date.now();
            hotels.push(hotel);
            localStorage.setItem('hotelsDB', JSON.stringify(hotels));
            return hotel;
        }

        try {
            const { data, error } = await this.client
                .from('hotels')
                .insert([hotel])
                .select()
                .single();
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            hotels.push(data);
            localStorage.setItem('hotelsDB', JSON.stringify(hotels));
            
            return data;
        } catch (error) {
            console.error('❌ Error creando hotel:', error);
            throw error;
        }
    }

    async updateHotel(id, updates) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, actualizando localStorage');
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            const index = hotels.findIndex(h => h.id === id);
            if (index !== -1) {
                hotels[index] = { ...hotels[index], ...updates };
                localStorage.setItem('hotelsDB', JSON.stringify(hotels));
                return hotels[index];
            }
            return null;
        }

        try {
            // Limpiar campos undefined y null innecesarios
            const cleanUpdates = {};
            Object.keys(updates).forEach(key => {
                if (updates[key] !== undefined) {
                    cleanUpdates[key] = updates[key];
                }
            });
            cleanUpdates.updated_at = new Date().toISOString();
            
            console.log('📤 Actualizando hotel en Supabase:', {
                id,
                updates: {
                    ...cleanUpdates,
                    images: cleanUpdates.images ? `${Array.isArray(cleanUpdates.images) ? cleanUpdates.images.length : 'N/A'} imagen(es)` : 'null'
                }
            });
            
            const { data, error } = await this.client
                .from('hotels')
                .update(cleanUpdates)
                .eq('id', id)
                .select()
                .single();
            
            if (error) {
                console.error('❌ Error detallado de Supabase:', {
                    code: error.code,
                    message: error.message,
                    details: error.details,
                    hint: error.hint
                });
                throw error;
            }
            
            // Sincronizar con localStorage
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            const index = hotels.findIndex(h => h.id === id);
            if (index !== -1) {
                hotels[index] = data;
                localStorage.setItem('hotelsDB', JSON.stringify(hotels));
            }
            
            return data;
        } catch (error) {
            console.error('❌ Error actualizando hotel:', error);
            throw error;
        }
    }

    async deleteHotel(id) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, eliminando de localStorage');
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            const filtered = hotels.filter(h => h.id !== id);
            localStorage.setItem('hotelsDB', JSON.stringify(filtered));
            return;
        }

        try {
            const { error } = await this.client
                .from('hotels')
                .delete()
                .eq('id', id);
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            const filtered = hotels.filter(h => h.id !== id);
            localStorage.setItem('hotelsDB', JSON.stringify(filtered));
        } catch (error) {
            console.error('❌ Error eliminando hotel:', error);
            throw error;
        }
    }

    // ============================================
    // RESERVAS
    // ============================================
    
    async getReservations(filters = {}) {
        if (!this.isInitialized()) {
            return JSON.parse(localStorage.getItem('reservationsDB') || '[]');
        }

        try {
            let query = this.client.from('reservations').select('*, hotels(*)');
            
            if (filters.status) {
                query = query.eq('status', filters.status);
            }
            if (filters.hotel_id) {
                query = query.eq('hotel_id', filters.hotel_id);
            }
            if (filters.date_from) {
                query = query.gte('check_in', filters.date_from);
            }
            
            const { data, error } = await query.order('created_at', { ascending: false });
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            if (data && data.length > 0) {
                localStorage.setItem('reservationsDB', JSON.stringify(data));
            }
            
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo reservas:', error);
            return JSON.parse(localStorage.getItem('reservationsDB') || '[]');
        }
    }

    async createReservation(reservation) {
        if (!this.isInitialized()) {
            const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
            reservation.id = reservation.id || 'res-' + Date.now();
            reservations.push(reservation);
            localStorage.setItem('reservationsDB', JSON.stringify(reservations));
            return reservation;
        }

        try {
            const { data, error } = await this.client
                .from('reservations')
                .insert([reservation])
                .select()
                .single();
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
            reservations.push(data);
            localStorage.setItem('reservationsDB', JSON.stringify(reservations));
            
            return data;
        } catch (error) {
            console.error('❌ Error creando reserva:', error);
            throw error;
        }
    }

    async updateReservation(id, updates) {
        if (!this.isInitialized()) {
            const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
            const index = reservations.findIndex(r => r.id === id);
            if (index !== -1) {
                reservations[index] = { ...reservations[index], ...updates };
                localStorage.setItem('reservationsDB', JSON.stringify(reservations));
                return reservations[index];
            }
            return null;
        }

        try {
            const { data, error } = await this.client
                .from('reservations')
                .update({ ...updates, updated_at: new Date().toISOString() })
                .eq('id', id)
                .select()
                .single();
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
            const index = reservations.findIndex(r => r.id === id);
            if (index !== -1) {
                reservations[index] = data;
                localStorage.setItem('reservationsDB', JSON.stringify(reservations));
            }
            
            return data;
        } catch (error) {
            console.error('❌ Error actualizando reserva:', error);
            throw error;
        }
    }

    // ============================================
    // COTIZACIONES
    // ============================================
    
    async getQuotes(filters = {}) {
        if (!this.isInitialized()) {
            return JSON.parse(localStorage.getItem('quotesDB') || '[]');
        }

        try {
            let query = this.client.from('quotes').select('*, hotels(*)');
            
            if (filters.status) {
                query = query.eq('status', filters.status);
            }
            
            const { data, error } = await query.order('created_at', { ascending: false });
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            if (data && data.length > 0) {
                localStorage.setItem('quotesDB', JSON.stringify(data));
            }
            
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo cotizaciones:', error);
            return JSON.parse(localStorage.getItem('quotesDB') || '[]');
        }
    }

    async createQuote(quote) {
        if (!this.isInitialized()) {
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            quote.id = quote.id || 'quote-' + Date.now();
            quotes.push(quote);
            localStorage.setItem('quotesDB', JSON.stringify(quotes));
            return quote;
        }

        try {
            const { data, error } = await this.client
                .from('quotes')
                .insert([quote])
                .select()
                .single();
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            quotes.push(data);
            localStorage.setItem('quotesDB', JSON.stringify(quotes));
            
            return data;
        } catch (error) {
            console.error('❌ Error creando cotización:', error);
            throw error;
        }
    }

    async updateQuote(id, updates) {
        if (!this.isInitialized()) {
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            const index = quotes.findIndex(q => q.id === id);
            if (index !== -1) {
                quotes[index] = { ...quotes[index], ...updates };
                localStorage.setItem('quotesDB', JSON.stringify(quotes));
                return quotes[index];
            }
            return null;
        }

        try {
            const { data, error } = await this.client
                .from('quotes')
                .update({ ...updates, updated_at: new Date().toISOString() })
                .eq('id', id)
                .select()
                .single();
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            const index = quotes.findIndex(q => q.id === id);
            if (index !== -1) {
                quotes[index] = data;
                localStorage.setItem('quotesDB', JSON.stringify(quotes));
            }
            
            return data;
        } catch (error) {
            console.error('❌ Error actualizando cotización:', error);
            throw error;
        }
    }

    // ============================================
    // GASTOS
    // ============================================
    
    async getExpenses(filters = {}) {
        if (!this.isInitialized()) {
            console.log('💾 Supabase no inicializado, cargando desde localStorage');
            return JSON.parse(localStorage.getItem('expensesDB') || '[]');
        }

        try {
            let query = this.client.from('expenses').select('*');
            
            if (filters.type) {
                query = query.eq('type', filters.type);
            }
            if (filters.date_from) {
                query = query.gte('date', filters.date_from);
            }
            if (filters.date_to) {
                query = query.lte('date', filters.date_to);
            }
            
            const { data, error } = await query.order('date', { ascending: false });
            
            if (error) throw error;
            
            console.log(`☁️ Gastos cargados de Supabase: ${data ? data.length : 0} registros`);
            
            // Solo sincronizar si hay datos
            if (data && data.length > 0) {
                localStorage.setItem('expensesDB', JSON.stringify(data));
            }
            
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo gastos:', error);
            return JSON.parse(localStorage.getItem('expensesDB') || '[]');
        }
    }

    async createExpense(expense) {
        // IMPORTANTE: Eliminar el id para que Supabase genere uno nuevo automáticamente
        const expenseToCreate = { ...expense };
        delete expenseToCreate.id;
        delete expenseToCreate.exchangeRate; // Solo usar snake_case para Supabase
        delete expenseToCreate.usd; // Solo usar usd_amount para Supabase
        
        console.log('📝 Creando gasto en Supabase:', expenseToCreate);
        
        if (!this.isInitialized()) {
            const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
            const newExpense = {
                ...expense,
                id: 'expense-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                created_at: new Date().toISOString()
            };
            expenses.push(newExpense);
            localStorage.setItem('expensesDB', JSON.stringify(expenses));
            console.log('💾 Gasto guardado en localStorage, total:', expenses.length);
            return newExpense;
        }

        try {
            const { data, error } = await this.client
                .from('expenses')
                .insert([expenseToCreate])
                .select()
                .single();
            
            if (error) {
                console.error('❌ Error de Supabase:', error);
                throw error;
            }
            
            console.log('✅ Gasto creado en Supabase con ID:', data.id);
            
            // NO sincronizar con localStorage aquí - se hará al cargar
            return data;
        } catch (error) {
            console.error('❌ Error creando gasto:', error);
            throw error;
        }
    }

    async updateExpense(id, updates) {
        // Convertir ID a número
        const numericId = typeof id === 'string' ? parseInt(id) : id;
        
        // Limpiar campos que no son de Supabase (solo enviar snake_case)
        const cleanUpdates = {
            date: updates.date,
            type: updates.type,
            category: updates.category,
            subcategory: updates.subcategory || '',
            description: updates.description,
            amount: updates.amount,
            exchange_rate: updates.exchange_rate,
            usd_amount: updates.usd_amount,
            updated_at: new Date().toISOString()
        };
        
        console.log('✏️ Actualizando gasto ID:', numericId, 'con datos:', cleanUpdates);
        
        if (!this.isInitialized()) {
            const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
            const index = expenses.findIndex(e => e.id == id || e.id == numericId);
            if (index !== -1) {
                expenses[index] = { ...expenses[index], ...updates, ...cleanUpdates };
                localStorage.setItem('expensesDB', JSON.stringify(expenses));
                console.log('💾 Gasto actualizado en localStorage, index:', index);
                return expenses[index];
            }
            console.warn('⚠️ Gasto no encontrado en localStorage, ID:', id);
            return null;
        }

        try {
            console.log('📤 Enviando UPDATE a Supabase para ID:', numericId);
            
            const { data, error } = await this.client
                .from('expenses')
                .update(cleanUpdates)
                .eq('id', numericId)
                .select();
            
            if (error) {
                console.error('❌ Error de Supabase al actualizar:', error);
                throw error;
            }
            
            if (!data || data.length === 0) {
                console.error('❌ No se encontró el gasto con ID:', numericId);
                throw new Error('Gasto no encontrado en la base de datos');
            }
            
            console.log('✅ Gasto actualizado en Supabase:', data[0]);
            
            return data[0];
        } catch (error) {
            console.error('❌ Error actualizando gasto:', error);
            throw error;
        }
    }

    async deleteExpense(id) {
        if (!this.isInitialized()) {
            const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
            const filtered = expenses.filter(e => e.id !== id);
            localStorage.setItem('expensesDB', JSON.stringify(filtered));
            return;
        }

        try {
            const { error } = await this.client
                .from('expenses')
                .delete()
                .eq('id', id);
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
            const filtered = expenses.filter(e => e.id !== id);
            localStorage.setItem('expensesDB', JSON.stringify(filtered));
        } catch (error) {
            console.error('❌ Error eliminando gasto:', error);
            throw error;
        }
    }

    // ============================================
    // USUARIOS DEL SISTEMA
    // ============================================
    
    async getUsers() {
        if (!this.isInitialized()) {
            return JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        }

        try {
            const { data, error } = await this.client
                .from('system_users')
                .select('*')
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo usuarios:', error);
            return JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        }
    }

    async createUser(user) {
        if (!this.isInitialized()) {
            const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
            user.id = user.id || 'user-' + Date.now();
            users.push(user);
            localStorage.setItem('checkin24hs_users', JSON.stringify(users));
            return user;
        }

        try {
            const { data, error } = await this.client
                .from('system_users')
                .insert([user])
                .select()
                .single();
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('❌ Error creando usuario:', error);
            throw error;
        }
    }

    async deleteUser(userId) {
        if (!this.isInitialized()) {
            const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
            const updatedUsers = users.filter(user => user.id !== userId);
            localStorage.setItem('checkin24hs_users', JSON.stringify(updatedUsers));
            return { success: true };
        }

        try {
            // Si el userId no es un UUID (es numérico o string simple), intentar eliminar por email
            const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
            const userToDelete = users.find(user => user.id === userId || user.id == userId);
            
            // Intentar eliminar por ID (si es UUID) o por email
            let deleteQuery = this.client.from('system_users').delete();
            
            // Verificar si el ID es un UUID válido
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
            const isUUID = uuidRegex.test(userId);
            
            if (isUUID) {
                // Si es UUID, eliminar por ID
                deleteQuery = deleteQuery.eq('id', userId);
            } else if (userToDelete && userToDelete.email) {
                // Si no es UUID pero tenemos el email, eliminar por email
                deleteQuery = deleteQuery.eq('email', userToDelete.email);
            } else {
                // Si no tenemos email y no es UUID, simplemente retornar éxito
                // (el usuario probablemente no existe en Supabase)
                console.log('ℹ️ Usuario no encontrado en Supabase, solo eliminando de localStorage');
                return { success: true };
            }
            
            const { error } = await deleteQuery;
            
            // Si el error es 400 o 404, probablemente el usuario no existe en Supabase
            // Esto es normal para usuarios de prueba que solo están en localStorage
            if (error) {
                if (error.code === 'PGRST116' || error.message?.includes('No rows')) {
                    console.log('ℹ️ Usuario no existe en Supabase (probablemente solo en localStorage)');
                    return { success: true };
                }
                throw error;
            }
            
            return { success: true };
        } catch (error) {
            // Si hay un error pero es porque el usuario no existe, no lanzar excepción
            if (error.code === 'PGRST116' || error.message?.includes('No rows') || error.status === 400) {
                console.log('ℹ️ Usuario no existe en Supabase, continuando con eliminación local');
                return { success: true };
            }
            console.error('❌ Error eliminando usuario:', error);
            throw error;
        }
    }

    // ============================================
    // ADMINISTRADORES DEL DASHBOARD
    // ============================================
    
    async getAdmins() {
        if (!this.isInitialized()) {
            return JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
        }

        try {
            const { data, error } = await this.client
                .from('dashboard_admins')
                .select('*')
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo administradores:', error);
            return JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
        }
    }

    async createAdmin(admin) {
        if (!this.isInitialized()) {
            const admins = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
            admin.id = admin.id || 'admin-' + Date.now();
            admins.push(admin);
            localStorage.setItem('dashboard_admin_users', JSON.stringify(admins));
            return admin;
        }

        try {
            // Nota: En producción, deberías hashear la contraseña antes de guardarla
            const { data, error } = await this.client
                .from('dashboard_admins')
                .insert([admin])
                .select()
                .single();
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('❌ Error creando administrador:', error);
            throw error;
        }
    }

    async updateAdmin(id, updates) {
        if (!this.isInitialized()) {
            const admins = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
            const index = admins.findIndex(a => a.id === id);
            if (index !== -1) {
                admins[index] = { ...admins[index], ...updates };
                localStorage.setItem('dashboard_admin_users', JSON.stringify(admins));
                return admins[index];
            }
            return null;
        }

        try {
            const { data, error } = await this.client
                .from('dashboard_admins')
                .update({ ...updates, updated_at: new Date().toISOString() })
                .eq('id', id)
                .select()
                .single();
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('❌ Error actualizando administrador:', error);
            throw error;
        }
    }

    // ============================================
    // SUBSCRIPCIONES EN TIEMPO REAL
    // ============================================
    
    // Almacenar suscripciones activas
    activeSubscriptions = {};

    subscribeToReservations(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se pueden usar suscripciones en tiempo real');
            return null;
        }

        const channel = this.client
            .channel('reservations-changes')
            .on('postgres_changes', 
                { event: '*', schema: 'public', table: 'reservations' },
                (payload) => {
                    console.log('🔄 Cambio en reservaciones:', payload.eventType);
                    callback(payload);
                }
            )
            .subscribe();
        
        this.activeSubscriptions.reservations = channel;
        return channel;
    }

    subscribeToQuotes(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se pueden usar suscripciones en tiempo real');
            return null;
        }

        const channel = this.client
            .channel('quotes-changes')
            .on('postgres_changes',
                { event: '*', schema: 'public', table: 'quotes' },
                (payload) => {
                    console.log('🔄 Cambio en cotizaciones:', payload.eventType);
                    callback(payload);
                }
            )
            .subscribe();
        
        this.activeSubscriptions.quotes = channel;
        return channel;
    }

    subscribeToHotels(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se pueden usar suscripciones en tiempo real');
            return null;
        }

        const channel = this.client
            .channel('hotels-changes')
            .on('postgres_changes',
                { event: '*', schema: 'public', table: 'hotels' },
                (payload) => {
                    console.log('🔄 Cambio en hoteles:', payload.eventType);
                    callback(payload);
                }
            )
            .subscribe();
        
        this.activeSubscriptions.hotels = channel;
        return channel;
    }

    subscribeToUsers(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se pueden usar suscripciones en tiempo real');
            return null;
        }

        const channel = this.client
            .channel('users-changes')
            .on('postgres_changes',
                { event: '*', schema: 'public', table: 'users' },
                (payload) => {
                    console.log('🔄 Cambio en usuarios:', payload.eventType);
                    callback(payload);
                }
            )
            .subscribe();
        
        this.activeSubscriptions.users = channel;
        return channel;
    }

    subscribeToExpenses(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se pueden usar suscripciones en tiempo real');
            return null;
        }

        const channel = this.client
            .channel('expenses-changes')
            .on('postgres_changes',
                { event: '*', schema: 'public', table: 'expenses' },
                (payload) => {
                    console.log('🔄 Cambio en gastos:', payload.eventType);
                    callback(payload);
                }
            )
            .subscribe();
        
        this.activeSubscriptions.expenses = channel;
        return channel;
    }

    subscribeToAgents(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se pueden usar suscripciones en tiempo real');
            return null;
        }

        const channel = this.client
            .channel('agents-changes')
            .on('postgres_changes',
                { event: '*', schema: 'public', table: 'agents' },
                (payload) => {
                    console.log('🔄 Cambio en agentes:', payload.eventType);
                    callback(payload);
                }
            )
            .subscribe();
        
        this.activeSubscriptions.agents = channel;
        return channel;
    }

    // Suscribirse a TODOS los cambios relevantes
    subscribeToAllChanges(callbacks = {}) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return;
        }

        console.log('🔄 Iniciando suscripciones en tiempo real...');

        if (callbacks.onReservationChange) {
            this.subscribeToReservations(callbacks.onReservationChange);
        }
        if (callbacks.onQuoteChange) {
            this.subscribeToQuotes(callbacks.onQuoteChange);
        }
        if (callbacks.onHotelChange) {
            this.subscribeToHotels(callbacks.onHotelChange);
        }
        if (callbacks.onUserChange) {
            this.subscribeToUsers(callbacks.onUserChange);
        }
        if (callbacks.onExpenseChange) {
            this.subscribeToExpenses(callbacks.onExpenseChange);
        }
        if (callbacks.onAgentChange) {
            this.subscribeToAgents(callbacks.onAgentChange);
        }

        console.log('✅ Suscripciones en tiempo real activas');
    }

    // Desuscribirse de todos los canales
    unsubscribeAll() {
        Object.values(this.activeSubscriptions).forEach(channel => {
            if (channel) {
                this.client.removeChannel(channel);
            }
        });
        this.activeSubscriptions = {};
        console.log('🔌 Desuscrito de todos los canales');
    }

    // ============================================
    // MÉTODO DE PRUEBA DE CONEXIÓN
    // ============================================
    
    async testConnection() {
        if (!this.isInitialized()) {
            return { success: false, error: 'Supabase no está inicializado' };
        }

        try {
            const { data, error } = await this.client
                .from('hotels')
                .select('count')
                .limit(1);
            
            if (error) throw error;
            
            return { success: true, message: 'Conexión exitosa con Supabase' };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }
}

// Crear instancia global
window.supabaseClient = new SupabaseClient();

// Exportar para uso en módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SupabaseClient;
}

