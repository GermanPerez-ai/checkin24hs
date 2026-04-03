/**
 * Meta Messaging Server - Flor IA
 * Webhook para Instagram y Facebook Messenger (Checkin24hs).
 * Recibe mensajes, los procesa con Flor IA (vía API del servidor WhatsApp) y responde.
 */

const express = require('express');
const axios = require('axios');

const PORT = parseInt(process.env.PORT || '3010', 10);
const FLOR_API_URL = (process.env.FLOR_API_URL || process.env.WHATSAPP_SERVER_URL || 'http://localhost:3001').replace(/\/$/, '');
const META_VERIFY_TOKEN = process.env.META_VERIFY_TOKEN || 'checkin24hs_flor_verify';
const META_PAGE_ACCESS_TOKEN = process.env.META_PAGE_ACCESS_TOKEN || '';

const app = express();
app.use(express.json());

// Log de arranque
console.log('🌸 Meta Messaging Server (Flor IA) - Checkin24hs');
console.log('   FLOR_API_URL:', FLOR_API_URL);
console.log('   META_VERIFY_TOKEN definido:', !!META_VERIFY_TOKEN);
console.log('   META_PAGE_ACCESS_TOKEN definido:', !!META_PAGE_ACCESS_TOKEN);

/**
 * Verificación del webhook (Meta envía GET con hub.mode, hub.verify_token, hub.challenge)
 */
app.get('/webhook', (req, res) => {
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    if (mode === 'subscribe' && token === META_VERIFY_TOKEN) {
        console.log('✅ Webhook verificado por Meta');
        res.status(200).send(challenge);
    } else {
        console.warn('⚠️ Webhook verification failed: mode=%s token match=%s', mode, token === META_VERIFY_TOKEN);
        res.sendStatus(403);
    }
});

/**
 * Recibir eventos de Meta (Instagram y Facebook Messenger)
 */
app.post('/webhook', (req, res) => {
    // Responder 200 enseguida para que Meta no reintente
    res.sendStatus(200);

    const body = req.body;
    if (!body || body.object !== 'instagram' && body.object !== 'page') {
        return;
    }

    const objectType = body.object;
    const entries = body.entry || [];

    for (const entry of entries) {
        const entryId = entry.id;
        const messaging = entry.messaging || [];

        for (const event of messaging) {
            // Ignorar mensajes enviados por nosotros (echo)
            if (event.message && event.message.is_echo) continue;
            if (event.sender && event.sender.id === entryId) continue;

            const senderId = event.sender?.id;
            const recipientId = event.recipient?.id || entryId;
            if (!senderId) continue;

            let text = null;
            if (event.message) {
                text = event.message.text || (event.message.quick_reply && event.message.quick_reply.payload) || null;
            }
            if (event.postback && event.postback.payload) {
                text = event.postback.payload;
            }

            if (!text || typeof text !== 'string' || !text.trim()) {
                continue;
            }

            processIncomingMessage(objectType, entryId, senderId, recipientId, text.trim(), event).catch(err => {
                console.error('❌ Error procesando mensaje Meta:', err.message);
            });
        }
    }
});

/**
 * Procesar mensaje: llamar a Flor IA y enviar respuesta por Graph API
 */
async function processIncomingMessage(objectType, entryId, senderId, recipientId, text, rawEvent) {
    const channel = objectType === 'instagram' ? 'Instagram' : 'Facebook';
    console.log(`📩 [${channel}] Mensaje de ${senderId}: ${text.slice(0, 60)}${text.length > 60 ? '...' : ''}`);

    if (!META_PAGE_ACCESS_TOKEN) {
        console.error('❌ META_PAGE_ACCESS_TOKEN no configurado. No se puede responder.');
        return;
    }

    let responseText = null;
    try {
        const florRes = await axios.post(
            `${FLOR_API_URL}/api/flor/process`,
            {
                message: text,
                context: {
                    channel: objectType,
                    sender_id: senderId,
                    recipient_id: recipientId,
                    entry_id: entryId
                }
            },
            { timeout: 25000, headers: { 'Content-Type': 'application/json' } }
        );

        if (florRes.data && florRes.data.response) {
            responseText = typeof florRes.data.response === 'string'
                ? florRes.data.response
                : (florRes.data.response.text != null ? florRes.data.response.text : null);
        }
    } catch (err) {
        console.error('❌ Error llamando a Flor API:', err.response?.status, err.message);
        responseText = 'Disculpá, en este momento no puedo procesar tu mensaje. ¿Podés intentar de nuevo en un rato?';
    }

    if (!responseText || !responseText.trim()) {
        return;
    }

    await sendMetaMessage(entryId, senderId, responseText.trim());
    console.log(`✅ [${channel}] Flor respondió a ${senderId}`);
}

/**
 * Enviar mensaje por Meta Graph API (Instagram y Messenger)
 * Endpoint: POST https://graph.facebook.com/v18.0/{page-or-ig-id}/messages
 */
async function sendMetaMessage(recipientIdOrPageId, senderPsid, text) {
    const url = `https://graph.facebook.com/v18.0/${recipientIdOrPageId}/messages`;
    const params = new URLSearchParams({ access_token: META_PAGE_ACCESS_TOKEN });
    const body = {
        recipient: { id: senderPsid },
        messaging_type: 'RESPONSE',
        message: { text: text }
    };

    const res = await axios.post(`${url}?${params.toString()}`, body, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 10000
    });

    if (res.data && res.data.error) {
        throw new Error(res.data.error.message || 'Meta API error');
    }
}

// Health
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'meta-messaging-flor',
        flor_api: FLOR_API_URL,
        has_token: !!META_PAGE_ACCESS_TOKEN,
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor escuchando en http://0.0.0.0:${PORT}`);
    console.log(`   Webhook URL: POST/GET .../webhook`);
});
