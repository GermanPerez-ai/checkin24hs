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
        },
        logger: false
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
        groupId: process.env.WHATSAPP_GROUP_ID,
        providerNumbers: (process.env.WHATSAPP_PROVIDER_NUMBERS || '5492944210725,5492944579759')
            .split(',')
            .map(n => n.trim().replace(/\D/g, ''))
            .filter(Boolean)
    },
    autoClose: {
        enabled: process.env.AUTO_CLOSE_RESERVATIONS === '1',
        dryRun: process.env.AUTO_CLOSE_DRY_RUN !== '0'
    },
    gemini: {
        apiKey: process.env.GEMINI_API_KEY || '',
        model: process.env.GEMINI_MODEL || 'gemini-2.0-flash-lite'
    },
    filterKeywords: (process.env.FILTER_KEYWORDS || 'reserva,modificación,modificacion,anulación,anulacion,cancelación,cancelacion,voucher,cupo,confirmación,confirmacion')
        .split(',')
        .map(k => k.trim().toLowerCase())
        .filter(Boolean),
    providerDomains: (process.env.PROVIDER_DOMAINS || 'tanica.com,ratehawk.com,emergingtravel.com')
        .split(',')
        .map(d => d.trim().toLowerCase())
        .filter(Boolean),
    hotelDomains: (process.env.HOTEL_DOMAINS || '')
        .split(',')
        .map(d => d.trim().toLowerCase())
        .filter(Boolean),
    internalSenders: (process.env.INTERNAL_SENDERS || 'checkin24hs.com,checkin24hs@gmail.com,axelbisio@hotmail.com')
        .split(',')
        .map(s => s.trim().toLowerCase())
        .filter(Boolean),
    agents: parseAgentNames(process.env.AGENT_NAMES || 'Mariano;German:Germán|German Perez|germanperez;Nazareno:Naza;Axel:Axel Bisio|axelbisio'),
    dryRun: process.argv.includes('--dry-run') || process.env.DRY_RUN === '1',
    markExisting: process.argv.includes('--mark-existing') || process.argv.includes('--seed')
};

/**
 * Parsea la configuración de agentes desde AGENT_NAMES
 * Formato: Nombre;Nombre2:alias1|alias2;Nombre3
 * Retorna: [{ name: 'Nombre', aliases: ['nombre', 'alias1', 'alias2'] }, ...]
 */
function parseAgentNames(agentNamesStr) {
    if (!agentNamesStr) return [];
    
    return agentNamesStr.split(';').map(entry => {
        const parts = entry.split(':');
        const name = parts[0].trim();
        const aliases = parts.length > 1 
            ? parts[1].split('|').map(a => a.trim().toLowerCase())
            : [];
        
        // Agregar el nombre mismo como alias (en minúsculas)
        const allAliases = [name.toLowerCase(), ...aliases];
        
        return {
            name: name,
            aliases: [...new Set(allAliases)] // Remover duplicados
        };
    }).filter(agent => agent.name);
}

// Validar configuración esencial
function validateConfig() {
    const errors = [];
    
    if (!CONFIG.imap.auth.user) errors.push('IMAP_USER no configurado');
    if (!CONFIG.imap.auth.pass) errors.push('IMAP_PASS no configurado');
    if (!CONFIG.supabase.url) errors.push('SUPABASE_URL no configurado');
    if (!CONFIG.supabase.serviceRoleKey) errors.push('SUPABASE_SERVICE_ROLE_KEY no configurado');
    if (!CONFIG.whatsapp.apiKey) errors.push('WHATSAPP_API_KEY no configurado');
    if (!CONFIG.whatsapp.groupId && CONFIG.whatsapp.providerNumbers.length === 0) {
        errors.push('WHATSAPP_GROUP_ID o WHATSAPP_PROVIDER_NUMBERS deben estar configurados');
    }
    
    if (errors.length > 0) {
        console.error('❌ Errores de configuración:');
        errors.forEach(err => console.error(`   - ${err}`));
        console.error('\n💡 Revisar el archivo .env y configurar las variables faltantes.');
        console.error('   Ver .env.example para más detalles.\n');
        return false;
    }
    
    return true;
}

// ===== CLASIFICACIÓN DE REMITENTES =====

/**
 * Verifica si un correo es de un remitente interno (no debe notificarse)
 */
function isInternalSender(email) {
    const emailLower = email.toLowerCase();
    return CONFIG.internalSenders.some(sender => {
        // Si el sender contiene @, es un email completo
        if (sender.includes('@')) {
            return emailLower === sender;
        }
        // Si no, es un dominio (ej: checkin24hs.com)
        return emailLower.endsWith('@' + sender);
    });
}

/**
 * Clasifica el tipo de remitente: 'provider', 'hotel', o 'internal'
 */
function classifySender(email) {
    const emailLower = email.toLowerCase();
    
    // Verificar si es interno
    if (isInternalSender(emailLower)) {
        return 'internal';
    }
    
    // Extraer dominio
    const domain = emailLower.split('@')[1];
    if (!domain) return 'hotel'; // Por defecto hotel si no hay dominio
    
    // Verificar si es proveedor
    if (CONFIG.providerDomains.some(d => domain === d || domain.endsWith('.' + d))) {
        return 'provider';
    }
    
    // Verificar si está en la lista explícita de hoteles (si existe)
    if (CONFIG.hotelDomains.length > 0) {
        if (CONFIG.hotelDomains.some(d => domain === d || domain.endsWith('.' + d))) {
            return 'hotel';
        }
        // Si hay lista de hoteles pero no matchea, tratar como provider
        return 'provider';
    }
    
    // Por defecto: si no es proveedor conocido, es hotel
    return 'hotel';
}

/**
 * Obtiene los destinatarios WhatsApp según el tipo de remitente
 * Retorna: { type: 'group'|'providers'|'internal', destinations: [...] }
 */
function getWhatsAppDestinations(email) {
    const senderType = classifySender(email);
    
    if (senderType === 'internal') {
        return { type: 'internal', destinations: [] };
    }
    
    if (senderType === 'provider') {
        return {
            type: 'providers',
            destinations: CONFIG.whatsapp.providerNumbers
        };
    }
    
    // Hotel
    return {
        type: 'group',
        destinations: CONFIG.whatsapp.groupId ? [CONFIG.whatsapp.groupId] : []
    };
}

// ===== DETECCIÓN DE AGENTES =====

/**
 * Detecta qué agente de Checkin24hs solicitó la reserva
 * Busca en orden de prioridad:
 * 1. Mensaje original citado / firma (después de "De:/From:/El...escribió")
 * 2. Saludo al inicio ("Hola Mariano", "Estimado Axel")
 * 3. Headers To/Cc con direcciones personales
 * 
 * @param {string} rawText - Texto completo del email SIN limpiar (incluye citas)
 * @param {object} parsed - Email parseado completo (para headers)
 * @returns {string} - Nombre del agente o 'no identificado'
 */
function detectAgent(rawText, parsed) {
    if (!rawText) return 'no identificado';
    
    const textLower = rawText.toLowerCase();
    
    // 1. PRIORIDAD: Buscar en el mensaje original citado / firma
    // Buscar después de patrones como "De:", "From:", "El ... escribió:", "On ... wrote:"
    const quotedPatterns = [
        /(?:de|from):\s*([^\n]+)/gi,
        /(?:el|on)\s+[^\n]*?,\s*([^\n<]+?)(?:\s+escribió|wrote|schrieb)/gi,
        /^-{2,}\s*$/gm,  // Línea de firma
    ];
    
    for (const pattern of quotedPatterns) {
        const matches = textLower.matchAll(pattern);
        for (const match of matches) {
            const context = match[1] || textLower.slice(match.index, match.index + 200);
            const agent = findAgentInText(context);
            if (agent) return agent;
        }
    }
    
    // Buscar en firmas de email (emails como axelbisio@hotmail.com)
    const emailMatches = textLower.match(/[\w.-]+@[\w.-]+\.\w+/g);
    if (emailMatches) {
        for (const email of emailMatches) {
            const agent = findAgentInText(email);
            if (agent) return agent;
        }
    }
    
    // 2. Buscar en saludos al inicio del mensaje (primeras 5 líneas)
    const firstLines = textLower.split('\n').slice(0, 5).join('\n');
    const greetingPatterns = [
        /(?:hola|estimado|estimada|querido|querida|buen\s+día|buenos\s+días)\s+([a-záéíóúñ]+)/gi,
        /([a-záéíóúñ]+)\s*,?\s*(?:como\s+estas|cómo\s+estás|buen\s+día)/gi
    ];
    
    for (const pattern of greetingPatterns) {
        const matches = firstLines.matchAll(pattern);
        for (const match of matches) {
            const name = match[1];
            const agent = findAgentInText(name);
            if (agent) return agent;
        }
    }
    
    // 3. Buscar en headers To/Cc
    const recipients = [];
    if (parsed.to && parsed.to.value) {
        recipients.push(...parsed.to.value.map(r => r.address || '').filter(Boolean));
    }
    if (parsed.cc && parsed.cc.value) {
        recipients.push(...parsed.cc.value.map(r => r.address || '').filter(Boolean));
    }
    
    for (const email of recipients) {
        const agent = findAgentInText(email.toLowerCase());
        if (agent) return agent;
    }
    
    return 'no identificado';
}

/**
 * Busca coincidencias de agentes en un texto dado
 * @param {string} text - Texto donde buscar (en minúsculas)
 * @returns {string|null} - Nombre del agente encontrado o null
 */
function findAgentInText(text) {
    if (!text) return null;
    
    const textLower = text.toLowerCase();
    
    for (const agent of CONFIG.agents) {
        for (const alias of agent.aliases) {
            if (textLower.includes(alias)) {
                return agent.name;
            }
        }
    }
    
    return null;
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
 * Limpia el texto del correo removiendo firmas, citas y ruido
 */
function cleanEmailText(text) {
    if (!text) return '';
    
    // Remover placeholders de imágenes inline [cid:...] y similares
    text = text.replace(/\[cid:[^\]]+\]/gi, '');
    text = text.replace(/\[image:[^\]]+\]/gi, '');
    text = text.replace(/\[https?:\/\/[^\]]+\.(jpg|jpeg|png|gif|bmp|webp)\]/gi, '');
    
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
    
    // Detectar qué agente solicitó (usar texto completo con citas)
    const requestedBy = detectAgent(rawText, parsed);
    
    return {
        messageId: parsed.messageId,
        from: fromAddr,
        fromName: fromName,
        subject: subject,
        text: cleanedText,
        rawText: rawText,  // Texto completo para otras operaciones
        requestedBy: requestedBy,
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

// ===== AUTO-CIERRE DE RESERVAS =====

/**
 * Extrae códigos de reserva del subject y body del correo
 * Busca códigos alfanuméricos (ej: V2K67A, VH6QHS, VG52SH, VX6KZM) o numéricos largos (ej: 598854662, 600986202)
 * @param {string} subject - Asunto del correo
 * @param {string} body - Cuerpo del correo (incluye texto citado)
 * @returns {string[]} - Array de códigos encontrados (sin duplicados)
 */
function extractReservationCodes(subject, body) {
    const codes = new Set();
    const combined = `${subject}\n${body}`;
    
    // Patrón para códigos alfanuméricos: 1-2 letras mayúsculas seguidas de 4-6 caracteres alfanuméricos
    // Debe contener al menos un dígito para evitar palabras comunes
    // Ejemplos: V2K67A, VH6QHS, VG52SH, VX6KZM
    const alphanumericPattern = /\b[A-Z]{1,2}[A-Z0-9]{4,6}\b/g;
    const alphanumericMatches = combined.match(alphanumericPattern) || [];
    alphanumericMatches.forEach(code => {
        // Verificar que contenga al menos un dígito
        if (/\d/.test(code)) {
            codes.add(code);
        }
    });
    
    // Patrón para códigos numéricos largos (8-9 dígitos)
    // 1. Con contexto relevante (más confiable)
    const numericWithContextPattern = /(?:reserva|cancelación|cancelacion|anulación|anulacion|código|codigo|code|n[°º]|#|localizador)\s*:?\s*#?\s*(\d{8,9})\b/gi;
    let match;
    while ((match = numericWithContextPattern.exec(combined)) !== null) {
        codes.add(match[1]);
    }
    
    // 2. Sin contexto: buscar números de 8-9 dígitos en el subject después de "Hotel" o al final
    // Esto captura casos como "ANULAR RESERVA Hotel Huilo-Huilo 598854662"
    const subjectNumericPattern = /(?:hotel|huilo|puyehue|corralco|tanica)[\s-]+\w+[\s-]+(\d{8,9})\b/gi;
    while ((match = subjectNumericPattern.exec(subject)) !== null) {
        codes.add(match[1]);
    }
    
    // 3. Números de 8-9 dígitos al final del subject
    const endNumericPattern = /\s(\d{8,9})$/i;
    const endMatch = subject.match(endNumericPattern);
    if (endMatch) {
        codes.add(endMatch[1]);
    }
    
    return Array.from(codes);
}

/**
 * Detecta si el correo confirma una cancelación o modificación
 * @param {string} text - Texto completo del correo (limpio)
 * @param {string} rawText - Texto completo sin limpiar (incluye citas)
 * @param {string} subject - Asunto del correo
 * @returns {object|null} - { action: 'cancelacion'|'modificacion', confidence: 'high'|'medium' } o null
 */
function detectConfirmation(text, rawText, subject) {
    const combined = `${subject}\n${text}`.toLowerCase();
    const rawCombined = `${subject}\n${rawText}`.toLowerCase();
    
    // Patrones negativos (hotel NO confirma, no puede, rechaza)
    const negativePatterns = [
        /no\s+(?:se\s+)?(?:puede|podemos|es\s+posible)/i,
        /no\s+(?:confirmamos|confirmó|procedemos|procederemos)/i,
        /imposible\s+(?:anular|cancelar|modificar)/i,
        /(?:hotel|establecimiento)\s+(?:no\s+)?(?:acepta|autoriza)/i,
        /cargo\s+por\s+(?:cancelación|cancelacion|anulación|anulacion)/i,
        /penalidad/i,
        /(?:debe|debera|deberá)\s+(?:abonar|pagar)/i
    ];
    
    for (const pattern of negativePatterns) {
        if (pattern.test(combined)) {
            return null; // Respuesta negativa o ambigua
        }
    }
    
    // Patrones de confirmación de ANULACIÓN/CANCELACIÓN
    const cancellationPatterns = [
        { pattern: /(?:procedemos\s+a\s+|queda\s+|dejar[áa]\s+)?anulad[oa]/i, confidence: 'high' },
        { pattern: /(?:procedemos\s+a\s+|queda\s+|dejar[áa]\s+)?cancelad[oa]/i, confidence: 'high' },
        { pattern: /procedemos\s+a\s+(?:anular|cancelar)/i, confidence: 'high' },
        { pattern: /(?:confirmamos|confirmo)\s+(?:la\s+)?(?:anulación|anulacion|cancelación|cancelacion)/i, confidence: 'high' },
        { pattern: /(?:anulación|anulacion|cancelación|cancelacion)\s+(?:confirmada|procesada|realizada|efectuada)/i, confidence: 'high' },
        { pattern: /n[°º]?\s*(?:de\s+)?(?:cancelación|cancelacion|anulación|anulacion)\s*:?\s*\d+/i, confidence: 'high' }
    ];
    
    for (const { pattern, confidence } of cancellationPatterns) {
        if (pattern.test(combined)) {
            return { action: 'cancelacion', confidence };
        }
    }
    
    // Patrones de confirmación de MODIFICACIÓN
    // Solo si el subject original menciona MODIFICAR (para evitar falsos positivos)
    const isModificationRequest = /modificar\s+reserva/i.test(rawCombined);
    
    if (isModificationRequest) {
        const modificationPatterns = [
            { pattern: /modificación\s+(?:confirmada|procesada|realizada|efectuada|aplicada)/i, confidence: 'high' },
            { pattern: /(?:confirmamos|confirmo)\s+(?:la\s+)?modificación/i, confidence: 'high' },
            { pattern: /(?:hemos\s+)?(?:modificado|actualizado)\s+(?:la\s+)?reserva/i, confidence: 'medium' },
            { pattern: /(?:cambio|cambios)\s+(?:realizado|realizados|aplicado|aplicados)/i, confidence: 'medium' }
        ];
        
        for (const { pattern, confidence } of modificationPatterns) {
            if (pattern.test(combined)) {
                return { action: 'modificacion', confidence };
            }
        }
    }
    
    return null;
}

/**
 * Busca una reserva en Supabase por código y verifica si está en estado abierto
 * @param {string} code - Código de reserva
 * @returns {object|null} - Reserva encontrada o null
 */
async function findOpenReservation(code) {
    if (!supabase) return null;
    
    try {
        const { data, error } = await supabase
            .from('reservations')
            .select('id,reservation_code,status,hotel_name,customer_name,notes,check_in,check_out,total_amount')
            .or(`reservation_code.eq.${code},reservation_code.ilike.*${code}*`)
            .in('status', ['Anulación pedida', 'Modificación pedida', 'En gestión'])
            .limit(1)
            .maybeSingle();
        
        if (error) {
            console.warn(`   ⚠️  Error buscando reserva ${code}:`, error.message);
            return null;
        }
        
        return data;
    } catch (error) {
        console.warn(`   ⚠️  Error buscando reserva ${code}:`, error.message);
        return null;
    }
}

/**
 * Extrae fechas del email (check-in y check-out)
 * Busca patrones de fechas en formatos comunes
 * @param {string} text - Texto del email
 * @param {string} rawText - Texto completo sin limpiar
 * @returns {object|null} - { checkIn: 'YYYY-MM-DD', checkOut: 'YYYY-MM-DD' } o null
 */
function extractDatesFromEmail(text, rawText) {
    const combined = `${text}\n${rawText}`;
    
    const dates = new Set();
    
    // Patrón ISO format: 2026-11-16
    const isoMatches = combined.matchAll(/(\d{4})-(\d{2})-(\d{2})/g);
    for (const match of isoMatches) {
        const year = parseInt(match[1]);
        const month = parseInt(match[2]);
        const day = parseInt(match[3]);
        
        if (year >= 2024 && year <= 2030 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            const dateObj = new Date(dateStr);
            
            // Verificar que la fecha sea válida y futura (o hasta 30 días atrás)
            const now = new Date();
            const thirtyDaysAgo = new Date(now);
            thirtyDaysAgo.setDate(now.getDate() - 30);
            
            if (dateObj >= thirtyDaysAgo) {
                dates.add(dateStr);
            }
        }
    }
    
    // Patrón DD/MM/YYYY o DD-MM-YYYY
    const ddmmyyyyMatches = combined.matchAll(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/g);
    for (const match of ddmmyyyyMatches) {
        const day = parseInt(match[1]);
        const month = parseInt(match[2]);
        const year = parseInt(match[3]);
        
        if (year >= 2024 && year <= 2030 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            const dateObj = new Date(dateStr);
            
            // Verificar que la fecha sea válida y futura (o hasta 30 días atrás)
            const now = new Date();
            const thirtyDaysAgo = new Date(now);
            thirtyDaysAgo.setDate(now.getDate() - 30);
            
            if (dateObj >= thirtyDaysAgo) {
                dates.add(dateStr);
            }
        }
    }
    
    // Convertir a array y ordenar
    const sortedDates = Array.from(dates).sort((a, b) => {
        return new Date(a) - new Date(b);
    });
    
    // Si encontramos al menos 2 fechas, la primera es check-in y la segunda check-out
    if (sortedDates.length >= 2) {
        return {
            checkIn: sortedDates[0],
            checkOut: sortedDates[1]
        };
    }
    
    return null;
}

/**
 * Extrae tarifa/monto del email
 * Busca patrones de montos en pesos argentinos, USD, o sin símbolo
 * @param {string} text - Texto del email
 * @param {string} rawText - Texto completo sin limpiar
 * @returns {number|null} - Monto encontrado o null
 */
function extractAmountFromEmail(text, rawText) {
    const combined = `${text}\n${rawText}`;
    
    // Patrones de montos con contextos relevantes
    const amountPatterns = [
        // "total: $1800", "total 1800", "total: 1800.50", "total es 1800"
        /total\s+(?:es|:)?\s*\$?\s*([\d,]+\.?\d*)/gi,
        // "tarifa: $1800", "tarifa nueva: 1800", "tarifa es: 1800"
        /tarifa\s*(?:nueva|es)?\s*:?\s*\$?\s*([\d,]+\.?\d*)/gi,
        // "monto: $1800", "monto 1800", "monto es 1800"
        /monto\s*(?:es)?\s*:?\s*\$?\s*([\d,]+\.?\d*)/gi,
        // "$ 1800", "ARS 1800", "USD 1800"
        /(?:\$|ARS|USD)\s*([\d,]+\.?\d*)/gi,
        // "1800.50" después de palabras clave
        /(?:abonar|pagar|costo|precio)\s*:?\s*\$?\s*([\d,]+\.?\d*)/gi
    ];
    
    const amounts = [];
    
    for (const pattern of amountPatterns) {
        let match;
        pattern.lastIndex = 0;
        while ((match = pattern.exec(combined)) !== null) {
            const amountStr = match[1].replace(/,/g, '');
            const amount = parseFloat(amountStr);
            
            // Validar rango razonable (entre 100 y 1,000,000)
            if (!isNaN(amount) && amount >= 100 && amount <= 1000000) {
                amounts.push(amount);
            }
        }
    }
    
    // Si encontramos montos, retornar el más frecuente o el primero
    if (amounts.length > 0) {
        return amounts[0];
    }
    
    return null;
}

/**
 * Determina qué datos cambiar en una modificación de reserva
 * Compara los datos extraídos del email con los datos actuales de la reserva
 * @param {object} reservation - Reserva actual
 * @param {string} rawText - Texto completo del email
 * @param {string} text - Texto limpio del email
 * @returns {object|null} - { dates: {...}, amount: ..., auditNotes: [...] } o null si no hay cambios claros
 */
function determineReservationChanges(reservation, rawText, text) {
    const changes = {
        checkIn: null,
        checkOut: null,
        totalAmount: null,
        auditNotes: []
    };
    
    let hasChanges = false;
    
    // Extraer fechas del email
    const extractedDates = extractDatesFromEmail(text, rawText);
    if (extractedDates) {
        const currentCheckIn = reservation.check_in;
        const currentCheckOut = reservation.check_out;
        
        // Si las fechas extraídas son diferentes a las actuales, es un cambio
        if (currentCheckIn && extractedDates.checkIn !== currentCheckIn) {
            changes.checkIn = extractedDates.checkIn;
            changes.auditNotes.push(`check_in ${currentCheckIn}→${extractedDates.checkIn}`);
            hasChanges = true;
        }
        
        if (currentCheckOut && extractedDates.checkOut !== currentCheckOut) {
            changes.checkOut = extractedDates.checkOut;
            changes.auditNotes.push(`check_out ${currentCheckOut}→${extractedDates.checkOut}`);
            hasChanges = true;
        }
    }
    
    // Extraer tarifa del email
    const extractedAmount = extractAmountFromEmail(text, rawText);
    if (extractedAmount) {
        const currentAmount = reservation.total_amount;
        
        // Si el monto es diferente al actual (con tolerancia de 1%), es un cambio
        if (currentAmount && Math.abs(extractedAmount - currentAmount) > currentAmount * 0.01) {
            changes.totalAmount = extractedAmount;
            changes.auditNotes.push(`total_amount ${currentAmount}→${extractedAmount}`);
            hasChanges = true;
        }
    }
    
    return hasChanges ? changes : null;
}

/**
 * Actualiza el estado de una reserva y agrega nota de auditoría
 * @param {object} reservation - Reserva a actualizar
 * @param {string} newStatus - Nuevo estado ('Cancelada' o 'Confirmada')
 * @param {object} emailInfo - Información del correo
 * @param {string} cancellationNumber - Número de cancelación (opcional)
 * @param {object} dataChanges - Cambios en los datos de la reserva (fechas/tarifa) - opcional
 * @returns {object} - { ok: boolean, code: string, oldStatus: string, newStatus: string, dataChanged: [...] }
 */
async function updateReservationStatus(reservation, newStatus, emailInfo, cancellationNumber = null, dataChanges = null) {
    if (!supabase) {
        return { ok: false, error: 'Supabase no disponible' };
    }
    
    try {
        const now = new Date().toISOString();
        const dateStr = new Date().toLocaleDateString('es-AR', { 
            timeZone: 'America/Argentina/Buenos_Aires',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        });
        
        // Crear nota de auditoría
        let auditLine = `[${dateStr}] Auto-cerrado por email-monitor: ${emailInfo.fromName} (${emailInfo.from}) confirmó`;
        if (cancellationNumber) {
            auditLine += ` - N° cancelación: ${cancellationNumber}`;
        }
        
        // Agregar cambios de datos a la auditoría
        if (dataChanges && dataChanges.auditNotes && dataChanges.auditNotes.length > 0) {
            auditLine += `; ${dataChanges.auditNotes.join('; ')}`;
        }
        
        const existingNotes = reservation.notes || '';
        const updatedNotes = existingNotes 
            ? `${existingNotes}\n${auditLine}`
            : auditLine;
        
        // Preparar objeto de actualización
        const updateData = {
            status: newStatus,
            notes: updatedNotes,
            updated_at: now
        };
        
        // Agregar cambios de datos si existen
        if (dataChanges) {
            if (dataChanges.checkIn) {
                updateData.check_in = dataChanges.checkIn;
            }
            if (dataChanges.checkOut) {
                updateData.check_out = dataChanges.checkOut;
            }
            if (dataChanges.totalAmount) {
                updateData.total_amount = dataChanges.totalAmount;
            }
        }
        
        // Actualizar en Supabase
        const { error } = await supabase
            .from('reservations')
            .update(updateData)
            .eq('id', reservation.id);
        
        if (error) {
            throw error;
        }
        
        return {
            ok: true,
            code: reservation.reservation_code,
            oldStatus: reservation.status,
            newStatus: newStatus,
            hotel: reservation.hotel_name,
            customer: reservation.customer_name,
            dataChanged: dataChanges ? dataChanges.auditNotes : []
        };
    } catch (error) {
        console.error(`   ❌ Error actualizando reserva ${reservation.reservation_code}:`, error.message);
        return { 
            ok: false, 
            error: error.message,
            code: reservation.reservation_code 
        };
    }
}

/**
 * Procesa el auto-cierre de reservas si corresponde
 * @param {object} info - Información del correo extraída
 * @param {object} parsed - Email parseado completo
 * @returns {object|null} - Resultado del procesamiento o null si no aplica
 */
async function processAutoClose(info, parsed) {
    // Verificar si está habilitado
    if (!CONFIG.autoClose.enabled && !CONFIG.autoClose.dryRun) {
        return null;
    }
    
    // Verificar que no sea remitente interno
    const senderType = classifySender(info.from);
    if (senderType === 'internal') {
        return null;
    }
    
    // Extraer códigos de reserva
    const codes = extractReservationCodes(info.subject, info.rawText);
    if (codes.length === 0) {
        return { skipped: true, reason: 'no_codes_found' };
    }
    
    // Detectar si es una confirmación
    const confirmation = detectConfirmation(info.text, info.rawText, info.subject);
    if (!confirmation) {
        return { skipped: true, reason: 'not_a_confirmation', codes };
    }
    
    // Determinar el nuevo estado según el tipo de confirmación
    const newStatus = confirmation.action === 'cancelacion' ? 'Cancelada' : 'Confirmada';
    
    // Buscar reservas abiertas que coincidan con los códigos
    const matches = [];
    for (const code of codes) {
        const reservation = await findOpenReservation(code);
        if (reservation) {
            matches.push({ code, reservation });
        }
    }
    
    if (matches.length === 0) {
        return { 
            skipped: true, 
            reason: 'no_open_reservations_found', 
            codes,
            confirmation: confirmation.action
        };
    }
    
    // Extraer número de cancelación si está presente (solo para anulaciones)
    let cancellationNumber = null;
    if (confirmation.action === 'cancelacion') {
        const cancNumPattern = /n[°º]?\s*(?:de\s+)?(?:cancelación|cancelacion|anulación|anulacion)\s*:?\s*#?\s*(\d+)/i;
        const match = info.rawText.match(cancNumPattern);
        if (match) {
            cancellationNumber = match[1];
        }
    }
    
    const results = [];
    
    // Procesar cada reserva
    for (const { code, reservation } of matches) {
        // Determinar cambios de datos si es una modificación
        let dataChanges = null;
        if (confirmation.action === 'modificacion') {
            dataChanges = determineReservationChanges(reservation, info.rawText, info.text);
            
            // Si no se pueden determinar los cambios con certeza, NO cerrar automáticamente
            if (!dataChanges) {
                console.log(`   ⚠️  [AUTO-CLOSE] Modificación de ${code}: no se pudieron determinar cambios de datos, requiere revisión manual`);
                results.push({
                    skipped: true,
                    code,
                    reason: 'manual_review_required',
                    oldStatus: reservation.status,
                    hotel: reservation.hotel_name
                });
                continue;
            }
        }
        
        if (CONFIG.autoClose.dryRun && !CONFIG.dryRun) {
            const changesSummary = dataChanges && dataChanges.auditNotes.length > 0 
                ? ` (${dataChanges.auditNotes.join(', ')})` 
                : '';
            console.log(`   🧪 [AUTO-CLOSE DRY-RUN] Se cerraría: ${code} (${reservation.status} → ${newStatus})${changesSummary}`);
            results.push({
                dryRun: true,
                code,
                oldStatus: reservation.status,
                newStatus,
                hotel: reservation.hotel_name,
                dataChanged: dataChanges ? dataChanges.auditNotes : []
            });
        } else if (CONFIG.dryRun) {
            // Ya estamos en dry-run global, no duplicar el log
            results.push({
                dryRun: true,
                code,
                oldStatus: reservation.status,
                newStatus,
                hotel: reservation.hotel_name,
                dataChanged: dataChanges ? dataChanges.auditNotes : []
            });
        } else {
            // Actualizar para real
            const updateResult = await updateReservationStatus(
                reservation, 
                newStatus, 
                info, 
                cancellationNumber,
                dataChanges
            );
            results.push(updateResult);
            
            if (updateResult.ok) {
                const changesSummary = updateResult.dataChanged && updateResult.dataChanged.length > 0
                    ? ` (${updateResult.dataChanged.join(', ')})`
                    : '';
                console.log(`   ✅ Reserva ${code} cerrada: ${reservation.status} → ${newStatus}${changesSummary}`);
            } else {
                console.error(`   ❌ Error cerrando reserva ${code}:`, updateResult.error);
            }
        }
    }
    
    return {
        processed: true,
        action: confirmation.action,
        confidence: confirmation.confidence,
        newStatus,
        results,
        cancellationNumber
    };
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
 * Envía notificación por WhatsApp a los destinatarios correctos
 * Retorna: { sent: number, destinations: string[], type: 'group'|'providers'|'internal' }
 */
async function sendWhatsAppNotification(info, summary, autoCloseResult = null) {
    const routing = getWhatsAppDestinations(info.from);
    
    // Si es remitente interno, no enviar nada
    if (routing.type === 'internal') {
        return { sent: 0, destinations: [], type: 'internal' };
    }
    
    let autoCloseLines = '';
    
    // Agregar información de auto-cierre si se procesó
    if (autoCloseResult?.processed && autoCloseResult.results?.length > 0) {
        const successful = autoCloseResult.results.filter(r => r.ok || r.dryRun);
        if (successful.length > 0) {
            const isDryRun = successful[0].dryRun;
            const prefix = isDryRun ? '🧪 [DRY-RUN] ' : '✅ ';
            autoCloseLines = `\n\n${prefix}*Reserva(s) cerrada(s) en dashboard:*\n`;
            for (const res of successful) {
                const dataChangedInfo = res.dataChanged && res.dataChanged.length > 0 
                    ? ` (${res.dataChanged.join(', ')})` 
                    : '';
                autoCloseLines += `• ${res.code}: ${res.oldStatus} → *${res.newStatus}*${dataChangedInfo}\n`;
            }
        }
    }
    
    const message = `📧 *Nueva respuesta sobre reserva*

📨 *De:* ${info.fromName}
📧 *Email:* ${info.from}
📋 *Asunto:* ${info.subject}
👤 *Solicitado por:* ${info.requestedBy}

💬 *Resumen:*
${summary}${autoCloseLines}

📝 *Mensaje:*
${info.text.substring(0, 800)}${info.text.length > 800 ? '...' : ''}

⏰ ${new Date().toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' })}`;

    const results = [];
    
    for (const destination of routing.destinations) {
        try {
            const response = await axios.post(
                `${CONFIG.whatsapp.apiUrl}/api/send`,
                {
                    number: destination,
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
                results.push({ destination, success: true });
            } else {
                results.push({ destination, success: false, error: response.data?.error || 'Unknown error' });
            }
        } catch (error) {
            const errorMsg = error.response 
                ? `Error ${error.response.status}: ${error.response.data?.error || error.message}`
                : error.message;
            results.push({ destination, success: false, error: errorMsg });
        }
    }
    
    const successCount = results.filter(r => r.success).length;
    const failedDestinations = results.filter(r => !r.success);
    
    if (successCount === 0) {
        const firstError = failedDestinations[0]?.error || 'Error desconocido';
        throw new Error(`No se pudo enviar a ningún destinatario: ${firstError}`);
    }
    
    if (failedDestinations.length > 0) {
        console.warn(`   ⚠️  Enviado a ${successCount}/${routing.destinations.length} destinatarios`);
        failedDestinations.forEach(f => {
            console.warn(`      ❌ ${f.destination}: ${f.error}`);
        });
    }
    
    return {
        sent: successCount,
        destinations: routing.destinations,
        type: routing.type
    };
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
        
        // Verificar si es remitente interno (excluir)
        const routing = getWhatsAppDestinations(info.from);
        if (routing.type === 'internal') {
            return { status: 'internal', reason: 'Remitente interno excluido' };
        }
        
        // Verificar duplicados
        if (await isAlreadyProcessed(info.messageId)) {
            return { status: 'duplicate', messageId: info.messageId };
        }
        
        console.log(`\n📧 Procesando: ${info.subject}`);
        console.log(`   De: ${info.fromName} <${info.from}>`);
        console.log(`   ↩️  Es respuesta`);
        console.log(`   📍 Tipo: ${routing.type === 'group' ? 'HOTEL (grupo)' : 'PROVEEDOR (individual)'}`);
        console.log(`   👤 Solicitado por: ${info.requestedBy}`);
        
        // Generar resumen
        const summary = await generateAISummary(info);
        console.log(`   📝 Resumen: ${summary}`);
        
        // Procesar auto-cierre de reservas
        let autoCloseResult = null;
        if (CONFIG.autoClose.enabled || CONFIG.autoClose.dryRun) {
            autoCloseResult = await processAutoClose(info, parsed);
            if (autoCloseResult?.processed) {
                const successful = autoCloseResult.results.filter(r => r.ok || r.dryRun).length;
                console.log(`   🔄 Auto-cierre: ${successful} reserva(s) procesada(s) (${autoCloseResult.action})`);
            }
        }
        
        // Mostrar destino
        if (routing.type === 'group') {
            console.log(`   📲 Destino: Grupo ${routing.destinations[0]}`);
        } else if (routing.type === 'providers') {
            console.log(`   📲 Destino: ${routing.destinations.length} número(s) proveedor: ${routing.destinations.join(', ')}`);
        }
        
        // Modo mark-existing: solo registrar sin enviar
        if (CONFIG.markExisting) {
            try {
                await markAsProcessed(info, summary, 'marked_existing');
                console.log('   ✅ Marcado como existente (no se envía)');
                return { status: 'marked', info, summary, autoClose: autoCloseResult };
            } catch (error) {
                console.warn('   ⚠️  Error marcando como existente:', error.message);
                return { status: 'error', error: error.message };
            }
        }
        
        // Modo dry-run: mostrar pero no enviar
        if (CONFIG.dryRun) {
            console.log('   🧪 [DRY-RUN] No se envía a WhatsApp ni se marca como procesado');
            console.log(`\n   Mensaje que se enviaría:\n${'-'.repeat(60)}`);
            console.log(`De: ${info.fromName} <${info.from}>`);
            console.log(`Asunto: ${info.subject}`);
            console.log(`Solicitado por: ${info.requestedBy}`);
            console.log(`Tipo: ${routing.type === 'group' ? 'HOTEL -> Grupo' : 'PROVEEDOR -> Individual'}`);
            console.log(`Destino: ${routing.destinations.join(', ')}`);
            console.log(`Resumen: ${summary}`);
            if (autoCloseResult?.processed) {
                console.log(`Auto-cierre: ${autoCloseResult.results.length} reserva(s)`);
            }
            console.log(`Texto (primeros 200 chars): ${info.text.substring(0, 200)}...`);
            console.log('-'.repeat(60));
            return { status: 'dry-run', info, summary, routing, autoClose: autoCloseResult };
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
            const result = await sendWhatsAppNotification(info, summary, autoCloseResult);
            console.log(`   ✅ Notificado: ${result.sent} mensaje(s) enviado(s)`);
            
            // Actualizar estado a 'notified'
            await updateProcessedStatus(info.messageId, 'notified', null);
            
            return { status: 'notified', info, summary, result, autoClose: autoCloseResult };
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
    
    if (CONFIG.markExisting) {
        console.log('🏷️  Modo MARK-EXISTING activado: se marcarán correos sin enviar\n');
    }
    
    console.log('📋 Configuración:');
    console.log(`   IMAP: ${CONFIG.imap.auth.user}@${CONFIG.imap.host}`);
    console.log(`   Buzón: ${CONFIG.mailbox}`);
    console.log(`   Desde: hace ${CONFIG.sinceDays} días`);
    console.log(`   WhatsApp Grupo (hoteles): ${CONFIG.whatsapp.groupId || 'No configurado'}`);
    console.log(`   WhatsApp Números (proveedores): ${CONFIG.whatsapp.providerNumbers.join(', ')}`);
    console.log(`   Proveedores conocidos: ${CONFIG.providerDomains.join(', ')}`);
    console.log(`   Remitentes internos (excluidos): ${CONFIG.internalSenders.join(', ')}`);
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
            internal: 0,
            marked: 0,
            error: 0,
            'dry-run': 0
        };
        
        for (const uid of messages) {
            const result = await processEmail(uid, client);
            stats[result.status] = (stats[result.status] || 0) + 1;
        }
        
        // Resumen
        console.log('\n' + '='.repeat(60));
        console.log('📊 RESUMEN');
        console.log('='.repeat(60));
        console.log(`Total procesados: ${stats.total}`);
        
        if (CONFIG.markExisting) {
            console.log(`🏷️  Marcados como existentes: ${stats.marked}`);
        } else if (CONFIG.dryRun) {
            console.log(`🧪 Dry-run (se enviarían): ${stats['dry-run']}`);
        } else {
            console.log(`✅ Notificados: ${stats.notified}`);
        }
        
        console.log(`🔍 Filtrados: ${stats.filtered}`);
        console.log(`🏢 Internos (excluidos): ${stats.internal}`);
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

module.exports = { 
    monitor, 
    isReservationRelated, 
    cleanEmailText, 
    extractEmailInfo,
    extractReservationCodes,
    detectConfirmation,
    processAutoClose,
    extractDatesFromEmail,
    extractAmountFromEmail,
    determineReservationChanges
};
