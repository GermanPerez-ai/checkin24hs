// Base de Conocimiento para el Agente de Conversación "Flor"
// Checkin24hs - Agente de Atención al Cliente

// Limpiar hoteles fantasma automáticamente al cargar
(function cleanPhantomHotels() {
    const phantomHotelIds = ['hotel-termas-chillan', 'hotel-puyehue', 'hotel-corralco', 'hotel-futangue', 'hotel-aguas-calientes'];
    const phantomHotelNames = ['Hotel Termas Chillán', 'Hotel Terma de Puyehue', 'Hotel Corralco Resort', 'Hotel Futangue', 'Cabañas Termas de Aguas Calientes'];
    try {
        const hotelsDB = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
        const cleanedHotels = hotelsDB.filter(h => 
            !phantomHotelIds.includes(h.id) && 
            !phantomHotelNames.includes(h.name)
        );
        if (cleanedHotels.length !== hotelsDB.length) {
            localStorage.setItem('hotelsDB', JSON.stringify(cleanedHotels));
            console.log('🧹 Hoteles fantasma eliminados automáticamente. Quedaron:', cleanedHotels.map(h => h.name));
        }
    } catch (e) {
        console.error('Error limpiando hoteles fantasma:', e);
    }
})();

const FlorKnowledgeBase = {
    // Información del Agente
    agent: {
        name: "Flor",
        role: "Asistente Virtual",
        greeting: "¡Hola! Mi nombre es Flor, soy tu asistente virtual y estoy aquí para ayudarte en lo que necesites! ¿Me podrías decir brevemente sobre qué hotel o servicio tienes una consulta?",
        personality: "Amable, eficiente y profesional"
    },

    // Base de conocimiento por hotel
    // Cada hotel tiene su propia integración con información completa
    hotelsKnowledge: {},

    // Políticas generales de la agencia
    policies: {
        reserva: {
            deposito: "Se requiere un depósito del 30% para confirmar la reserva",
            metodos_pago: ["Tarjeta de crédito", "Transferencia bancaria", "PayPal"],
            plazo_confirmacion: "Las reservas se confirman dentro de 24 horas"
        },
        cancelacion: {
            gratuita_hasta: "72 horas antes del check-in",
            penalizacion: "50% del total si se cancela entre 48-72 horas antes, 100% si se cancela con menos de 48 horas",
            excepciones: "Se evaluarán casos de fuerza mayor"
        },
        checkin_checkout: {
            checkin_horario: "Desde las 15:00 horas",
            checkout_horario: "Hasta las 11:00 horas",
            checkin_early: "Disponible según disponibilidad, puede tener costo adicional",
            checkout_late: "Disponible según disponibilidad, puede tener costo adicional"
        },
        mascotas: {
            permitidas: false,
            excepciones: "Algunos hoteles pueden aceptar mascotas con cargo adicional. Consultar disponibilidad."
        }
    },

    // Rangos de precios aproximados (para dar una idea general)
    priceRanges: {
        economico: { min: 150, max: 300, currency: "USD" },
        medio: { min: 300, max: 600, currency: "USD" },
        alto: { min: 600, max: 1500, currency: "USD" },
        premium: { min: 1500, max: 3000, currency: "USD" }
    },

    // Palabras clave para detectar intenciones
    intents: {
        saludar: ["hola", "buenos días", "buenas tardes", "buenas noches", "hi", "hello", "saludos"],
        despedirse: ["adiós", "chao", "gracias", "hasta luego", "bye", "thanks"],
        consulta_hotel: ["hotel", "hoteles", "qué hoteles", "que hoteles", "catálogo", "opciones", "lugares", "sitios", "trabajan", "trabajamos", "tienen", "ofrecen", "manejan", "lista", "listado", "cuales", "cuáles", "todos los hoteles", "ver hoteles", "mostrar hoteles"],
        ubicacion: ["dónde", "donde", "ubicación", "ubicacion", "dirección", "direccion", "ubicado", "localización", "localizacion", "donde queda", "como llego", "cómo llego"],
        servicios: ["servicios", "amenidades", "comodidades", "qué incluye", "que incluye", "facilidades", "tiene", "cuenta con", "ofrece", "incluye"],
        precios: ["precio", "precios", "cuánto", "cuanto", "costo", "tarifa", "tarifas", "valor", "cuanto cuesta", "cuánto cuesta", "cuanto sale", "cuánto sale"],
        disponibilidad: ["disponible", "disponibilidad", "libre", "vacante", "hay lugar", "puedo reservar", "hay disponibilidad"],
        reservar: ["reservar", "reserva", "quiero reservar", "hacer reserva", "confirmar", "agendar", "book", "booking"],
        cancelar: ["cancelar", "cancelación", "cancelacion", "anular", "eliminar reserva"],
        contacto_humano: ["humano", "persona", "agente", "asesor", "hablar con alguien", "representante", "llamar", "contactar"],
        problema: ["problema", "error", "no funciona", "no entiendo", "confundido", "ayuda urgente", "queja", "reclamo"]
    },

    // Respuestas predefinidas para situaciones comunes
    responses: {
        no_entendido: "No estoy segura de haber entendido tu consulta. Te cuento que trabajamos con varios hoteles de calidad. ¿Te gustaría saber qué hoteles tenemos disponibles o tienes alguna consulta específica?",
        no_informacion: "No tengo esa información específica disponible en este momento. Déjame conectarte con un agente humano que podrá ayudarte mejor con tu consulta.",
        transferir_humano: "Perfecto, voy a conectarte inmediatamente con uno de nuestros agentes que podrá asistirte mejor. Un momento por favor...",
        despedida: "¡Fue un placer ayudarte! Si necesitas algo más, no dudes en consultarme. ¡Que tengas un excelente día!",
        confirmacion_servicios: "Perfecto, te puedo ayudar con información sobre servicios. ¿Sobre qué hotel específico te gustaría consultar?",
        confirmacion_precios: "Te puedo dar una idea general de precios. Los rangos varían según el hotel y temporada. ¿Sobre qué hotel te interesa saber?"
    },

    // Función para obtener información de hoteles desde localStorage
    getHotelsFromDB: function() {
        try {
            const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
            return hotels.filter(h => h.is_active !== false);
        } catch (error) {
            console.error('Error al cargar hoteles:', error);
            return [];
        }
    },

    // Función para buscar hotel por nombre
    findHotelByName: function(hotelName) {
        const hotels = this.getHotelsFromDB();
        const searchTerm = hotelName.toLowerCase().trim();
        
        return hotels.find(hotel => 
            hotel.name.toLowerCase().includes(searchTerm) ||
            hotel.location.toLowerCase().includes(searchTerm) ||
            (hotel.address && hotel.address.toLowerCase().includes(searchTerm))
        );
    },

    // Obtener información completa de un hotel desde la base de conocimiento (sincronizada)
    getHotelKnowledge: function(hotelId) {
        // Primero obtener la información base del hotel desde hotelsDB
        const hotels = this.getHotelsFromDB();
        const hotel = hotels.find(h => h.id === hotelId || h.id == hotelId);
        
        // Luego obtener el conocimiento extra de Flor
        let extraKnowledge = null;
        
        // Intentar cargar desde el nuevo formato (flor_hotel_knowledge objeto completo)
        const allKnowledge = localStorage.getItem('flor_hotel_knowledge');
        if (allKnowledge) {
            try {
                const parsed = JSON.parse(allKnowledge);
                extraKnowledge = parsed[hotelId] || null;
            } catch (e) {
                console.error('Error parsing flor_hotel_knowledge:', e);
            }
        }
        
        // Fallback al formato antiguo
        if (!extraKnowledge) {
            const stored = localStorage.getItem(`flor_hotel_knowledge_${hotelId}`);
            if (stored) {
                try {
                    extraKnowledge = JSON.parse(stored);
                } catch (e) {
                    console.error('Error parsing hotel knowledge:', e);
                }
            }
        }
        
        // Si no hay hotel ni conocimiento extra, retornar null
        if (!hotel && !extraKnowledge) {
            return this.hotelsKnowledge[hotelId] || null;
        }
        
        // Combinar información sincronizada con conocimiento extra
        const combinedKnowledge = {
            // Información sincronizada del hotel
            name: hotel?.name || extraKnowledge?.syncedInfo?.name,
            location: hotel?.location || extraKnowledge?.syncedInfo?.location,
            address: hotel?.location || extraKnowledge?.syncedInfo?.location,
            rating: hotel?.rating || extraKnowledge?.syncedInfo?.rating,
            priceRange: hotel?.priceRange || hotel?.price_range || extraKnowledge?.syncedInfo?.priceRange,
            amenities: hotel?.amenities || extraKnowledge?.syncedInfo?.amenities || [],
            mainImage: hotel?.mainImage || (hotel?.images && hotel.images[0]) || extraKnowledge?.syncedInfo?.mainImage,
            galleryImages: hotel?.galleryImages || (hotel?.images && hotel.images.slice(1)) || extraKnowledge?.syncedInfo?.galleryImages || [],
            googleMaps: hotel?.googleMaps || extraKnowledge?.syncedInfo?.googleMaps,
            website: hotel?.website || extraKnowledge?.syncedInfo?.website || '',
            // Información extra de Flor
            description: extraKnowledge?.description || hotel?.description || '',
            servicesDetail: extraKnowledge?.servicesDetail || '',
            pricing: extraKnowledge?.pricing || '',
            transport: extraKnowledge?.transport || '',
            notes: extraKnowledge?.notes || '',
            // Información extraída del sitio web del hotel
            websiteInfo: extraKnowledge?.websiteInfo || '',
            // Integraciones específicas (palabras clave, contenido, envío de imagen)
            specificIntegrations: extraKnowledge?.specificIntegrations || [],
            // Metadata
            lastUpdated: extraKnowledge?.lastUpdated,
            hasSyncedInfo: !!hotel,
            hasExtraKnowledge: !!extraKnowledge,
            hasWebsiteInfo: !!(extraKnowledge?.websiteInfo)
        };
        
        return combinedKnowledge;
    },

    // Guardar información de conocimiento de un hotel
    saveHotelKnowledge: function(hotelId, knowledge) {
        // Guardar en localStorage (nuevo formato)
        const allKnowledge = JSON.parse(localStorage.getItem('flor_hotel_knowledge') || '{}');
        allKnowledge[hotelId] = knowledge;
        localStorage.setItem('flor_hotel_knowledge', JSON.stringify(allKnowledge));
        
        // También guardar en formato antiguo para compatibilidad
        localStorage.setItem(`flor_hotel_knowledge_${hotelId}`, JSON.stringify(knowledge));
        
        // Actualizar en el objeto
        this.hotelsKnowledge[hotelId] = knowledge;
    },
    
    // Obtener imagen principal del hotel
    getHotelMainImage: function(hotelId) {
        const hotels = this.getHotelsFromDB();
        const hotel = hotels.find(h => h.id === hotelId || h.id == hotelId);
        if (hotel) {
            return hotel.mainImage || (hotel.images && hotel.images[0]) || null;
        }
        return null;
    },
    
    // Obtener galería de imágenes del hotel
    getHotelGallery: function(hotelId) {
        const hotels = this.getHotelsFromDB();
        const hotel = hotels.find(h => h.id === hotelId || h.id == hotelId);
        if (hotel) {
            return hotel.galleryImages || (hotel.images && hotel.images.slice(1)) || [];
        }
        return [];
    },

    // Obtener servicios específicos de un hotel
    getHotelServices: function(hotel) {
        if (!hotel) return [];
        
        // Intentar obtener de la base de conocimiento específica del hotel
        const hotelKnowledge = this.getHotelKnowledge(hotel.id);
        if (hotelKnowledge && hotelKnowledge.services) {
            return hotelKnowledge.services;
        }
        
        // Si no existe conocimiento específico, usar amenities básicas como fallback
        if (hotel.amenities) {
            const amenitiesMap = {
                'thermal_waters': 'Aguas Termales',
                'spa': 'Spa',
                'restaurant': 'Restaurante',
                'gym': 'Gimnasio',
                'volcano_views': 'Vistas a Volcanes',
                'native_forest': 'Bosque Nativo',
                'natural_pool': 'Piscina Natural',
                'bar': 'Bar',
                'mountain_activities': 'Actividades de Montaña',
                'wifi': 'Wi-Fi',
                'parking': 'Estacionamiento',
                'breakfast': 'Desayuno',
                'desayuno': 'Desayuno',
                'ski_slopes': 'Pistas de Esquí',
                'adventure_center': 'Centro de Aventura',
                'gourmet_restaurant': 'Restaurante Gourmet',
                'panoramic_views': 'Vistas Panorámicas',
                'tour_guide': 'Guía de Tours'
            };
            return hotel.amenities.map(amenity => amenitiesMap[amenity] || amenity);
        }
        
        return [];
    },

    // Función para obtener información completa de un hotel (sincronizada con hotelsDB)
    getHotelFullInfo: function(hotel) {
        if (!hotel) return null;

        // Obtener información combinada (sincronizada + extra de Flor)
        const hotelKnowledge = this.getHotelKnowledge(hotel.id);
        
        // Servicios: combinar amenities del hotel con detalle de servicios de Flor
        const services = this.getHotelServices(hotel);
        
        // Construir información completa
        const fullInfo = {
            // Información básica sincronizada
            name: hotel.name,
            location: hotel.location,
            address: hotel.address || hotel.location,
            rating: hotel.rating || 'No calificado',
            amenities: hotel.amenities || [],
            
            // Imágenes sincronizadas
            mainImage: hotel.mainImage || (hotel.images && hotel.images[0]) || null,
            galleryImages: hotel.galleryImages || (hotel.images && hotel.images.slice(1)) || [],
            googleMaps: hotel.googleMaps || null,
            
            // Información de precios
            priceRange: hotel.priceRange || hotel.price_range || null,
            priceInfo: hotelKnowledge?.pricing || {
                dynamic: true,
                message: "Las tarifas son dinámicas y varían según fecha, pueden variar en alta temporada o en baja temporada. Para una cotización precisa solicítela con: Fecha de Check-in, cantidad de noches y cantidad de personas. Las tarifas enviadas tienen validez de 24 horas.",
                requiresQuote: true
            },
            
            // Servicios
            services: services,
            servicesDetail: hotelKnowledge?.servicesDetail || '',
            
            // Información extra de Flor
            description: hotelKnowledge?.description || hotel.description || 'Hotel de calidad superior',
            transport: hotelKnowledge?.transport || '',
            notes: hotelKnowledge?.notes || '',
            
            // Metadata
            hasDetailedKnowledge: !!(hotelKnowledge?.description || hotelKnowledge?.servicesDetail),
            hasSyncedInfo: true,
            hasImages: !!(hotel.mainImage || (hotel.images && hotel.images.length > 0))
        };
        
        return fullInfo;
    },

    // Verificar si tiene información específica sobre un aspecto de un hotel
    hasHotelInformation: function(hotelId, informationType) {
        const hotelKnowledge = this.getHotelKnowledge(hotelId);
        if (!hotelKnowledge) return false;

        const informationMap = {
            'services': !!hotelKnowledge.services,
            'servicesDetails': !!hotelKnowledge.servicesDetails,
            'roomTypes': !!hotelKnowledge.roomTypes,
            'policies': !!hotelKnowledge.policies,
            'priceRange': !!hotelKnowledge.priceRange,
            'description': !!hotelKnowledge.description
        };

        return informationMap[informationType] || false;
    },

    // Función para generar respuesta detallada sobre un hotel
    generateHotelInfoResponse: function(hotel) {
        const info = this.getHotelFullInfo(hotel);
        if (!info) return "No encontré información sobre ese hotel.";

        let response = `📍 **${info.name}**\n\n`;
        response += `📍 Ubicación: ${info.location}\n`;
        if (info.address && info.address !== info.location) {
            response += `Dirección: ${info.address}\n`;
        }
        response += `⭐ Calificación: ${info.rating}/5\n\n`;
        response += `${info.description}\n\n`;

        if (info.services && info.services.length > 0) {
            response += `🎯 Servicios incluidos: ${info.services.join(', ')}\n\n`;
        }

        // Información de precios dinámicos
        if (info.priceInfo && typeof info.priceInfo === 'object' && info.priceInfo.message) {
            response += `💰 **Información sobre tarifas:**\n${info.priceInfo.message}\n`;
        } else {
            response += `💰 **Información sobre tarifas:**\nLas tarifas son dinámicas y varían según fecha, pueden variar en alta temporada o en baja temporada. Para una cotización precisa solicítela con: Fecha de Check-in, cantidad de noches y cantidad de personas. Las tarifas enviadas tienen validez de 24 horas.\n`;
        }

        return response;
    },

    // Función para obtener rangos de precios por hotel
    getHotelPriceRange: function(hotel) {
        if (!hotel) return null;

        // Intentar obtener precio del hotel
        const price = hotel.price || hotel.priceRange || hotel.price_range;
        
        if (price) {
            return price;
        }

        // Si no hay precio específico, estimar según rating
        const rating = hotel.rating || 4.0;
        
        if (rating >= 4.8) {
            return this.priceRanges.premium;
        } else if (rating >= 4.5) {
            return this.priceRanges.alto;
        } else if (rating >= 4.0) {
            return this.priceRanges.medio;
        } else {
            return this.priceRanges.economico;
        }
    },

    // Información adicional sobre servicios comunes
    serviceDetails: {
        'aguas termales': 'Las aguas termales son perfectas para relajación y bienestar. Generalmente tienen beneficios terapéuticos y están disponibles en varios de nuestros hoteles.',
        'spa': 'Nuestros spas ofrecen tratamientos de relajación, masajes terapéuticos, tratamientos faciales y corporales. Suelen tener costo adicional.',
        'restaurante': 'Muchos hoteles cuentan con restaurantes gourmet con cocina de autor. Algunos incluyen el desayuno, mientras que otros tienen menú a la carta.',
        'gimnasio': 'Instalaciones de fitness modernas generalmente incluidas en la estadía.',
        'piscina': 'Piscinas climatizadas o al aire libre. La mayoría están incluidas en la estadía.',
        'wifi': 'Conexión a internet de alta velocidad generalmente incluida en todos los hoteles.',
        'estacionamiento': 'Estacionamiento privado generalmente incluido sin costo adicional.',
        'desayuno': 'El desayuno puede estar incluido o tener costo adicional dependiendo del hotel y tipo de habitación.',
        'traslado': 'Servicio de traslado desde/hacia el aeropuerto generalmente tiene costo adicional y debe reservarse con anticipación.'
    },

    // Función para obtener detalles de un servicio
    getServiceDetail: function(serviceName) {
        const normalized = serviceName.toLowerCase().trim();
        return this.serviceDetails[normalized] || null;
    },

    // ===== INTEGRACIONES ESPECÍFICAS POR HOTEL =====
    // Las integraciones se activan según consultas puntuales del usuario
    
    // Obtener integraciones específicas de un hotel
    getHotelIntegrations: function(hotelId) {
        const hotelKnowledge = this.getHotelKnowledge(hotelId);
        if (!hotelKnowledge) return [];
        
        return hotelKnowledge.specificIntegrations || [];
    },

    // Detectar si una consulta del usuario requiere una integración específica
    detectIntegrationTrigger: function(userMessage, hotelId) {
        if (!hotelId) return null;
        
        const integrations = this.getHotelIntegrations(hotelId);
        if (!integrations || integrations.length === 0) return null;
        
        const message = userMessage.toLowerCase().trim();
        
        // Buscar si alguna integración coincide con la consulta del usuario
        for (const integration of integrations) {
            if (!integration.triggerKeywords || integration.triggerKeywords.length === 0) {
                continue;
            }
            
            // Verificar si alguna palabra clave coincide
            const matches = integration.triggerKeywords.some(keyword => {
                const normalizedKeyword = keyword.toLowerCase().trim();
                return message.includes(normalizedKeyword);
            });
            
            if (matches) {
                return integration;
            }
        }
        
        return null;
    },

    // Obtener información de integración específica para incluir en el prompt
    getIntegrationContext: function(integration, hotelId) {
        if (!integration) return null;
        
        let context = `\n=== INTEGRACIÓN ESPECÍFICA: ${integration.name || 'Información Adicional'} ===\n`;
        
        if (integration.description) {
            context += `Descripción: ${integration.description}\n`;
        }
        
        if (integration.content) {
            context += `Contenido:\n${integration.content}\n`;
        }
        
        if (integration.apiEndpoint) {
            context += `[NOTA: Esta integración requiere consulta a API externa: ${integration.apiEndpoint}]\n`;
        }
        
        if (integration.data) {
            context += `Datos específicos:\n${JSON.stringify(integration.data, null, 2)}\n`;
        }
        
        // Agregar información sobre envío de imagen
        if (integration.sendImage) {
            context += `[IMPORTANTE: Esta integración debe enviar una imagen del hotel. Usa el formato [SEND_IMAGE:${hotelId}:${integration.imageType || 'main'}] al final de tu respuesta para indicar que se debe enviar la imagen.]\n`;
        }
        
        context += `=== FIN DE INTEGRACIÓN ESPECÍFICA ===\n`;
        
        return context;
    },

    // Guardar o actualizar una integración específica para un hotel
    saveHotelIntegration: function(hotelId, integration) {
        const hotelKnowledge = this.getHotelKnowledge(hotelId) || {};
        
        if (!hotelKnowledge.specificIntegrations) {
            hotelKnowledge.specificIntegrations = [];
        }
        
        // Si la integración ya existe (por ID), actualizarla
        if (integration.id) {
            const index = hotelKnowledge.specificIntegrations.findIndex(i => i.id === integration.id);
            if (index !== -1) {
                hotelKnowledge.specificIntegrations[index] = integration;
            } else {
                hotelKnowledge.specificIntegrations.push(integration);
            }
        } else {
            // Crear nuevo ID si no existe
            integration.id = `integration_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            hotelKnowledge.specificIntegrations.push(integration);
        }
        
        // Guardar de vuelta
        this.saveHotelKnowledge(hotelId, hotelKnowledge);
        
        return integration;
    },

    // Eliminar una integración específica
    deleteHotelIntegration: function(hotelId, integrationId) {
        const hotelKnowledge = this.getHotelKnowledge(hotelId);
        if (!hotelKnowledge || !hotelKnowledge.specificIntegrations) {
            return false;
        }
        
        const initialLength = hotelKnowledge.specificIntegrations.length;
        hotelKnowledge.specificIntegrations = hotelKnowledge.specificIntegrations.filter(
            i => i.id !== integrationId
        );
        
        if (hotelKnowledge.specificIntegrations.length < initialLength) {
            this.saveHotelKnowledge(hotelId, hotelKnowledge);
            return true;
        }
        
        return false;
    },

    // Obtener todas las integraciones activas para un hotel (para mostrar en CRM)
    getAllHotelIntegrations: function(hotelId) {
        return this.getHotelIntegrations(hotelId);
    }
};

// Exportar para uso en otros archivos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FlorKnowledgeBase;
}

