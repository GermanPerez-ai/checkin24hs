/**
 * 🌸 Servidor de WhatsApp para Flor - Checkin24hs
 * 
 * Este servidor conecta WhatsApp con el chatbot Flor
 * Permite usar WhatsApp en el teléfono mientras Flor responde automáticamente
 * 
 * VERSIÓN 2.0 - Integración con Supabase
 * - Guarda chats e interacciones en Supabase
 * - Auto-crea usuarios desde contactos de WhatsApp
 * - Aprendizaje automático de Flor
 */

// ===== LOGS DE INICIO =====
console.log('🚀 Iniciando servidor WhatsApp...');
console.log('📦 Cargando dependencias...');

const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

console.log('✅ Dependencias cargadas');

// ===== CONFIGURAR LD_LIBRARY_PATH PARA PUPPETEER =====
// Asegurar que las librerías del sistema sean accesibles para Chromium de Puppeteer
if (!process.env.LD_LIBRARY_PATH) {
    process.env.LD_LIBRARY_PATH = '/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/lib';
} else {
    process.env.LD_LIBRARY_PATH = `/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/lib:${process.env.LD_LIBRARY_PATH}`;
}
console.log(`📚 LD_LIBRARY_PATH configurado: ${process.env.LD_LIBRARY_PATH}`);

// ===== CONFIGURACIÓN =====
const CONFIG = {
    PORT: process.env.PORT || 3001,
    INSTANCE_NUMBER: parseInt(process.env.INSTANCE_NUMBER) || 1, // Número de instancia de WhatsApp (1, 2, 3, 4)
    AUTO_REPLY: true,                    // Activar respuestas automáticas de Flor
    FLOR_ENABLED: true,                  // Habilitar Flor
    SAVE_MESSAGES: true,                 // Guardar mensajes en archivo
    SAVE_TO_SUPABASE: true,              // Guardar en Supabase
    USE_GEMINI_AI: true,                 // Usar Gemini IA para respuestas inteligentes
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',  // Se configura desde el endpoint /api/config
    GEMINI_MODEL: 'gemini-1.5-flash',    // Modelo de Gemini
    AGENT_NUMBERS: [                     // Números de agentes (no reciben respuestas automáticas)
        // Agregar números de agentes aquí en formato: '5491112345678@c.us'
    ],
    BUSINESS_HOURS: {
        enabled: false,                   // Activar horario de atención
        start: 9,                        // Hora inicio (24h)
        end: 21,                         // Hora fin (24h)
        timezone: 'America/Argentina/Buenos_Aires'
    },
    SUPABASE: {
        url: (process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co').trim(),
        anonKey: (process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4').trim()
    }
};

// ===== CLIENTE DE SUPABASE =====
let supabase = null;
try {
    supabase = createClient(CONFIG.SUPABASE.url, CONFIG.SUPABASE.anonKey);
    console.log('✅ Cliente de Supabase inicializado');
} catch (e) {
    console.error('❌ Error inicializando Supabase:', e.message);
}

// Cargar configuración guardada
const configFile = path.join(__dirname, 'config.json');
if (fs.existsSync(configFile)) {
    try {
        const savedConfig = JSON.parse(fs.readFileSync(configFile, 'utf8'));
        if (savedConfig.GEMINI_API_KEY) CONFIG.GEMINI_API_KEY = savedConfig.GEMINI_API_KEY;
        if (savedConfig.GEMINI_MODEL) CONFIG.GEMINI_MODEL = savedConfig.GEMINI_MODEL;
        if (savedConfig.USE_GEMINI_AI !== undefined) CONFIG.USE_GEMINI_AI = savedConfig.USE_GEMINI_AI;
        console.log('✅ Configuración cargada desde config.json');
    } catch (e) {
        console.log('⚠️ No se pudo cargar config.json');
    }
}

// ===== BASE DE CONOCIMIENTO DE FUTURA FLOR =====
// Base de conocimiento básica (fallback)
const FLOR_KNOWLEDGE_BASIC = {
    agent: {
        name: "Futura Flor",
        greeting: "¡Hola! 👋 Mi nombre es Futura Flor, soy la asistente virtual de *Checkin24hs*. ¿En qué puedo ayudarte hoy?",
        farewell: "¡Gracias por contactarnos! Si necesitas algo más, no dudes en escribirme. ¡Que tengas un excelente día! 🌸"
    },
    responses: {
        hotels: "🏨 Trabajamos con los mejores hoteles de lujo en la Patagonia:\n\n• *Hotel Terma de Puyehue* - Spa termal\n• *Hotel Huilo-Huilo* - Selva Valdiviana\n• *Hotel Corralco* - Ski y naturaleza\n• *Hotel Futangue* - Lagos y montañas\n\n¿Sobre cuál te gustaría más información?",
        prices: "💰 Los precios varían según la temporada y tipo de habitación. Para darte una cotización exacta, necesito:\n\n• Fecha de entrada\n• Fecha de salida\n• Cantidad de personas\n• Hotel de preferencia\n\n¿Me proporcionas estos datos?",
        reservation: "📅 ¡Excelente decisión! Para hacer una reserva, un agente humano te asistirá personalmente.\n\nTu solicitud ha sido registrada y un agente se pondrá en contacto contigo pronto.\n\n¿Hay algo más en lo que pueda ayudarte mientras tanto?",
        contact: "📞 Puedes contactarnos por:\n\n• WhatsApp: Este mismo número\n• Email: reservas@checkin24hs.com\n• Web: www.checkin24hs.com\n\n¿En qué más puedo ayudarte?",
        unknown: "🤔 Disculpa, no estoy segura de entender tu consulta. Puedo ayudarte con:\n\n• Información de hoteles\n• Cotizaciones\n• Reservas\n• Servicios disponibles\n\n¿Qué te interesa saber?"
    }
};

// Base de conocimiento cargada desde Supabase (se actualiza dinámicamente)
let FLOR_KNOWLEDGE = { ...FLOR_KNOWLEDGE_BASIC };
let FLOR_HOTELS_KNOWLEDGE = {}; // Conocimiento detallado por hotel
let FLOR_HOTELS_LIST = []; // Lista de hoteles desde Supabase

// Cargar base de conocimiento desde Supabase
async function loadFlorKnowledgeFromSupabase() {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) {
        console.log('⚠️ Supabase no disponible, usando base de conocimiento básica');
        return;
    }

    try {
        console.log('📚 Cargando base de conocimiento de Flor desde Supabase...');
        
        // Cargar hoteles desde Supabase
        const { data: hotels, error: hotelsError } = await supabase
            .from('hotels')
            .select('*')
            .order('name');
        
        if (!hotelsError && hotels && hotels.length > 0) {
            FLOR_HOTELS_LIST = hotels;
            console.log(`✅ ${hotels.length} hoteles cargados desde Supabase`);
            
            // Construir lista de hoteles para respuestas
            const hotelsList = hotels.map(h => `• *${h.name}*${h.description ? ' - ' + h.description.substring(0, 50) : ''}`).join('\n');
            FLOR_KNOWLEDGE.responses.hotels = `🏨 Trabajamos con los mejores hoteles de lujo en la Patagonia:\n\n${hotelsList}\n\n¿Sobre cuál te gustaría más información?`;
        }
        
        // Cargar base de conocimiento de hoteles desde system_config
        const { data: knowledgeConfig, error: knowledgeError } = await supabase
            .from('system_config')
            .select('value')
            .eq('key', 'flor_hotel_knowledge')
            .single();
        
        if (!knowledgeError && knowledgeConfig && knowledgeConfig.value) {
            try {
                FLOR_HOTELS_KNOWLEDGE = JSON.parse(knowledgeConfig.value);
                console.log(`✅ Base de conocimiento de hoteles cargada (${Object.keys(FLOR_HOTELS_KNOWLEDGE).length} hoteles)`);
            } catch (e) {
                console.error('❌ Error parseando base de conocimiento:', e);
            }
        }
        
        // Cargar configuración del agente Flor
        const { data: agentConfig, error: agentError } = await supabase
            .from('system_config')
            .select('value')
            .eq('key', 'flor_agent_config')
            .single();
        
        if (!agentError && agentConfig && agentConfig.value) {
            try {
                const agentData = JSON.parse(agentConfig.value);
                if (agentData.name) FLOR_KNOWLEDGE.agent.name = agentData.name;
                if (agentData.greeting) FLOR_KNOWLEDGE.agent.greeting = agentData.greeting;
                if (agentData.farewell) FLOR_KNOWLEDGE.agent.farewell = agentData.farewell;
                console.log('✅ Configuración del agente Flor cargada');
            } catch (e) {
                console.error('❌ Error parseando configuración del agente:', e);
            }
        }
        
        console.log('✅ Base de conocimiento de Flor cargada correctamente');
    } catch (error) {
        console.error('❌ Error cargando base de conocimiento desde Supabase:', error);
        console.log('⚠️ Usando base de conocimiento básica');
    }
}

// Recargar base de conocimiento periódicamente (cada 5 minutos)
setInterval(() => {
    if (supabase && CONFIG.SAVE_TO_SUPABASE) {
        loadFlorKnowledgeFromSupabase();
    }
}, 5 * 60 * 1000); // 5 minutos

// ===== INICIALIZACIÓN =====
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// CORS configuración completa
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: false
}));

// Middleware adicional para headers CORS (por si acaso)
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});

app.use(express.json());
app.use(express.static('public'));

// Estado del cliente
let clientReady = false;
let qrCodeData = null;

// Función para limpiar locks de Chrome antes de inicializar
function cleanChromeLocks(dataPath) {
    try {
        const sessionPath = path.join(__dirname, dataPath);
        const defaultPath = path.join(sessionPath, 'session', 'Default');
        
        if (fs.existsSync(defaultPath)) {
            // Eliminar archivos de lock
            const lockFiles = [
                'SingletonLock',
                'SingletonSocket',
                'SingletonCookie',
                'lockfile'
            ];
            
            lockFiles.forEach(lockFile => {
                const lockPath = path.join(defaultPath, lockFile);
                if (fs.existsSync(lockPath)) {
                    try {
                        fs.unlinkSync(lockPath);
                        console.log(`✅ Lock eliminado: ${lockFile}`);
                    } catch (e) {
                        // Ignorar errores si el archivo está en uso
                    }
                }
            });
            
            // Buscar y eliminar otros archivos de lock
            try {
                const files = fs.readdirSync(defaultPath);
                files.forEach(file => {
                    if (file.includes('Lock') || file.includes('Singleton')) {
                        const filePath = path.join(defaultPath, file);
                        try {
                            fs.unlinkSync(filePath);
                        } catch (e) {
                            // Ignorar errores
                        }
                    }
                });
            } catch (e) {
                // Ignorar errores de lectura
            }
        }
    } catch (error) {
        console.log(`⚠️ No se pudieron limpiar locks (puede ser normal): ${error.message}`);
    }
}

// Directorio de sesión único por instancia
const sessionDataPath = `.wwebjs_auth_${CONFIG.INSTANCE_NUMBER}`;
console.log(`📁 Usando directorio de sesión: ${sessionDataPath} (Instancia ${CONFIG.INSTANCE_NUMBER})`);

// Limpiar locks antes de crear el cliente
cleanChromeLocks(sessionDataPath);

// Nota: Usamos Chromium del sistema (PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true)
// por lo que no necesitamos copiar librerías al Chromium de Puppeteer

// Crear cliente de WhatsApp con autenticación local (persiste la sesión)
// Usar Chromium del sistema si está disponible, de lo contrario usar el de Puppeteer
const chromiumPath = process.env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium';
const puppeteerConfig = {
    headless: true,
    args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--single-process',
        '--disable-gpu',
        '--disable-software-rasterizer',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-renderer-backgrounding',
        '--disable-features=TranslateUI',
        '--disable-ipc-flooding-protection',
        `--user-data-dir=${path.join(__dirname, sessionDataPath, 'session')}`
    ]
};

// FORZAR uso del Chromium del sistema (ya instalado en el Dockerfile)
// Validar ANTES de crear el cliente para evitar que Puppeteer descargue su propio Chromium
let executablePath = null;
const { execSync } = require('child_process');

// Función para verificar si un archivo existe y es ejecutable
function checkExecutable(filePath) {
    try {
        if (fs.existsSync(filePath)) {
            // Verificar que sea ejecutable
            fs.accessSync(filePath, fs.constants.F_OK | fs.constants.X_OK);
            return true;
        }
    } catch (e) {
        return false;
    }
    return false;
}

// 1. Verificar la ruta configurada en la variable de entorno
if (chromiumPath && checkExecutable(chromiumPath)) {
    executablePath = chromiumPath;
    console.log(`✅ Chromium del sistema encontrado (ENV): ${chromiumPath}`);
} else {
    // 2. Buscar en ubicaciones comunes de Debian/Ubuntu
    const systemPaths = [
        '/usr/bin/chromium',
        '/usr/bin/chromium-browser',
        '/usr/bin/chromium/chromium',
        '/usr/bin/google-chrome',
        '/usr/bin/google-chrome-stable',
        '/snap/bin/chromium',
        '/usr/lib/chromium-browser/chromium-browser',
        '/usr/lib/chromium/chromium'
    ];
    
    for (const altPath of systemPaths) {
        if (checkExecutable(altPath)) {
            executablePath = altPath;
            console.log(`✅ Chromium encontrado en: ${altPath}`);
            break;
        }
    }
    
    // 3. Si aún no se encuentra, intentar con which/whereis
    if (!executablePath) {
        try {
            // Intentar which primero
            const chromiumFound = execSync('which chromium chromium-browser 2>/dev/null | head -1', { encoding: 'utf8', timeout: 5000 }).trim();
            if (chromiumFound && checkExecutable(chromiumFound)) {
                executablePath = chromiumFound;
                console.log(`✅ Chromium encontrado con which: ${chromiumFound}`);
            }
        } catch (e) {
            console.log(`⚠️  No se pudo encontrar Chromium con which`);
        }
        
        // Intentar whereis como alternativa
        if (!executablePath) {
            try {
                const whereisResult = execSync('whereis -b chromium chromium-browser 2>/dev/null', { encoding: 'utf8', timeout: 5000 });
                const paths = whereisResult.split(':')[1]?.trim().split(/\s+/).filter(p => p);
                for (const p of paths || []) {
                    if (checkExecutable(p)) {
                        executablePath = p;
                        console.log(`✅ Chromium encontrado con whereis: ${p}`);
                        break;
                    }
                }
            } catch (e) {
                console.log(`⚠️  No se pudo encontrar Chromium con whereis`);
            }
        }
    }
    
    // 4. Si aún no se encuentra, buscar el Chromium de Puppeteer como fallback
    if (!executablePath) {
        console.log(`⚠️  Chromium del sistema no encontrado. Buscando Chromium de Puppeteer...`);
        const puppeteerChromiumPaths = [
            // Rutas modernas de Puppeteer (nuevas versiones)
            path.join(__dirname, 'node_modules', '.cache', 'puppeteer'),
            path.join(process.cwd(), 'node_modules', '.cache', 'puppeteer'),
            path.join(__dirname, 'node_modules', 'puppeteer', '.cache', 'puppeteer'),
            path.join(process.cwd(), 'node_modules', 'puppeteer', '.cache', 'puppeteer'),
            // Rutas antiguas de Puppeteer (compatibilidad)
            path.join(__dirname, 'node_modules', 'puppeteer', '.local-chromium'),
            path.join(__dirname, 'node_modules', 'puppeteer-core', '.local-chromium'),
            path.join(process.cwd(), 'node_modules', 'puppeteer', '.local-chromium'),
            path.join(process.cwd(), 'node_modules', 'puppeteer-core', '.local-chromium')
        ];
        
        for (const basePath of puppeteerChromiumPaths) {
            if (fs.existsSync(basePath)) {
                // Buscar el ejecutable de Chromium dentro de la estructura de Puppeteer
                try {
                    const chromiumDirs = fs.readdirSync(basePath);
                    for (const dir of chromiumDirs) {
                        // Estructura moderna: chrome-*/chrome-linux64/chrome
                        const modernPath = path.join(basePath, dir, 'chrome-linux64', 'chrome');
                        if (checkExecutable(modernPath)) {
                            executablePath = modernPath;
                            console.log(`✅ Chromium de Puppeteer encontrado (moderno): ${modernPath}`);
                            break;
                        }
                        // Estructura antigua: chrome-*/chrome-linux/chrome
                        const oldPath = path.join(basePath, dir, 'chrome-linux', 'chrome');
                        if (checkExecutable(oldPath)) {
                            executablePath = oldPath;
                            console.log(`✅ Chromium de Puppeteer encontrado (antiguo): ${oldPath}`);
                            break;
                        }
                    }
                    if (executablePath) break;
                } catch (e) {
                    // Continuar buscando
                }
            }
        }
    }
}

// Si no se encuentra ningún Chromium, permitir que Puppeteer lo descargue automáticamente
if (!executablePath) {
    console.warn(`⚠️  ADVERTENCIA: No se encontró Chromium del sistema ni de Puppeteer.`);
    console.warn(`   Puppeteer intentará descargar Chromium automáticamente.`);
    console.warn(`   Esto puede tomar tiempo y requiere conexión a internet.`);
    // NO hacer process.exit(1) - permitir que Puppeteer descargue su propio Chromium
    // Pero establecer PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false para permitir la descarga
    process.env.PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = 'false';
} else {
    // Asegurar que Puppeteer use el Chromium encontrado
    process.env.PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = 'true';
    process.env.PUPPETEER_EXECUTABLE_PATH = executablePath;
}

// Establecer executablePath en la configuración ANTES de crear el cliente
if (executablePath) {
    puppeteerConfig.executablePath = executablePath;
    console.log(`📦 Configuración de Puppeteer:`);
    console.log(`   executablePath: ${puppeteerConfig.executablePath}`);
} else {
    console.log(`📦 Configuración de Puppeteer:`);
    console.log(`   executablePath: (Puppeteer descargará Chromium automáticamente)`);
}
console.log(`   PUPPETEER_SKIP_CHROMIUM_DOWNLOAD: ${process.env.PUPPETEER_SKIP_CHROMIUM_DOWNLOAD || 'no configurado'}`);

// Nota: ensureChromiumLibs() eliminada - ya no es necesaria con Chromium del sistema

const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: sessionDataPath
    }),
    puppeteer: puppeteerConfig
});

// ===== EVENTOS DE WHATSAPP =====

// Evento: Código QR generado
client.on('qr', (qr) => {
    console.log('\n📱 Escanea el código QR con WhatsApp:');
    console.log('WhatsApp > Dispositivos vinculados > Vincular dispositivo\n');
    qrcode.generate(qr, { small: true });
    qrCodeData = qr;
    io.emit('qr', qr);
});

// Evento: Cliente autenticado
client.on('authenticated', () => {
    console.log('✅ WhatsApp autenticado correctamente');
    io.emit('authenticated');
});

// Evento: Sesión guardada
client.on('auth_failure', (msg) => {
    console.error('❌ Error de autenticación:', msg);
    io.emit('auth_failure', msg);
});

// Evento: Cliente listo
client.on('ready', () => {
    console.log('🚀 WhatsApp conectado y listo!');
    console.log('🌸 Futura Flor está lista para responder mensajes');
    clientReady = true;
    qrCodeData = null;
    io.emit('ready');
});

// Evento: Cliente desconectado - con reconexión automática
client.on('disconnected', async (reason) => {
    console.log('⚠️ WhatsApp desconectado:', reason);
    clientReady = false;
    io.emit('disconnected', reason);
    
    // Intentar reconexión automática después de 10 segundos
    console.log('🔄 Intentando reconexión automática en 10 segundos...');
    setTimeout(async () => {
        try {
            console.log('🔄 Reconectando WhatsApp...');
            await client.initialize();
        } catch (error) {
            console.error('❌ Error al reconectar:', error);
            // Reintentar en 30 segundos si falla
            setTimeout(() => {
                console.log('🔄 Reintentando reconexión...');
                client.initialize().catch(e => console.error('❌ Error:', e));
            }, 30000);
        }
    }, 10000);
});

// Evento: Mensaje recibido
client.on('message', async (message) => {
    try {
        // Ignorar mensajes propios y de grupos
        if (message.fromMe || message.from.includes('@g.us')) {
            return;
        }

        const startTime = Date.now();
        console.log(`\n📨 Mensaje recibido de ${message.from}:`);
        console.log(`   "${message.body}"`);

        // Actualizar estadísticas
        stats.totalMessages++;
        stats.uniqueContacts.add(message.from);

        // Guardar mensaje en archivo local
        if (CONFIG.SAVE_MESSAGES) {
            saveMessage(message);
        }

        // Guardar mensaje en Supabase
        await saveMessageToSupabase(message.from, message.body, false, message.type);

        // Obtener nombre del contacto e intentar crear/actualizar usuario
        let contactName = null;
        try {
            const contact = await message.getContact();
            contactName = contact.pushname || contact.name || null;
        } catch (e) {
            // Ignorar error al obtener contacto
        }
        
        // Crear o actualizar usuario desde WhatsApp
        await saveOrUpdateUser(message.from, contactName);

        // Emitir a clientes conectados (CRM/Dashboard)
        io.emit('message', {
            from: message.from,
            body: message.body,
            timestamp: message.timestamp,
            type: message.type,
            contactName: contactName,
            instance: CONFIG.INSTANCE_NUMBER
        });

        // Verificar si es un agente (no responder automáticamente)
        if (CONFIG.AGENT_NUMBERS.includes(message.from)) {
            console.log('   ℹ️ Mensaje de agente, no se responde automáticamente');
            return;
        }

        // Responder automáticamente con Futura Flor
        if (CONFIG.AUTO_REPLY && CONFIG.FLOR_ENABLED) {
            // Simular tiempo de escritura mientras genera respuesta
            await client.sendPresenceAvailable();
            await message.getChat().then(chat => chat.sendStateTyping());
            
            // Detectar intent
            const intent = detectIntent(message.body);
            
            // Obtener respuesta inteligente (Gemini IA o predefinida)
            const response = await getSmartResponse(message.body);
            const usedAI = CONFIG.USE_GEMINI_AI && CONFIG.GEMINI_API_KEY;
            
            await message.reply(response);
            
            // Calcular tiempo de respuesta
            const responseTime = Date.now() - startTime;
            
            // Guardar respuesta en Supabase
            await saveMessageToSupabase(message.from, response, true, 'text');
            
            // Guardar interacción para aprendizaje de Flor
            await saveInteraction(
                message.from,
                message.body,
                response,
                intent,
                usedAI,
                responseTime
            );
            
            stats.autoReplies++; // Incrementar respuestas automáticas
            console.log(`   🌸 Futura Flor respondió: "${response.substring(0, 50)}..." (${responseTime}ms)`);
        }

    } catch (error) {
        console.error('❌ Error procesando mensaje:', error);
    }
});

// ===== FUNCIONES DE FLOR =====

function generateFlorResponse(userMessage) {
    const msg = userMessage.toLowerCase().trim();
    
    // Detectar saludos
    if (matchAny(msg, ['hola', 'buenos dias', 'buenas tardes', 'buenas noches', 'hey', 'hi'])) {
        return FLOR_KNOWLEDGE.agent.greeting;
    }
    
    // Detectar despedidas
    if (matchAny(msg, ['gracias', 'chau', 'adios', 'bye', 'hasta luego', 'nos vemos'])) {
        return FLOR_KNOWLEDGE.agent.farewell;
    }
    
    // Detectar consulta de hoteles
    if (matchAny(msg, ['hotel', 'hoteles', 'alojamiento', 'hospedaje', 'donde', 'trabajan', 'tienen'])) {
        return FLOR_KNOWLEDGE.responses.hotels;
    }
    
    // Detectar consulta de precios
    if (matchAny(msg, ['precio', 'precios', 'costo', 'cuanto', 'tarifa', 'valor', 'cotiza'])) {
        return FLOR_KNOWLEDGE.responses.prices;
    }
    
    // Detectar intención de reserva
    if (matchAny(msg, ['reserva', 'reservar', 'quiero', 'necesito', 'disponibilidad', 'fecha'])) {
        return FLOR_KNOWLEDGE.responses.reservation;
    }
    
    // Detectar consulta de contacto
    if (matchAny(msg, ['contacto', 'telefono', 'email', 'correo', 'llamar', 'web', 'pagina'])) {
        return FLOR_KNOWLEDGE.responses.contact;
    }
    
    // Detectar hotel específico usando base de conocimiento cargada
    for (const hotel of FLOR_HOTELS_LIST) {
        const hotelName = hotel.name?.toLowerCase() || '';
        const hotelKeywords = [
            hotelName,
            ...(hotel.name?.split(' ') || []).map(w => w.toLowerCase()),
            ...(hotel.description?.split(' ') || []).slice(0, 5).map(w => w.toLowerCase())
        ];
        
        if (matchAny(msg, hotelKeywords)) {
            // Buscar conocimiento detallado del hotel
            const hotelKnowledge = FLOR_HOTELS_KNOWLEDGE[hotel.id] || FLOR_HOTELS_KNOWLEDGE[String(hotel.id)];
            
            if (hotelKnowledge && hotelKnowledge.description) {
                return `🏨 *${hotel.name}*\n\n${hotelKnowledge.description}\n\n📍 ${hotel.location || hotel.address || 'Patagonia, Chile'}\n\n¿Te gustaría recibir una cotización?`;
            } else if (hotel.description) {
                return `🏨 *${hotel.name}*\n\n${hotel.description.substring(0, 200)}${hotel.description.length > 200 ? '...' : ''}\n\n📍 ${hotel.location || hotel.address || 'Patagonia, Chile'}\n\n¿Te gustaría recibir una cotización?`;
            } else {
                return `🏨 *${hotel.name}*\n\n📍 ${hotel.location || hotel.address || 'Patagonia, Chile'}\n\n¿Te gustaría recibir una cotización?`;
            }
        }
    }
    
    // Fallback a hoteles conocidos (si no se cargaron desde Supabase)
    if (matchAny(msg, ['puyehue', 'termas'])) {
        return "🏨 *Hotel Terma de Puyehue*\n\n📍 Ubicación: Ruta 215 Km 76, Puyehue, Chile\n🌡️ Especialidad: Spa termal con aguas termales naturales\n✨ Destacado: Piscinas termales, tratamientos de spa, restaurant gourmet\n\n¿Te gustaría recibir una cotización?";
    }
    
    if (matchAny(msg, ['huilo', 'huilo-huilo', 'nothofagus'])) {
        return "🏨 *Hotel Huilo-Huilo*\n\n📍 Ubicación: Reserva Biológica Huilo Huilo, Chile\n🌲 Especialidad: Ecoturismo en la selva valdiviana\n✨ Destacado: Arquitectura única, bosques milenarios, volcanes\n\n¿Te gustaría recibir una cotización?";
    }
    
    if (matchAny(msg, ['corralco'])) {
        return "🏨 *Hotel Corralco*\n\n📍 Ubicación: Volcán Lonquimay, Chile\n⛷️ Especialidad: Ski y actividades de montaña\n✨ Destacado: Centro de ski, trekking, termas naturales\n\n¿Te gustaría recibir una cotización?";
    }
    
    // Respuesta por defecto
    return FLOR_KNOWLEDGE.responses.unknown;
}

function matchAny(text, keywords) {
    return keywords.some(keyword => text.includes(keyword));
}

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ===== INTEGRACIÓN CON GEMINI IA =====

async function generateGeminiResponse(userMessage, conversationHistory = []) {
    if (!CONFIG.GEMINI_API_KEY) {
        console.log('⚠️ API Key de Gemini no configurada, usando respuestas predefinidas');
        return null;
    }

    // Construir información de hoteles desde la base de conocimiento cargada
    let hotelsInfo = '';
    if (FLOR_HOTELS_LIST.length > 0) {
        hotelsInfo = FLOR_HOTELS_LIST.map((hotel, idx) => {
            const hotelKnowledge = FLOR_HOTELS_KNOWLEDGE[hotel.id] || FLOR_HOTELS_KNOWLEDGE[String(hotel.id)];
            let hotelDesc = hotel.description || '';
            if (hotelKnowledge && hotelKnowledge.description) {
                hotelDesc = hotelKnowledge.description;
            }
            return `${idx + 1}. ${hotel.name}${hotel.location ? ' - ' + hotel.location : ''}${hotelDesc ? '\n   ' + hotelDesc.substring(0, 150) : ''}`;
        }).join('\n\n');
    } else {
        hotelsInfo = `1. Hotel Terma de Puyehue - Spa termal con aguas termales naturales
2. Hotel Huilo-Huilo - Ecoturismo en la selva valdiviana
3. Hotel Corralco - Ski y actividades de montaña
4. Hotel Futangue - Lagos y montañas`;
    }

    const systemPrompt = `Eres ${FLOR_KNOWLEDGE.agent.name}, la asistente virtual de Checkin24hs, una agencia de viajes especializada en hoteles de lujo en la Patagonia chilena.

INFORMACIÓN DE LA EMPRESA:
- Nombre: Checkin24hs
- Email: reservas@checkin24hs.com
- Web: www.checkin24hs.com
- Especialidad: Hoteles de lujo en Patagonia

HOTELES QUE MANEJAMOS:
${hotelsInfo}

BASE DE CONOCIMIENTO DETALLADA:
${Object.keys(FLOR_HOTELS_KNOWLEDGE).length > 0 ? 
    Object.entries(FLOR_HOTELS_KNOWLEDGE).map(([hotelId, knowledge]) => {
        const hotel = FLOR_HOTELS_LIST.find(h => String(h.id) === String(hotelId));
        const hotelName = hotel?.name || `Hotel ${hotelId}`;
        let info = `\n${hotelName}:`;
        if (knowledge.description) info += `\n- Descripción: ${knowledge.description}`;
        if (knowledge.address) info += `\n- Dirección: ${knowledge.address}`;
        if (knowledge.servicesDetails) {
            const services = typeof knowledge.servicesDetails === 'string' ? JSON.parse(knowledge.servicesDetails) : knowledge.servicesDetails;
            if (services && Object.keys(services).length > 0) {
                info += `\n- Servicios: ${Object.keys(services).join(', ')}`;
            }
        }
        if (knowledge.policies) {
            const policies = typeof knowledge.policies === 'string' ? JSON.parse(knowledge.policies) : knowledge.policies;
            if (policies && Object.keys(policies).length > 0) {
                info += `\n- Políticas: ${Object.keys(policies).join(', ')}`;
            }
        }
        return info;
    }).join('\n') : 'Usa la información básica de los hoteles listados arriba.'}

TU PERSONALIDAD:
- Amable y profesional
- Respuestas concisas pero informativas
- Usa emojis moderadamente
- Si te piden una cotización, solicita: fechas, cantidad de personas y hotel preferido
- Si quieren reservar, indica que un agente humano los contactará
- Usa la información detallada de la base de conocimiento cuando respondas sobre hoteles específicos

IMPORTANTE:
- Responde en español
- Máximo 300 caracteres por respuesta para WhatsApp
- No inventes precios, solo di que varían según temporada
- Si no sabes algo, ofrece conectar con un agente humano
- Prioriza usar la información de la BASE DE CONOCIMIENTO DETALLADA cuando respondas sobre hoteles`;

    try {
        const modelName = CONFIG.GEMINI_MODEL || 'gemini-1.5-flash';
        const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${CONFIG.GEMINI_API_KEY}`;
        console.log(`🤖 Llamando a Gemini: ${modelName}`);
        
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                contents: [
                    {
                        role: 'user',
                        parts: [{ text: systemPrompt + '\n\nMensaje del cliente: ' + userMessage }]
                    }
                ],
                generationConfig: {
                    temperature: 0.7,
                    maxOutputTokens: 500,
                }
            })
        });

        if (!response.ok) {
            const errorBody = await response.text();
            console.error('❌ Error de Gemini:', response.status, response.statusText);
            console.error('❌ Detalles:', errorBody);
            return null;
        }

        const data = await response.json();
        
        if (data.candidates && data.candidates[0] && data.candidates[0].content) {
            const aiResponse = data.candidates[0].content.parts[0].text;
            console.log('🤖 Respuesta de Gemini IA');
            return aiResponse;
        }
        
        return null;
    } catch (error) {
        console.error('❌ Error llamando a Gemini:', error.message);
        return null;
    }
}

// Función principal de respuesta (usa Gemini si está configurado)
async function getSmartResponse(userMessage) {
    // Intentar con Gemini IA primero
    if (CONFIG.USE_GEMINI_AI && CONFIG.GEMINI_API_KEY) {
        const aiResponse = await generateGeminiResponse(userMessage);
        if (aiResponse) {
            return aiResponse;
        }
    }
    
    // Fallback a respuestas predefinidas
    return generateFlorResponse(userMessage);
}

// ===== GUARDAR MENSAJES =====

function saveMessage(message) {
    const logDir = path.join(__dirname, 'logs');
    if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
    }
    
    const today = new Date().toISOString().split('T')[0];
    const logFile = path.join(logDir, `messages-${today}.json`);
    
    let messages = [];
    if (fs.existsSync(logFile)) {
        messages = JSON.parse(fs.readFileSync(logFile, 'utf8'));
    }
    
    messages.push({
        from: message.from,
        body: message.body,
        timestamp: new Date().toISOString(),
        type: message.type
    });
    
    fs.writeFileSync(logFile, JSON.stringify(messages, null, 2));
}

// ===== FUNCIONES DE SUPABASE =====

// Guardar o actualizar chat en Supabase
async function saveOrUpdateChat(phone, message, isFromMe = false) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return null;
    
    try {
        const cleanPhone = phone.replace('@c.us', '');
        
        // Buscar chat existente
        const { data: existingChat } = await supabase
            .from('whatsapp_chats')
            .select('*')
            .eq('phone', cleanPhone)
            .eq('whatsapp_instance', CONFIG.INSTANCE_NUMBER)
            .single();
        
        if (existingChat) {
            // Actualizar chat existente
            const { data, error } = await supabase
                .from('whatsapp_chats')
                .update({
                    last_message: message.substring(0, 500),
                    last_message_time: new Date().toISOString(),
                    unread_count: isFromMe ? 0 : existingChat.unread_count + 1,
                    updated_at: new Date().toISOString()
                })
                .eq('id', existingChat.id)
                .select()
                .single();
            
            if (error) throw error;
            return data;
        } else {
            // Crear nuevo chat
            const { data, error } = await supabase
                .from('whatsapp_chats')
                .insert([{
                    phone: cleanPhone,
                    name: null, // Se actualizará cuando obtengamos el nombre del contacto
                    last_message: message.substring(0, 500),
                    last_message_time: new Date().toISOString(),
                    unread_count: isFromMe ? 0 : 1,
                    status: 'active',
                    whatsapp_instance: CONFIG.INSTANCE_NUMBER
                }])
                .select()
                .single();
            
            if (error) throw error;
            console.log(`📱 Nuevo chat creado para ${cleanPhone}`);
            return data;
        }
    } catch (error) {
        console.error('❌ Error guardando chat en Supabase:', error.message);
        return null;
    }
}

// Guardar mensaje en Supabase
async function saveMessageToSupabase(phone, message, isFromMe = false, messageType = 'text') {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return null;
    
    try {
        const cleanPhone = phone.replace('@c.us', '');
        
        // Obtener o crear chat
        const chat = await saveOrUpdateChat(phone, message, isFromMe);
        
        // Guardar mensaje
        const { data, error } = await supabase
            .from('whatsapp_messages')
            .insert([{
                chat_id: chat?.id || null,
                phone: cleanPhone,
                message: message,
                message_type: messageType,
                is_from_me: isFromMe,
                is_read: isFromMe,
                whatsapp_instance: CONFIG.INSTANCE_NUMBER
            }])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    } catch (error) {
        console.error('❌ Error guardando mensaje en Supabase:', error.message);
        return null;
    }
}

// Guardar interacción de Flor para aprendizaje
async function saveInteraction(phone, userMessage, botResponse, intent, usedAI = false, responseTimeMs = 0) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return null;
    
    try {
        const cleanPhone = phone.replace('@c.us', '');
        
        const { data, error } = await supabase
            .from('flor_interactions')
            .insert([{
                phone: cleanPhone,
                user_message: userMessage,
                bot_response: botResponse,
                intent: intent,
                success: true,
                used_ai: usedAI,
                ai_model: usedAI ? CONFIG.GEMINI_MODEL : null,
                response_time_ms: responseTimeMs,
                whatsapp_instance: CONFIG.INSTANCE_NUMBER
            }])
            .select()
            .single();
        
        if (error) throw error;
        console.log(`📝 Interacción guardada: ${intent || 'general'}`);
        return data;
    } catch (error) {
        console.error('❌ Error guardando interacción:', error.message);
        return null;
    }
}

// Crear o actualizar usuario desde contacto de WhatsApp
async function saveOrUpdateUser(phone, name = null) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return null;
    
    try {
        const cleanPhone = phone.replace('@c.us', '');
        const formattedPhone = '+' + cleanPhone; // Formato internacional
        
        // Buscar usuario existente por teléfono
        const { data: existingUser } = await supabase
            .from('users')
            .select('*')
            .eq('phone', formattedPhone)
            .single();
        
        if (existingUser) {
            // Actualizar última actividad
            const updates = {
                last_activity: new Date().toISOString(),
                updated_at: new Date().toISOString()
            };
            
            // Actualizar nombre si tenemos uno nuevo y el existente está vacío
            if (name && !existingUser.name) {
                updates.name = name;
            }
            
            const { data, error } = await supabase
                .from('users')
                .update(updates)
                .eq('id', existingUser.id)
                .select()
                .single();
            
            if (error) throw error;
            return data;
        } else {
            // Crear nuevo usuario
            const { data, error } = await supabase
                .from('users')
                .insert([{
                    name: name || 'Usuario WhatsApp',
                    phone: formattedPhone,
                    email: null,
                    status: 'active',
                    is_active: true,
                    last_activity: new Date().toISOString(),
                    rewards_points: 0,
                    tipo_cuenta: 'cliente_whatsapp'
                }])
                .select()
                .single();
            
            if (error) throw error;
            console.log(`👤 Nuevo usuario creado desde WhatsApp: ${formattedPhone}`);
            
            // Vincular usuario al chat
            await linkUserToChat(cleanPhone, data.id);
            
            return data;
        }
    } catch (error) {
        // Si es error de duplicado, ignorar
        if (error.code === '23505') {
            console.log(`ℹ️ Usuario ya existe: ${phone}`);
            return null;
        }
        console.error('❌ Error guardando usuario:', error.message);
        return null;
    }
}

// Vincular usuario a chat
async function linkUserToChat(phone, userId) {
    if (!supabase) return;
    
    try {
        await supabase
            .from('whatsapp_chats')
            .update({ user_id: userId })
            .eq('phone', phone)
            .eq('whatsapp_instance', CONFIG.INSTANCE_NUMBER);
    } catch (error) {
        console.error('❌ Error vinculando usuario a chat:', error.message);
    }
}

// Detectar intent del mensaje
function detectIntent(message) {
    const msg = message.toLowerCase().trim();
    
    if (matchAny(msg, ['hola', 'buenos dias', 'buenas tardes', 'buenas noches', 'hey', 'hi'])) {
        return 'saludo';
    }
    if (matchAny(msg, ['gracias', 'chau', 'adios', 'bye', 'hasta luego'])) {
        return 'despedida';
    }
    if (matchAny(msg, ['hotel', 'hoteles', 'alojamiento', 'hospedaje'])) {
        return 'consulta_hotel';
    }
    if (matchAny(msg, ['precio', 'precios', 'costo', 'cuanto', 'tarifa', 'cotiza'])) {
        return 'consulta_precio';
    }
    if (matchAny(msg, ['reserva', 'reservar', 'disponibilidad', 'fecha'])) {
        return 'reserva';
    }
    if (matchAny(msg, ['puyehue', 'huilo', 'corralco', 'futangue'])) {
        return 'consulta_hotel_especifico';
    }
    if (matchAny(msg, ['contacto', 'telefono', 'email', 'web'])) {
        return 'contacto';
    }
    
    return 'consulta_general';
}

// ===== ESTADÍSTICAS =====
let stats = {
    totalMessages: 0,
    autoReplies: 0,
    uniqueContacts: new Set(),
    startTime: Date.now()
};

// Cargar estadísticas guardadas
const statsFile = path.join(__dirname, 'stats.json');
if (fs.existsSync(statsFile)) {
    try {
        const savedStats = JSON.parse(fs.readFileSync(statsFile, 'utf8'));
        stats.totalMessages = savedStats.totalMessages || 0;
        stats.autoReplies = savedStats.autoReplies || 0;
        stats.uniqueContacts = new Set(savedStats.uniqueContacts || []);
    } catch (e) {
        console.log('⚠️ No se pudieron cargar estadísticas');
    }
}

// Guardar estadísticas periódicamente
setInterval(() => {
    const statsData = {
        totalMessages: stats.totalMessages,
        autoReplies: stats.autoReplies,
        uniqueContacts: Array.from(stats.uniqueContacts)
    };
    fs.writeFileSync(statsFile, JSON.stringify(statsData, null, 2));
}, 60000); // Cada minuto

// ===== API ENDPOINTS =====

// Estado del servidor (compatible con CRM)
// Rutas principales Y alias para compatibilidad
app.get(['/api/status', '/status'], async (req, res) => {
    let phoneNumber = '-';
    let userName = '-';
    
    if (clientReady) {
        try {
            const info = await client.info;
            if (info) {
                phoneNumber = info.wid ? info.wid.user : '-';
                userName = info.pushname || '-';
            }
        } catch (e) {
            console.log('No se pudo obtener info del cliente');
        }
    }
    
    res.json({
        connected: clientReady,
        whatsapp: clientReady ? 'connected' : 'disconnected',
        flor: CONFIG.FLOR_ENABLED ? 'active' : 'inactive',
        autoReply: CONFIG.AUTO_REPLY,
        qrCode: qrCodeData ? `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(qrCodeData)}` : null,
        phoneNumber: phoneNumber,
        userName: userName,
        lastActivity: new Date().toLocaleString('es-AR')
    });
});

// Obtener código QR (con alias)
app.get(['/api/qr', '/qr'], (req, res) => {
    if (clientReady) {
        res.json({ status: 'connected', qr: null });
    } else if (qrCodeData) {
        res.json({ 
            status: 'waiting_scan', 
            qr: qrCodeData,
            qrImage: `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(qrCodeData)}`
        });
    } else {
        res.json({ status: 'initializing', qr: null });
    }
});

// Desconectar/Logout de WhatsApp (con alias)
app.post(['/api/logout', '/logout'], async (req, res) => {
    try {
        if (clientReady) {
            await client.logout();
            clientReady = false;
            qrCodeData = null;
            console.log('🔌 WhatsApp desconectado por solicitud del usuario');
            res.json({ success: true, message: 'WhatsApp desconectado' });
        } else {
            res.json({ success: true, message: 'WhatsApp ya estaba desconectado' });
        }
    } catch (error) {
        console.error('Error al desconectar:', error);
        res.status(500).json({ error: error.message });
    }
});

// Estadísticas de WhatsApp
app.get('/api/stats', (req, res) => {
    const uptime = Date.now() - stats.startTime;
    const avgResponseTime = stats.autoReplies > 0 ? Math.round(uptime / stats.autoReplies / 1000) : 0;
    
    res.json({
        totalMessages: stats.totalMessages,
        autoReplies: stats.autoReplies,
        uniqueContacts: stats.uniqueContacts.size,
        avgResponseTime: avgResponseTime > 0 ? `${avgResponseTime}s` : '-',
        uptime: Math.round(uptime / 1000 / 60) + ' min'
    });
});

// Enviar mensaje
app.post('/api/send', async (req, res) => {
    try {
        const { number, message } = req.body;
        
        if (!clientReady) {
            return res.status(503).json({ error: 'WhatsApp no está conectado' });
        }
        
        // Formatear número (agregar @c.us si no lo tiene)
        let chatId = number;
        if (!chatId.includes('@')) {
            chatId = chatId.replace(/[^0-9]/g, '') + '@c.us';
        }
        
        await client.sendMessage(chatId, message);
        res.json({ success: true, message: 'Mensaje enviado' });
        
    } catch (error) {
        console.error('Error enviando mensaje:', error);
        res.status(500).json({ error: error.message });
    }
});

// Toggle auto-reply
app.post('/api/toggle-auto-reply', (req, res) => {
    CONFIG.AUTO_REPLY = !CONFIG.AUTO_REPLY;
    console.log(`🔄 Auto-reply ${CONFIG.AUTO_REPLY ? 'activado' : 'desactivado'}`);
    res.json({ autoReply: CONFIG.AUTO_REPLY });
});

// Toggle Flor
app.post('/api/toggle-flor', (req, res) => {
    CONFIG.FLOR_ENABLED = !CONFIG.FLOR_ENABLED;
    console.log(`🌸 Futura Flor ${CONFIG.FLOR_ENABLED ? 'activada' : 'desactivada'}`);
    res.json({ florEnabled: CONFIG.FLOR_ENABLED });
});

// Recargar base de conocimiento desde Supabase
app.post('/api/flor/reload-knowledge', async (req, res) => {
    try {
        console.log('🔄 Recargando base de conocimiento de Flor...');
        await loadFlorKnowledgeFromSupabase();
        res.json({ 
            success: true, 
            message: 'Base de conocimiento recargada',
            hotelsLoaded: FLOR_HOTELS_LIST.length,
            knowledgeLoaded: Object.keys(FLOR_HOTELS_KNOWLEDGE).length
        });
    } catch (error) {
        console.error('❌ Error recargando base de conocimiento:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Configurar Gemini IA
app.post('/api/config/gemini', (req, res) => {
    const { apiKey, model, enabled } = req.body;
    
    if (apiKey !== undefined) CONFIG.GEMINI_API_KEY = apiKey;
    if (model !== undefined) CONFIG.GEMINI_MODEL = model;
    if (enabled !== undefined) CONFIG.USE_GEMINI_AI = enabled;
    
    // Guardar configuración
    const configData = {
        GEMINI_API_KEY: CONFIG.GEMINI_API_KEY,
        GEMINI_MODEL: CONFIG.GEMINI_MODEL,
        USE_GEMINI_AI: CONFIG.USE_GEMINI_AI
    };
    fs.writeFileSync(configFile, JSON.stringify(configData, null, 2));
    
    console.log(`🤖 Gemini IA ${CONFIG.USE_GEMINI_AI ? 'activada' : 'desactivada'} - Modelo: ${CONFIG.GEMINI_MODEL}`);
    res.json({ 
        success: true,
        geminiEnabled: CONFIG.USE_GEMINI_AI,
        model: CONFIG.GEMINI_MODEL,
        hasApiKey: !!CONFIG.GEMINI_API_KEY
    });
});

// Obtener configuración actual
app.get('/api/config', (req, res) => {
    res.json({
        autoReply: CONFIG.AUTO_REPLY,
        florEnabled: CONFIG.FLOR_ENABLED,
        geminiEnabled: CONFIG.USE_GEMINI_AI,
        geminiModel: CONFIG.GEMINI_MODEL,
        hasGeminiKey: !!CONFIG.GEMINI_API_KEY,
        businessHours: CONFIG.BUSINESS_HOURS
    });
});

// Actualizar configuración desde CRM
app.post('/api/config', (req, res) => {
    const { autoReply, businessHoursOnly, outOfHoursMessage } = req.body;
    
    if (autoReply !== undefined) {
        CONFIG.AUTO_REPLY = autoReply;
    }
    if (businessHoursOnly !== undefined) {
        CONFIG.BUSINESS_HOURS.enabled = businessHoursOnly;
    }
    if (outOfHoursMessage !== undefined) {
        CONFIG.OUT_OF_HOURS_MESSAGE = outOfHoursMessage;
    }
    
    console.log('📱 Configuración actualizada desde CRM:', { autoReply, businessHoursOnly });
    
    res.json({
        success: true,
        autoReply: CONFIG.AUTO_REPLY,
        businessHoursEnabled: CONFIG.BUSINESS_HOURS.enabled
    });
});

// Obtener conversaciones del día
app.get('/api/messages/today', (req, res) => {
    const today = new Date().toISOString().split('T')[0];
    const logFile = path.join(__dirname, 'logs', `messages-${today}.json`);
    
    if (fs.existsSync(logFile)) {
        const messages = JSON.parse(fs.readFileSync(logFile, 'utf8'));
        res.json(messages);
    } else {
        res.json([]);
    }
});

// ===== ENDPOINTS DE SUPABASE =====

// Obtener chats desde Supabase
app.get('/api/chats', async (req, res) => {
    if (!supabase) {
        return res.status(503).json({ error: 'Supabase no está configurado' });
    }
    
    try {
        const { data, error } = await supabase
            .from('whatsapp_chats')
            .select('*, users(name, email)')
            .eq('whatsapp_instance', CONFIG.INSTANCE_NUMBER)
            .order('last_message_time', { ascending: false })
            .limit(50);
        
        if (error) throw error;
        res.json(data || []);
    } catch (error) {
        console.error('Error obteniendo chats:', error);
        res.status(500).json({ error: error.message });
    }
});

// Obtener mensajes de un chat específico
app.get('/api/chats/:chatId/messages', async (req, res) => {
    if (!supabase) {
        return res.status(503).json({ error: 'Supabase no está configurado' });
    }
    
    try {
        const { chatId } = req.params;
        const limit = parseInt(req.query.limit) || 100;
        
        const { data, error } = await supabase
            .from('whatsapp_messages')
            .select('*')
            .eq('chat_id', chatId)
            .order('created_at', { ascending: true })
            .limit(limit);
        
        if (error) throw error;
        
        // Marcar como leídos
        await supabase
            .from('whatsapp_messages')
            .update({ is_read: true })
            .eq('chat_id', chatId)
            .eq('is_from_me', false);
        
        // Resetear contador de no leídos
        await supabase
            .from('whatsapp_chats')
            .update({ unread_count: 0 })
            .eq('id', chatId);
        
        res.json(data || []);
    } catch (error) {
        console.error('Error obteniendo mensajes:', error);
        res.status(500).json({ error: error.message });
    }
});

// Obtener interacciones de Flor
app.get('/api/interactions', async (req, res) => {
    if (!supabase) {
        return res.status(503).json({ error: 'Supabase no está configurado' });
    }
    
    try {
        const limit = parseInt(req.query.limit) || 100;
        const { data, error } = await supabase
            .from('flor_interactions')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(limit);
        
        if (error) throw error;
        res.json(data || []);
    } catch (error) {
        console.error('Error obteniendo interacciones:', error);
        res.status(500).json({ error: error.message });
    }
});

// Obtener estadísticas de Flor
app.get('/api/flor/stats', async (req, res) => {
    if (!supabase) {
        return res.status(503).json({ error: 'Supabase no está configurado' });
    }
    
    try {
        // Estadísticas generales
        const { data: statsData } = await supabase
            .from('flor_interactions')
            .select('id, success, used_ai, response_time_ms')
            .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()); // Últimos 30 días
        
        // Intents más comunes
        const { data: intentsData } = await supabase
            .from('flor_interactions')
            .select('intent')
            .not('intent', 'is', null)
            .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());
        
        // Contar intents
        const intentCounts = {};
        intentsData?.forEach(item => {
            intentCounts[item.intent] = (intentCounts[item.intent] || 0) + 1;
        });
        
        const total = statsData?.length || 0;
        const successful = statsData?.filter(s => s.success).length || 0;
        const withAI = statsData?.filter(s => s.used_ai).length || 0;
        const avgResponseTime = total > 0 
            ? Math.round(statsData.reduce((sum, s) => sum + (s.response_time_ms || 0), 0) / total)
            : 0;
        
        res.json({
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
        });
    } catch (error) {
        console.error('Error obteniendo estadísticas:', error);
        res.status(500).json({ error: error.message });
    }
});

// Página de estado/QR
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>WhatsApp Futura Flor - Checkin24hs</title>
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
        .status.waiting { background: #fff3cd; color: #856404; }
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
        .instructions ol { margin-left: 20px; color: #666; }
        .instructions li { margin: 8px 0; }
        .flor-badge {
            display: inline-block;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌸 Futura Flor WhatsApp</h1>
        <p class="subtitle">Checkin24hs - Asistente Virtual</p>
        
        <div id="status" class="status waiting">
            Inicializando...
        </div>
        
        <div id="qr-container"></div>
        
        <div class="instructions" id="instructions" style="display: none;">
            <h3>📱 Para conectar:</h3>
            <ol>
                <li>Abre WhatsApp en tu teléfono</li>
                <li>Ve a <strong>Configuración > Dispositivos vinculados</strong></li>
                <li>Toca <strong>Vincular un dispositivo</strong></li>
                <li>Escanea el código QR</li>
            </ol>
        </div>
        
        <div class="flor-badge">🌸 Futura Flor activa</div>
    </div>
    
    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        const statusEl = document.getElementById('status');
        const qrContainer = document.getElementById('qr-container');
        const instructions = document.getElementById('instructions');
        
        socket.on('qr', (qr) => {
            console.log('📱 QR recibido');
            statusEl.className = 'status waiting';
            statusEl.textContent = '📱 Escanea el código QR';
            instructions.style.display = 'block';
            
            // Usar API externa para generar imagen del QR (más confiable)
            const qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=' + encodeURIComponent(qr);
            qrContainer.innerHTML = '<img src="' + qrImageUrl + '" alt="Código QR" style="border-radius: 10px; border: 4px solid #25D366;">';
        });
        
        socket.on('authenticated', () => {
            statusEl.className = 'status connected';
            statusEl.textContent = '✅ Autenticado';
        });
        
        socket.on('ready', () => {
            statusEl.className = 'status connected';
            statusEl.textContent = '✅ WhatsApp conectado - Futura Flor activa';
            qrContainer.innerHTML = '<p style="font-size: 60px;">✅</p>';
            instructions.style.display = 'none';
        });
        
        socket.on('disconnected', () => {
            statusEl.className = 'status disconnected';
            statusEl.textContent = '❌ Desconectado';
        });
        
        // Verificar estado inicial
        fetch('/api/status')
            .then(r => r.json())
            .then(data => {
                if (data.whatsapp === 'connected') {
                    statusEl.className = 'status connected';
                    statusEl.textContent = '✅ WhatsApp conectado - Futura Flor activa';
                    qrContainer.innerHTML = '<p style="font-size: 60px;">✅</p>';
                }
            });
    </script>
</body>
</html>
    `);
});

// ===== INICIAR SERVIDOR =====

server.listen(CONFIG.PORT, '0.0.0.0', async () => {
    try {
        console.log('\n========================================');
        console.log('🌸 Servidor WhatsApp Futura Flor - Checkin24hs');
        console.log('========================================');
        console.log(`📡 Servidor corriendo en puerto ${CONFIG.PORT}`);
        console.log(`🌐 Panel: http://localhost:${CONFIG.PORT}`);
        console.log('========================================\n');
        
        // Cargar base de conocimiento desde Supabase al iniciar
        try {
            await loadFlorKnowledgeFromSupabase();
        } catch (error) {
            console.error('⚠️ Error cargando base de conocimiento:', error.message);
            console.log('📚 Continuando con base de conocimiento básica...');
        }
        
        console.log('⏳ Inicializando WhatsApp...\n');
        
        // Health check cada 5 minutos para mantener la sesión activa
        setInterval(() => {
            if (clientReady) {
                console.log('💓 Heartbeat: WhatsApp conectado ✅');
            } else {
                console.log('💔 Heartbeat: WhatsApp desconectado ❌');
            }
        }, 5 * 60 * 1000); // 5 minutos
    } catch (error) {
        console.error('❌ Error en callback de inicio del servidor:', error);
        console.error(error.stack);
    }
});

// Iniciar cliente de WhatsApp
// Nota: Usamos Chromium del sistema, no necesitamos esperar descargas
client.initialize();

// Manejo de cierre
process.on('SIGINT', async () => {
    console.log('\n🛑 Cerrando servidor...');
    try {
        if (client) {
            await client.destroy();
        }
    } catch (error) {
        console.error('⚠️ Error al destruir cliente:', error.message);
    }
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n🛑 Cerrando servidor (SIGTERM)...');
    try {
        if (client) {
            await client.destroy();
        }
    } catch (error) {
        console.error('⚠️ Error al destruir cliente:', error.message);
    }
    process.exit(0);
});


