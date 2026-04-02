/**
 * API proxy para el chat Flor en la web.
 * Recibe POST desde www.checkin24hs.com y reenvía al servidor WhatsApp (misma lógica Flor).
 * Mismo origen = sin CORS. No entra en conflicto con WhatsApp (solo reenvía).
 */
const express = require('express');
const http = require('http');

const app = express();
const PORT = process.env.PORT || 8080;

const WHATSAPP_URL = process.env.WHATSAPP_URL || 'http://whatsapp:3001';

const ALLOWED_ORIGINS = ['https://www.checkin24hs.com', 'https://checkin24hs.com'];
// CORS primero: el preflight OPTIONS debe recibir siempre estos headers
app.use((req, res, next) => {
  const origin = req.get('Origin');
  const allowOrigin = (origin && ALLOWED_ORIGINS.includes(origin)) ? origin : ALLOWED_ORIGINS[0];
  res.set('Access-Control-Allow-Origin', allowOrigin);
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
  res.set('Access-Control-Max-Age', '86400');
  res.set('X-Flor-API', '1'); // diagnóstico: si aparece en la respuesta, la petición llegó a este backend
  if (req.method === 'OPTIONS') return res.status(204).end();
  next();
});

// Debug: ?debug=1 o path /__debug__ devuelve qué llega (no depende de headers)
app.use((req, res, next) => {
  const raw = (req.url || '') + '';
  if (raw.includes('debug=1') || raw.includes('__debug__')) {
    return res.json({ url: req.url, method: req.method, raw: raw.slice(0, 300) });
  }
  next();
});

app.use(express.json({ limit: '1mb' }));

// Cuando Apache (u otro proxy) reenvía con URI absoluta, Express no hace match con rutas como /health.
// Normalizar req.url al path y responder /health aquí para no depender del matcher de Express.
app.use((req, res, next) => {
  let path = (req.url || '').trim();
  if (path.startsWith('http')) {
    try {
      path = new URL(path).pathname;
      req.url = path + (req.url.includes('?') ? '?' + req.url.split('?').slice(1).join('?') : '');
    } catch (_) {
      path = path.split('?')[0];
    }
  } else {
    path = path.split('?')[0];
  }
  path = path.replace(/\/+/g, '/').replace(/\/$/, '') || '/';
  if (req.method === 'GET') {
    if (path.endsWith('/debug') || path === '/debug') {
      return res.json({ url: req.url, path, method: req.method, raw: (req.url || '').slice(0, 200) });
    }
    if (path.endsWith('/health') || path === '/health' || path.includes('health')) {
      return res.json({ ok: true, service: 'flor-web-api' });
    }
  }
  next();
});

// Preflight: ruta explícita por si el middleware no corre (imagen vieja) o el path llega distinto
app.options('/api/flor/process', (req, res) => {
  const origin = req.get('Origin');
  const allowOrigin = (origin && ALLOWED_ORIGINS.includes(origin)) ? origin : ALLOWED_ORIGINS[0];
  res.set('Access-Control-Allow-Origin', allowOrigin);
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
  res.set('Access-Control-Max-Age', '86400');
  res.set('X-Flor-API', '1');
  res.status(204).end();
});
app.options('*', (req, res) => {
  const origin = req.get('Origin');
  const allowOrigin = (origin && ALLOWED_ORIGINS.includes(origin)) ? origin : ALLOWED_ORIGINS[0];
  res.set('Access-Control-Allow-Origin', allowOrigin);
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
  res.set('Access-Control-Max-Age', '86400');
  res.set('X-Flor-API', '1');
  res.status(204).end();
});

app.post('/api/flor/process', (req, res) => {
  const payload = {
    message: req.body?.message || '',
    context: req.body?.context || {},
    channel: req.body?.channel || undefined,
    external_id: req.body?.external_id || undefined,
    display_name: req.body?.display_name || undefined
  };
  const body = JSON.stringify(payload);
  const url = new URL('/api/flor/process', WHATSAPP_URL);
  const port = url.port || (url.protocol === 'https:' ? 443 : 80);
  const opts = {
    hostname: url.hostname,
    port: port,
    path: url.pathname,
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) }
  };

  const proxyReq = http.request(opts, (proxyRes) => {
    let data = '';
    proxyRes.on('data', (ch) => { data += ch; });
    proxyRes.on('end', () => {
      res.status(proxyRes.statusCode).set(proxyRes.headers).send(data || undefined);
    });
  });
  proxyReq.on('error', (err) => {
    console.error('[flor-web-api] Error proxy:', err.message || err.code || err, '→ target:', opts.hostname + ':' + opts.port);
    res.status(502).json({ error: 'Flor no disponible', response: null });
  });
  proxyReq.write(body);
  proxyReq.end();
});

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'flor-web-api' });
});

// Debug: ver qué recibe el backend cuando la petición viene por proxy (Apache)
app.get('/debug', (req, res) => {
  res.json({
    url: req.url,
    path: req.path,
    method: req.method,
    host: req.get('host'),
    'content-type': req.get('content-type')
  });
});

// Catch-all: ver qué llega cuando no coincide nada (p. ej. por proxy Apache)
app.get('*', (req, res) => {
  res.json({ received: req.url, path: req.path, method: req.method });
});

app.listen(PORT, () => {
  console.log(`[flor-web-api] Escuchando en ${PORT}, proxy a ${WHATSAPP_URL}`);
});
