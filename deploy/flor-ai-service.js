// Servicio de IA para Flor - Integración con APIs de Inteligencia Artificial
// Checkin24hs - Asistente Virtual Inteligente

class FlorAIService {
    constructor() {
        this.config = {
            enabled: false,
            provider: 'openai', // 'openai', 'gemini', 'claude', 'custom'
            apiKey: null,
            apiUrl: null,
            model: 'gpt-4o-mini', // Modelo por defecto
            temperature: 0.7,
            maxTokens: 500
        };
        
        // Cargar configuración desde localStorage
        this.loadConfig();
    }

    // Cargar configuración guardada
    loadConfig() {
        try {
            const saved = localStorage.getItem('flor_ai_config');
            if (saved) {
                const parsed = JSON.parse(saved);
                this.config = { ...this.config, ...parsed };
                console.log('[Flor AI] ✅ Configuración cargada desde localStorage');
            }
            
            // También intentar cargar desde Supabase (asíncrono)
            this.loadConfigFromSupabase();
        } catch (e) {
            console.error('[Flor AI] Error al cargar configuración:', e);
        }
    }
    
    // Cargar configuración desde Supabase
    async loadConfigFromSupabase() {
        try {
            if (typeof window !== 'undefined' && window.supabaseClient && window.supabaseClient.isInitialized()) {
                const { data, error } = await window.supabaseClient.client
                    .from('system_config')
                    .select('value')
                    .eq('key', 'flor_ai_config')
                    .single();
                
                if (!error && data && data.value) {
                    const cloudConfig = JSON.parse(data.value);
                    // Solo actualizar si la config de la nube tiene API key
                    if (cloudConfig.apiKey) {
                        this.config = { ...this.config, ...cloudConfig };
                        // Guardar también en localStorage para acceso rápido
                        localStorage.setItem('flor_ai_config', JSON.stringify(this.config));
                        console.log('[Flor AI] ☁️ Configuración sincronizada desde Supabase');
                    }
                }
            }
        } catch (e) {
            // Silencioso si falla - usará localStorage
            console.log('[Flor AI] ℹ️ Usando configuración de localStorage');
        }
    }

    // Guardar configuración
    saveConfig() {
        try {
            localStorage.setItem('flor_ai_config', JSON.stringify(this.config));
            console.log('[Flor AI] ✅ Configuración guardada');
        } catch (e) {
            console.error('[Flor AI] Error al guardar configuración:', e);
        }
    }

    // Configurar el servicio de IA
    configure(options) {
        this.config = { ...this.config, ...options };
        this.saveConfig();
        console.log('[Flor AI] 🔧 Configuración actualizada:', this.config);
    }

    // Generar respuesta usando IA con contexto de la base de conocimiento
    async generateAIResponse(userMessage, context = {}) {
        if (!this.config.enabled || !this.config.apiKey) {
            console.log('[Flor AI] ⚠️ IA deshabilitada o sin API key');
            return null;
        }

        try {
            const knowledgeBase = FlorKnowledgeBase;
            const hotels = knowledgeBase.getHotelsFromDB();
            
            // Construir contexto para la IA (incluir userMessage para detectar integraciones)
            context.userMessage = userMessage;
            const systemPrompt = this.buildSystemPrompt(knowledgeBase, hotels, context);
            const userPrompt = this.buildUserPrompt(userMessage, context);

            let response;

            switch (this.config.provider) {
                case 'openai':
                    response = await this.callOpenAI(systemPrompt, userPrompt);
                    break;
                case 'gemini':
                    response = await this.callGemini(systemPrompt, userPrompt);
                    break;
                case 'claude':
                    response = await this.callClaude(systemPrompt, userPrompt);
                    break;
                case 'custom':
                    response = await this.callCustomAPI(systemPrompt, userPrompt);
                    break;
                default:
                    throw new Error(`Proveedor no soportado: ${this.config.provider}`);
            }

            return response;

        } catch (error) {
            console.error('[Flor AI] ❌ Error al generar respuesta:', error);
            console.error('[Flor AI] 📋 Detalles del error:', {
                message: error.message,
                stack: error.stack,
                name: error.name,
                provider: this.config.provider,
                enabled: this.config.enabled,
                hasApiKey: !!this.config.apiKey
            });
            return null; // Retornar null para usar fallback
        }
    }

    // Construir prompt del sistema con toda la información de Flor
    buildSystemPrompt(knowledgeBase, hotels, context) {
        let prompt = `Eres Flor, una asistente virtual profesional y amable de Checkin24hs, una agencia de viajes y hoteles.

CAPACIDADES MULTIMODALES:
- Puedes recibir y analizar imágenes enviadas por los clientes
- Puedes recibir y transcribir audios enviados por los clientes
- Puedes enviar imágenes de hoteles cuando el cliente lo solicite o cuando sea relevante

TU PERSONALIDAD:
- Amable, eficiente y profesional
- Siempre mantén un tono cálido y servicial
- Responde en español
- Usa emoticones (emoji) apropiados para hacer las respuestas más amigables y visuales

REGLAS CRÍTICAS PARA RESPONDER:
1. Cuando pregunten "qué hoteles trabajan", "qué hoteles tienen", "lista de hoteles" o similar → SIEMPRE lista TODOS los hoteles disponibles con su ubicación
2. Cuando pregunten sobre "ubicación" sin especificar hotel → muestra las ubicaciones de TODOS los hoteles
3. NUNCA digas "no entendí" si puedes dar información útil sobre hoteles
4. Si la pregunta es genérica, ofrece la lista de hoteles y pregunta cuál les interesa

🌐 ACCESO A INFORMACIÓN WEB DE HOTELES:
- Para cada hotel registrado, tienes acceso a su SITIO WEB OFICIAL
- Cuando te pregunten sobre un hotel registrado, DEBES usar la información de su sitio web oficial para responder
- Si el hotel tiene URL de sitio web, usa esa información como fuente principal y confiable
- Responde con información precisa basándote en los datos del sitio web oficial del hotel

⚠️ HOTELES NO REGISTRADOS O INACTIVOS:
- Si el usuario pregunta por un hotel que NO está en la lista de hoteles registrados → Responde: "Por el momento no estamos trabajando con ese hotel, pero esperamos poder incorporarlo a la brevedad. ¿Te gustaría información sobre alguno de nuestros hoteles disponibles?"
- Si el hotel está en estado "Inactivo" o "Mantenimiento" → Responde: "Ese hotel no está disponible actualmente. ¿Te gustaría ver nuestros hoteles disponibles?"
- SOLO proporciona información de hoteles que estén ACTIVOS y REGISTRADOS en el sistema

FORMATO Y PRESENTACIÓN DE TUS RESPUESTAS:
IMPORTANTE: Debes estructurar tus respuestas de forma visual y atractiva usando Markdown.

1. TÍTULOS Y ESTRUCTURA:
   - Usa **negritas** para títulos principales (ej: **🏨 Hotel Terma de Puyehue**)
   - Usa *cursiva* para énfasis secundario
   - Separa información en párrafos cortos (2-3 líneas máximo cada uno)

2. ESTRUCTURA RECOMENDADA:
   - Comienza con un título en negritas con emoji relevante
   - Usa viñetas (• o -) para listas
   - Separa secciones con saltos de línea
   - Usa emojis relevantes: 🏨 (hotel), 📍 (ubicación), 💰 (precios), 🎯 (servicios), ⭐ (calificación), 📞 (contacto), etc.

3. LONGITUD Y PRECISIÓN:
   - Sé MUY CONCISA: máximo 80-100 palabras por respuesta (OBLIGATORIO)
   - Proporciona SOLO la información esencial y directamente relevante
   - Responde directamente la pregunta sin información innecesaria
   - Evita explicaciones largas o detalles excesivos
   - Si necesitas dar más información, hazlo en puntos muy cortos (máximo 3-4 puntos)
   - Prioriza la brevedad sobre la exhaustividad

4. EJEMPLO DE FORMATO:
   **🏨 Hotel Terma de Puyehue**
   
   📍 **Ubicación:** Osorno, Los Lagos, Chile
   
   ✨ [Descripción breve de 2-3 líneas]
   
   🎯 **Servicios principales:**
   • Spa Termal (incluido)
   • Restaurante Gourmet
   • Piscina climatizada
   
   💰 **Precios:** Las tarifas son dinámicas...

5. EMOTICONES A USAR:
   🏨 (hoteles), 📍 (ubicación), 💰 (precios), 🎯 (servicios), ⭐ (calificación), ✨ (características), 📞 (contacto), ✅ (incluido), ⚠️ (importante), 🔔 (notificación), 🎉 (especial)

TU CONOCIMIENTO:

Hoteles disponibles:
`;
        
        // Agregar información de hoteles
        hotels.forEach(hotel => {
            const hotelKnowledge = knowledgeBase.getHotelKnowledge(hotel.id);
            // Obtener información de Flor IA (soportar ambos formatos)
            const florInfo = hotel.florInfo || hotel.flor_info || {};
            
            prompt += `\n--- ${hotel.name} (${hotel.location}) ---\n`;
            prompt += `Estado: ${hotel.status || 'Activo'}\n`;
            prompt += `Calificación: ${hotel.rating || 'N/A'}/5\n`;
            
            // PRIORIZAR información de Flor IA si existe
            if (florInfo.description) {
                prompt += `DESCRIPCIÓN DETALLADA: ${florInfo.description}\n`;
            } else if (hotelKnowledge && hotelKnowledge.description) {
                prompt += `DESCRIPCIÓN: ${hotelKnowledge.description}\n`;
            } else if (hotel.description) {
                prompt += `DESCRIPCIÓN: ${hotel.description}\n`;
            }
            
            // Servicios e instalaciones de Flor IA
            if (florInfo.services) {
                prompt += `SERVICIOS E INSTALACIONES:\n${florInfo.services}\n`;
            } else if (hotelKnowledge && hotelKnowledge.servicesDetails) {
                const services = Object.values(hotelKnowledge.servicesDetails);
                prompt += `SERVICIOS DISPONIBLES:\n`;
                services.forEach(service => {
                    prompt += `  - ${service.name}`;
                    if (service.description) prompt += `: ${service.description}`;
                    if (service.cost && service.cost !== 'Incluido') prompt += ` (Costo: ${service.cost})`;
                    if (service.included) prompt += ` [INCLUIDO]`;
                    prompt += `\n`;
                });
            } else if (hotel.amenities && hotel.amenities.length > 0) {
                prompt += `AMENITIES: ${Array.isArray(hotel.amenities) ? hotel.amenities.join(', ') : hotel.amenities}\n`;
            }
            
            // Excursiones y actividades de Flor IA
            if (florInfo.excursions) {
                prompt += `EXCURSIONES Y ACTIVIDADES:\n${florInfo.excursions}\n`;
            }
            
            // Información de precios de Flor IA
            if (florInfo.prices) {
                prompt += `INFORMACIÓN DE PRECIOS Y TARIFAS:\n${florInfo.prices}\n`;
            } else if (hotelKnowledge && hotelKnowledge.priceInfo && hotelKnowledge.priceInfo.message) {
                prompt += `INFORMACIÓN DE PRECIOS: ${hotelKnowledge.priceInfo.message}\n`;
            } else {
                prompt += `INFORMACIÓN DE PRECIOS: Las tarifas son dinámicas y varían según fecha. Para una cotización precisa solicítela con: Fecha de Check-in, cantidad de noches y cantidad de personas. Las tarifas enviadas tienen validez de 24 horas.\n`;
            }
            
            // Políticas de Flor IA
            if (florInfo.policies) {
                prompt += `POLÍTICAS DEL HOTEL:\n${florInfo.policies}\n`;
            } else if (hotelKnowledge && hotelKnowledge.policies) {
                prompt += `POLÍTICAS ESPECÍFICAS: ${JSON.stringify(hotelKnowledge.policies)}\n`;
            }
            
            // Cómo llegar de Flor IA
            if (florInfo.transport) {
                prompt += `CÓMO LLEGAR / TRANSPORTE:\n${florInfo.transport}\n`;
            }
            
            // Contacto de Flor IA
            if (florInfo.contact) {
                prompt += `CONTACTO: ${florInfo.contact}\n`;
            }
            
            // Sitio web
            if (hotel.website) {
                prompt += `SITIO WEB OFICIAL: ${hotel.website}\n`;
            }
            
            // Google Maps
            if (hotel.googleMaps || hotel.google_maps) {
                prompt += `GOOGLE MAPS: ${hotel.googleMaps || hotel.google_maps}\n`;
            }
            
            if (hotelKnowledge && hotelKnowledge.address) {
                prompt += `DIRECCIÓN: ${hotelKnowledge.address}\n`;
            }
            
            if (hotelKnowledge && hotelKnowledge.roomTypes && hotelKnowledge.roomTypes.length > 0) {
                prompt += `TIPOS DE HABITACIONES: ${hotelKnowledge.roomTypes.join(', ')}\n`;
            }
            
            if (hotelKnowledge && hotelKnowledge.additionalInfo) {
                prompt += `INFORMACIÓN ADICIONAL: ${JSON.stringify(hotelKnowledge.additionalInfo)}\n`;
            }
            
            // Información del sitio web del hotel
            if (hotelKnowledge && hotelKnowledge.websiteInfo) {
                prompt += `\n📌 INFORMACIÓN DEL SITIO WEB OFICIAL DEL HOTEL:\n${hotelKnowledge.websiteInfo}\n`;
            }
            
            // URL del sitio web - IMPORTANTE para búsqueda de información
            if (hotel.website || (hotelKnowledge && hotelKnowledge.website)) {
                const websiteUrl = hotel.website || hotelKnowledge.website;
                prompt += `\n🌐 SITIO WEB OFICIAL: ${websiteUrl}`;
                prompt += `\n💡 INSTRUCCIÓN: Cuando el usuario pregunte sobre este hotel, usa la información del sitio web oficial (${websiteUrl}) como fuente principal. Si necesitas más detalles, puedes acceder a esa URL para obtener información actualizada.\n`;
            }
            
            // Estado del hotel
            const hotelStatus = hotel.status || 'Activo';
            prompt += `📊 ESTADO: ${hotelStatus}\n`;
            
            prompt += '\n';
        });
        
        // Agregar lista de hoteles registrados para validación
        prompt += `\n=== LISTA DE HOTELES REGISTRADOS (ACTIVOS) ===\n`;
        const activeHotels = hotels.filter(h => h.status !== 'Inactivo' && h.status !== 'Mantenimiento');
        activeHotels.forEach(h => {
            prompt += `✅ ${h.name} - ${h.location}${h.website ? ' (Web: ' + h.website + ')' : ''}\n`;
        });
        prompt += `\n⚠️ IMPORTANTE: Solo proporciona información de los hoteles listados arriba. Si preguntan por otro hotel, indica que no trabajamos con ese hotel actualmente.\n`;

        // Agregar políticas (por hotel si existe, sino generales)
        let policies = knowledgeBase.policies; // Políticas generales por defecto
        let hotelPolicies = null;
        
        if (context.currentHotel) {
            const hotelKnowledge = knowledgeBase.getHotelKnowledge(context.currentHotel.id);
            if (hotelKnowledge && hotelKnowledge.policies) {
                hotelPolicies = hotelKnowledge.policies; // Usar políticas específicas del hotel
            }
        }
        
        // Formato nuevo simplificado o formato antiguo (compatibilidad)
        if (hotelPolicies) {
            if (hotelPolicies.condiciones_reserva || hotelPolicies.cancelacion_modificacion) {
                // Formato nuevo simplificado
                prompt += `
POLÍTICAS ESPECÍFICAS DEL HOTEL:

1. Condiciones para la Reserva:
${hotelPolicies.condiciones_reserva || 'No especificadas'}

2. Políticas de Cancelación o Modificación:
${hotelPolicies.cancelacion_modificacion || 'No especificadas'}
`;
            } else {
                // Formato antiguo (compatibilidad)
                prompt += `
Políticas de reserva (formato antiguo - migrar a nuevo formato):
- Depósito: ${hotelPolicies.reserva?.deposito || 'No especificado'}
- Métodos de pago: ${(hotelPolicies.reserva?.metodos_pago || []).join(', ') || 'No especificados'}
- Cancelación gratuita: ${hotelPolicies.cancelacion?.gratuita_hasta || 'No especificada'}
- Check-in: ${hotelPolicies.checkin_checkout?.checkin_horario || 'No especificado'}
- Check-out: ${hotelPolicies.checkin_checkout?.checkout_horario || 'No especificado'}
`;
            }
        } else {
            // Políticas generales (formato antiguo o nuevo)
            if (policies.condiciones_reserva || policies.cancelacion_modificacion) {
                prompt += `
POLÍTICAS GENERALES DE LA AGENCIA:

1. Condiciones para la Reserva:
${policies.condiciones_reserva || 'No especificadas'}

2. Políticas de Cancelación o Modificación:
${policies.cancelacion_modificacion || 'No especificadas'}
`;
            } else {
                // Formato antiguo (compatibilidad)
                prompt += `
Políticas generales de reserva:
- Depósito: ${policies.reserva?.deposito || 'No especificado'}
- Métodos de pago: ${(policies.reserva?.metodos_pago || []).join(', ') || 'No especificados'}
- Cancelación gratuita: ${policies.cancelacion?.gratuita_hasta || 'No especificada'}
- Check-in: ${policies.checkin_checkout?.checkin_horario || 'No especificado'}
- Check-out: ${policies.checkin_checkout?.checkout_horario || 'No especificado'}
`;
            }
        }

        prompt += `
INSTRUCCIONES IMPORTANTES:
1. ESTRUCTURA TUS RESPUESTAS:
   - Usa **negritas** para títulos y puntos importantes
   - Usa emojis relevantes al inicio de cada sección
   - Separa información en párrafos cortos (máximo 2-3 líneas)
   - Usa viñetas (•) para listas de servicios, características, etc.
   - Máximo 150-200 palabras por respuesta (sé concisa pero completa)

2. INFORMACIÓN PRECISA:
   - Proporciona información COMPLETA y PRECISA usando TODO el conocimiento disponible
   - Responde directamente la pregunta sin rodeos
   - Si mencionan un hotel por nombre parcial (ej: "Puyehue"), identifica el hotel completo (ej: "Hotel Terma de Puyehue")

3. CUANDO ESCALAR:
   - SOLO deriva a un agente humano si:
     * El usuario explícitamente dice "quiero reservar", "hacer reserva", "confirmar reserva", "agendar"
     * El usuario explícitamente pide "cancelar" una reserva existente
     * NO tienes NINGUNA información sobre lo que pregunta (después de revisar todo el conocimiento disponible)

4. ESTILO:
   - Mantén un tono conversacional, natural y amable
   - Usa emojis apropiados para mejorar la presentación visual
   - Responde siempre en español
   - Identifica párrafos naturales y sepáralos correctamente

`;

        // Agregar contexto de la conversación si existe
        if (context.currentHotel) {
            prompt += `CONTEXTO ACTUAL: El usuario está consultando sobre ${context.currentHotel.name}\n\n`;
        }

        // Agregar información de imagen si fue procesada
        if (context.lastImage) {
            prompt += `IMAGEN RECIBIDA: El usuario envió una imagen que fue analizada.\n`;
            prompt += `Descripción de la imagen: ${context.lastImage.description}\n`;
            if (context.lastImage.objects && context.lastImage.objects.length > 0) {
                prompt += `Objetos detectados: ${context.lastImage.objects.join(', ')}\n`;
            }
            if (context.lastImage.labels && context.lastImage.labels.length > 0) {
                prompt += `Elementos identificados: ${context.lastImage.labels.join(', ')}\n`;
            }
            prompt += `\nIMPORTANTE: Si la imagen muestra un hotel, habitación, o problema relacionado con reservas, usa esta información para responder de manera precisa.\n`;
            prompt += `Si el usuario pregunta por fotos o imágenes de un hotel, puedes indicar que puedes enviar una imagen usando el formato especial: [SEND_IMAGE:nombre_hotel]\n\n`;
        }

        // Agregar integraciones específicas si la consulta del usuario las requiere
        // Buscar en todos los hoteles si no hay un hotel específico en el contexto
        let triggeredIntegration = null;
        let integrationHotelId = null;
        
        if (context.userMessage) {
            if (context.currentHotel) {
                // Si hay un hotel en el contexto, buscar integraciones solo en ese hotel
                triggeredIntegration = knowledgeBase.detectIntegrationTrigger(
                    context.userMessage, 
                    context.currentHotel.id
                );
                if (triggeredIntegration) {
                    integrationHotelId = context.currentHotel.id;
                }
            } else {
                // Si no hay hotel en el contexto, buscar en todos los hoteles
                const hotels = knowledgeBase.getHotelsFromDB();
                for (const hotel of hotels) {
                    const integration = knowledgeBase.detectIntegrationTrigger(
                        context.userMessage,
                        hotel.id
                    );
                    if (integration) {
                        triggeredIntegration = integration;
                        integrationHotelId = hotel.id;
                        // Establecer el hotel en el contexto para futuras consultas
                        context.currentHotel = hotel;
                        break;
                    }
                }
            }
            
            if (triggeredIntegration && integrationHotelId) {
                const integrationContext = knowledgeBase.getIntegrationContext(
                    triggeredIntegration, 
                    integrationHotelId
                );
                
                if (integrationContext) {
                    prompt += integrationContext;
                    // Guardar la integración activada en el contexto para enviarla después
                    context.triggeredIntegration = triggeredIntegration;
                    context.integrationHotelId = integrationHotelId;
                }
            }
        }

        return prompt;
    }

    // Construir prompt del usuario
    buildUserPrompt(userMessage, context) {
        return userMessage;
    }

    // Llamar a OpenAI API
    async callOpenAI(systemPrompt, userPrompt) {
        const url = this.config.apiUrl || 'https://api.openai.com/v1/chat/completions';
        
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.config.apiKey}`
            },
            body: JSON.stringify({
                model: this.config.model,
                messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: userPrompt }
                ],
                temperature: this.config.temperature,
                max_tokens: Math.min(this.config.maxTokens, 200) // Limitar a 200 tokens para respuestas muy concisas
            })
        });

        if (!response.ok) {
            const error = await response.json().catch(() => ({}));
            throw new Error(error.error?.message || `Error ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        let responseText = data.choices[0]?.message?.content?.trim() || null;
        
        // Procesar comandos especiales en la respuesta (ej: [SEND_IMAGE:nombre_hotel])
        if (responseText) {
            responseText = this.processSpecialCommands(responseText, context);
        }
        
        return responseText;
    }

    // Listar modelos disponibles de Gemini
    async listGeminiModels() {
        const apiVersions = ['v1beta', 'v1'];
        
        for (const apiVersion of apiVersions) {
            try {
                const url = `https://generativelanguage.googleapis.com/${apiVersion}/models?key=${this.config.apiKey}`;
                console.log(`[Flor AI] 🔍 Listando modelos disponibles con ${apiVersion}...`);
                
                const response = await fetch(url);
                
                if (!response.ok) {
                    console.warn(`[Flor AI] ⚠️ Error al listar modelos con ${apiVersion}: ${response.status}`);
                    continue;
                }
                
                const data = await response.json();
                const models = data.models?.filter(m => 
                    m.supportedGenerationMethods?.includes('generateContent')
                ) || [];
                
                if (models.length > 0) {
                    const modelNames = models.map(m => m.name.replace('models/', ''));
                    console.log(`[Flor AI] ✅ Modelos disponibles con ${apiVersion}:`, modelNames);
                    return { version: apiVersion, models: modelNames };
                }
            } catch (error) {
                console.warn(`[Flor AI] ⚠️ Excepción al listar modelos con ${apiVersion}:`, error.message);
                continue;
            }
        }
        
        return null;
    }

    // Llamar a Google Gemini API
    async callGemini(systemPrompt, userPrompt) {
        // Primero, intentar listar modelos disponibles
        let availableModelsInfo = null;
        try {
            availableModelsInfo = await this.listGeminiModels();
        } catch (error) {
            console.warn('[Flor AI] ⚠️ No se pudieron listar modelos, usando lista por defecto');
        }
        
        // Modelos por defecto si no se pueden listar
        const defaultModels = [
            'gemini-1.5-flash',
            'gemini-1.5-pro',
            'gemini-1.0-pro',
            'gemini-pro',
            'gemini-1.5-flash-latest',
            'gemini-1.5-pro-latest'
        ];
        
        // Usar modelos listados o los por defecto
        const apiVersion = availableModelsInfo?.version || 'v1beta';
        const availableModels = availableModelsInfo?.models || defaultModels;
        
        // Priorizar modelos gratuitos (flash, flash-lite, lite) sobre modelos pro/preview que requieren facturación
        const freeModels = availableModels.filter(m => 
            (m.includes('flash') && !m.includes('preview') && !m.includes('exp') && !m.includes('pro')) ||
            m.includes('flash-lite') || 
            m.includes('lite-latest') ||
            m === 'gemini-flash-latest'
        );
        
        const preferredModels = freeModels.length > 0 ? freeModels : ['gemini-2.5-flash', 'gemini-flash-latest'];
        
        // Intentar primero con el modelo configurado si está en la lista de modelos gratuitos
        let model = this.config.model;
        
        // Si el modelo configurado no está en la lista de gratuitos, o no está disponible, usar uno gratuito
        if (!model || 
            !availableModels.some(m => m === model || m.includes(model.replace('models/', ''))) ||
            (preferredModels.length > 0 && !preferredModels.some(m => m === model || m.includes(model.replace('models/', ''))))) {
            model = preferredModels[0] || availableModels[0];
            console.log(`[Flor AI] 📝 Usando modelo gratuito: ${model}`);
        }
        
        // Crear lista de modelos a probar: primero los gratuitos preferidos, luego el configurado, luego los demás
        const otherModels = availableModels.filter(m => 
            m !== model && !preferredModels.includes(m)
        );
        
        // Construir lista priorizando modelos gratuitos
        let modelsToTry = [];
        if (model && preferredModels.some(m => m === model || m.includes(model.replace('models/', '')))) {
            modelsToTry.push(model, ...preferredModels.filter(m => m !== model && !m.includes(model.replace('models/', ''))));
        } else {
            modelsToTry.push(...preferredModels);
            if (model && availableModels.includes(model)) {
                modelsToTry.push(model);
            }
        }
        modelsToTry.push(...otherModels);
        
        console.log(`[Flor AI] 🔄 Modelos a probar: ${modelsToTry.join(', ')}`);
        
        let lastError = null;
        
        for (const modelToTry of modelsToTry) {
            try {
                // Limpiar el nombre del modelo (eliminar prefijo 'models/' si existe)
                const cleanModel = modelToTry.replace('models/', '');
                
                // Gemini requiere la API key en la URL
                const url = `https://generativelanguage.googleapis.com/${apiVersion}/models/${cleanModel}:generateContent?key=${this.config.apiKey}`;
                
                // Gemini usa un formato diferente - combina system y user en un solo prompt
                const fullPrompt = `${systemPrompt}\n\nUsuario: ${userPrompt}\n\nAsistente:`;
                
                console.log(`[Flor AI] 🔄 Intentando con ${apiVersion} y modelo ${cleanModel}...`);
                
                const response = await fetch(url, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        contents: [{
                            parts: [{
                                text: fullPrompt
                            }]
                        }],
                        generationConfig: {
                            temperature: this.config.temperature,
                            maxOutputTokens: Math.min(this.config.maxTokens, 200) // Limitar a 200 tokens para respuestas muy concisas
                        }
                    })
                });

                if (!response.ok) {
                    const error = await response.json().catch(() => ({}));
                    const errorMessage = error.error?.message || error.message || `Error ${response.status}: ${response.statusText}`;
                    lastError = errorMessage;
                    
                    // Si es error 429 (quota exceeded), saltar a modelos gratuitos directamente
                    if (response.status === 429) {
                        console.warn(`[Flor AI] ⚠️ Cuota excedida con ${cleanModel} (plan gratuito limitado). Saltando a modelos gratuitos...`);
                        // Filtrar modelos que probablemente requieren facturación
                        const freeModels = modelsToTry.filter(m => 
                            m.includes('flash') && !m.includes('pro') && !m.includes('preview') && !m.includes('exp') ||
                            m.includes('flash-lite') || 
                            m === 'gemini-flash-latest'
                        );
                        if (freeModels.length > 0) {
                            // Actualizar lista de modelos a probar con solo los gratuitos
                            modelsToTry.splice(0, modelsToTry.length, ...freeModels);
                            continue;
                        }
                    }
                    
                    console.warn(`[Flor AI] ⚠️ Error con ${apiVersion}/${cleanModel}: ${errorMessage}`);
                    continue; // Intentar con el siguiente modelo
                }

                const data = await response.json();
                
                // Verificar si hay contenido en la respuesta
                if (!data.candidates || data.candidates.length === 0) {
                    lastError = 'No se recibió respuesta de Gemini';
                    continue;
                }
                
                const text = data.candidates[0]?.content?.parts?.[0]?.text?.trim();
                if (!text) {
                    lastError = 'La respuesta de Gemini está vacía';
                    continue;
                }
                
                console.log(`[Flor AI] ✅ Respuesta exitosa con ${apiVersion} y modelo ${cleanModel}`);
                
                // Guardar el modelo que funcionó para próximas llamadas
                if (cleanModel !== this.config.model) {
                    this.config.model = cleanModel;
                    this.saveConfig();
                    console.log(`[Flor AI] 💾 Modelo guardado: ${cleanModel}`);
                }
                
                return text;
                
            } catch (error) {
                lastError = error.message;
                console.warn(`[Flor AI] ⚠️ Excepción con ${modelToTry}: ${error.message}`);
                continue;
            }
        }
        
        // Si llegamos aquí, todos los intentos fallaron
        throw new Error(`No se pudo conectar con Gemini. Último error: ${lastError}. Verifica tu API key o la disponibilidad de los modelos.`);
    }

    // Llamar a Claude API (Anthropic)
    async callClaude(systemPrompt, userPrompt) {
        const url = this.config.apiUrl || 'https://api.anthropic.com/v1/messages';
        
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': this.config.apiKey,
                'anthropic-version': '2023-06-01'
            },
            body: JSON.stringify({
                model: this.config.model || 'claude-3-haiku-20240307',
                max_tokens: Math.min(this.config.maxTokens, 200), // Limitar a 200 tokens para respuestas muy concisas
                system: systemPrompt,
                messages: [
                    { role: 'user', content: userPrompt }
                ]
            })
        });

        if (!response.ok) {
            const error = await response.json().catch(() => ({}));
            throw new Error(error.error?.message || `Error ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        return data.content[0]?.text?.trim() || null;
    }

    // Llamar a API personalizada
    async callCustomAPI(systemPrompt, userPrompt) {
        if (!this.config.apiUrl) {
            throw new Error('API URL no configurada');
        }

        const response = await fetch(this.config.apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(this.config.apiKey && { 'Authorization': `Bearer ${this.config.apiKey}` })
            },
            body: JSON.stringify({
                system: systemPrompt,
                user: userPrompt,
                model: this.config.model,
                temperature: this.config.temperature,
                max_tokens: Math.min(this.config.maxTokens, 200) // Limitar a 200 tokens para respuestas muy concisas
            })
        });

        if (!response.ok) {
            throw new Error(`Error ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        // Ajustar según el formato de respuesta de tu API
        return data.response || data.message || data.text || null;
    }

    // Procesar comandos especiales en las respuestas de IA
    processSpecialCommands(responseText, context) {
        // Detectar comando [SEND_IMAGE:hotelId:imageType] o [SEND_IMAGE:nombre_hotel]
        const imageCommandRegex = /\[SEND_IMAGE:([^\]]+)\]/gi;
        const matches = [...responseText.matchAll(imageCommandRegex)];
        
        if (matches.length > 0) {
            // Remover el comando del texto y preparar información para envío de imagen
            matches.forEach(match => {
                const params = match[1].trim();
                responseText = responseText.replace(match[0], '');
                
                // Parsear parámetros: puede ser "hotelId:imageType" o solo "nombre_hotel"
                const parts = params.split(':');
                let hotelId = null;
                let imageType = 'main';
                let hotelName = null;
                
                if (parts.length === 2) {
                    // Formato: hotelId:imageType
                    hotelId = parts[0].trim();
                    imageType = parts[1].trim();
                } else if (parts.length === 1) {
                    // Formato: nombre_hotel o hotelId
                    const value = parts[0].trim();
                    if (!isNaN(value)) {
                        hotelId = value;
                    } else {
                        hotelName = value;
                    }
                }
                
                // Agregar información al contexto para que el agente sepa que debe enviar imagen
                if (!context.sendImages) {
                    context.sendImages = [];
                }
                context.sendImages.push({
                    hotelId: hotelId,
                    hotelName: hotelName,
                    type: imageType
                });
            });
        }
        
        return responseText.trim();
    }

    // Verificar si el servicio está disponible
    isAvailable() {
        return this.config.enabled && this.config.apiKey && this.config.apiKey.trim() !== '';
    }
}

// Crear instancia global
const florAIService = new FlorAIService();

// Exportar para uso en otros archivos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FlorAIService;
}

