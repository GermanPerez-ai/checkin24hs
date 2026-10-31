#!/usr/bin/env node
/**
 * 📧 Servicio de Monitoreo de Correo - Checkin24hs
 * 
 * Monitorea reservas@checkin24hs.com por IMAP y notifica al equipo por WhatsApp
 * cuando llegan respuestas relacionadas con reservas.
 */

require('dotenv').config();
const { ImapFlow } = require('imapflow');
const { simpleParser } = require('mailparser');
const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');

// ===== CONFIGURACIÓN =====
const CONFIG = {
    imap: {
        host: process.env.IMAP_HOST || 'imap.hostinger.com',
        port: parseInt(process.env.IMAP_PORT || '993', 10),
        secure: process.env.IMAP_SECURE !== '0',
        auth: {
            user: process.env.IMAP_USER,
            pass: process.env.IMAP_PASS
        },
        tls: {
            rejectUnauthorized: process.env.IMAP_TLS_REJECT_UNAUTHORIZED !== '0'
        }
    },
    mailbox: process.env.IMAP_MAILBOX || 'INBOX',
    sinceDays: parseInt(process.env.IMAP_SINCE_DAYS || '7', 10),
    supabase: {
        url: process.env.SUPABASE_URL,
        serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY
    },
    whatsapp: {
        apiUrl: process.env.WHATSAPP_API_URL || 'http://localhost:3001',
        apiKey: (process.env.WHATSAPP_API_KEY || '').trim().replace(/[\r\n]/g, ''),
        groupId: process.env.WHATSAPP_GROUP_ID
    },
    gemini: {
        apiKey: process.env.GEMINI_API_KEY || '',
        model: process.env.GEMINI_MODEL || 'gemini-2.0-flash-lite'
    },
    filterKeywords: (process.env.FILTER_KEYWORDS || 'reserva,modificación,modificacion,anulación,anulacion,cancelación,cancelacion,voucher,cupo,confirmación,confirmacion')
        .split(',')
        .map(k => k.trim().toLowerCase())
        .filter(Boolean),
    dryRun: process.argv.includes('--dry-run') || process.env.DRY_RUN === '1'
};

// Validar configuración esencial
function validateConfig() {
    const errors = [];
    
    if (!CONFIG.imap.auth.user) errors.push('IMAP_USER no configurado');
    if (!CONFIG.imap.auth.pass) errors.push('IMAP_PASS no configurado');
    if (!CONFIG.supabase.url) errors.push('SUPABASE_URL no configurado');
    if (!CONFIG.supabase.serviceRoleKey) errors.push('SUPABASE_SERVICE_ROLE_KEY no configurado');
    if (!CONFIG.whatsapp.apiKey) errors.push('WHATSAPP_API_KEY no configurado');
    if (!CONFIG.whatsapp.groupId) errors.push('WHATSAPP_GROUP_ID no configurado');
    
    if (errors.length > 0) {
        console.error('❌ Errores de configuración:');
        errors.forEach(err => console.error(`   - ${err}`));
        console.error('\n💡 Revisar el archivo .env y configurar las variables faltantes.');
        console.error('   Ver .env.example para más detalles.\n');
        return false;
    }
    
    return true;
}

// Inicializar Supabase
let supabase = null;
if (CONFIG.supabase.url && CONFIG.supabase.serviceRoleKey) {
    supabase = createClient(CONFIG.supabase.url, CONFIG.supabase.serviceRoleKey);
}

// ===== FILTROS Y PARSERS =====

/**
 * Verifica si un correo es una respuesta relacionada con reservas
 */
function isReservationRelated(parsed) {
    const subject = (parsed.subject || '').toLowerCase();
    const text = (parsed.text || '').toLowerCase();
    const combined = `${subject} ${text}`;
    
    // Buscar palabras clave
    const hasKeyword = CONFIG.filterKeywords.some(keyword => combined.includes(keyword));
    if (!hasKeyword) return false;
    
    // Verificar que sea respuesta o parte de un hilo
    // (tiene In-Reply-To o References)
    const isReply = Boolean(parsed.inReplyTo || (parsed.references && parsed.references.length > 0));
    
    return { isRelated: true, isReply };
}

/**
 * Limpia el texto del correo removiendo firmas y citas
 */
function cleanEmailText(text) {
    if (!text) return '';
    
    const lines = text.split('\n');
    const cleaned = [];
    let inQuote = false;
    
    for (const line of lines) {
        const trimmed = line.trim();
        
        // Detectar inicio de citas (>, El ... escribió:, etc)
        if (trimmed.startsWith('>') || 
            /^(el|on|am|le|il).*(escribió|wrote|schrieb|a écrit)/i.test(trimmed) ||
            /^-{3,}.*mensaje original/i.test(trimmed)) {
            inQuote = true;
            continue;
        }
        
        // Detectar firmas comunes
        if (/^-{2,}$/.test(trimmed) || 
            /^saludos?|^atentamente|^cordialmente|^regards|^best/i.test(trimmed)) {
            break;
        }
        
        if (!inQuote && trimmed.length > 0) {
            cleaned.push(trimmed);
        }
    }
    
    return cleaned.join('\n').trim().substring(0, 1500); // Limitar a 1500 chars
}

/**
 * Extrae texto de HTML (fallback para correos HTML-only)
 */
function extractTextFromHTML(html) {
    if (!html) return '';
    
    // Remover tags HTML básico
    return html
        .replace(/<style[^>]*>.*?<\/style>/gis, '')
        .replace(/<script[^>]*>.*?<\/script>/gis, '')
        .replace(/<[^>]+>/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

/**
 * Extrae información relevante del correo
 */
function extractEmailInfo(parsed) {
    const fromAddr = parsed.from && parsed.from.value && parsed.from.value[0] 
        ? parsed.from.value[0].address 
        : 'desconocido';
    
    const fromName = parsed.from && parsed.from.value && parsed.from.value[0] 
        ? parsed.from.value[0].name || fromAddr
        : fromAddr;
    
    const subject = (parsed.subject || 'Sin asunto').trim();
    
    // Preferir texto plano, pero si está vacío usar HTML
    let rawText = parsed.text || '';
    if (!rawText || rawText.trim().length < 10) {
        rawText = extractTextFromHTML(parsed.html);
    }
    
    const cleanedText = cleanEmailText(rawText);
    
    return {
        messageId: parsed.messageId,
        from: fromAddr,
        fromName: fromName,
        subject: subject,
        text: cleanedText,
        date: parsed.date
    };
}

/**
 * Genera un resumen ejecutivo simple (sin IA)
 */
function generateSimpleSummary(info) {
    const hotel = info.fromName || info.from;
    const action = detectAction(info.subject + ' ' + info.text);
    
    return `${hotel}: ${action} - ${info.subject}`;
}

/**
 * Detecta la acción principal del correo
 */
function detectAction(text) {
    const lower = text.toLowerCase();
    
    if (lower.includes('confirm') || lower.includes('confirmación') || lower.includes('confirmacion')) {
        return 'Confirmación';
    }
    if (lower.includes('anulad') || lower.includes('cancelad')) {
        return 'Anulación';
    }
    if (lower.includes('modific')) {
        return 'Modificación';
    }
    if (lower.includes('voucher')) {
        return 'Voucher';
    }
    if (lower.includes('cupo')) {
        return 'Consulta de cupo';
    }
    
    return 'Respuesta sobre reserva';
}

/**
 * Genera un resumen ejecutivo usando IA (Gemini)
 */
async function generateAISummary(info) {
    if (!CONFIG.gemini.apiKey) {
        return generateSimpleSummary(info);
    }
    
    try {
        // Limitar texto para evitar prompts muy largos (max ~800 chars para Gemini)
        const textoParaIA = info.text.substring(0, 800);
        
        const prompt = `Eres un asistente que resume correos de hoteles sobre reservas.

Correo de: ${info.fromName} (${info.from})
Asunto: ${info.subject}
Texto: ${textoParaIA}

Genera un resumen ejecutivo de máximo 100 caracteres que responda: ¿Quién envió el correo y qué dice sobre la reserva?
Formato: "Hotel X: [acción/estado]"
Ejemplos:
- "Hotel Puyehue: Confirmó modificación de fechas"
- "Corralco: Solicitó datos adicionales del pasajero"
- "Huilo Huilo: Anulación confirmada"

Resumen:`;

        const response = await axios.post(
            `https://generativelanguage.googleapis.com/v1beta/models/${CONFIG.gemini.model}:generateContent?key=${CONFIG.gemini.apiKey}`,
            {
                contents: [{
                    parts: [{ text: prompt }]
                }],
                generationConfig: {
                    maxOutputTokens: 50,
                    temperature: 0.3
                }
            },
            {
                timeout: 10000,
                headers: { 'Content-Type': 'application/json' }
            }
        );
        
        const summary = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
        if (summary && summary.length > 0) {
            return summary.substring(0, 200);
        }
        
        return generateSimpleSummary(info);
    } catch (error) {
        console.warn('⚠️  Error generando resumen con IA, usando resumen simple:', error.message);
        return generateSimpleSummary(info);
    }
}

// ===== SUPABASE =====

/**
 * Verifica si un correo ya fue procesado
 */
async function isAlreadyProcessed(messageId) {
    if (!supabase) return false;
    
    try {
        const { data, error } = await supabase
            .from('email_monitor_notifications')
            .select('id')
            .eq('message_id', messageId)
            .maybeSingle();
        
        if (error) {
            console.warn('⚠️  Error verificando duplicado:', error.message);
            return false;
        }
        
        return Boolean(data);
    } catch (error) {
        console.warn('⚠️  Error verificando duplicado:', error.message);
        return false;
    }
}

/**
 * Registra un correo como procesado
 */
async function markAsProcessed(info, summary, status = 'notified', errorDetail = null) {
    if (!supabase) return;
    
    try {
        const { error } = await supabase
            .from('email_monitor_notifications')
            .insert({
                message_id: info.messageId,
                from_addr: info.from,
                subject: info.subject,
                summary: summary,
                status: status,
                error_detail: errorDetail
            });
        
        if (error) {
            throw error;
        }
    } catch (error) {
        console.warn('⚠️  Error guardando en Supabase:', error.message);
        throw error;
    }
}

/**
 * Actualiza el estado de un correo ya registrado
 */
async function updateProcessedStatus(messageId, status, errorDetail = null) {
    if (!supabase) return;
    
    try {
        const { error } = await supabase
            .from('email_monitor_notifications')
            .update({
                status: status,
                error_detail: errorDetail,
                notified_at: status === 'notified' ? new Date().toISOString() : undefined
            })
            .eq('message_id', messageId);
        
        if (error) {
            console.warn('⚠️  Error actualizando estado en Supabase:', error.message);
        }
    } catch (error) {
        console.warn('⚠️  Error actualizando estado en Supabase:', error.message);
    }
}

// ===== WHATSAPP =====

/**
 * Envía notificación al grupo de WhatsApp
 */
async function sendWhatsAppNotification(info, summary) {
    const message = `📧 *Nueva respuesta sobre reserva*

📨 *De:* ${info.fromName}
📧 *Email:* ${info.from}
📋 *Asunto:* ${info.subject}

💬 *Resumen:*
${summary}

📝 *Mensaje:*
${info.text.substring(0, 800)}${info.text.length > 800 ? '...' : ''}

⏰ ${new Date().toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' })}`;

    try {
        const response = await axios.post(
            `${CONFIG.whatsapp.apiUrl}/api/send`,
            {
                number: CONFIG.whatsapp.groupId,
                text: message
            },
            {
                timeout: 30000,
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': CONFIG.whatsapp.apiKey
                }
            }
        );
        
        if (response.data && response.data.success) {
            return true;
        }
        
        throw new Error(response.data?.error || 'Error desconocido del servidor WhatsApp');
    } catch (error) {
        if (error.response) {
            throw new Error(`Error ${error.response.status}: ${error.response.data?.error || error.message}`);
        }
        throw error;
    }
}

// ===== MONITOR PRINCIPAL =====

/**
 * Procesa un correo individual
 */
async function processEmail(uid, client) {
    try {
        // Descargar correo completo
        const message = await client.fetchOne(uid, { source: true });
        const parsed = await simpleParser(message.source);
        
        // Verificar si es relacionado con reservas
        const filter = isReservationRelated(parsed);
        if (!filter.isRelated) {
            return { status: 'filtered', reason: 'No relacionado con reservas' };
        }
        
        // Extraer información
        const info = extractEmailInfo(parsed);
        
        // Verificar que sea realmente una respuesta/hilo (evitar newsletters)
        if (!filter.isReply) {
            return { status: 'filtered', reason: 'No es respuesta (falta In-Reply-To/References)' };
        }
        
        // Verificar duplicados
        if (await isAlreadyProcessed(info.messageId)) {
            return { status: 'duplicate', messageId: info.messageId };
        }
        
        console.log(`\n📧 Procesando: ${info.subject}`);
        console.log(`   De: ${info.fromName} <${info.from}>`);
        console.log(`   ↩️  Es respuesta`);
        
        // Generar resumen
        const summary = await generateAISummary(info);
        console.log(`   📝 Resumen: ${summary}`);
        
        if (CONFIG.dryRun) {
            console.log('   🧪 [DRY-RUN] No se envía a WhatsApp ni se marca como procesado');
            console.log(`\n   Mensaje que se enviaría:\n${'-'.repeat(60)}`);
            console.log(`De: ${info.fromName} <${info.from}>`);
            console.log(`Asunto: ${info.subject}`);
            console.log(`Resumen: ${summary}`);
            console.log(`Texto (primeros 200 chars): ${info.text.substring(0, 200)}...`);
            console.log('-'.repeat(60));
            return { status: 'dry-run', info, summary };
        }
        
        // PREVENIR RACE CONDITION: Registrar ANTES de enviar
        // Si falla el insert por duplicado (unique constraint), otro proceso ya lo está manejando
        try {
            await markAsProcessed(info, summary, 'processing');
        } catch (error) {
            // Si falla por constraint único, es porque otro proceso lo insertó primero
            if (error.message && (error.message.includes('duplicate') || error.message.includes('unique'))) {
                console.log('   ⚠️  Otro proceso ya está procesando este correo');
                return { status: 'duplicate', messageId: info.messageId };
            }
            // Otro tipo de error, continuar de todos modos
            console.warn('   ⚠️  Error pre-registrando (continuando):', error.message);
        }
        
        // Enviar a WhatsApp
        try {
            await sendWhatsAppNotification(info, summary);
            console.log('   ✅ Notificado por WhatsApp');
            
            // Actualizar estado a 'notified'
            await updateProcessedStatus(info.messageId, 'notified', null);
            
            return { status: 'notified', info, summary };
        } catch (error) {
            console.error('   ❌ Error enviando a WhatsApp:', error.message);
            await updateProcessedStatus(info.messageId, 'error', error.message);
            return { status: 'error', error: error.message };
        }
        
    } catch (error) {
        console.error('   ❌ Error procesando correo:', error.message);
        return { status: 'error', error: error.message };
    }
}

/**
 * Función principal de monitoreo
 */
async function monitor() {
    console.log('🚀 Iniciando monitoreo de correo...\n');
    
    // Validar configuración
    if (!validateConfig()) {
        process.exit(1);
    }
    
    if (CONFIG.dryRun) {
        console.log('🧪 Modo DRY-RUN activado: no se enviarán notificaciones\n');
    }
    
    console.log('📋 Configuración:');
    console.log(`   IMAP: ${CONFIG.imap.auth.user}@${CONFIG.imap.host}`);
    console.log(`   Buzón: ${CONFIG.mailbox}`);
    console.log(`   Desde: hace ${CONFIG.sinceDays} días`);
    console.log(`   WhatsApp: ${CONFIG.whatsapp.groupId}`);
    console.log(`   IA: ${CONFIG.gemini.apiKey ? 'Habilitada' : 'Deshabilitada (resumen simple)'}`);
    console.log(`   Palabras clave: ${CONFIG.filterKeywords.join(', ')}\n`);
    
    const client = new ImapFlow(CONFIG.imap);
    
    try {
        // Conectar
        console.log('🔌 Conectando a IMAP...');
        await client.connect();
        console.log('✅ Conectado\n');
        
        // Abrir buzón
        await client.mailboxOpen(CONFIG.mailbox);
        
        // Calcular fecha desde
        const sinceDate = new Date();
        sinceDate.setDate(sinceDate.getDate() - CONFIG.sinceDays);
        
        console.log(`🔍 Buscando correos desde ${sinceDate.toLocaleDateString('es-AR')}...\n`);
        
        // Buscar correos recientes
        const messages = await client.search({
            since: sinceDate
        });
        
        console.log(`📬 Encontrados ${messages.length} correos\n`);
        
        // Procesar cada correo
        const stats = {
            total: messages.length,
            notified: 0,
            filtered: 0,
            duplicate: 0,
            error: 0,
            dryRun: 0
        };
        
        for (const uid of messages) {
            const result = await processEmail(uid, client);
            stats[result.status]++;
        }
        
        // Resumen
        console.log('\n' + '='.repeat(60));
        console.log('📊 RESUMEN');
        console.log('='.repeat(60));
        console.log(`Total procesados: ${stats.total}`);
        console.log(`✅ Notificados: ${stats.notified}`);
        console.log(`🧪 Dry-run: ${stats.dryRun}`);
        console.log(`🔍 Filtrados: ${stats.filtered}`);
        console.log(`♻️  Duplicados: ${stats.duplicate}`);
        console.log(`❌ Errores: ${stats.error}`);
        console.log('='.repeat(60) + '\n');
        
    } catch (error) {
        console.error('\n❌ Error fatal:', error.message);
        process.exit(1);
    } finally {
        await client.logout();
        console.log('👋 Desconectado de IMAP');
    }
}

// Ejecutar
if (require.main === module) {
    monitor().catch(error => {
        console.error('❌ Error:', error);
        process.exit(1);
    });
}

module.exports = { monitor, isReservationRelated, cleanEmailText, extractEmailInfo };
