/**
 * 🌸 Servidor de WhatsApp para Flor - Checkin24hs
 * 
 * Este servidor conecta WhatsApp con el chatbot Flor
 * Permite usar WhatsApp en el teléfono mientras Flor responde automáticamente
 */

const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const path = require('path');

// ===== CONFIGURACIÓN =====
const CONFIG = {
    PORT: process.env.PORT || 3001,
    AUTO_REPLY: true,                    // Activar respuestas automáticas de Flor
    FLOR_ENABLED: true,                  // Habilitar Flor
    SAVE_MESSAGES: true,                 // Guardar mensajes en archivo
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
    }
};

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

// ===== BASE DE CONOCIMIENTO DE FUTURA FLOR (simplificada) =====
const FLOR_KNOWLEDGE = {
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

// ===== INICIALIZACIÓN =====
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Estado del cliente
let clientReady = false;
let qrCodeData = null;

// Crear cliente de WhatsApp con autenticación local (persiste la sesión)
const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: '.wwebjs_auth'
    }),
    puppeteer: {
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--single-process',
            '--disable-gpu'
        ]
    }
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

// Evento: Cliente desconectado
client.on('disconnected', (reason) => {
    console.log('⚠️ WhatsApp desconectado:', reason);
    clientReady = false;
    io.emit('disconnected', reason);
});

// Evento: Mensaje recibido
client.on('message', async (message) => {
    try {
        // Ignorar mensajes propios y de grupos
        if (message.fromMe || message.from.includes('@g.us')) {
            return;
        }

        console.log(`\n📨 Mensaje recibido de ${message.from}:`);
        console.log(`   "${message.body}"`);

        // Actualizar estadísticas
        stats.totalMessages++;
        stats.uniqueContacts.add(message.from);

        // Guardar mensaje
        if (CONFIG.SAVE_MESSAGES) {
            saveMessage(message);
        }

        // Emitir a clientes conectados (CRM/Dashboard)
        io.emit('message', {
            from: message.from,
            body: message.body,
            timestamp: message.timestamp,
            type: message.type
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
            
            // Obtener respuesta inteligente (Gemini IA o predefinida)
            const response = await getSmartResponse(message.body);
            
            await message.reply(response);
            stats.autoReplies++; // Incrementar respuestas automáticas
            console.log(`   🌸 Futura Flor respondió: "${response.substring(0, 50)}..."`);
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
    
    // Detectar hotel específico
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

    const systemPrompt = `Eres Futura Flor, la asistente virtual de Checkin24hs, una agencia de viajes especializada en hoteles de lujo en la Patagonia chilena.

INFORMACIÓN DE LA EMPRESA:
- Nombre: Checkin24hs
- Email: reservas@checkin24hs.com
- Web: www.checkin24hs.com
- Especialidad: Hoteles de lujo en Patagonia

HOTELES QUE MANEJAMOS:
1. Hotel Terma de Puyehue - Spa termal con aguas termales naturales
2. Hotel Huilo-Huilo - Ecoturismo en la selva valdiviana
3. Hotel Corralco - Ski y actividades de montaña
4. Hotel Futangue - Lagos y montañas

TU PERSONALIDAD:
- Amable y profesional
- Respuestas concisas pero informativas
- Usa emojis moderadamente
- Si te piden una cotización, solicita: fechas, cantidad de personas y hotel preferido
- Si quieren reservar, indica que un agente humano los contactará

IMPORTANTE:
- Responde en español
- Máximo 300 caracteres por respuesta para WhatsApp
- No inventes precios, solo di que varían según temporada
- Si no sabes algo, ofrece conectar con un agente humano`;

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
app.get('/api/status', async (req, res) => {
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

// Obtener código QR
app.get('/api/qr', (req, res) => {
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

// Desconectar/Logout de WhatsApp
app.post('/api/logout', async (req, res) => {
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
    
    <script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
    <script>
        const socket = io();
        const statusEl = document.getElementById('status');
        const qrContainer = document.getElementById('qr-container');
        const instructions = document.getElementById('instructions');
        
        socket.on('qr', async (qr) => {
            statusEl.className = 'status waiting';
            statusEl.textContent = '📱 Escanea el código QR';
            instructions.style.display = 'block';
            
            qrContainer.innerHTML = '<canvas id="qr-canvas"></canvas>';
            await QRCode.toCanvas(document.getElementById('qr-canvas'), qr, {
                width: 256,
                margin: 2
            });
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

server.listen(CONFIG.PORT, () => {
    console.log('\n========================================');
    console.log('🌸 Servidor WhatsApp Futura Flor - Checkin24hs');
    console.log('========================================');
    console.log(`📡 Servidor corriendo en puerto ${CONFIG.PORT}`);
    console.log(`🌐 Panel: http://localhost:${CONFIG.PORT}`);
    console.log('========================================\n');
    console.log('⏳ Inicializando WhatsApp...\n');
});

// Iniciar cliente de WhatsApp
client.initialize();

// Manejo de cierre
process.on('SIGINT', async () => {
    console.log('\n🛑 Cerrando servidor...');
    await client.destroy();
    process.exit(0);
});

