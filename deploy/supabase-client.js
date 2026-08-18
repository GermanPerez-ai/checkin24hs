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
        const includeInactive = opts.includeInactive === true;

        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, usando localStorage como fallback');
            const raw = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            return includeInactive ? raw : this._filterActiveHotels(raw);
        }

        const light = opts.light !== false; // por defecto true para evitar statement timeout
        const selectColumns = light
            ? 'id,name,location,status,google_maps,website,rating,price,description,amenities,coordinates,created_at,updated_at,pais,region,tipo_producto,mostrar_como_hotel,mostrar_como_paquete,elegido_del_mes,pack_elegido_del_mes,precio_desde'
            : '*';

        try {
            let query = this.client
                .from('hotels')
                .select(selectColumns);
            if (!includeInactive) {
                query = query.or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null');
            }
            const { data, error } = await query.order('created_at', { ascending: false });

            if (error) throw error;

            // Supabase es la fuente de verdad: no escribir en localStorage para evitar llenar cuota
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo hoteles:', error);
            try {
                const raw = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
                return includeInactive ? raw : this._filterActiveHotels(raw);
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
    // TESTIMONIOS (Home web checkin24hs.com)
    // ============================================

    async getTestimonios() {
        if (!this.isInitialized()) return [];
        try {
            const { data, error } = await this.client
                .from('testimonios')
                .select('*')
                .order('orden', { ascending: true })
                .order('created_at', { ascending: false });
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo testimonios:', error);
            return [];
        }
    }

    async createTestimonio(row) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { data, error } = await this.client
            .from('testimonios')
            .insert([{
                nombre: row.nombre || '',
                texto: row.texto || '',
                fuente: row.fuente || 'instagram',
                estrellas: row.estrellas != null ? Number(row.estrellas) : 5,
                avatar_url: row.avatar_url || null,
                enlace_url: row.enlace_url || null,
                activo: row.activo !== false,
                orden: row.orden != null ? Number(row.orden) : 0
            }])
            .select()
            .single();
        if (error) throw error;
        return data;
    }

    async updateTestimonio(id, updates) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { data, error } = await this.client
            .from('testimonios')
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

    async deleteTestimonio(id) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { error } = await this.client.from('testimonios').delete().eq('id', id);
        if (error) throw error;
    }

    // ============================================
    // NEWSLETTER (suscriptores web)
    // ============================================

    async getNewsletterSubscribers() {
        if (!this.isInitialized()) return [];
        try {
            const { data, error } = await this.client
                .from('newsletter_subscribers')
                .select('*')
                .order('created_at', { ascending: false });
            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo newsletter:', error);
            return [];
        }
    }

    async deleteNewsletterSubscriber(id) {
        if (!this.isInitialized()) throw new Error('Supabase no inicializado');
        const { error } = await this.client.from('newsletter_subscribers').delete().eq('id', id);
        if (error) throw error;
    }

    async getSitePageStats(fromIso, toIso) {
        if (!this.isInitialized()) return null;
        const { data, error } = await this.client.rpc('site_page_stats', {
            p_from: fromIso,
            p_to: toIso,
        });
        if (error) throw error;
        return data || { pageviews: 0, visitors: 0, top_pages: [], top_utm: [], recent: [] };
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
            try {
                await this.upsertUser({
                    name: data.client_name || data.customer_name || reservationToCreate.client_name,
                    email: data.client_email || data.customer_email || reservationToCreate.client_email,
                    phone: data.client_phone || data.customer_phone || reservationToCreate.client_phone,
                    hotel_id: data.hotel_id || reservationToCreate.hotel_id,
                    hotel_name: data.hotel_name || reservationToCreate.hotel_name
                });
            } catch (userErr) {
                console.warn('⚠️ Reserva OK, no se pudo actualizar hotel de interés del usuario:', userErr?.message || userErr);
            }
            
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

    _removeRealtimeChannel(key) {
        const ch = this.activeSubscriptions[key];
        if (!ch) return;
        try {
            this.client.removeChannel(ch);
        } catch (e) { /* ignore */ }
        delete this.activeSubscriptions[key];
    }

    subscribeToReservations(callback) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, no se pueden usar suscripciones en tiempo real');
            return null;
        }

        this._removeRealtimeChannel('reservations');
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

        this._removeRealtimeChannel('quotes');
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

        this._removeRealtimeChannel('hotels');
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

        this._removeRealtimeChannel('users');
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

        this._removeRealtimeChannel('expenses');
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

        this._removeRealtimeChannel('agents');
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

    /** Conteo exacto (no recorta en 1000). PostgREST head+count. */
    async countExact(table, applyFilters) {
        if (!this.isInitialized()) return 0;
        try {
            let q = this.client.from(table).select('id', { count: 'exact', head: true });
            if (typeof applyFilters === 'function') q = applyFilters(q);
            const { count, error } = await q;
            if (error) throw error;
            return count || 0;
        } catch (error) {
            console.warn('⚠️ countExact', table, error?.message || error);
            return 0;
        }
    }

    /** Inicio del mes calendario en Argentina (UTC-3). */
    getArgentinaMonthStartIso() {
        const parts = new Intl.DateTimeFormat('en-CA', {
            timeZone: 'America/Argentina/Buenos_Aires',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).formatToParts(new Date());
        const get = (t) => parts.find((p) => p.type === t)?.value;
        return `${get('year')}-${get('month')}-01T00:00:00.000-03:00`;
    }

    /** Totales reales para las tarjetas de Gestión de Usuarios. */
    async getUsersDashboardStats() {
        const empty = { totalUsers: 0, newThisMonth: 0, totalQuotes: 0, avgRating: null };
        if (!this.isInitialized()) return empty;
        const monthStart = this.getArgentinaMonthStartIso();
        try {
            const [totalUsers, newThisMonth, totalQuotes] = await Promise.all([
                this.countExact('users'),
                this.countExact('users', (q) => q.gte('created_at', monthStart)),
                this.countExact('quotes')
            ]);
            let avgRating = null;
            const { data: hotels, error: hotelErr } = await this.client
                .from('hotels')
                .select('rating,puntuacion_num');
            if (!hotelErr && hotels && hotels.length) {
                const vals = hotels
                    .map((h) => Number(h.puntuacion_num != null ? h.puntuacion_num : h.rating))
                    .filter((n) => Number.isFinite(n) && n > 0);
                if (vals.length) {
                    avgRating = vals.reduce((a, b) => a + b, 0) / vals.length;
                }
            }
            return { totalUsers, newThisMonth, totalQuotes, avgRating };
        } catch (error) {
            console.warn('⚠️ getUsersDashboardStats:', error?.message || error);
            return empty;
        }
    }
    
    async getUsers() {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado, usando localStorage como fallback');
            return JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        }

        try {
            const pageSize = 1000;
            let from = 0;
            const all = [];
            for (;;) {
                const { data, error } = await this.client
                    .from('users')
                    .select('*')
                    .order('last_activity', { ascending: false, nullsFirst: false })
                    .order('created_at', { ascending: false })
                    .range(from, from + pageSize - 1);
                if (error) throw error;
                const batch = data || [];
                all.push(...batch);
                if (batch.length < pageSize) break;
                from += pageSize;
                if (from >= 100000) break;
            }
            console.log(`☁️ Usuarios cargados de Supabase: ${all.length} registros`);
            return all;
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

    async recordUserHotelInterest(userId, hotelId, options = {}) {
        if (!this.isInitialized() || !userId || !hotelId) return false;
        const phone = options.phone || null;
        const source = options.source || 'reserva';
        const nowIso = new Date().toISOString();
        try {
            const { error } = await this.client.rpc('record_user_hotel_interest', {
                p_user_id: userId,
                p_hotel_id: hotelId,
                p_phone: phone,
                p_instance: options.instance || null,
                p_source: source
            });
            if (!error) return true;
            const { data: existing } = await this.client
                .from('user_hotel_interests')
                .select('id, interest_count')
                .eq('user_id', userId)
                .eq('hotel_id', hotelId)
                .limit(1);
            const row = existing && existing[0];
            if (row?.id) {
                await this.client.from('user_hotel_interests').update({
                    interest_count: (row.interest_count || 1) + 1,
                    last_interest_at: nowIso,
                    phone: phone || undefined,
                    source
                }).eq('id', row.id);
            } else {
                await this.client.from('user_hotel_interests').insert({
                    user_id: userId,
                    hotel_id: hotelId,
                    phone,
                    source,
                    interest_count: 1,
                    first_interest_at: nowIso,
                    last_interest_at: nowIso
                });
            }
            await this.client.from('users').update({
                last_hotel_id: hotelId,
                last_activity: nowIso,
                updated_at: nowIso
            }).eq('id', userId);
            return true;
        } catch (err) {
            console.warn('⚠️ recordUserHotelInterest:', err?.message || err);
            return false;
        }
    }

    // Crear o actualizar usuario (upsert con lógica de deduplicación)
    async upsertUser(userData) {
        const email = userData.email?.trim().toLowerCase() || '';
        const phone = userData.phone?.trim() || '';
        const name = userData.name?.trim() || '';
        const hotelId = userData.hotel_id || userData.hotelId || null;
        
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
            let saved = existingUser;
            
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
                if (hotelId) updates.last_hotel_id = hotelId;
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
                    saved = data;
                } else {
                    console.log('ℹ️ Usuario ya existe, sin cambios necesarios:', existingUser.id);
                }
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
                if (hotelId) newUser.last_hotel_id = hotelId;
                
                const { data, error } = await this.client
                    .from('users')
                    .insert([newUser])
                    .select()
                    .single();
                
                if (error) throw error;
                
                console.log('✅ Nuevo usuario creado en Supabase:', data.id);
                saved = data;
            }
            if (saved?.id && hotelId) {
                await this.recordUserHotelInterest(saved.id, hotelId, { phone, source: 'reserva' });
            }
            return saved;
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
    
    async getWhatsAppChats(limit = null) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        const PAGE_SIZE = 500;
        const fetchAll = limit == null || limit <= 0;

        const fetchPage = async (from, to) => {
            let query = this.client
                .from('whatsapp_chats')
                .select('*')
                .order('last_message_time', { ascending: false });
            if (fetchAll) {
                query = query.range(from, to);
            } else {
                query = query.limit(limit);
            }
            return query;
        };

        const fetchPageSimple = async (from, to) => {
            let query = this.client.from('whatsapp_chats').select('*');
            if (fetchAll) {
                query = query.range(from, to);
            } else {
                query = query.limit(limit);
            }
            return query;
        };

        try {
            const all = [];
            let offset = 0;

            while (true) {
                const from = offset;
                const to = offset + PAGE_SIZE - 1;
                let { data, error } = await fetchPage(from, to);

                if (error && (error.code === 'PGRST116' || error.status === 400 || error.message?.includes('does not exist') || error.message?.includes('column'))) {
                    console.log('ℹ️ Error con ordenamiento, intentando sin ordenar...');
                    const result = await fetchPageSimple(from, to);
                    if (result.error) {
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
                    if (error.status === 400) {
                        console.log('ℹ️ Error 400: La tabla whatsapp_chats puede no existir o tener estructura diferente');
                        return [];
                    }
                    throw error;
                }

                const batch = data || [];
                all.push(...batch);

                if (!fetchAll || batch.length < PAGE_SIZE) break;
                offset += PAGE_SIZE;
            }

            console.log(`📱 ${all.length} chats de WhatsApp cargados desde Supabase${fetchAll ? ' (todos)' : ''}`);
            return all;
        } catch (error) {
            console.error('❌ Error obteniendo chats:', error);
            return [];
        }
    }

    async getWhatsAppMessages(chatId, limit = 100, options = {}) {
        if (!this.isInitialized()) {
            console.warn('⚠️ Supabase no está inicializado');
            return [];
        }

        const skipMarkRead = !!(options && options.skipMarkRead);

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

            if (!skipMarkRead) {
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
            }

            return data || [];
        } catch (error) {
            console.error('❌ Error obteniendo mensajes:', error);
            return [];
        }
    }

    /**
     * Mensajes de varios chat_id (mismo contacto duplicado en whatsapp_chats). Deduplica por id de mensaje.
     */
    async getWhatsAppMessagesForChatIds(chatIds, limit = 200, options = {}) {
        const ids = [...new Set((chatIds || []).map(String).filter(Boolean))];
        if (!ids.length) return [];
        if (!this.isInitialized()) return [];
        const perChat = Math.max(50, Math.ceil(limit / Math.max(ids.length, 1)));
        const byMsgId = new Map();
        const skipMarkRead = !!(options && options.skipMarkRead);
        for (let i = 0; i < ids.length; i++) {
            const id = ids[i];
            const opts = { skipMarkRead: skipMarkRead || i > 0 };
            const msgs = await this.getWhatsAppMessages(id, perChat, opts);
            for (const m of msgs) {
                if (m && m.id != null) byMsgId.set(String(m.id), m);
            }
        }
        let merged = [...byMsgId.values()].sort((a, b) => new Date(a.created_at || 0) - new Date(b.created_at || 0));
        if (merged.length > limit) merged = merged.slice(-limit);
        return merged;
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

    /**
     * Eliminar un chat de whatsapp_chats (los mensajes se borran por CASCADE en chat_id).
     */
    async deleteWhatsAppChat(chatId) {
        if (!this.isInitialized() || !chatId) return false;
        try {
            try {
                await this.client.from('whatsapp_conversations').delete().eq('id', chatId);
            } catch (e) { /* tabla opcional */ }
            const { error } = await this.client
                .from('whatsapp_chats')
                .delete()
                .eq('id', chatId);
            if (error) throw error;
            console.log('✅ Chat eliminado:', chatId);
            return true;
        } catch (e) {
            console.error('❌ Error eliminando chat:', e?.message || e);
            return false;
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

    // ============================================
    // PROGRAMA FLEXI (vouchers / canjes)
    // ============================================

    _isUuid(v) {
        return v && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(v).trim());
    }

    /** Fecha YYYY-MM-DD o null; nunca '' (Postgres rechaza ''::date y PostgREST devuelve 400). */
    _flexiDateOptional(val) {
        if (val == null) return null;
        const s = String(val).trim();
        if (!s) return null;
        if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
        const t = Date.parse(s);
        if (!Number.isNaN(t)) return new Date(t).toISOString().slice(0, 10);
        return null;
    }

    /** flexi_programs.fecha_inicio / fecha_fin son NOT NULL */
    _flexiProgramDates(p) {
        const today = new Date().toISOString().slice(0, 10);
        let fi = this._flexiDateOptional(p.fechaInicio || p.fecha_inicio);
        let ff = this._flexiDateOptional(p.fechaFin || p.fecha_fin);
        if (!fi && ff) fi = ff;
        if (!ff && fi) ff = fi;
        if (!fi && !ff) {
            fi = today;
            ff = today;
        } else if (!fi) fi = ff;
        else if (!ff) ff = fi;
        if (fi > ff) {
            const x = fi;
            fi = ff;
            ff = x;
        }
        return { fecha_inicio: fi, fecha_fin: ff };
    }

    _flexiProgramToRow(p) {
        const hid = p.hotelId || p.hotel_id;
        const d = this._flexiProgramDates(p);
        return {
            id: String(p.id),
            hotel_id: this._isUuid(hid) ? String(hid).trim() : null,
            hotel_name: p.hotelName || p.hotel_name || '',
            cupos_por_voucher: parseInt(p.cuposPorVoucher || p.cupos_por_voucher, 10) || 0,
            precio_usd: parseFloat(p.precioUSD ?? p.precio_usd ?? 0) || 0,
            fecha_inicio: d.fecha_inicio,
            fecha_fin: d.fecha_fin,
            descripcion: p.descripcion || null,
            estado: p.estado || 'Activo',
            fecha_creacion: p.fechaCreacion || p.fecha_creacion || new Date().toISOString(),
            updated_at: new Date().toISOString()
        };
    }

    _flexiProgramFromRow(r) {
        if (!r) return null;
        return {
            id: r.id,
            hotelId: r.hotel_id,
            hotelName: r.hotel_name,
            cuposPorVoucher: r.cupos_por_voucher,
            precioUSD: parseFloat(r.precio_usd),
            fechaInicio: r.fecha_inicio,
            fechaFin: r.fecha_fin,
            descripcion: r.descripcion || '',
            estado: r.estado,
            fechaCreacion: r.fecha_creacion
        };
    }

    _flexiVoucherToRow(v) {
        const hid = v.hotelId || v.hotel_id;
        let cap = v.capturaPagoUrl != null ? String(v.capturaPagoUrl) : (v.captura_pago_url != null ? String(v.captura_pago_url) : null);
        if (cap && cap.length > 120000) cap = null;
        return {
            id: String(v.id),
            programa_id: v.programaId || v.programa_id || null,
            codigo: String(v.codigo || '').trim(),
            hotel_id: this._isUuid(hid) ? String(hid).trim() : null,
            hotel_name: v.hotelName || v.hotel_name || null,
            cliente_nombre: v.clienteNombre || v.cliente_nombre || null,
            cliente_email: v.clienteEmail || v.cliente_email || null,
            cliente_telefono: v.clienteTelefono || v.cliente_telefono || null,
            cupos_iniciales: parseInt(v.cuposIniciales ?? v.cupos_iniciales, 10) || 0,
            cupos_disponibles: parseInt(v.cuposDisponibles ?? v.cupos_disponibles, 10) || 0,
            precio_usd: v.precioUSD != null ? parseFloat(v.precioUSD) : (v.precio_usd != null ? parseFloat(v.precio_usd) : null),
            fecha_venta: this._flexiDateOptional(v.fechaVenta || v.fecha_venta),
            fecha_inicio_uso: this._flexiDateOptional(v.fechaInicioUso || v.fecha_inicio_uso),
            fecha_fin_uso: this._flexiDateOptional(v.fechaFinUso || v.fecha_fin_uso),
            estado: v.estado || 'Activo',
            notas: v.notas || null,
            captura_pago_url: cap,
            fecha_creacion: v.fechaCreacion || v.fecha_creacion || new Date().toISOString(),
            updated_at: new Date().toISOString()
        };
    }

    _flexiVoucherFromRow(r) {
        if (!r) return null;
        return {
            id: r.id,
            programaId: r.programa_id,
            codigo: r.codigo,
            hotelId: r.hotel_id,
            hotelName: r.hotel_name,
            clienteNombre: r.cliente_nombre,
            clienteEmail: r.cliente_email,
            clienteTelefono: r.cliente_telefono,
            cuposIniciales: r.cupos_iniciales,
            cuposDisponibles: r.cupos_disponibles,
            precioUSD: r.precio_usd != null ? parseFloat(r.precio_usd) : undefined,
            fechaVenta: r.fecha_venta,
            fechaInicioUso: r.fecha_inicio_uso,
            fechaFinUso: r.fecha_fin_uso,
            estado: r.estado,
            notas: r.notas || '',
            capturaPagoUrl: r.captura_pago_url || null,
            fechaCreacion: r.fecha_creacion
        };
    }

    _flexiCanjeToRow(c) {
        return {
            id: String(c.id),
            voucher_id: String(c.voucherId || c.voucher_id),
            voucher_codigo: c.voucherCodigo || c.voucher_codigo || null,
            cliente_nombre: c.clienteNombre || c.cliente_nombre || null,
            hotel_name: c.hotelName || c.hotel_name || null,
            check_in: c.checkIn || c.check_in || null,
            check_out: c.checkOut || c.check_out || null,
            personas: c.personas != null ? parseInt(c.personas, 10) : null,
            cupos_usados: parseInt(c.cuposUsados ?? c.cupos_usados, 10) || 0,
            notas: c.notas || null,
            estado: c.estado || 'Confirmado',
            fecha_registro: c.fechaRegistro || c.fecha_registro || new Date().toISOString(),
            motivo_anulacion: c.motivoAnulacion || c.motivo_anulacion || null,
            fecha_anulacion: c.fechaAnulacion || c.fecha_anulacion || null,
            fecha_noshow: c.fechaNoShow || c.fecha_noshow || null,
            updated_at: new Date().toISOString()
        };
    }

    _flexiCanjeFromRow(r) {
        if (!r) return null;
        return {
            id: r.id,
            voucherId: r.voucher_id,
            voucherCodigo: r.voucher_codigo,
            clienteNombre: r.cliente_nombre,
            hotelName: r.hotel_name,
            checkIn: r.check_in,
            checkOut: r.check_out,
            personas: r.personas,
            cuposUsados: r.cupos_usados,
            notas: r.notas || '',
            estado: r.estado,
            fechaRegistro: r.fecha_registro,
            motivoAnulacion: r.motivo_anulacion,
            fechaAnulacion: r.fecha_anulacion,
            fechaNoShow: r.fecha_noshow
        };
    }

    async getFlexiPrograms() {
        if (!this.isInitialized()) return [];
        const { data, error } = await this.client.from('flexi_programs').select('*').order('fecha_creacion', { ascending: false });
        if (error) throw error;
        return (data || []).map(r => this._flexiProgramFromRow(r)).filter(Boolean);
    }

    async getFlexiVouchers() {
        if (!this.isInitialized()) return [];
        const { data, error } = await this.client.from('flexi_vouchers').select('*').order('fecha_creacion', { ascending: false });
        if (error) throw error;
        return (data || []).map(r => this._flexiVoucherFromRow(r)).filter(Boolean);
    }

    async getFlexiCanjes() {
        if (!this.isInitialized()) return [];
        const { data, error } = await this.client.from('flexi_canjes').select('*').order('fecha_registro', { ascending: false });
        if (error) throw error;
        return (data || []).map(r => this._flexiCanjeFromRow(r)).filter(Boolean);
    }

    /** Un mismo upsert no puede incluir dos filas con el mismo id/codigo único (Postgres 21000). */
    _dedupeFlexiRowsByKey(rows, key) {
        if (!rows || !rows.length) return [];
        const map = new Map();
        for (const row of rows) {
            const k = row && row[key] != null ? String(row[key]).trim() : '';
            if (!k) continue;
            map.set(k, row);
        }
        return [...map.values()];
    }

    /** Upsert masivo (órden: programas → vouchers → canjes por FKs). */
    async syncFlexiData(programs, vouchers, canjes) {
        if (!this.isInitialized()) return;
        let pRows = (programs || []).map(p => this._flexiProgramToRow(p));
        pRows = this._dedupeFlexiRowsByKey(pRows, 'id');
        let vRows = (vouchers || []).map(v => this._flexiVoucherToRow(v)).filter(row => row.codigo);
        vRows = this._dedupeFlexiRowsByKey(vRows, 'id');
        vRows = this._dedupeFlexiRowsByKey(vRows, 'codigo');
        let cRows = (canjes || []).map(c => this._flexiCanjeToRow(c));
        cRows = this._dedupeFlexiRowsByKey(cRows, 'id');

        if (pRows.length) {
            const { error } = await this.client.from('flexi_programs').upsert(pRows, { onConflict: 'id' });
            if (error) {
                console.error('flexi_programs upsert', error.message, error.details, error.hint, error.code);
                throw error;
            }
        }
        if (vRows.length) {
            let vErr;
            ({ error: vErr } = await this.client.from('flexi_vouchers').upsert(vRows, { onConflict: 'id' }));
            if (vErr && String(vErr.code || '') === 'PGRST204' && /captura_pago_url/i.test(String(vErr.message || ''))) {
                const sinCaptura = vRows.map(({ captura_pago_url: _x, ...rest }) => rest);
                ({ error: vErr } = await this.client.from('flexi_vouchers').upsert(sinCaptura, { onConflict: 'id' }));
            }
            if (vErr) {
                console.error('flexi_vouchers upsert', vErr.message, vErr.details, vErr.hint, vErr.code);
                throw vErr;
            }
        }
        if (cRows.length) {
            const { error } = await this.client.from('flexi_canjes').upsert(cRows, { onConflict: 'id' });
            if (error) {
                console.error('flexi_canjes upsert', error.message, error.details, error.hint, error.code);
                throw error;
            }
        }
    }

    async deleteFlexiProgramFromDb(id) {
        if (!this.isInitialized() || !id) return;
        const { error } = await this.client.from('flexi_programs').delete().eq('id', String(id));
        if (error) throw error;
    }
}

// Crear instancia global
window.supabaseClient = new SupabaseClient();

// Exportar para uso en módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SupabaseClient;
}

