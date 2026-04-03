/**
 * 🌸 Servidor Adaptador Evolution API para Flor IA - Checkin24hs
 * 
 * Este servidor conecta Evolution API con Flor IA
 * Recibe mensajes de Evolution API y los procesa con Flor
 */

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración
const CONFIG = {
    EVOLUTION_API_URL: process.env.EVOLUTION_API_URL || 'http://localhost:8080',
    EVOLUTION_API_KEY: process.env.EVOLUTION_API_KEY || 'checkin24hs-secret-key-2024',
    FLOR_ENABLED: process.env.FLOR_ENABLED !== 'false',
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
    GEMINI_MODEL: process.env.GEMINI_MODEL || 'gemini-1.5-flash',
    SUPABASE: {
        url: process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        key: process.env.SUPABASE_ANON_KEY || ''
    },
    INSTANCES: ['whatsapp-1', 'whatsapp-2', 'whatsapp-3', 'whatsapp-4']
};

// Inicializar Supabase
const supabase = CONFIG.SUPABASE.key ? createClient(CONFIG.SUPABASE.url, CONFIG.SUPABASE.key) : null;

// Middleware
app.use(cors());
app.use(express.json());

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
async function guardarMensaje(instancia, numero, mensaje, esEnviado = false, respuestaFlor = null) {
    if (!supabase) return;

    try {
        const { error } = await supabase
            .from('whatsapp_messages')
            .insert({
                instance_name: instancia,
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

/**
 * Enviar mensaje a través de Evolution API
 */
async function enviarMensaje(instancia, numero, texto) {
    try {
        const response = await axios.post(
            `${CONFIG.EVOLUTION_API_URL}/message/sendText/${instancia}`,
            {
                number: numero,
                text: texto
            },
            {
                headers: {
                    'apikey': CONFIG.EVOLUTION_API_KEY,
                    'Content-Type': 'application/json'
                }
            }
        );

        return response.data;
    } catch (error) {
        console.error(`❌ Error enviando mensaje a ${instancia}:`, error.message);
        throw error;
    }
}

// ===== ENDPOINTS =====

/**
 * Webhook para recibir mensajes de Evolution API
 */
app.post('/webhook/evolution', async (req, res) => {
    try {
        const evento = req.body;

        console.log('📥 Evento recibido:', evento.event);

        // Procesar mensajes nuevos
        if (evento.event === 'messages.upsert') {
            const mensajes = evento.data?.messages || [];

            for (const mensaje of mensajes) {
                // Solo procesar mensajes entrantes (no enviados por nosotros)
                if (mensaje.key?.fromMe) continue;

                const numero = mensaje.key?.remoteJid?.replace('@s.whatsapp.net', '') || '';
                const texto = mensaje.message?.conversation || mensaje.message?.extendedTextMessage?.text || '';
                const instancia = evento.instance || 'whatsapp-1';

                if (!texto) continue;

                console.log(`📱 Mensaje recibido en ${instancia} de ${numero}: ${texto}`);

                // Guardar mensaje recibido
                await guardarMensaje(instancia, numero, texto, false);

                // Procesar con Flor IA
                const respuestaFlor = await procesarConFlor(texto, {
                    instancia,
                    numero,
                    timestamp: mensaje.messageTimestamp
                });

                if (respuestaFlor) {
                    // Enviar respuesta de Flor
                    await enviarMensaje(instancia, numero, respuestaFlor);
                    
                    // Guardar respuesta
                    await guardarMensaje(instancia, numero, respuestaFlor, true, respuestaFlor);
                    
                    console.log(`✅ Flor respondió en ${instancia} a ${numero}`);
                }
            }
        }

        // Procesar actualizaciones de QR
        if (evento.event === 'qrcode.updated') {
            console.log(`📱 QR actualizado para ${evento.instance}`);
            // Aquí puedes notificar al dashboard si es necesario
        }

        // Procesar cambios de conexión
        if (evento.event === 'connection.update') {
            const estado = evento.data?.connection;
            console.log(`🔌 Estado de conexión ${evento.instance}: ${estado}`);
            // Aquí puedes notificar al dashboard si es necesario
        }

        res.status(200).json({ success: true });
    } catch (error) {
        console.error('❌ Error procesando webhook:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Endpoint para obtener QR de una instancia
 */
app.get('/api/qr/:instance', async (req, res) => {
    try {
        const { instance } = req.params;

        const response = await axios.get(
            `${CONFIG.EVOLUTION_API_URL}/instance/connect/${instance}`,
            {
                headers: {
                    'apikey': CONFIG.EVOLUTION_API_KEY
                }
            }
        );

        res.json(response.data);
    } catch (error) {
        console.error(`❌ Error obteniendo QR de ${req.params.instance}:`, error.message);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Endpoint para obtener estado de una instancia
 */
app.get('/api/status/:instance', async (req, res) => {
    try {
        const { instance } = req.params;

        const response = await axios.get(
            `${CONFIG.EVOLUTION_API_URL}/instance/fetchInstance/${instance}`,
            {
                headers: {
                    'apikey': CONFIG.EVOLUTION_API_KEY
                }
            }
        );

        res.json(response.data);
    } catch (error) {
        console.error(`❌ Error obteniendo estado de ${req.params.instance}:`, error.message);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Endpoint para enviar mensaje
 */
app.post('/api/send/:instance', async (req, res) => {
    try {
        const { instance } = req.params;
        const { number, text } = req.body;

        if (!number || !text) {
            return res.status(400).json({ error: 'number y text son requeridos' });
        }

        const resultado = await enviarMensaje(instance, number, text);
        res.json(resultado);
    } catch (error) {
        console.error(`❌ Error enviando mensaje:`, error.message);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Endpoint para crear instancia
 */
app.post('/api/instance/create', async (req, res) => {
    try {
        const { instanceName } = req.body;

        if (!instanceName) {
            return res.status(400).json({ error: 'instanceName es requerido' });
        }

        const response = await axios.post(
            `${CONFIG.EVOLUTION_API_URL}/instance/create`,
            {
                instanceName,
                qrcode: true,
                integration: 'WHATSAPP-BAILEYS'
            },
            {
                headers: {
                    'apikey': CONFIG.EVOLUTION_API_KEY,
                    'Content-Type': 'application/json'
                }
            }
        );

        res.json(response.data);
    } catch (error) {
        console.error(`❌ Error creando instancia:`, error.message);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Endpoint de salud
 */
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`🚀 Servidor Evolution API Adaptador iniciado en puerto ${PORT}`);
    console.log(`📡 Evolution API URL: ${CONFIG.EVOLUTION_API_URL}`);
    console.log(`🤖 Flor IA: ${CONFIG.FLOR_ENABLED ? 'Habilitada' : 'Deshabilitada'}`);
    console.log(`📦 Instancias: ${CONFIG.INSTANCES.join(', ')}`);
});


