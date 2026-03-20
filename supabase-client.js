// ============================================
// CLIENTE DE SUPABASE PARA CHECKIN24HS
// ============================================
// Este archivo contiene todas las funciones para interactuar con Supabase.
// Cuando Supabase está inicializado, es la única fuente de verdad: no se escribe
// en localStorage al cargar (hoteles, reservas, usuarios, cotizaciones, gastos),
// para evitar QuotaExceededError. localStorage solo se usa como fallback cuando
// Supabase no está disponible.

class SupabaseClient {
    constructor() {
        // Cargar configuración
        const config = window.SUPABASE_CONFIG || {};
        
        if (!config.url || !config.anonKey || config.url.includes('TU_SUPABASE')) {
            console.error('❌ Error: Configura DASHBOARD_CONFIG.supabase en dashboard.html primero');
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
    
    /**
     * Lista de hoteles. Por defecto usa consulta ligera (sin images ni flor_info) para evitar timeout en Supabase.
     * @param {Object} [opts] - { light: true } (default) = solo columnas ligeras; { light: false } = fila completa (images, flor_info).
     */
    /** Solo hoteles visibles: status = 'active', 'activo', 'Activo' o null (excluye 'inactive'/'Inactivo') */
    _filterActiveHotels(list) {
        if (!Array.isArray(list)) return [];
        const active = (s) => s === 'active' || s === 'activo' || s === 'Activo' || s == null || s === '';
        return list.filter(h => h && active(h.status));
    }

    async getHotels(opts = {}) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, usando localStorage como fallback');
            const raw = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            return this._filterActiveHotels(raw);
        }

        const light = opts.light !== false; // por defecto true para evitar statement timeout
        const selectColumns = light
            ? 'id,name,location,status,google_maps,website,rating,price,description,amenities,coordinates,created_at,updated_at'
            : '*';

        try {
            const { data, error } = await this.client
                .from('hotels')
                .select(selectColumns)
                .or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null')
                .order('created_at', { ascending: false });

            if (error) throw error;

            // Supabase es la fuente de verdad: no escribir en localStorage para evitar llenar cuota
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo hoteles:', error);
            try {
                const raw = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
                return this._filterActiveHotels(raw);
            } catch (e) {
                return [];
            }
        }
    }

    /** Obtiene un hotel completo por ID (incluye images y flor_info). Usar para abrir el formulario de edición. */
    async getHotelById(id) {
        if (!this.isInitialized() || !id) {
            const local = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            return local.find(h => h.id == id || String(h && h.id) === String(id)) || null;
        }
        try {
            const { data, error } = await this.client
                .from('hotels')
                .select('*')
                .eq('id', id)
                .single();
            if (error) throw error;
            return data;
        } catch (error) {
            console.warn('⚠️ Error obteniendo hotel por ID:', error);
            const local = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            return local.find(h => h.id == id || String(h && h.id) === String(id)) || null;
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
            const match = (h, i) => h.id == i || String(h && h.id) === String(i);
            const index = hotels.findIndex(h => match(h, id));
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
            
            const florKeys = cleanUpdates.flor_info && typeof cleanUpdates.flor_info === 'object' ? Object.keys(cleanUpdates.flor_info) : [];
            console.log('📤 Actualizando hotel en Supabase:', {
                id,
                flor_info_keys: florKeys.length ? florKeys : 'no enviado',
                images: cleanUpdates.images ? `${Array.isArray(cleanUpdates.images) ? cleanUpdates.images.length : 'N/A'} imagen(es)` : 'null'
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
            
            // Sincronizar con localStorage (si hay espacio; si no, no fallar - Supabase es la fuente de verdad)
            try {
                const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
                const match = (h, i) => h.id == i || String(h && h.id) === String(i);
                const index = hotels.findIndex(h => match(h, id));
                if (index !== -1) {
                    hotels[index] = data;
                    localStorage.setItem('hotelsDB', JSON.stringify(hotels));
                }
            } catch (e) {
                if (e.name === 'QuotaExceededError') {
                    console.warn('⚠️ localStorage lleno: no se pudo guardar copia local del hotel. Los datos sí están en Supabase.');
                } else {
                    console.warn('⚠️ Error sincronizando a localStorage:', e);
                }
            }
            
            return data;
        } catch (error) {
            console.error('❌ Error actualizando hotel:', error);
            throw error;
        }
    }

    // Upsert hotel (crear o actualizar)
    async upsertHotel(hotel) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, guardando en localStorage');
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            const existingIndex = hotels.findIndex(h => h.id === hotel.id || h.name === hotel.name);
            if (existingIndex !== -1) {
                hotels[existingIndex] = { ...hotels[existingIndex], ...hotel };
            } else {
                hotel.id = hotel.id || 'hotel-' + Date.now();
                hotels.push(hotel);
            }
            localStorage.setItem('hotelsDB', JSON.stringify(hotels));
            return hotel;
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
            
            // Sincronizar con localStorage
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            const existingIndex = hotels.findIndex(h => h.id === data.id);
            if (existingIndex !== -1) {
                hotels[existingIndex] = data;
            } else {
                hotels.push(data);
            }
            localStorage.setItem('hotelsDB', JSON.stringify(hotels));
            
            return data;
        } catch (error) {
            console.error('❌ Error en upsert hotel:', error);
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
    // PROMOCIONES
    // ============================================
    
    async getPromotions(hotelId = null) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, usando localStorage como fallback');
            // Buscar en localStorage
            if (hotelId) {
                return JSON.parse(localStorage.getItem(`promotions_${hotelId}`) || '[]');
            } else {
                // Si no hay hotelId, buscar todas las promociones de todos los hoteles
                const allKeys = Object.keys(localStorage);
                const promotionKeys = allKeys.filter(key => key.startsWith('promotions_'));
                const allPromotions = [];
                promotionKeys.forEach(key => {
                    const promos = JSON.parse(localStorage.getItem(key) || '[]');
                    allPromotions.push(...promos);
                });
                return allPromotions;
            }
        }

        try {
            let query = this.client.from('promotions').select('*');
            
            if (hotelId) {
                query = query.eq('hotel_id', hotelId);
            }
            
            const { data, error } = await query
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            
            // Mapear datos de Supabase al formato del frontend
            const mappedData = (data || []).map(promo => ({
                id: promo.id,
                hotelId: promo.hotel_id,
                name: promo.name,
                type: promo.type,
                description: promo.description,
                discount: parseFloat(promo.discount || 0),
                price: promo.promotional_price ? parseFloat(promo.promotional_price) : null,
                promotionalPrice: promo.promotional_price ? parseFloat(promo.promotional_price) : null,
                startDate: promo.start_date,
                endDate: promo.end_date,
                travelStartDate: promo.travel_start_date || null,
                travelEndDate: promo.travel_end_date || null,
                status: promo.status || 'active',
                createdAt: promo.created_at,
                created_at: promo.created_at
            }));
            
            return mappedData;
        } catch (error) {
            console.error('❌ Error obteniendo promociones:', error);
            // Fallback a localStorage
            if (hotelId) {
                return JSON.parse(localStorage.getItem(`promotions_${hotelId}`) || '[]');
            }
            return [];
        }
    }

    async createPromotion(promotion) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, guardando en localStorage');
            const hotelId = promotion.hotelId || promotion.hotel_id;
            if (!hotelId) {
                throw new Error('hotelId es requerido');
            }
            const existingPromotions = JSON.parse(localStorage.getItem(`promotions_${hotelId}`) || '[]');
            const newPromotion = {
                ...promotion,
                id: promotion.id || Date.now() + Math.random().toString(36).substr(2, 9),
                createdAt: promotion.createdAt || new Date().toISOString()
            };
            existingPromotions.push(newPromotion);
            localStorage.setItem(`promotions_${hotelId}`, JSON.stringify(existingPromotions));
            return newPromotion;
        }

        try {
            // Mapear campos del frontend a Supabase
            const promotionData = {
                hotel_id: promotion.hotelId || promotion.hotel_id,
                name: promotion.name,
                type: promotion.type || null,
                description: promotion.description || null,
                discount: parseFloat(promotion.discount || 0),
                promotional_price: promotion.promotionalPrice || promotion.price || promotion.promotional_price || null,
                start_date: promotion.startDate || promotion.start_date,
                end_date: promotion.endDate || promotion.end_date,
                travel_start_date: promotion.travelStartDate || promotion.travel_start_date || null,
                travel_end_date: promotion.travelEndDate || promotion.travel_end_date || null,
                status: promotion.status || 'active'
            };
            
            const { data, error } = await this.client
                .from('promotions')
                .insert([promotionData])
                .select()
                .single();
            
            if (error) throw error;
            
            // Mapear de vuelta a formato del frontend
            const mappedData = {
                id: data.id,
                hotelId: data.hotel_id,
                name: data.name,
                type: data.type,
                description: data.description,
                discount: parseFloat(data.discount || 0),
                price: data.promotional_price ? parseFloat(data.promotional_price) : null,
                promotionalPrice: data.promotional_price ? parseFloat(data.promotional_price) : null,
                startDate: data.start_date,
                endDate: data.end_date,
                travelStartDate: data.travel_start_date || null,
                travelEndDate: data.travel_end_date || null,
                status: data.status,
                createdAt: data.created_at,
                created_at: data.created_at
            };
            
            return mappedData;
        } catch (error) {
            console.error('❌ Error creando promoción:', error);
            throw error;
        }
    }

    async updatePromotion(id, updates) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, actualizando localStorage');
            // Buscar en localStorage
            const allKeys = Object.keys(localStorage);
            const promotionKeys = allKeys.filter(key => key.startsWith('promotions_'));
            for (const key of promotionKeys) {
                const promos = JSON.parse(localStorage.getItem(key) || '[]');
                const index = promos.findIndex(p => p.id === id);
                if (index !== -1) {
                    promos[index] = { ...promos[index], ...updates };
                    localStorage.setItem(key, JSON.stringify(promos));
                    return promos[index];
                }
            }
            return null;
        }

        try {
            // Mapear campos del frontend a Supabase
            const updateData = {};
            if (updates.hotelId !== undefined) updateData.hotel_id = updates.hotelId;
            if (updates.name !== undefined) updateData.name = updates.name;
            if (updates.type !== undefined) updateData.type = updates.type;
            if (updates.description !== undefined) updateData.description = updates.description;
            if (updates.discount !== undefined) updateData.discount = parseFloat(updates.discount);
            if (updates.price !== undefined || updates.promotionalPrice !== undefined) {
                updateData.promotional_price = updates.promotionalPrice || updates.price || null;
            }
            if (updates.startDate !== undefined) updateData.start_date = updates.startDate;
            if (updates.endDate !== undefined) updateData.end_date = updates.endDate;
            if (updates.travelStartDate !== undefined) updateData.travel_start_date = updates.travelStartDate || null;
            if (updates.travelEndDate !== undefined) updateData.travel_end_date = updates.travelEndDate || null;
            if (updates.status !== undefined) updateData.status = updates.status;
            
            const { data, error } = await this.client
                .from('promotions')
                .update(updateData)
                .eq('id', id)
                .select()
                .single();
            
            if (error) throw error;
            
            // Mapear de vuelta a formato del frontend
            const mappedData = {
                id: data.id,
                hotelId: data.hotel_id,
                name: data.name,
                type: data.type,
                description: data.description,
                discount: parseFloat(data.discount || 0),
                price: data.promotional_price ? parseFloat(data.promotional_price) : null,
                promotionalPrice: data.promotional_price ? parseFloat(data.promotional_price) : null,
                startDate: data.start_date,
                endDate: data.end_date,
                travelStartDate: data.travel_start_date || null,
                travelEndDate: data.travel_end_date || null,
                status: data.status,
                createdAt: data.created_at
            };
            
            return mappedData;
        } catch (error) {
            console.error('❌ Error actualizando promoción:', error);
            throw error;
        }
    }

    async deletePromotion(id) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, eliminando de localStorage');
            // Buscar en localStorage
            const allKeys = Object.keys(localStorage);
            const promotionKeys = allKeys.filter(key => key.startsWith('promotions_'));
            for (const key of promotionKeys) {
                const promos = JSON.parse(localStorage.getItem(key) || '[]');
                const filtered = promos.filter(p => p.id !== id);
                if (filtered.length !== promos.length) {
                    localStorage.setItem(key, JSON.stringify(filtered));
                    return;
                }
            }
            return;
        }

        try {
            const { error } = await this.client
                .from('promotions')
                .delete()
                .eq('id', id);
            
            if (error) throw error;
        } catch (error) {
            console.error('❌ Error eliminando promoción:', error);
            throw error;
        }
    }

    // Migrar promociones desde localStorage a Supabase
    async migratePromotionsFromLocalStorage() {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se puede migrar');
            return { migrated: 0, errors: 0 };
        }

        console.log('🔄 Iniciando migración de promociones desde localStorage a Supabase...');
        
        const allKeys = Object.keys(localStorage);
        const promotionKeys = allKeys.filter(key => key.startsWith('promotions_'));
        
        let migrated = 0;
        let errors = 0;
        
        for (const key of promotionKeys) {
            const hotelId = key.replace('promotions_', '');
            const promos = JSON.parse(localStorage.getItem(key) || '[]');
            
            console.log(`📋 Migrando ${promos.length} promociones para hotel ${hotelId}...`);
            
            for (const promo of promos) {
                try {
                    await this.createPromotion({
                        hotelId: hotelId,
                        name: promo.name,
                        type: promo.type,
                        description: promo.description,
                        discount: promo.discount || 0,
                        promotionalPrice: promo.price || promo.promotionalPrice || null,
                        startDate: promo.startDate || promo.start_date,
                        endDate: promo.endDate || promo.end_date,
                        travelStartDate: promo.travelStartDate || promo.travel_start_date || null,
                        travelEndDate: promo.travelEndDate || promo.travel_end_date || null,
                        status: promo.status || 'active'
                    });
                    migrated++;
                } catch (error) {
                    console.error(`❌ Error migrando promoción ${promo.id}:`, error);
                    errors++;
                }
            }
        }
        
        console.log(`✅ Migración completada: ${migrated} promociones migradas, ${errors} errores`);
        return { migrated, errors };
    }

    // ============================================
    // SLIDER OFERTAS (Banners del Home - checkin24hs.com)
    // ============================================

    async getSliderOfertas() {
        if (!this.isInitialized()) return [];
        try {
            const { data, error } = await this.client
                .from('slider_ofertas')
                .select('*')
                .order('orden', { ascending: true });
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo slider_ofertas:', error);
            return [];
        }
    }

    async createSliderOferta(row) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { data, error } = await this.client
            .from('slider_ofertas')
            .insert([{
                titulo: row.titulo || null,
                texto_boton: row.texto_boton || null,
                imagen_url: row.imagen_url || '',
                imagen_url_mobile: row.imagen_url_mobile || null,
                link_destino: row.link_destino || null,
                tipo_link: row.tipo_link || 'url',
                orden: row.orden != null ? row.orden : 0,
                activo: row.activo !== false
            }])
            .select()
            .single();
        if (error) throw error;
        return data;
    }

    async updateSliderOferta(id, updates) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { data, error } = await this.client
            .from('slider_ofertas')
            .update({
                ...updates,
                updated_at: new Date().toISOString()
            })
            .eq('id', id)
            .select()
            .single();
        if (error) throw error;
        return data;
    }

    async deleteSliderOferta(id) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { error } = await this.client.from('slider_ofertas').delete().eq('id', id);
        if (error) throw error;
    }

    // ============================================
    // NOVEDADES (Feed web checkin24hs.com)
    // ============================================

    async getNovedades() {
        if (!this.isInitialized()) return [];
        try {
            const { data, error } = await this.client
                .from('novedades')
                .select('*')
                .order('fecha_publicacion', { ascending: false });
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo novedades:', error);
            return [];
        }
    }

    async createNovedad(row) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { data, error } = await this.client
            .from('novedades')
            .insert([{
                titulo: row.titulo || '',
                resumen: row.resumen || null,
                imagen_miniatura: row.imagen_miniatura || null,
                imagen_miniatura_mobile: row.imagen_miniatura_mobile || null,
                video_miniatura: row.video_miniatura || null,
                fecha_publicacion: row.fecha_publicacion || new Date().toISOString(),
                cuerpo_nota: row.cuerpo_nota || null,
                slug: row.slug || null,
                etiqueta_boton: row.etiqueta_boton != null ? row.etiqueta_boton : null
            }])
            .select()
            .single();
        if (error) throw error;
        return data;
    }

    async updateNovedad(id, updates) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { data, error } = await this.client
            .from('novedades')
            .update({
                ...updates,
                updated_at: new Date().toISOString()
            })
            .eq('id', id)
            .select()
            .single();
        if (error) throw error;
        return data;
    }

    async deleteNovedad(id) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { error } = await this.client.from('novedades').delete().eq('id', id);
        if (error) throw error;
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
            // Supabase es la fuente de verdad: no escribir en localStorage
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

    /**
     * Elimina todas las reservas (Supabase y localStorage).
     * Útil para vaciar y subir de nuevo mejor ordenadas.
     * @returns {{ deleted: number, error?: string }}
     */
    async deleteAllReservations() {
        if (!this.isInitialized()) {
            localStorage.removeItem('reservationsDB');
            console.log('💾 localStorage de reservas vaciado');
            return { deleted: 0 };
        }

        try {
            const { data: rows, error: selectError } = await this.client
                .from('reservations')
                .select('id');

            if (selectError) throw selectError;
            if (!rows || rows.length === 0) {
                localStorage.removeItem('reservationsDB');
                return { deleted: 0 };
            }

            const ids = rows.map(r => r.id);
            const BATCH = 100;
            let deleted = 0;

            for (let i = 0; i < ids.length; i += BATCH) {
                const chunk = ids.slice(i, i + BATCH);
                const { error: deleteError } = await this.client
                    .from('reservations')
                    .delete()
                    .in('id', chunk);

                if (deleteError) throw deleteError;
                deleted += chunk.length;
            }

            localStorage.removeItem('reservationsDB');
            console.log(`✅ ${deleted} reservas eliminadas`);
            return { deleted };
        } catch (error) {
            console.error('❌ Error vaciando reservas:', error);
            return { deleted: 0, error: error.message };
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
    
    // Función auxiliar para mapear datos de Supabase al formato del frontend
    mapQuoteFromSupabase(supabaseQuote) {
        if (!supabaseQuote) return null;
        // Spread primero: si después ponemos `hotel` explícito, no lo pisa un `hotel: null` venido de la fila SQL.
        const row = { ...supabaseQuote };
        return {
            ...row,
            id: supabaseQuote.id,
            code: supabaseQuote.code || null, // Código único
            clientName: supabaseQuote.customer_name || supabaseQuote.clientName || '',
            clientPhone: supabaseQuote.customer_phone || supabaseQuote.clientPhone || '',
            clientEmail: supabaseQuote.customer_email || supabaseQuote.clientEmail || '',
            hotelId: supabaseQuote.hotel_id || supabaseQuote.hotelId || null,
            // Priorizar hotel_name (cotizador web); la columna `hotel` a veces viene null y rompía el listado del dashboard
            hotel: supabaseQuote.hotels?.name || supabaseQuote.hotel_name || supabaseQuote.hotelName || supabaseQuote.hotel || '',
            checkIn: supabaseQuote.check_in || supabaseQuote.checkIn || null,
            checkOut: supabaseQuote.check_out || supabaseQuote.checkOut || null,
            adults: supabaseQuote.adults || 1,
            children: supabaseQuote.children || 0,
            infants: supabaseQuote.infants || 0,
            tariff: parseFloat(supabaseQuote.tariff || 0),
            discount: parseFloat(supabaseQuote.discount || 0),
            finalTariff: parseFloat(supabaseQuote.total || supabaseQuote.finalTariff || 0),
            status: supabaseQuote.status || 'pending',
            notes: supabaseQuote.notes || '',
            timestamp: supabaseQuote.created_at || supabaseQuote.timestamp || new Date().toISOString(),
            source: supabaseQuote.source || 'dashboard',
            origen: supabaseQuote.contact_origin || supabaseQuote.origen || null,
            contact_channel: supabaseQuote.contact_origin || supabaseQuote.contact_channel || null,
            selectedPromotionId: supabaseQuote.selected_promotion_id || supabaseQuote.selectedPromotionId || null,
            selectedPromotionName: supabaseQuote.selected_promotion_name || supabaseQuote.selectedPromotionName || null
        };
    }
    
    async getQuotes(filters = {}) {
        if (!this.isInitialized()) {
            return JSON.parse(localStorage.getItem('quotesDB') || '[]');
        }

        try {
            // Consulta simple sin JOIN a hotels para evitar statement timeout (hotel_name se resuelve después por quote)
            let query = this.client.from('quotes').select('*');
            if (filters.status) {
                query = query.eq('status', filters.status);
            }
            const { data, error } = await query.order('created_at', { ascending: false });
            
            if (error) throw error;
            
            // Mapear datos de Supabase al formato del frontend (hotel_name se resuelve por quote si falta)
            const mappedDataPromises = (data || []).map(async (quote) => {
                const mapped = this.mapQuoteFromSupabase(quote);
                
                // Si no hay nombre de hotel en el mapeo, intentar obtenerlo desde Supabase o localStorage
                if (!mapped.hotel || mapped.hotel.trim() === '') {
                    const hotelId = mapped.hotelId || mapped.hotel_id;
                    if (hotelId) {
                        // Primero intentar desde Supabase
                        try {
                            if (this.isInitialized()) {
                                const { data: hotelData, error: hotelError } = await this.client
                                    .from('hotels')
                                    .select('name, id')
                                    .eq('id', hotelId)
                                    .single();
                                
                                if (!hotelError && hotelData && hotelData.name) {
                                    mapped.hotel = hotelData.name;
                                    console.log(`✅ Hotel encontrado en Supabase para cotización ${mapped.code}:`, hotelData.name);
                                }
                            }
                        } catch (supabaseError) {
                            console.warn('⚠️ Error buscando hotel en Supabase:', supabaseError);
                        }
                        
                        // Si aún no hay hotel, intentar desde localStorage (solo lectura, no escritura)
                        if (!mapped.hotel || mapped.hotel.trim() === '') {
                            try {
                                const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
                                const hotel = hotels.find(h => h.id === hotelId || h.hotelId === hotelId);
                                if (hotel && hotel.name) {
                                    mapped.hotel = hotel.name;
                                    console.log(`✅ Hotel encontrado en localStorage para cotización ${mapped.code}:`, hotel.name);
                                } else {
                                    console.warn(`⚠️ Hotel no encontrado para cotización ${mapped.code}, hotelId:`, hotelId);
                                }
                            } catch (e) {
                                // Si localStorage está lleno, solo mostrar warning
                                if (e.name !== 'QuotaExceededError') {
                                    console.warn('⚠️ Error buscando hotel en localStorage:', e);
                                }
                            }
                        }
                    } else {
                        console.warn(`⚠️ Cotización ${mapped.code} no tiene hotelId`);
                    }
                }
                
                // Debug para cotizaciones específicas
                if (mapped.code === 'A93CP' || mapped.code === 'SJT66') {
                    console.log('🔍 DEBUG Supabase - Cotización', mapped.code, ':', {
                        rawFromSupabase: quote,
                        mapped: mapped,
                        selected_promotion_id: quote.selected_promotion_id,
                        selected_promotion_name: quote.selected_promotion_name,
                        mappedSelectedPromotionId: mapped.selectedPromotionId,
                        mappedSelectedPromotionName: mapped.selectedPromotionName
                    });
                }
                return mapped;
            });
            
            // Esperar a que todas las promesas se resuelvan
            const mappedData = await Promise.all(mappedDataPromises);
            // Supabase es la fuente de verdad: no escribir en localStorage
            return mappedData || [];
        } catch (error) {
            if (error.name === 'QuotaExceededError') {
                console.warn('⚠️ localStorage lleno al guardar cotizaciones. Mostrando datos desde caché si hay.');
            } else {
                console.error('❌ Error obteniendo cotizaciones:', error);
            }
            try {
                return JSON.parse(localStorage.getItem('quotesDB') || '[]');
            } catch (e) {
                return [];
            }
        }
    }

    async createQuote(quote) {
        if (!this.isInitialized()) {
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            quote.id = quote.id || 'quote-' + Date.now();
            quotes.push(quote);
            try {
                localStorage.setItem('quotesDB', JSON.stringify(quotes));
            } catch (storageError) {
                console.warn('⚠️ No se pudo guardar en localStorage (espacio lleno)');
            }
            return quote;
        }

        try {
            // Validar y ajustar código si es necesario (debe ser exactamente 5 caracteres)
            let quoteCode = quote.code || null;
            if (quoteCode && quoteCode.length !== 5) {
                console.warn(`⚠️ Código "${quoteCode}" tiene ${quoteCode.length} caracteres, debe tener exactamente 5. Truncando/ajustando...`);
                if (quoteCode.length > 5) {
                    quoteCode = quoteCode.substring(0, 5);
                } else {
                    // Si es menor a 5, rellenar con caracteres aleatorios
                    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
                    while (quoteCode.length < 5) {
                        quoteCode += chars.charAt(Math.floor(Math.random() * chars.length));
                    }
                }
                console.log(`✅ Código ajustado a: "${quoteCode}"`);
            }
            
            // Validar hotel_id: Supabase espera UUID; si viene el nombre (ej. "Corralco") no enviarlo como id
            const rawHotelId = quote.hotelId || quote.hotel_id || null;
            const isLikelyUuid = rawHotelId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(rawHotelId).trim());
            const hotelIdForDb = (rawHotelId && isLikelyUuid) ? rawHotelId : null;
            // Nombre del hotel que eligió el cliente (evita mostrar otro hotel por resolución errónea de hotel_id)
            let hotelNameForDb = (quote.hotel || quote.hotel_name || quote.hotelName || '').trim() || null;
            // Si el front solo mandó UUID y el nombre vino vacío (bug / versión vieja), resolver desde tabla hotels
            if (!hotelNameForDb && hotelIdForDb) {
                try {
                    const hotelRow = await this.getHotelById(hotelIdForDb);
                    if (hotelRow && hotelRow.name) {
                        hotelNameForDb = String(hotelRow.name).trim();
                        console.log('✅ hotel_name resuelto desde Supabase (hotels):', hotelNameForDb);
                    }
                } catch (e) {
                    console.warn('⚠️ No se pudo resolver hotel_name por hotel_id:', e && e.message ? e.message : e);
                }
            }

            // Mapear campos del frontend a Supabase
            // NOTA: Solo incluir columnas que existen en la tabla quotes de Supabase
            const quoteData = {
                code: quoteCode, // Código único de exactamente 5 caracteres
                customer_name: quote.clientName || quote.customer_name || null,
                customer_email: quote.clientEmail || quote.customer_email || null,
                customer_phone: quote.clientPhone || quote.customer_phone || null,
                hotel_id: hotelIdForDb,
                hotel_name: hotelNameForDb, // Guardar nombre elegido para mostrar correcto en detalle
                check_in: quote.checkIn || quote.check_in || null,
                check_out: quote.checkOut || quote.check_out || null,
                adults: quote.adults || 1,
                children: quote.children || 0,
                infants: quote.infants || 0,
                total: parseFloat(quote.finalTariff || quote.total || quote.tariff || 0),
                status: quote.status || 'Pendiente',
                notes: quote.notes || null,
                selected_promotion_id: quote.selectedPromotionId || quote.selected_promotion_id || null,
                selected_promotion_name: quote.selectedPromotionName || quote.selected_promotion_name || null,
                contact_origin: quote.origen || quote.contact_channel || quote.contact_origin || null
            };
            
            // Eliminar campos null/undefined/vacíos innecesarios
            Object.keys(quoteData).forEach(key => {
                if (quoteData[key] === undefined || quoteData[key] === null || quoteData[key] === '') {
                    // Mantener null solo para campos opcionales que pueden ser null
                    if (['code', 'customer_email', 'customer_phone', 'hotel_id', 'hotel_name', 'check_in', 'check_out', 'notes', 'selected_promotion_id', 'selected_promotion_name'].includes(key)) {
                        // Mantener null para estos campos opcionales
                    } else {
                        delete quoteData[key];
                    }
                }
            });
            
            // Asegurar que los campos requeridos tengan valores
            if (!quoteData.customer_name) quoteData.customer_name = 'Sin nombre';
            if (!quoteData.adults) quoteData.adults = 1;
            if (!quoteData.children) quoteData.children = 0;
            // Nota: infants puede no existir en la tabla, se manejará en el catch si falla
            if (quote.infants !== undefined && quote.infants !== null) {
                quoteData.infants = quote.infants;
            }
            if (!quoteData.total) quoteData.total = 0;
            if (!quoteData.status) quoteData.status = 'Pendiente';
            
            console.log('📤 Datos a insertar en Supabase:', quoteData);

            // Intentar insertar con infants primero
            let data, error;
            const result = await this.client
                .from('quotes')
                .insert([quoteData])
                .select()
                .single();
            
            data = result.data;
            error = result.error;
            
            // Si hay error relacionado con infants (schema cache desactualizado o columna no existe)
            if (error && (
                error.message && (
                    error.message.includes("infants") || 
                    error.message.includes("Could not find") ||
                    error.code === 'PGRST204'
                )
            )) {
                console.warn('⚠️ Error relacionado con columna "infants" (posible schema cache desactualizado). Intentando sin ese campo...', {
                    code: error.code,
                    message: error.message
                });
                
                const quoteDataWithoutInfants = { ...quoteData };
                delete quoteDataWithoutInfants.infants;
                
                const retryResult = await this.client
                    .from('quotes')
                    .insert([quoteDataWithoutInfants])
                    .select()
                    .single();
                
                data = retryResult.data;
                error = retryResult.error;
                
                if (!error) {
                    console.log('✅ Cotización insertada sin campo "infants" (el schema cache se actualizará automáticamente)');
                }
            }

            // Si hay error por columna hotel_name no existente, reintentar sin ella (ejecutar migración 021 después)
            if (error && error.message && (
                error.message.includes("hotel_name") ||
                (error.code === 'PGRST204' && quoteData.hotel_name != null)
            )) {
                console.warn('⚠️ Columna hotel_name no existe aún. Intentando insertar sin hotel_name. Ejecutá la migración 038_quotes_hotel_name.sql en Supabase.');
                const quoteDataWithoutHotelName = { ...quoteData };
                delete quoteDataWithoutHotelName.hotel_name;
                const retryResult = await this.client.from('quotes').insert([quoteDataWithoutHotelName]).select().single();
                data = retryResult.data;
                error = retryResult.error;
                if (!error) console.log('✅ Cotización insertada sin hotel_name (agregar columna con migración 021 para futuras).');
            }
            
            if (error) {
                console.error('❌ Error de Supabase al insertar cotización:', {
                    message: error.message,
                    code: error.code,
                    details: error.details,
                    hint: error.hint
                });
                throw error;
            }
            
            console.log('✅ Cotización insertada en Supabase:', data);
            
            // Mapear de vuelta a formato del frontend
            const mappedData = this.mapQuoteFromSupabase(data);
            
            // IMPORTANTE: Preservar campos de promoción del frontend si existen
            if (quote.selectedPromotionId || quote.selectedPromotionName) {
                mappedData.selectedPromotionId = quote.selectedPromotionId || mappedData.selectedPromotionId;
                mappedData.selectedPromotionName = quote.selectedPromotionName || mappedData.selectedPromotionName;
                console.log('✅ Preservando promoción del frontend:', {
                    id: mappedData.selectedPromotionId,
                    name: mappedData.selectedPromotionName
                });
            }
            
            // IMPORTANTE: Preservar campo de infantes del frontend si existe
            if (quote.infants !== undefined && quote.infants !== null) {
                mappedData.infants = quote.infants;
                console.log('✅ Preservando infantes del frontend:', mappedData.infants);
            }
            
            // Sincronizar con localStorage (mantener formato del frontend)
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            // Combinar datos originales del frontend con los de Supabase, preservando campos del frontend
            const finalQuote = { 
                ...mappedData, 
                ...quote, // Los datos del frontend tienen prioridad
                id: data.id,
                // Asegurar que los campos de promoción se preserven
                selectedPromotionId: quote.selectedPromotionId || mappedData.selectedPromotionId || null,
                selectedPromotionName: quote.selectedPromotionName || mappedData.selectedPromotionName || null,
                // Asegurar que los infantes se preserven
                infants: quote.infants !== undefined && quote.infants !== null ? quote.infants : (mappedData.infants || 0)
            };
            
            console.log('📋 Cotización final combinada:', {
                code: finalQuote.code,
                selectedPromotionId: finalQuote.selectedPromotionId,
                selectedPromotionName: finalQuote.selectedPromotionName,
                infants: finalQuote.infants
            });
            
            quotes.push(finalQuote);
            try {
                localStorage.setItem('quotesDB', JSON.stringify(quotes));
            } catch (storageError) {
                console.warn('⚠️ No se pudo guardar en localStorage (espacio lleno), pero la cotización se guardó en Supabase');
            }
            
            return finalQuote;
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
                try {
                    localStorage.setItem('quotesDB', JSON.stringify(quotes));
                } catch (storageError) {
                    console.warn('⚠️ No se pudo guardar en localStorage (espacio lleno)');
                }
                return quotes[index];
            }
            return null;
        }

        try {
            // No enviar final_tariff a Supabase (la tabla tiene "total"); filtrar por si el dashboard lo manda
            const safeUpdates = { ...updates };
            delete safeUpdates.final_tariff;
            // Mapear campos del frontend a Supabase para updates
            const updateData = {};
            if (safeUpdates.code !== undefined) updateData.code = safeUpdates.code;
            if (safeUpdates.clientName !== undefined) updateData.customer_name = safeUpdates.clientName;
            if (safeUpdates.clientPhone !== undefined) updateData.customer_phone = safeUpdates.clientPhone;
            if (safeUpdates.clientEmail !== undefined) updateData.customer_email = safeUpdates.clientEmail;
            if (safeUpdates.hotelId !== undefined) updateData.hotel_id = safeUpdates.hotelId;
            if (safeUpdates.checkIn !== undefined) updateData.check_in = safeUpdates.checkIn;
            if (safeUpdates.checkOut !== undefined) updateData.check_out = safeUpdates.checkOut;
            if (safeUpdates.adults !== undefined) updateData.adults = safeUpdates.adults;
            if (safeUpdates.children !== undefined) updateData.children = safeUpdates.children;
            if (safeUpdates.infants !== undefined) updateData.infants = safeUpdates.infants;
            // No enviar tariff: la tabla quotes puede no tener esa columna (solo total)
            if (safeUpdates.finalTariff !== undefined) updateData.total = safeUpdates.finalTariff;
            if (safeUpdates.status !== undefined) updateData.status = safeUpdates.status;
            if (safeUpdates.notes !== undefined) updateData.notes = safeUpdates.notes;
            if (safeUpdates.selectedPromotionId !== undefined) updateData.selected_promotion_id = safeUpdates.selectedPromotionId;
            if (safeUpdates.selectedPromotionName !== undefined) updateData.selected_promotion_name = safeUpdates.selectedPromotionName;
            if (safeUpdates.sentAt !== undefined) updateData.sent_at = safeUpdates.sentAt;
            const origin = safeUpdates.origen ?? safeUpdates.contact_channel ?? safeUpdates.contact_origin;
            if (origin !== undefined) updateData.contact_origin = origin;
            
            // Agregar solo columnas snake_case que existan en la tabla (evitar 400 por columnas inexistentes)
            const allowedExtra = ['room_type', 'program', 'client_note', 'sent_at'];
            Object.keys(safeUpdates).forEach(key => {
                if (key.includes('_') && !updateData[key] && allowedExtra.includes(key)) {
                    updateData[key] = safeUpdates[key];
                }
            });
            
            updateData.updated_at = new Date().toISOString();

            const { data, error } = await this.client
                .from('quotes')
                .update(updateData)
                .eq('id', id)
                .select()
                .single();
            
            if (error) throw error;
            
            // Mapear de vuelta a formato del frontend
            const mappedData = this.mapQuoteFromSupabase(data);
            
            // Sincronizar con localStorage
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            const index = quotes.findIndex(q => q.id === id);
            if (index !== -1) {
                quotes[index] = { ...quotes[index], ...mappedData };
                try {
                    localStorage.setItem('quotesDB', JSON.stringify(quotes));
                } catch (storageError) {
                    console.warn('⚠️ No se pudo guardar en localStorage (espacio lleno), pero la cotización se actualizó en Supabase');
                }
            }
            
            return mappedData;
        } catch (error) {
            console.error('❌ Error actualizando cotización:', error);
            throw error;
        }
    }

    async deleteQuote(id) {
        if (!this.isInitialized()) {
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            const filtered = quotes.filter(q => q.id !== id);
            try {
                localStorage.setItem('quotesDB', JSON.stringify(filtered));
            } catch (storageError) {
                console.warn('⚠️ No se pudo guardar en localStorage (espacio lleno)');
            }
            return true;
        }

        try {
            const { error } = await this.client
                .from('quotes')
                .delete()
                .eq('id', id);
            
            if (error) throw error;
            
            // Sincronizar con localStorage
            const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
            const filtered = quotes.filter(q => q.id !== id);
            try {
                localStorage.setItem('quotesDB', JSON.stringify(filtered));
            } catch (storageError) {
                console.warn('⚠️ No se pudo guardar en localStorage (espacio lleno)');
            }
            
            return true;
        } catch (error) {
            console.error('❌ Error eliminando cotización:', error);
            throw error;
        }
    }

    async deleteAllQuotes() {
        console.log('🗑️ Eliminando todas las cotizaciones de Supabase...');
        
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no inicializado');
            return false;
        }
        
        try {
            // Obtener todas las cotizaciones primero
            const { data: allQuotes, error: fetchError } = await this.client
                .from('quotes')
                .select('id');
            
            if (fetchError) {
                console.warn('⚠️ Error obteniendo cotizaciones:', fetchError);
                // Intentar eliminar directamente
            }
            
            // Eliminar todas las cotizaciones
            const { error } = await this.client
                .from('quotes')
                .delete()
                .neq('id', '00000000-0000-0000-0000-000000000000'); // Condición que siempre es verdadera para eliminar todas
            
            if (error) {
                // Si falla, intentar eliminar una por una
                if (allQuotes && allQuotes.length > 0) {
                    console.log(`🔄 Eliminando ${allQuotes.length} cotizaciones una por una...`);
                    for (const quote of allQuotes) {
                        try {
                            await this.client
                                .from('quotes')
                                .delete()
                                .eq('id', quote.id);
                        } catch (e) {
                            console.warn(`⚠️ Error eliminando cotización ${quote.id}:`, e);
                        }
                    }
                    console.log('✅ Todas las cotizaciones eliminadas de Supabase (una por una)');
                } else {
                    throw error;
                }
            } else {
                console.log('✅ Todas las cotizaciones eliminadas de Supabase');
            }
            
            return true;
        } catch (error) {
            console.error('❌ Error eliminando cotizaciones de Supabase:', error);
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
            // Supabase es la fuente de verdad: no escribir en localStorage
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
                    console.log('📋 Datos de la cotización:', payload.new || payload.old);
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
            // Supabase es la fuente de verdad: no escribir en localStorage
            return data || [];
        } catch (error) {
            if (error.name === 'QuotaExceededError') {
                console.warn('⚠️ localStorage lleno al obtener usuarios. Usando caché si hay.');
            } else {
                console.error('❌ Error obteniendo usuarios:', error);
            }
            try {
                return JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
            } catch (e) {
                return [];
            }
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
    // CHATS DE WHATSAPP (solo lectura desde Supabase; no se usa localStorage)
    // ============================================
    
    async getWhatsAppChats(limit = 50) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        try {
            // Intentar obtener chats con ordenamiento
            let query = this.client
                .from('whatsapp_chats')
                .select('*')
                .limit(limit);
            
            // Intentar ordenar por last_message_time si existe
            try {
                query = query.order('last_message_time', { ascending: false });
            } catch (e) {
                // Si falla el ordenamiento, continuar sin ordenar
                console.log('ℹ️ No se pudo ordenar por last_message_time, continuando sin ordenar');
            }

            let { data, error } = await query;

            // Si hay error 400 o la tabla no existe, intentar sin ordenamiento
            if (error && (error.code === 'PGRST116' || error.status === 400 || error.message?.includes('does not exist') || error.message?.includes('column'))) {
                console.log('ℹ️ Error con ordenamiento, intentando sin ordenar...');
                const simpleQuery = this.client
                    .from('whatsapp_chats')
                    .select('*')
                    .limit(limit);
                
                const result = await simpleQuery;
                if (result.error) {
                    // Si aún falla, la tabla probablemente no existe
                    if (result.error.code === 'PGRST116' || result.error.message?.includes('does not exist')) {
                        console.log('ℹ️ Tabla whatsapp_chats no existe aún en Supabase');
                        return [];
                    }
                    throw result.error;
                }
                data = result.data;
                error = result.error;
            } else if (error) {
                console.error('❌ Error obteniendo chats:', error);
                // Si es un error 400, probablemente la tabla no existe o tiene estructura diferente
                if (error.status === 400) {
                    console.log('ℹ️ Error 400: La tabla whatsapp_chats puede no existir o tener estructura diferente');
                    return [];
                }
                throw error;
            }

            console.log(`📱 ${data?.length || 0} chats de WhatsApp cargados desde Supabase`);
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo chats:', error);
            // En caso de cualquier error, retornar array vacío para no romper la aplicación
            return [];
        }
    }

    async getWhatsAppMessages(chatId, limit = 100) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        try {
            // Pedir los N más RECIENTES (desc), luego invertir para mostrar cronológico. Así no se cortan los mensajes nuevos.
            let { data, error } = await this.client
                .from('whatsapp_messages')
                .select('*')
                .eq('chat_id', chatId)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error && (error.message?.includes('chat_id') || error.message?.includes('column') || error.code === '42703')) {
                const fallback = await this.client
                    .from('whatsapp_messages')
                    .select('*')
                    .eq('conversation_id', chatId)
                    .order('created_at', { ascending: false })
                    .limit(limit);
                if (!fallback.error) {
                    data = fallback.data || [];
                    error = null;
                }
            }
            // Si no hubo error pero 0 mensajes, intentar por conversation_id (por si los mensajes se guardaron solo con esa columna)
            if (!error && (!data || data.length === 0) && chatId) {
                const resConv = await this.client
                    .from('whatsapp_messages')
                    .select('*')
                    .eq('conversation_id', chatId)
                    .order('created_at', { ascending: false })
                    .limit(limit);
                if (!resConv.error && resConv.data && resConv.data.length > 0) {
                    data = resConv.data;
                    console.log('📥 Mensajes obtenidos por conversation_id:', data.length);
                }
            }

            if (error) throw error;
            // Devolver en orden cronológico (más antiguo primero) para que el panel los muestre bien
            if (data && data.length > 0) data = data.reverse();

            // Marcar como leídos y resetear unread (no bloquear la respuesta si fallan)
            try {
                await this.client
                    .from('whatsapp_messages')
                    .update({ is_read: true })
                    .eq('chat_id', chatId)
                    .eq('is_from_me', false);
            } catch (e) {
                try {
                    await this.client
                        .from('whatsapp_messages')
                        .update({ is_read: true })
                        .eq('conversation_id', chatId)
                        .eq('is_from_me', false);
                } catch (e2) {
                    console.warn('⚠️ No se pudo marcar mensajes como leídos:', e?.message || e2?.message);
                }
            }
            try {
                await this.client
                    .from('whatsapp_chats')
                    .update({ unread_count: 0 })
                    .eq('id', chatId);
            } catch (e) {
                console.warn('⚠️ No se pudo actualizar unread_count del chat:', e?.message || e);
            }

            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo mensajes:', error);
            return [];
        }
    }

    /**
     * Obtener mensajes por phone (ej. web_abc123). Útil para chats canal cuando chat_id no devuelve resultados.
     */
    async getWhatsAppMessagesByPhone(phone, limit = 100) {
        if (!this.isInitialized() || !phone) return [];
        try {
            let { data, error } = await this.client
                .from('whatsapp_messages')
                .select('*')
                .eq('phone', String(phone))
                .order('created_at', { ascending: false })
                .limit(limit);
            if (error) throw error;
            if (data && data.length > 0) data = data.reverse();
            return data || [];
        } catch (e) {
            console.warn('⚠️ getWhatsAppMessagesByPhone:', e?.message || e);
            return [];
        }
    }

    // Suscribirse a nuevos mensajes de WhatsApp
    subscribeToWhatsAppMessages(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return null;
        }

        if (!this.activeSubscriptions) {
            this.activeSubscriptions = {};
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

        if (!this.activeSubscriptions) {
            this.activeSubscriptions = {};
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

    /**
     * Actualizar el número de teléfono real de un chat (para mostrar en el dashboard cuando el chat usa LID).
     * @param {string} chatId - UUID del chat en whatsapp_chats
     * @param {string} realPhone - Número real (ej. +54 9 2944 57-9759 o 5492944579759)
     */
    async updateWhatsAppChatRealPhone(chatId, realPhone) {
        if (!this.isInitialized() || !chatId) return null;
        const normalized = String(realPhone || '').replace(/\D/g, '').trim();
        if (!normalized || normalized.length < 10) return null;
        try {
            const { data, error } = await this.client
                .from('whatsapp_chats')
                .update({ real_phone: normalized, updated_at: new Date().toISOString() })
                .eq('id', chatId)
                .select()
                .single();
            if (error) throw error;
            console.log('✅ Número real actualizado para chat:', chatId, '→', normalized);
            return data;
        } catch (e) {
            console.error('❌ Error actualizando real_phone:', e?.message || e);
            return null;
        }
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

    // Guardar una nueva interacción de Flor
    async saveFlorInteraction(interactionData) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, guardando en localStorage');
            const interactions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
            const newInteraction = {
                id: 'inter-' + Date.now(),
                ...interactionData,
                created_at: new Date().toISOString()
            };
            interactions.push(newInteraction);
            localStorage.setItem('flor_interactions', JSON.stringify(interactions));
            return newInteraction;
        }

        try {
            const interaction = {
                user_message: interactionData.userMessage || interactionData.user_message || '',
                bot_response: interactionData.botResponse || interactionData.bot_response || '',
                intent: interactionData.intent || 'consulta_general',
                phone: interactionData.phone || null,
                email: interactionData.email || null,
                success: interactionData.success !== false,
                used_ai: interactionData.usedAI || interactionData.used_ai || true,
                hotel_id: interactionData.hotelId || interactionData.hotel_id || null,
                metadata: interactionData.metadata || {}
            };

            const { data, error } = await this.client
                .from('flor_interactions')
                .insert([interaction])
                .select()
                .single();

            if (error) throw error;

            console.log('✅ Interacción guardada en Supabase:', data.id);
            
            // Sincronizar con localStorage como backup
            const interactions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
            interactions.push(data);
            localStorage.setItem('flor_interactions', JSON.stringify(interactions));
            
            return data;
        } catch (error) {
            console.error('❌ Error guardando interacción:', error);
            // Fallback a localStorage
            const interactions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
            const newInteraction = {
                id: 'inter-' + Date.now(),
                ...interactionData,
                created_at: new Date().toISOString()
            };
            interactions.push(newInteraction);
            localStorage.setItem('flor_interactions', JSON.stringify(interactions));
            return newInteraction;
        }
    }

    // Analizar interacciones para aprendizaje
    async analyzeFlorInteractions(limit = 100) {
        if (!this.isInitialized()) {
            const interactions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
            return this.analyzeInteractionsLocal(interactions);
        }

        try {
            const { data, error } = await this.client
                .from('flor_interactions')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;

            return this.analyzeInteractionsLocal(data || []);
        } catch (error) {
            console.error('❌ Error analizando interacciones:', error);
            const interactions = JSON.parse(localStorage.getItem('flor_interactions') || '[]');
            return this.analyzeInteractionsLocal(interactions);
        }
    }

    // Análisis local de interacciones
    analyzeInteractionsLocal(interactions) {
        const analysis = {
            total: interactions.length,
            successful: 0,
            failed: 0,
            intents: {},
            commonWords: {},
            averageResponseTime: 0,
            mostCommonQuestions: [],
            improvementSuggestions: []
        };

        interactions.forEach(inter => {
            // Contar éxitos
            if (inter.success !== false) {
                analysis.successful++;
            } else {
                analysis.failed++;
            }

            // Contar intents
            const intent = inter.intent || 'consulta_general';
            analysis.intents[intent] = (analysis.intents[intent] || 0) + 1;

            // Extraer palabras comunes del mensaje del usuario
            const userMessage = (inter.user_message || inter.userMessage || '').toLowerCase();
            const words = userMessage.split(/\s+/).filter(w => w.length > 3);
            words.forEach(word => {
                analysis.commonWords[word] = (analysis.commonWords[word] || 0) + 1;
            });

            // Preguntas más comunes
            if (userMessage.includes('?')) {
                analysis.mostCommonQuestions.push(userMessage);
            }
        });

        // Ordenar palabras comunes
        analysis.commonWords = Object.entries(analysis.commonWords)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 20)
            .reduce((obj, [word, count]) => {
                obj[word] = count;
                return obj;
            }, {});

        // Preguntas más comunes
        const questionCounts = {};
        analysis.mostCommonQuestions.forEach(q => {
            questionCounts[q] = (questionCounts[q] || 0) + 1;
        });
        analysis.mostCommonQuestions = Object.entries(questionCounts)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 10)
            .map(([question, count]) => ({ question, count }));

        // Sugerencias de mejora
        if (analysis.failed > analysis.successful * 0.3) {
            analysis.improvementSuggestions.push('Tasa de éxito baja. Revisar respuestas para intents más comunes.');
        }
        if (Object.keys(analysis.intents).length > 10) {
            analysis.improvementSuggestions.push('Muchos intents diferentes. Considerar agrupar intents similares.');
        }

        return analysis;
    }
}

// Crear instancia global
window.supabaseClient = new SupabaseClient();

// Exportar para uso en módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SupabaseClient;
}

