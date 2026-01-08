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
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        try {
            const { data, error } = await this.client
                .from('hotels')
                .select('*')
                .order('created_at', { ascending: false });

            if (error) throw error;

            console.log(`☁️ ${data?.length || 0} hoteles cargados desde Supabase`);
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo hoteles:', error);
            return [];
        }
    }

    async createHotel(hotel) {
        if (!this.isInitialized()) {
            console.error('❌ Supabase no está inicializado');
            throw new Error('Supabase no está inicializado');
        }

        try {
            const { data, error } = await this.client
                .from('hotels')
                .insert([hotel])
                .select()
                .single();

            if (error) throw error;
            
            console.log('✅ Hotel creado en Supabase:', data.name);
            return data;
        } catch (error) {
            console.error('❌ Error creando hotel:', error);
            throw error;
        }
    }

    async updateHotel(id, updates) {
        if (!this.isInitialized()) {
            console.error('❌ Supabase no está inicializado');
            throw new Error('Supabase no está inicializado');
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
            
            console.log('✅ Hotel actualizado en Supabase:', data.name);
            return data;
        } catch (error) {
            console.error('❌ Error actualizando hotel:', error);
            throw error;
        }
    }

    // Upsert hotel (crear o actualizar)
    async upsertHotel(hotel) {
        if (!this.isInitialized()) {
            console.error('❌ Supabase no está inicializado');
            throw new Error('Supabase no está inicializado');
        }

        try {
            // Preparar datos para upsert
            const hotelData = { ...hotel };
            hotelData.updated_at = new Date().toISOString();
            
            const { data, error } = await this.client
                .from('hotels')
                .upsert([hotelData], { onConflict: 'id' })
                .select()
                .single();
            
            if (error) throw error;
            
            console.log('✅ Hotel guardado en Supabase:', data.name);
            return data;
        } catch (error) {
            console.error('❌ Error en upsert hotel:', error);
            throw error;
        }
    }

    async deleteHotel(id) {
        if (!this.isInitialized()) {
            console.error('❌ Supabase no está inicializado');
            throw new Error('Supabase no está inicializado');
        }

        try {
            const { error } = await this.client
                .from('hotels')
                .delete()
                .eq('id', id);
            
            if (error) throw error;
            
            console.log('✅ Hotel eliminado de Supabase');
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
            console.log('💾 Supabase no inicializado, cargando reservas desde localStorage');
            return JSON.parse(localStorage.getItem('reservationsDB') || '[]');
        }

        try {
            let query = this.client.from('reservations').select('*');
            
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
            
            console.log(`☁️ Reservas cargadas de Supabase: ${data ? data.length : 0} registros`);
            
            // Sincronizar con localStorage solo si hay datos
            if (data && data.length > 0) {
                try {
                    localStorage.setItem('reservationsDB', JSON.stringify(data));
                } catch (e) {
                    console.warn('⚠️ No se pudo guardar en localStorage');
                }
            }
            
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo reservas:', error);
            return JSON.parse(localStorage.getItem('reservationsDB') || '[]');
        }
    }

    async createReservation(reservation) {
        // Eliminar id para que Supabase genere uno nuevo (UUID)
        const reservationToCreate = { ...reservation };
        delete reservationToCreate.id;
        
        console.log('📝 Creando/Actualizando reserva en Supabase:', reservationToCreate);
        
        if (!this.isInitialized()) {
            console.log('💾 Supabase no inicializado, guardando en localStorage');
            const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
            // Buscar si ya existe por reservation_code
            const existingIndex = reservations.findIndex(r => 
                r.reservation_code === reservationToCreate.reservation_code || 
                r.reservationCode === reservationToCreate.reservation_code
            );
            
            if (existingIndex !== -1) {
                // Actualizar existente
                reservations[existingIndex] = { ...reservations[existingIndex], ...reservationToCreate };
                localStorage.setItem('reservationsDB', JSON.stringify(reservations));
                return reservations[existingIndex];
            } else {
                // Crear nuevo
                const newReservation = {
                    ...reservationToCreate,
                    id: 'res-' + Date.now(),
                    created_at: new Date().toISOString()
                };
                reservations.push(newReservation);
                localStorage.setItem('reservationsDB', JSON.stringify(reservations));
                return newReservation;
            }
        }

        try {
            // Usar UPSERT: si existe reservation_code, actualiza; si no, crea
            const { data, error } = await this.client
                .from('reservations')
                .upsert([reservationToCreate], { 
                    onConflict: 'reservation_code',
                    ignoreDuplicates: false 
                })
                .select()
                .single();
            
            if (error) {
                console.error('❌ Error de Supabase:', error);
                throw error;
            }
            
            console.log('✅ Reserva guardada en Supabase con ID:', data.id);
            
            return data;
        } catch (error) {
            console.error('❌ Error creando/actualizando reserva:', error);
            throw error;
        }
    }

    // Función para eliminar reservas duplicadas (mantiene la más reciente)
    async cleanDuplicateReservations() {
        if (!this.isInitialized()) {
            console.log('❌ Supabase no inicializado');
            return { deleted: 0, kept: 0 };
        }

        try {
            console.log('🔍 Buscando reservas duplicadas...');
            
            // Obtener todas las reservas
            const { data: allReservations, error: fetchError } = await this.client
                .from('reservations')
                .select('*')
                .order('created_at', { ascending: false });

            if (fetchError) throw fetchError;

            // Agrupar por reservation_code
            const groupedByCode = {};
            allReservations.forEach(res => {
                const code = res.reservation_code;
                if (!code) return;
                
                if (!groupedByCode[code]) {
                    groupedByCode[code] = [];
                }
                groupedByCode[code].push(res);
            });

            // Encontrar duplicados (códigos con más de 1 reserva)
            const duplicatesToDelete = [];
            let keptCount = 0;

            Object.keys(groupedByCode).forEach(code => {
                const reservations = groupedByCode[code];
                if (reservations.length > 1) {
                    console.log(`🔄 Código ${code}: ${reservations.length} duplicados encontrados`);
                    // Mantener el primero (más reciente por created_at desc), eliminar el resto
                    keptCount++;
                    for (let i = 1; i < reservations.length; i++) {
                        duplicatesToDelete.push(reservations[i].id);
                    }
                } else {
                    keptCount++;
                }
            });

            console.log(`📊 Resumen: ${keptCount} reservas únicas, ${duplicatesToDelete.length} duplicados a eliminar`);

            // Eliminar duplicados
            if (duplicatesToDelete.length > 0) {
                for (const id of duplicatesToDelete) {
                    const { error: deleteError } = await this.client
                        .from('reservations')
                        .delete()
                        .eq('id', id);

                    if (deleteError) {
                        console.error(`❌ Error eliminando duplicado ${id}:`, deleteError);
                    }
                }
                console.log(`✅ ${duplicatesToDelete.length} duplicados eliminados`);
            } else {
                console.log('✅ No se encontraron duplicados');
            }

            return { deleted: duplicatesToDelete.length, kept: keptCount };
        } catch (error) {
            console.error('❌ Error limpiando duplicados:', error);
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
        // Mantener el ID tal como está (puede ser UUID string o número)
        const expenseId = id;
        
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
            image_url: updates.image_url || null,
            image_name: updates.image_name || null,
            updated_at: new Date().toISOString()
        };
        
        console.log('✏️ Actualizando gasto ID:', expenseId, 'con datos:', cleanUpdates);
        
        if (!this.isInitialized()) {
            const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
            const index = expenses.findIndex(e => e.id == id);
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
            console.log('📤 Enviando UPDATE a Supabase para ID:', expenseId);
            
            const { data, error } = await this.client
                .from('expenses')
                .update(cleanUpdates)
                .eq('id', expenseId)
                .select();
            
            if (error) {
                console.error('❌ Error de Supabase al actualizar:', error);
                throw error;
            }
            
            if (!data || data.length === 0) {
                console.error('❌ No se encontró el gasto con ID:', expenseId);
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

    // Limpiar gastos duplicados
    async cleanDuplicateExpenses() {
        console.log('🧹 Iniciando limpieza de gastos duplicados...');
        
        if (!this.isInitialized()) {
            console.log('⚠️ Supabase no inicializado, limpiando localStorage...');
            const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
            const uniqueMap = new Map();
            
            expenses.forEach(expense => {
                const key = `${expense.date}|${expense.amount}|${expense.description}|${expense.category}|${expense.subcategory || ''}`;
                if (!uniqueMap.has(key)) {
                    uniqueMap.set(key, expense);
                }
            });
            
            const uniqueExpenses = Array.from(uniqueMap.values());
            const duplicatesRemoved = expenses.length - uniqueExpenses.length;
            localStorage.setItem('expensesDB', JSON.stringify(uniqueExpenses));
            console.log(`✅ ${duplicatesRemoved} duplicados eliminados de localStorage`);
            return { deleted: duplicatesRemoved, kept: uniqueExpenses.length };
        }

        try {
            // Obtener todos los gastos
            const { data: expenses, error } = await this.client
                .from('expenses')
                .select('*')
                .order('created_at', { ascending: true });
            
            if (error) throw error;
            
            console.log(`📊 Total de gastos encontrados: ${expenses.length}`);
            
            // Agrupar por clave única (fecha + monto + descripción + categoría + subcategoría)
            const groupedExpenses = {};
            const duplicatesToDelete = [];
            let keptCount = 0;
            
            expenses.forEach(expense => {
                const key = `${expense.date}|${expense.amount}|${expense.description}|${expense.category}|${expense.subcategory || ''}`;
                
                if (!groupedExpenses[key]) {
                    groupedExpenses[key] = expense;
                    keptCount++;
                } else {
                    // Este es un duplicado, marcarlo para eliminar
                    duplicatesToDelete.push(expense.id);
                }
            });
            
            console.log(`📊 Resumen: ${keptCount} gastos únicos, ${duplicatesToDelete.length} duplicados a eliminar`);
            
            // Eliminar duplicados
            if (duplicatesToDelete.length > 0) {
                for (const id of duplicatesToDelete) {
                    const { error: deleteError } = await this.client
                        .from('expenses')
                        .delete()
                        .eq('id', id);
                    
                    if (deleteError) {
                        console.error(`❌ Error eliminando duplicado ${id}:`, deleteError);
                    }
                }
                console.log(`✅ ${duplicatesToDelete.length} gastos duplicados eliminados`);
            } else {
                console.log('✅ No se encontraron gastos duplicados');
            }
            
            // Actualizar localStorage
            const { data: updatedExpenses } = await this.client
                .from('expenses')
                .select('*')
                .order('date', { ascending: false });
            
            localStorage.setItem('expensesDB', JSON.stringify(updatedExpenses || []));
            
            return { deleted: duplicatesToDelete.length, kept: keptCount };
        } catch (error) {
            console.error('❌ Error limpiando duplicados de gastos:', error);
            throw error;
        }
    }

    // Verificar si un gasto ya existe (para evitar duplicados en sincronización)
    async expenseExists(expense) {
        if (!this.isInitialized()) {
            const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
            return expenses.some(e => 
                e.date === expense.date && 
                e.amount === expense.amount && 
                e.description === expense.description &&
                e.category === expense.category
            );
        }

        try {
            const { data, error } = await this.client
                .from('expenses')
                .select('id')
                .eq('date', expense.date)
                .eq('amount', expense.amount)
                .eq('description', expense.description)
                .eq('category', expense.category)
                .limit(1);
            
            if (error) throw error;
            return data && data.length > 0;
        } catch (error) {
            console.error('❌ Error verificando existencia de gasto:', error);
            return false;
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

    async updateUser(userId, updates) {
        if (!this.isInitialized()) {
            const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
            const index = users.findIndex(u => u.id === userId || u.id == userId);
            if (index !== -1) {
                users[index] = { ...users[index], ...updates };
                localStorage.setItem('checkin24hs_users', JSON.stringify(users));
                return users[index];
            }
            return null;
        }

        try {
            // Verificar si el ID es un UUID válido
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
            const isUUID = uuidRegex.test(userId);
            
            let query = this.client.from('system_users').update(updates);
            
            if (isUUID) {
                query = query.eq('id', userId);
            } else {
                // Buscar por email si no es UUID
                const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
                const user = users.find(u => u.id === userId || u.id == userId);
                if (user && user.email) {
                    query = query.eq('email', user.email);
                } else {
                    throw new Error('Usuario no encontrado');
                }
            }
            
            const { data, error } = await query.select().single();
            
            if (error) throw error;
            console.log('✅ Usuario actualizado en Supabase:', data);
            return data;
        } catch (error) {
            console.error('❌ Error actualizando usuario:', error);
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
            const existingIndex = admins.findIndex(a => a.id === admin.id || a.username === admin.username);
            if (existingIndex !== -1) {
                admins[existingIndex] = { ...admins[existingIndex], ...admin };
            } else {
                admin.id = admin.id || 'admin-' + Date.now();
                admins.push(admin);
            }
            localStorage.setItem('dashboard_admin_users', JSON.stringify(admins));
            return admin;
        }

        try {
            // Usar upsert para crear o actualizar si ya existe
            const adminData = { ...admin };
            adminData.updated_at = new Date().toISOString();
            
            // Si tiene ID, usar upsert con conflicto en id
            // Si no tiene ID, intentar por username
            const conflictColumn = adminData.id ? 'id' : 'username';
            
            const { data, error } = await this.client
                .from('dashboard_admins')
                .upsert([adminData], { 
                    onConflict: conflictColumn,
                    ignoreDuplicates: false 
                })
                .select()
                .single();
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('❌ Error creando/actualizando administrador:', error);
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
    // AGENTES
    // ============================================
    
    async getAgents() {
        if (!this.isInitialized()) {
            console.log('💾 Supabase no inicializado, cargando agentes desde localStorage');
            return JSON.parse(localStorage.getItem('agentsDB') || '[]');
        }

        try {
            const { data, error } = await this.client
                .from('agents')
                .select('*')
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            
            console.log(`☁️ Agentes cargados de Supabase: ${data ? data.length : 0} registros`);
            
            // Sincronizar con localStorage como backup
            if (data && data.length > 0) {
                localStorage.setItem('agentsDB', JSON.stringify(data));
            }
            
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo agentes:', error);
            return JSON.parse(localStorage.getItem('agentsDB') || '[]');
        }
    }

    async createAgent(agent) {
        if (!this.isInitialized()) {
            const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
            agent.id = agent.id || 'agent-' + Date.now();
            agent.created_at = new Date().toISOString();
            agents.push(agent);
            localStorage.setItem('agentsDB', JSON.stringify(agents));
            return agent;
        }

        try {
            const { data, error } = await this.client
                .from('agents')
                .insert([agent])
                .select()
                .single();
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
            agents.push(data);
            localStorage.setItem('agentsDB', JSON.stringify(agents));
            
            return data;
        } catch (error) {
            console.error('❌ Error creando agente:', error);
            throw error;
        }
    }

    async updateAgent(id, updates) {
        if (!this.isInitialized()) {
            const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
            const index = agents.findIndex(a => a.id === id || a.id == id);
            if (index !== -1) {
                agents[index] = { ...agents[index], ...updates, updated_at: new Date().toISOString() };
                localStorage.setItem('agentsDB', JSON.stringify(agents));
                return agents[index];
            }
            return null;
        }

        try {
            const { data, error } = await this.client
                .from('agents')
                .update({ ...updates, updated_at: new Date().toISOString() })
                .eq('id', id)
                .select()
                .single();
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
            const index = agents.findIndex(a => a.id === id);
            if (index !== -1) {
                agents[index] = data;
                localStorage.setItem('agentsDB', JSON.stringify(agents));
            }
            
            return data;
        } catch (error) {
            console.error('❌ Error actualizando agente:', error);
            throw error;
        }
    }

    async deleteAgent(id) {
        if (!this.isInitialized()) {
            const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
            const filtered = agents.filter(a => a.id !== id && a.id != id);
            localStorage.setItem('agentsDB', JSON.stringify(filtered));
            return { success: true };
        }

        try {
            const { error } = await this.client
                .from('agents')
                .delete()
                .eq('id', id);
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const agents = JSON.parse(localStorage.getItem('agentsDB') || '[]');
            const filtered = agents.filter(a => a.id !== id);
            localStorage.setItem('agentsDB', JSON.stringify(filtered));
            
            return { success: true };
        } catch (error) {
            console.error('❌ Error eliminando agente:', error);
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
    // USUARIOS (CLIENTES)
    // ============================================
    
    async getUsers() {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, usando localStorage como fallback');
            return JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        }

        try {
            const { data, error } = await this.client
                .from('users')
                .select('*')
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            
            console.log(`☁️ Usuarios cargados de Supabase: ${data ? data.length : 0} registros`);
            
            // Sincronizar con localStorage
            if (data && data.length > 0) {
                localStorage.setItem('checkin24hs_users', JSON.stringify(data));
            }
            
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo usuarios:', error);
            return JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        }
    }

    // Buscar usuario por email O teléfono (para evitar duplicados)
    async findUserByEmailOrPhone(email, phone) {
        if (!this.isInitialized()) {
            // Fallback a localStorage
            const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
            return users.find(u => {
                const emailMatch = email && u.email && u.email.toLowerCase() === email.toLowerCase();
                const phoneMatch = phone && u.phone && u.phone === phone;
                return emailMatch || phoneMatch;
            }) || null;
        }

        try {
            let query = this.client.from('users').select('*');
            
            // Construir OR query
            const conditions = [];
            if (email && email.trim()) {
                conditions.push(`email.ilike.${email.toLowerCase()}`);
            }
            if (phone && phone.trim()) {
                conditions.push(`phone.eq.${phone}`);
            }
            
            if (conditions.length === 0) {
                return null;
            }
            
            const { data, error } = await this.client
                .from('users')
                .select('*')
                .or(conditions.join(','))
                .limit(1)
                .single();
            
            if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
                throw error;
            }
            
            return data || null;
        } catch (error) {
            console.error('❌ Error buscando usuario:', error);
            return null;
        }
    }

    // Crear o actualizar usuario (upsert con lógica de deduplicación)
    async upsertUser(userData) {
        const email = userData.email?.trim().toLowerCase() || '';
        const phone = userData.phone?.trim() || '';
        const name = userData.name?.trim() || '';
        
        // Si no hay email ni teléfono, no guardar
        if (!email && !phone) {
            console.log('⚠️ Usuario sin email ni teléfono, no se guarda');
            return null;
        }
        
        if (!this.isInitialized()) {
            // Fallback a localStorage con lógica de deduplicación
            return this.upsertUserLocal(userData);
        }

        try {
            // Buscar si ya existe por email o teléfono
            const existingUser = await this.findUserByEmailOrPhone(email, phone);
            
            if (existingUser) {
                // Actualizar usuario existente - agregar campos faltantes
                const updates = {};
                
                if (!existingUser.email && email) {
                    updates.email = email;
                }
                if (!existingUser.phone && phone) {
                    updates.phone = phone;
                }
                if (!existingUser.name && name) {
                    updates.name = name;
                }
                updates.last_activity = new Date().toISOString();
                updates.updated_at = new Date().toISOString();
                
                if (Object.keys(updates).length > 2) { // Más que solo last_activity y updated_at
                    const { data, error } = await this.client
                        .from('users')
                        .update(updates)
                        .eq('id', existingUser.id)
                        .select()
                        .single();
                    
                    if (error) throw error;
                    console.log('🔄 Usuario actualizado en Supabase:', data.id);
                    return data;
                }
                
                console.log('ℹ️ Usuario ya existe, sin cambios necesarios:', existingUser.id);
                return existingUser;
            } else {
                // Crear nuevo usuario
                const newUser = {
                    name: name,
                    email: email || null,
                    phone: phone || null,
                    status: 'active',
                    is_active: true,
                    last_activity: new Date().toISOString(),
                    rewards_points: 0,
                    tipo_cuenta: 'cliente_reserva'
                };
                
                const { data, error } = await this.client
                    .from('users')
                    .insert([newUser])
                    .select()
                    .single();
                
                if (error) throw error;
                
                console.log('✅ Nuevo usuario creado en Supabase:', data.id);
                return data;
            }
        } catch (error) {
            console.error('❌ Error en upsertUser:', error);
            // Fallback a localStorage
            return this.upsertUserLocal(userData);
        }
    }

    // Versión local de upsertUser para fallback
    upsertUserLocal(userData) {
        const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        const email = userData.email?.trim().toLowerCase() || '';
        const phone = userData.phone?.trim() || '';
        const name = userData.name?.trim() || '';
        
        // Buscar usuario existente por email o teléfono
        const existingIndex = users.findIndex(u => {
            const emailMatch = email && u.email && u.email.toLowerCase() === email.toLowerCase();
            const phoneMatch = phone && u.phone && u.phone === phone;
            return emailMatch || phoneMatch;
        });
        
        if (existingIndex !== -1) {
            // Actualizar usuario existente
            const existing = users[existingIndex];
            if (!existing.email && email) existing.email = email;
            if (!existing.phone && phone) existing.phone = phone;
            if (!existing.name && name) existing.name = name;
            existing.last_activity = new Date().toISOString();
            existing.updatedAt = new Date().toISOString();
            users[existingIndex] = existing;
            console.log('🔄 Usuario actualizado en localStorage:', existing.id);
        } else {
            // Crear nuevo
            const maxId = users.reduce((max, u) => Math.max(max, parseInt(u.id) || 0), 0);
            const newUser = {
                id: maxId + 1,
                name: name,
                email: email || null,
                phone: phone || null,
                status: 'active',
                is_active: true,
                createdAt: new Date().toISOString(),
                created_at: new Date().toISOString(),
                last_activity: new Date().toISOString(),
                rewards_points: 0,
                tipoCuenta: 'cliente_reserva'
            };
            users.push(newUser);
            console.log('✅ Nuevo usuario creado en localStorage:', newUser.id);
        }
        
        localStorage.setItem('checkin24hs_users', JSON.stringify(users));
        return users[existingIndex !== -1 ? existingIndex : users.length - 1];
    }

    // Limpiar usuarios duplicados en localStorage
    cleanDuplicateUsers() {
        const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        console.log(`🧹 Limpiando duplicados de ${users.length} usuarios...`);
        
        const uniqueUsers = [];
        const seenEmails = new Set();
        const seenPhones = new Set();
        
        // Ordenar por fecha de creación (más recientes primero) para mantener los más recientes
        users.sort((a, b) => {
            const dateA = new Date(a.created_at || a.createdAt || 0);
            const dateB = new Date(b.created_at || b.createdAt || 0);
            return dateB - dateA;
        });
        
        for (const user of users) {
            const email = user.email?.trim().toLowerCase() || '';
            const phone = user.phone?.trim() || '';
            
            // Si no tiene ni email ni teléfono, saltar
            if (!email && !phone) continue;
            
            // Verificar si ya vimos este email o teléfono
            const emailExists = email && seenEmails.has(email);
            const phoneExists = phone && seenPhones.has(phone);
            
            if (!emailExists && !phoneExists) {
                uniqueUsers.push(user);
                if (email) seenEmails.add(email);
                if (phone) seenPhones.add(phone);
            } else {
                // Usuario duplicado - buscar el original y agregar campos faltantes
                const originalIndex = uniqueUsers.findIndex(u => {
                    const eMatch = email && u.email && u.email.toLowerCase() === email;
                    const pMatch = phone && u.phone && u.phone === phone;
                    return eMatch || pMatch;
                });
                
                if (originalIndex !== -1) {
                    const original = uniqueUsers[originalIndex];
                    // Agregar campos faltantes
                    if (!original.email && email) {
                        original.email = user.email;
                        seenEmails.add(email);
                    }
                    if (!original.phone && phone) {
                        original.phone = user.phone;
                        seenPhones.add(phone);
                    }
                    if (!original.name && user.name) {
                        original.name = user.name;
                    }
                    uniqueUsers[originalIndex] = original;
                }
            }
        }
        
        // Reasignar IDs consecutivos
        uniqueUsers.forEach((user, index) => {
            user.id = index + 1;
        });
        
        localStorage.setItem('checkin24hs_users', JSON.stringify(uniqueUsers));
        console.log(`✅ Limpieza completada: ${users.length} → ${uniqueUsers.length} usuarios (${users.length - uniqueUsers.length} duplicados eliminados)`);
        
        return {
            before: users.length,
            after: uniqueUsers.length,
            removed: users.length - uniqueUsers.length
        };
    }

    // Sincronizar usuarios locales con Supabase
    async syncUsersToSupabase() {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no inicializado');
            return;
        }
        
        // Primero limpiar duplicados locales
        const cleanResult = this.cleanDuplicateUsers();
        console.log(`🧹 Duplicados locales limpiados:`, cleanResult);
        
        const localUsers = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        console.log(`☁️ Sincronizando ${localUsers.length} usuarios a Supabase...`);
        
        let synced = 0;
        let errors = 0;
        
        for (const user of localUsers) {
            try {
                await this.upsertUser({
                    name: user.name,
                    email: user.email,
                    phone: user.phone
                });
                synced++;
            } catch (error) {
                errors++;
            }
        }
        
        console.log(`✅ Sincronización completada: ${synced} OK, ${errors} errores`);
        return { synced, errors };
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

    // ============================================
    // CHATS DE WHATSAPP
    // ============================================
    
    async getWhatsAppChats(limit = 50) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        try {
            // Primero intentar con el join a users
            let query = this.client
                .from('whatsapp_chats')
                .select('*, users(name, email)')
                .order('last_message_time', { ascending: false })
                .limit(limit);
            
            let { data, error } = await query;

            // Si hay error con el join, intentar sin el join
            if (error && error.message && error.message.includes('users')) {
                console.warn('⚠️ Error con join a users, intentando sin join:', error.message);
                query = this.client
                    .from('whatsapp_chats')
                    .select('*')
                    .order('last_message_time', { ascending: false })
                    .limit(limit);
                
                const result = await query;
                data = result.data;
                error = result.error;
            }

            if (error) {
                console.error('❌ Error obteniendo chats:', error);
                throw error;
            }

            console.log(`📱 ${data?.length || 0} chats de WhatsApp cargados desde Supabase`);
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo chats:', error);
            return [];
        }
    }

    async getWhatsAppMessages(chatId, limit = 100) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        try {
            const { data, error } = await this.client
                .from('whatsapp_messages')
                .select('*')
                .eq('chat_id', chatId)
                .order('created_at', { ascending: true })
                .limit(limit);

            if (error) throw error;

            // Marcar como leídos
            await this.client
                .from('whatsapp_messages')
                .update({ is_read: true })
                .eq('chat_id', chatId)
                .eq('is_from_me', false);

            // Resetear contador
            await this.client
                .from('whatsapp_chats')
                .update({ unread_count: 0 })
                .eq('id', chatId);

            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo mensajes:', error);
            return [];
        }
    }

    // Suscribirse a nuevos mensajes de WhatsApp
    subscribeToWhatsAppMessages(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return null;
        }

        const channel = this.client
            .channel('whatsapp-messages')
            .on('postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'whatsapp_messages' },
                (payload) => {
                    console.log('📱 Nuevo mensaje de WhatsApp:', payload.new);
                    callback(payload.new);
                }
            )
            .subscribe();

        this.activeSubscriptions.whatsappMessages = channel;
        return channel;
    }

    // Suscribirse a cambios en chats
    subscribeToWhatsAppChats(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return null;
        }

        const channel = this.client
            .channel('whatsapp-chats')
            .on('postgres_changes',
                { event: '*', schema: 'public', table: 'whatsapp_chats' },
                (payload) => {
                    console.log('📱 Cambio en chat de WhatsApp:', payload);
                    callback(payload);
                }
            )
            .subscribe();

        this.activeSubscriptions.whatsappChats = channel;
        return channel;
    }

    // ============================================
    // INTERACCIONES DE FLOR
    // ============================================
    
    async getFlorInteractions(limit = 100, filters = {}) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        try {
            let query = this.client
                .from('flor_interactions')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(limit);

            if (filters.intent) {
                query = query.eq('intent', filters.intent);
            }
            if (filters.dateFrom) {
                query = query.gte('created_at', filters.dateFrom);
            }
            if (filters.dateTo) {
                query = query.lte('created_at', filters.dateTo);
            }

            const { data, error } = await query;

            if (error) throw error;

            console.log(`🌸 ${data?.length || 0} interacciones de Flor cargadas desde Supabase`);
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo interacciones:', error);
            return [];
        }
    }

    async getFlorStats(days = 30) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return null;
        }

        try {
            const dateFrom = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

            // Obtener interacciones
            const { data: interactions, error } = await this.client
                .from('flor_interactions')
                .select('id, success, used_ai, response_time_ms, intent')
                .gte('created_at', dateFrom);

            if (error) throw error;

            const total = interactions?.length || 0;
            const successful = interactions?.filter(i => i.success).length || 0;
            const withAI = interactions?.filter(i => i.used_ai).length || 0;
            const avgResponseTime = total > 0
                ? Math.round(interactions.reduce((sum, i) => sum + (i.response_time_ms || 0), 0) / total)
                : 0;

            // Contar intents
            const intentCounts = {};
            interactions?.forEach(i => {
                if (i.intent) {
                    intentCounts[i.intent] = (intentCounts[i.intent] || 0) + 1;
                }
            });

            return {
                total,
                successful,
                successRate: total > 0 ? Math.round(100 * successful / total) : 0,
                withAI,
                aiRate: total > 0 ? Math.round(100 * withAI / total) : 0,
                avgResponseTime,
                topIntents: Object.entries(intentCounts)
                    .sort((a, b) => b[1] - a[1])
                    .slice(0, 5)
                    .map(([intent, count]) => ({ intent, count }))
            };
        } catch (error) {
            console.error('❌ Error obteniendo estadísticas de Flor:', error);
            return null;
        }
    }

    // Suscribirse a nuevas interacciones
    subscribeToFlorInteractions(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return null;
        }

        const channel = this.client
            .channel('flor-interactions')
            .on('postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'flor_interactions' },
                (payload) => {
                    console.log('🌸 Nueva interacción de Flor:', payload.new);
                    callback(payload.new);
                }
            )
            .subscribe();

        this.activeSubscriptions.florInteractions = channel;
        return channel;
    }
}

// Crear instancia global
window.supabaseClient = new SupabaseClient();

// Exportar para uso en módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SupabaseClient;
}

