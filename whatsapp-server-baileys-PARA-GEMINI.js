/**
 * =============================================================================
 * COPIA PARA GEMINI - Análisis y configuración
 * =============================================================================
 *
 * Este archivo es una copia de whatsapp-server/whatsapp-server-baileys.js:
 * servidor de WhatsApp (Baileys) + Flor IA (Gemini) para Checkin24hs.
 *
 * Por favor:
 * 1. Explicame QUÉ ES este código: qué hace, arquitectura, flujo principal.
 * 2. Decime CÓMO CONFIGURARLO paso a paso:
 *    - Variables de entorno (GEMINI_API_KEY, SUPABASE, PORT, etc.)
 *    - Supabase (tablas, system_config: flor_general_config, flor_ai_config, flor_responses)
 *    - Despliegue (Docker, EasyPanel, VPS)
 *    - Conexión WhatsApp (QR, auth).
 *
 * =============================================================================
 */

/**
 * 🌸 Servidor de WhatsApp usando Baileys para Flor - Checkin24hs
 * 
 * VERSIÓN 3.0 - Usando Baileys (sin Chrome/Puppeteer)
 * - Más ligero y rápido
 * - No requiere Chrome
 * - Funciona en cualquier servidor
 * - Soporte para 4 instancias WhatsApp
 */

// Asegurar que crypto esté disponible globalmente para Baileys
const crypto = require('crypto');
if (typeof globalThis.crypto === 'undefined') {
    globalThis.crypto = crypto;
}
if (typeof global.crypto === 'undefined') {
    global.crypto = crypto;
}

const { default: makeWASocket, DisconnectReason, useMultiFileAuthState, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const path = require('path');
const qrcode = require('qrcode');
const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');

console.log('🚀 Iniciando servidor WhatsApp con Baileys...');

// ===== CONFIGURACIÓN =====
const CONFIG = {
    PORT: process.env.PORT || 3001,
    INSTANCE_NUMBER: parseInt(process.env.INSTANCE_NUMBER) || 1,
    // URL base del servidor (para logging y referencias)
    // Si no se especifica, se construye automáticamente
    BASE_URL: process.env.BASE_URL || process.env.SERVER_URL || null,
    AUTO_REPLY: true,
    FLOR_ENABLED: true,
    SAVE_MESSAGES: true,
    SAVE_TO_SUPABASE: true,
    USE_GEMINI_AI: true,
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
    GEMINI_MODEL: process.env.GEMINI_MODEL || 'gemini-2.5-flash', // Usar el mismo modelo que el dashboard
    SUPABASE: {
        url: process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        anonKey: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4'
    }
};

// Construir URL base si no está configurada
if (!CONFIG.BASE_URL) {
    // Intentar detectar desde variables de entorno comunes
    const host = process.env.HOST || process.env.SERVER_HOST || '0.0.0.0';
    const protocol = process.env.PROTOCOL || 'http';
    CONFIG.BASE_URL = `${protocol}://${host}:${CONFIG.PORT}`;
}

// ===== INICIALIZAR EXPRESS =====
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Configurar CORS explícitamente
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: true
}));

// Manejar preflight requests
app.options('*', cors());

app.use(express.json());

// ===== CLIENTE DE SUPABASE =====
let supabase = null;
try {
    supabase = createClient(CONFIG.SUPABASE.url, CONFIG.SUPABASE.anonKey);
    console.log('✅ Cliente de Supabase inicializado');
} catch (e) {
    console.error('❌ Error inicializando Supabase:', e.message);
}

// ===== VARIABLES GLOBALES =====
let sock = null;
let qrCodeData = null;
let connectionStatus = 'close'; // 'close', 'connecting', 'open'
let phoneNumber = null;
let connectionTimestamp = null; // Timestamp de cuando se conectó exitosamente
let phoneName = null;
let qrExpirationTimer = null; // Timer para detectar QR expirado

// Delay antes de que Flor responda (ms). El usuario puede hacer todas las consultas que quiera en la misma conversación.
// Si en esos 5s llega 1 solo mensaje → Flor responde esa consulta y queda atenta a la siguiente.
// Si llegan varios en ese lapso → se acumulan y Flor responde a todos juntos. Sin límite de consultas por usuario.
const FLOR_DELAY_MS = Math.max(0, parseInt(process.env.FLOR_DELAY_MS, 10) || 5000);
const florPendingByUser = new Map(); // key: remoteJid -> { timeoutId, messages: [{texto, ts}], nombre, numero }
if (FLOR_DELAY_MS > 0) {
    console.log(`⏱️ Flor: delay ${FLOR_DELAY_MS}ms para agrupar mensajes. Usuario puede consultar las veces que quiera; 1 mensaje → 1 respuesta, varios en ${FLOR_DELAY_MS}ms → respuesta a todos.`);
}

// Prompt por defecto (mismo que Dashboard Flor IA → General). Usado si no hay flor_general_config en Supabase.
const FLOR_PROMPT_DEFAULT = `Eres Flor IA 🌸, asistente virtual de Checkin24hs. Operás con inmediatez y eficiencia para atender a clientes de alto poder adquisitivo en una agencia de hoteles de lujo.

**Propósito:** Sos el primer punto de contacto. Gestionás y respondés de forma inmediata y precisa consultas sobre hoteles, servicios y promociones (WhatsApp y redes).

**Público:** Clientes viajeros, aventureros y empresarios con alto poder adquisitivo. Esperan servicio premium y suelen ser impacientes; priorizá velocidad y claridad.

**Tono:** Amable y amigable, profesional y eficiente. Cálida y servicial, nunca lenta.

**Bienvenida:** "¡Mi nombre es Flor IA 🌸, soy tu asistente virtual y estoy aquí para ayudarte! ¿Me podrías decir brevemente sobre qué hotel o servicio tenés una consulta?"

**Reglas importantes:**
- No enviés nunca el carácter '#' al cliente.
- No des precios por noche como información para cotizar; esa información es interna.
- No realices cotizaciones vos misma.

**Cotización:** Si el cliente pide cotizar, tarifa o reservar: no des precios. Enviále este enlace y explicá que complete los datos para que le pasemos la cotización: https://cotizar.checkin24hs.com/

**Manejo de errores:** Si la consulta no es clara, disculpate de forma concisa y ofrecé pasar a un agente humano.

**Escalación a humano (transferir de inmediato):**
1. El cliente pide "hablar con un humano", "agente" o "asesor".
2. El cliente quiere reservar (ej. "Quiero reservar", "Hacer una reserva para [fecha]").
3. No entendés la consulta o no tenés la información para responder bien.

**Límites:** Respuestas directas, concisas y orientadas a la acción. Máximo 3 oraciones, salvo que pidan una lista de servicios.

**Base de conocimiento:** Usá solo datos verificados sobre hoteles, direcciones, servicios, tarifas y políticas. No compartas datos personales de otros clientes ni información financiera interna.`;

// Reglas de prioridad que SIEMPRE se inyectan (evitan que Flor redirija a la web para info de hotel).
const FLOR_REGLAS_PRIORIDAD = `
**PRIORIDAD - OBLIGATORIO:**
- Cuando pregunten por información de un hotel o destino (ej. "info de Puyehue", "qué me cuentas de X", "hotel Y"): usá SIEMPRE la base de hoteles proporcionada. NUNCA redirijas a la web solo para dar información general.
- Solo enviá el link https://cotizar.checkin24hs.com/ cuando pidan explícitamente cotizar, tarifa, precio o reservar. Para consultas de información (descripción, servicios, ubicación, etc.) respondé con los datos de la base de hoteles.

**NO REPETIR PRESENTACIÓN:**
- La frase "¡Mi nombre es Flor IA 🌸, soy tu asistente virtual y estoy aquí para ayudarte!" es SOLO para el primer saludo. NUNCA la repitas en respuestas sobre hoteles, cotización o consultas concretas.
- En consultas de hotel, confirmaciones ("sí", "ok") o pedidos de información: respondé directo al tema, sin volver a presentarte.`;

// Cache de prompt General (Supabase). TTL 5 min.
const FLOR_PROMPT_CACHE = { prompt: null, ts: 0 };
const FLOR_PROMPT_CACHE_TTL_MS = 5 * 60 * 1000;

// Cache de base de hoteles para Flor. TTL 5 min.
const FLOR_HOTELS_CACHE = { block: null, ts: 0 };
const FLOR_HOTELS_CACHE_TTL_MS = 5 * 60 * 1000;

// Cache de respuestas predefinidas de Flor (Supabase). TTL 5 min.
const FLOR_RESPONSES_CACHE = { responses: null, ts: 0 };
const FLOR_RESPONSES_CACHE_TTL_MS = 5 * 60 * 1000;

// Cache de configuración de IA de Flor (Supabase). TTL 5 min.
const FLOR_AI_CONFIG_CACHE = { config: null, ts: 0 };
const FLOR_AI_CONFIG_CACHE_TTL_MS = 5 * 60 * 1000;

// Respuestas por defecto (usadas si no hay en Supabase)
const FLOR_RESPONSES_DEFAULTS = {
    noEntendido: 'Lo siento, no he podido entender tu consulta. ¿Podrías reformularla o prefieres que te conecte con un agente humano?',
    rateLimitExceeded: 'Estoy recibiendo muchas consultas ahora. Por favor intentá de nuevo en un minuto, o si preferís te conecto con un agente humano.',
    saludo: '¡Hola! Soy Flor IA 🌸, tu asistente de Checkin24hs. ¿En qué puedo ayudarte hoy? ¿Algún hotel, cotización o consulta?',
    transferir: 'Entendido, voy a transferirte con uno de nuestros agentes. Por favor espera un momento.',
    despedida: '¡Gracias por contactarnos! Si tienes más preguntas, estaré aquí para ayudarte. ¡Hasta pronto!',
    audioFallback: 'Disculpa, el audio no fue del todo claro. Para atenderte con la rapidez que mereces, ¿podrías enviarme tu consulta por escrito, o prefieres que te conecte con un agente ahora mismo?',
    audioProcessing: 'Un momento, estoy escuchando tu mensaje de voz... 🎧',
    imageFallback: 'No pude identificar claramente la imagen. ¿Podrías describirme qué estás buscando o enviar otra foto con mejor iluminación?',
    imageProcessing: 'Un momento, estoy analizando la imagen... 🔍',
    imageHotelFound: '¡Reconozco esa imagen! Se trata de {nombre_hotel}. Te cuento más sobre este hotel:',
    imageSending: 'Aquí te muestro una foto de {nombre_hotel}:',
    imageNotAvailable: 'Lo siento, no tengo imágenes disponibles de este hotel en este momento. ¿Te gustaría que te conecte con un agente que pueda mostrarte fotos?'
};

// Configuración de IA por defecto (usada si no hay en Supabase)
const FLOR_AI_CONFIG_DEFAULT = {
    enabled: true,
    provider: 'gemini',
    model: 'gemini-2.5-flash',
    temperature: 0.7,
    maxTokens: 500
};

/**
 * Obtener prompt de Flor para Gemini. Origen: Supabase (flor_general_config) > FLOR_PROMPT_DEFAULT.
 */
async function getFlorPromptForGemini() {
    const now = Date.now();
    if (FLOR_PROMPT_CACHE.prompt && (now - FLOR_PROMPT_CACHE.ts) < FLOR_PROMPT_CACHE_TTL_MS) {
        return FLOR_PROMPT_CACHE.prompt;
    }
    if (supabase) {
        try {
            const { data, error } = await supabase
                .from('system_config')
                .select('value')
                .eq('key', 'flor_general_config')
                .single();
            if (!error && data && data.value) {
                const config = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
                const p = (config.promptGeneral && String(config.promptGeneral).trim()) ? config.promptGeneral : null;
                if (p) {
                    FLOR_PROMPT_CACHE.prompt = p;
                    FLOR_PROMPT_CACHE.ts = now;
                    console.log('🌸 Flor: usando Prompt General desde Supabase (flor_general_config)');
                    return p;
                }
            }
        } catch (e) {
            console.warn('⚠️ No se pudo cargar flor_general_config desde Supabase:', e?.message || e);
        }
    }
    FLOR_PROMPT_CACHE.prompt = FLOR_PROMPT_DEFAULT;
    FLOR_PROMPT_CACHE.ts = now;
    console.log('🌸 Flor: usando Prompt General por defecto (sin flor_general_config en Supabase)');
    return FLOR_PROMPT_DEFAULT;
}

/**
 * Buscar hoteles por nombre parcial (ej: "Puyehue" → "Termas de Puyehue")
 * Retorna array de hoteles que coinciden con el término de búsqueda
 */
async function buscarHotelesPorNombreParcial(termino) {
    if (!supabase || !termino || termino.trim().length < 3) return [];
    
    try {
        const { data: hotels, error } = await supabase
            .from('hotels')
            .select('id, name, location, flor_info, status')
            .order('name');
        
        if (error) throw error;
        
        const list = Array.isArray(hotels) ? hotels : [];
        const active = list.filter(h => {
            const s = (h.status || '').toLowerCase();
            return s !== 'inactivo' && s !== 'inactive';
        });
        
        const terminoLower = termino.toLowerCase().trim();
        const coincidencias = active.filter(h => {
            const hotelName = (h.name || '').toLowerCase();
            const location = (h.location || '').toLowerCase();
            
            // Búsqueda exacta en nombre
            if (hotelName.includes(terminoLower)) return true;
            
            // Búsqueda en ubicación
            if (location.includes(terminoLower)) return true;
            
            // Búsqueda parcial: palabras del término en el nombre
            const terminoWords = terminoLower.split(/\s+/).filter(w => w.length >= 3);
            const hotelNameWords = hotelName.split(/\s+/);
            
            // Si alguna palabra del término está en el nombre del hotel
            if (terminoWords.some(tw => hotelNameWords.some(hw => hw.includes(tw) || tw.includes(hw)))) {
                return true;
            }
            
            // Búsqueda inversa: palabras del nombre del hotel en el término
            const palabrasSignificativas = hotelNameWords.filter(w => w.length >= 4 && !['de', 'la', 'el', 'y', 'en', 'a', 'del', 'las', 'los', 'hotel', 'terma', 'termas'].includes(w));
            if (palabrasSignificativas.some(p => terminoLower.includes(p))) {
                return true;
            }
            
            return false;
        });
        
        return coincidencias;
    } catch (e) {
        console.warn('⚠️ Error buscando hoteles por nombre parcial:', e?.message || e);
        return [];
    }
}

/**
 * Obtener bloque de texto con hoteles para el prompt de Flor (Supabase `hotels`).
 * Solo hoteles activos; incluye nombre, ubicación y flor_info (descripción, servicios, etc.).
 */
async function getHotelsBlockForFlor() {
    const now = Date.now();
    if (FLOR_HOTELS_CACHE.block !== null && (now - FLOR_HOTELS_CACHE.ts) < FLOR_HOTELS_CACHE_TTL_MS) {
        return FLOR_HOTELS_CACHE.block;
    }
    let block = '';
    if (supabase) {
        try {
            const { data: hotels, error } = await supabase
                .from('hotels')
                .select('id, name, location, flor_info, status')
                .order('name');
            if (error) throw error;
            const list = Array.isArray(hotels) ? hotels : [];
            const active = list.filter(h => {
                const s = (h.status || '').toLowerCase();
                return s !== 'inactivo' && s !== 'inactive';
            });
            if (active.length === 0) {
                block = 'No hay hoteles activos cargados en la base. Indicá que consultes con el equipo.';
            } else {
                const parts = active.map(h => {
                    const fi = h.flor_info || {};
                    const hotelName = h.name || 'Sin nombre';
                    // Crear lista de nombres alternativos para búsqueda (ej: "Puyehue" → "Termas de Puyehue", "futangue" → "Parque Futangue")
                    let nameVariants = [
                        hotelName,
                        hotelName.toLowerCase(),
                        hotelName.replace(/hotel\s+/i, '').replace(/terma[s]?\s+de\s+/i, '').trim(),
                        hotelName.replace(/terma[s]?\s+de\s+/i, '').trim(),
                        hotelName.replace(/hotel\s+/i, '').trim(),
                        hotelName.replace(/^parque\s+/i, '').trim(),
                        hotelName.replace(/^parque\s+/i, '').toLowerCase().trim()
                    ];
                    if (hotelName.toLowerCase().includes('futangue')) {
                        nameVariants.push('futanque', 'Futanque');
                    }
                    nameVariants = nameVariants.filter((v, i, arr) => v && arr.indexOf(v) === i);
                    
                    const lines = [
                        `### ${hotelName}`,
                        `Nombres alternativos: ${nameVariants.join(', ')}`,
                        `Ubicación: ${h.location || '-'}`,
                        fi.description ? `Descripción: ${String(fi.description).slice(0, 400)}` : '',
                        fi.services ? `Servicios: ${String(fi.services).slice(0, 300)}` : '',
                        fi.excursions ? `Excursiones/actividades: ${String(fi.excursions).slice(0, 250)}` : '',
                        fi.prices ? `Precios (resumen): ${String(fi.prices).slice(0, 200)}` : '',
                        fi.policies ? `Políticas: ${String(fi.policies).slice(0, 200)}` : '',
                        fi.transport ? `Cómo llegar: ${String(fi.transport).slice(0, 150)}` : '',
                        fi.contact ? `Contacto: ${String(fi.contact).slice(0, 120)}` : ''
                    ].filter(Boolean);
                    return lines.join('\n');
                });
                block = `## Hoteles Checkin24hs\n\nIMPORTANTE: Si el cliente menciona un nombre parcial de hotel (ej: "Puyehue"), busca en los "Nombres alternativos" de cada hotel. Responde con la información completa del hotel que coincida.\n\n${parts.join('\n\n')}`;
            }
            FLOR_HOTELS_CACHE.block = block;
            FLOR_HOTELS_CACHE.ts = now;
        } catch (e) {
            console.warn('⚠️ Error cargando hoteles para Flor:', e?.message || e);
            block = 'No se pudo cargar la base de hoteles. Pedí al cliente que consulte con el equipo.';
        }
    } else {
        block = 'Base de hoteles no disponible. Indicá consultar con el equipo.';
    }
    return block;
}

/**
 * Obtener respuestas predefinidas de Flor desde Supabase (flor_responses).
 * Origen: Supabase > FLOR_RESPONSES_DEFAULTS.
 */
async function getFlorResponses() {
    const now = Date.now();
    if (FLOR_RESPONSES_CACHE.responses && (now - FLOR_RESPONSES_CACHE.ts) < FLOR_RESPONSES_CACHE_TTL_MS) {
        return FLOR_RESPONSES_CACHE.responses;
    }
    if (supabase) {
        try {
            const { data, error } = await supabase
                .from('system_config')
                .select('value')
                .eq('key', 'flor_responses')
                .single();
            if (!error && data && data.value) {
                const responses = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
                if (responses && typeof responses === 'object') {
                    // Mergear con defaults para asegurar que todas las claves existan
                    const merged = { ...FLOR_RESPONSES_DEFAULTS, ...responses };
                    FLOR_RESPONSES_CACHE.responses = merged;
                    FLOR_RESPONSES_CACHE.ts = now;
                    return merged;
                }
            }
        } catch (e) {
            console.warn('⚠️ No se pudo cargar flor_responses desde Supabase:', e?.message || e);
        }
    }
    FLOR_RESPONSES_CACHE.responses = FLOR_RESPONSES_DEFAULTS;
    FLOR_RESPONSES_CACHE.ts = now;
    return FLOR_RESPONSES_DEFAULTS;
}

/**
 * Obtener configuración de IA de Flor desde Supabase (flor_ai_config).
 * Origen: Supabase > FLOR_AI_CONFIG_DEFAULT > CONFIG (env vars).
 */
async function getFlorAIConfig() {
    const now = Date.now();
    if (FLOR_AI_CONFIG_CACHE.config && (now - FLOR_AI_CONFIG_CACHE.ts) < FLOR_AI_CONFIG_CACHE_TTL_MS) {
        return FLOR_AI_CONFIG_CACHE.config;
    }
    let config = { ...FLOR_AI_CONFIG_DEFAULT };
    if (supabase) {
        try {
            const { data, error } = await supabase
                .from('system_config')
                .select('value')
                .eq('key', 'flor_ai_config')
                .single();
            if (!error && data && data.value) {
                const cloudConfig = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
                if (cloudConfig && typeof cloudConfig === 'object') {
                    // Mergear con defaults
                    config = { ...FLOR_AI_CONFIG_DEFAULT, ...cloudConfig };
                }
            }
        } catch (e) {
            console.warn('⚠️ No se pudo cargar flor_ai_config desde Supabase:', e?.message || e);
        }
    }
    // Si la configuración de Supabase tiene enabled: false, respetarlo
    if (config.enabled === false) {
        FLOR_AI_CONFIG_CACHE.config = config;
        FLOR_AI_CONFIG_CACHE.ts = now;
        return config;
    }
    // Usar modelo de CONFIG (env) si está disponible, pero respetar temperature y maxTokens de Supabase
    if (CONFIG.GEMINI_MODEL) {
        config.model = CONFIG.GEMINI_MODEL;
    }
    FLOR_AI_CONFIG_CACHE.config = config;
    FLOR_AI_CONFIG_CACHE.ts = now;
    return config;
}

// ===== FUNCIONES DE FLOR IA =====

/**
 * Procesar mensaje con Flor IA usando Gemini.
 * Usa el Prompt General de Flor IA → General (Supabase flor_general_config) o FLOR_PROMPT_DEFAULT.
 * Usa flor_ai_config desde Supabase para model, temperature, maxTokens.
 * Usa flor_responses desde Supabase para respuestas predefinidas cuando sea apropiado.
 */
async function procesarConFlor(mensaje, contexto = {}) {
    if (!CONFIG.FLOR_ENABLED) {
        return null;
    }
    
    if (!CONFIG.GEMINI_API_KEY || CONFIG.GEMINI_API_KEY.trim() === '') {
        console.warn('⚠️ GEMINI_API_KEY no configurada. Flor IA no funcionará. Configura la variable en EasyPanel.');
        return null;
    }

    // Obtener configuración de IA desde Supabase
    const aiConfig = await getFlorAIConfig();
    if (aiConfig.enabled === false) {
        console.log('ℹ️ Flor IA deshabilitada en configuración (flor_ai_config.enabled = false)');
        return null;
    }

    // Obtener respuestas predefinidas (por si necesitamos usarlas)
    const responses = await getFlorResponses();

    // Detectar si el mensaje requiere una respuesta predefinida
    const mensajeLower = (mensaje || '').toLowerCase().trim();
    
    // Detectar solicitud de transferencia a humano
    const transferKeywords = ['hablar con humano', 'hablar con agente', 'hablar con asesor', 'transferir', 'agente humano', 'asesor humano', 'quiero hablar con alguien'];
    if (transferKeywords.some(kw => mensajeLower.includes(kw))) {
        console.log('🔄 Usando respuesta predefinida: transferir');
        return responses.transferir;
    }

    // Detectar despedida
    const despedidaKeywords = ['gracias', 'chau', 'adiós', 'hasta luego', 'nos vemos', 'bye', 'hasta pronto'];
    if (despedidaKeywords.some(kw => mensajeLower.includes(kw)) && mensajeLower.length < 30) {
        console.log('👋 Usando respuesta predefinida: despedida');
        return responses.despedida;
    }

    // Detectar saludo simple (hola, buen día, etc.): responder con bienvenida SIN llamar a Gemini
    const saludoKeywords = ['hola', 'buen día', 'buenos días', 'buenas', 'hi', 'hey', 'qué tal', 'buenas tardes', 'buenas noches'];
    const esSoloSaludo = mensajeLower.length <= 25 && saludoKeywords.some(kw => mensajeLower.includes(kw));
    if (esSoloSaludo) {
        const saludo = (responses.saludo && responses.saludo.trim()) ? responses.saludo.trim() : FLOR_RESPONSES_DEFAULTS.saludo;
        console.log('👋 Usando respuesta predefinida: saludo');
        return saludo;
    }

    // Detectar si el mensaje menciona un nombre parcial de hotel
    const mensajeWords = mensajeLower.split(/\s+/).filter(w => w.length >= 3);
    let hotelesCoincidentes = [];
    let nombreHotelDetectado = null;
    
    // Buscar hoteles mencionados en el mensaje
    for (const word of mensajeWords) {
        const coincidencias = await buscarHotelesPorNombreParcial(word);
        if (coincidencias.length > 0) {
            hotelesCoincidentes = coincidencias;
            nombreHotelDetectado = word;
            break; // Usar la primera coincidencia encontrada
        }
    }
    
    // Si no se encontró con palabras individuales, intentar con el mensaje completo
    if (hotelesCoincidentes.length === 0 && mensajeLower.length >= 3) {
        hotelesCoincidentes = await buscarHotelesPorNombreParcial(mensajeLower);
        if (hotelesCoincidentes.length > 0) {
            nombreHotelDetectado = mensajeLower;
        }
    }
    
    // Obtener prompt y hoteles
    const [systemPrompt, hotelsBlock] = await Promise.all([getFlorPromptForGemini(), getHotelsBlockForFlor()]);
    
    // Construir prompt con lógica de confirmación si hay hoteles coincidentes
    let instruccionesEspeciales = '';
    if (hotelesCoincidentes.length > 0) {
        if (hotelesCoincidentes.length === 1) {
            // Un solo hotel encontrado: preguntar por confirmación
            const hotel = hotelesCoincidentes[0];
            instruccionesEspeciales = `\n\n⚠️ IMPORTANTE - DETECCIÓN DE HOTEL:\nEl cliente mencionó "${nombreHotelDetectado}" que podría referirse al hotel "${hotel.name}".\n\nINSTRUCCIONES ESPECIALES:\n1. NO des la información completa del hotel todavía.\n2. Pregúntale al cliente: "¿Te refieres a ${hotel.name}?" o "¿Querés información sobre ${hotel.name}?"\n3. Espera a que el cliente confirme con "sí", "ok", "correcto", "👍", "✅" o cualquier afirmación.\n4. SOLO después de la confirmación, proporciona toda la información del hotel.\n5. Si el cliente dice "no" o niega, pregunta qué hotel específicamente busca.\n\nSi el cliente ya confirmó en mensajes anteriores o está respondiendo a tu pregunta de confirmación con una afirmación, entonces SÍ proporciona toda la información del hotel.`;
        } else {
            // Múltiples hoteles encontrados: listar opciones
            const nombresHoteles = hotelesCoincidentes.map(h => h.name).join(', ');
            instruccionesEspeciales = `\n\n⚠️ IMPORTANTE - MÚLTIPLES HOTELES DETECTADOS:\nEl cliente mencionó "${nombreHotelDetectado}" que podría referirse a varios hoteles: ${nombresHoteles}.\n\nINSTRUCCIONES ESPECIALES:\n1. NO des información de ningún hotel todavía.\n2. Lista las opciones: "Encontré varios hoteles que podrían coincidir: [lista]. ¿Cuál te interesa?"\n3. Espera a que el cliente elija uno específico.\n4. SOLO después de que el cliente confirme un hotel específico, proporciona toda la información de ese hotel.\n\nSi el cliente ya eligió un hotel en mensajes anteriores, entonces SÍ proporciona toda la información del hotel elegido.`;
        }
    }
    
    // Detectar si el mensaje es una confirmación (respuesta a pregunta previa)
    const confirmaciones = ['sí', 'si', 'yes', 'ok', 'okay', 'correcto', 'exacto', 'ese', 'ese mismo', 'ese es', '👍', '✅', 'perfecto', 'dale', 'va', 'claro'];
    const esConfirmacion = confirmaciones.some(conf => mensajeLower.includes(conf)) && mensajeLower.length < 50;
    
    if (esConfirmacion && hotelesCoincidentes.length > 0) {
        // El usuario está confirmando, dar información completa
        instruccionesEspeciales = `\n\n✅ CONFIRMACIÓN DETECTADA:\nEl cliente está confirmando que se refiere a "${hotelesCoincidentes[0].name}".\n\nINSTRUCCIONES:\nProporciona TODA la información disponible del hotel: descripción, servicios, ubicación, excursiones, políticas, cómo llegar, contacto, etc. Sé completo y útil.`;
    }
    
    let multiConsultasNote = '';
    if (contexto.multiConsultas && Array.isArray(contexto.consultas) && contexto.consultas.length > 1) {
        multiConsultasNote = `\n\n⚠️ MÚLTIPLES CONSULTAS: El cliente envió ${contexto.consultas.length} mensajes seguidos. Responde a TODAS las consultas en un solo mensaje, de forma ordenada y clara (por ejemplo numerando o separando por temas).`;
    }

    // System instruction: prompt + hoteles + reglas prioridad (Gemini las trata como instrucciones fijas).
    const systemPart = `${systemPrompt}

${hotelsBlock}
${FLOR_REGLAS_PRIORIDAD}`;

    // Contenido usuario: instrucciones dinámicas + mensaje + contexto.
    const userPart = `${instruccionesEspeciales}
${multiConsultasNote}

---

Mensaje del cliente: ${mensaje}

Contexto: ${JSON.stringify(contexto)}

Responde de manera breve y útil usando la base de hoteles cuando aplique.${esConfirmacion ? ' El cliente está confirmando, así que proporciona información completa.' : ''}`;

    // Usar modelo, temperature y maxTokens de flor_ai_config
    const model = aiConfig.model || CONFIG.GEMINI_MODEL || 'gemini-2.5-flash';
    const temperature = aiConfig.temperature !== undefined ? aiConfig.temperature : 0.7;
    const maxTokens = aiConfig.maxTokens !== undefined ? aiConfig.maxTokens : 500;

    const startTime = Date.now();
    try {
        const requestBody = {
            systemInstruction: { parts: [{ text: systemPart }] },
            contents: [{ parts: [{ text: userPart }] }],
            generationConfig: {
                temperature: temperature,
                maxOutputTokens: maxTokens
            }
        };

        // Intentar con retry para rate limit 429 (4 intentos: 2s, 4s, 8s de espera entre llamadas).
        let response = null;
        let lastError = null;
        const maxRetries = 4;
        for (let attempt = 0; attempt < maxRetries; attempt++) {
            try {
                response = await axios.post(
                    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${CONFIG.GEMINI_API_KEY}`,
                    requestBody,
                    {
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        timeout: 30000 // 30 segundos de timeout
                    }
                );
                break; // Éxito, salir del loop
            } catch (retryError) {
                lastError = retryError;
                if (retryError.response?.status === 429 && attempt < maxRetries - 1) {
                    const waitMs = Math.min(2000 * Math.pow(2, attempt), 12000);
                    console.warn(`⚠️ Rate limit 429 en Gemini (intento ${attempt + 1}/${maxRetries}). Esperando ${waitMs}ms...`);
                    await new Promise(resolve => setTimeout(resolve, waitMs));
                    continue;
                }
                throw retryError; // Re-lanzar si no es 429 o es el último intento
            }
        }

        if (response.data?.candidates?.[0]?.content?.parts?.[0]?.text) {
            const responseTime = Date.now() - startTime;
            const respuesta = response.data.candidates[0].content.parts[0].text;
            console.log(`✅ Flor respondió usando modelo ${model} (${responseTime}ms)`);
            return respuesta;
        }
    } catch (error) {
        const responseTime = Date.now() - startTime;
        if (error.response?.status === 429) {
            console.error(`❌ Error 429: Rate limit de Gemini excedido. Demasiadas requests.`);
            const msg = (responses.rateLimitExceeded && responses.rateLimitExceeded.trim()) ? responses.rateLimitExceeded.trim() : FLOR_RESPONSES_DEFAULTS.rateLimitExceeded;
            console.log('🔄 Usando respuesta predefinida: rateLimitExceeded (429). El usuario puede volver a consultar cuando quiera.');
            return { text: msg, intent: 'rate_limit_429' };
        }
        if (error.response?.status === 404) {
            console.error(`❌ Error 404: Modelo ${model} no encontrado. Intentando con modelo alternativo...`);
            try {
                const altModel = 'gemini-2.0-flash';
                const altResponse = await axios.post(
                    `https://generativelanguage.googleapis.com/v1beta/models/${altModel}:generateContent?key=${CONFIG.GEMINI_API_KEY}`,
                    {
                        systemInstruction: { parts: [{ text: systemPart }] },
                        contents: [{ parts: [{ text: userPart }] }],
                        generationConfig: {
                            temperature: temperature,
                            maxOutputTokens: maxTokens
                        }
                    },
                    {
                        headers: { 'Content-Type': 'application/json' },
                        timeout: 30000
                    }
                );
                if (altResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text) {
                    console.log(`✅ Respuesta de Gemini obtenida con modelo alternativo (${altModel}, ${Date.now() - startTime}ms)`);
                    return altResponse.data.candidates[0].content.parts[0].text;
                }
            } catch (retryError) {
                console.error('❌ Error con modelo alternativo. Verifica GEMINI_API_KEY en EasyPanel.');
                if (retryError.response?.status === 400) {
                    console.error('   💡 La API key puede estar mal formateada o ser inválida.');
                } else if (retryError.response?.status === 403) {
                    console.error('   💡 La API key puede no tener permisos o la cuota estar excedida.');
                }
            }
        } else if (error.response?.status === 400) {
            console.error('❌ Error 400: API key de Gemini inválida o formato incorrecto. Verifica GEMINI_API_KEY en EasyPanel.');
        } else if (error.response?.status === 403) {
            console.error('❌ Error 403: API key de Gemini sin permisos o cuota excedida. Verifica GEMINI_API_KEY en EasyPanel.');
        } else if (error.code === 'ECONNABORTED') {
            console.error('❌ Error: Timeout al procesar con Flor (30 segundos).');
        } else {
            console.error('❌ Error procesando con Flor:', error.message || error.response?.data || error);
        }
        
        // Si falla la IA, usar respuesta predefinida "no entendido"
        console.log('🔄 Usando respuesta predefinida: noEntendido (fallback por error de IA)');
        return responses.noEntendido;
    }

    // Si no hay respuesta, usar "no entendido"
    console.log('🔄 Usando respuesta predefinida: noEntendido (sin respuesta de IA)');
    return responses.noEntendido;
}

/**
 * Guardar interacción de Flor en flor_interactions (Supabase).
 * Lo usa el Dashboard en Interacciones → Historial de Conversaciones.
 */
async function guardarFlorInteraction(opts) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return;
    const { phone, userMessage, botResponse, intent = 'consulta_general', success = true, usedAi = true, responseTimeMs = null } = opts;
    if (!phone || !userMessage || !botResponse) {
        console.warn('⚠️ guardarFlorInteraction: faltan phone, userMessage o botResponse');
        return;
    }
    try {
        const row = {
            phone: String(phone),
            user_message: String(userMessage),
            bot_response: String(botResponse),
            intent: String(intent),
            success: !!success,
            used_ai: !!usedAi,
            ai_model: CONFIG.GEMINI_MODEL || 'gemini-2.5-flash',
            whatsapp_instance: CONFIG.INSTANCE_NUMBER || 1
        };
        if (responseTimeMs != null) row.response_time_ms = Math.round(responseTimeMs);
        const { error, data } = await supabase.from('flor_interactions').insert([row]).select();
        if (error) throw error;
        console.log(`🌸 Interacción guardada en flor_interactions (ID: ${data?.[0]?.id || 'N/A'})`);
        console.log(`   📱 Phone: ${phone}, Intent: ${intent}, Success: ${success}, Response time: ${responseTimeMs || 'N/A'}ms`);
    } catch (e) {
        console.error('❌ Error guardando en flor_interactions:', e?.message || e);
        console.error('   Detalles:', JSON.stringify(e, null, 2));
    }
}

/**
 * Guardar mensaje en Supabase
 */
/**
 * Obtener o crear conversation_id para un número de teléfono
 * Intenta primero con whatsapp_conversations, luego con whatsapp_chats
 */
async function obtenerOcrearChatId(numero, nombre = null) {
    if (!supabase) return null;

    try {
        // PRIMERO: Intentar con whatsapp_conversations (si existe)
        // La tabla whatsapp_conversations tiene:
        // - id (uuid, auto-generado)
        // - external_id (text, REQUERIDO) - usamos el número de teléfono
        // - status (text, default: 'open')
        // - metadata (jsonb, default: '{}')
        // - created_at, updated_at (auto-generados)
        
        // Buscar conversación existente por external_id (que es el phone)
        let { data: conversacionExistente, error: errorBuscarConv } = await supabase
            .from('whatsapp_conversations')
            .select('id')
            .eq('external_id', numero)
            .limit(1)
            .maybeSingle(); // Usar maybeSingle para evitar error si no existe

        if (conversacionExistente && !errorBuscarConv) {
            console.log(`✅ Conversación existente encontrada para ${numero}`);
            return conversacionExistente.id;
        }

        // Si no existe, crear una nueva conversación
        // IMPORTANTE: external_id es REQUERIDO (NOT NULL sin default)
        const { data: nuevaConversacion, error: errorCrearConv } = await supabase
            .from('whatsapp_conversations')
            .insert({
                external_id: numero, // REQUERIDO - usamos el número de teléfono
                status: 'open',      // Tiene default pero lo incluimos por claridad
                metadata: {           // Opcional pero útil para guardar info adicional
                    phone: numero,
                    name: nombre || numero,
                    whatsapp_instance: CONFIG.INSTANCE_NUMBER
                }
            })
            .select('id')
            .single();

        if (nuevaConversacion && !errorCrearConv) {
            console.log(`✅ Nueva conversación creada en whatsapp_conversations para ${numero}`);
            return nuevaConversacion.id;
        } else if (errorCrearConv) {
            console.warn('⚠️ Error creando conversación en whatsapp_conversations:', errorCrearConv.message);
        }

        // SEGUNDO: Intentar con whatsapp_chats (estructura principal)
        // Buscar chat existente
        const { data: chatExistente, error: errorBuscarChat } = await supabase
            .from('whatsapp_chats')
            .select('id')
            .eq('phone', numero)
            .eq('whatsapp_instance', CONFIG.INSTANCE_NUMBER)
            .maybeSingle(); // Usar maybeSingle para evitar error si no existe

        if (chatExistente && !errorBuscarChat) {
            console.log(`✅ Chat existente encontrado en whatsapp_chats para ${numero}`);
            return chatExistente.id;
        }

        // Si no existe, crear uno nuevo
        const { data: nuevoChat, error: errorCrearChat } = await supabase
            .from('whatsapp_chats')
            .insert({
                phone: numero,
                name: nombre || numero,
                whatsapp_instance: CONFIG.INSTANCE_NUMBER,
                status: 'active',
                last_message: '',
                unread_count: 0
            })
            .select('id')
            .single();

        if (nuevoChat && !errorCrearChat) {
            console.log(`✅ Nuevo chat creado en whatsapp_chats para ${numero}`);
            return nuevoChat.id;
        } else if (errorCrearChat) {
            console.warn('⚠️ Error creando chat en whatsapp_chats:', errorCrearChat.message);
        }

        // Si todo falla, retornar null
        console.warn('⚠️ No se pudo obtener/crear conversation_id para', numero);
        return null;
    } catch (error) {
        console.warn('⚠️ Error obteniendo/creando conversation_id:', error.message);
        return null;
    }
}

/**
 * Guardar mensaje en Supabase
 * Estructura real: chat_id, phone, message, is_from_me, whatsapp_instance, message_type
 */
async function guardarMensaje(numero, mensaje, esEnviado = false, respuestaFlor = null, nombre = null) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return;

    try {
        // Obtener o crear chat_id desde whatsapp_chats
        const chatId = await obtenerOcrearChatId(numero, nombre);
        
        if (!chatId) {
            console.error('❌ No se pudo obtener/crear chat_id. No se puede guardar el mensaje.');
            return;
        }

        // Estructura: conversation_id, direction, sender, recipient (NOT NULL en producción).
        const direction = esEnviado ? 'outbound' : 'inbound';
        const sender = esEnviado ? (phoneNumber || `bot_${CONFIG.INSTANCE_NUMBER}`) : String(numero);
        const recipient = esEnviado ? String(numero) : (phoneNumber || `bot_${CONFIG.INSTANCE_NUMBER}`);
        const base = {
            conversation_id: chatId,
            chat_id: chatId,
            direction,
            sender,
            recipient,
            phone: numero,
            message: mensaje,
            is_from_me: esEnviado,
            is_read: false,
            whatsapp_instance: CONFIG.INSTANCE_NUMBER
        };
        let datosMensaje = { ...base };
        let datosConTipo = { ...base, message_type: 'text' };

        // Insertar: intentar con message_type; si falla por esa columna, sin ella
        let errorMensaje = null;
        let { error } = await supabase
            .from('whatsapp_messages')
            .insert(datosConTipo);
        
        if (error && error.message && error.message.includes('message_type')) {
            console.warn('⚠️ Tabla whatsapp_messages no tiene columna message_type, guardando sin ella');
            ({ error } = await supabase
                .from('whatsapp_messages')
                .insert(datosMensaje));
        }
        if (error && error.message && error.message.includes('chat_id')) {
            console.warn('⚠️ Tabla solo usa conversation_id, guardando sin chat_id');
            const soloConv = { conversation_id: chatId, direction, sender, recipient, phone: numero, message: mensaje, is_from_me: esEnviado, is_read: false, whatsapp_instance: CONFIG.INSTANCE_NUMBER };
            ({ error } = await supabase
                .from('whatsapp_messages')
                .insert(soloConv));
        }
        errorMensaje = error;

        if (errorMensaje) {
            if (errorMensaje.message && errorMensaje.message.includes('Invalid API key')) {
                console.error('⚠️ Error: API key de Supabase inválida. Verifica SUPABASE_ANON_KEY en EasyPanel');
            } else {
                console.error('❌ Error guardando mensaje:', errorMensaje.message || errorMensaje);
            }
            return;
        }

        console.log(`✅ Mensaje guardado en whatsapp_messages: ${esEnviado ? 'enviado' : 'recibido'} de ${numero} (sender=${sender}, recipient=${recipient})`);

        // Actualizar whatsapp_chats con el último mensaje
        const mensajePreview = mensaje.length > 100 ? mensaje.substring(0, 100) + '...' : mensaje;
        
        // Obtener unread_count actual si es un mensaje entrante
        let unreadCount = 0;
        if (!esEnviado) {
            const { data: chatData } = await supabase
                .from('whatsapp_chats')
                .select('unread_count')
                .eq('id', chatId)
                .single();
            unreadCount = (chatData?.unread_count || 0) + 1;
        }
        
        const { error: errorChat } = await supabase
            .from('whatsapp_chats')
            .update({
                last_message: mensajePreview,
                last_message_time: new Date().toISOString(),
                name: nombre || numero,
                unread_count: unreadCount,
                updated_at: new Date().toISOString()
            })
            .eq('id', chatId);

        if (errorChat) {
            console.warn('⚠️ Error actualizando whatsapp_chats:', errorChat.message || errorChat);
        } else {
            console.log(`✅ Chat actualizado en whatsapp_chats para ${numero}`);
        }

    } catch (error) {
        if (error.message && !error.message.includes('Invalid API key')) {
            console.error('❌ Error guardando mensaje:', error.message || error);
        }
    }
}

// ===== FUNCIÓN PARA CONECTAR WHATSAPP =====

async function connectToWhatsApp() {
    const { state, saveCreds } = await useMultiFileAuthState(`auth_info_baileys_${CONFIG.INSTANCE_NUMBER}`);
    
    const { version } = await fetchLatestBaileysVersion();
    
    sock = makeWASocket({
        auth: state,
        printQRInTerminal: true,
        version,
        browser: ['Chrome', 'Desktop', '1.0.0'],
        
        // MODO PASIVO
        passive: true, // Usar valores más estándar
        qrTimeout: 120000, // 120 segundos (2 minutos) para generar QR - más tiempo para escanear
        connectTimeoutMs: 300000, // 300 segundos (5 minutos) - AUMENTADO para dar más tiempo a la autenticación
        defaultQueryTimeoutMs: 60000, // 180 segundos (3 minutos) - AUMENTADO para queries
        keepAliveIntervalMs: 10000, // 20 segundos - REDUCIDO para mantener conexión más activa
        markOnlineOnConnect: true, // Marcar como online al conectar
        generateHighQualityLinkPreview: false, // Desactivar previews para mejor rendimiento
        syncFullHistory: false, // No sincronizar historial completo
        retryRequestDelayMs: 500, // 500ms - AUMENTADO para dar más tiempo entre reintentos
        maxMsgRetryCount: 3, // Máximo de reintentos para mensajes
        shouldSyncHistoryMessage: () => false, // No sincronizar historial
        shouldSyncAppState: () => false, // NO sincronizar app state (modo pasivo)
        shouldIgnoreJid: () => false, // No ignorar ningún JID
        getMessage: async (key) => {
            return undefined; // No obtener mensajes antiguos
        },
        // Optimizar sincronización del app state para evitar timeouts
        appStateSyncTimeoutMs: 0, // 5 minutos - AUMENTADO para dar más tiempo a la sincronización
        // Nota: La sincronización del app state es necesaria para WhatsApp
        // Los timeouts aumentados deberían dar suficiente tiempo para completar la autenticación
    });

    // Manejar eventos de conexión
    sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr) {
            // Limpiar QR code completamente
            let cleanQR = String(qr).trim();
            
            // Remover cualquier prefijo problemático
            cleanQR = cleanQR.replace(/^undefined,?/i, '');
            cleanQR = cleanQR.replace(/^null,?/i, '');
            cleanQR = cleanQR.replace(/^NaN,?/i, '');
            
            // Asegurar que el QR tenga el formato correcto (debe empezar con algo válido)
            if (!cleanQR || cleanQR.length < 10) {
                console.error('❌ QR code inválido recibido:', qr);
                return;
            }
            
            connectionStatus = 'connecting';
            
            console.log('📱 QR Code recibido (longitud:', cleanQR.length, 'caracteres)');
            console.log('📱 Primeros 50 caracteres del QR:', cleanQR.substring(0, 50));
            
            // Verificar si hay una sesión guardada (puede que no necesite escanear de nuevo)
            const authDir = path.join(__dirname, `auth_info_baileys_${CONFIG.INSTANCE_NUMBER}`);
            const hasAuthFiles = fs.existsSync(authDir) && fs.readdirSync(authDir).length > 0;
            if (hasAuthFiles) {
                console.log('💡 Nota: Hay archivos de autenticación guardados. Si ya escaneaste el QR anteriormente,');
                console.log('💡 es posible que este nuevo QR no sea necesario. Espera unos segundos para ver si');
                console.log('💡 la autenticación continúa automáticamente.');
            } else {
                console.log('📱 Por favor, escanea este QR code con WhatsApp para conectar.');
            }
            
            // Generar QR como imagen
            try {
                const qrImage = await qrcode.toDataURL(cleanQR, {
                    errorCorrectionLevel: 'M',
                    type: 'image/png',
                    quality: 0.92,
                    margin: 1,
                    width: 256
                });
                qrCodeData = {
                    qr: cleanQR,
                    qrImage: qrImage,
                    timestamp: Date.now()
                };
                console.log('✅ QR Code imagen generada exitosamente');
            } catch (error) {
                console.error('❌ Error generando QR imagen:', error);
                // Si falla la generación de imagen, guardar al menos el QR limpio
                qrCodeData = {
                    qr: cleanQR,
                    qrImage: null,
                    timestamp: Date.now()
                };
            }

            // Emitir QR via Socket.IO
            io.emit('qr', qrCodeData);
            console.log('📱 QR Code generado para instancia', CONFIG.INSTANCE_NUMBER);
        }

        if (connection === 'close') {
            // Verificar si debe reconectar (no debe reconectar si fue logout manual)
            const error = lastDisconnect?.error;
            const statusCode = error?.output?.statusCode;
            const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
            connectionStatus = 'close';
            phoneNumber = null;
            phoneName = null;
            
            console.log('❌ Conexión cerrada:', lastDisconnect?.error);
            console.log('📊 Detalles del error:', JSON.stringify({
                statusCode: statusCode,
                message: error?.message,
                data: error?.data
            }, null, 2));
            
            // Error 428: Connection Terminated by Server - Generalmente durante autenticación
            // No es un error crítico, solo reconectar sin limpiar sesión
            if (statusCode === 428) {
                console.log('⚠️ Error 428: Conexión terminada por servidor durante autenticación');
                console.log('💡 Esto es NORMAL cuando la autenticación tarda más de lo esperado');
                console.log('💡 Si ya escaneaste el QR, NO necesitas escanearlo de nuevo');
                console.log('💡 El sistema está reconectando automáticamente para continuar la autenticación...');
                console.log('🔄 Reconectando sin limpiar sesión (tu QR escaneado sigue siendo válido)...');
            }
            
            // Error 515: restart required - Normal después del pairing, no es un error crítico
            if (statusCode === 515) {
                console.log('ℹ️ Error 515: Restart required (normal después del pairing)');
                console.log('💡 El teléfono está autenticando, esperando antes de reconectar...');
                console.log('🔄 Reconectando automáticamente en 10 segundos...');
                // No limpiar sesión, solo reconectar
                // Dar más tiempo al teléfono para completar la autenticación
                io.emit('connection', { status: 'close' });
                if (shouldReconnect) {
                    setTimeout(() => {
                        console.log('🔄 Iniciando reconexión después de restart required...');
                        connectToWhatsApp().catch(err => {
                            console.error('❌ Error en reconexión:', err);
                            // Reintentar después de 30 segundos si falla
                            setTimeout(() => {
                                console.log('🔄 Reintentando reconexión después de error 515...');
                                connectToWhatsApp().catch(e => console.error('❌ Error en reintento:', e));
                            }, 30000);
                        });
                    }, 10000); // Aumentado a 10 segundos para dar tiempo al teléfono
                }
                return; // Salir temprano, no procesar más
            }
            
            // Detectar si el error es "device_removed" o conflicto de sesión
            const errorData = error?.data;
            
            // Múltiples formas de detectar device_removed
            const isDeviceRemoved = (
                // Forma 1: Error 401 con conflict device_removed
                (statusCode === 401 && errorData?.content?.some?.(
                    item => item?.tag === 'conflict' && item?.attrs?.type === 'device_removed'
                )) ||
                // Forma 2: Error 401 con stream:error
                (statusCode === 401 && errorData?.tag === 'stream:error' && errorData?.content?.some?.(
                    item => item?.tag === 'conflict' && item?.attrs?.type === 'device_removed'
                )) ||
                // Forma 3: Mensaje de error contiene "device_removed"
                (error?.message && error.message.includes('device_removed')) ||
                // Forma 4: Error 401 genérico (puede ser sesión conflictiva)
                (statusCode === 401 && error?.message?.includes('conflict'))
            );
            
            if (isDeviceRemoved || statusCode === 401) {
                // Verificar si estamos sincronizando app state
                // Si es así, puede ser un falso positivo - la sincronización puede tardar mucho
                if (isSyncingAppState || connectionStatus === 'syncing' || (connectionTimestamp && phoneNumber)) {
                    const timeSinceConnection = connectionTimestamp ? Date.now() - connectionTimestamp : 0;
                    const minutesSinceConnection = Math.round(timeSinceConnection / 60000);
                    const secondsSinceConnection = Math.round(timeSinceConnection / 1000);
                    
                    // Si la conexión ocurrió hace menos de 15 minutos, proteger la sesión
                    // (la sincronización puede tardar mucho tiempo)
                    if (minutesSinceConnection < 15 && secondsSinceConnection > 30) {
                        console.log('⚠️ Error durante sincronización del app state');
                        console.log(`💡 Tiempo desde conexión: ${minutesSinceConnection} minutos, ${secondsSinceConnection % 60} segundos`);
                        console.log('💡 Esto puede ser normal - la sincronización puede tardar varios minutos');
                        console.log('💡 Esperando más tiempo antes de considerar que es un error real...');
                        console.log('🔄 Reconectando sin limpiar sesión (puede ser solo un timeout de sincronización)...');
                        
                        // Reconectar sin limpiar sesión si estamos sincronizando
                        if (sock) {
                            try {
                                sock.end().catch(() => {});
                                sock = null;
                            } catch (e) {}
                        }
                        
                        // Reconectar después de un tiempo
                        setTimeout(() => {
                            console.log('🔄 Reconectando después de error durante sincronización...');
                            connectToWhatsApp().catch(err => {
                                console.error('❌ Error reconectando:', err);
                            });
                        }, 5000);
                        
                        return; // Salir sin limpiar sesión
                    }
                }
                
                console.log('⚠️ Sesión conflictiva detectada. Cerrando socket y limpiando sesión...');
                
                // Cerrar el socket actual antes de limpiar
                if (sock) {
                    try {
                        console.log('🔌 Cerrando socket actual...');
                        await sock.end();
                        sock = null;
                        console.log('✅ Socket cerrado correctamente');
                        connectionTimestamp = null; // Resetear timestamp de conexión
                        isSyncingAppState = false; // Resetear flag de sincronización
                    } catch (closeError) {
                        console.error('⚠️ Error cerrando socket (puede estar ya cerrado):', closeError.message);
                        sock = null;
                    }
                }
                
                // Esperar un momento para que el socket se cierre completamente
                await new Promise(resolve => setTimeout(resolve, 1000));
                
                const authDir = path.join(__dirname, `auth_info_baileys_${CONFIG.INSTANCE_NUMBER}`);
                try {
                    if (fs.existsSync(authDir)) {
                        // Eliminar todos los archivos y subdirectorios recursivamente
                        const deleteRecursive = (dir) => {
                            if (fs.existsSync(dir)) {
                                const files = fs.readdirSync(dir);
                                files.forEach(file => {
                                    const filePath = path.join(dir, file);
                                    const stat = fs.statSync(filePath);
                                    if (stat.isDirectory()) {
                                        deleteRecursive(filePath);
                                        fs.rmdirSync(filePath);
                                    } else {
                                        fs.unlinkSync(filePath);
                                    }
                                });
                            }
                        };
                        deleteRecursive(authDir);
                        // Intentar eliminar el directorio también
                        try {
                            fs.rmdirSync(authDir);
                        } catch (e) {
                            // Ignorar si no se puede eliminar (puede estar en uso)
                        }
                        console.log('✅ Sesión limpiada completamente. Se generará un nuevo QR code.');
                        qrCodeData = null; // Limpiar QR code actual
                    } else {
                        console.log('⚠️ Directorio de autenticación no existe, no hay nada que limpiar');
                    }
                } catch (cleanError) {
                    console.error('❌ Error limpiando sesión:', cleanError);
                }
                
                // Forzar reconexión después de limpiar sesión por device_removed
                console.log('🔄 Forzando reconexión después de limpiar sesión...');
                io.emit('connection', { status: 'close' });
                
                // Reconectar después de 10 segundos (dar tiempo para que se cierre todo)
                setTimeout(() => {
                    console.log('🔄 Iniciando reconexión después de device_removed...');
                    connectToWhatsApp().catch(err => {
                        console.error('❌ Error en reconexión después de device_removed:', err);
                        // Reintentar después de 30 segundos si falla
                        setTimeout(() => {
                            console.log('🔄 Reintentando reconexión después de error...');
                            connectToWhatsApp().catch(e => console.error('❌ Error en reintento:', e));
                        }, 30000);
                    });
                }, 10000);
                
                return; // Salir temprano después de limpiar sesión y programar reconexión
            }
            
            io.emit('connection', { status: 'close' });

            console.log('🔍 Verificando si debe reconectar...');
            console.log('   shouldReconnect:', shouldReconnect);
            console.log('   statusCode:', statusCode);
            console.log('   DisconnectReason.loggedOut:', DisconnectReason.loggedOut);

            if (shouldReconnect) {
                console.log('🔄 Reconectando...');
                // Delay más largo cuando hay error de sesión para evitar bloqueos
                // Error 428: delay corto (5 segundos) - es un error temporal durante autenticación
                // Error 401/device_removed: delay largo (10 segundos) - necesita limpiar sesión
                // Otros errores: delay medio (3 segundos)
                let reconnectDelay = 3000; // Default: 3 segundos
                if (isDeviceRemoved || statusCode === 401) {
                    reconnectDelay = 10000; // 10 segundos para errores de sesión
                } else if (statusCode === 428) {
                    reconnectDelay = 5000; // 5 segundos para error 428 (temporal)
                }
                
                setTimeout(() => {
                    console.log('🔄 Iniciando reconexión...');
                    connectToWhatsApp().catch(err => {
                        console.error('❌ Error en reconexión:', err);
                        // Reintentar después de 30 segundos si falla
                        setTimeout(() => {
                            console.log('🔄 Reintentando reconexión después de error...');
                            connectToWhatsApp().catch(e => console.error('❌ Error en reintento:', e));
                        }, 30000);
                    });
                }, reconnectDelay);
            }
        } else if (connection === 'open') {
            connectionStatus = 'open';
            
            // Guardar timestamp de conexión
            connectionTimestamp = Date.now();
            
            console.log('✅ WhatsApp conectado exitosamente para instancia', CONFIG.INSTANCE_NUMBER);
            
            // Obtener información del teléfono
            const me = sock.user;
            if (me) {
                phoneNumber = me.id.split(':')[0];
                phoneName = me.name || phoneNumber;
                console.log('📱 Teléfono conectado:', phoneNumber);
                console.log('👤 Nombre:', phoneName);
            } else {
                console.log('⚠️ No se pudo obtener información del usuario');
            }
            
            // Limpiar QR code ya que la conexión fue exitosa
            qrCodeData = null;
            
            io.emit('connection', { 
                status: 'open',
                phone: phoneNumber,
                name: phoneName
            });
            console.log('✅ Evento de conexión emitido via Socket.IO');
        } else if (connection === 'connecting') {
            connectionStatus = 'connecting';
            console.log('🔄 Estado: Conectando... (esperando autenticación)');
            
            // Si hay un QR code pero el estado es "connecting", significa que se escaneó el QR
            if (qrCodeData && qrCodeData.timestamp) {
                const timeSinceQR = Date.now() - qrCodeData.timestamp;
                const secondsElapsed = Math.round(timeSinceQR / 1000);
                console.log('⏳ QR escaneado, esperando autenticación... (tiempo transcurrido:', secondsElapsed, 'segundos)');
                
                // Advertir si está tomando mucho tiempo
                if (secondsElapsed > 60) {
                    console.log('⚠️  La autenticación está tardando más de lo normal. Esto puede ser normal, espera pacientemente.');
                }
                if (secondsElapsed > 120) {
                    console.log('⚠️  La autenticación está tardando más de 2 minutos. Verifica que no haya otras sesiones activas.');
                }
            }
            
            io.emit('connection', { status: 'connecting' });
        }
    });

    // Guardar credenciales cuando cambien
    sock.ev.on('creds.update', saveCreds);

    // Manejar mensajes recibidos
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
        if (type !== 'notify') return;

        for (const msg of messages) {
            // Solo procesar mensajes entrantes
            if (msg.key.fromMe) continue;

            const message = msg.message;
            if (!message) continue;

            // Obtener texto del mensaje
            let texto = '';
            if (message.conversation) {
                texto = message.conversation;
            } else if (message.extendedTextMessage?.text) {
                texto = message.extendedTextMessage.text;
            }

            if (!texto) continue;

            const numero = msg.key.remoteJid?.replace('@s.whatsapp.net', '') || '';
            const nombre = msg.pushName || numero;
            const remoteJid = msg.key.remoteJid;

            console.log(`📱 Mensaje recibido de ${nombre} (${numero}): ${texto}`);

            // Guardar mensaje recibido de inmediato
            await guardarMensaje(numero, texto, false, null, nombre);

            if (!CONFIG.AUTO_REPLY || !CONFIG.FLOR_ENABLED) continue;

            // Acumular mensajes y responder tras FLOR_DELAY_MS. Si llegan más en ese lapso, se agregan y Flor responde a todos.
            const key = String(remoteJid);
            let pending = florPendingByUser.get(key);

            if (!pending) {
                pending = {
                    timeoutId: null,
                    messages: [],
                    nombre,
                    numero,
                    remoteJid
                };
                florPendingByUser.set(key, pending);
            }

            pending.messages.push({ texto, ts: Date.now() });
            pending.nombre = nombre;
            pending.numero = numero;
            pending.remoteJid = remoteJid;

            if (pending.messages.length > 1) {
                console.log(`📬 Mensaje adicional de ${nombre} durante la espera (${pending.messages.length} en cola, ${FLOR_DELAY_MS}ms)`);
            }

            const processPending = async () => {
                const p = florPendingByUser.get(key);
                florPendingByUser.delete(key);
                if (!p || !p.messages.length) return;

                const textos = p.messages.map(m => m.texto);
                const combined = textos.length === 1
                    ? textos[0]
                    : textos.map((t, i) => `Consulta ${i + 1}: ${t}`).join('\n\n');

                console.log(`⏱️ Procesando ${textos.length} mensaje(s) de ${p.nombre} (delay ${FLOR_DELAY_MS}ms)`);

                const t0 = Date.now();
                const raw = await procesarConFlor(combined, {
                    numero: p.numero,
                    nombre: p.nombre,
                    instancia: CONFIG.INSTANCE_NUMBER,
                    multiConsultas: textos.length > 1,
                    consultas: textos
                });
                const responseTimeMs = Date.now() - t0;
                const respuestaFlor = (typeof raw === 'object' && raw != null && 'text' in raw) ? raw.text : (typeof raw === 'string' ? raw : null);
                const intentFlor = (typeof raw === 'object' && raw != null && raw.intent) ? raw.intent : 'consulta_general';
                const usedAi = intentFlor !== 'rate_limit_429';

                if (respuestaFlor && sock) {
                    await sock.sendMessage(p.remoteJid, { text: respuestaFlor });
                    await guardarMensaje(p.numero, respuestaFlor, true, respuestaFlor, p.nombre);
                    await guardarFlorInteraction({
                        phone: p.numero,
                        userMessage: combined,
                        botResponse: respuestaFlor,
                        intent: intentFlor,
                        success: true,
                        usedAi,
                        responseTimeMs
                    });
                    console.log(`✅ Flor respondió a ${p.nombre} (${textos.length} consulta(s))${intentFlor === 'rate_limit_429' ? ' [rate_limit_429]' : ''}`);
                }
            };

            // Timer de 5s desde el *primer* mensaje. Si llegan más en ese lapso, se acumulan; al cumplirse 5s se procesan todos.
            if (!pending.timeoutId) {
                pending.timeoutId = setTimeout(() => {
                    pending.timeoutId = null;
                    processPending();
                }, FLOR_DELAY_MS);
            }
        }
    });
}

// ===== API ENDPOINTS =====

// Favicon (evitar error 404) - Debe estar antes de otras rutas
app.get('/favicon.ico', (req, res) => {
    console.log('📌 Petición a /favicon.ico recibida');
    res.status(204).end();
});

// Health check (sin '/' para que la página HTML pueda mostrarse)
app.get(['/api/health', '/health'], (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.json({
        status: 'ok',
        instance: CONFIG.INSTANCE_NUMBER,
        whatsapp: connectionStatus,
        timestamp: new Date().toISOString()
    });
});

// API Flor: misma lógica que WhatsApp. La web (y otros canales) llaman aquí para que Flor responda igual.
app.post('/api/flor/process', async (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    try {
        const { message, context = {} } = req.body;
        if (!message || typeof message !== 'string') {
            return res.status(400).json({ error: 'message (string) es requerido' });
        }
        const respuesta = await procesarConFlor(message.trim(), context);
        const text = respuesta && typeof respuesta === 'object' && respuesta.text != null
            ? respuesta.text
            : (typeof respuesta === 'string' ? respuesta : null);
        res.json({ response: text, success: !!text });
    } catch (error) {
        console.error('Error en /api/flor/process:', error);
        res.status(500).json({ error: error.message, response: null });
    }
});
app.options('/api/flor/process', (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).end();
});

// Obtener QR Code
app.get(['/api/qr', '/qr'], async (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    
    // Detectar si es una petición del navegador (HTML) o API (JSON)
    const acceptsHtml = req.headers.accept && req.headers.accept.includes('text/html');
    const isApiRequest = req.headers.accept && req.headers.accept.includes('application/json');
    const userAgent = req.headers['user-agent'] || '';
    // Detectar navegador: si no es curl/Postman/axios y no tiene header Accept con application/json explícito
    const isBrowser = !userAgent.includes('curl') && 
                      !userAgent.includes('Postman') && 
                      !userAgent.includes('axios') &&
                      !userAgent.includes('node') &&
                      (acceptsHtml || req.path === '/qr' || (!isApiRequest && userAgent.includes('Mozilla')));
    
    if (qrCodeData) {
        // Asegurar que el QR esté limpio (sin "undefined," al inicio)
        let qrValue = qrCodeData.qr || qrCodeData;
        if (typeof qrValue === 'string' && qrValue.startsWith('undefined,')) {
            qrValue = qrValue.replace(/^undefined,/, '');
        }
        
        const qrImage = qrCodeData.qrImage || null;
        
        // Si es navegador (incluso si accede a /api/qr), devolver HTML
        if (isBrowser) {
            const html = `<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WhatsApp QR Code - Checkin24hs</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 500px;
            width: 100%;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 16px;
        }
        .qr-container {
            background: #f5f5f5;
            border-radius: 15px;
            padding: 30px;
            margin: 30px 0;
            display: inline-block;
        }
        .qr-container img {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
        }
        .status {
            margin-top: 20px;
            padding: 12px 24px;
            border-radius: 25px;
            font-weight: 600;
            display: inline-block;
        }
        .status.waiting {
            background: #fff3cd;
            color: #856404;
        }
        .status.connected {
            background: #d4edda;
            color: #155724;
        }
        .instructions {
            margin-top: 30px;
            color: #666;
            font-size: 14px;
            line-height: 1.6;
        }
        .instructions ol {
            text-align: left;
            display: inline-block;
            margin-top: 10px;
        }
        .instructions li {
            margin: 8px 0;
        }
        .refresh-btn {
            margin-top: 20px;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.3s;
        }
        .refresh-btn:hover {
            background: #5568d3;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌸 WhatsApp QR Code</h1>
        <p class="subtitle">Checkin24hs - Instancia ${CONFIG.INSTANCE_NUMBER}</p>
        
        <div class="qr-container">
            ${qrImage ? `<img src="${qrImage}" alt="QR Code" id="qr-image">` : '<p>Cargando QR code...</p>'}
        </div>
        
        <div class="status waiting" id="status">
            Escanea este código con WhatsApp
        </div>
        
        <div class="instructions">
            <p><strong>Instrucciones:</strong></p>
            <ol>
                <li>Abre WhatsApp en tu teléfono</li>
                <li>Ve a <strong>Configuración</strong> → <strong>Dispositivos vinculados</strong></li>
                <li>Toca <strong>Vincular un dispositivo</strong></li>
                <li>Escanea este código QR</li>
            </ol>
        </div>
        
        <button class="refresh-btn" onclick="location.reload()">🔄 Actualizar</button>
    </div>
    
    <script>
        // Auto-refresh cada 30 segundos si está esperando
        let refreshInterval = setInterval(() => {
            fetch('/api/status')
                .then(res => res.json())
                .then(data => {
                    if (data.status === 'connected') {
                        clearInterval(refreshInterval);
                        document.getElementById('status').textContent = '✅ Conectado';
                        document.getElementById('status').className = 'status connected';
                    }
                })
                .catch(err => console.error('Error:', err));
        }, 30000);
    </script>
</body>
</html>`;
            res.setHeader('Content-Type', 'text/html; charset=utf-8');
            return res.send(html);
        }
        
        // Si es API, devolver JSON
        res.json({
            status: 'waiting_scan',
            qr: qrValue,
            qrImage: qrImage,
            phone: phoneNumber,
            name: phoneName
        });
    } else {
        // No hay QR disponible
        if (isBrowser && !req.path.includes('/api/')) {
            const html = `<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WhatsApp - Checkin24hs</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 500px;
        }
        h1 { color: #333; margin-bottom: 20px; }
        .status {
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .status.connected {
            background: #d4edda;
            color: #155724;
        }
        .status.initializing {
            background: #fff3cd;
            color: #856404;
        }
        .refresh-btn {
            margin-top: 20px;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌸 WhatsApp - Checkin24hs</h1>
        <div class="status ${connectionStatus === 'open' ? 'connected' : 'initializing'}">
            ${connectionStatus === 'open' ? '✅ Conectado' : '⏳ Inicializando...'}
        </div>
        ${phoneNumber ? `<p>Teléfono: ${phoneNumber}</p>` : ''}
        <button class="refresh-btn" onclick="location.reload()">🔄 Actualizar</button>
    </div>
</body>
</html>`;
            res.setHeader('Content-Type', 'text/html; charset=utf-8');
            return res.send(html);
        }
        
        res.json({
            status: connectionStatus === 'open' ? 'connected' : 'initializing',
            qr: null,
            phone: phoneNumber,
            name: phoneName
        });
    }
});

// Obtener estado
app.get(['/api/status', '/status'], (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    
    // Detectar si es una petición del navegador (HTML) o API (JSON)
    const acceptsHtml = req.headers.accept && req.headers.accept.includes('text/html');
    const isApiRequest = req.headers.accept && req.headers.accept.includes('application/json');
    const userAgent = req.headers['user-agent'] || '';
    // Detectar navegador: si no es curl/Postman/axios y no tiene header Accept con application/json explícito
    const isBrowser = !userAgent.includes('curl') && 
                      !userAgent.includes('Postman') && 
                      !userAgent.includes('axios') &&
                      !userAgent.includes('node') &&
                      (acceptsHtml || req.path === '/status' || (!isApiRequest && userAgent.includes('Mozilla')));
    
    const statusData = {
        connected: connectionStatus === 'open',
        whatsapp: connectionStatus === 'open' ? 'connected' : 'disconnected',
        flor: CONFIG.FLOR_ENABLED ? 'active' : 'inactive',
        autoReply: CONFIG.AUTO_REPLY,
        qrCode: qrCodeData ? (qrCodeData.qrImage || `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent((qrCodeData.qr || qrCodeData).replace(/^undefined,/, ''))}`) : null,
        phone: phoneNumber,
        name: phoneName,
        instance: CONFIG.INSTANCE_NUMBER
    };
    
    // Si es navegador (incluso si accede a /api/status), devolver HTML
    if (isBrowser) {
        const html = `<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Estado WhatsApp - Checkin24hs</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 600px;
            width: 100%;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 16px;
        }
        .status-card {
            background: #f5f5f5;
            border-radius: 15px;
            padding: 20px;
            margin: 20px 0;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        .status-item:last-child {
            border-bottom: none;
        }
        .status-label {
            font-weight: 600;
            color: #333;
        }
        .status-value {
            padding: 6px 16px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 14px;
        }
        .status-value.connected {
            background: #d4edda;
            color: #155724;
        }
        .status-value.disconnected {
            background: #f8d7da;
            color: #721c24;
        }
        .status-value.active {
            background: #d1ecf1;
            color: #0c5460;
        }
        .qr-container {
            background: #f5f5f5;
            border-radius: 15px;
            padding: 30px;
            margin: 30px 0;
            display: inline-block;
        }
        .qr-container img {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
        }
        .phone-info {
            margin-top: 20px;
            padding: 15px;
            background: #e7f3ff;
            border-radius: 10px;
            color: #004085;
        }
        .refresh-btn {
            margin-top: 20px;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.3s;
        }
        .refresh-btn:hover {
            background: #5568d3;
        }
        .no-qr {
            color: #666;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌸 Estado WhatsApp</h1>
        <p class="subtitle">Checkin24hs - Instancia ${CONFIG.INSTANCE_NUMBER}</p>
        
        <div class="status-card">
            <div class="status-item">
                <span class="status-label">Estado:</span>
                <span class="status-value ${statusData.connected ? 'connected' : 'disconnected'}">
                    ${statusData.connected ? '✅ Conectado' : '❌ Desconectado'}
                </span>
            </div>
            <div class="status-item">
                <span class="status-label">WhatsApp:</span>
                <span class="status-value ${statusData.whatsapp === 'connected' ? 'connected' : 'disconnected'}">
                    ${statusData.whatsapp === 'connected' ? 'Conectado' : 'Desconectado'}
                </span>
            </div>
            <div class="status-item">
                <span class="status-label">Flor IA:</span>
                <span class="status-value ${statusData.flor === 'active' ? 'active' : 'disconnected'}">
                    ${statusData.flor === 'active' ? 'Activa' : 'Inactiva'}
                </span>
            </div>
            <div class="status-item">
                <span class="status-label">Respuesta Automática:</span>
                <span class="status-value ${statusData.autoReply ? 'active' : 'disconnected'}">
                    ${statusData.autoReply ? 'Activada' : 'Desactivada'}
                </span>
            </div>
        </div>
        
        ${statusData.qrCode ? `
        <div class="qr-container">
            <h3 style="margin-bottom: 15px; color: #333;">QR Code</h3>
            <img src="${statusData.qrCode}" alt="QR Code" id="qr-image">
            <p style="margin-top: 15px; color: #666; font-size: 14px;">Escanea este código con WhatsApp</p>
        </div>
        ` : statusData.connected ? '' : '<p class="no-qr">QR Code no disponible</p>'}
        
        ${statusData.phone ? `
        <div class="phone-info">
            <strong>Teléfono:</strong> ${statusData.phone}<br>
            ${statusData.name ? `<strong>Nombre:</strong> ${statusData.name}` : ''}
        </div>
        ` : ''}
        
        <button class="refresh-btn" onclick="location.reload()">🔄 Actualizar</button>
    </div>
    
    <script>
        // Auto-refresh cada 30 segundos
        let refreshInterval = setInterval(() => {
            fetch('/api/status')
                .then(res => res.json())
                .then(data => {
                    if (data.connected && data.whatsapp === 'connected') {
                        clearInterval(refreshInterval);
                        location.reload();
                    }
                })
                .catch(err => console.error('Error:', err));
        }, 30000);
    </script>
</body>
</html>`;
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        return res.send(html);
    }
    
    // Si es API, devolver JSON
    res.json(statusData);
});

// Enviar mensaje
app.post('/api/send', async (req, res) => {
    try {
        const { number, text } = req.body;

        if (!number || !text) {
            return res.status(400).json({ error: 'number y text son requeridos' });
        }

        if (connectionStatus !== 'open') {
            return res.status(400).json({ error: 'WhatsApp no está conectado' });
        }

        const jid = `${number}@s.whatsapp.net`;
        await sock.sendMessage(jid, { text });

        await guardarMensaje(number, text, true, null, null);

        res.json({ success: true, message: 'Mensaje enviado' });
    } catch (error) {
        console.error('Error enviando mensaje:', error);
        res.status(500).json({ error: error.message });
    }
});

// Página HTML simple para mostrar QR
app.get('/', (req, res) => {
    console.log('📌 Petición a / recibida');
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>WhatsApp ${CONFIG.INSTANCE_NUMBER} - Checkin24hs</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="/socket.io/socket.io.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 500px;
            width: 100%;
        }
        h1 { color: #333; margin-bottom: 10px; }
        .subtitle { color: #666; margin-bottom: 30px; }
        .status {
            padding: 15px 25px;
            border-radius: 10px;
            font-weight: bold;
            margin: 20px 0;
        }
        .status.connected { background: #d4edda; color: #155724; }
        .status.disconnected { background: #f8d7da; color: #721c24; }
        .status.connecting { background: #fff3cd; color: #856404; }
        #qr-container { margin: 20px 0; }
        #qr-container img { max-width: 256px; border-radius: 10px; }
        .instructions {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
            text-align: left;
        }
        .instructions h3 { margin-bottom: 10px; color: #333; }
        .instructions ol { margin-left: 20px; }
        .instructions li { margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📱 WhatsApp ${CONFIG.INSTANCE_NUMBER}</h1>
        <p class="subtitle">Checkin24hs - Flor IA</p>
        
        <div id="status" class="status disconnected">Desconectado</div>
        
        <div id="qr-container"></div>
        
        <div id="phone-info" style="display: none; margin: 20px 0;">
            <p><strong>Teléfono:</strong> <span id="phone-number">-</span></p>
            <p><strong>Nombre:</strong> <span id="phone-name">-</span></p>
        </div>
        
        <div class="instructions">
            <h3>📱 Cómo conectar:</h3>
            <ol>
                <li>Abre WhatsApp en tu teléfono</li>
                <li>Ve a <strong>Configuración</strong> → <strong>Dispositivos vinculados</strong></li>
                <li>Toca <strong>Vincular un dispositivo</strong></li>
                <li>Escanea el código QR que aparece arriba</li>
            </ol>
        </div>
    </div>

    <script>
        const socket = io();
        const statusDiv = document.getElementById('status');
        const qrContainer = document.getElementById('qr-container');
        const phoneInfo = document.getElementById('phone-info');
        const phoneNumber = document.getElementById('phone-number');
        const phoneName = document.getElementById('phone-name');

        socket.on('qr', (data) => {
            const qr = data.qr || data;
            const qrImage = data.qrImage;
            
            if (qrImage) {
                qrContainer.innerHTML = '<img src="' + qrImage + '" alt="QR Code">';
            } else {
                // Generar QR usando API externa
                const qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=' + encodeURIComponent(qr);
                qrContainer.innerHTML = '<img src="' + qrUrl + '" alt="QR Code">';
            }
            
            statusDiv.textContent = 'Conectando...';
            statusDiv.className = 'status connecting';
        });

        socket.on('connection', (data) => {
            if (data.status === 'open') {
                statusDiv.textContent = 'Conectado ✅';
                statusDiv.className = 'status connected';
                qrContainer.innerHTML = '<div style="font-size: 48px;">✅</div><p>WhatsApp conectado exitosamente</p>';
                
                if (data.phone) {
                    phoneNumber.textContent = data.phone;
                    phoneName.textContent = data.name || data.phone;
                    phoneInfo.style.display = 'block';
                }
            } else if (data.status === 'close') {
                statusDiv.textContent = 'Desconectado';
                statusDiv.className = 'status disconnected';
                qrContainer.innerHTML = '';
                phoneInfo.style.display = 'none';
            } else if (data.status === 'connecting') {
                statusDiv.textContent = 'Conectando...';
                statusDiv.className = 'status connecting';
            }
        });

        // Cargar estado inicial
        fetch('/api/status')
            .then(res => res.json())
            .then(data => {
                if (data.connected || data.whatsapp === 'connected') {
                    statusDiv.textContent = 'Conectado ✅';
                    statusDiv.className = 'status connected';
                    qrContainer.innerHTML = '<div style="font-size: 48px;">✅</div><p>WhatsApp conectado</p>';
                    if (data.phone) {
                        phoneNumber.textContent = data.phone;
                        phoneName.textContent = data.name || data.phone;
                        phoneInfo.style.display = 'block';
                    }
                } else {
                    // Intentar obtener QR code
                    fetch('/api/qr')
                        .then(res => res.json())
                        .then(qrData => {
                            if (qrData.qr && qrData.status === 'waiting_scan') {
                                const qr = qrData.qr;
                                const qrImage = qrData.qrImage;
                                
                                if (qrImage) {
                                    qrContainer.innerHTML = '<img src="' + qrImage + '" alt="QR Code">';
                                } else {
                                    const qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=' + encodeURIComponent(qr);
                                    qrContainer.innerHTML = '<img src="' + qrUrl + '" alt="QR Code">';
                                }
                                statusDiv.textContent = 'Conectando...';
                                statusDiv.className = 'status connecting';
                            } else {
                                statusDiv.textContent = 'Esperando QR code...';
                                statusDiv.className = 'status disconnected';
                            }
                        })
                        .catch(err => {
                            console.error('Error cargando QR:', err);
                            statusDiv.textContent = 'Esperando QR code...';
                            statusDiv.className = 'status disconnected';
                        });
                }
            })
            .catch(err => {
                console.error('Error cargando estado:', err);
                statusDiv.textContent = 'Error cargando estado';
                statusDiv.className = 'status disconnected';
            });
    </script>
</body>
</html>
    `);
});

// ===== INICIAR SERVIDOR =====

async function start() {
    try {
        // Limpiar QR y estado al iniciar (por si hay un QR viejo en memoria)
        qrCodeData = null;
        connectionStatus = 'close';
        if (qrExpirationTimer) {
            clearTimeout(qrExpirationTimer);
            qrExpirationTimer = null;
        }
        
        // Iniciar servidor HTTP PRIMERO (antes de conectar WhatsApp)
        // Esto asegura que el servidor esté disponible incluso si WhatsApp tarda en conectar
        server.listen(CONFIG.PORT, '0.0.0.0', () => {
            console.log(`✅ Servidor iniciado en puerto ${CONFIG.PORT}`);
            console.log(`📱 Instancia WhatsApp: ${CONFIG.INSTANCE_NUMBER}`);
            console.log(`🌐 Servidor escuchando en 0.0.0.0:${CONFIG.PORT} (accesible desde cualquier interfaz)`);
            if (CONFIG.BASE_URL) {
                console.log(`🔗 URL base configurada: ${CONFIG.BASE_URL}`);
            }
            console.log(`📋 Endpoints disponibles:`);
            console.log(`   - GET  ${CONFIG.BASE_URL || `http://0.0.0.0:${CONFIG.PORT}`}/api/health`);
            console.log(`   - GET  ${CONFIG.BASE_URL || `http://0.0.0.0:${CONFIG.PORT}`}/api/status`);
            console.log(`   - GET  ${CONFIG.BASE_URL || `http://0.0.0.0:${CONFIG.PORT}`}/api/qr`);
        });

        // Conectar a WhatsApp (después de iniciar el servidor)
        // Esto se hace en segundo plano para no bloquear el servidor HTTP
        connectToWhatsApp().catch(error => {
            console.error('❌ Error conectando a WhatsApp:', error);
            // El servidor HTTP seguirá funcionando aunque WhatsApp falle
        });
    } catch (error) {
        console.error('❌ Error iniciando servidor:', error);
        process.exit(1);
    }
}

// Manejar cierre limpio
process.on('SIGINT', () => {
    console.log('\n🛑 Cerrando servidor...');
    if (sock) {
        sock.end();
    }
    process.exit(0);
});

// Iniciar
start();

