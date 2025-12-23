/**
 * 🌸 Servidor de WhatsApp usando Baileys para Flor - Checkin24hs
 * 
 * VERSIÓN 3.0 - Usando Baileys (sin Chrome/Puppeteer)
 * - Más ligero y rápido
 * - No requiere Chrome
 * - Funciona en cualquier servidor
 * - Soporte para 4 instancias WhatsApp
 */

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
    AUTO_REPLY: true,
    FLOR_ENABLED: true,
    SAVE_MESSAGES: true,
    SAVE_TO_SUPABASE: true,
    USE_GEMINI_AI: true,
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
    GEMINI_MODEL: 'gemini-1.5-flash',
    SUPABASE: {
        url: process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        anonKey: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4'
    }
};

// ===== INICIALIZAR EXPRESS =====
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
let phoneName = null;

// ===== FUNCIONES DE FLOR IA =====

/**
 * Procesar mensaje con Flor IA usando Gemini
 */
async function procesarConFlor(mensaje, contexto = {}) {
    if (!CONFIG.FLOR_ENABLED || !CONFIG.GEMINI_API_KEY) {
        return null;
    }

    try {
        const response = await axios.post(
            `https://generativelanguage.googleapis.com/v1beta/models/${CONFIG.GEMINI_MODEL}:generateContent?key=${CONFIG.GEMINI_API_KEY}`,
            {
                contents: [{
                    parts: [{
                        text: `Eres Flor, un asistente virtual de Checkin24hs. Responde de manera amigable y profesional.
                        
Mensaje del cliente: ${mensaje}

Contexto: ${JSON.stringify(contexto)}

Responde de manera breve y útil.`
                    }]
                }]
            },
            {
                headers: {
                    'Content-Type': 'application/json'
                }
            }
        );

        if (response.data?.candidates?.[0]?.content?.parts?.[0]?.text) {
            return response.data.candidates[0].content.parts[0].text;
        }
    } catch (error) {
        console.error('❌ Error procesando con Flor:', error.message);
    }

    return null;
}

/**
 * Guardar mensaje en Supabase
 */
async function guardarMensaje(numero, mensaje, esEnviado = false, respuestaFlor = null) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return;

    try {
        const { error } = await supabase
            .from('whatsapp_messages')
            .insert({
                instance_name: `whatsapp-${CONFIG.INSTANCE_NUMBER}`,
                phone_number: numero,
                message: mensaje,
                is_sent: esEnviado,
                flor_response: respuestaFlor,
                created_at: new Date().toISOString()
            });

        if (error) {
            console.error('❌ Error guardando mensaje:', error);
        }
    } catch (error) {
        console.error('❌ Error guardando mensaje:', error);
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
        browser: ['Checkin24hs', 'Flor', '1.0.0']
    });

    // Manejar eventos de conexión
    sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr) {
            // Generar QR code
            qrCodeData = qr;
            connectionStatus = 'connecting';
            
            // Generar QR como imagen
            try {
                const qrImage = await qrcode.toDataURL(qr);
                qrCodeData = {
                    qr: qr,
                    qrImage: qrImage,
                    timestamp: Date.now()
                };
            } catch (error) {
                console.error('Error generando QR:', error);
            }

            // Emitir QR via Socket.IO
            io.emit('qr', qrCodeData);
            console.log('📱 QR Code generado para instancia', CONFIG.INSTANCE_NUMBER);
        }

        if (connection === 'close') {
            const shouldReconnect = (lastDisconnect?.error as Boom)?.output?.statusCode !== DisconnectReason.loggedOut;
            connectionStatus = 'close';
            phoneNumber = null;
            phoneName = null;
            
            console.log('❌ Conexión cerrada:', lastDisconnect?.error);
            io.emit('connection', { status: 'close' });

            if (shouldReconnect) {
                console.log('🔄 Reconectando...');
                connectToWhatsApp();
            }
        } else if (connection === 'open') {
            connectionStatus = 'open';
            console.log('✅ WhatsApp conectado para instancia', CONFIG.INSTANCE_NUMBER);
            
            // Obtener información del teléfono
            const me = sock.user;
            if (me) {
                phoneNumber = me.id.split(':')[0];
                phoneName = me.name || phoneNumber;
            }
            
            io.emit('connection', { 
                status: 'open',
                phone: phoneNumber,
                name: phoneName
            });
        } else if (connection === 'connecting') {
            connectionStatus = 'connecting';
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

            console.log(`📱 Mensaje recibido de ${nombre} (${numero}): ${texto}`);

            // Guardar mensaje recibido
            await guardarMensaje(numero, texto, false);

            // Procesar con Flor IA si está habilitado
            if (CONFIG.AUTO_REPLY && CONFIG.FLOR_ENABLED) {
                const respuestaFlor = await procesarConFlor(texto, {
                    numero,
                    nombre,
                    instancia: CONFIG.INSTANCE_NUMBER
                });

                if (respuestaFlor) {
                    // Enviar respuesta
                    await sock.sendMessage(msg.key.remoteJid, { text: respuestaFlor });
                    
                    // Guardar respuesta
                    await guardarMensaje(numero, respuestaFlor, true, respuestaFlor);
                    
                    console.log(`✅ Flor respondió a ${nombre}`);
                }
            }
        }
    });
}

// ===== API ENDPOINTS =====

// Obtener QR Code
app.get(['/api/qr', '/qr'], async (req, res) => {
    if (qrCodeData) {
        res.json({
            qr: qrCodeData.qr || qrCodeData,
            qrImage: qrCodeData.qrImage || null,
            status: connectionStatus,
            phone: phoneNumber,
            name: phoneName
        });
    } else {
        res.json({
            qr: null,
            status: connectionStatus,
            phone: phoneNumber,
            name: phoneName
        });
    }
});

// Obtener estado
app.get(['/api/status', '/status'], (req, res) => {
    res.json({
        status: connectionStatus,
        phone: phoneNumber,
        name: phoneName,
        instance: CONFIG.INSTANCE_NUMBER
    });
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

        await guardarMensaje(number, text, true);

        res.json({ success: true, message: 'Mensaje enviado' });
    } catch (error) {
        console.error('Error enviando mensaje:', error);
        res.status(500).json({ error: error.message });
    }
});

// Página HTML simple para mostrar QR
app.get('/', (req, res) => {
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
                if (data.status === 'open') {
                    statusDiv.textContent = 'Conectado ✅';
                    statusDiv.className = 'status connected';
                    qrContainer.innerHTML = '<div style="font-size: 48px;">✅</div><p>WhatsApp conectado</p>';
                    if (data.phone) {
                        phoneNumber.textContent = data.phone;
                        phoneName.textContent = data.name || data.phone;
                        phoneInfo.style.display = 'block';
                    }
                } else if (data.status === 'connecting') {
                    fetch('/api/qr')
                        .then(res => res.json())
                        .then(qrData => {
                            if (qrData.qr) {
                                const qr = qrData.qr;
                                const qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=' + encodeURIComponent(qr);
                                qrContainer.innerHTML = '<img src="' + qrUrl + '" alt="QR Code">';
                                statusDiv.textContent = 'Conectando...';
                                statusDiv.className = 'status connecting';
                            }
                        });
                }
            });
    </script>
</body>
</html>
    `);
});

// ===== INICIAR SERVIDOR =====

async function start() {
    try {
        // Conectar a WhatsApp
        await connectToWhatsApp();

        // Iniciar servidor HTTP
        server.listen(CONFIG.PORT, () => {
            console.log(`✅ Servidor iniciado en puerto ${CONFIG.PORT}`);
            console.log(`📱 Instancia WhatsApp: ${CONFIG.INSTANCE_NUMBER}`);
            console.log(`🌐 Accede a: http://localhost:${CONFIG.PORT}`);
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

