// Agente de Conversación "Flor" - Motor Principal
// Checkin24hs - Sistema de Atención al Cliente Inteligente

class FlorAgent {
    constructor() {
        this.knowledgeBase = FlorKnowledgeBase;
        this.aiService = typeof florAIService !== 'undefined' ? florAIService : null;
        this.multimodalService = typeof florMultimodalService !== 'undefined' ? florMultimodalService : null;
        this.conversationHistory = [];
        this.shouldEscalate = false;
        this.useAI = false; // Flag para habilitar/deshabilitar IA
        this.context = {
            currentHotel: null,
            currentIntent: null,
            lastMessage: null
        };
    }

    // Habilitar o deshabilitar el uso de IA
    setUseAI(enabled) {
        this.useAI = enabled;
        console.log(`[Flor Agent] ${enabled ? '✅ IA habilitada' : '⚠️ IA deshabilitada'}`);
    }

    // Función principal para procesar mensajes (ahora con soporte para IA y multimodal)
    async processMessage(userMessage, mediaType = null, mediaFile = null) {
        let message = userMessage;
        
        // Si hay un archivo multimedia, procesarlo primero
        if (mediaFile && this.multimodalService) {
            if (mediaType === 'audio') {
                console.log('[Flor Agent] 🎤 Procesando audio...');
                const audioResult = await this.multimodalService.processAudio(mediaFile);
                if (audioResult.success) {
                    message = audioResult.text;
                    console.log('[Flor Agent] ✅ Audio transcrito:', message);
                } else {
                    // Si falla la transcripción, devolver el mensaje de fallback
                    return audioResult.text || this.multimodalService.config.audio.fallbackMessage;
                }
            } else if (mediaType === 'image') {
                console.log('[Flor Agent] 📸 Procesando imagen...');
                const imageResult = await this.multimodalService.processImage(mediaFile);
                if (imageResult.success) {
                    // Agregar la descripción de la imagen al mensaje
                    const imageDescription = imageResult.description || 'Imagen recibida';
                    message = userMessage ? `${userMessage}\n\n[Imagen: ${imageDescription}]` : `[Imagen: ${imageDescription}]`;
                    console.log('[Flor Agent] ✅ Imagen analizada:', imageDescription);
                    
                    // Guardar información de la imagen en el contexto
                    this.context.lastImage = {
                        description: imageDescription,
                        objects: imageResult.objects || [],
                        labels: imageResult.labels || []
                    };
                } else {
                    // Si falla el análisis, continuar con el mensaje de texto si existe
                    if (!userMessage) {
                        return imageResult.description || 'No pude analizar la imagen. ¿Podrías describir lo que necesitas?';
                    }
                }
            }
        }
        
        const messageLower = message.toLowerCase().trim();
        this.context.lastMessage = message;
        this.conversationHistory.push({ 
            role: 'user', 
            content: message, 
            timestamp: new Date(),
            mediaType: mediaType,
            mediaDescription: mediaType === 'image' ? this.context.lastImage?.description : null
        });

        // Verificar si debe escalar a humano
        if (this.shouldEscalateToHuman(messageLower)) {
            this.shouldEscalate = true;
            return this.getEscalationResponse();
        }

        // Intentar usar IA si está habilitada y disponible
        if (this.useAI && this.aiService && this.aiService.isAvailable()) {
            try {
                console.log('[Flor Agent] 🤖 Generando respuesta con IA...');
                const aiResponse = await this.aiService.generateAIResponse(message, this.context);
                
                if (aiResponse && aiResponse.trim()) {
                    // Verificar si la respuesta de IA indica que debe escalar
                    if (this.shouldEscalateBasedOnAIResponse(aiResponse)) {
                        this.shouldEscalate = true;
                        return this.getEscalationResponse();
                    }
                    
                    // Verificar si hay imágenes para enviar (procesadas por el servicio de IA)
                    if (this.context.sendImages && this.context.sendImages.length > 0) {
                        const imageToSend = this.context.sendImages[0];
                        const hotels = this.knowledgeBase.getHotelsFromDB();
                        let hotel = null;
                        
                        // Buscar hotel por ID o nombre
                        if (imageToSend.hotelId) {
                            hotel = hotels.find(h => h.id == imageToSend.hotelId);
                        } else if (imageToSend.hotelName) {
                            hotel = hotels.find(h => 
                                h.name.toLowerCase().includes(imageToSend.hotelName.toLowerCase()) ||
                                imageToSend.hotelName.toLowerCase().includes(h.name.toLowerCase())
                            ) || this.findHotelInMessage(imageToSend.hotelName, hotels);
                        } else if (this.context.currentHotel) {
                            // Usar el hotel actual del contexto
                            hotel = this.context.currentHotel;
                        }
                        
                        if (hotel) {
                            this.context.currentHotel = hotel;
                            return {
                                text: aiResponse,
                                sendImage: {
                                    hotelId: hotel.id,
                                    hotelName: hotel.name,
                                    type: imageToSend.type || 'main'
                                }
                            };
                        }
                    }
                    
                    // Verificar si hay una integración activada y enviar su contenido
                    if (this.context.triggeredIntegration && this.context.integrationHotelId) {
                        const integration = this.context.triggeredIntegration;
                        const hotelId = this.context.integrationHotelId;
                        
                        // Construir respuesta combinando la respuesta de IA con el contenido de la integración
                        // Asegurarse de que aiResponse sea un string
                        let finalResponseText = typeof aiResponse === 'string' ? aiResponse : (aiResponse.text || String(aiResponse));
                        
                        // Si la integración tiene contenido, agregarlo a la respuesta
                        if (integration.content && integration.content.trim()) {
                            finalResponseText += '\n\n' + integration.content;
                        }
                        
                        // Preparar objeto de respuesta
                        const responseObj = {
                            text: finalResponseText
                        };
                        
                        // Si la integración requiere enviar imagen
                        if (integration.sendImage) {
                            const hotels = this.knowledgeBase.getHotelsFromDB();
                            const hotel = hotels.find(h => h.id == hotelId);
                            
                            if (hotel) {
                                responseObj.sendImage = {
                                    hotelId: hotel.id,
                                    hotelName: hotel.name,
                                    type: integration.imageType || 'main'
                                };
                            }
                        }
                        
                        // Limpiar la integración del contexto después de usarla
                        delete this.context.triggeredIntegration;
                        delete this.context.integrationHotelId;
                        
                        // Agregar respuesta al historial
                        this.conversationHistory.push({ role: 'bot', content: finalResponseText, timestamp: new Date() });
                        
                        // Guardar interacción para aprendizaje
                        if (typeof FlorLearningSystem !== 'undefined' && FlorLearningSystem.config.enabled) {
                            try {
                                FlorLearningSystem.saveInteraction({
                                    userMessage: message,
                                    botResponse: finalResponseText,
                                    intent: this.context.currentIntent || 'consulta_general',
                                    hotelId: this.context.currentHotel ? this.context.currentHotel.id : null,
                                    success: true,
                                    usedAI: true
                                });
                            } catch (e) {
                                console.error('[Flor Agent] Error al guardar interacción:', e);
                            }
                        }
                        
                        return responseObj;
                    }
                    
                    // Verificar si la integración activa requiere enviar imagen (fallback)
                    if (this.context.currentHotel) {
                        const triggeredIntegration = this.knowledgeBase.detectIntegrationTrigger(
                            message,
                            this.context.currentHotel.id
                        );
                        
                        if (triggeredIntegration && triggeredIntegration.sendImage) {
                            return {
                                text: aiResponse,
                                sendImage: {
                                    hotelId: this.context.currentHotel.id,
                                    hotelName: this.context.currentHotel.name,
                                    type: triggeredIntegration.imageType || 'main'
                                }
                            };
                        }
                    }
                    
                    // Agregar respuesta al historial
                    this.conversationHistory.push({ role: 'bot', content: aiResponse, timestamp: new Date() });
                    
                    // Guardar interacción para aprendizaje
                    if (typeof FlorLearningSystem !== 'undefined' && FlorLearningSystem.config.enabled) {
                        try {
                            const responseText = typeof aiResponse === 'object' ? aiResponse.text || JSON.stringify(aiResponse) : aiResponse;
                            FlorLearningSystem.saveInteraction({
                                userMessage: message,
                                botResponse: responseText,
                                intent: this.context.currentIntent || 'consulta_general',
                                hotelId: this.context.currentHotel ? this.context.currentHotel.id : null,
                                success: true,
                                usedAI: true
                            });
                        } catch (e) {
                            console.error('[Flor Agent] Error al guardar interacción:', e);
                        }
                    }
                    
                    // Limitar historial
                    if (this.conversationHistory.length > 20) {
                        this.conversationHistory = this.conversationHistory.slice(-20);
                    }
                    
                    return aiResponse;
                }
            } catch (error) {
                console.warn('[Flor Agent] ⚠️ Error con IA, usando fallback:', error);
                // Continuar con el sistema de reglas como fallback
            }
        }

        // Sistema de reglas: prompt/knowledge = flor_info de cada hotel (Supabase) + getHotelKnowledge
        const intent = this.detectIntent(messageLower);
        this.context.currentIntent = intent;
        if (typeof console !== 'undefined' && console.log) console.log('[Flor Agent] 📋 Origen: reglas (sin Flor API/Gemini). Intent:', intent);

        // Generar respuesta según intención
        let response = this.generateResponse(intent, messageLower);
        
        // Si hay una imagen procesada y la respuesta menciona un hotel, verificar si debemos enviar imagen
        if (mediaType === 'image' && this.context.lastImage) {
            const shouldSendImage = this.shouldSendHotelImage(response, this.context);
            if (shouldSendImage) {
                response = {
                    text: response,
                    sendImage: shouldSendImage
                };
            }
        }
        
        // Agregar respuesta al historial
        this.conversationHistory.push({ role: 'bot', content: response, timestamp: new Date() });

        // Guardar interacción para aprendizaje
        if (typeof FlorLearningSystem !== 'undefined' && FlorLearningSystem.config.enabled) {
            try {
                const responseText = typeof response === 'object' ? response.text || JSON.stringify(response) : response;
                FlorLearningSystem.saveInteraction({
                    userMessage: message,
                    botResponse: responseText,
                    intent: intent,
                    hotelId: this.context.currentHotel ? this.context.currentHotel.id : null,
                    success: true,
                    usedAI: false
                });
            } catch (e) {
                console.error('[Flor Agent] Error al guardar interacción:', e);
            }
        }

        // Limitar historial a últimas 20 conversaciones
        if (this.conversationHistory.length > 20) {
            this.conversationHistory = this.conversationHistory.slice(-20);
        }

        return response;
    }

    // Verificar si la respuesta de IA indica que debe escalar
    shouldEscalateBasedOnAIResponse(aiResponse) {
        // Solo escalar si la respuesta explícitamente menciona escalación O si contiene frases específicas de escalación
        const escalationPhrases = [
            'conectarte con un agente',
            'conectarte con un humano',
            'transferir a un agente',
            'transferir a un humano',
            'escalar a un agente',
            'un agente se comunicará',
            'no puedo ayudarte con reservas',
            'no puedo procesar reservas',
            'no puedo hacer reservas'
        ];
        
        const responseLower = aiResponse.toLowerCase();
        
        // Solo escalar si contiene una frase completa de escalación, no solo palabras sueltas
        const hasEscalationPhrase = escalationPhrases.some(phrase => responseLower.includes(phrase));
        
        // NO escalar si la respuesta contiene información útil (indica que está respondiendo)
        const hasUsefulInfo = responseLower.length > 50; // Respuestas largas probablemente tienen información
        
        // Solo escalar si tiene frase de escalación Y la respuesta es corta (indica que realmente quiere escalar)
        return hasEscalationPhrase && !hasUsefulInfo;
    }

    // Detectar intención del mensaje
    detectIntent(message) {
        const intents = this.knowledgeBase.intents;
        const messageLower = message.toLowerCase();
        
        // Primero verificar si menciona un hotel (priorizar consultas específicas sobre saludos genéricos)
        const hotels = this.knowledgeBase.getHotelsFromDB();
        const mentionsHotel = this.findHotelInMessage(message, hotels);
        
        // Si hay un hotel en contexto, las preguntas de seguimiento se refieren a ese hotel
        const hasHotelContext = this.context.currentHotel !== null;
        
        // Palabras que indican pregunta de seguimiento sobre el hotel actual
        const followUpWords = ['tiene', 'tienen', 'hay', 'ofrece', 'ofrecen', 'incluye', 'cuenta con',
                               'excursiones', 'excursion', 'actividades', 'actividad', 'paseos', 'tours', 
                               'spa', 'piscina', 'restaurant', 'bar', 'wifi', 'estacionamiento', 'mascotas',
                               'que servicios', 'qué servicios', 'mas info', 'más info', 'más información',
                               'si quiero', 'sí quiero', 'cuéntame', 'cuentame', 'dime más', 'dime mas'];
        const isFollowUp = hasHotelContext && followUpWords.some(w => messageLower.includes(w));
        
        // Si es pregunta de seguimiento sobre hotel en contexto
        if (isFollowUp) {
            console.log('[Flor] Pregunta de seguimiento detectada, hotel en contexto:', this.context.currentHotel.name);
            if (this.matchesIntent(message, intents.precios) || messageLower.includes('precio') || messageLower.includes('cuesta') || messageLower.includes('tarifa')) {
                return 'precios';
            }
            if (this.matchesIntent(message, intents.ubicacion) || messageLower.includes('ubicacion') || messageLower.includes('donde') || messageLower.includes('llegar')) {
                return 'ubicacion';
            }
            // Por defecto, preguntas de seguimiento son sobre servicios
            return 'servicios';
        }
        
        // Detectar preguntas sobre lista de hoteles (alta prioridad)
        const hotelListKeywords = ['qué hoteles', 'que hoteles', 'cuáles hoteles', 'cuales hoteles', 
                                   'lista de hoteles', 'listado de hoteles', 'hoteles trabajan', 
                                   'hoteles tienen', 'hoteles ofrecen', 'hoteles manejan',
                                   'ver hoteles', 'mostrar hoteles', 'todos los hoteles',
                                   'con qué hoteles', 'con que hoteles', 'cuantos hoteles', 'cuántos hoteles'];
        const asksForHotelList = hotelListKeywords.some(keyword => message.includes(keyword));
        
        if (asksForHotelList) {
            return 'consulta_hotel';
        }
        
        // Si menciona un hotel o tiene palabras clave de consulta, priorizar consultas específicas (antes que saludar)
        if (mentionsHotel || this.hasConsultationKeywords(message) || hasHotelContext) {
            if (this.matchesIntent(message, intents.reservar)) return 'reservar';
            if (mentionsHotel) return 'consulta_hotel';
            if (this.matchesIntent(message, intents.consulta_hotel)) return 'consulta_hotel';
            if (this.matchesIntent(message, intents.ubicacion)) return 'ubicacion';
            if (this.matchesIntent(message, intents.servicios)) return 'servicios';
            if (this.matchesIntent(message, intents.precios)) return 'precios';
            if (this.matchesIntent(message, intents.disponibilidad)) return 'disponibilidad';
            if (this.matchesIntent(message, intents.cancelar)) return 'cancelar';
        }

        // Luego verificar otras intenciones
        if (this.matchesIntent(message, intents.despedirse)) return 'despedirse';
        if (this.matchesIntent(message, intents.contacto_humano)) return 'contacto_humano';
        if (this.matchesIntent(message, intents.problema)) return 'problema';
        
        // Verificar consulta_hotel antes de saludar (para capturar "hola, qué hoteles tienen")
        if (this.matchesIntent(message, intents.consulta_hotel)) return 'consulta_hotel';
        
        if (this.matchesIntent(message, intents.saludar)) return 'saludar';

        // Si no detectó intención pero menciona hotel, tratar como consulta_hotel
        if (mentionsHotel) return 'consulta_hotel';

        return 'no_entendido';
    }
    
    // Verificar si el mensaje tiene palabras clave de consulta
    hasConsultationKeywords(message) {
        const consultationWords = ['info', 'información', 'datos', 'detalles', 'sobre', 'puyehue', 
                                   'hotel', 'ubicación', 'servicios', 'precio', 'precios', 'cuesta', 
                                   'cuanto', 'cuánto', 'tarifa', 'tarifas', 'disponible', 'disponibilidad'];
        return consultationWords.some(word => message.includes(word.toLowerCase()));
    }

    // Verificar si el mensaje coincide con alguna palabra clave
    matchesIntent(message, keywords) {
        return keywords.some(keyword => message.includes(keyword));
    }

    // Generar respuesta según intención
    generateResponse(intent, message) {
        switch (intent) {
            case 'saludar':
                return this.knowledgeBase.agent.greeting;

            case 'despedirse':
                return this.knowledgeBase.responses.despedida;

            case 'reservar':
                this.shouldEscalate = true;
                return "Entiendo que deseas hacer una reserva. Para asegurar que tengas la mejor atención y confirmación, voy a conectarte inmediatamente con uno de nuestros agentes especializados. Un momento por favor...";

            case 'consulta_hotel':
                return this.handleHotelQuery(message);

            case 'ubicacion':
                return this.handleLocationQuery(message);

            case 'servicios':
                return this.handleServicesQuery(message);

            case 'precios':
                return this.handlePricesQuery(message);

            case 'disponibilidad':
                this.shouldEscalate = true;
                return "Para verificar disponibilidad en tiempo real, necesito conectarte con nuestro sistema de reservas. Te estoy transfiriendo a un agente que podrá consultar las fechas exactas para ti.";

            case 'cancelar':
                this.shouldEscalate = true;
                return "Para gestionar cancelaciones, necesito conectarte con nuestro equipo. Te estoy transfiriendo a un agente que podrá ayudarte con tu cancelación.";

            case 'contacto_humano':
                this.shouldEscalate = true;
                return this.knowledgeBase.responses.transferir_humano;

            case 'problema':
                this.shouldEscalate = true;
                return "Lamento que estés teniendo un problema. Voy a conectarte inmediatamente con un agente que podrá resolver tu situación.";

            default:
                // Si no entendió, intentar dar información útil
                const mentionedHotel = this.findHotelInMessage(message, this.knowledgeBase.getHotelsFromDB());
                if (mentionedHotel) {
                    // Hay un hotel mencionado pero no entendió la consulta específica
                    const hotelKnowledge = this.knowledgeBase.getHotelKnowledge(mentionedHotel.id);
                    if (!hotelKnowledge || !hotelKnowledge.description) {
                        // No tiene conocimiento configurado del hotel, derivar
                        this.shouldEscalate = true;
                        return `No tengo suficiente información configurada sobre ${mentionedHotel.name}. Déjame conectarte con un agente humano que podrá ayudarte mejor con tu consulta.`;
                    }
                }
                
                // Si no entendió pero hay hoteles, mostrar lista como ayuda
                const allHotels = this.knowledgeBase.getHotelsFromDB();
                if (allHotels.length > 0) {
                    let response = `Disculpa, no estoy segura de entender tu consulta. Te cuento que trabajamos con ${allHotels.length} hoteles de calidad:\n\n`;
                    allHotels.forEach((hotel, index) => {
                        response += `${index + 1}. **${hotel.name}** - ${hotel.location} ⭐ ${hotel.rating || 'N/A'}/5\n`;
                    });
                    response += `\n¿Sobre cuál te gustaría más información? También puedo ayudarte con ubicaciones, servicios o precios.`;
                    return response;
                }
                
                return this.knowledgeBase.responses.no_entendido;
        }
    }

    // Manejar consultas sobre hoteles
    handleHotelQuery(message) {
        const hotels = this.knowledgeBase.getHotelsFromDB();
        
        if (hotels.length === 0) {
            return "Disculpa, no tengo información de hoteles disponible en este momento. Déjame conectarte con un agente que podrá ayudarte mejor.";
        }

        // Verificar si menciona un hotel que NO tenemos registrado
        const unregisteredHotel = this.detectUnregisteredHotel(message, hotels);
        if (unregisteredHotel) {
            return `Por el momento no estamos trabajando con "${unregisteredHotel}", pero esperamos poder incorporarlo a la brevedad. 😊\n\n¿Te gustaría información sobre alguno de nuestros hoteles disponibles?\n\n${hotels.filter(h => h.status !== 'Inactivo').map(h => `• **${h.name}** - ${h.location}`).join('\n')}`;
        }

        // Buscar si menciona un hotel específico (usar la función mejorada)
        const mentionedHotel = this.findHotelInMessage(message, hotels);

        if (mentionedHotel) {
            // Verificar si el hotel está inactivo o en mantenimiento
            if (mentionedHotel.status === 'Inactivo' || mentionedHotel.status === 'Mantenimiento') {
                const activeHotels = hotels.filter(h => h.status !== 'Inactivo' && h.status !== 'Mantenimiento');
                return `El hotel **${mentionedHotel.name}** no está disponible actualmente${mentionedHotel.status === 'Mantenimiento' ? ' (en mantenimiento)' : ''}. 😊\n\n¿Te gustaría información sobre alguno de nuestros hoteles disponibles?\n\n${activeHotels.map(h => `• **${h.name}** - ${h.location}`).join('\n')}`;
            }
            
            this.context.currentHotel = mentionedHotel;
            
            // Obtener información completa del hotel (flor_info desde Supabase + flor_hotel_knowledge)
            const hotelKnowledge = this.knowledgeBase.getHotelKnowledge(mentionedHotel.id);
            const info = this.knowledgeBase.getHotelFullInfo(mentionedHotel);
            const hasDescription = !!(hotelKnowledge && (hotelKnowledge.description || (mentionedHotel.flor_info && mentionedHotel.flor_info.description)));
            if (typeof console !== 'undefined' && console.log) console.log('[Flor Agent] 🏨 Hotel:', mentionedHotel.name, '| flor_info:', !!mentionedHotel.flor_info, '| description:', !!hasDescription);

            // Sin descripción (ni flor_info ni conocimiento extra) → ofrecer conectar con agente
            if (!hotelKnowledge || !hasDescription) {
                let response = `Sí, trabajamos con **${info.name}** ubicado en ${info.location}.\n\n`;
                response += `⭐ Calificación: ${info.rating}/5\n\n`;
                response += `Para información detallada sobre este hotel (servicios, precios, políticas específicas), puedo conectarte con un agente humano que tiene toda la información actualizada. ¿Te parece bien?`;
                return response;
            }

            // Con descripción (flor_info o conocimiento): respuesta completa
            const description = (hotelKnowledge && hotelKnowledge.description) || (mentionedHotel.flor_info && mentionedHotel.flor_info.description) || '';
            let response = `Sí, trabajamos con **${info.name}** ubicado en ${info.location}.\n\n`;
            response += `${description}\n\n`;
            response += `⭐ Calificación: ${info.rating}/5\n`;
            
            // Servicios: flor_info (Supabase), servicesDetails o info.services
            const servicesDetail = (hotelKnowledge && hotelKnowledge.servicesDetail) || (mentionedHotel.flor_info && mentionedHotel.flor_info.services) || '';
            if (hotelKnowledge && hotelKnowledge.servicesDetails && Object.keys(hotelKnowledge.servicesDetails).length > 0) {
                const services = Object.values(hotelKnowledge.servicesDetails).slice(0, 5).map(s => s.name);
                response += `🎯 Servicios principales: ${services.join(', ')}\n`;
            } else if (servicesDetail) {
                response += `🎯 Servicios: ${typeof servicesDetail === 'string' ? servicesDetail.slice(0, 300) : ''}\n`;
            } else if (info.services && info.services.length > 0) {
                response += `🎯 Servicios principales: ${info.services.slice(0, 5).join(', ')}\n`;
            }
            response += `\n`;
            response += `¿Te gustaría saber más sobre ubicación exacta, servicios completos, precios o políticas específicas?`;
            return response;
        }

        // Listar solo hoteles ACTIVOS
        const activeHotels = hotels.filter(h => h.status !== 'Inactivo' && h.status !== 'Mantenimiento');
        
        if (activeHotels.length === 0) {
            return "Disculpa, no tenemos hoteles disponibles en este momento. Déjame conectarte con un agente que podrá ayudarte mejor.";
        }
        
        let response = `🏨 **Nuestros Hoteles Disponibles**\n\nTrabajamos con ${activeHotels.length} hotel${activeHotels.length > 1 ? 'es' : ''} de excelente calidad:\n\n`;
        activeHotels.forEach((hotel, index) => {
            const rating = hotel.rating ? `⭐ ${hotel.rating}/5` : '';
            response += `${index + 1}. **${hotel.name}**\n`;
            response += `   📍 ${hotel.location} ${rating}\n\n`;
        });
        response += `¿Sobre cuál te gustaría más información? Puedo contarte sobre ubicación, servicios, precios o cualquier otro detalle. 😊`;
        return response;
    }

    // Manejar consultas sobre ubicación
    handleLocationQuery(message) {
        const hotels = this.knowledgeBase.getHotelsFromDB();
        let mentionedHotel = this.findHotelInMessage(message, hotels);

        // Si no menciona hotel pero tenemos uno en contexto, usar ese
        if (!mentionedHotel && this.context.currentHotel) {
            mentionedHotel = this.context.currentHotel;
        }
        
        // Si solo hay un hotel, usar ese
        if (!mentionedHotel && hotels.length === 1) {
            mentionedHotel = hotels[0];
        }

        if (!mentionedHotel) {
            // Si no menciona hotel específico, listar todos
            if (hotels.length <= 3) {
                let response = "Aquí tienes las ubicaciones de nuestros hoteles:\n\n";
                hotels.forEach(hotel => {
                    const hotelKnowledge = this.knowledgeBase.getHotelKnowledge(hotel.id);
                    const address = hotelKnowledge ? (hotelKnowledge.address || hotel.address) : (hotel.address || hotel.location);
                    response += `📍 **${hotel.name}**: ${address}\n`;
                });
                response += "\n¿Sobre cuál necesitas más detalles?";
                return response;
            }
            return "¿Sobre qué hotel específico te gustaría saber la ubicación? Puedo ayudarte con cualquiera de nuestros hoteles.";
        }

        this.context.currentHotel = mentionedHotel;
        
        // Verificar si tiene información de Flor IA (soportar ambos formatos)
        const florInfo = mentionedHotel.florInfo || mentionedHotel.flor_info || {};
        
        if (florInfo.transport) {
            let response = `📍 **Ubicación de ${mentionedHotel.name}:**\n\n`;
            response += `${mentionedHotel.location}\n\n`;
            response += `🚗 **Cómo Llegar:**\n${florInfo.transport}`;
            if (mentionedHotel.googleMaps) {
                response += `\n\n🗺️ [Ver en Google Maps](${mentionedHotel.googleMaps})`;
            }
            response += `\n\n¿Necesitas alguna otra información? 😊`;
            return response;
        }
        
        // Obtener información de ubicación desde la base de conocimiento
        const hotelKnowledge = this.knowledgeBase.getHotelKnowledge(mentionedHotel.id);
        const address = hotelKnowledge ? (hotelKnowledge.address || mentionedHotel.address) : (mentionedHotel.address || mentionedHotel.location);
        
        let response = `📍 **${mentionedHotel.name}** está ubicado en:\n\n`;
        response += `${address}\n`;
        response += `📍 Ubicación: ${mentionedHotel.location}\n\n`;
        
        // Agregar información adicional sobre ubicación si está disponible
        if (hotelKnowledge && hotelKnowledge.additionalInfo) {
            if (hotelKnowledge.additionalInfo.transport) {
                response += `🚗 **Transporte:** ${hotelKnowledge.additionalInfo.transport}\n\n`;
            }
            if (hotelKnowledge.additionalInfo.nearbyPoints) {
                response += `📍 **Puntos de interés cercanos:** ${hotelKnowledge.additionalInfo.nearbyPoints}\n\n`;
            }
        }
        
        // Si no tiene información adicional configurada, ofrecer derivar
        if (!hotelKnowledge || !hotelKnowledge.additionalInfo || 
            (!hotelKnowledge.additionalInfo.transport && !hotelKnowledge.additionalInfo.nearbyPoints)) {
            response += `¿Necesitas información sobre cómo llegar, puntos de interés cercanos o algo más sobre la ubicación? Si necesitas detalles específicos, puedo conectarte con un agente que tiene más información.`;
        } else {
            response += `¿Necesitas información adicional sobre la ubicación?`;
        }
        
        return response;
    }

    // Manejar consultas sobre servicios
    handleServicesQuery(message) {
        const hotels = this.knowledgeBase.getHotelsFromDB();
        let mentionedHotel = this.findHotelInMessage(message, hotels);

        // Si no menciona hotel pero tenemos uno en contexto, usar ese
        if (!mentionedHotel && this.context.currentHotel) {
            mentionedHotel = this.context.currentHotel;
            console.log('[Flor] Usando hotel del contexto:', mentionedHotel.name);
        }
        
        // Si solo hay un hotel, usar ese
        if (!mentionedHotel && hotels.length === 1) {
            mentionedHotel = hotels[0];
            console.log('[Flor] Usando único hotel disponible:', mentionedHotel.name);
        }

        if (!mentionedHotel) {
            return "¿Sobre qué hotel te gustaría conocer los servicios? Puedo darte información detallada de cualquier hotel.";
        }

        this.context.currentHotel = mentionedHotel;
        
        // Obtener información completa del hotel desde la base de conocimiento
        const hotelKnowledge = this.knowledgeBase.getHotelKnowledge(mentionedHotel.id);
        
        // Verificar si tiene información de Flor IA cargada (soportar ambos formatos)
        const florInfo = mentionedHotel.florInfo || mentionedHotel.flor_info || {};
        
        // Si tiene información de servicios o excursiones de Flor IA
        if (florInfo.services || florInfo.excursions) {
            let response = `🏨 **${mentionedHotel.name}**\n\n`;
            
            if (florInfo.services) {
                response += `🏊 **Servicios e Instalaciones:**\n${florInfo.services}\n\n`;
            }
            
            if (florInfo.excursions) {
                response += `🎿 **Excursiones y Actividades:**\n${florInfo.excursions}\n\n`;
            }
            
            if (florInfo.policies) {
                response += `📋 **Políticas:**\n${florInfo.policies}\n\n`;
            }
            
            response += `¿Te gustaría saber sobre precios, cómo llegar, o hacer una reserva? 😊`;
            return response;
        }
        
        // Verificar si tiene información específica de servicios en el sistema antiguo
        if (!hotelKnowledge || !hotelKnowledge.servicesDetails || Object.keys(hotelKnowledge.servicesDetails).length === 0) {
            // Si el hotel tiene amenities básicos, mostrarlos
            if (mentionedHotel.amenities && mentionedHotel.amenities.length > 0) {
                let response = `🏨 **Servicios de ${mentionedHotel.name}:**\n\n`;
                response += mentionedHotel.amenities.map(s => `✅ ${s}`).join('\n');
                response += `\n\n📍 Ubicación: ${mentionedHotel.location}`;
                if (mentionedHotel.website) {
                    response += `\n🌐 Más info en: ${mentionedHotel.website}`;
                }
                response += `\n\n¿Te gustaría hacer una reserva o necesitas más detalles? Puedo conectarte con un agente especializado.`;
                return response;
            }
            
            // No tiene información de servicios, dar respuesta general
            let response = `El **${mentionedHotel.name}** está ubicado en ${mentionedHotel.location}.\n\n`;
            response += `⭐ Calificación: ${mentionedHotel.rating || 'N/A'}/5\n\n`;
            if (mentionedHotel.website) {
                response += `🌐 Puedes ver todos los servicios en su web: ${mentionedHotel.website}\n\n`;
            }
            response += `Para información detallada sobre servicios y excursiones, puedo conectarte con un agente especializado. ¿Te parece bien?`;
            return response;
        }

        // Tiene información específica, construir respuesta detallada
        const servicesDetails = hotelKnowledge.servicesDetails;
        const servicesIncluded = [];
        const servicesAdditional = [];
        
        Object.keys(servicesDetails).forEach(key => {
            const service = servicesDetails[key];
            const serviceText = `**${service.name}**${service.description ? ': ' + service.description : ''}`;
            
            if (service.included) {
                servicesIncluded.push(serviceText);
            } else {
                const costText = service.cost > 0 ? ` (Costo adicional: $${service.cost} USD)` : ' (Costo adicional)';
                servicesAdditional.push(serviceText + costText);
            }
        });

        let response = `🎯 **${mentionedHotel.name}** - Servicios y Amenidades:\n\n`;
        
        if (servicesIncluded.length > 0) {
            response += `✅ **Servicios Incluidos:**\n`;
            servicesIncluded.forEach(service => {
                response += `• ${service}\n`;
            });
            response += `\n`;
        }
        
        if (servicesAdditional.length > 0) {
            response += `💰 **Servicios Adicionales (con costo):**\n`;
            servicesAdditional.forEach(service => {
                response += `• ${service}\n`;
            });
            response += `\n`;
        }
        
        response += `¿Necesitas información sobre algún servicio específico o tienes otra consulta?`;
        
        return response;
    }

    // Manejar consultas sobre precios
    handlePricesQuery(message) {
        const hotels = this.knowledgeBase.getHotelsFromDB();
        let mentionedHotel = this.findHotelInMessage(message, hotels);

        // Si no menciona hotel pero tenemos uno en contexto, usar ese
        if (!mentionedHotel && this.context.currentHotel) {
            mentionedHotel = this.context.currentHotel;
        }
        
        // Si solo hay un hotel, usar ese
        if (!mentionedHotel && hotels.length === 1) {
            mentionedHotel = hotels[0];
        }

        if (!mentionedHotel) {
            // Si no menciona hotel específico, dar información general sobre tarifas dinámicas
            let response = "Las tarifas son dinámicas y varían según fecha, pueden variar en alta temporada o en baja temporada.\n\n";
            response += `¿Sobre qué hotel específico te gustaría más información?`;
            return response;
        }

        this.context.currentHotel = mentionedHotel;
        
        // Verificar si tiene información de Flor IA (soportar ambos formatos)
        const florInfo = mentionedHotel.florInfo || mentionedHotel.flor_info || {};
        
        if (florInfo.prices) {
            let response = `💰 **Tarifas de ${mentionedHotel.name}:**\n\n`;
            response += florInfo.prices;
            response += `\n\n📋 *Las tarifas pueden variar según temporada. Para una cotización exacta, indícame: fecha de check-in, cantidad de noches y número de personas.*`;
            response += `\n\n¿Te gustaría solicitar una cotización o hacer una reserva? 😊`;
            return response;
        }
        
        // Obtener información de precios desde la base de conocimiento específica
        const hotelKnowledge = this.knowledgeBase.getHotelKnowledge(mentionedHotel.id);
        
        // Mensaje estándar para tarifas dinámicas
        const dynamicPriceMessage = "Las tarifas son dinámicas y varían según fecha, pueden variar en alta temporada o en baja temporada. Para una cotización precisa solicítela con: Fecha de Check-in, cantidad de noches y cantidad de personas. Las tarifas enviadas tienen validez de 24 horas.";
        
        // Verificar si tiene información de precios configurada
        if (!hotelKnowledge || !hotelKnowledge.priceInfo) {
            // No tiene información de precios específica, usar mensaje estándar
            let response = `💰 Información sobre tarifas para **${mentionedHotel.name}**:\n\n`;
            response += dynamicPriceMessage;
            return response;
        }
        
        // Tiene información de precios, proporcionarla (usar mensaje de tarifas dinámicas)
        const priceInfo = hotelKnowledge.priceInfo;
        let response = `💰 Información sobre tarifas para **${mentionedHotel.name}**:\n\n`;
        response += priceInfo.message || dynamicPriceMessage;
        
        return response;
    }

    // Detectar si el usuario menciona un hotel que NO está registrado
    detectUnregisteredHotel(message, registeredHotels) {
        const messageLower = message.toLowerCase();
        
        // Obtener solo hoteles activos
        const activeHotels = registeredHotels.filter(h => h.status !== 'Inactivo' && h.status !== 'Mantenimiento');
        
        // Lista de palabras que indican que están preguntando por un hotel específico
        const hotelIndicators = ['hotel', 'resort', 'termas', 'cabañas', 'lodge', 'hostal', 'hostería', 'llao', 'info de', 'información de', 'informacion de', 'sobre el', 'sobre'];
        
        // Verificar si menciona algún indicador de hotel o nombre específico
        const mentionsHotelType = hotelIndicators.some(indicator => messageLower.includes(indicator));
        
        // Verificar si el hotel mencionado está en nuestra lista de hoteles ACTIVOS
        const foundRegistered = this.findHotelInMessage(message, activeHotels);
        if (foundRegistered) return null; // Si lo encontramos registrado y activo, no es un hotel no registrado
        
        // Si menciona algún indicador de hotel pero no encontramos coincidencia, es un hotel no registrado
        if (mentionsHotelType) {
            // Intentar extraer el nombre del hotel mencionado
            // Patrones comunes: "hotel llao llao", "info de corralco", "termas de chillan"
            const patterns = [
                /(?:hotel|resort|termas|cabañas|lodge|hostal|hostería)\s+([a-záéíóúñü\s-]+)/i,
                /(?:info(?:rmación)?|información)\s+(?:de|del|sobre)\s+(?:hotel\s+)?([a-záéíóúñü\s-]+)/i,
                /(?:sobre|del?)\s+(?:hotel\s+)?([a-záéíóúñü\s-]+?)(?:\?|$)/i,
                /([a-záéíóúñü]{4,})\s+(?:hotel|resort)/i
            ];
            
            for (const pattern of patterns) {
                const match = messageLower.match(pattern);
                if (match && match[1]) {
                    const potentialHotelName = match[1].trim();
                    // Verificar que no sea una palabra genérica
                    const genericWords = ['que', 'los', 'las', 'del', 'para', 'este', 'ese', 'cual', 'cuál', 'tienen', 'trabajan', 'hoteles'];
                    if (potentialHotelName.length > 2 && !genericWords.includes(potentialHotelName)) {
                        // Verificar que no coincida con ninguno de nuestros hoteles activos (incl. alias futangue/futanque)
                        const isRegistered = activeHotels.some(h => {
                            const hotelNameLower = (h.name || '').toLowerCase();
                            if (hotelNameLower.includes(potentialHotelName) || potentialHotelName.includes(hotelNameLower.replace('hotel ', '').trim())) return true;
                            const keyForAlias = FlorAgent.HOTEL_NAME_ALIASES[potentialHotelName];
                            if (keyForAlias && hotelNameLower.includes(keyForAlias)) return true;
                            return false;
                        });
                        if (!isRegistered) {
                            // Capitalizar primera letra
                            const formattedName = potentialHotelName.split(' ')
                                .map(w => w.charAt(0).toUpperCase() + w.slice(1))
                                .join(' ');
                            return formattedName;
                        }
                    }
                }
            }
            
            // Si menciona "hotel" pero no pudimos extraer el nombre, probablemente es un hotel no registrado
            if (messageLower.includes('hotel') || messageLower.includes('resort') || messageLower.includes('termas')) {
                // Extraer palabras después de "hotel/resort/termas"
                const simpleMatch = messageLower.match(/(?:hotel|resort|termas)\s+(\w+(?:\s+\w+)?)/i);
                if (simpleMatch && simpleMatch[1]) {
                    const name = simpleMatch[1].trim();
                    const isRegistered = activeHotels.some(h => h.name.toLowerCase().includes(name));
                    if (!isRegistered && name.length > 2) {
                        return name.charAt(0).toUpperCase() + name.slice(1);
                    }
                }
            }
        }
        
        return null;
    }

    // Alias de nombres (mismo criterio que WhatsApp): variantes y typos para reconocer el hotel
    static HOTEL_NAME_ALIASES = { futanque: 'futangue', futangue: 'futangue', furtangue: 'futangue', puyehue: 'puyehue', huilo: 'huilo', guilo: 'huilo', corralco: 'corralco', llao: 'llao' };

    // Buscar hotel mencionado en el mensaje (mejorado para búsqueda parcial + alias como WhatsApp)
    findHotelInMessage(message, hotels) {
        const messageLower = message.toLowerCase();
        
        return hotels.find(hotel => {
            const hotelNameLower = (hotel.name || '').toLowerCase();
            const hotelLocationLower = (hotel.location || '').toLowerCase();
            const hotelAddressLower = hotel.address ? hotel.address.toLowerCase() : '';
            
            // Alias: si el mensaje contiene "futangue"/"futanque" etc., matchear hotel cuyo nombre contenga la clave
            for (const [alias, key] of Object.entries(FlorAgent.HOTEL_NAME_ALIASES)) {
                if (messageLower.includes(alias) && hotelNameLower.includes(key)) return true;
            }
            
            // Búsqueda exacta
            if (messageLower.includes(hotelNameLower) || 
                messageLower.includes(hotelLocationLower) ||
                (hotelAddressLower && messageLower.includes(hotelAddressLower))) {
                return true;
            }
            
            // Búsqueda parcial: buscar palabras del nombre del hotel en el mensaje
            const hotelNameWords = hotelNameLower.split(/\s+/);
            const commonWords = ['de', 'la', 'el', 'y', 'en', 'a', 'del', 'las', 'los'];
            const hasHotelWord = hotelNameWords.some(word => {
                if (word.length < 4 || commonWords.includes(word)) return false;
                return messageLower.includes(word);
            });
            
            if (hasHotelWord) return true;
            
            // Búsqueda parcial: buscar palabras del mensaje en el nombre del hotel
            const messageWords = messageLower.split(/\s+/).filter(word => word.length >= 4);
            const hasMessageWord = messageWords.some(word => hotelNameLower.includes(word));
            
            if (hasMessageWord) return true;
            
            // Búsqueda en ubicación (más flexible)
            const locationWords = hotelLocationLower.split(/\s*,\s*/);
            const hasLocationMatch = locationWords.some(loc => messageLower.includes(loc.trim()));
            
            return hasLocationMatch;
        });
    }

    // Verificar si debe escalar a humano
    shouldEscalateToHuman(message) {
        const intents = this.knowledgeBase.intents;
        
        // Escalación inmediata si:
        // 1. Solicita explícitamente humano/agente/asesor
        if (this.matchesIntent(message, intents.contacto_humano)) return true;
        
        // 2. Quiere reservar
        if (this.matchesIntent(message, intents.reservar)) return true;
        
        // 3. Tiene un problema
        if (this.matchesIntent(message, intents.problema)) return true;

        return false;
    }

    // Respuesta de escalación
    getEscalationResponse() {
        return {
            message: this.knowledgeBase.responses.transferir_humano,
            escalate: true,
            escalateReason: 'Solicitud del usuario o necesidad de información especializada'
        };
    }

    // Reiniciar conversación
    reset() {
        this.conversationHistory = [];
        this.shouldEscalate = false;
        this.context = {
            currentHotel: null,
            currentIntent: null,
            lastMessage: null
        };
    }

    // Obtener historial de conversación
    getHistory() {
        return this.conversationHistory;
    }

    // Determinar si se debe enviar una imagen de hotel
    shouldSendHotelImage(response, context) {
        // Verificar si la respuesta menciona un hotel específico
        if (context.currentHotel) {
            // Verificar si el usuario pregunta por apariencia, fotos, imágenes, etc.
            const imageKeywords = ['foto', 'imagen', 'fotografía', 'apariencia', 'cómo se ve', 'cómo luce', 'ver', 'mostrar'];
            const lastMessageLower = (context.lastMessage || '').toLowerCase();
            const hasImageRequest = imageKeywords.some(keyword => lastMessageLower.includes(keyword));
            
            if (hasImageRequest) {
                return {
                    hotelId: context.currentHotel.id,
                    hotelName: context.currentHotel.name,
                    type: 'main' // o 'gallery' según el contexto
                };
            }
        }
        return null;
    }

    // Obtener URL de imagen de hotel
    async getHotelImageUrl(hotelId, hotelName, type = 'main') {
        try {
            // Llamar al endpoint del servidor
            const baseUrl = window.location.origin;
            const response = await fetch(`${baseUrl}/api/hoteles/imagen/${encodeURIComponent(hotelName)}?type=${type}`);
            if (response.ok) {
                const data = await response.json();
                // Construir URL completa
                const imageUrl = data.imageUrl ? `${baseUrl}${data.imageUrl}` : null;
                return imageUrl;
            } else {
                console.warn('[Flor Agent] No se pudo obtener imagen del servidor, usando ruta local');
                // Fallback: construir ruta local basada en el patrón conocido
                const hotelSlug = this.getHotelSlugFromName(hotelName);
                return `/hotel-images/hotel-${hotelId}-${hotelSlug}/${type === 'main' ? 'main' : type}.jpg`;
            }
        } catch (error) {
            console.error('[Flor Agent] Error al obtener imagen de hotel:', error);
            // Fallback: construir ruta local
            const hotelSlug = this.getHotelSlugFromName(hotelName);
            return `/hotel-images/hotel-${hotelId}-${hotelSlug}/${type === 'main' ? 'main' : type}.jpg`;
        }
    }

    // Función auxiliar para obtener slug del nombre del hotel
    getHotelSlugFromName(hotelName) {
        let cleanName = hotelName.replace(/^hotel\s+/i, '');
        return cleanName.toLowerCase()
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .trim();
    }
}

// Exportar para uso en otros archivos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FlorAgent;
}

