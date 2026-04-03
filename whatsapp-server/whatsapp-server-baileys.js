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

const baileysLib = require('@whiskeysockets/baileys');
const {
    default: makeWASocket,
    DisconnectReason,
    useMultiFileAuthState,
    fetchLatestBaileysVersion
} = baileysLib;
/** Copia :device entre JIDs (LID→PN); reduce retries "message not available" en Business + LID. */
const transferDeviceFn = typeof baileysLib.transferDevice === 'function' ? baileysLib.transferDevice : null;
const jidNormalizedUserFn = typeof baileysLib.jidNormalizedUser === 'function' ? baileysLib.jidNormalizedUser : null;
let downloadMediaMessage;
try {
    downloadMediaMessage = baileysLib.downloadMediaMessage;
} catch (e) {
    downloadMediaMessage = null;
}
const { Boom } = require('@hapi/boom');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const os = require('os');
const qrcode = require('qrcode');
const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');
const { getLinkPreview } = require('link-preview-js');

console.log('🚀 Iniciando servidor WhatsApp con Baileys...');

// ===== CONFIGURACIÓN =====
const CONFIG = {
    PORT: process.env.PORT || 3001,
    INSTANCE_NUMBER: parseInt(process.env.INSTANCE_NUMBER) || 1,
    // URL base del servidor (para logging y referencias)
    // Si no se especifica, se construye automáticamente
    BASE_URL: process.env.BASE_URL || process.env.SERVER_URL || null,
    AUTO_REPLY: process.env.AUTO_REPLY !== undefined ? (process.env.AUTO_REPLY === 'true' || process.env.AUTO_REPLY === '1') : true,
    FLOR_ENABLED: process.env.FLOR_ENABLED !== undefined ? (process.env.FLOR_ENABLED === 'true' || process.env.FLOR_ENABLED === '1') : true,
    SAVE_MESSAGES: true,
    SAVE_TO_SUPABASE: true,
    USE_GEMINI_AI: true,
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
    // Default: Gemini 3.1 Flash-Lite (Google anunció apagado de Gemini 2.0 ~jun 2026). Override: GEMINI_MODEL o flor_ai_config en Supabase.
    GEMINI_MODEL: process.env.GEMINI_MODEL || 'gemini-3.1-flash-lite-preview',
    SUPABASE: {
        url: process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        anonKey: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4'
    },
    // URL de la imagen promocional para cotización (WhatsApp la incrusta al enviar el link). Si está vacía, se envía solo texto.
    IMAGEN_COTIZACION_URL: (process.env.IMAGEN_COTIZACION_URL || 'https://dashboard.checkin24hs.com/og-cotizar.jpg').trim() || null,
    // Slack: alertas cuando Flor escala a humano o no tiene dato técnico (noEntendido). Definir SLACK_WEBHOOK_URL en el servidor.
    SLACK_WEBHOOK_URL: (process.env.SLACK_WEBHOOK_URL || '').trim() || null,
    /** Prueba A/B: 1 = enviar Flor al mismo JID entrante (@lid) sin pasar a PN (si los retries siguen, probá esto). */
    FLOR_SEND_USE_REMOTE_JID_ONLY: process.env.FLOR_SEND_USE_REMOTE_JID_ONLY === '1'
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

// CORS: el middleware manual DEBE usar la misma lógica que cors(); si no, el preflight OPTIONS falla
// (ej. dashboard en https://dashboard.checkin24hs.com → POST /api/send).
const allowedOrigins = [
    'https://dashboard.checkin24hs.com',
    'http://dashboard.checkin24hs.com',
    'https://www.checkin24hs.com',
    'http://www.checkin24hs.com',
    'https://checkin24hs.com',
    'http://checkin24hs.com',
    'https://cotizar.checkin24hs.com',
    'http://cotizar.checkin24hs.com',
    'http://localhost:3000',
    'http://127.0.0.1:3000'
];

function isAllowedCorsOrigin(originRaw) {
    if (originRaw == null || String(originRaw).trim() === '') return true;
    const origin = String(originRaw).trim();
    if (allowedOrigins.includes(origin)) return true;
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)) return true;
    try {
        const u = new URL(origin);
        const h = u.hostname.toLowerCase();
        if (h === 'checkin24hs.com' || h.endsWith('.checkin24hs.com')) return true;
        if (h.includes('easypanel')) return true;
    } catch (e) { /* ignore */ }
    if (/dashboard|easypanel|checkin24hs/i.test(origin)) return true;
    return false;
}

/** Valor exacto para Access-Control-Allow-Origin (nunca mentir con otro dominio). */
function accessControlAllowOriginHeader(originRaw) {
    if (originRaw == null || String(originRaw).trim() === '') return '*';
    const origin = String(originRaw).trim();
    return isAllowedCorsOrigin(origin) ? origin : null;
}

function corsOrigin(origin, cb) {
    if (!origin) return cb(null, true);
    if (isAllowedCorsOrigin(origin)) return cb(null, true);
    return cb(null, false);
}

const CORS_ALLOW_HEADERS = 'Content-Type, Authorization, Accept, X-Requested-With';
const CORS_ALLOW_METHODS = 'GET, POST, OPTIONS, PUT, DELETE';

// Primero: OPTIONS y cabeceras en TODAS las respuestas (incl. preflight desde el dashboard).
app.use((req, res, next) => {
    const origin = req.headers.origin;
    const allowOrigin = accessControlAllowOriginHeader(origin);
    if (allowOrigin) {
        res.setHeader('Access-Control-Allow-Origin', allowOrigin);
    }
    res.setHeader('Access-Control-Allow-Methods', CORS_ALLOW_METHODS);
    res.setHeader('Access-Control-Allow-Headers', CORS_ALLOW_HEADERS);
    res.setHeader('Access-Control-Max-Age', '86400');
    res.setHeader('Vary', 'Origin');
    if (req.method === 'OPTIONS') {
        return res.status(204).end();
    }
    next();
});
// Segundo: sin credentials para evitar choque con Allow-Origin en fetch del dashboard (mode cors por defecto).
app.use(cors({
    origin: corsOrigin,
    methods: ['GET', 'POST', 'OPTIONS', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    credentials: false
}));

app.options('*', (req, res) => {
    const origin = req.headers.origin;
    const allowOrigin = accessControlAllowOriginHeader(origin);
    if (allowOrigin) res.setHeader('Access-Control-Allow-Origin', allowOrigin);
    res.setHeader('Access-Control-Allow-Methods', CORS_ALLOW_METHODS);
    res.setHeader('Access-Control-Allow-Headers', CORS_ALLOW_HEADERS);
    res.status(204).end();
});

// Límite alto para /api/send-media (archivos en base64 ~33% más grandes que el original)
app.use(express.json({ limit: '30mb' }));

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
let isSyncingAppState = false; // Flag para indicar si se está sincronizando el app state

// Delay antes de que Flor responda (ms). El usuario puede hacer todas las consultas que quiera en la misma conversación.
// Si en esos 5s llega 1 solo mensaje → Flor responde esa consulta y queda atenta a la siguiente.
// Si llegan varios en ese lapso → se acumulan y Flor responde a todos juntos. Sin límite de consultas por usuario.
const FLOR_DELAY_MS = Math.max(0, parseInt(process.env.FLOR_DELAY_MS, 10) || 5000);
const FLOR_SILENCE_MINUTES = Math.max(1, parseInt(process.env.FLOR_SILENCE_MINUTES || '30', 10) || 30);
/** Mínimo de tokens de salida Gemini para no cortar descripciones (puede subir con FLOR_MAX_OUTPUT_TOKENS o Supabase flor_ai_config.maxTokens) */
const FLOR_MAX_OUTPUT_TOKENS_MIN = Math.max(256, parseInt(process.env.FLOR_MAX_OUTPUT_TOKENS_MIN || '1500', 10) || 1500);

/** Ventana deslizante para errores cripto/sesión (Bad MAC, decrypt). Resumen en log + campo en /health. */
const FLOR_SESSION_CRYPTO_WINDOW_MS = Math.max(60_000, parseInt(process.env.FLOR_SESSION_CRYPTO_WINDOW_MS || '300000', 10) || 300_000);
const FLOR_SESSION_CRYPTO_SUMMARY = process.env.FLOR_SESSION_CRYPTO_SUMMARY !== '0' && process.env.FLOR_SESSION_CRYPTO_SUMMARY !== 'false';
const _origConsoleErrorForFlor = console.error.bind(console);
const florSessionCryptoIssueTimes = [];
let florSessionCryptoLastSummaryAt = 0;

function florSessionCryptoNormalizeDetail(args) {
    return args.map((a) => {
        if (typeof a === 'string') return a;
        if (a && typeof a === 'object') {
            if (a.msg) return String(a.msg);
            if (a.err && a.err.message) return String(a.err.message);
            try {
                return JSON.stringify(a);
            } catch (e) {
                return String(a);
            }
        }
        return String(a);
    }).join(' ');
}

function florSessionCryptoIsMatch(text) {
    return /Bad MAC|failed to decrypt|SessionError|No matching sessions|Session error:\s*Error:\s*Bad MAC/i.test(String(text || ''));
}

function pruneFlorSessionCryptoIssueTimes() {
    const now = Date.now();
    while (florSessionCryptoIssueTimes.length && florSessionCryptoIssueTimes[0] < now - FLOR_SESSION_CRYPTO_WINDOW_MS) {
        florSessionCryptoIssueTimes.shift();
    }
}

function recordFlorSessionCryptoIssue(detail) {
    if (!FLOR_SESSION_CRYPTO_SUMMARY) return;
    const now = Date.now();
    pruneFlorSessionCryptoIssueTimes();
    florSessionCryptoIssueTimes.push(now);
    const n = florSessionCryptoIssueTimes.length;
    const shouldLog =
        n === 1 ||
        n === 5 ||
        n === 15 ||
        n === 30 ||
        (n % 50 === 0) ||
        (now - florSessionCryptoLastSummaryAt > 120_000 && n >= 3);
    if (shouldLog) {
        florSessionCryptoLastSummaryAt = now;
        const winMin = Math.max(1, Math.round(FLOR_SESSION_CRYPTO_WINDOW_MS / 60000));
        _origConsoleErrorForFlor(
            `🔐 Flor: ${n} evento(s) cripto/sesión en ~${winMin} min (Bad MAC / decrypt). ` +
                `Si crece: 1 réplica, volumen auth estable, deploy stop-first; si sigue: reset auth+QR. ` +
                `Muestra: ${String(detail).slice(0, 180)}`
        );
    }
}

function getFlorSessionCryptoIssueCount() {
    pruneFlorSessionCryptoIssueTimes();
    return florSessionCryptoIssueTimes.length;
}

function createFlorBaileysLogger() {
    const emit = (level, args) => {
        const [one] = args;
        const text = florSessionCryptoNormalizeDetail(args);
        if (florSessionCryptoIsMatch(text)) recordFlorSessionCryptoIssue(text.slice(0, 300));
        if (typeof one === 'object' && one !== null && one.msg !== undefined) {
            const line = JSON.stringify(one);
            if (level === 'error' || level === 'fatal') _origConsoleErrorForFlor(line);
            else if (level === 'warn') console.warn(line);
            else console.log(line);
            return;
        }
        if (level === 'error' || level === 'fatal') _origConsoleErrorForFlor(...args);
        else if (level === 'warn') console.warn(...args);
        else console.log(...args);
    };
    const base = {};
    for (const level of ['trace', 'debug', 'info', 'warn', 'error', 'fatal']) {
        base[level] = (...args) => emit(level, args);
    }
    base.child = () => createFlorBaileysLogger();
    return base;
}

if (FLOR_SESSION_CRYPTO_SUMMARY) {
    console.error = function (...args) {
        try {
            const text = florSessionCryptoNormalizeDetail(args);
            if (florSessionCryptoIsMatch(text)) recordFlorSessionCryptoIssue(text.slice(0, 300));
        } catch (e) { /* ignore */ }
        return _origConsoleErrorForFlor.apply(console, args);
    };
}

const florPendingByUser = new Map(); // key: remoteJid -> { timeoutId, messages: [{texto, ts}], nombre, numero }
/** Silencio Flor: respaldo en RAM si aún no existe fila en whatsapp_chats (clave: solo dígitos, ≥10) */
const florPauseMemoryUntil = new Map();
/** JID del chat (remoteJid / variante) → +E.164 real; evita pausar con PN interno (ej. 133397…@s.whatsapp.net) en mensajes salientes del humano */
const florJidToRealPhoneForPause = new Map();
const FLOR_JID_PHONE_CACHE_MAX = 8000;

function rememberFlorChatJidToPhone(remoteJid, phoneE164) {
    if (!remoteJid || !phoneE164) return;
    const d = String(phoneE164).replace(/\D/g, '');
    if (d.length < 10 || d.length > 15) return;
    const normalized = '+' + d;
    const j = String(remoteJid).trim().toLowerCase();
    const local = j.replace(/@s\.whatsapp\.net$/i, '').replace(/@lid$/i, '').trim();
    const keys = new Set([j, local, `${local}@s.whatsapp.net`, `${local}@lid`].filter(Boolean));
    for (const k of keys) {
        florJidToRealPhoneForPause.set(k, normalized);
    }
    while (florJidToRealPhoneForPause.size > FLOR_JID_PHONE_CACHE_MAX) {
        const first = florJidToRealPhoneForPause.keys().next().value;
        if (first == null) break;
        florJidToRealPhoneForPause.delete(first);
    }
}

/** LID @lid → JID *@s.whatsapp.net para envíos (senderPn a veces hidrata después; evita "Esperando mensaje"). */
const florLidToPnSendJid = new Map();
const FLOR_LID_PN_SEND_MAX = 4000;
function rememberLidPnForSend(remoteJid, pnJid) {
    if (!remoteJid || !pnJid || !String(remoteJid).includes('@lid')) return;
    if (!String(pnJid).includes('@s.whatsapp.net') || String(pnJid).includes('@lid')) return;
    const k = String(remoteJid).trim().toLowerCase();
    florLidToPnSendJid.set(k, pnJid);
    while (florLidToPnSendJid.size > FLOR_LID_PN_SEND_MAX) {
        const first = florLidToPnSendJid.keys().next().value;
        if (first == null) break;
        florLidToPnSendJid.delete(first);
    }
}

/** JID entrante con :device si existe (mejor fuente para transferDevice). */
function pickFromJidForDeviceTransfer(p) {
    let best = p.remoteJid && String(p.remoteJid);
    for (const e of p.messages || []) {
        const rj = e.msg?.key?.remoteJid && String(e.msg.key.remoteJid);
        if (rj && rj.includes(':') && (rj.includes('@lid') || rj.includes('@s.whatsapp.net'))) {
            best = rj;
            break;
        }
    }
    return best || p.remoteJid;
}

/**
 * Chat entró como @lid y resolvemos envío a *@s.whatsapp.net: copiar :device del JID entrante (Baileys).
 * Sin esto, a veces hay retries "message not available" y el cliente queda en "Esperando mensaje".
 */
function applyFlorDestJidDeviceTransfer(p, destJid) {
    if (!p?.remoteJid || !destJid || !transferDeviceFn) return destJid;
    const from = pickFromJidForDeviceTransfer(p);
    const to = String(destJid);
    try {
        if (String(from).includes('@lid') && to.includes('@s.whatsapp.net') && !to.includes('@lid')) {
            const toBase = jidNormalizedUserFn ? jidNormalizedUserFn(to) : to;
            const merged = transferDeviceFn(from, toBase || to);
            if (merged && merged !== to) {
                console.log(`📤 Flor: transferDevice (LID→PN) ${from.split('@')[0]} → ${merged}`);
            }
            return merged || destJid;
        }
    } catch (e) {
        console.warn('⚠️ transferDevice Flor:', e?.message || e);
    }
    return destJid;
}

/** PN sin :device → JID canónico con dispositivo (evita retries "message not available" en Business). */
async function enrichPnJidWithOnWhatsApp(sock, pnJidBare) {
    if (!sock || typeof sock.onWhatsApp !== 'function' || !pnJidBare || !String(pnJidBare).includes('@s.whatsapp.net')) {
        return pnJidBare;
    }
    if (String(pnJidBare).includes('@lid')) return pnJidBare;
    try {
        const r = await sock.onWhatsApp(pnJidBare);
        const arr = Array.isArray(r) ? r : r ? [r] : [];
        const j = arr.find((x) => x && x.jid && String(x.jid).includes('@s.whatsapp.net') && !String(x.jid).includes('@lid'));
        if (j?.jid && j.jid !== pnJidBare) {
            console.log(`📤 Flor: onWhatsApp enriqueció PN → ${j.jid}`);
            return j.jid;
        }
    } catch (e) {
        console.warn('⚠️ enrichPnJidWithOnWhatsApp:', e?.message || e);
    }
    return pnJidBare;
}

/** Primer argumento de sock.sendMessage: string JID u objeto con jid/remoteJid. */
function extractDestJidFromSendArgs(args) {
    const a0 = args && args[0];
    if (typeof a0 === 'string') return a0.trim();
    if (a0 && typeof a0 === 'object') {
        const j = a0.remoteJid || a0.jid || a0.key?.remoteJid;
        if (typeof j === 'string') return j.trim();
    }
    return '';
}

/**
 * Tras enviar, WA puede usar otro @lid que el del destino; enlazar todos los JID encontrados al +E.164 del cliente.
 */
function collectJidStringsForFlorPauseMap(obj, depth, visited, outSet) {
    if (depth > 8 || !obj || typeof obj !== 'object') return;
    try {
        if (visited.has(obj)) return;
        visited.add(obj);
    } catch (e) {
        return;
    }
    if (Array.isArray(obj)) {
        for (let i = 0; i < obj.length; i++) collectJidStringsForFlorPauseMap(obj[i], depth + 1, visited, outSet);
        return;
    }
    for (const v of Object.values(obj)) {
        if (typeof v === 'string') {
            const s = v.trim();
            if (s.length >= 12 && s.length <= 120 && /\d{8,}@(lid|s\.whatsapp\.net)$/i.test(s)) outSet.add(s);
        } else if (v && typeof v === 'object') {
            collectJidStringsForFlorPauseMap(v, depth + 1, visited, outSet);
        }
    }
}

/**
 * processPending borra florPendingByUser al arrancar (antes de los sendMessage), así que el wrapper de sendMessage
 * no puede usar la cola. Esta pila vive durante todo el envío Flor y enlaza cualquier @lid (incl. el que usa WA al salir).
 */
let florDispatchStack = [];

function pruneFlorDispatchStack() {
    const now = Date.now();
    const maxAge = 15 * 60 * 1000;
    florDispatchStack = florDispatchStack.filter((x) => now - x.startedAt < maxAge);
}

function pushFlorDispatchContext(remoteJid, phoneE164) {
    if (!remoteJid || !phoneE164) return;
    pruneFlorDispatchStack();
    const nd = String(phoneE164).replace(/\D/g, '');
    if (nd.length < 10 || isLikelyPseudoWhatsappPn(nd) || isOurBotPhoneDigits(nd)) return;
    const e164 = String(phoneE164).startsWith('+') ? phoneE164 : '+' + nd;
    florDispatchStack.push({
        remoteJidLower: String(remoteJid).trim().toLowerCase(),
        phoneE164: e164,
        startedAt: Date.now()
    });
}

function popFlorDispatchContext(remoteJid) {
    if (!remoteJid) return;
    const want = String(remoteJid).trim().toLowerCase();
    const i = florDispatchStack.findIndex((x) => x.remoteJidLower === want);
    if (i >= 0) florDispatchStack.splice(i, 1);
}

/** Si hay un solo envío Flor activo y el @lid no coincide con el entrante, igual usamos su +E.164 (WA usa otro LID al salir). */
function peekFlorDispatchPhoneForLid(destJid) {
    const d = String(destJid || '').trim().toLowerCase();
    if (!d.includes('@lid')) return null;
    pruneFlorDispatchStack();
    for (const x of florDispatchStack) {
        if (x.remoteJidLower === d) return x.phoneE164;
    }
    if (florDispatchStack.length === 1) return florDispatchStack[0].phoneE164;
    return null;
}

/**
 * Teléfono +E.164 del destino de sendMessage (Flor/API): para @lid usa LID store o pila de dispatch Flor.
 */
function resolvePhoneForFlorSendDestination(sock, destJid) {
    const dest = String(destJid || '').trim();
    if (!dest || dest.includes('@g.us') || dest === 'status@broadcast') return null;
    if (dest.includes('@s.whatsapp.net')) {
        const e = jidPnToE164(dest.includes('@') ? dest : `${dest}@s.whatsapp.net`);
        if (e && !isOurBotPhoneDigits(e.replace(/^\+/, ''))) return e;
        return null;
    }
    if (dest.includes('@lid')) {
        const fromStore = resolveLidToPhone(sock, dest);
        if (fromStore) {
            const d = String(fromStore).replace(/\D/g, '');
            if (d.length >= 10 && !isLikelyPseudoWhatsappPn(d) && !isOurBotPhoneDigits(d)) return '+' + d;
        }
        const fromDispatch = peekFlorDispatchPhoneForLid(dest);
        if (fromDispatch) return fromDispatch;
        const destLow = dest.toLowerCase();
        for (const pend of florPendingByUser.values()) {
            const rj = pend.remoteJid && String(pend.remoteJid).trim();
            if (!rj) continue;
            if (rj.toLowerCase() !== destLow) continue;
            const num = pend.numero;
            if (!num) continue;
            const nd = String(num).replace(/\D/g, '');
            if (nd.length >= 10 && !isLikelyPseudoWhatsappPn(nd) && !isOurBotPhoneDigits(nd)) {
                return num.startsWith('+') ? num : '+' + nd;
            }
        }
    }
    return null;
}
/** Mensajes enviados por sock.sendMessage en este proceso: el eco fromMe trae el mismo id; no es “humano en celular”. */
const florOutboundBaileysMessageIds = new Map(); // id -> expiry timestamp
/** TTL del registro de IDs salientes (ms). Ecos pueden llegar tarde (append) o con id distinto; default 15 min. */
const FLOR_OUTBOUND_BAILEYS_ID_TTL_MS = Math.max(
    5 * 60 * 1000,
    Math.min(30 * 60 * 1000, parseInt(process.env.FLOR_OUTBOUND_ID_TTL_MS || '900000', 10) || 900000)
);
/** Tras pausar desde /api/send|audio|media, el eco fromMe a veces no coincide en msg.id; evitar doble pausa/log. */
const recentDashboardFlorPauseByDigits = new Map(); // dígitos E.164 -> expiry
const RECENT_DASHBOARD_PAUSE_WINDOW_MS = 120000;
/** Ecos fromMe (mismo msgId) pueden entrar varias veces (notify + append); evita logs/pausas duplicadas. */
const recentHumanSilenceFromMeByMsgId = new Map();
const HUMAN_SILENCE_FROM_ME_DEDUPE_MS = Math.max(
    60_000,
    Math.min(300_000, parseInt(process.env.FLOR_HUMAN_FROMME_DEDUPE_MS || '120000', 10) || 120000)
);

function normalizeBaileysMessageId(id) {
    if (id == null || id === '') return null;
    if (Buffer.isBuffer(id)) return id.toString('hex');
    return String(id);
}

/**
 * Recoge key.id de la respuesta de sendMessage (objeto, array o { messages: [] }) sin recorrer el proto completo.
 */
function collectMessageIdsFromBaileysSendResult(res, out) {
    if (res == null) return;
    if (Array.isArray(res)) {
        for (let i = 0; i < res.length; i++) collectMessageIdsFromBaileysSendResult(res[i], out);
        return;
    }
    if (typeof res !== 'object') return;
    try {
        const k = res.key;
        if (k && k.id != null && k.id !== '') {
            const n = normalizeBaileysMessageId(k.id);
            if (n) out.add(n);
        }
    } catch (e) { /* ignore */ }
    if (Array.isArray(res.messages)) {
        for (let j = 0; j < res.messages.length; j++) collectMessageIdsFromBaileysSendResult(res.messages[j], out);
    }
}

function pruneFlorOutboundBaileysIdMap() {
    const now = Date.now();
    for (const [id, exp] of florOutboundBaileysMessageIds) {
        if (exp <= now) florOutboundBaileysMessageIds.delete(id);
    }
    while (florOutboundBaileysMessageIds.size > 10000) {
        const first = florOutboundBaileysMessageIds.keys().next().value;
        if (first == null) break;
        florOutboundBaileysMessageIds.delete(first);
    }
}

function markRecentDashboardFlorPause(phoneRaw) {
    const d = String(phoneRaw || '').replace(/\D/g, '');
    if (d.length < 10) return;
    recentDashboardFlorPauseByDigits.set(d, Date.now() + RECENT_DASHBOARD_PAUSE_WINDOW_MS);
    for (const [k, exp] of recentDashboardFlorPauseByDigits) {
        if (exp <= Date.now()) recentDashboardFlorPauseByDigits.delete(k);
    }
}

function shouldSkipFromMePauseBecauseRecentDashboard(primaryForDb, jidDigits) {
    const d1 = primaryForDb ? String(primaryForDb).replace(/\D/g, '') : '';
    const d2 = jidDigits ? String(jidDigits).replace(/\D/g, '') : '';
    const now = Date.now();
    for (const d of [d1, d2]) {
        if (d.length < 10) continue;
        const exp = recentDashboardFlorPauseByDigits.get(d);
        if (exp && exp > now) return true;
    }
    return false;
}

function pruneHumanSilenceFromMeDedupe() {
    const now = Date.now();
    for (const [id, exp] of recentHumanSilenceFromMeByMsgId) {
        if (exp <= now) recentHumanSilenceFromMeByMsgId.delete(id);
    }
}

function shouldSkipFromMeHumanSilenceDuplicate(msgId) {
    const n = normalizeBaileysMessageId(msgId);
    if (!n) return false;
    pruneHumanSilenceFromMeDedupe();
    const exp = recentHumanSilenceFromMeByMsgId.get(n);
    if (exp && exp > Date.now()) return true;
    return false;
}

function markFromMeHumanSilenceProcessed(msgId) {
    const n = normalizeBaileysMessageId(msgId);
    if (!n) return;
    recentHumanSilenceFromMeByMsgId.set(n, Date.now() + HUMAN_SILENCE_FROM_ME_DEDUPE_MS);
    pruneHumanSilenceFromMeDedupe();
}

function florPauseMemoryTouch(phone) {
    florPauseMemoryTouchMany(phone);
}
/** Pausa Flor en RAM bajo todas las variantes de número (evita mismatch LID vs +E.164 al comparar con mensajes entrantes). */
function florPauseMemoryTouchMany(...phones) {
    const until = Date.now() + FLOR_SILENCE_MINUTES * 60 * 1000;
    const seen = new Set();
    for (const phone of phones) {
        if (phone == null || phone === '') continue;
        for (const c of normalizarCandidatosTelefono(phone)) {
            const d = String(c).replace(/\D/g, '');
            if (d.length >= 10 && !seen.has(d)) {
                seen.add(d);
                florPauseMemoryUntil.set(d, until);
            }
        }
    }
}
function florPauseMemoryIsActive(phone) {
    const now = Date.now();
    for (const c of normalizarCandidatosTelefono(phone)) {
        const d = String(c).replace(/\D/g, '');
        if (d.length < 10) continue;
        const u = florPauseMemoryUntil.get(d);
        if (u && u > now) return true;
    }
    return false;
}
function registerFlorOutboundBaileysMessageId(id) {
    const n = normalizeBaileysMessageId(id);
    if (!n) return;
    florOutboundBaileysMessageIds.set(n, Date.now() + FLOR_OUTBOUND_BAILEYS_ID_TTL_MS);
    pruneFlorOutboundBaileysIdMap();
}

function registerFlorOutboundBaileysMessageIdsFromSendResult(res) {
    const ids = new Set();
    collectMessageIdsFromBaileysSendResult(res, ids);
    for (const n of ids) {
        florOutboundBaileysMessageIds.set(n, Date.now() + FLOR_OUTBOUND_BAILEYS_ID_TTL_MS);
    }
    pruneFlorOutboundBaileysIdMap();
}

function isFlorOutboundBaileysMessageId(id) {
    const n = normalizeBaileysMessageId(id);
    if (!n) return false;
    const exp = florOutboundBaileysMessageIds.get(n);
    if (exp && exp > Date.now()) return true;
    if (exp) florOutboundBaileysMessageIds.delete(n);
    return false;
}
if (FLOR_DELAY_MS > 0) {
    console.log(`⏱️ Flor: delay ${FLOR_DELAY_MS}ms para agrupar mensajes. Usuario puede consultar las veces que quiera; 1 mensaje → 1 respuesta, varios en ${FLOR_DELAY_MS}ms → respuesta a todos.`);
}
console.log(`⏸️ Flor: silencio tras intervención humana = ${FLOR_SILENCE_MINUTES} min (env FLOR_SILENCE_MINUTES). Registro de ids salientes ${Math.round(FLOR_OUTBOUND_BAILEYS_ID_TTL_MS / 60000)} min (FLOR_OUTBOUND_ID_TTL_MS). Mín. tokens salida = ${FLOR_MAX_OUTPUT_TOKENS_MIN} (+ flor_ai_config / FLOR_MAX_OUTPUT_TOKENS).`);
if (FLOR_SESSION_CRYPTO_SUMMARY) {
    console.log(`🔐 Flor: resumen cripto/sesión cada ~${Math.round(FLOR_SESSION_CRYPTO_WINDOW_MS / 60000)} min en /health (florSessionCryptoIssuesLastWindow). Desactivar: FLOR_SESSION_CRYPTO_SUMMARY=0. Ventana ms: FLOR_SESSION_CRYPTO_WINDOW_MS.`);
}

// Prompt mínimo (spec: conocimiento en servidor, Flor como "capa de lenguaje"). Usado si no hay flor_general_config en Supabase.
const FLOR_PROMPT_DEFAULT = `Eres **Flor IA** 🌸, asistente virtual de **Checkin24hs**. Tono de lujo: amable, profesional y fluido.

**1. Identidad y fuente de verdad:**
Solo actuás como capa de lenguaje. NUNCA inventes hoteles. Para cualquier dato de hotel o destino debés usar la función consultarCatalogoHoteles. Si el resultado es nulo o el hotel no existe en nuestra base: ofrecé alternativas de nivel similar sin dar nombres de la competencia. Respuesta exacta: "Por el momento no trabajamos directamente con ese hotel, pero contamos con opciones exclusivas de nivel similar en la zona. ¿Te gustaría que te cuente sobre nuestras alternativas disponibles?"

**2. Presentación (solo primer mensaje):**
Presentate como **Flor IA** 🌸 y da la bienvenida amable. En mensajes siguientes: PROHIBIDO volver a presentarte o saludar formalmente. Respondé directo a la consulta. Mantené el hilo.

**3. Fijación de Destino (MEMORIA):**
Si el cliente ya mencionó un hotel (ej: "Huilo Huilo"), TODOS los mensajes siguientes deben referirse a ESE hotel. PROHIBIDO preguntar "¿A qué destino te diriges?" si ya lo dijo antes. Usá siempre el historial de la conversación para no perder contexto.

**4. Negritas estratégicas:**
Usá **negritas** para resaltar: nombres de **Hoteles**, **Precios/Tarifas**, **Beneficios clave** (ej: "incluye **Pensión Completa**"), y **Promociones activas**. Esto mejora la lectura en WhatsApp.

**5. Misión y límites:**
Responder dudas sobre hoteles y servicios. PROHIBIDO dar precios por noche o cotizar directamente. PROHIBIDO dar teléfonos de hoteles o datos de contacto externos. Solo información de servicios y direcciones.

**6. Link de cotización (CTA):**
Solo enviá https://cotizar.checkin24hs.com/ cuando: pregunten por precios, cotización o reserva; o al cerrar un tema de venta; o cuando el cliente se muestre convencido ("me gusta", "lo voy a tomar", "perfecto", "quiero reservar"). NUNCA en saludos ni en respuestas informativas generales.

**7. Protocolo de cierre y silencio:**
Al enviar el link de cotización o cerrar la conversación, usá siempre: "¡Gracias por su consulta! 🙏". Después de un mensaje manual del asesor, Flor debe guardar **10 minutos de silencio** en ese chat antes de volver a intervenir. No repetir bloques informativos que ya se enviaron.

**8. Escalación a humano:**
Si piden "humano", "agente" o "asesor"; si no entendés la consulta tras un intento; si es una integración compleja → transferir de inmediato.

**9. Estilo:**
Sé clara y completa: en saludos o confirmaciones breves usá 2-4 oraciones; si el cliente pide detalle (programas, qué incluye, spa, políticas), podés extenderte hasta ~10 oraciones o una lista con viñetas para no cortar información útil. Emojis con mesura (1-2 por mensaje). No repitas bloques informativos ya enviados en la misma conversación.

**10. Trigger de alerta (reserva/asesor):**
Cuando detectes intención de reserva ("reservar", "confirmar", "hacer la reserva", "agendar") o pedido de asesor, el sistema disparará automáticamente una alerta al equipo de ventas. Vos respondé al cliente confirmando que lo conectás con un agente especializado.`;

// Reglas que se inyectan siempre (complementan prompt mínimo / Supabase).
const FLOR_REGLAS_PRIORIDAD = `
**VERIFICACIÓN OBLIGATORIA:** Nunca des por sentado qué incluye un programa. Ante "¿Qué incluye?" o "¿Qué programas hay?", ejecutá SIEMPRE consultarCatalogoHoteles o buscarHotel y leé la columna detalles_programas específica de ESE hotel. No respondas sin haber llamado la función.
**PROGRAMAS INVIERNO Y VERANO:** Los programas cargados en el panel (Ski Full, Pensión Completa, etc.) están en detalles_programas. Usá ese array para responder "qué incluye", tickets, equipo, pensión; diferenciá temporada invierno vs verano según lo que figure en los datos.
**PROHIBIDO INVENTAR (Anti-Alucinación):** Si la base de datos dice "Almuerzo de 3 tiempos", no digas "Almuerzo buffet". Usá las palabras exactas que aparecen en el sistema.
**OCULTAR "CEREBRO" (Output Leaking):** CRÍTICO: El usuario NUNCA debe ver nombres de funciones, código ni output interno. El resultado de consultarCatalogoHoteles y enviarDocumentoPorWhatsApp va SOLO a tu contexto. Respondé ÚNICAMENTE con texto humano natural. Prohibido incluir en tu respuesta: nombres de funciones (consultarCatalogoHoteles, enviarDocumentoPorWhatsApp), print(, default_api, JSON crudo, URLs de imagen (data:image, base64) ni ningún output técnico.
**MEMORIA DE HOTEL:** Si el usuario ya mencionó un hotel (ej: Puyehue), todos tus siguientes mensajes sobre "programas" deben referirse a ESE hotel. No preguntes "¿De qué hotel hablamos?" si ya te lo dijeron antes.
**PRECISIÓN EN LINKS:** No uses el texto [Link de Cotización]. Escribí siempre la URL completa: https://cotizar.checkin24hs.com/ para que sea clickeable.
**IMÁGENES DE HOTEL:** Cuando pregunten "cómo es el hotel", "foto del hotel", "imagen", "mostrame el hotel" - NUNCA incluyas en tu respuesta datos de imagen (URL, Base64, data:image). En su lugar llamá la función enviarImagenHotelPorWhatsApp con url=img_general del hotel (del resultado de consultarCatalogoHoteles) y nombre_hotel. El sistema enviará la imagen correctamente por WhatsApp.
**FOTO + TEXTO (multitarea):** Si el cliente pide "foto y detalle de Pensión Completa" o "imagen + texto" en un mismo mensaje, podés llamar EN EL MISMO TURNO consultarCatalogoHoteles Y enviarImagenHotelPorWhatsApp. El sistema procesa ambas; respondé con el resumen de Pensión Completa en texto humano y la imagen se enviará por separado.
**ÚNICA FUENTE DE VERDAD:** La única fuente de verdad para datos de hoteles es la función consultarCatalogoHoteles. No inventes ni adivines datos. Si la búsqueda falla o devuelve vacío, usá la frase de alternativas sin nombrar competencia; NUNCA inventes hoteles ni información.
**OBLIGATORIO:** Para información de hoteles o destinos usá SIEMPRE la función consultarCatalogoHoteles. Si preguntan "qué hoteles tienen" o "qué opciones hay", llamá la función SIN ubicación ni hotel_especifico: devuelve el listado completo. NUNCA respondas "necesito ubicación" en ese caso. Para "info de X" o un hotel/destino concreto, pasá el término (ej: Guilo, Huilo, Puyehue, Patagonia).
**VARIOS HOTELES:** Si la función devuelve varios=true con más de un hotel, NO des el detalle de uno solo. Preguntá: "¿Te referís a [nombre A] o a [nombre B]?" (o listá los nombres) para que el usuario elija.
**PROTOCOLO DE FORMATOS (programas/spa/detalles):** (1) Dá un resumen rápido con puntos (bullets). (2) Incluí siempre la "Nota Importante" (ej: vehículo 4x4 en Futangue) si aparece en la base. (3) Preguntá siempre: "¿Preferís que te envíe el detalle completo en PDF, imagen o seguimos por texto aquí?" Si eligen PDF, llamá **enviarDocumentoPorWhatsApp** con la URL del PDF (del resultado de consultarCatalogoHoteles) y un nombre amigable. El sistema enviará el archivo por WhatsApp. Si eligen texto, resumí el contenido.
**AJUSTE DE PARSING PARA PROGRAMAS (Parque Futangue y otros):**
- Prioridad de enumeración: al responder sobre programas, buscá ESPECÍFICAMENTE la sección que dice "Este programa incluye:" dentro del texto cargado en la base de datos.
- Integridad de nombres: PROHIBIDO generar nombres de marketing (ej. "Programa Romántico", "Escape para Dos") si NO están en la base. Usá ÚNICAMENTE los nombres cargados en el Dashboard (detalles_programas, flor_info.programas, etc.).
- Formato obligatorio al responder por programa: 1) **Nombre del Programa** (exacto al Dashboard). 2) **Lo que incluye:** Resumen fiel de los ítems cargados (Desayuno, Almuerzo, Cena, Spa, excursiones, etc.) según "Este programa incluye:". 3) **Aclaración de transporte:** Incluí SIEMPRE la advertencia del vehículo 4x4 que está al final del texto cargado (ej. Parque Futangue: acceso en 4x4 obligatorio).
**MANEJO DE BLOQUES COMPLETOS (programas):** Cuando la función devuelva detalles de programas (detalles_programas, descripcion con "Este programa incluye"), leé TODO el bloque de cada programa, NO solo el primer párrafo. Incluí siempre la sección "Este programa incluye" y el aviso de transporte (4x4) al final. NUNCA inventes beneficios que no figuren en el texto.
**ANUNCIOS (fb.me / instagram.com):** Si el cliente envía un link de anuncio (fb.me o instagram.com) o una imagen, podés recibir la imagen adjunta. Identificá si es Puyehue, Corralco o Huilo Huilo y respondé directamente sobre ese hotel sin preguntar de nuevo; usá consultarCatalogoHoteles con ese nombre si hace falta.
**SALUDO:** La presentación formal solo en el primer mensaje de la conversación. Después respondé directo al tema. Saludá y despedite con naturalidad; evitá respuestas tipo plantilla.
**LINK COTIZACIÓN:** Solo incluí el link de cotización cuando pidan precio, cotización o reserva, o al ofrecer cierre de venta. No en cada mensaje.
**FORMATO DE RESPUESTA:** Usá iconos con mesura (📍 mapa, ✅ beneficios, 🏔️ destino), puntos claros con viñetas cuando enumeres, y si el hotel tiene ubicación_maps incluí el link de mapas en tu respuesta. Mantené el tono narrativo de Flor (calidez, profesional).
**CAMPAMENTOS DE MARKETING:** Si el mensaje del cliente menciona campañas (ej: 25% OFF, Black Friday, Invierno, descuento, promoción), priorizá esa información: mencioná las promociones activas del hotel que figuren en consultarCatalogoHoteles (campo promociones) y adaptá la respuesta a la campaña.
**EMOJIS:** Con mesura (uno o dos por mensaje como máximo).`;

// Protocolo de Ventas, Objeciones y Cierre (reglas comerciales inyectadas siempre; aplican a texto y audio).
const FLOR_PROTOCOLO_VENTAS = `
**PROTOCOLO DE VENTAS, OBJECIONES Y CIERRE**

1) **Reglas generales de interacción**
- Empatía ante todo: Validá siempre el sentimiento del cliente antes de dar una solución técnica.
- Valor sobre precio: Antes de justificar un costo, resaltá la mística y exclusividad de la experiencia Checkin24hs.
- Prohibición de bloqueos: NUNCA ofrezcas "bloquear habitaciones". Hablá de "asegurar disponibilidad" o "congelar la tarifa actual".

2) **Manejo de objeciones** (respondé según la situación):
- "Es muy caro / Fuera de presupuesto": Ser empática. Resaltar que son hoteles de experiencia, no solo cama. Ofrecer comparar con otro hotel del catálogo más accesible (ej. Puyehue vs Huilo Huilo) o sugerir menos noches.
- "Por esa plata me voy al Caribe o Europa": No competir con el destino. Resaltar la exclusividad de la Patagonia, la arquitectura única y la comodidad de la cercanía (sin escalas largas ni jet lag). Es una escapada premium cerca de casa.
- "En la página del hotel está más barato": Informar sobre nuestros convenios directos. Pedir amablemente una captura de pantalla. Auditar: ¿Es la misma fecha? ¿Mismo programa (ej. Seres Mágicos)? ¿Misma habitación? Si es idéntico, confirmar que podemos igualar la tarifa oficial.
- "Dudas por el clima (lluvia/frío)": Transformar en experiencia. Explicar que los hoteles están diseñados para disfrutar la lluvia: piscinas termales, spas con vista al bosque y gastronomía de primer nivel.
- "Lo tengo que consultar con mi familia": Validar la decisión. Ofrecer proactivamente enviar los PDFs de excursiones/programas para que el cliente tenga material visual para mostrar en casa.

3) **Protocolos de cierre (Call to Action)** — Usá estos gatillos para no dejar la charla en la nada:
- Gatillo de disponibilidad: "Como son hoteles muy icónicos, la disponibilidad cambia minuto a minuto. ¿Te gustaría que te ayude a asegurar esta tarifa ahora?"
- Gatillo de promoción: "Recordá que el beneficio de [Nombre de Promo] es por tiempo limitado. ¿Querés que verifiquemos tus fechas antes de que termine?"
- Gatillo de derivación humana: Si el cliente ya tiene toda la info pero no avanza: "Si preferís, puedo pedirle a uno de mis compañeros expertos que te llame para cerrar los detalles finales del pago. ¿Te parece bien?"
- **CTA OBLIGATORIO:** Cuando el cliente muestre interés o se declare convencido (ej: "me gusta", "lo voy a tomar", "perfecto", "quiero reservar", "me convenció"), SIEMPRE incluir el link de cotización: https://cotizar.checkin24hs.com/

4) **Verificación ante captura de precio más bajo:** Cuando el usuario mande una captura de precio más bajo, Flor debe preguntar para auditar:
- ¿La tarifa es por persona o por habitación doble?
- ¿Qué plan de comidas incluye (MAP, Pensión Completa, Desayuno)?
- ¿La política de cancelación es la misma?
`;

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

// Cache de integraciones por hotel (system_config + hotels.flor_info). TTL 2 min para que cambios se reflejen rápido.
const FLOR_INTEGRATIONS_CACHE = { data: null, ts: 0 };
const FLOR_INTEGRATIONS_CACHE_TTL_MS = 2 * 60 * 1000;

// Respuestas por defecto (usadas si no hay en Supabase)
const FLOR_RESPONSES_DEFAULTS = {
    noEntendido: 'Lo siento, no he podido entender tu consulta. ¿Podrías reformularla o prefieres que te conecte con un agente humano?',
    rateLimitExceeded: 'Estoy recibiendo muchas consultas ahora. Por favor intentá de nuevo en un minuto, o si preferís te conecto con un agente humano.',
    saludo: '¡Hola! Soy **Flor 🌸**, tu asistente de **Checkin24hs**. Estoy aquí para ayudarte a planificar tu escapada ideal hacia el relax y la naturaleza de la Patagonia. 🏔️✨ ¿Tenés algún hotel en mente (como Puyehue o Huilo Huilo) o te gustaría que te recomiende un refugio mágico para descansar?',
    transferir: 'Entendido, voy a transferirte con uno de nuestros agentes. Por favor espera un momento.',
    despedida: '¡Gracias por su consulta! 🙏 Si tienes más preguntas, estaré aquí para ayudarte. ¡Hasta pronto!',
    audioFallback: 'Disculpa, el audio no fue del todo claro. Para atenderte con la rapidez que mereces, ¿podrías enviarme tu consulta por escrito, o prefieres que te conecte con un agente ahora mismo?',
    audioProcessing: 'Un momento, estoy escuchando tu mensaje de voz... 🎧',
    imageFallback: 'No pude identificar claramente la imagen. ¿Podrías describirme qué estás buscando o enviar otra foto con mejor iluminación?',
    imageProcessing: 'Un momento, estoy analizando la imagen... 🔍',
    imageHotelFound: '¡Reconozco esa imagen! Se trata de {nombre_hotel}. Te cuento más sobre este hotel:',
    imageSending: 'Aquí te muestro una foto de {nombre_hotel}:',
    imageNotAvailable: 'Lo siento, no tengo imágenes disponibles de este hotel en este momento. ¿Te gustaría que te conecte con un agente que pueda mostrarte fotos?'
};

/**
 * Prioridad de Integraciones: Obtener integraciones desde system_config Y hotels.flor_info (doble fuente).
 * Retorna: { hotelId: { specificIntegrations: [...], name? } }
 */
async function obtenerIntegracionesPorHotel() {
    const now = Date.now();
    if (FLOR_INTEGRATIONS_CACHE.data && (now - FLOR_INTEGRATIONS_CACHE.ts) < FLOR_INTEGRATIONS_CACHE_TTL_MS) {
        return FLOR_INTEGRATIONS_CACHE.data;
    }
    const merged = {};
    if (supabase) {
        try {
            const { data, error } = await supabase
                .from('system_config')
                .select('value')
                .eq('key', 'flor_hotel_knowledge')
                .single();
            if (!error && data?.value) {
                const parsed = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
                if (typeof parsed === 'object' && parsed !== null) {
                    for (const [hid, v] of Object.entries(parsed)) {
                        if (v?.specificIntegrations?.length) merged[String(hid)] = { ...v };
                    }
                }
            }
        } catch (e) { console.warn('⚠️ flor_hotel_knowledge:', e?.message || e); }
        try {
            const { data: hotels } = await supabase.from('hotels').select('id, name, flor_info');
            for (const h of hotels || []) {
                const fi = h.flor_info || {};
                const ints = fi.specificIntegrations || [];
                const hid = String(h.id);
                if (ints.length > 0) {
                    if (!merged[hid] || !merged[hid].specificIntegrations?.length) {
                        merged[hid] = merged[hid] || {};
                        merged[hid].specificIntegrations = ints;
                    }
                }
                // Siempre asignar nombre para hoteles en merged (venga de system_config o hotels)
                if (merged[hid] && h.name) merged[hid].name = String(h.name).trim();
            }
        } catch (e) { console.warn('⚠️ integraciones desde hotels:', e?.message || e); }
        // Completar nombres para hoteles que vienen solo de system_config
        for (const hid of Object.keys(merged)) {
            if (!merged[hid]?.name && supabase) {
                try {
                    const { data: h } = await supabase.from('hotels').select('name').eq('id', hid).single();
                    if (h?.name) merged[hid].name = String(h.name).trim();
                } catch (e) { /* ignorar */ }
            }
        }
    }
    FLOR_INTEGRATIONS_CACHE.data = merged;
    FLOR_INTEGRATIONS_CACHE.ts = now;
    const totalInts = Object.values(merged).reduce((s, v) => s + (v?.specificIntegrations?.length || 0), 0);
    if (totalInts > 0) console.log(`📋 Integraciones cargadas: ${totalInts} en ${Object.keys(merged).length} hotel(es)`);
    return merged;
}

/**
 * Prioridad de Integraciones: Detectar si el mensaje activa alguna integración (override antes del LLM).
 * Escanea palabras clave de todas las integraciones. Si lastHotelNombre está definido, prioriza ese hotel.
 * @returns {Promise<{integration, hotelId, hotel}|null>}
 */
async function detectarIntegracionActivada(mensaje, lastHotelNombre) {
    if (!mensaje || typeof mensaje !== 'string') return null;
    const message = String(mensaje).toLowerCase().trim();
    const allKnowledge = await obtenerIntegracionesPorHotel();
    if (!allKnowledge || typeof allKnowledge !== 'object') return null;

    // Ordenar: si hay lastHotel, priorizar ese hotel. Buscar nombre en hotels.
    let hotelIds = Object.keys(allKnowledge).filter(k => allKnowledge[k]?.specificIntegrations?.length > 0);
    if (hotelIds.length === 0) return null;

    if (lastHotelNombre) {
        try {
            const hoteles = await buscarHotelesPorNombreParcial(lastHotelNombre);
            if (hoteles && hoteles.length > 0) {
                const lastId = String(hoteles[0].id);
                if (hotelIds.includes(lastId)) {
                    hotelIds = [lastId, ...hotelIds.filter(id => id !== lastId)];
                }
            }
        } catch (e) { /* ignorar */ }
    }

    for (const hotelId of hotelIds) {
        const integrations = allKnowledge[hotelId]?.specificIntegrations || [];
        const hotelName = (allKnowledge[hotelId]?.name || '').toLowerCase().trim();
        for (const integration of integrations) {
            const keywords = [...(integration.triggerKeywords || [])];
            // Palabras significativas del nombre del hotel como trigger implícito (ej. "futangue" en "Hotel Futangue")
            if (hotelName && hotelName.length >= 3) {
                const words = hotelName.split(/\s+/).filter(w => w.length >= 3 && !/^(hotel|los|las|el|la|de|del|y)$/i.test(w));
                words.forEach(w => { if (w && !keywords.some(k => String(k).toLowerCase() === w)) keywords.push(w); });
            }
            if (keywords.length === 0) continue;
            const match = keywords.some(kw => {
                const k = String(kw).toLowerCase().trim();
                return k && message.includes(k);
            });
            if (match) {
                let hotel = null;
                if (supabase) {
                    try {
                        const { data: h } = await supabase.from('hotels').select('id, name, flor_info, images').eq('id', hotelId).single();
                        hotel = h || null;
                    } catch (e) { /* ignorar */ }
                }
                return { integration, hotelId, hotel };
            }
        }
    }
    const total = Object.values(allKnowledge).reduce((s, v) => s + (v?.specificIntegrations?.length || 0), 0);
    if (total > 0) console.log(`📋 Integraciones: sin match para "${message.slice(0, 40)}" (${total} cargadas)`);
    return null;
}

// Configuración de IA por defecto (usada si no hay en Supabase)
// Temperatura 0.3 = más preciso al usar funciones; 0.7 = más flexible en lenguaje natural (configurable en Supabase flor_ai_config)
const FLOR_AI_CONFIG_DEFAULT = {
    enabled: true,
    provider: 'gemini',
    model: 'gemini-3.1-flash-lite-preview',
    temperature: 0.3,
    maxTokens: 2048,
    imagen_cotizacion_url: null // URL de imagen para preview del link cotizador (Supabase o env IMAGEN_COTIZACION_URL)
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

// Historial de sesión por chat (para preguntas de seguimiento y fijación de hotel). Últimos 8 mensajes = 4 turnos (user+model).
const FLOR_SESSION_MAX_TURNS = 4;
const FLOR_SESSION_MAX_MESSAGES = 8; // últimos 6-8 mensajes a Gemini para que "No repetir" y "Fijación de destino" funcionen
const florSessionByPhone = new Map(); // phone -> [{ role: 'user'|'model', parts: [{ text }] }]
// Fallos consecutivos por teléfono: si llega a 2, se resetea el contexto para salir del bucle "no entiendo"
const florFailureCountByPhone = new Map(); // phone -> number
// Última actividad por teléfono (ms): si pasan >30 min, se limpia el historial
const florLastActivityByPhone = new Map(); // phone -> timestamp
const FLOR_SESSION_INACTIVITY_MS = 30 * 60 * 1000; // 30 minutos
// Último hotel consultado por chat (Context Drift fix): al preguntar "¿Qué incluye?" se fuerza consultarCatalogoHoteles con este hotel
const florLastHotelByPhone = new Map(); // phone -> string (nombre hotel)
// Control repetición: "Temporada de Oportunidades" (y similares) se envía solo una vez por hotel por chat
const florOportunidadesSentByPhone = new Map(); // phoneKey -> Set(hotelId o hotelName)

/** Obtener promociones activas por lista de hotel_id (tabla promotions del Dashboard). */
async function obtenerPromocionesActivasPorHoteles(hotelIds) {
    if (!supabase || !Array.isArray(hotelIds) || hotelIds.length === 0) return [];
    try {
        const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
        const { data, error } = await supabase
            .from('promotions')
            .select('id, hotel_id, name, type, description, discount, start_date, end_date, status')
            .in('hotel_id', hotelIds)
            .eq('status', 'active')
            .lte('start_date', today)
            .gte('end_date', today);
        if (error) {
            console.warn('⚠️ Error obteniendo promociones:', error.message);
            return [];
        }
        return (data || []).map(p => ({
            hotel_id: p.hotel_id,
            name: p.name,
            type: p.type || '',
            description: (p.description && String(p.description).slice(0, 500)) || '',
            discount: parseFloat(p.discount) || 0,
            start_date: p.start_date,
            end_date: p.end_date
        }));
    } catch (e) {
        console.warn('⚠️ Error obteniendo promociones:', e?.message || e);
        return [];
    }
}

/** Obtener todos los hoteles activos en formato de la herramienta (para "qué hoteles tienen" sin filtro). Incluye promociones activas. */
async function obtenerTodosLosHotelesParaTool() {
    if (!supabase) return [];
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
        const hotelIds = active.slice(0, 15).map(h => h.id);
        const promos = await obtenerPromocionesActivasPorHoteles(hotelIds);
        const promosByHotel = {};
        for (const p of promos) {
            if (!promosByHotel[p.hotel_id]) promosByHotel[p.hotel_id] = [];
            promosByHotel[p.hotel_id].push(p);
        }
        return active.slice(0, 15).map(hotel => {
            const fi = hotel.flor_info || {};
            const ubicacionMaps = fi.ubicacion_maps || hotel.location || '';
            return {
                nombre: hotel.name,
                ubicacion: hotel.location,
                descripcion: (fi.description && String(fi.description).slice(0, 400)) || (fi.narrativa_poetica && String(fi.narrativa_poetica).slice(0, 400)) || '',
                servicios: (fi.services && String(fi.services).slice(0, 300)) || '',
                excursiones: (fi.excursions && String(fi.excursions).slice(0, 250)) || '',
                politicas: (fi.policies && String(fi.policies).slice(0, 200)) || '',
                como_llegar: (fi.transport && String(fi.transport).slice(0, 150)) || '',
                ubicacion_maps: ubicacionMaps,
                detalles_programas: fi.detalles_programas || [],
                servicios_json: fi.servicios_json || {},
                gastronomia_info: (fi.gastronomia_info && String(fi.gastronomia_info).slice(0, 300)) || '',
                tips_agencia: (fi.tips_agencia && String(fi.tips_agencia).slice(0, 300)) || '',
                img_general: fi.img_general || '',
                img_habitacion: fi.img_habitacion || '',
                img_spa: fi.img_spa || '',
                img_cuadro_programas: fi.img_cuadro_programas || '',
                pdf_menu_resto: fi.pdf_menu_resto || fi.carta_restaurante_verano || fi.carta_restaurante_invierno || '',
                pdf_menu_spa: fi.pdf_menu_spa || fi.spa_verano || fi.spa_invierno || '',
                pdf_programas: fi.pdf_programas || fi.excursiones_verano || fi.excursiones_invierno || '',
                spa_verano: fi.spa_verano || '',
                spa_invierno: fi.spa_invierno || '',
                carta_restaurante_verano: fi.carta_restaurante_verano || '',
                carta_restaurante_invierno: fi.carta_restaurante_invierno || '',
                excursiones_verano: fi.excursiones_verano || '',
                excursiones_invierno: fi.excursiones_invierno || '',
                instagram_verano: fi.instagram_verano || '',
                instagram_invierno: fi.instagram_invierno || '',
                link_cotizacion: fi.link_cotizacion || 'https://cotizar.checkin24hs.com/',
                promociones: promosByHotel[hotel.id] || []
            };
        });
    } catch (e) {
        console.warn('⚠️ Error obteniendo todos los hoteles:', e?.message || e);
        return [];
    }
}

/** True si el valor es un string Base64 de imagen (data:image/...;base64,...). No enviar a Gemini para no saturar contexto ni disparar filtros. */
function esBase64Imagen(val) {
    if (typeof val !== 'string' || !val.trim()) return false;
    return /^data:image\/[^;]+;base64,/i.test(val.trim());
}

/** Sanitiza el objeto hotel para el tool result: elimina campos Base64 y opcionalmente vacíos. La IA recibe solo URLs o referencias; para enviar imagen se usa enviarImagenHotelPorWhatsApp. */
function sanitizarHotelParaGemini(raw) {
    const o = { ...raw };
    const camposImagen = ['img_general', 'img_habitacion', 'img_spa', 'img_cuadro_programas'];
    for (const key of camposImagen) {
        if (o[key] && esBase64Imagen(o[key])) {
            delete o[key];
        }
        if (o[key] === '' || o[key] == null) delete o[key];
    }
    if (o.flor_info && typeof o.flor_info === 'object') {
        const fi = { ...o.flor_info };
        for (const k of ['img_general', 'img_habitacion', 'img_spa', 'img_cuadro_programas']) {
            if (fi[k] && esBase64Imagen(fi[k])) delete fi[k];
        }
        if (fi.prices !== undefined && (fi.prices === null || (typeof fi.prices === 'object' && Object.keys(fi.prices).length === 0))) delete fi.prices;
        o.flor_info = fi;
    }
    return o;
}

/** Tool para Gemini: consultar catálogo de hoteles por ubicación y/o nombre. El conocimiento vive en el servidor, no en el prompt. Payload sin Base64 para no saturar contexto. */
async function consultarCatalogoHotelesTool(ubicacion, hotel_especifico) {
    const u = (ubicacion && String(ubicacion).trim()) || '';
    const h = (hotel_especifico && String(hotel_especifico).trim()) || '';
    // Sin filtro ("qué hoteles tienen"): devolver listado limitado para no exceder tamaño de request (evitar 400)
    if (!u && !h) {
        const list = await obtenerTodosLosHotelesParaTool();
        if (list.length === 0) return { encontrado: false, mensaje: 'No hay hoteles activos cargados en la base.' };
        const maxEnRespuesta = 5;
        const hotelesEnviados = list.slice(0, maxEnRespuesta).map(sanitizarHotelParaGemini);
        return {
            encontrado: true,
            varios: list.length > 1,
            total_disponibles: list.length,
            nota: list.length > maxEnRespuesta ? `Mostrando ${maxEnRespuesta} de ${list.length} hoteles; el usuario puede pedir por ubicación o nombre para ver más.` : '',
            hoteles: hotelesEnviados
        };
    }

    let hoteles = [];
    if (h) {
        hoteles = await buscarHotelesPorNombreParcial(h);
    }
    if (u && hoteles.length === 0) {
        const porUbicacion = await buscarHotelesPorUbicacion(u);
        if (porUbicacion.length > 0) hoteles = porUbicacion;
    }
    if (u && h && hoteles.length === 0) {
        const porNombre = await buscarHotelesPorNombreParcial(h);
        const porUbic = await buscarHotelesPorUbicacion(u);
        const ids = new Set(porNombre.map(x => x.id));
        hoteles = porUbic.filter(x => ids.has(x.id)).length ? porUbic.filter(x => ids.has(x.id)) : (porNombre.length ? porNombre : porUbic);
    }

    if (hoteles.length === 0) {
        return { encontrado: false, mensaje: 'No se encontraron hoteles con esos criterios en nuestra base autorizada.' };
    }
    const varios = hoteles.length > 1;
    const sliceHoteles = hoteles.slice(0, 5);
    const hotelIds = sliceHoteles.map(h => h.id);
    const promos = await obtenerPromocionesActivasPorHoteles(hotelIds);
    const promosByHotel = {};
    for (const p of promos) {
        if (!promosByHotel[p.hotel_id]) promosByHotel[p.hotel_id] = [];
        promosByHotel[p.hotel_id].push(p);
    }
    const list = sliceHoteles.map(hotel => {
        const fi = hotel.flor_info || {};
        const imgGeneral = fi.img_general || '';
        const ubicacionMaps = fi.ubicacion_maps || hotel.location || '';
        const raw = {
            nombre: hotel.name,
            ubicacion: hotel.location,
            descripcion: (fi.description && String(fi.description).slice(0, 1200)) || (fi.narrativa_poetica && String(fi.narrativa_poetica).slice(0, 1200)) || '',
            servicios: (fi.services && String(fi.services).slice(0, 500)) || '',
            excursiones: (fi.excursions && String(fi.excursions).slice(0, 400)) || '',
            politicas: (fi.policies && String(fi.policies).slice(0, 300)) || '',
            como_llegar: (fi.transport && String(fi.transport).slice(0, 300)) || '',
            ubicacion_maps: ubicacionMaps,
            detalles_programas: fi.detalles_programas || [],
            servicios_json: fi.servicios_json || {},
            gastronomia_info: (fi.gastronomia_info && String(fi.gastronomia_info).slice(0, 300)) || '',
            tips_agencia: (fi.tips_agencia && String(fi.tips_agencia).slice(0, 300)) || '',
            img_general: esBase64Imagen(imgGeneral) ? undefined : imgGeneral,
            img_habitacion: esBase64Imagen(fi.img_habitacion) ? undefined : (fi.img_habitacion || ''),
            img_spa: esBase64Imagen(fi.img_spa) ? undefined : (fi.img_spa || ''),
            img_cuadro_programas: esBase64Imagen(fi.img_cuadro_programas) ? undefined : (fi.img_cuadro_programas || ''),
            pdf_menu_resto: fi.pdf_menu_resto || fi.carta_restaurante_verano || fi.carta_restaurante_invierno || '',
            pdf_menu_spa: fi.pdf_menu_spa || fi.spa_verano || fi.spa_invierno || '',
            pdf_programas: fi.pdf_programas || fi.excursiones_verano || fi.excursiones_invierno || '',
            spa_verano: fi.spa_verano || '',
            spa_invierno: fi.spa_invierno || '',
            carta_restaurante_verano: fi.carta_restaurante_verano || '',
            carta_restaurante_invierno: fi.carta_restaurante_invierno || '',
            excursiones_verano: fi.excursiones_verano || '',
            excursiones_invierno: fi.excursiones_invierno || '',
            instagram_verano: fi.instagram_verano || '',
            instagram_invierno: fi.instagram_invierno || '',
            link_cotizacion: fi.link_cotizacion || 'https://cotizar.checkin24hs.com/',
            promociones: promosByHotel[hotel.id] || []
        };
        return sanitizarHotelParaGemini(raw);
    });
    return { encontrado: true, varios, hoteles: list };
}

async function buscarHotelesPorUbicacion(ubicacion) {
    if (!supabase || !ubicacion || String(ubicacion).trim().length < 2) return [];
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
        const term = String(ubicacion).toLowerCase().trim();
        // Buscar en: location, nombre, descripción y narrativa (ej. "Patagonia" en flor_info.description)
        return active.filter(h => {
            const location = (h.location || '').toLowerCase();
            const name = (h.name || '').toLowerCase();
            const fi = h.flor_info || {};
            const description = (fi.description && String(fi.description).toLowerCase()) || '';
            const narrativa = (fi.narrativa_poetica && String(fi.narrativa_poetica).toLowerCase()) || '';
            const region = (fi.region && String(fi.region).toLowerCase()) || '';
            return location.includes(term) || name.includes(term) || description.includes(term) || narrativa.includes(term) || region.includes(term);
        });
    } catch (e) {
        console.warn('⚠️ Error buscando hoteles por ubicación:', e?.message || e);
        return [];
    }
}

/**
 * Similitud para fuzzy match: permite 1 carácter de diferencia (ej. Guilo ↔ Huilo).
 * Solo para términos cortos (3–12 caracteres) para evitar falsos positivos.
 */
function similarEnough(a, b) {
    if (!a || !b) return false;
    a = String(a).toLowerCase().trim();
    b = String(b).toLowerCase().trim();
    if (a === b) return true;
    if (a.length < 3 || b.length < 3 || a.length > 12 || b.length > 12) return false;
    const diff = Math.abs(a.length - b.length);
    if (diff > 1) return false;
    let edits = 0;
    let i = 0, j = 0;
    while (i < a.length && j < b.length) {
        if (a[i] !== b[j]) {
            edits++;
            if (edits > 1) return false;
            if (a.length === b.length) { i++; j++; }
            else if (a.length < b.length) j++;
            else i++;
        } else { i++; j++; }
    }
    edits += (a.length - i) + (b.length - j);
    return edits <= 1;
}

/**
 * Buscar hoteles por nombre parcial (ej: "Puyehue" → "Termas de Puyehue", "Guilo" → "Hotel Huilo-Huilo")
 * Incluye alias_busqueda y fuzzy match (1 carácter de diferencia) para errores de tipeo.
 */
async function buscarHotelesPorNombreParcial(termino) {
    if (!supabase || !termino || termino.trim().length < 3) return [];
    
    try {
        const { data: hotels, error } = await supabase
            .from('hotels')
            .select('id, name, location, flor_info, status')
            .order('name');
        
        if (error) {
            console.warn(`⚠️ Flor/Supabase: error leyendo hotels (posible RLS o red): ${error.message || error.code}`);
            throw error;
        }
        
        const list = Array.isArray(hotels) ? hotels : [];
        if (list.length === 0) {
            console.warn('🔍 Flor/Supabase: hotels devolvió 0 filas. Si la tabla tiene datos, revisar RLS (ej. ejecutar supabase-migrations/010_hotels_rls_select.sql).');
        }
        const active = list.filter(h => {
            const s = (h.status || '').toLowerCase();
            return s !== 'inactivo' && s !== 'inactive';
        });
        
        const terminoLower = termino.toLowerCase().trim();
        const hotelNameWordsStop = ['de', 'la', 'el', 'y', 'en', 'a', 'del', 'las', 'los', 'hotel', 'terma', 'termas'];
        
        const coincidencias = active.filter(h => {
            const hotelName = (h.name || '').toLowerCase();
            const location = (h.location || '').toLowerCase();
            const fi = h.flor_info || {};
            const aliasBusqueda = (fi.alias_busqueda || '').toLowerCase();
            const aliasList = aliasBusqueda ? aliasBusqueda.split(',').map(a => a.trim()).filter(Boolean) : [];
            const hotelNameWords = hotelName.split(/\s+/).filter(w => w.length >= 2);
            
            // Búsqueda exacta en nombre
            if (hotelName.includes(terminoLower)) return true;
            
            // Búsqueda en alias_busqueda (sinónimos: Puyehue, Guilo, Wilo, Huilo Huilo)
            if (aliasList.some(alias => alias.includes(terminoLower) || terminoLower.includes(alias))) return true;
            
            // Fuzzy: 1 carácter de diferencia (Guilo ↔ Huilo, Wilo ↔ Huilo)
            if (aliasList.some(alias => similarEnough(terminoLower, alias))) return true;
            if (hotelNameWords.some(w => similarEnough(terminoLower, w))) return true;
            
            // Búsqueda en ubicación
            if (location.includes(terminoLower)) return true;
            
            // Búsqueda parcial: palabras del término en el nombre
            const terminoWords = terminoLower.split(/\s+/).filter(w => w.length >= 2);
            if (terminoWords.some(tw => hotelNameWords.some(hw => hw.includes(tw) || tw.includes(hw)))) {
                return true;
            }
            
            const palabrasSignificativas = hotelNameWords.filter(w => w.length >= 4 && !hotelNameWordsStop.includes(w));
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
                    // Crear lista de nombres alternativos para búsqueda (ej: "Puyehue" → "Termas de Puyehue")
                    const nameVariants = [
                        hotelName,
                        hotelName.toLowerCase(),
                        hotelName.replace(/hotel\s+/i, '').replace(/terma[s]?\s+de\s+/i, '').trim(), // "Puyehue" de "Termas de Puyehue"
                        hotelName.replace(/terma[s]?\s+de\s+/i, '').trim(),
                        hotelName.replace(/hotel\s+/i, '').trim()
                    ].filter((v, i, arr) => arr.indexOf(v) === i); // Eliminar duplicados
                    
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

/**
 * Comprobar si Flor está pausada para este chat (asesor envió mensaje/audio desde dashboard).
 * Si flor_paused_until > now() en whatsapp_chats, Flor no debe responder.
 */
function normalizarCandidatosTelefono(phone) {
    const raw = String(phone || '').trim();
    const sinDominio = raw.replace(/@s\.whatsapp\.net$/i, '').replace(/@lid$/i, '').trim();
    const sinMas = sinDominio.replace(/^\+/, '').trim();
    const soloDigitos = sinMas.replace(/\D/g, '').trim();
    const conMas = soloDigitos ? `+${soloDigitos}` : '';
    const jid = soloDigitos ? `${soloDigitos}@s.whatsapp.net` : '';
    const candidatos = [raw, sinDominio, sinMas, soloDigitos, conMas, jid].filter(Boolean);
    return [...new Set(candidatos)];
}

function florPausedUntilFromRows(rows) {
    if (!rows || !rows.length) return null;
    const raw = rows[0].flor_paused_until;
    if (!raw) return null;
    const until = new Date(raw).getTime();
    return until > Date.now() ? until : null;
}

async function isFlorPausedForChat(phone, instanceNumber) {
    if (!phone) return false;
    if (florPauseMemoryIsActive(phone)) {
        console.log(`⏸️ Flor pausa: memoria RAM (silencio reciente) — clave numérica asociada a este chat`);
        return true;
    }
    if (!supabase) return false;
    try {
        const candidatos = normalizarCandidatosTelefono(phone);
        const inst = instanceNumber || 1;
        // La fila puede tener el cliente en `phone` (a veces LID) o en `real_phone` mientras `phone` ya es +E.164
        for (const col of ['phone', 'real_phone']) {
            const { data: rows, error } = await supabase
                .from('whatsapp_chats')
                .select('flor_paused_until')
                .eq('whatsapp_instance', inst)
                .in(col, candidatos)
                .order('updated_at', { ascending: false })
                .limit(1);
            if (error) continue;
            if (florPausedUntilFromRows(rows)) {
                const u = rows[0]?.flor_paused_until;
                console.log(`⏸️ Flor pausa: DB flor_paused_until=${u} (columna ${col})`);
                return true;
            }
        }
        return false;
    } catch (e) {
        return false;
    }
}

/**
 * Pausar Flor para un chat por N minutos (ej: cuando Flor deriva a asesor humano, o cuando un humano envía mensaje desde el panel).
 * Actualiza flor_paused_until en whatsapp_chats por phone + whatsapp_instance, o por chatId si se indica.
 * @param {string} phone - Número del chat (+E.164 o null si solo hay LID)
 * @param {number} minutes - Minutos de pausa (ej: 10)
 * @param {string} [chatIdOptional] - Si viene del dashboard con chat_id, actualizar por id para no fallar con LID
 * @param {string} [lidDigitsForRowMatch] - JID local @lid (solo dígitos): la fila en Supabase a menudo tiene phone=LID; sin esto el UPDATE por +549 no pega y Flor sigue respondiendo.
 */
async function setFlorPausedUntil(phone, minutes, chatIdOptional = null, lidDigitsForRowMatch = null) {
    const lidClean = lidDigitsForRowMatch ? String(lidDigitsForRowMatch).replace(/\D/g, '') : '';
    if (phone) florPauseMemoryTouch(phone);
    if (lidClean.length >= 10) florPauseMemoryTouchMany('+' + lidClean);
    if (!supabase) return;
    if (!chatIdOptional && !phone && lidClean.length < 10) return;
    try {
        const until = new Date(Date.now() + minutes * 60 * 1000).toISOString();
        const instance = CONFIG.INSTANCE_NUMBER || 1;
        const updates = { flor_paused_until: until, updated_at: new Date().toISOString() };

        const mergeMatchKeys = () => {
            const s = new Set();
            if (phone) {
                for (const c of normalizarCandidatosTelefono(phone)) s.add(String(c).trim());
            }
            if (lidClean.length >= 10) {
                s.add(lidClean);
                s.add('+' + lidClean);
            }
            return [...s].filter(Boolean);
        };
        const keys = mergeMatchKeys();

        let anyUpdated = false;
        if (chatIdOptional && String(chatIdOptional).trim()) {
            const { data: updatedRows, error } = await supabase
                .from('whatsapp_chats')
                .update(updates)
                .eq('whatsapp_instance', instance)
                .eq('id', String(chatIdOptional).trim())
                .select('id');
            if (error) {
                console.warn('⚠️ No se pudo pausar Flor para el chat:', error.message);
                return;
            }
            anyUpdated = !!(updatedRows && updatedRows.length);
        } else if (keys.length) {
            for (const col of ['phone', 'real_phone']) {
                const { data: updatedRows, error } = await supabase
                    .from('whatsapp_chats')
                    .update(updates)
                    .eq('whatsapp_instance', instance)
                    .in(col, keys)
                    .select('id');
                if (error) {
                    console.warn(`⚠️ Pausa Flor (${col}):`, error.message);
                    continue;
                }
                if (updatedRows && updatedRows.length) anyUpdated = true;
            }
        }

        if (!anyUpdated && !chatIdOptional && phone) {
            const cands = normalizarCandidatosTelefono(phone);
            const primary = cands.map(c => String(c).trim()).find(p => p.replace(/\D/g, '').length >= 10) || String(phone).trim();
            const phoneInsert = primary.replace(/^\+/, '').replace(/\D/g, '').length >= 10
                ? primary.replace(/^\+/, '').replace(/\D/g, '')
                : primary;
            const { error: insErr } = await supabase.from('whatsapp_chats').insert({
                phone: phoneInsert,
                whatsapp_instance: instance,
                flor_paused_until: until,
                name: phoneInsert,
                channel: 'whatsapp',
                status: 'active',
                updated_at: new Date().toISOString()
            });
            if (insErr) {
                console.warn('⚠️ Pausa Flor: update sin filas e insert falló (¿duplicado?):', insErr.message);
            } else {
                console.log(`⏸️ Chat creado con flor_paused_until (${minutes} min) para phone=${phoneInsert}`);
            }
        }
        console.log(`⏸️ Flor pausada ${minutes} min para este chat (modo silencio)`);
    } catch (e) {
        console.warn('⚠️ setFlorPausedUntil:', e?.message || e);
    }
}

/**
 * Obtener los últimos N mensajes del chat desde Supabase para usarlos como context window de Flor.
 * Así Flor no olvida de qué estaban hablando (ej: Huilo Huilo).
 * @param {string} phone - Teléfono del chat (o clave del chat)
 * @param {number} instanceNumber - Instancia WhatsApp
 * @param {number} limit - Cantidad de mensajes (default 10)
 * @returns {Promise<Array<{role: 'user'|'model', parts: [{text: string}]}>>}
 */
async function obtenerUltimosMensajesChat(phone, instanceNumber, limit = 10) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE || !phone) return [];
    try {
        const instance = instanceNumber || CONFIG.INSTANCE_NUMBER || 1;
        const phoneStr = String(phone).trim();
        const numerosABuscar = [phoneStr];
        if (phoneStr && !phoneStr.includes('@')) {
            numerosABuscar.push(phoneStr + '@s.whatsapp.net');
        }
        if (phoneStr.endsWith('@s.whatsapp.net')) {
            numerosABuscar.push(phoneStr.replace(/@s\.whatsapp\.net$/, '').trim());
        }
        let chatId = null;
        for (const num of numerosABuscar) {
            const { data: chat, error: errChat } = await supabase
                .from('whatsapp_chats')
                .select('id')
                .eq('phone', num)
                .eq('whatsapp_instance', instance)
                .maybeSingle();
            if (chat?.id && !errChat) {
                chatId = chat.id;
                break;
            }
        }
        if (!chatId) return [];

        const colConv = 'conversation_id';
        const res = await supabase
            .from('whatsapp_messages')
            .select('message, body, is_from_me, sent_at')
            .eq(colConv, chatId)
            .order('sent_at', { ascending: false })
            .limit(limit);
        let rows = res.data;
        if (res.error) {
            const alt = await supabase
                .from('whatsapp_messages')
                .select('message, body, is_from_me, sent_at')
                .eq('chat_id', chatId)
                .order('sent_at', { ascending: false })
                .limit(limit);
            if (alt.error) return [];
            rows = alt.data;
        }
        if (!rows || rows.length === 0) return [];
        const crono = [...rows].reverse();
        return crono.map((r) => {
            const text = (r.message || r.body || '').trim() || '[sin texto]';
            return {
                role: r.is_from_me ? 'model' : 'user',
                parts: [{ text }]
            };
        });
    } catch (e) {
        console.warn('⚠️ obtenerUltimosMensajesChat:', e?.message || e);
        return [];
    }
}

/**
 * Envía alerta a Slack cuando Flor escala a humano o no tiene dato técnico (noEntendido).
 * Formato: mensaje con attachments (Cliente, Teléfono, Hotel en Contexto, Última duda).
 */
async function sendSlackEscalationAlert(nombreWhatsapp, telefono, hotelActual, ultimaPreguntaUsuario) {
    const url = CONFIG.SLACK_WEBHOOK_URL;
    if (!url) {
        console.log('ℹ️ Slack: SLACK_WEBHOOK_URL no configurada, no se envía alerta');
        return;
    }
    const nombre = nombreWhatsapp || 'Sin nombre';
    const phone = telefono || 'Sin teléfono';
    const hotel = hotelActual || 'No definido';
    const duda = (ultimaPreguntaUsuario || '—').slice(0, 500);
    console.log('📤 Slack: enviando POST al webhook...');
    try {
        const payload = {
            text: `🚨 *Solicitud de asistencia humana* — ${nombre}`,
            blocks: [
                {
                    type: 'section',
                    text: { type: 'mrkdwn', text: '🚨 *Flor IA solicita intervención humana*' }
                },
                {
                    type: 'section',
                    fields: [
                        { type: 'mrkdwn', text: `*Cliente:* ${nombre}` },
                        { type: 'mrkdwn', text: `*WhatsApp:* ${phone}` },
                        { type: 'mrkdwn', text: `*Hotel:* ${hotel}` },
                        { type: 'mrkdwn', text: '*Estado:* Pendiente de Agente' }
                    ]
                },
                {
                    type: 'section',
                    text: { type: 'mrkdwn', text: `*Última duda:*\n${duda}` }
                },
                { type: 'divider' },
                {
                    type: 'context',
                    elements: [
                        { type: 'mrkdwn', text: '🕒 *Horario de atención:* 08:30 a 21:00 hs. Por favor, intervenir el chat de inmediato.' }
                    ]
                }
            ]
        };
        const res = await axios.post(url, payload, { headers: { 'Content-Type': 'application/json' }, timeout: 8000 });
        console.log('📤 Alerta de escalación enviada a Slack OK (status ' + (res && res.status) + ')');
    } catch (e) {
        const status = e.response && e.response.status;
        const data = e.response && e.response.data;
        console.warn('⚠️ Error enviando alerta a Slack:', e?.message || e, status ? ' (HTTP ' + status + ')' : '', data ? JSON.stringify(data).slice(0, 200) : '');
    }
}

/**
 * Envía alerta de VENTA/RESERVA a Slack (canal #general-alertas-cotizacion-reservas-flor).
 * Mensaje prioritario cuando el cliente quiere confirmar reserva.
 */
async function sendSlackReservaAlert(nombreWhatsapp, telefono, hotelActual) {
    const url = CONFIG.SLACK_WEBHOOK_URL;
    if (!url) {
        console.log('ℹ️ Slack: SLACK_WEBHOOK_URL no configurada, no se envía alerta de venta');
        return;
    }
    const nombre = nombreWhatsapp || 'Cliente';
    const phone = telefono || 'Sin teléfono';
    const hotel = hotelActual || 'No definido';
    console.log('📤 Slack: enviando alerta de venta/reserva...');
    try {
        const payload = {
            text: '🔥 *ALERTA DE VENTA: CIERRE EN CURSO*',
            blocks: [
                {
                    type: 'section',
                    text: { type: 'mrkdwn', text: '🔥 *¡Venta en cierre detectada por Flor IA!*' }
                },
                {
                    type: 'section',
                    fields: [
                        { type: 'mrkdwn', text: `*Cliente:* ${nombre}` },
                        { type: 'mrkdwn', text: `*WhatsApp:* ${phone}` },
                        { type: 'mrkdwn', text: `*Hotel:* ${hotel}` },
                        { type: 'mrkdwn', text: '*Estado:* Pendiente de Agente' }
                    ]
                },
                { type: 'divider' },
                {
                    type: 'context',
                    elements: [
                        { type: 'mrkdwn', text: '🕒 *Horario de atención:* 08:30 a 21:00 hs. Por favor, intervenir el chat de inmediato.' }
                    ]
                }
            ]
        };
        const res = await axios.post(url, payload, { headers: { 'Content-Type': 'application/json' }, timeout: 8000 });
        console.log('📤 Alerta de venta enviada a Slack OK (status ' + (res && res.status) + ')');
    } catch (e) {
        const status = e.response && e.response.status;
        const data = e.response && e.response.data;
        console.warn('⚠️ Error enviando alerta de venta a Slack:', e?.message || e, status ? ' (HTTP ' + status + ')' : '', data ? JSON.stringify(data).slice(0, 200) : '');
    }
}

// ===== FUNCIONES DE FLOR IA =====

/**
 * Detectar URLs en un texto
 * @param {string} texto - Texto donde buscar URLs
 * @returns {string[]} - Array de URLs encontradas
 */
function detectarURLs(texto) {
    if (!texto || typeof texto !== 'string') return [];
    
    // Patrón para detectar URLs (http, https, www, etc.)
    const urlPattern = /(https?:\/\/[^\s]+|www\.[^\s]+)/gi;
    const urls = texto.match(urlPattern) || [];
    
    // Normalizar URLs que empiezan con www.
    return urls.map(url => {
        if (url.startsWith('www.')) {
            return 'https://' + url;
        }
        return url;
    }).filter((url, index, self) => self.indexOf(url) === index); // Eliminar duplicados
}

/**
 * Obtener preview de una URL usando link-preview-js
 * @param {string} url - URL para obtener preview
 * @returns {Promise<Object|null>} - Objeto con metadatos o null si falla
 */
async function obtenerPreviewURL(url) {
    if (!url || typeof url !== 'string') return null;
    if (esLinkMaps(url)) return null; // Maps bloquea scrapers; evita fetch failed
    try {
        const preview = await getLinkPreview(url, {
            timeout: 3000,
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        });
        
        return {
            title: preview.title || '',
            description: preview.description || '',
            image: preview.images && preview.images.length > 0 ? preview.images[0] : null,
            siteName: preview.siteName || '',
            url: url
        };
    } catch (error) {
        // Silenciar: no ensuciar log; Baileys generará preview automático
        return null;
    }
}

/**
 * Añadir emoji al inicio del mensaje según el tipo (Flor, cotización, manual).
 * Da calidez y consistencia a la conversación.
 * @param {string} texto - Texto del mensaje
 * @param {'flor'|'cotizacion'|'manual'} tipo - Origen del mensaje
 * @returns {string} - Texto con emoji al inicio (sin duplicar si ya lo tiene)
 */
function añadirEmojiMensaje(texto, tipo) {
    if (!texto || typeof texto !== 'string') return texto;
    const t = texto.trim();
    if (!t) return texto;
    // Flor: 🌸 | Cotización: emojis visibles (link/precio) para evitar caracteres raros
    const emojis = { flor: '🌸 ', cotizacion: '💰 📋 ', manual: '💬 ' };
    const emoji = emojis[tipo] || '';
    if (!emoji) return texto;
    // Evitar duplicar el mismo emoji al inicio
    if (t.startsWith(emoji.trim()) || t.startsWith('🌸') || (tipo === 'cotizacion' && (t.startsWith('📋') || t.startsWith('💰'))) || (tipo === 'manual' && t.startsWith('💬'))) return texto;
    return emoji + t;
}

/**
 * Normalizar enlaces para WhatsApp: reemplazar markdown [texto](url) por solo la URL
 * para que se envíe un solo link y no cause "Invalid Dynamic Link" con short URLs.
 */
function normalizarLinksParaWhatsApp(texto) {
    if (!texto || typeof texto !== 'string') return texto;
    return texto.replace(/\[([^\]]*)\]\((https?:\/\/[^)]+)\)/g, (_, __, url) => url.trim());
}

/**
 * Sanitizar contenido de integración: solo convertir [texto](url) a URL para evitar Invalid Dynamic Link.
 * El resto del texto se deja 100% literal (precios, meses, etc.).
 */
function sanitizarContenidoIntegracionParaLinks(texto) {
    if (!texto || typeof texto !== 'string') return texto;
    return normalizarLinksParaWhatsApp(texto);
}

/** Detecta si el texto es una respuesta de cotización (contiene link del cotizador). */
function esRespuestaCotizacion(texto) {
    if (!texto || typeof texto !== 'string') return false;
    return /cotizar\.checkin24hs\.com/i.test(texto);
}

/** Caption corto para imagen de cotización; el texto largo va en un 2.º mensaje (límite WA ~1024 en caption). */
function captionImagenCotizacionResumido(textoCompleto) {
    const t = String(textoCompleto || '');
    const m = t.match(/\S*cotizar\.checkin24hs\.com[^\s]*/i);
    const linkLine = m ? m[0].trim() : 'https://cotizar.checkin24hs.com/';
    const cap = `🌸 Flor · Cotización Checkin24hs\n${linkLine}\n\n📩 El detalle completo viene en el siguiente mensaje.`;
    return cap.length > 1024 ? cap.slice(0, 1021) + '...' : cap;
}

/** Detecta si una URL es de Google Maps (corta o larga). */
function esLinkMaps(url) {
    if (!url || typeof url !== 'string') return false;
    const u = url.trim();
    return /maps\.app\.goo\.gl/i.test(u) || /goo\.gl\/maps/i.test(u) || /google\.com\/maps/i.test(u);
}

/**
 * Busca un hotel cuyo "Cómo Llegar" (ubicacion_maps o transport) contenga la URL de Maps dada.
 * Devuelve el hotel con la URL de imagen principal (flor_info.img_general o primera imagen del hotel).
 * @param {string} texto - Mensaje que puede contener una o más URLs de Maps
 * @returns {Promise<{ hotel, imageUrl, mapsUrl }|null>}
 */
async function buscarHotelPorMapsLinkEnTexto(texto) {
    const urls = detectarURLs(texto);
    const mapsUrls = urls.filter(u => esLinkMaps(u));
    if (mapsUrls.length === 0) return null;
    if (!supabase) return null;
    try {
        const { data: hotels, error } = await supabase
            .from('hotels')
            .select('id, name, location, flor_info, status, images')
            .order('name');
        if (error) throw error;
        const list = Array.isArray(hotels) ? hotels : [];
        const active = list.filter(h => {
            const s = (h.status || '').toLowerCase();
            return s !== 'inactivo' && s !== 'inactive';
        });
        for (const mapsUrl of mapsUrls) {
            const normalizada = mapsUrl.replace(/\s/g, '').toLowerCase();
            const hotel = active.find(h => {
                const fi = h.flor_info || {};
                const ub = (fi.ubicacion_maps || '').replace(/\s/g, '').toLowerCase();
                const tr = (fi.transport || '').replace(/\s/g, '').toLowerCase();
                return ub && ub.includes(normalizada) || tr && tr.includes(normalizada);
            });
            if (hotel) {
                const fi = hotel.flor_info || {};
                const firstImg = Array.isArray(hotel.images) && hotel.images[0];
                const imageUrl = (fi.img_general || (typeof firstImg === 'string' ? firstImg : firstImg?.url || firstImg?.src) || '').trim();
                if (imageUrl && !imageUrl.startsWith('data:')) {
                    console.log(`📍 Combo ubicación: hotel "${hotel.name}" encontrado con imagen (img_general/images), se enviará miniatura del hotel + texto`);
                    return { hotel, imageUrl, mapsUrl };
                }
                if (!imageUrl || imageUrl.startsWith('data:')) {
                    console.log(`📍 Combo ubicación: hotel "${hotel.name}" tiene el link de Maps pero no tiene img_general/imagen en flor_info. Editar el hotel en el Dashboard y guardar (con imagen principal) para activar miniatura.`);
                }
                return { hotel, imageUrl: null, mapsUrl };
            }
        }
        console.log(`📍 Combo ubicación: ningún hotel en la base tiene el link de Maps en ubicacion_maps/transport. Revisar que el hotel (ej. Huilo Huilo) tenga esa URL en "Cómo Llegar" o "Ubicación Maps".`);
        return null;
    } catch (e) {
        console.warn('⚠️ Error en buscarHotelPorMapsLinkEnTexto:', e?.message || e);
        return null;
    }
}

/**
 * Preparar mensaje con preview si contiene URLs
 * @param {string} texto - Texto del mensaje
 * @returns {Promise<Object>} - Objeto con formato de mensaje para Baileys
 */
async function prepararMensajeConPreview(texto) {
    texto = normalizarLinksParaWhatsApp(texto);
    // Baileys detecta automáticamente URLs en el texto y genera previews
    // No necesitamos usar extendedTextMessage con externalAdReply (eso es para anuncios)
    // Simplemente enviamos el texto y Baileys se encarga del preview
    
    // Verificar si hay URLs en el texto
    const urls = detectarURLs(texto);
    
    if (urls.length === 0) {
        // Sin URLs, enviar mensaje simple
        return { text: texto };
    }
    
    // Si hay URLs, Baileys generará automáticamente el preview
    // Solo enviamos el texto normal
    // Opcionalmente podemos obtener el preview para logging, pero no lo usamos en el mensaje
    try {
        const primeraURL = urls[0];
        const preview = await obtenerPreviewURL(primeraURL);
        if (preview) {
            console.log(`🔗 Preview obtenido para ${primeraURL}: ${preview.title || 'Sin título'}`);
        }
    } catch (error) {
        // Si falla obtener el preview, no importa - Baileys generará uno automáticamente
        console.log(`ℹ️ No se pudo obtener preview, Baileys generará uno automáticamente`);
    }
    
    // Enviar mensaje simple - Baileys detectará la URL y generará el preview
    return { text: texto };
}

/**
 * Preparar mensaje de Flor para envío: si es respuesta de cotización y hay URL de imagen,
 * envía imagen + caption; si el texto contiene link de Maps y hay hotel con imagen,
 * devuelve sendAsCombo para enviar imagen del hotel + texto con ubicación.
 * @param {string} texto - Texto ya con emoji y links normalizados
 * @returns {Promise<Object>} - Objeto para sock.sendMessage o { sendAsCombo: true, imageUrl, caption, textWithLink }
 */
async function prepararMensajeFlorParaEnvio(texto) {
    texto = normalizarLinksParaWhatsApp(texto);
    const captionMaxLen = 1024; // Límite de caption en WhatsApp
    const aiConfig = await getFlorAIConfig();
    const imagenCotizacionUrl = (aiConfig.imagen_cotizacion_url || CONFIG.IMAGEN_COTIZACION_URL || '').trim() || null;
    if (esRespuestaCotizacion(texto) && imagenCotizacionUrl) {
        // WhatsApp limita el caption de imagen a ~1024 chars; si no, el cliente ve el texto cortado ("Estadía míni...").
        if (texto.length <= captionMaxLen) {
            return { image: { url: imagenCotizacionUrl }, caption: texto };
        }
        return {
            sendCotizacionCombo: true,
            imageUrl: imagenCotizacionUrl,
            caption: captionImagenCotizacionResumido(texto),
            textFull: texto
        };
    }
    // Combo ubicación: si el mensaje tiene link de Maps y encontramos hotel con imagen, enviar imagen + texto
    const combo = await prepararComboUbicacionConImagen(texto);
    if (combo) return combo;
    return await prepararMensajeConPreview(texto);
}

/**
 * Si el texto contiene un link de Google Maps y hay un hotel con esa URL en Cómo Llegar/ubicacion_maps
 * y tiene imagen, devuelve objeto para enviar primero imagen (miniatura del hotel) y luego el texto con el link.
 * Así WhatsApp muestra la foto del hotel en lugar del recuadro genérico de Maps.
 * @param {string} texto - Texto del mensaje (con o sin emoji)
 * @returns {Promise<{ sendAsCombo: true, imageUrl, caption, textWithLink }|null>}
 */
async function prepararComboUbicacionConImagen(texto) {
    if (!texto || typeof texto !== 'string') return null;
    const found = await buscarHotelPorMapsLinkEnTexto(texto);
    if (!found || !found.imageUrl) return null; // buscarHotelPorMapsLinkEnTexto ya loguea el motivo
    const hotelName = found.hotel?.name || 'Hotel';
    const caption = `📍 ${hotelName}\n\nTe comparto la ubicación.`;
    return {
        sendAsCombo: true,
        imageUrl: found.imageUrl,
        caption: caption.slice(0, 1024),
        textWithLink: normalizarLinksParaWhatsApp(texto)
    };
}

/**
 * Obtener imagen desde URL y devolver base64 (para multimodal: anuncios fb.me/instagram).
 */
async function fetchImageAsBase64(imageUrl) {
    try {
        const res = await axios.get(imageUrl, { responseType: 'arraybuffer', timeout: 10000 });
        const base64 = Buffer.from(res.data).toString('base64');
        const contentType = res.headers['content-type'] || 'image/jpeg';
        return { mimeType: contentType.split(';')[0].trim(), data: base64 };
    } catch (e) {
        console.warn('⚠️ No se pudo descargar imagen para multimodal:', e?.message || e);
        return null;
    }
}

/** Descargar URL a Buffer (para enviar PDF como documento por WhatsApp). */
async function downloadUrlToBuffer(url) {
    if (!url || typeof url !== 'string') return null;
    try {
        const res = await axios.get(url.trim(), { responseType: 'arraybuffer', timeout: 15000, maxContentLength: 25 * 1024 * 1024 });
        return Buffer.from(res.data);
    } catch (e) {
        console.warn('⚠️ No se pudo descargar URL para documento:', e?.message || e);
        return null;
    }
}

/**
 * Clona `candidate.content.parts` del turno modelo para el siguiente paso con function calling.
 * Gemini 3 exige devolver thoughtSignature / thought_signature en la primera functionCall (y el orden de partes);
 * en 2.5 la firma puede estar en la primera parte aunque no sea functionCall. Reenviar todas las partes evita 400.
 * @see https://ai.google.dev/gemini-api/docs/thought-signatures
 */
function cloneModelPartsForToolFollowup(parts) {
    if (!Array.isArray(parts)) return [];
    return parts.map(p => (p && typeof p === 'object' ? { ...p } : p));
}

/**
 * Transcribir audio a texto usando Gemini (multimodal: audio → texto).
 * @param {string} audioBase64 - Audio en base64
 * @param {string} mimeType - Ej: audio/ogg, audio/mp3 (Gemini soporta ogg, mp3, wav, aac, flac)
 * @returns {Promise<string|null>} - Texto transcrito o null si falla
 */
async function transcribeAudioWithGemini(audioBase64, mimeType = 'audio/ogg') {
    if (!CONFIG.GEMINI_API_KEY || CONFIG.GEMINI_API_KEY.trim() === '') {
        console.warn('⚠️ Transcripción de audio: GEMINI_API_KEY no configurada. Configura la variable de entorno en EasyPanel (servicio WhatsApp).');
        return null;
    }
    const model = CONFIG.GEMINI_MODEL || 'gemini-3.1-flash-lite-preview';
    const prompt = 'Transcribe this voice message to text. Reply only with the transcribed text, in the same language as the speaker. No other commentary or punctuation beyond what was said.';
    try {
        const requestBody = {
            contents: [{
                role: 'user',
                parts: [
                    { text: prompt },
                    { inlineData: { mimeType: mimeType.split(';')[0].trim(), data: audioBase64 } }
                ]
            }],
            generationConfig: {
                temperature: 0.2,
                maxOutputTokens: 1024
            }
        };
        const response = await axios.post(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${CONFIG.GEMINI_API_KEY}`,
            requestBody,
            { headers: { 'Content-Type': 'application/json' }, timeout: 20000 }
        );
        const text = response?.data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text && typeof text === 'string') {
            return text.trim();
        }
        // Respuesta sin texto (ej. bloqueo de seguridad, audio no reconocido)
        const blockReason = response?.data?.candidates?.[0]?.finishReason || response?.data?.promptFeedback?.blockReason;
        console.warn('⚠️ Transcripción Gemini: sin texto en respuesta. finishReason:', blockReason, 'respuesta:', JSON.stringify(response?.data?.candidates?.[0] || {}).slice(0, 200));
        return null;
    } catch (e) {
        const status = e?.response?.status;
        const body = e?.response?.data ? JSON.stringify(e.response.data).slice(0, 300) : '';
        console.warn('⚠️ Error transcribiendo audio con Gemini:', e?.message || e, status ? `HTTP ${status}` : '', body || '');
        return null;
    }
}

/**
 * Procesar mensaje con Flor IA usando Gemini.
 * Usa el Prompt General de Flor IA → General (Supabase flor_general_config) o FLOR_PROMPT_DEFAULT.
 * Usa flor_ai_config desde Supabase para model, temperature, maxTokens.
 * imageParts: opcional, array de { mimeType, data (base64) } para análisis multimodal (anuncios fb.me/instagram o imagen).
 */
async function procesarConFlor(mensaje, contexto = {}, imageParts = []) {
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
    
    // Detectar solicitud de transferencia a humano → respuesta predefinida y pausar Flor (por defecto 30 min)
    const transferKeywords = ['hablar con humano', 'hablar con agente', 'hablar con asesor', 'transferir', 'agente humano', 'asesor humano', 'quiero hablar con alguien', 'asesor'];
    if (transferKeywords.some(kw => mensajeLower.includes(kw))) {
        console.log(`🔄 Usando respuesta predefinida: transferir (Flor se pausará ${FLOR_SILENCE_MINUTES} min para este chat)`);
        return { text: responses.transferir, intent: 'transferir', pausarFlorMin: FLOR_SILENCE_MINUTES, pausarFlor20Min: true };
    }

    // Detectar despedida
    const despedidaKeywords = ['gracias', 'chau', 'adiós', 'hasta luego', 'nos vemos', 'bye', 'hasta pronto'];
    if (despedidaKeywords.some(kw => mensajeLower.includes(kw)) && mensajeLower.length < 30) {
        console.log('👋 Usando respuesta predefinida: despedida');
        return responses.despedida;
    }

    // Detectar intención de reserva: disparar webhook Slack de alerta de venta y conectar con agente
    const reservaKeywords = ['reservar', 'hacer la reserva', 'hacer reserva', 'confirmar', 'quiero reservar', 'confirmar reserva', 'agendar'];
    if (reservaKeywords.some(kw => mensajeLower.includes(kw))) {
        console.log('🔥 Intención de reserva detectada: enviando alerta de venta a Slack');
        const phoneKey = (contexto.numero && String(contexto.numero).replace(/\D/g, '')) || 'unknown';
        const hotelActual = florLastHotelByPhone.get(phoneKey) || 'No definido';
        await sendSlackReservaAlert(contexto.nombre || contexto.numero || 'Cliente', contexto.numero || '', hotelActual);
        const textoReserva = 'Entiendo que deseas hacer una reserva. Para asegurar que tengas la mejor atención y confirmación, voy a conectarte inmediatamente con uno de nuestros agentes especializados. Un momento por favor...';
        return { text: textoReserva, intent: 'reservar' };
    }

    // Saludos y transiciones: delegados a Gemini para que suenen más naturales (no usar plantilla flor_responses.saludo)
    // (Se eliminó el early-return por saludo para que Gemini maneje saludos y transiciones con fluidez.)

    const systemPrompt = await getFlorPromptForGemini();
    const FLOR_FORZAR_TOOL_HOTEL = '\n**FORZAR HERRAMIENTA:** Si en tu respuesta vas a mencionar un hotel concreto del catálogo (Puyehue, Corralco, Huilo Huilo, Futangue, etc.), DEBÉS disparar INMEDIATAMENTE la herramienta consultarCatalogoHoteles o buscarHotel con ese hotel. No envíes solo un texto de confirmación ("Dejame darte los detalles...") sin haber llamado la función; el usuario debe recibir los datos reales. Chain of Thought: (1) llamá buscarHotel(nombre_hotel) o consultarCatalogoHoteles(hotel_especifico=...), (2) el backend ejecuta la consulta en Supabase y te devuelve el JSON, (3) recién entonces generá tu respuesta con esos datos. La respuesta al usuario solo se envía después de que las búsquedas terminen.';
    const FLOR_PROGRAMAS_SOLO_CATALOGO = '\n**PROGRAMAS SOLO DEL CATÁLOGO:** Cuando consultes el catálogo, SOLO mencioná los programas que aparecen explícitamente en el campo "programas" (o detalles_programas). Si no hay programas cargados, no inventes nombres como "Semana Blanca" ni asumas beneficios. En su lugar, decí que los programas se están actualizando y ofrecé que te contacten para el detalle.';
    const systemPart = `${systemPrompt}\n\n${FLOR_REGLAS_PRIORIDAD}\n\n${FLOR_PROTOCOLO_VENTAS}\n\n${FLOR_FORZAR_TOOL_HOTEL}\n\n${FLOR_PROGRAMAS_SOLO_CATALOGO}`;

    let multiConsultasNote = '';
    if (contexto.multiConsultas && Array.isArray(contexto.consultas) && contexto.consultas.length > 1) {
        multiConsultasNote = `\n(Múltiples consultas: responde a todas en un solo mensaje, ordenado.)\n`;
    }
    // Palabras clave de campañas de marketing: priorizar promociones en la respuesta
    const CAMPANA_KEYWORDS = ['25% off', 'black friday', 'invierno', 'descuento', 'promoción', 'promo', 'oferta', 'campaña'];
    const esSeguimientoCampana = CAMPANA_KEYWORDS.some(kw => mensajeLower.includes(kw));
    const hintCampana = esSeguimientoCampana
        ? ' [CONTEXTO CAMPAÑA: El cliente está respondiendo a una campaña de marketing. Priorizá en tu respuesta las promociones activas (campo promociones de consultarCatalogoHoteles) y adaptá el mensaje a la oferta (descuentos, fechas, beneficios).]'
        : '';

    // Detectar consulta de hotel/destino: reforzar que debe llamar consultarCatalogoHoteles (evita bucle "no entiendo")
    const hotelKeywords = ['huilo', 'guilo', 'wilo', 'hotel', 'carta', 'menú', 'restaurante', 'spa', 'programa', 'info de', 'información de', 'qué hoteles', 'que hoteles', 'destino', 'puyehue', 'corralco', 'futangue', 'bariloche', 'termas'];
    const pareceConsultaHotel = hotelKeywords.some(kw => mensajeLower.includes(kw));
    // Extraer hotel/destino de la frase (ej: "información de Futangue" → Futangue) para inyectar hotel_especifico sin preguntar de nuevo
    let hotelExtraido = '';
    const patronesEntidad = [
        /(?:información|info)\s+de\s+([a-záéíóúñ\s\-]+?)(?:\s+por favor|\s*$|\.|,|\?)/i,
        /(?:programas|programa)\s+de\s+([a-záéíóúñ\s\-]+?)(?:\s+por favor|\s*$|\.|,|\?)/i,
        /(?:precio|tarifa)\s+(?:de\s+)?([a-záéíóúñ\s\-]+?)(?:\s+por favor|\s*$|\.|,|\?)/i
    ];
    for (const p of patronesEntidad) {
        const m = mensaje.match(p);
        if (m && m[1] && m[1].trim().length >= 3) {
            hotelExtraido = m[1].trim();
            break;
        }
    }
    const hintEntidad = hotelExtraido
        ? ` [VALIDACIÓN DE ENTIDAD: El cliente mencionó explícitamente el hotel/destino "${hotelExtraido}". Llamá buscarHotel(nombre_hotel="${hotelExtraido}") o consultarCatalogoHoteles(hotel_especifico="${hotelExtraido}") INMEDIATAMENTE, sin preguntar de nuevo.]`
        : '';
    const hintHotel = pareceConsultaHotel
        ? ` [INSTRUCCIÓN: El cliente pide información o detalles de hotel. Debes llamar PRIMERO buscarHotel(nombre_hotel=...) o consultarCatalogoHoteles(hotel_especifico=...) con el nombre que mencionó (Huilo Huilo, Puyehue, Corralco, Futangue); el backend ejecutará la consulta y te devolverá el JSON; recién entonces respondé con esos datos. No respondas "Dejame darte los detalles" sin haber llamado la función.]${hintEntidad}`
        : '';
    // Context Drift fix: si pregunta por programas/spa/menú sin mencionar hotel y ya tenemos último hotel, forzar consulta
    const phoneKey = (contexto.numero && String(contexto.numero).replace(/\D/g, '')) || 'unknown';
    const programKeywords = ['programa', 'programas', 'qué incluye', 'que incluye', 'qué hay', 'que hay', 'qué tiene', 'que tiene', 'spa', 'menú', 'menus', 'carta', 'restaurante', 'excursiones', 'detalle', 'pensión completa', 'pension completa', 'incluye', 'incluyen'];
    const esPreguntaProgramas = programKeywords.some(kw => mensajeLower.includes(kw));
    const lastHotel = florLastHotelByPhone.get(phoneKey);
    const hintContextDrift = (esPreguntaProgramas && !hotelExtraido && lastHotel)
        ? (() => { console.log(`🔄 Flor: Context Drift fix - forzando buscarHotel/consultarCatalogoHoteles con hotel="${lastHotel}" para pregunta de programas`); return ` [CONTEXT DRIFT - OBLIGATORIO: El usuario pregunta sobre programas/spa/menú pero NO mencionó hotel en este mensaje. En la conversación anterior ya habíamos hablado de "${lastHotel}". DEBÉS llamar buscarHotel(nombre_hotel="${lastHotel}") o consultarCatalogoHoteles(hotel_especifico="${lastHotel}") ANTES de responder. No uses memoria ni historial; traé datos frescos de la función.]`; })()
        : '';
    // Refuerzo para consultas cortas/ambiguas: usar hotel previo del chat y evitar "no entendí".
    const shortAmbiguousKeywords = ['info', 'detalle', 'detalles', 'precio', 'tarifa', 'valor', 'cuanto sale', 'cuánto sale', 'incluye', 'que incluye', 'qué incluye'];
    const esConsultaAmbigua = !hotelExtraido
        && !!lastHotel
        && !pareceConsultaHotel
        && mensajeLower.length <= 80
        && shortAmbiguousKeywords.some(kw => mensajeLower.includes(kw));
    const hintAmbiguoConContexto = esConsultaAmbigua
        ? (() => {
            console.log(`🔄 Flor: refuerzo contexto - consulta ambigua, forzando hotel previo="${lastHotel}"`);
            return ` [SEGUIMIENTO AMBIGUO - OBLIGATORIO: El usuario hizo una consulta corta sin nombrar hotel, pero en esta conversación el hotel en contexto es "${lastHotel}". Debés llamar buscarHotel(nombre_hotel="${lastHotel}") o consultarCatalogoHoteles(hotel_especifico="${lastHotel}") ANTES de responder. No pidas destino de nuevo.]`;
        })()
        : '';
    let userPart = `${multiConsultasNote}Mensaje del cliente: ${mensaje}${hintCampana}${hintHotel}${hintContextDrift}${hintAmbiguoConContexto}`;
    if (imageParts && imageParts.length > 0) {
        userPart += ' [ANUNCIO/PUBLICIDAD: Analizá esta imagen publicitaria. Identificá el hotel (Puyehue, Corralco o Huilo Huilo) y respondé basándote EXCLUSIVAMENTE en ese hotel. IGNORÁ el historial previo; priorizá solo lo que ves en esta imagen. Llamá consultarCatalogoHoteles con el nombre del hotel que identifiques en la imagen.]';
    }

    // Historial de sesión para seguimiento ("¿Y tiene spa?")
    const now = Date.now();
    if (florLastActivityByPhone.get(phoneKey) && (now - florLastActivityByPhone.get(phoneKey)) > FLOR_SESSION_INACTIVITY_MS) {
        florSessionByPhone.delete(phoneKey);
        florFailureCountByPhone.set(phoneKey, 0);
        florLastHotelByPhone.delete(phoneKey);
        console.log(`🔄 Flor: reset de contexto por inactividad >30 min (${phoneKey})`);
    }
    florLastActivityByPhone.set(phoneKey, now);
    // Context window: últimos 10 mensajes del chat desde Supabase para que Flor no olvide (ej: "estábamos hablando de Huilo Huilo")
    let sessionHistory = (imageParts && imageParts.length > 0) ? [] : (florSessionByPhone.get(phoneKey) || []);
    const historialDesdeBD = await obtenerUltimosMensajesChat(contexto.numero, CONFIG.INSTANCE_NUMBER, 10);
    if (historialDesdeBD && historialDesdeBD.length > 0) {
        sessionHistory = historialDesdeBD;
        if (sessionHistory.length > 0) {
            console.log(`📜 Flor: usando ${sessionHistory.length} mensajes del chat como context window`);
        }
    }
    const lastMessages = sessionHistory.slice(-10);
    const userMessageParts = [{ text: userPart }];
    if (imageParts && imageParts.length > 0) {
        for (const img of imageParts) {
            userMessageParts.push({
                inlineData: { mimeType: img.mimeType || 'image/jpeg', data: img.data }
            });
        }
    }
    const contents = [
        ...lastMessages,
        { role: 'user', parts: userMessageParts }
    ];

    const toolDeclarations = [
        {
            name: 'consultarCatalogoHoteles',
            description: 'Busca y devuelve la narrativa poética, imágenes (img_general, img_spa, etc.), detalles técnicos, programas, spa, cartas y promociones de hoteles desde la base de datos de Supabase. OBLIGATORIO llamar esta función ANTES de responder cualquier consulta sobre un hotel o destino; sin llamarla no tenés datos reales. Si el cliente pregunta "qué hoteles tienen" o "qué opciones hay", llamá SIN ubicacion ni hotel_especifico (devuelve el listado). Si menciona nombre (Puyehue, Corralco, Huilo Huilo, Futangue) o ubicación (Patagonia, Bariloche), pasá hotel_especifico y/o ubicacion. El resultado incluye nombre, descripcion, servicios, detalles_programas, img_general, PDFs y promociones; usá esos datos para tu respuesta.',
            parameters: {
                type: 'OBJECT',
                properties: {
                    ubicacion: { type: 'STRING', description: 'Ciudad o región (ej: Patagonia, Bariloche). Opcional.' },
                    hotel_especifico: { type: 'STRING', description: 'Nombre del hotel o término que dijo el cliente (Puyehue, Corralco, Huilo Huilo, Guilo, Futangue). Opcional pero recomendado cuando piden info de un hotel concreto.' }
                }
            }
        },
        {
            name: 'buscarHotel',
            description: 'Busca UN hotel específico por nombre y devuelve su narrativa poética, imágenes (img_general, img_spa), detalles técnicos, programas, spa, cartas y promociones desde Supabase. Usar cuando el usuario pida "detalles de X", "info de X", "contame de X", "dame los detalles" o "dejame darte los detalles". OBLIGATORIO llamar esta función ANTES de responder con datos del hotel; el backend ejecuta la consulta y te devuelve el JSON; recién entonces generá tu respuesta. No respondas solo con texto de confirmación sin haber llamado buscarHotel.',
            parameters: {
                type: 'OBJECT',
                properties: {
                    nombre_hotel: { type: 'STRING', description: 'Nombre del hotel (Puyehue, Corralco, Huilo Huilo, Guilo, Futangue, etc.).' }
                },
                required: ['nombre_hotel']
            }
        },
        {
            name: 'enviarDocumentoPorWhatsApp',
            description: 'Envía un PDF por WhatsApp como archivo (no como link). Usalo cuando el cliente pida el detalle en PDF (menú spa, carta restaurante, excursiones). Pasá la URL del PDF (del resultado de consultarCatalogoHoteles) y un nombre de archivo amigable (ej. menu-spa.pdf).',
            parameters: {
                type: 'OBJECT',
                properties: {
                    url: { type: 'STRING', description: 'URL pública del PDF (ej. de Supabase Storage o del hotel).' },
                    nombre_archivo: { type: 'STRING', description: 'Nombre del archivo para el usuario (ej. menu-spa.pdf, carta-restaurante.pdf).' }
                },
                required: ['url']
            }
        },
        {
            name: 'enviarImagenHotelPorWhatsApp',
            description: 'Envía la imagen del hotel por WhatsApp. Usalo cuando el cliente pida "cómo es el hotel", "foto del hotel", "imagen", "mostrame el hotel". Pasá la URL img_general del hotel (del resultado de consultarCatalogoHoteles) y el nombre del hotel. NUNCA incluyas Base64 ni data:image en tu respuesta; usá esta función.',
            parameters: {
                type: 'OBJECT',
                properties: {
                    url: { type: 'STRING', description: 'URL pública de la imagen (img_general del hotel, ej. de Supabase Storage).' },
                    nombre_hotel: { type: 'STRING', description: 'Nombre del hotel para el caption (ej. Hotel Huilo Huilo).' }
                },
                required: ['url']
            }
        }
    ];

    const model = aiConfig.model || CONFIG.GEMINI_MODEL || 'gemini-3.1-flash-lite-preview';
    const temperature = aiConfig.temperature !== undefined ? aiConfig.temperature : 0.3;
    let configured = aiConfig.maxTokens !== undefined
        ? Number(aiConfig.maxTokens)
        : (parseInt(process.env.FLOR_MAX_OUTPUT_TOKENS || String(FLOR_MAX_OUTPUT_TOKENS_MIN), 10) || FLOR_MAX_OUTPUT_TOKENS_MIN);
    if (!Number.isFinite(configured) || configured < 1) {
        configured = FLOR_MAX_OUTPUT_TOKENS_MIN;
    }
    const maxTokens = Math.max(FLOR_MAX_OUTPUT_TOKENS_MIN, Math.min(Math.floor(configured), 8192));
    const startTime = Date.now();

    console.log(`🌸 Flor → Gemini (model=${model}, maxOutputTokens=${maxTokens}), mensaje=${mensaje.length} chars, herramientas consultarCatalogoHoteles + buscarHotel activas${pareceConsultaHotel ? ', hint hotel inyectado' : ''}`);

    try {
        let currentContents = contents;
        let finalText = null;
        const maxToolRounds = 3;
        let toolWasCalled = false;
        let documentToSend = null;
        let imageToSend = null;
        // CoT: la respuesta al usuario solo se devuelve al terminar el loop; cada tool (buscarHotel, consultarCatalogoHoteles) se await, así que la promesa no se resuelve antes de que las búsquedas terminen.

        for (let round = 0; round < maxToolRounds; round++) {
            const requestBody = {
                systemInstruction: { parts: [{ text: systemPart }] },
                contents: currentContents,
                tools: [{ functionDeclarations: toolDeclarations }],
                generationConfig: {
                    temperature,
                    maxOutputTokens: maxTokens
                }
            };

            let response = null;
            const maxRetries = 5;
            for (let attempt = 0; attempt < maxRetries; attempt++) {
                try {
                    response = await axios.post(
                        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${CONFIG.GEMINI_API_KEY}`,
                        requestBody,
                        { headers: { 'Content-Type': 'application/json' }, timeout: 45000 }
                    );
                    break;
                } catch (retryError) {
                    if (retryError.response?.status === 429 && attempt < maxRetries - 1) {
                        const waitMs = Math.pow(attempt + 1, 2) * 2000;
                        console.warn(`⚠️ Error 429. Reintento ${attempt + 1}/${maxRetries}...`);
                        await new Promise(resolve => setTimeout(resolve, waitMs));
                        continue;
                    }
                    throw retryError;
                }
            }

            const candidate = response?.data?.candidates?.[0];
            if (!candidate?.content?.parts?.length) {
                console.warn('⚠️ Gemini sin parts en la respuesta');
                break;
            }

            const finishReason = candidate.finishReason || candidate.finish_reason;
            if (finishReason && finishReason !== 'STOP') {
                console.warn(`⚠️ Flor Gemini finishReason=${finishReason} (si es MAX_TOKENS, subí flor_ai_config.maxTokens o FLOR_MAX_OUTPUT_TOKENS; mínimo servidor=${FLOR_MAX_OUTPUT_TOKENS_MIN})`);
            }

            const parts = candidate.content.parts;
            let textPart = null;
            const functionCalls = [];
            for (const p of parts) {
                if (p.text) textPart = p.text;
                if (p.functionCall) functionCalls.push(p.functionCall);
            }

            if (functionCalls.length > 0) {
                console.log(`🔧 Flor: Gemini envió ${functionCalls.length} function_call(s): ${functionCalls.map(fc => fc.name).join(', ')}`);
            } else if (textPart) {
                const fr = candidate.finishReason || candidate.finish_reason || '';
                console.log(`📝 Flor: Gemini devolvió solo texto (sin function_call), ${textPart.length} chars, finishReason=${fr || 'n/a'}`);
            }

            if (functionCalls.length > 0) {
                let modelParts = cloneModelPartsForToolFollowup(parts);
                if (!modelParts.some(p => p && p.functionCall)) {
                    console.warn('⚠️ Flor: parts sin functionCall; fallback sin thought signatures (Gemini 3 puede responder 400)');
                    modelParts = functionCalls.map(fc => ({ functionCall: fc }));
                }
                const functionResponses = [];
                for (const fc of functionCalls) {
                    if (fc.name === 'consultarCatalogoHoteles') {
                        toolWasCalled = true;
                        const args = fc.args || {};
                        const resultado = await consultarCatalogoHotelesTool(args.ubicacion, args.hotel_especifico);
                        functionResponses.push({ name: fc.name, response: resultado });
                        console.log(`🔧 Flor llamó consultarCatalogoHoteles(ubicacion=${args.ubicacion}, hotel_especifico=${args.hotel_especifico}) → ${resultado.encontrado ? resultado.hoteles?.length + ' hotel(es)' : 'no encontrado'}`);
                        // Context Drift fix: guardar último hotel consultado para forzar reconsulta en "¿Qué incluye?"
                        if (resultado.encontrado && resultado.hoteles?.length > 0) {
                            const lastHotel = (args.hotel_especifico && String(args.hotel_especifico).trim()) || resultado.hoteles[0]?.nombre || '';
                            if (lastHotel) florLastHotelByPhone.set(phoneKey, lastHotel);
                        }
                    } else if (fc.name === 'buscarHotel') {
                        toolWasCalled = true;
                        const args = fc.args || {};
                        const nombreHotel = (args.nombre_hotel && String(args.nombre_hotel).trim()) || '';
                        const resultado = await consultarCatalogoHotelesTool('', nombreHotel);
                        functionResponses.push({ name: fc.name, response: resultado });
                        console.log(`🔧 Flor llamó buscarHotel(nombre_hotel=${nombreHotel}) → ${resultado.encontrado ? resultado.hoteles?.length + ' hotel(es)' : 'no encontrado'}`);
                        if (resultado.encontrado && resultado.hoteles?.length > 0 && nombreHotel) {
                            florLastHotelByPhone.set(phoneKey, nombreHotel);
                        }
                    } else if (fc.name === 'enviarDocumentoPorWhatsApp') {
                        const args = fc.args || {};
                        const url = (args.url && String(args.url).trim()) || '';
                        const fileName = (args.nombre_archivo && String(args.nombre_archivo).trim()) || 'documento.pdf';
                        if (url) {
                            documentToSend = { url, fileName: fileName.endsWith('.pdf') ? fileName : fileName + '.pdf' };
                            console.log(`📄 Flor solicitó enviar PDF por WhatsApp: ${fileName}`);
                        }
                        functionResponses.push({ name: fc.name, response: { enviado: true, mensaje: 'El documento se enviará por WhatsApp.' } });
                    } else if (fc.name === 'enviarImagenHotelPorWhatsApp') {
                        const args = fc.args || {};
                        const imgUrl = (args.url && String(args.url).trim()) || '';
                        const nombreHotel = (args.nombre_hotel && String(args.nombre_hotel).trim()) || 'Hotel';
                        if (imgUrl && !imgUrl.startsWith('data:')) {
                            imageToSend = { url: imgUrl, caption: `📍 ${nombreHotel}\n\nTe comparto una foto del hotel.` };
                            console.log(`🖼️ Flor solicitó enviar imagen del hotel por WhatsApp: ${nombreHotel}`);
                        }
                        functionResponses.push({ name: fc.name, response: { enviado: true, mensaje: 'La imagen se enviará por WhatsApp.' } });
                    }
                }
                if (functionResponses.length > 0) {
                    const userParts = functionResponses.map(fr => ({ functionResponse: fr }));
                    currentContents = [
                        ...currentContents,
                        { role: 'model', parts: modelParts },
                        { role: 'user', parts: userParts }
                    ];
                    if (functionCalls.length > 1) console.log(`🔄 Flor: Parallel Function Calling - ${functionCalls.length} herramientas en un turno`);
                    continue;
                }
            }

            if (textPart && functionCalls.length === 0) {
                finalText = textPart;
                break;
            }
            if (textPart && functionCalls.length > 0 && functionResponses.length === 0) {
                finalText = textPart;
                break;
            }
            break;
        }

        if (!finalText && pareceConsultaHotel && !toolWasCalled) {
            console.warn(`⚠️ Flor: mensaje parecía consulta de hotel pero Gemini NO llamó consultarCatalogoHoteles ni buscarHotel. Revisar prompt en Supabase (flor_general_config) y que el servidor use el código actual.`);
        }
        if (!finalText) {
            console.log(`🔄 Flor: Gemini no devolvió texto después del loop. ¿Llamó la herramienta? Revisar logs anteriores.`);
        }

        if (finalText) {
            // Filtro selectivo: solo quitar bloques técnicos (código, JSON crudo, datos Base64), no texto humano ni la palabra "base64" en prosa
            const tieneBloqueBase64 = /data:image\/[^;]+;base64,[A-Za-z0-9+/=]{50,}/.test(finalText);
            const tieneCodigo = /\bprint\s*\(|default_api|function\s*\([^)]*\)\s*\{/.test(finalText);
            if (tieneBloqueBase64 || tieneCodigo) {
                const antes = finalText;
                finalText = finalText
                    .replace(/data:image\/[^;]+;base64,[A-Za-z0-9+/=]+/g, '')
                    .replace(/\n[^\n]*(?:print\s*\(|default_api)[^\n]*/gi, '')
                    .replace(/\bprint\s*\([^)]*\)[^.\n]*/gi, '')
                    .replace(/default_api[^\s\n]*/gi, '')
                    .replace(/\n{3,}/g, '\n\n').trim();
                if (finalText !== antes) console.warn('⚠️ Flor: se eliminó bloque técnico (código/Base64) de la respuesta; se mantuvo el texto humano');
            }
            if (!finalText || finalText.length < 20) {
                if (toolWasCalled) {
                    finalText = 'Encontré la información del hotel en nuestro sistema. ¿Podés decirme qué necesitás? Por ejemplo: programas de invierno o verano, menú spa, carta del restaurante.';
                    console.warn('⚠️ Flor: respuesta filtrada vacía pero hubo datos de catálogo; usando fallback con referencia al catálogo');
                } else {
                    finalText = 'Te comparto la información solicitada. ¿Necesitás algo más?';
                    console.warn('⚠️ Flor: respuesta filtrada quedó vacía; usando mensaje fallback');
                }
            }
            const responseTime = Date.now() - startTime;
            const finalLower = (finalText || '').toLowerCase();
            const pareceNoEntendido = /no he podido entender|no (pude|pudo) entender|no entiendo|no (logro|logr[eé]) (entender|interpretar)/i.test(finalLower);
            if (pareceConsultaHotel && pareceNoEntendido) {
                console.warn(`⚠️ Flor: Gemini devolvió texto tipo "no entiendo" en vez de llamar consultarCatalogoHoteles. Revisar flor_general_config en Supabase. Preview: ${finalText.slice(0, 120).replace(/\n/g, ' ')}...`);
            } else {
                console.log(`✅ Flor respondió (${model}, ${responseTime}ms)`);
            }
            florFailureCountByPhone.set(phoneKey, 0); // reset fallos al responder bien
            const newTurns = [...sessionHistory, { role: 'user', parts: [{ text: userPart }] }, { role: 'model', parts: [{ text: finalText }] }];
            florSessionByPhone.set(phoneKey, newTurns.slice(-FLOR_SESSION_MAX_MESSAGES));
            // Intent para flor_interactions: consulta_hotel si usó la herramienta, consulta_hotel_sin_resolver si era de hotel pero no la llamó
            const intent = toolWasCalled ? 'consulta_hotel' : (pareceConsultaHotel ? 'consulta_hotel_sin_resolver' : 'consulta_general');
            const result = { text: finalText, intent };
            if (documentToSend) result.sendDocument = documentToSend;
            if (imageToSend) result.sendImage = imageToSend;
            return result;
        }
    } catch (error) {
        const responseTime = Date.now() - startTime;
        if (error.response?.status === 429) {
            console.error(`❌ Error 429: Rate limit de Gemini excedido.`);
            const msg = (responses.rateLimitExceeded && responses.rateLimitExceeded.trim()) ? responses.rateLimitExceeded.trim() : FLOR_RESPONSES_DEFAULTS.rateLimitExceeded;
            return { text: msg, intent: 'rate_limit_429' };
        }
        if (error.response?.status === 404) {
            console.error(`❌ Error 404: Modelo ${model} no encontrado.`);
        } else if (error.response?.status === 400) {
            const errBody = error.response?.data;
            const errMsg = errBody?.error?.message || errBody?.message || (typeof errBody === 'string' ? errBody : JSON.stringify(errBody || {}).slice(0, 500));
            console.error('❌ Error 400 de Gemini:', errMsg);
            if (errBody && typeof errBody === 'object') console.error('   Detalle:', JSON.stringify(errBody).slice(0, 800));
        } else if (error.response?.status === 403) {
            const errBody403 = error.response?.data;
            const errMsg403 = errBody403?.error?.message || errBody403?.message || (typeof errBody403 === 'string' ? errBody403 : '');
            console.error('❌ Error 403 de Gemini:', errMsg403 || 'API key sin permisos o cuota excedida.');
            if (errBody403 && typeof errBody403 === 'object') console.error('   Detalle:', JSON.stringify(errBody403).slice(0, 500));
        } else if (error.code === 'ECONNABORTED') {
            console.error('❌ Timeout al procesar con Flor (30s).');
        } else {
            console.error('❌ Error procesando con Flor:', error.message || error.response?.data || error);
        }
        console.log('🔄 Usando respuesta predefinida: noEntendido');
        const msg = maybeResetContextAndNoEntendido(phoneKey, responses.noEntendido);
        const intent = pareceConsultaHotel ? 'consulta_hotel_sin_resolver' : 'consulta_general';
        return { text: msg, intent, enviarSlackAlerta: true };
    }

    console.log('🔄 Usando respuesta predefinida: noEntendido (sin respuesta de IA)');
    const msg = maybeResetContextAndNoEntendido(phoneKey, responses.noEntendido);
    const intent = pareceConsultaHotel ? 'consulta_hotel_sin_resolver' : 'consulta_general';
    return { text: msg, intent, enviarSlackAlerta: true };
}

/**
 * Si el usuario acumula 2 respuestas "no entiendo" seguidas, se resetea el contexto
 * y se devuelve un mensaje para empezar de nuevo (evita el bucle).
 */
function maybeResetContextAndNoEntendido(phoneKey, noEntendidoMsg) {
    const count = (florFailureCountByPhone.get(phoneKey) || 0) + 1;
    florFailureCountByPhone.set(phoneKey, count);
    if (count >= 2) {
        florSessionByPhone.delete(phoneKey);
        florFailureCountByPhone.set(phoneKey, 0);
        florLastHotelByPhone.delete(phoneKey);
        console.log(`🔄 Flor: reset de contexto tras ${count} fallos consecutivos (${phoneKey})`);
        return 'Parece que hubo un problema para entender. ¿Empezamos de nuevo? Escribí, por ejemplo: "info del Hotel Huilo Huilo" o "qué hoteles tienen?".';
    }
    return noEntendidoMsg;
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
            ai_model: CONFIG.GEMINI_MODEL || 'gemini-3.1-flash-lite-preview',
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
        // PRIMERO: Intentar con whatsapp_chats (estructura principal que usa el dashboard)
        // Buscar chat existente: probar numero tal cual y con @s.whatsapp.net (formato que guarda WhatsApp)
        const numerosABuscar = [numero];
        if (numero && !String(numero).includes('@')) {
            numerosABuscar.push(String(numero).trim() + '@s.whatsapp.net');
        }
        if (numero && String(numero).endsWith('@s.whatsapp.net')) {
            numerosABuscar.push(String(numero).replace(/@s\.whatsapp\.net$/, '').trim());
        }
        for (const num of numerosABuscar) {
            const { data: chatExistente, error: errorBuscarChat } = await supabase
                .from('whatsapp_chats')
                .select('id')
                .eq('phone', num)
                .eq('whatsapp_instance', CONFIG.INSTANCE_NUMBER)
                .maybeSingle();
            if (chatExistente && !errorBuscarChat) {
                console.log(`✅ Chat existente encontrado en whatsapp_chats para ${numero} (phone=${num})`);
                return chatExistente.id;
            }
        }

        // Si no está en whatsapp_chats, buscar en whatsapp_conversations por external_id (evita duplicado y error unique)
        const { data: convExistente } = await supabase
            .from('whatsapp_conversations')
            .select('id')
            .eq('external_id', String(numero))
            .maybeSingle();
        if (convExistente?.id) {
            console.log(`✅ Conversation existente en whatsapp_conversations para ${numero}, usando id: ${convExistente.id}`);
            return convExistente.id;
        }

        // Si no existe, crear uno nuevo en whatsapp_chats (nombre y real_phone para mostrar en dashboard)
        const dIns = String(numero ?? '').replace(/\D/g, '');
        const nombreIns = nombre != null ? String(nombre).trim() : '';
        const nameLooksLikeLidOnly = nombreIns && nombreIns.replace(/\D/g, '') === dIns;
        const insertPayload = {
            phone: numero,
            name: isLikelyPseudoWhatsappPn(dIns) && (!nombreIns || nameLooksLikeLidOnly) ? 'Cliente' : (nombre || numero),
            whatsapp_instance: CONFIG.INSTANCE_NUMBER,
            status: 'active',
            last_message: '',
            unread_count: 0
        };
        if (isRealPhoneForStorage(numero)) {
            insertPayload.real_phone = String(numero).replace(/^\+/, '').trim();
        }
        const { data: nuevoChat, error: errorCrearChat } = await supabase
            .from('whatsapp_chats')
            .insert(insertPayload)
            .select('id')
            .single();

        if (nuevoChat && !errorCrearChat) {
            console.log(`✅ Nuevo chat creado en whatsapp_chats para ${numero} (ID: ${nuevoChat.id})`);
            
            // OPCIONAL: También crear en whatsapp_conversations si existe (para compatibilidad)
            try {
                const { error: errorConv } = await supabase
                    .from('whatsapp_conversations')
                    .upsert({
                        id: nuevoChat.id, // Usar el mismo ID para mantener sincronización
                        external_id: numero,
                        status: 'open',
                        metadata: {
                            phone: numero,
                            name: nombre || numero,
                            whatsapp_instance: CONFIG.INSTANCE_NUMBER
                        }
                    }, { onConflict: 'external_id' }); // AHORA CONFLICTO POR external_id
                if (!errorConv) {
                    console.log(`✅ Chat también creado/actualizado en whatsapp_conversations para ${numero}`);
                } else {
                    console.warn('⚠️ Error creando/actualizando chat en whatsapp_conversations:', errorConv.message);
                }
            } catch (e) {
                // Ignorar si la tabla no existe o hay error
                console.log('ℹ️ whatsapp_conversations no disponible o error (ignorado en catch): ', e.message);
            }
            
            return nuevoChat.id;
        } else if (errorCrearChat) {
            console.error('❌ Error creando chat en whatsapp_chats:', errorCrearChat.message || errorCrearChat);
            console.error('   Detalles:', JSON.stringify(errorCrearChat, null, 2));
            console.error('   Número:', numero);
            console.error('   Nombre:', nombre);
            // Verificar si es error de cuota
            if (errorCrearChat.message && (errorCrearChat.message.includes('quota') || errorCrearChat.message.includes('limit') || errorCrearChat.message.includes('exceeded'))) {
                console.error('   ⚠️ PROBLEMA: Supabase está bloqueando la creación por cuota excedida');
            }
        } else if (!nuevoChat) {
            console.warn('⚠️ Creación de chat no devolvió datos (puede estar bloqueada por cuota de Supabase)');
            console.warn('   Número:', numero);
            console.warn('   Error:', errorCrearChat);
        }

        // Si todo falla, retornar null
        console.warn('⚠️ No se pudo obtener/crear chat_id para', numero);
        return null;
    } catch (error) {
        console.warn('⚠️ Error obteniendo/creando chat_id:', error.message);
        return null;
    }
}

/**
 * Intentar obtener el número real de teléfono cuando el contacto usa JID @lid (WhatsApp no siempre lo expone).
 * Baileys 6.8+ puede tener signalRepository.getLIDMappingStore().getPNForLID(lid).
 */
function resolveLidToPhone(sock, remoteJid) {
    if (!sock || !remoteJid || !String(remoteJid).includes('@lid')) return null;
    try {
        const store = sock.signalRepository?.getLIDMappingStore?.();
        if (!store || typeof store.getPNForLID !== 'function') return null;
        const lid = String(remoteJid).trim();
        const phone = store.getPNForLID(lid);
        if (phone && /^[0-9]{10,}$/.test(String(phone).replace(/^\+/, ''))) return String(phone).replace(/^\+/, '');
        return null;
    } catch (e) {
        return null;
    }
}

/**
 * PN en @s.whatsapp.net a veces NO es E.164 (IDs internos tipo 133…, 125… de 15 dígitos); no usar para pausa en DB.
 * Móviles AR suelen ser 549 + ~10 dígitos (longitud total ~12–13).
 */
function isLikelyPseudoWhatsappPn(digits) {
    const d = String(digits || '').replace(/\D/g, '');
    if (d.length < 10 || d.length > 15) return true;
    if (d.length >= 14 && d.startsWith('133')) return true;
    if (d.length >= 14 && d.startsWith('125')) return true;
    if (d.length >= 15 && !d.startsWith('54')) return true;
    return false;
}

/**
 * Para guardar en whatsapp_chats.real_phone / no pisar con LID: los LID son 10–15 dígitos pero NO son MSISDN.
 * Antes /^\+?[0-9]{10,}$/ marcaba 280671952093251 como “teléfono” y sobrescribía real_phone con el LID.
 */
function isRealPhoneForStorage(numero) {
    const s = String(numero ?? '').trim();
    if (!s || s.includes('@')) return false;
    const d = s.replace(/\D/g, '');
    if (d.length < 10 || d.length > 15) return false;
    if (isLikelyPseudoWhatsappPn(d)) return false;
    return true;
}

/** Número de teléfono del propio bot (sin @), para no “pausar Flor” contra uno mismo. */
function getOurBotPhoneDigits() {
    const raw = phoneNumber || (sock?.user?.id && String(sock.user.id).split(':')[0]) || '';
    return String(raw).replace(/\D/g, '');
}

function isOurBotPhoneDigits(digits) {
    const d = String(digits || '').replace(/\D/g, '');
    const ours = getOurBotPhoneDigits();
    if (!ours || d.length < 10) return false;
    return d === ours || d.endsWith(ours) || ours.endsWith(d);
}

function jidPnToE164(jidStr) {
    if (!jidStr || typeof jidStr !== 'string') return null;
    if (!jidStr.includes('@s.whatsapp.net')) return null;
    const pn = jidStr.replace(/@s\.whatsapp\.net$/i, '').trim();
    if (!pn || !/^[0-9]{10,}$/.test(pn.replace(/^\+/, ''))) return null;
    const d = pn.replace(/\D/g, '');
    if (isLikelyPseudoWhatsappPn(d) || isOurBotPhoneDigits(d)) return null;
    return '+' + d;
}

/** Algunas versiones de Baileys ponen peer_recipient_pn solo en el envelope, no en key. */
function extractPeerRecipientPnFromMessage(msg) {
    if (!msg) return null;
    const blobs = [msg, msg.key, msg.message, msg.message?.extendedTextMessage?.contextInfo].filter(Boolean);
    const names = ['peerRecipientPn', 'peer_recipient_pn', 'recipientPn', 'recipient_pn'];
    for (const b of blobs) {
        for (const n of names) {
            const v = b[n];
            if (v && typeof v === 'string') {
                const e = jidPnToE164(v);
                if (e) return e;
            }
        }
    }
    return null;
}

/** Recorre el objeto del mensaje (attrs internos, etc.) buscando un JID *@s.whatsapp.net válido. */
function deepScanMessageForRecipientPn(obj, depth, visited) {
    if (depth > 10 || !obj || typeof obj !== 'object') return null;
    try {
        if (visited.has(obj)) return null;
        visited.add(obj);
    } catch (e) {
        return null;
    }
    if (Array.isArray(obj)) {
        for (let i = 0; i < obj.length; i++) {
            const r = deepScanMessageForRecipientPn(obj[i], depth + 1, visited);
            if (r) return r;
        }
        return null;
    }
    for (const v of Object.values(obj)) {
        if (typeof v === 'string' && v.length > 8 && v.length < 200 && /\d{8,}@s\.whatsapp\.net/i.test(v)) {
            const e = jidPnToE164(v);
            if (e) return e;
        } else if (v && typeof v === 'object') {
            const r = deepScanMessageForRecipientPn(v, depth + 1, visited);
            if (r) return r;
        }
    }
    return null;
}

/**
 * JID definitivo para enviar respuestas de Flor. Si solo hay @lid, el cliente suele mostrar "Esperando mensaje";
 * prioriza PN ya resuelto, senderPn en cola, deepScan, LID store, Supabase y onWhatsApp.
 */
async function resolveFlorSendJid(sock, p) {
    const rjLow = p.remoteJid && String(p.remoteJid).trim().toLowerCase();
    if (rjLow && rjLow.includes('@lid') && florLidToPnSendJid.has(rjLow)) {
        const j = florLidToPnSendJid.get(rjLow);
        console.log(`📤 Envío Flor: caché LID→PN → ${j}`);
        return j;
    }
    const fb = (p.jidDestino && String(p.jidDestino).trim()) || (p.remoteJid && String(p.remoteJid).trim());
    if (fb && fb.includes('@s.whatsapp.net') && !fb.toLowerCase().includes('@lid')) {
        const e164 = jidPnToE164(fb);
        if (e164) {
            const d = e164.replace(/\D/g, '');
            return `${d}@s.whatsapp.net`;
        }
    }
    for (const entry of p.messages || []) {
        const msg = entry.msg;
        if (!msg) continue;
        const k = msg.key;
        const sp = k && (k.senderPn || k.sender_pn);
        if (sp && String(sp).includes('@s.whatsapp.net')) {
            const e164 = jidPnToE164(String(sp));
            if (e164) {
                const d = e164.replace(/\D/g, '');
                console.log(`📤 Envío Flor: PN desde msg.key.senderPn → ${d}@s.whatsapp.net`);
                return `${d}@s.whatsapp.net`;
            }
        }
        const fromPeer = extractPeerRecipientPnFromMessage(msg);
        if (fromPeer) {
            const d = fromPeer.replace(/\D/g, '');
            console.log(`📤 Envío Flor: peer_recipient_pn → ${d}@s.whatsapp.net`);
            return `${d}@s.whatsapp.net`;
        }
        const deep = deepScanMessageForRecipientPn(msg, 0, new WeakSet());
        if (deep) {
            const d = deep.replace(/\D/g, '');
            console.log(`📤 Envío Flor: deepScan(cola) → ${d}@s.whatsapp.net`);
            return `${d}@s.whatsapp.net`;
        }
    }
    if (p.numero && String(p.numero).trim().startsWith('+')) {
        const nd = String(p.numero).replace(/\D/g, '');
        if (nd.length >= 10 && !isLikelyPseudoWhatsappPn(nd) && !isOurBotPhoneDigits(nd)) {
            return `${nd}@s.whatsapp.net`;
        }
    }
    const rj = p.remoteJid && String(p.remoteJid);
    if (rj && rj.includes('@lid') && sock) {
        const pn = resolveLidToPhone(sock, rj);
        if (pn) {
            console.log(`📤 Envío Flor: LID store → ${pn}@s.whatsapp.net`);
            return `${pn}@s.whatsapp.net`;
        }
        const lidDigits = rj.replace(/@lid$/i, '').replace(/:[0-9]+$/, '').replace(/\D/g, '');
        if (lidDigits.length >= 10) {
            const supPhone = await resolvePausePhoneViaSupabaseLid(lidDigits);
            if (supPhone) {
                const d = supPhone.replace(/\D/g, '');
                const basePn = `${d}@s.whatsapp.net`;
                const enriched = await enrichPnJidWithOnWhatsApp(sock, basePn);
                if (enriched === basePn) {
                    console.log(`📤 Envío Flor: Supabase (LID→tel) → ${basePn}`);
                }
                return enriched;
            }
        }
        try {
            if (typeof sock.onWhatsApp === 'function') {
                const r = await sock.onWhatsApp(rj);
                const arr = Array.isArray(r) ? r : r ? [r] : [];
                const j = arr.find((x) => x && x.jid && String(x.jid).includes('@s.whatsapp.net') && !String(x.jid).includes('@lid'));
                if (j?.jid) {
                    console.log(`📤 Envío Flor: onWhatsApp → ${j.jid}`);
                    return j.jid;
                }
            }
        } catch (e) {
            console.warn('⚠️ resolveFlorSendJid onWhatsApp:', e?.message || e);
        }
    }
    return fb || rj;
}

/**
 * Si el chat ya existe en Supabase con phone=LID o real_phone=LID y phone actualizado a +54…, usar ese +E.164 para pausa.
 */
async function resolvePausePhoneViaSupabaseLid(jidDigits) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE || !jidDigits) return null;
    const d = String(jidDigits).replace(/\D/g, '');
    if (d.length < 10) return null;
    try {
        const inst = CONFIG.INSTANCE_NUMBER || 1;
        const q = (col, val) =>
            supabase.from('whatsapp_chats').select('phone, real_phone').eq('whatsapp_instance', inst).eq(col, val).limit(5);
        const attempts = [() => q('phone', d), () => q('phone', '+' + d), () => q('real_phone', d), () => q('real_phone', '+' + d)];
        const seen = new Set();
        for (const run of attempts) {
            const { data, error } = await run();
            if (error || !data?.length) continue;
            for (const row of data) {
                const key = row.phone + '|' + row.real_phone;
                if (seen.has(key)) continue;
                seen.add(key);
                const raw = row.phone || row.real_phone;
                if (!raw) continue;
                const n = normalizarPhoneParaSupabase(raw);
                const nd = n.replace(/\D/g, '');
                if (n.startsWith('+') && nd.length >= 10 && !isLikelyPseudoWhatsappPn(nd) && !isOurBotPhoneDigits(nd)) {
                    return n;
                }
            }
        }
        return null;
    } catch (e) {
        return null;
    }
}

/**
 * Para mensajes salientes (fromMe) del humano: obtener el mismo identificador que usa el flujo entrante (+E.164),
 * así florPauseMemoryUntil y whatsapp_chats.flor_paused_until coinciden con isFlorPausedForChat.
 */
function resolvePhoneForFlorPauseFromOutgoing(sock, msg) {
    if (!msg?.key?.remoteJid) return null;
    const key = msg.key;
    const remoteJid = String(key.remoteJid);
    const jLower = remoteJid.trim().toLowerCase();
    let numero = remoteJid.replace(/@s\.whatsapp\.net$/i, '').replace(/@lid$/i, '').trim();

    // Baileys / WA: en salientes aparece peer_recipient_pn (PN real del cliente) aunque remoteJid sea @lid o PN interno
    const peerPn =
        key.peerRecipientPn ||
        key.peer_recipient_pn ||
        key.recipientPn ||
        key.recipient_pn;
    const fromPeer = jidPnToE164(typeof peerPn === 'string' ? peerPn : '');
    if (fromPeer) return fromPeer;
    const fromEnvelope = extractPeerRecipientPnFromMessage(msg);
    if (fromEnvelope) return fromEnvelope;

    const cacheKeys = [jLower, numero, `${numero}@s.whatsapp.net`, `${numero}@lid`].filter(Boolean);
    for (const ck of cacheKeys) {
        const hit = florJidToRealPhoneForPause.get(ck);
        if (hit && !isLikelyPseudoWhatsappPn(hit.replace(/^\+/, ''))) return hit;
    }

    const remoteJidAlt = msg.key.remoteJidAlt;
    if (remoteJidAlt && String(remoteJidAlt).includes('@s.whatsapp.net')) {
        const altNum = String(remoteJidAlt).replace('@s.whatsapp.net', '').trim();
        if (altNum && /^[0-9]{10,}$/.test(altNum.replace(/^\+/, ''))) {
            const realPhone = altNum.startsWith('+') ? altNum : '+' + altNum.replace(/\D/g, '');
            if (!isLikelyPseudoWhatsappPn(realPhone)) return realPhone;
        }
    }

    const scanKeyForPn = (key) => {
        if (!key) return null;
        const candidates = [
            key.peerRecipientPn,
            key.peer_recipient_pn,
            key.recipientPn,
            key.recipient_pn,
            key.senderPn,
            key.sender_pn,
            key.participant,
            key.participantAlt,
            key.participant_alt,
            key.remoteJidAlt,
            key.remote_jid_alt
        ].filter(Boolean);
        for (const k of Object.keys(key || {})) {
            const v = key[k];
            if (v && typeof v === 'string' && v.includes('@s.whatsapp.net')) candidates.push(v);
        }
        for (const jidStr of candidates) {
            const s = String(jidStr).trim();
            if (!s.includes('@s.whatsapp.net')) continue;
            const pn = s.replace(/@s\.whatsapp\.net$/i, '').trim();
            if (pn && /^[0-9]{10,}$/.test(pn.replace(/^\+/, ''))) {
                const d = pn.replace(/\D/g, '');
                if (!isLikelyPseudoWhatsappPn(d) && !isOurBotPhoneDigits(d)) return d.length >= 10 ? ('+' + d) : null;
            }
        }
        return null;
    };

    if (remoteJid.includes('@lid')) {
        let realPhone = resolveLidToPhone(sock, remoteJid);
        if (!realPhone) realPhone = scanKeyForPn(msg.key)?.replace(/^\+/, '');
        if (realPhone) {
            const d = String(realPhone).replace(/\D/g, '');
            if (d.length >= 10 && !isLikelyPseudoWhatsappPn(d) && !isOurBotPhoneDigits(d)) return '+' + d;
        }
    } else {
        // @s.whatsapp.net con dígitos que no son el móvil real: intentar LID store con sufijo @lid
        let realPhone = resolveLidToPhone(sock, `${numero}@lid`);
        if (!realPhone) realPhone = scanKeyForPn(msg.key)?.replace(/^\+/, '');
        if (realPhone) {
            const d = String(realPhone).replace(/\D/g, '');
            if (d.length >= 10 && !isLikelyPseudoWhatsappPn(d) && !isOurBotPhoneDigits(d)) return '+' + d;
        }
    }

    const deepPn = deepScanMessageForRecipientPn(msg, 0, new WeakSet());
    if (deepPn) return deepPn;

    const d = String(numero).replace(/\D/g, '');
    if (d.length >= 10 && !isLikelyPseudoWhatsappPn(d) && !isOurBotPhoneDigits(d)) return '+' + d;
    return null;
}

/** WhatsApp suele truncar ~4096 caracteres; enviar en partes si hace falta. */
async function enviarTextoWhatsAppEnPartes(sock, remoteJid, texto) {
    const max = 4090;
    const t = String(texto || '');
    if (t.length <= max) {
        await sock.sendMessage(remoteJid, { text: t });
        return;
    }
    let rest = t;
    let part = 0;
    while (rest.length > 0) {
        const chunk = rest.slice(0, max);
        rest = rest.slice(max);
        part += 1;
        await sock.sendMessage(remoteJid, { text: part > 1 ? `(continúa ${part})\n${chunk}` : chunk });
    }
    console.log(`📤 Flor: respuesta larga partida en ${part} mensaje(s) (${t.length} chars)`);
}

/**
 * Normaliza el número de teléfono para guardar en Supabase (campo phone).
 * Siempre devuelve un string: E.164 cuando es número real, o el valor limpio (ej. LID), nunca undefined ni el tipo de dato.
 */
function normalizarPhoneParaSupabase(numero) {
    if (numero == null || (typeof numero !== 'string' && typeof numero !== 'number')) return 'unknown';
    const s = String(numero).trim();
    if (s === '') return 'unknown';
    const digits = s.replace(/^\+/, '').replace(/\D/g, '');
    if (digits.length >= 10) {
        // No anteponer + a un LID (se confunde con E.164 en el dashboard)
        if (isLikelyPseudoWhatsappPn(digits)) return digits;
        return '+' + digits;
    }
    return s;
}

/**
 * Asegurar que exista la fila en whatsapp_conversations para el chatId.
 * Si whatsapp_messages.conversation_id tiene FK a whatsapp_conversations(id), el insert falla si no existe.
 * Usa onConflict: 'id' para actualizar la fila con ese id (p. ej. cuando pasamos de LID a número real)
 * y evitar duplicate key en pkey al intentar insertar un id que ya existe.
 */
async function asegurarConversationExiste(chatId, numero, nombre = null) {
    if (!supabase || !chatId) return;
    try {
        const { error } = await supabase
            .from('whatsapp_conversations')
            .upsert({
                id: chatId,
                external_id: String(numero),
                status: 'open',
                metadata: { phone: numero, name: nombre || numero, whatsapp_instance: CONFIG.INSTANCE_NUMBER }
            }, { onConflict: 'id' });
        if (error) {
            // Ignorar si la tabla no existe o el esquema es distinto
            if (error.code !== '42P01' && !error.message?.includes('does not exist')) {
                console.warn('⚠️ whatsapp_conversations upsert:', error.message);
            }
        }
    } catch (e) {
        // Tabla puede no existir
    }
}

/**
 * Guardar mensaje en Supabase
 * Estructura real: chat_id, phone, message, is_from_me, whatsapp_instance, message_type
 * @param {string} [chatIdFromDashboard] - Si viene del dashboard, usar este chat_id para no crear chats duplicados
 * @param {string} [messageType] - 'text' | 'audio' | 'voice' | 'image' para whatsapp_messages.message_type
 */
async function guardarMensaje(numero, mensaje, esEnviado = false, respuestaFlor = null, nombre = null, chatIdFromDashboard = null, messageType = 'text') {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE) return;

    try {
        let chatId = chatIdFromDashboard && String(chatIdFromDashboard).trim() ? String(chatIdFromDashboard).trim() : null;
        if (!chatId) {
            chatId = await obtenerOcrearChatId(numero, nombre);
        }
        
        if (!chatId) {
            console.error('❌ No se pudo obtener/crear chat_id. No se puede guardar el mensaje.');
            return;
        }

        // Si whatsapp_messages.conversation_id apunta a whatsapp_conversations(id), asegurar que exista la fila
        await asegurarConversationExiste(chatId, numero, nombre);

        // Número real para Supabase: siempre string explícito (E.164 o LID), nunca undefined ni tipo de dato
        const phoneParaInsert = normalizarPhoneParaSupabase(numero);

        // Estructura compatible con schema: conversation_id, chat_id, direction, sender, recipient, message, body, sent_at, phone, is_from_me, is_read, whatsapp_instance, message_type
        const direction = esEnviado ? 'outbound' : 'inbound';
        const sender = esEnviado ? (phoneNumber || `bot_${CONFIG.INSTANCE_NUMBER}`) : phoneParaInsert;
        const recipient = esEnviado ? phoneParaInsert : (phoneNumber || `bot_${CONFIG.INSTANCE_NUMBER}`);
        const nowIso = new Date().toISOString();
        const base = {
            conversation_id: chatId,
            chat_id: chatId,
            direction,
            sender,
            recipient,
            phone: phoneParaInsert,
            message: mensaje,
            body: mensaje,
            sent_at: nowIso,
            is_from_me: esEnviado,
            is_read: false,
            whatsapp_instance: CONFIG.INSTANCE_NUMBER
        };
        let datosMensaje = { ...base };
        let datosConTipo = { ...base, message_type: messageType || 'text' };

        // Log del objeto antes del insert (para verificar que phone llega en E.164 / valor real)
        console.log('📤 whatsapp_messages insert payload:', JSON.stringify({
            conversation_id: datosConTipo.conversation_id,
            chat_id: datosConTipo.chat_id,
            phone: datosConTipo.phone,
            direction: datosConTipo.direction,
            is_from_me: datosConTipo.is_from_me,
            message_preview: (datosConTipo.message || '').substring(0, 50)
        }));

        // Insertar: intentar con message_type; si falla por esa columna, sin ella
        let errorMensaje = null;
        let { error } = await supabase
            .from('whatsapp_messages')
            .insert(datosConTipo);

        if (error && error.message && error.message.includes('message_type')) {
            console.warn('⚠️ Tabla whatsapp_messages no tiene columna message_type, guardando sin ella');
            delete datosMensaje.message_type;
            ({ error } = await supabase.from('whatsapp_messages').insert(datosMensaje));
        }
        if (error && error.message && error.message.includes('chat_id')) {
            console.warn('⚠️ Tabla solo usa conversation_id, guardando sin chat_id');
            const { chat_id, ...soloConv } = datosMensaje;
            ({ error } = await supabase.from('whatsapp_messages').insert(soloConv));
        }
        if (error && (error.message?.includes('foreign key') || error.code === '23503')) {
            console.error('❌ Error FK al guardar mensaje: conversation_id debe existir en whatsapp_conversations. ChatId:', chatId, '- Creá/verificá la fila en whatsapp_conversations con id =', chatId);
        }
        errorMensaje = error;

        if (errorMensaje) {
            if (errorMensaje.message && errorMensaje.message.includes('Invalid API key')) {
                console.error('⚠️ Error: API key de Supabase inválida. Verifica SUPABASE_ANON_KEY en EasyPanel');
            } else if (!errorMensaje.message?.includes('foreign key') && errorMensaje.code !== '23503') {
                console.error('❌ Error guardando mensaje:', errorMensaje.message || errorMensaje);
            }
            return;
        }

        console.log(`✅ Mensaje guardado en whatsapp_messages: ${esEnviado ? 'enviado' : 'recibido'} de ${phoneParaInsert} (sender=${sender}, recipient=${recipient})`);

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
        
        // real_phone: solo MSISDN plausible; nunca LID (15 dígitos tipo 280…). name: no usar LID como nombre si no hay pushName.
        const dNum = String(numero ?? '').replace(/\D/g, '');
        const nombreStr = nombre != null ? String(nombre).trim() : '';
        const nombreEsSoloLid = nombreStr && nombreStr.replace(/\D/g, '') === dNum;
        const updatePayload = {
            last_message: mensajePreview,
            last_message_time: new Date().toISOString(),
            unread_count: unreadCount,
            updated_at: new Date().toISOString()
        };
        if (isLikelyPseudoWhatsappPn(dNum)) {
            if (nombreStr && !nombreEsSoloLid) updatePayload.name = nombreStr;
        } else {
            updatePayload.name = nombreStr || numero;
        }
        if (isRealPhoneForStorage(numero)) {
            updatePayload.real_phone = String(numero).replace(/^\+/, '').trim();
        }

        const { error: errorChat, data: dataChat } = await supabase
            .from('whatsapp_chats')
            .update(updatePayload)
            .eq('id', chatId)
            .select(); // Agregar .select() para verificar que se actualizó

        if (errorChat) {
            console.error('❌ Error actualizando whatsapp_chats:', errorChat.message || errorChat);
            console.error('   Detalles:', JSON.stringify(errorChat, null, 2));
            console.error('   Chat ID:', chatId);
            console.error('   Número:', numero);
        } else if (!dataChat || dataChat.length === 0) {
            console.warn('⚠️ Actualización de whatsapp_chats no devolvió datos (puede estar bloqueada por cuota de Supabase)');
            console.warn('   Chat ID:', chatId);
            console.warn('   Número:', numero);
            console.warn('   Mensaje preview:', mensajePreview);
            console.warn('   Esto indica que Supabase puede estar bloqueando la actualización debido a cuota excedida');
        } else {
            console.log(`✅ Chat actualizado en whatsapp_chats para ${numero} (ID: ${chatId})`);
            console.log(`   Último mensaje: ${mensajePreview.substring(0, 50)}...`);
            console.log(`   Datos devueltos por UPDATE:`, JSON.stringify(dataChat[0], null, 2));
            // Verificar si last_message se actualizó realmente
            if (dataChat[0] && dataChat[0].last_message !== mensajePreview) {
                console.warn('⚠️ ADVERTENCIA: last_message en la respuesta no coincide con el valor enviado');
                console.warn(`   Enviado: "${mensajePreview}"`);
                console.warn(`   Recibido: "${dataChat[0].last_message || '(vacío)'}"`);
                console.warn('   Esto indica que Supabase puede estar bloqueando la actualización de last_message');
            }
        }

    } catch (error) {
        if (error.message && !error.message.includes('Invalid API key')) {
            console.error('❌ Error guardando mensaje:', error.message || error);
        }
    }
}

// ===== FUNCIÓN PARA CONECTAR WHATSAPP =====

async function connectToWhatsApp() {
    const { state, saveCreds } = await useMultiFileAuthState(path.join(__dirname, `auth_info_baileys_${CONFIG.INSTANCE_NUMBER}`));
    
    const { version } = await fetchLatestBaileysVersion();
    
    sock = makeWASocket({
        logger: createFlorBaileysLogger(),
        auth: state,
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

    // Distinguir eco fromMe de Flor/API (mismo message id) vs humano escribiendo desde el celular
    const _origSendMessage = sock.sendMessage.bind(sock);
    sock.sendMessage = async function (...args) {
        const destJid = extractDestJidFromSendArgs(args);
        let phoneForMap = resolvePhoneForFlorSendDestination(sock, destJid);
        const res = await _origSendMessage(...args);
        try {
            if (res) registerFlorOutboundBaileysMessageIdsFromSendResult(res);
            // Enlace LID ↔ +E.164: los salientes humanos a veces traen otro @lid que el del mensaje entrante;
            // Flor puede enviar a PN *@s.whatsapp.net (jidDestino) cuando hay +E.164; el envío devuelve JIDs para el mapa de pausa.
            const sentRj = res?.key?.remoteJid;
            if (!phoneForMap && sentRj) phoneForMap = resolvePhoneForFlorSendDestination(sock, sentRj);
            if (phoneForMap && destJid && !String(destJid).includes('@g.us')) {
                rememberFlorChatJidToPhone(destJid, phoneForMap);
                if (sentRj && !String(sentRj).includes('@g.us')) rememberFlorChatJidToPhone(sentRj, phoneForMap);
                const jids = new Set();
                collectJidStringsForFlorPauseMap(res, 0, new WeakSet(), jids);
                for (const j of jids) {
                    if (j && !String(j).includes('@g.us')) rememberFlorChatJidToPhone(j, phoneForMap);
                }
            }
        } catch (e) { /* ignore */ }
        return res;
    };

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
                // Error 440 (conflict/replaced): DOS procesos usan la misma sesión. Delay MUY largo para que el otro muera.
                const isConflict440 = (statusCode === 440 || (error?.output?.payload?.message || '').includes('conflict'));
                if (isConflict440) {
                    console.error('❌ CONFLICTO 440: Otro proceso/contenedor está usando la misma sesión WhatsApp. Detené duplicados (docker ps | grep whatsapp) y esperá 90 segundos.');
                }
                console.log('🔄 Reconectando...');
                // Delay según tipo de error
                // 440 conflict: 90 segundos - dar tiempo a que el proceso duplicado termine
                // 401/device_removed: 10 segundos
                // 428: 5 segundos
                let reconnectDelay = 3000;
                if (isConflict440) {
                    reconnectDelay = 90000; // 90 segundos para 440
                } else if (isDeviceRemoved || statusCode === 401) {
                    reconnectDelay = 10000;
                } else if (statusCode === 428) {
                    reconnectDelay = 5000;
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
        console.log(`📨 Evento messages.upsert recibido - type: ${type}, cantidad: ${messages?.length || 0}`);
        
        // Procesar 'notify' (tiempo real) Y 'append' (mensajes offline/buffer al reconectar; anuncios pueden venir por append)
        if (type !== 'notify' && type !== 'append') {
            console.log(`⚠️ Tipo de mensaje no procesable (es '${type}'), ignorando...`);
            return;
        }
        if (type === 'append') {
            console.log(`📬 Procesando mensajes type=append (offline/buffer)`);
        }

        for (const msg of messages) {
            // Mensajes SALIENTES (fromMe): Baileys recibe también lo enviado por Flor y por el humano desde el teléfono.
            if (msg.key.fromMe) {
                const remoteJidOut = msg.key.remoteJid;
                if (remoteJidOut && String(remoteJidOut).includes('@g.us')) {
                    continue;
                }
                // Stubs del protocolo (llamada perdida, etc.): no son “humano escribiendo”.
                if (msg.message && typeof msg.message.messageStubType === 'number') {
                    continue;
                }
                if (msg.key.id && isFlorOutboundBaileysMessageId(msg.key.id)) {
                    // Eco del mismo proceso (Flor o API que usa sock.sendMessage); no pausar
                    continue;
                }
                if (remoteJidOut) {
                    const jidLocal = String(remoteJidOut).replace(/@s\.whatsapp\.net$/i, '').replace(/@lid$/i, '').trim();
                    let resolved = resolvePhoneForFlorPauseFromOutgoing(sock, msg);
                    if (!resolved) {
                        resolved = await resolvePausePhoneViaSupabaseLid(jidLocal);
                        if (resolved) {
                            console.log(`🔇 Modo Silencio: +E.164 desde Supabase por LID jid=${jidLocal} → ${resolved}`);
                        }
                    }
                    const jidDigits = (jidLocal && /^[0-9]+$/.test(String(jidLocal).replace(/^\+/, '')))
                        ? String(jidLocal).replace(/\D/g, '')
                        : '';
                    // @lid: el user no es E.164; jamás armar +<dígitos> solo desde el JID (ej. 72005227429971 → falso +720…).
                    const remoteIsLid = String(remoteJidOut).includes('@lid');
                    const fromJidOk = !remoteIsLid && jidDigits.length >= 10 && !isLikelyPseudoWhatsappPn(jidDigits) && !isOurBotPhoneDigits(jidDigits);
                    let primaryForDb = resolved || (fromJidOk ? ('+' + jidDigits) : null);
                    if (primaryForDb && isOurBotPhoneDigits(primaryForDb.replace(/^\+/, ''))) {
                        console.log(`🔇 Modo Silencio: ignorado (destino es el propio número del bot / eco). jid=${jidLocal} msgId=${msg.key.id || 'n/a'}`);
                        primaryForDb = null;
                    }
                    // Eco tras /api/send: ya pausamos en HTTP; el id del eco a veces no coincide con el registrado.
                    if (shouldSkipFromMePauseBecauseRecentDashboard(primaryForDb, jidDigits)) {
                        continue;
                    }
                    const willPauseFromMeHuman =
                        (primaryForDb && !String(primaryForDb).includes('@')) ||
                        (jidDigits.length >= 10 && !isOurBotPhoneDigits(jidDigits));
                    if (willPauseFromMeHuman && shouldSkipFromMeHumanSilenceDuplicate(msg.key.id)) {
                        continue;
                    }
                    if (willPauseFromMeHuman) {
                        markFromMeHumanSilenceProcessed(msg.key.id);
                    }
                    // Siempre tocar RAM con el JID local (LID o PN): el entrante puede matchear otro formato que +E.164
                    if (jidDigits.length >= 10) {
                        florPauseMemoryTouchMany(resolved, '+' + jidDigits);
                    } else {
                        florPauseMemoryTouchMany(resolved);
                    }
                    if (primaryForDb && !String(primaryForDb).includes('@')) {
                        await setFlorPausedUntil(primaryForDb, FLOR_SILENCE_MINUTES, null, jidDigits.length >= 10 ? jidDigits : null);
                        console.log(`🔇 Modo Silencio: mensaje saliente HUMANO (WhatsApp/app, no bot) → Flor ${FLOR_SILENCE_MINUTES} min | jid=${jidLocal} resolved=${resolved || '—'} dbPhone=${primaryForDb} msgId=${msg.key.id || 'n/a'}`);
                    } else if (jidDigits.length >= 10 && !isOurBotPhoneDigits(jidDigits)) {
                        await setFlorPausedUntil(null, FLOR_SILENCE_MINUTES, null, jidDigits);
                        console.log(`🔇 Modo Silencio: HUMANO desde móvil (solo LID en remoteJid) → Flor ${FLOR_SILENCE_MINUTES} min | jid=${jidLocal} (DB por phone/real_phone=LID)`);
                    } else if (!primaryForDb && !isOurBotPhoneDigits(jidDigits)) {
                        console.warn(`⚠️ Modo Silencio: no se pudo resolver +E.164 real para pausa. remoteJid=${remoteJidOut} jid=${jidLocal}. Si el key trae peer_recipient_pn, actualizar Baileys / redeploy.`);
                    }
                }
                continue;
            }

            const message = msg.message;
            if (!message) {
                console.log(`⚠️ Mensaje sin contenido (message es null/undefined)`);
                continue;
            }

            // Obtener texto del mensaje (incl. caption de imagen, audio/voice)
            let texto = '';
            if (message.conversation) {
                texto = message.conversation;
            } else if (message.extendedTextMessage?.text) {
                texto = message.extendedTextMessage.text;
            } else if (message.imageMessage?.caption) {
                texto = message.imageMessage.caption;
            }
            const tieneImagen = !!(message.imageMessage);
            const tieneAudio = !!(message.audioMessage || message.pttMessage);

            if (!texto && !tieneImagen && !tieneAudio) {
                console.log(`⚠️ Mensaje sin texto, imagen ni audio`);
                continue;
            }
            if (!texto && tieneImagen) texto = '[Imagen]';
            if (!texto && tieneAudio) texto = '[Audio]';

            const remoteJid = msg.key.remoteJid;
            let numero = remoteJid?.replace('@s.whatsapp.net', '')?.replace('@lid', '') || '';
            if (remoteJid) numero = String(remoteJid).replace(/@s\.whatsapp\.net$/, '').replace(/@lid$/i, '').trim() || numero;
            const esLid = remoteJid && String(remoteJid).includes('@lid');
            // Baileys 6.8+: remoteJidAlt tiene el número real cuando hay LID (a veces remoteJid viene como 205132033732831@s.whatsapp.net igual)
            const remoteJidAlt = msg.key.remoteJidAlt;
            if (remoteJidAlt && String(remoteJidAlt).includes('@s.whatsapp.net')) {
                const altNum = String(remoteJidAlt).replace('@s.whatsapp.net', '').trim();
                if (altNum && /^[0-9]{10,}$/.test(altNum.replace(/^\+/, ''))) {
                    const realPhone = altNum.startsWith('+') ? altNum : '+' + altNum.replace(/\D/g, '');
                    console.log(`📱 Número real desde remoteJidAlt: ${numero} → ${realPhone}`);
                    numero = realPhone;
                    if (supabase && CONFIG.SAVE_TO_SUPABASE) {
                        try {
                            const jidSinSufijo = String(remoteJid).replace(/@s\.whatsapp\.net$/, '').replace(/@lid$/i, '').trim();
                            if (jidSinSufijo) {
                                const update = { phone: realPhone, real_phone: realPhone, name: msg.pushName || realPhone };
                                await supabase.from('whatsapp_chats').update(update).eq('phone', jidSinSufijo).eq('whatsapp_instance', CONFIG.INSTANCE_NUMBER);
                            }
                        } catch (e) { /* ignorar */ }
                    }
                }
            } else if (esLid) {
                // Log del key para depurar (ver qué propiedades trae Baileys)
                const keyKeys = msg.key ? Object.keys(msg.key) : [];
                const keyPreview = msg.key ? JSON.stringify(msg.key) : 'null';
                if (keyPreview.length < 300) {
                    console.log(`📱 LID key: keys=[${keyKeys.join(',')}] val=${keyPreview}`);
                } else {
                    console.log(`📱 LID key: keys=[${keyKeys.join(',')}] senderPn=${msg.key?.senderPn ?? 'n/a'} participant=${msg.key?.participant ?? 'n/a'}`);
                }
                let realPhone = resolveLidToPhone(sock, remoteJid);
                // Fallback: número real desde key (senderPn, participant, participantAlt o cualquier propiedad con JID @s.whatsapp.net)
                if (!realPhone && msg.key) {
                    const key = msg.key;
                    const candidates = [
                        key.senderPn,
                        key.sender_pn,
                        key.participant,
                        key.participantAlt,
                        key.participant_alt,
                        key.remoteJidAlt,
                        key.remote_jid_alt
                    ].filter(Boolean);
                    // También revisar todas las propiedades del key por si el nombre varía
                    for (const k of Object.keys(key || {})) {
                        const v = key[k];
                        if (v && typeof v === 'string' && v.includes('@s.whatsapp.net')) candidates.push(v);
                    }
                    for (const jidStr of candidates) {
                        const s = String(jidStr).trim();
                        if (!s || !s.includes('@s.whatsapp.net')) continue;
                        const pn = s.replace(/@s\.whatsapp\.net$/i, '').trim();
                        if (pn && /^[0-9]{10,}$/.test(pn.replace(/^\+/, ''))) {
                            realPhone = pn.startsWith('+') ? pn : '+' + pn.replace(/\D/g, '');
                            console.log(`📱 Número real desde key: ${numero} → ${realPhone}`);
                            break;
                        }
                    }
                }
                // sender_pn a veces solo viene en el envelope (attrs), no en msg.key → evita enviar solo a @lid ("Esperando mensaje" en el cliente)
                if (!realPhone && msg) {
                    const deepE164 = deepScanMessageForRecipientPn(msg, 0, new WeakSet());
                    if (deepE164) {
                        realPhone = deepE164.replace(/^\+/, '');
                        console.log(`📱 Número real desde deepScan (sender_pn / envelope): ${numero} → +${realPhone}`);
                    }
                }
                if (realPhone) {
                    const normalized = String(realPhone).startsWith('+') ? String(realPhone) : '+' + String(realPhone).replace(/\D/g, '');
                    numero = normalized;
                    if (supabase && CONFIG.SAVE_TO_SUPABASE) {
                        const numeroSinLid = String(remoteJid).replace(/@lid$/i, '').replace(/@s\.whatsapp\.net$/, '').trim();
                        try {
                            const update = { phone: normalized, real_phone: normalized.replace(/^\+/, ''), name: msg.pushName || normalized };
                            // Actualizar solo la fila que tiene el LID para no pisar otras y evitar unique constraint
                            const { error: errUpdate } = await supabase
                                .from('whatsapp_chats')
                                .update(update)
                                .eq('phone', numeroSinLid)
                                .eq('whatsapp_instance', CONFIG.INSTANCE_NUMBER);
                            if (errUpdate) console.warn('⚠️ Error actualizando chat con número real:', errUpdate.message);
                        } catch (e) {
                            console.warn('⚠️ Error actualizando whatsapp_chats (número real):', e?.message || e);
                        }
                    }
                }
            }
            if (esLid && !numero.startsWith('+')) {
                console.log(`📱 LID: numero final=${numero}, key.senderPn=${msg.key?.senderPn ?? 'n/a'}, key.participant=${msg.key?.participant ?? 'n/a'}`);
            }
            // Mapear JID → +E.164 para pausar Flor cuando el humano escribe desde el celular (outgoing usa a veces PN interno 133…@s.whatsapp.net)
            {
                const nd = String(numero).replace(/\D/g, '');
                if (nd.length >= 10 && nd.length <= 15 && !isLikelyPseudoWhatsappPn(nd)) {
                    const e164 = String(numero).startsWith('+') ? numero : ('+' + nd);
                    rememberFlorChatJidToPhone(remoteJid, e164);
                }
            }
            /** Si ya tenemos +E.164 real, enviar a *@s.whatsapp.net; mandar solo a @lid rompe el cifrado en muchos clientes ("Esperando mensaje"). */
            let jidDestino = remoteJid;
            {
                const ndf = String(numero || '').replace(/\D/g, '');
                if (numero && String(numero).trim().startsWith('+') && ndf.length >= 10
                    && !isLikelyPseudoWhatsappPn(ndf) && !isOurBotPhoneDigits(ndf)) {
                    jidDestino = `${ndf}@s.whatsapp.net`;
                    if (String(remoteJid).includes('@lid') && jidDestino !== remoteJid) {
                        console.log(`📤 Flor usará PN para enviar (no solo LID): ${remoteJid} → ${jidDestino}`);
                    }
                    rememberFlorChatJidToPhone(jidDestino, String(numero).trim().startsWith('+') ? numero : '+' + ndf);
                }
            }
            // senderPn a veces viene en la misma recepción; priorizar sobre número aún no normalizado (+E.164)
            {
                const sp = msg.key && (msg.key.senderPn || msg.key.sender_pn);
                if (sp && String(sp).includes('@s.whatsapp.net')) {
                    const e164sp = jidPnToE164(String(sp));
                    if (e164sp) {
                        const d = e164sp.replace(/\D/g, '');
                        jidDestino = `${d}@s.whatsapp.net`;
                        if (String(remoteJid).includes('@lid')) {
                            console.log(`📤 Flor: JID destino desde senderPn al encolar: ${remoteJid} → ${jidDestino}`);
                        }
                        rememberLidPnForSend(remoteJid, jidDestino);
                    }
                }
            }
            const nombre = msg.pushName || numero;

            console.log(`📱 Mensaje recibido de ${nombre} (${numero}): ${texto}${tieneAudio ? ' [audio/voice]' : ''}`);

            // Guardar mensaje recibido de inmediato (message_type: text | audio para logs)
            await guardarMensaje(numero, texto, false, null, nombre, null, tieneAudio ? 'audio' : 'text');

            if (!CONFIG.AUTO_REPLY || !CONFIG.FLOR_ENABLED) continue;

            if (await isFlorPausedForChat(numero, CONFIG.INSTANCE_NUMBER)) {
                console.log(`⏸️ Flor pausada para este chat (asesor tomó la conversación hasta flor_paused_until)`);
                continue;
            }

            // Acumular mensajes y responder tras FLOR_DELAY_MS. Si llegan más en ese lapso, se agregan y Flor responde a todos.
            const key = String(remoteJid);
            let pending = florPendingByUser.get(key);

            if (!pending) {
                pending = {
                    timeoutId: null,
                    messages: [],
                    nombre,
                    numero,
                    remoteJid,
                    jidDestino
                };
                florPendingByUser.set(key, pending);
            }

            // Guardar siempre msg si hay LID: sin msg.key en cola resolveFlorSendJid no puede leer senderPn (hidrata tarde) → "Esperando mensaje"
            pending.messages.push({
                texto,
                ts: Date.now(),
                msg: (String(remoteJid).includes('@lid') || tieneImagen || tieneAudio) ? msg : null
            });
            pending.nombre = nombre;
            pending.numero = numero;
            pending.remoteJid = remoteJid;
            pending.jidDestino = jidDestino;

            if (pending.messages.length > 1) {
                console.log(`📬 Mensaje adicional de ${nombre} durante la espera (${pending.messages.length} en cola, ${FLOR_DELAY_MS}ms)`);
            }

            /** Presencia Baileys: puede devolver Promise; try/catch síncrono no evita crash si rechaza. */
            const safeSendPresenceUpdate = async (state, jid) => {
                if (!sock || !jid) return;
                try {
                    const pr = sock.sendPresenceUpdate(state, jid);
                    if (pr && typeof pr.then === 'function') await pr.catch(() => {});
                } catch (e) { /* conexión cerrada / 428 */ }
            };

            const processPending = async () => {
                const p = florPendingByUser.get(key);
                if (!p || !p.messages.length) return;

                if (await isFlorPausedForChat(p.numero, CONFIG.INSTANCE_NUMBER)) {
                    florPendingByUser.delete(key);
                    console.log(`⏸️ Flor pausada antes de llamar a la IA (silencio activo para ${p.numero})`);
                    return;
                }

                // No procesar si el socket se cerró (p. ej. conflicto 440 / rolling update); evita crash en sendPresenceUpdate/sendMessage
                if (connectionStatus !== 'open' || !sock) {
                    console.warn(`⚠️ processPending omitido: WhatsApp no conectado (status=${connectionStatus || 'n/a'}). Revisá conflicto 440 o duplicados. Mensajes en cola se descartan para este ciclo.`);
                    florPendingByUser.delete(key);
                    return;
                }

                // senderPn a veces se rellena en msg.key después del encolar (mientras corre el delay / Gemini)
                for (const entry of p.messages || []) {
                    const m = entry.msg;
                    if (!m?.key) continue;
                    const sp = m.key.senderPn || m.key.sender_pn;
                    if (sp && String(sp).includes('@s.whatsapp.net')) {
                        const e164 = jidPnToE164(String(sp));
                        if (e164) {
                            p.jidDestino = e164.replace(/\D/g, '') + '@s.whatsapp.net';
                            rememberLidPnForSend(p.remoteJid, p.jidDestino);
                        }
                    }
                }

                let destJid = await resolveFlorSendJid(sock, p);
                if (CONFIG.FLOR_SEND_USE_REMOTE_JID_ONLY && p.remoteJid) {
                    destJid = String(p.remoteJid);
                    console.log(`📤 Flor: envío al JID entrante (FLOR_SEND_USE_REMOTE_JID_ONLY) → ${destJid}`);
                } else {
                    destJid = applyFlorDestJidDeviceTransfer(p, destJid);
                    if (destJid && String(destJid).includes('@s.whatsapp.net') && !String(destJid).includes('@lid')) {
                        destJid = await enrichPnJidWithOnWhatsApp(sock, destJid);
                    }
                }

                let dispatchPushed = false;
                const ndDispatch = String(p.numero || '').replace(/\D/g, '');
                let phoneE164ForDispatch = null;
                if (ndDispatch.length >= 10 && !isLikelyPseudoWhatsappPn(ndDispatch) && !isOurBotPhoneDigits(ndDispatch)) {
                    phoneE164ForDispatch = String(p.numero || '').startsWith('+') ? p.numero : '+' + ndDispatch;
                }
                if (phoneE164ForDispatch && p.remoteJid) {
                    pushFlorDispatchContext(p.remoteJid, phoneE164ForDispatch);
                    if (destJid && destJid !== p.remoteJid) {
                        pushFlorDispatchContext(destJid, phoneE164ForDispatch);
                    }
                    dispatchPushed = true;
                }
                florPendingByUser.delete(key);

                try {
                const textos = p.messages.map(m => m.texto);
                let combined = textos.length === 1
                    ? textos[0]
                    : textos.map((t, i) => `Consulta ${i + 1}: ${t}`).join('\n\n');

                console.log(`⏱️ Procesando ${textos.length} mensaje(s) de ${p.nombre} (delay ${FLOR_DELAY_MS}ms)`);

                // 3) Si hay audio: transcribir PRIMERO (necesitamos el texto para matchear integraciones)
                const msgConAudio = p.messages.find(m => m.msg && m.msg.message && (m.msg.message.audioMessage || m.msg.message.pttMessage));
                if (msgConAudio && msgConAudio.msg && typeof downloadMediaMessage === 'function') {
                    try {
                        const buffer = await downloadMediaMessage(msgConAudio.msg, 'buffer', {});
                        if (buffer && Buffer.isBuffer(buffer)) {
                            const audioBase64 = buffer.toString('base64');
                            const mimeType = (msgConAudio.msg.message?.audioMessage?.mimetype || msgConAudio.msg.message?.pttMessage?.mimetype || 'audio/ogg').split(';')[0].trim();
                            const transcription = await transcribeAudioWithGemini(audioBase64, mimeType);
                            if (transcription && transcription.trim()) {
                                console.log(`🎙️ Audio recibido -> Transcripción: ${transcription}`);
                                const idxAudio = textos.findIndex(t => t === '[Audio]');
                                if (idxAudio !== -1) textos[idxAudio] = transcription;
                                combined = textos.length === 1 ? textos[0] : textos.map((t, i) => `Consulta ${i + 1}: ${t}`).join('\n\n');
                            } else {
                                const audioFallback = FLOR_RESPONSES_DEFAULTS.audioFallback;
                                if (sock && destJid) {
                                    await sock.sendMessage(destJid, { text: añadirEmojiMensaje(audioFallback, 'flor') });
                                    await guardarMensaje(p.numero, audioFallback, true, audioFallback, p.nombre);
                                    await guardarFlorInteraction({ phone: p.numero, userMessage: '[Audio]', botResponse: audioFallback, intent: 'audio_fallback', success: false, usedAi: false, responseTimeMs: 0 });
                                }
                                await safeSendPresenceUpdate('paused', destJid);
                                return;
                            }
                        }
                    } catch (e) {
                        const audioFallback = FLOR_RESPONSES_DEFAULTS.audioFallback;
                        if (sock && destJid) {
                            await sock.sendMessage(destJid, { text: añadirEmojiMensaje(audioFallback, 'flor') });
                            await guardarMensaje(p.numero, audioFallback, true, audioFallback, p.nombre);
                        }
                        await safeSendPresenceUpdate('paused', destJid);
                        return;
                    }
                }

                // ═══ PRIORIDAD ABSOLUTA: Integraciones - PRIMERA capa de respuesta. Si hay match, NUNCA llamar al LLM.
                const phoneKeyInt = (p.numero && String(p.numero).replace(/\D/g, '')) || 'unknown';
                const lastHotelNombre = florLastHotelByPhone.get(phoneKeyInt) || null;
                let integracionMatch = await detectarIntegracionActivada(combined, lastHotelNombre);
                if (integracionMatch && sock && destJid) {
                    const { integration, hotel } = integracionMatch;
                    const integrationName = (integration.name || '').toLowerCase();
                    const isOportunidades = integrationName.includes('temporada') && integrationName.includes('oportunidades');
                    const hotelKey = (hotel && (hotel.id || hotel.name || hotel.nombre)) ? String(hotel.id || hotel.name || hotel.nombre) : '';
                    if (isOportunidades && hotelKey) {
                        let sentSet = florOportunidadesSentByPhone.get(phoneKeyInt);
                        if (!sentSet) { sentSet = new Set(); florOportunidadesSentByPhone.set(phoneKeyInt, sentSet); }
                        if (sentSet.has(hotelKey)) {
                            console.log(`📋 Integración "Temporada de Oportunidades" ya enviada para este hotel (${hotelKey}), se omite para no repetir`);
                            integracionMatch = null;
                        } else {
                            sentSet.add(hotelKey);
                        }
                    }
                }
                if (integracionMatch && sock && destJid) {
                    const { integration, hotel } = integracionMatch;
                    let contenido = (integration.content && String(integration.content).trim()) || '';
                    console.log(`📋 Integración activada: "${integration.name || 'Sin nombre'}" (override, BLOQUEO DE LLM)`);
                    contenido = sanitizarContenidoIntegracionParaLinks(contenido);
                    if (contenido) await sock.sendMessage(destJid, { text: contenido });
                    if (integration.sendImage && hotel) {
                        const fi = hotel.flor_info || {};
                        const imgUrl = fi.img_general || (hotel.images && hotel.images[0]);
                        if (imgUrl) try { await sock.sendMessage(destJid, { image: { url: imgUrl } }); } catch (e) { console.warn('⚠️ Imagen integración:', e?.message); }
                    }
                    const mediaUrls = integration.mediaUrls || [];
                    for (const m of mediaUrls) {
                        const url = m.url && String(m.url).trim();
                        if (!url) continue;
                        const tipo = (m.type || '').toLowerCase();
                        const nombre = m.name || 'archivo';
                        try {
                            if (url.startsWith('data:')) {
                                const base64Match = url.match(/^data:[^;]+;base64,(.+)$/);
                                if (base64Match) {
                                    const buf = Buffer.from(base64Match[1], 'base64');
                                    if (tipo.includes('video')) await sock.sendMessage(destJid, { video: buf });
                                    else if (tipo.includes('pdf') || nombre.toLowerCase().endsWith('.pdf')) await sock.sendMessage(destJid, { document: buf, mimetype: 'application/pdf', fileName: nombre.endsWith('.pdf') ? nombre : nombre + '.pdf' });
                                    else await sock.sendMessage(destJid, { image: buf });
                                }
                            } else if (tipo.includes('video')) await sock.sendMessage(destJid, { video: { url } });
                            else if (tipo.includes('pdf') || nombre.toLowerCase().endsWith('.pdf')) {
                                const buf = await downloadUrlToBuffer(url);
                                if (buf?.length) await sock.sendMessage(destJid, { document: buf, mimetype: 'application/pdf', fileName: nombre.endsWith('.pdf') ? nombre : nombre + '.pdf' });
                            } else await sock.sendMessage(destJid, { image: { url } });
                        } catch (e) { console.warn('⚠️ Medio integración:', e?.message); }
                    }
                    await guardarMensaje(p.numero, contenido, true, contenido, p.nombre);
                    await guardarFlorInteraction({ phone: p.numero, userMessage: combined, botResponse: contenido, intent: 'integracion_override', success: true, usedAi: false, responseTimeMs: 0 });
                    await safeSendPresenceUpdate('paused', destJid);
                    return;
                }

                // Multimodal: imagen para Gemini (anuncio fb.me/instagram o imagen enviada por el usuario)
                let imageParts = [];
                const combinedLower = (combined || '').toLowerCase();
                // 1) Si hay link de anuncio (FB/IG), obtener imagen del preview
                const esLinkAnuncio = (u) => { const l = u.toLowerCase(); return l.includes('fb.me') || l.includes('instagram.com') || l.includes('facebook.com/share'); };
                if (combinedLower.includes('fb.me') || combinedLower.includes('instagram.com') || combinedLower.includes('facebook.com')) {
                    const urls = detectarURLs(combined);
                    const anuncioUrl = urls.find(u => esLinkAnuncio(u));
                    if (anuncioUrl) {
                        try {
                            const preview = await obtenerPreviewURL(anuncioUrl);
                            if (preview && preview.image) {
                                const imgPart = await fetchImageAsBase64(preview.image);
                                if (imgPart) {
                                    imageParts = [imgPart];
                                    console.log('🖼️ Imagen de anuncio obtenida para análisis multimodal (Puyehue/Corralco/Huilo Huilo)');
                                }
                            }
                        } catch (e) {
                            console.warn('⚠️ No se pudo obtener imagen del anuncio para multimodal:', e?.message || e);
                        }
                    }
                }
                // Imagen del usuario para multimodal
                if (imageParts.length === 0 && typeof downloadMediaMessage === 'function') {
                    const msgConImagen = p.messages.find(m => m.msg && m.msg.message && m.msg.message.imageMessage);
                    if (msgConImagen && msgConImagen.msg) {
                        try {
                            const buffer = await downloadMediaMessage(msgConImagen.msg, 'buffer', {});
                            if (buffer && Buffer.isBuffer(buffer)) {
                                const base64 = buffer.toString('base64');
                                imageParts = [{ mimeType: 'image/jpeg', data: base64 }];
                                console.log('🖼️ Imagen del mensaje descargada para análisis multimodal');
                            }
                        } catch (e) {
                            console.warn('⚠️ No se pudo descargar imagen del mensaje:', e?.message || e);
                        }
                    }
                }

                // Reset de contexto por publicidad: si hay fb.me/instagram o imagen, limpiar historial para no mezclar hoteles
                if (imageParts.length > 0) {
                    const phoneKey = (p.numero && String(p.numero).replace(/\D/g, '')) || 'unknown';
                    florSessionByPhone.delete(phoneKey);
                    florLastHotelByPhone.delete(phoneKey);
                    console.log('🔄 Flor: reset de contexto por anuncio/imagen (prioridad multimodal, sin historial previo)');
                }

                // Simulación de escritura (spec: UX premium)
                await safeSendPresenceUpdate('composing', destJid);

                const t0 = Date.now();
                const raw = await procesarConFlor(combined, {
                    numero: p.numero,
                    nombre: p.nombre,
                    instancia: CONFIG.INSTANCE_NUMBER,
                    multiConsultas: textos.length > 1,
                    consultas: textos
                }, imageParts);
                const responseTimeMs = Date.now() - t0;
                let respuestaFlor = (typeof raw === 'object' && raw != null && 'text' in raw) ? raw.text : (typeof raw === 'string' ? raw : null);
                // Personalizar link de cotización con el número de WhatsApp del usuario: al abrirlo el formulario tendrá el teléfono ya escrito
                const numeroUsuario = (p.numero && String(p.numero).replace(/\D/g, '')) || (destJid && String(destJid).replace(/@.*$/, '').replace(/\D/g, '')) || '';
                if (respuestaFlor && numeroUsuario.length >= 10) {
                    respuestaFlor = respuestaFlor.replace(/https:\/\/cotizar\.checkin24hs\.com\/[^\s]*/gi, 'https://cotizar.checkin24hs.com/?phone=' + numeroUsuario);
                    if (respuestaFlor.includes('?phone=' + numeroUsuario)) {
                        console.log('📱 Link de cotización personalizado con teléfono del usuario para pre-llenar el formulario');
                    }
                }
                const intentFlor = (typeof raw === 'object' && raw != null && raw.intent) ? raw.intent : 'consulta_general';
                const usedAi = intentFlor !== 'rate_limit_429';
                const pausarFlor = (typeof raw === 'object' && raw != null && (raw.pausarFlor20Min === true || Number(raw.pausarFlorMin) > 0)) || intentFlor === 'transferir';
                if (pausarFlor && p.numero) {
                    console.log(`📤 Slack: disparando alerta de escalación (transferir) para ${p.numero} — último mensaje: "${(combined || '').slice(0, 80)}..."`);
                    await setFlorPausedUntil(p.numero, FLOR_SILENCE_MINUTES);
                    const phoneKeyForSlack = (p.numero && String(p.numero).replace(/\D/g, '')) || 'unknown';
                    await sendSlackEscalationAlert(p.nombre || p.numero, p.numero, florLastHotelByPhone.get(phoneKeyForSlack) || 'No definido', combined);
                }
                if ((typeof raw === 'object' && raw != null && raw.enviarSlackAlerta === true) && p.numero) {
                    const phoneKeyForSlack = (p.numero && String(p.numero).replace(/\D/g, '')) || 'unknown';
                    await sendSlackEscalationAlert(p.nombre || p.numero, p.numero, florLastHotelByPhone.get(phoneKeyForSlack) || 'No definido', combined);
                }

                // Si Flor pidió enviar un PDF como documento, descargar y enviar el archivo (no el link)
                if (raw && raw.sendDocument && sock && destJid) {
                    try {
                        const buf = await downloadUrlToBuffer(raw.sendDocument.url);
                        if (buf && buf.length > 0) {
                            await sock.sendMessage(destJid, {
                                document: buf,
                                mimetype: 'application/pdf',
                                fileName: raw.sendDocument.fileName || 'documento.pdf'
                            });
                            console.log(`📄 PDF enviado por WhatsApp: ${raw.sendDocument.fileName}`);
                        } else {
                            console.warn('⚠️ No se pudo descargar el PDF para enviar; se enviará solo el texto.');
                        }
                    } catch (e) {
                        console.warn('⚠️ Error enviando PDF por WhatsApp:', e?.message || e);
                    }
                }
                // Si Flor pidió enviar imagen del hotel, enviar desde URL (nunca Base64 como texto)
                if (raw && raw.sendImage && sock && destJid) {
                    try {
                        const { url: imgUrl, caption } = raw.sendImage;
                        if (imgUrl && !imgUrl.startsWith('data:')) {
                            await sock.sendMessage(destJid, { image: { url: imgUrl }, caption: (caption || '').slice(0, 1024) });
                            console.log('🖼️ Imagen del hotel enviada por WhatsApp');
                        } else {
                            console.warn('⚠️ sendImage tiene data: URI o URL vacía; no se envía.');
                        }
                    } catch (e) {
                        console.warn('⚠️ Error enviando imagen del hotel por WhatsApp:', e?.message || e);
                    }
                }

                if (respuestaFlor && sock) {
                    // Añadir emoji Flor; si es cotización y hay IMAGEN_COTIZACION_URL, enviar imagen + caption
                    const textoConEmoji = añadirEmojiMensaje(respuestaFlor, 'flor');
                    const mensajeParaEnvio = await prepararMensajeFlorParaEnvio(textoConEmoji);
                    if (mensajeParaEnvio.sendAsCombo) {
                        // Combo ubicación: primero imagen del hotel, luego texto con link de Maps
                        const imgUrl = mensajeParaEnvio.imageUrl;
                        const isDataUri = typeof imgUrl === 'string' && imgUrl.startsWith('data:');
                        let imagePayload;
                        if (isDataUri) {
                            const base64 = imgUrl.replace(/^data:image\/\w+;base64,/, '');
                            const buf = Buffer.from(base64, 'base64');
                            imagePayload = { image: buf, caption: mensajeParaEnvio.caption };
                        } else {
                            imagePayload = { image: { url: imgUrl }, caption: mensajeParaEnvio.caption };
                        }
                        await sock.sendMessage(destJid, imagePayload);
                        const twl = mensajeParaEnvio.textWithLink || '';
                        if (twl.length > 4090) {
                            await enviarTextoWhatsAppEnPartes(sock, destJid, twl);
                        } else {
                            await sock.sendMessage(destJid, { text: twl });
                        }
                        console.log('📍 Combo ubicación enviado: imagen del hotel + texto con link');
                    } else if (mensajeParaEnvio.sendCotizacionCombo) {
                        await sock.sendMessage(destJid, {
                            image: { url: mensajeParaEnvio.imageUrl },
                            caption: mensajeParaEnvio.caption
                        });
                        await enviarTextoWhatsAppEnPartes(sock, destJid, mensajeParaEnvio.textFull);
                        console.log(`📋 Cotización: imagen + texto completo (${mensajeParaEnvio.textFull.length} chars, sin truncar caption)`);
                    } else {
                        const plainText = mensajeParaEnvio.text;
                        if (plainText && plainText.length > 4090) {
                            await enviarTextoWhatsAppEnPartes(sock, destJid, plainText);
                        } else {
                            await sock.sendMessage(destJid, mensajeParaEnvio);
                        }
                    }
                    const textoGuardado = mensajeParaEnvio.sendAsCombo
                        ? (mensajeParaEnvio.caption + '\n\n' + mensajeParaEnvio.textWithLink)
                        : mensajeParaEnvio.sendCotizacionCombo
                            ? mensajeParaEnvio.textFull
                            : (mensajeParaEnvio.caption || mensajeParaEnvio.text || textoConEmoji);
                    await guardarMensaje(p.numero, textoGuardado, true, respuestaFlor, p.nombre);
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
                // Quitar indicador "escribiendo"
                await safeSendPresenceUpdate('paused', destJid);
                } catch (procErr) {
                    console.error('❌ processPending:', procErr?.message || procErr, procErr?.stack || '');
                } finally {
                    if (dispatchPushed) popFlorDispatchContext(destJid);
                }
            };

            // Timer de 5s desde el *primer* mensaje. Si llegan más en ese lapso, se acumulan; al cumplirse 5s se procesan todos.
            if (!pending.timeoutId) {
                pending.timeoutId = setTimeout(() => {
                    pending.timeoutId = null;
                    processPending().catch(err => {
                        console.error('❌ processPending:', err?.message || err, err?.stack || '');
                    });
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
        timestamp: new Date().toISOString(),
        florSessionCryptoIssuesLastWindow: getFlorSessionCryptoIssueCount(),
        florSessionCryptoWindowMinutes: Math.max(1, Math.round(FLOR_SESSION_CRYPTO_WINDOW_MS / 60000))
    });
});

// Obtener QR Code (ambas rutas funcionan)
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

/**
 * Normaliza número para envío WhatsApp. En Argentina (54) el móvil debe ser 54 9 XX XXXX XXXX (13 dígitos).
 * Si llega 542944210725 (54 + 10 dígitos = 12) se convierte a 5492944210725 (54 + 9 + 10 = 13) para que llegue al teléfono.
 */
function normalizarNumeroParaEnvio(numero) {
    if (numero === undefined || numero === null) return numero;
    const num = String(numero).replace(/^\+/, '').replace(/\D/g, '').trim();
    if (num.length < 10) return num;
    // Argentina: 54 + 10 dígitos sin 9 (12 en total) -> 54 + 9 + 10 dígitos (13 en total) para móvil
    if (num.startsWith('54') && num.length === 12 && num[2] !== '9') {
        const normalized = '54' + '9' + num.slice(2);
        console.log('📱 Normalizado número Argentina para envío:', num, '->', normalized);
        return normalized;
    }
    // Por si acaso llega 54 + 9 dígitos (11 total, formato antiguo)
    if (num.startsWith('54') && num.length === 11) {
        const normalized = '54' + '9' + num.slice(2);
        console.log('📱 Normalizado número Argentina para envío:', num, '->', normalized);
        return normalized;
    }
    return num;
}

// Enviar mensaje (chat_id opcional: si lo envía el dashboard, se usa para guardar en el mismo chat y que los mensajes aparezcan)
app.post('/api/send', async (req, res) => {
    try {
        const { number, text, chat_id: chatIdFromDashboard } = req.body;

        if (!number || !text) {
            return res.status(400).json({ error: 'number y text son requeridos' });
        }

        if (connectionStatus !== 'open' || !sock) {
            return res.status(400).json({ error: 'WhatsApp no está conectado' });
        }

        const raw = String(number || '').replace(/^\+/, '').replace(/\D/g, '').trim();
        const num = normalizarNumeroParaEnvio(number) || raw;
        console.log('📥 /api/send recibido number:', JSON.stringify(number), '-> para envío:', num, num !== raw ? '(Argentina normalizado)' : '');
        const jid = num.includes('@') ? num : `${num}@s.whatsapp.net`;
        // Emoji según tipo: cotización (📋) o mensaje manual del asesor (💬)
        const esCotizacion = /cotizaci[oó]n|cotizar|cotizar\.checkin24hs|tu cotizaci[oó]n|te enviamos.*cotizaci[oó]n/i.test(String(text));
        const textoConEmoji = añadirEmojiMensaje(text, esCotizacion ? 'cotizacion' : 'manual');
        const aiConfigSend = await getFlorAIConfig();
        const imagenCotizacionUrlSend = (aiConfigSend.imagen_cotizacion_url || CONFIG.IMAGEN_COTIZACION_URL || '').trim() || null;
        const textoNorm = normalizarLinksParaWhatsApp(textoConEmoji);
        if (esCotizacion && imagenCotizacionUrlSend) {
            if (textoNorm.length <= 1024) {
                await sock.sendMessage(jid, { image: { url: imagenCotizacionUrlSend }, caption: textoNorm });
            } else {
                await sock.sendMessage(jid, {
                    image: { url: imagenCotizacionUrlSend },
                    caption: captionImagenCotizacionResumido(textoNorm)
                });
                await enviarTextoWhatsAppEnPartes(sock, jid, textoNorm);
            }
        } else {
            const mensajeParaEnvio = await prepararMensajeConPreview(textoConEmoji);
            await sock.sendMessage(jid, mensajeParaEnvio);
        }

        const textoGuardado = textoNorm;
        await guardarMensaje(num.replace(/@.*$/, ''), textoGuardado, true, null, null, chatIdFromDashboard || null);
        await setFlorPausedUntil(num.replace(/@.*$/, ''), FLOR_SILENCE_MINUTES, chatIdFromDashboard || null);
        markRecentDashboardFlorPause(num);

        res.json({ success: true, message: 'Mensaje enviado' });
    } catch (error) {
        console.error('Error enviando mensaje:', error);
        res.status(500).json({ error: error.message });
    }
});

// Convertir WebM a OGG/Opus con ffmpeg para que WhatsApp reproduzca la nota de voz (muchos dispositivos no reproducen webm).
function webmToOgg(buffer) {
    return new Promise((resolve, reject) => {
        const tmpDir = os.tmpdir();
        const id = Date.now() + '-' + Math.random().toString(36).slice(2, 8);
        const inputPath = path.join(tmpDir, `wa_audio_${id}.webm`);
        const outputPath = path.join(tmpDir, `wa_audio_${id}.ogg`);
        fs.writeFileSync(inputPath, buffer);
        const ff = spawn('ffmpeg', [
            '-y', '-i', inputPath,
            '-ac', '1', '-ar', '48000',
            '-c:a', 'libopus', '-b:a', '32k',
            '-application', 'voip', '-frame_duration', '20',
            '-f', 'ogg', outputPath
        ], { stdio: ['ignore', 'pipe', 'pipe'] });
        let stderr = '';
        ff.stderr && ff.stderr.on('data', (d) => { stderr += d.toString(); });
        ff.on('close', (code) => {
            try { fs.unlinkSync(inputPath); } catch (e) {}
            if (code !== 0) {
                try { fs.unlinkSync(outputPath); } catch (e) {}
                return reject(new Error('Error convirtiendo audio: ' + (stderr.slice(-200) || code)));
            }
            try {
                const out = fs.readFileSync(outputPath);
                fs.unlinkSync(outputPath);
                resolve(out);
            } catch (e) {
                reject(e);
            }
        });
        ff.on('error', (err) => {
            try { fs.unlinkSync(inputPath); } catch (e) {}
            try { fs.unlinkSync(outputPath); } catch (e) {}
            reject(err);
        });
    });
}

// Enviar audio (voz) - usado por el dashboard cuando el asesor envía nota de voz (chat_id opcional)
// ptt: true = nota de voz en WhatsApp. WebM se convierte a OGG para mejor compatibilidad.
app.post('/api/send-audio', async (req, res) => {
    try {
        const { number, audioBase64, mimetype, chat_id: chatIdFromDashboard } = req.body;
        if (!number || !audioBase64) {
            return res.status(400).json({ error: 'number y audioBase64 son requeridos' });
        }
        if (connectionStatus !== 'open' || !sock) {
            return res.status(400).json({ error: 'WhatsApp no está conectado' });
        }
        let buffer = Buffer.from(audioBase64, 'base64');
        if (buffer.length === 0) {
            return res.status(400).json({ error: 'audioBase64 inválido' });
        }
        if (buffer.length < 500) {
            return res.status(400).json({ error: 'El audio es demasiado corto o está vacío. Grabá al menos 1 segundo.' });
        }
        let mime = (mimetype && mimetype.startsWith('audio/')) ? mimetype : 'audio/ogg; codecs=opus';
        if (mime.includes('webm')) {
            try {
                buffer = await webmToOgg(buffer);
                mime = 'audio/ogg; codecs=opus';
            } catch (e) {
                console.error('Conversión webm→ogg falló, enviando webm:', e.message);
            }
        }
        const num = normalizarNumeroParaEnvio(number) || String(number).replace(/^\+/, '').replace(/\D/g, '').trim();
        const jid = num.includes('@') ? num : `${num}@s.whatsapp.net`;
        await sock.sendMessage(jid, { audio: buffer, mimetype: mime, ptt: true });
        await guardarMensaje(num.replace(/@.*$/, ''), '[Audio]', true, null, null, chatIdFromDashboard || null);
        await setFlorPausedUntil(num.replace(/@.*$/, ''), FLOR_SILENCE_MINUTES, chatIdFromDashboard || null);
        markRecentDashboardFlorPause(num);
        res.json({ success: true, message: 'Audio enviado' });
    } catch (error) {
        console.error('Error enviando audio:', error);
        res.status(500).json({ error: error.message });
    }
});

// Enviar imagen, video o documento - usado por el dashboard (chat_id opcional)
app.post('/api/send-media', async (req, res) => {
    try {
        const { number, type, dataBase64, mimetype, fileName, caption, chat_id: chatIdFromDashboard } = req.body;
        if (!number || !type || !dataBase64) {
            return res.status(400).json({ error: 'number, type (image|video|document) y dataBase64 son requeridos' });
        }
        if (connectionStatus !== 'open' || !sock) {
            return res.status(400).json({ error: 'WhatsApp no está conectado' });
        }
        const buffer = Buffer.from(dataBase64, 'base64');
        if (buffer.length === 0) {
            return res.status(400).json({ error: 'dataBase64 inválido' });
        }
        const num = normalizarNumeroParaEnvio(number) || String(number).replace(/^\+/, '').replace(/\D/g, '').trim();
        const jid = num.includes('@') ? num : `${num}@s.whatsapp.net`;
        const tipo = String(type).toLowerCase();
        const cap = (caption || '').slice(0, 1024);
        if (tipo === 'image') {
            await sock.sendMessage(jid, { image: buffer, caption: cap || undefined, mimetype: mimetype || 'image/jpeg' });
            await guardarMensaje(num.replace(/@.*$/, ''), caption ? '[Imagen] ' + cap : '[Imagen]', true, null, null, chatIdFromDashboard || null);
        } else if (tipo === 'video') {
            await sock.sendMessage(jid, { video: buffer, caption: cap || undefined, mimetype: mimetype || 'video/mp4' });
            await guardarMensaje(num.replace(/@.*$/, ''), caption ? '[Video] ' + cap : '[Video]', true, null, null, chatIdFromDashboard || null);
        } else if (tipo === 'document') {
            const fname = (fileName || 'documento').replace(/[^a-zA-Z0-9._-]/g, '_');
            await sock.sendMessage(jid, { document: buffer, mimetype: mimetype || 'application/octet-stream', fileName: fname });
            await guardarMensaje(num.replace(/@.*$/, ''), '[Documento] ' + (caption || fname), true, null, null, chatIdFromDashboard || null);
        } else {
            return res.status(400).json({ error: 'type debe ser image, video o document' });
        }
        await setFlorPausedUntil(num.replace(/@.*$/, ''), FLOR_SILENCE_MINUTES, chatIdFromDashboard || null);
        markRecentDashboardFlorPause(num);
        res.json({ success: true, message: 'Media enviado' });
    } catch (error) {
        console.error('Error enviando media:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Obtener o crear chat por canal (web, instagram, facebook, tiktok). No usa whatsapp_instance.
 * phone en BD = prefijo_canal + external_id (ej. web_abc123, ig_123456) para no colisionar con números WA.
 */
async function obtenerOcrearChatIdCanal(canal, externalId, displayName) {
    if (!supabase || !canal || !externalId) return null;
    const canalNorm = String(canal).toLowerCase().trim();
    const idNorm = String(externalId).trim().substring(0, 128);
    const phoneKey = `${canalNorm}_${idNorm}`;
    const nombresCanal = { web: 'Visitante web', instagram: 'Usuario Instagram', facebook: 'Usuario Facebook', tiktok: 'Usuario TikTok' };
    const nombreMostrar = displayName && String(displayName).trim() ? String(displayName).trim() : (nombresCanal[canalNorm] || `Usuario ${canalNorm}`);

    try {
        const { data: existente, error: errBuscar } = await supabase
            .from('whatsapp_chats')
            .select('id')
            .eq('channel', canalNorm)
            .eq('phone', phoneKey)
            .maybeSingle();
        if (existente?.id) return existente.id;
        if (errBuscar) {
            console.warn('⚠️ Error buscando chat canal:', errBuscar.message);
            return null;
        }

        const { data: nuevo, error: errCrear } = await supabase
            .from('whatsapp_chats')
            .insert({
                channel: canalNorm,
                phone: phoneKey,
                name: nombreMostrar,
                display_name: nombreMostrar,
                status: 'active',
                last_message: '',
                unread_count: 0,
                whatsapp_instance: CONFIG.INSTANCE_NUMBER
            })
            .select('id')
            .single();
        if (nuevo?.id) {
            console.log(`✅ Chat canal ${canalNorm} creado para ${phoneKey} (ID: ${nuevo.id})`);
            return nuevo.id;
        }
        if (errCrear) console.error('❌ Error creando chat canal:', errCrear.message);
        return null;
    } catch (e) {
        console.warn('⚠️ obtenerOcrearChatIdCanal:', e?.message || e);
        return null;
    }
}

/**
 * Guardar conversación de un canal (web, instagram, etc.): mensaje del usuario + respuesta de Flor.
 * Se usa desde /api/flor/process cuando vienen channel y external_id.
 */
async function guardarConversacionCanal(canal, externalId, displayName, userMessage, botResponse) {
    if (!supabase || !CONFIG.SAVE_TO_SUPABASE || !userMessage) return;
    const chatId = await obtenerOcrearChatIdCanal(canal, externalId, displayName);
    if (!chatId) return;

    const canalNorm = String(canal).toLowerCase().trim();
    const phoneKey = `${canalNorm}_${String(externalId).trim().substring(0, 128)}`;
    const nowIso = new Date().toISOString();
    const baseMsg = {
        chat_id: chatId,
        conversation_id: chatId,
        phone: phoneKey,
        is_read: false,
        whatsapp_instance: CONFIG.INSTANCE_NUMBER,
        message_type: 'text',
        channel: canalNorm
    };

    const doInsert = async (msg, isFromMe) => {
        const row = { ...baseMsg, message: String(msg).trim().substring(0, 8000), is_from_me: isFromMe };
        let err = (await supabase.from('whatsapp_messages').insert(row)).error;
        if (err && err.message && err.message.includes('message_type')) { delete row.message_type; err = (await supabase.from('whatsapp_messages').insert(row)).error; }
        if (err && err.message && err.message.includes('channel')) { delete row.channel; err = (await supabase.from('whatsapp_messages').insert(row)).error; }
        if (err && err.message && err.message.includes('conversation_id')) { delete row.conversation_id; err = (await supabase.from('whatsapp_messages').insert(row)).error; }
        if (err) console.warn('⚠️ Error insert mensaje canal:', err.message);
    };

    try { await doInsert(userMessage, false); } catch (e) { console.warn('⚠️ Error insert mensaje usuario canal:', e?.message); }
    if (botResponse && String(botResponse).trim()) {
        try { await doInsert(botResponse, true); } catch (e) { console.warn('⚠️ Error insert respuesta Flor canal:', e?.message); }
    }

    const preview = (botResponse || userMessage || '').substring(0, 200);
    try {
        await supabase.from('whatsapp_chats').update({
            last_message: preview.length > 100 ? preview.substring(0, 100) + '...' : preview,
            last_message_time: nowIso,
            updated_at: nowIso
        }).eq('id', chatId);
    } catch (e) {
        console.warn('⚠️ Error actualizando last_message chat canal:', e?.message);
    }
    console.log(`✅ Conversación canal ${canalNorm} guardada (chatId: ${chatId})`);
}

// API para procesar mensaje con Flor IA (web, Instagram, Facebook, TikTok, etc.)
app.post('/api/flor/process', async (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    try {
        const { message, context = {}, channel, external_id, display_name } = req.body;
        if (!message || typeof message !== 'string') {
            return res.status(400).json({ error: 'message (string) es requerido' });
        }
        const respuesta = await procesarConFlor(message.trim(), context);
        const text = respuesta && typeof respuesta === 'object' && respuesta.text != null
            ? respuesta.text
            : (typeof respuesta === 'string' ? respuesta : null);

        // Guardar en Supabase para que aparezca en el dashboard (web, instagram, facebook, tiktok)
        const canal = (channel && String(channel).trim()) || null;
        const externalId = (external_id != null && String(external_id).trim()) ? String(external_id).trim() : null;
        if (canal && externalId && CONFIG.SAVE_TO_SUPABASE) {
            await guardarConversacionCanal(canal, externalId, display_name || null, message.trim(), text || '');
        }

        res.json({ response: text, success: !!text });
    } catch (error) {
        console.error('Error en /api/flor/process:', error);
        res.status(500).json({ error: error.message, response: null });
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
            console.log(`📤 Slack alertas: ${CONFIG.SLACK_WEBHOOK_URL ? 'webhook configurado' : 'NO configurado (SLACK_WEBHOOK_URL)'}`);
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

