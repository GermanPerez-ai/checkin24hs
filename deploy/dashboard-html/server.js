/**
 * Servidor para dashboard.html (Usuario + Contraseña).
 * Sirve dashboard.html en /, supabase-config.js, supabase-client.js, logo.png, og-cotizar.jpg.
 * POST /whatsapp-send y /whatsapp-send-audio → proxy a whatsapp.checkin24hs.com (evita CORS).
 * El resto de rutas → dashboard.html (SPA / client-side routing).
 */
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const tls = require('tls');

const WHATSAPP_PROXY_TARGET = 'https://whatsapp.checkin24hs.com';

/** Proxy estado/QR: red interna Docker primero, luego URL pública (evita 404 Traefik + CORS en dashboard). */
const WHATSAPP_INSTANCE_TARGETS = {
  1: {
    internal: (process.env.WHATSAPP1_INTERNAL_URL || 'http://checkin24hs_whatsapp:3001').replace(/\/$/, ''),
    public: (process.env.WHATSAPP1_PUBLIC_URL || 'https://whatsapp.checkin24hs.com').replace(/\/$/, ''),
  },
  2: {
    internal: (process.env.WHATSAPP2_INTERNAL_URL || 'http://checkin24hs_whatsapp2:3002').replace(/\/$/, ''),
    public: (process.env.WHATSAPP2_PUBLIC_URL || 'https://whatsapp2.checkin24hs.com').replace(/\/$/, ''),
  },
  3: {
    internal: (process.env.WHATSAPP3_INTERNAL_URL || 'http://checkin24hs_whatsapp3:3003').replace(/\/$/, ''),
    public: (process.env.WHATSAPP3_PUBLIC_URL || 'https://whatsapp3.checkin24hs.com').replace(/\/$/, ''),
  },
  4: {
    internal: (process.env.WHATSAPP4_INTERNAL_URL || 'http://checkin24hs_whatsapp4:3004').replace(/\/$/, ''),
    public: (process.env.WHATSAPP4_PUBLIC_URL || 'https://whatsapp4.checkin24hs.com').replace(/\/$/, ''),
  },
};

function proxyHttpGet(urlString, extraHeaders, cb) {
  let u;
  try {
    u = new URL(urlString);
  } catch (e) {
    cb(e);
    return;
  }
  const mod = u.protocol === 'https:' ? https : http;
  const opts = {
    hostname: u.hostname,
    port: u.port || (u.protocol === 'https:' ? 443 : 80),
    path: u.pathname + (u.search || ''),
    method: 'GET',
    headers: extraHeaders || {},
    timeout: 15000,
  };
  // Fallback HTTPS a subdominios propios: no fallar si Let's Encrypt aún no renovó el cert.
  if (u.protocol === 'https:') {
    opts.rejectUnauthorized = false;
  }
  const req = mod.request(opts, (proxyRes) => {
    const chunks = [];
    proxyRes.on('data', (c) => chunks.push(c));
    proxyRes.on('end', () => cb(null, proxyRes.statusCode, Buffer.concat(chunks), proxyRes.headers));
  });
  req.on('error', (err) => cb(err));
  req.on('timeout', () => {
    req.destroy();
    cb(new Error('timeout'));
  });
  req.end();
}

function proxyWhatsAppGet(instance, apiPath, reqHeaders, res) {
  const inst = parseInt(instance, 10);
  const targets = WHATSAPP_INSTANCE_TARGETS[inst];
  if (!targets) {
    res.writeHead(404, { 'Content-Type': 'application/json', ...noCacheHeaders });
    res.end(JSON.stringify({ error: 'Instancia WhatsApp no configurada: ' + instance }));
    return;
  }
  const urls = [targets.internal, targets.public];
  const tryAt = (idx) => {
    if (idx >= urls.length) {
      res.writeHead(502, { 'Content-Type': 'application/json', ...noCacheHeaders });
      res.end(JSON.stringify({ error: 'No se pudo contactar WhatsApp Línea ' + inst }));
      return;
    }
    const fullUrl = urls[idx] + apiPath;
    proxyHttpGet(fullUrl, reqHeaders, (err, code, body, headers) => {
      if (err || !code || code === 404 || code >= 502) {
        console.warn('[WhatsApp proxy] L' + inst, fullUrl, err?.message || ('HTTP ' + code));
        tryAt(idx + 1);
        return;
      }
      const ct = (headers && (headers['content-type'] || headers['Content-Type'])) || 'application/json';
      res.writeHead(code, { 'Content-Type': ct, ...noCacheHeaders });
      res.end(body);
    });
  };
  tryAt(0);
}

const port = 3000;
const rootDir = __dirname;

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const noCacheHeaders = {
  'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0, proxy-revalidate',
  'Pragma': 'no-cache',
  'Expires': '0',
  'Surrogate-Control': 'no-store',
};

function sendPlainJson(res, status, json) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', ...noCacheHeaders });
  res.end(JSON.stringify(json));
}

function smtpConfigured() {
  return Boolean((process.env.SMTP_PASS || '').trim());
}

function parseEmailList(raw) {
  return String(raw || '')
    .split(/[,;]+/)
    .map((s) => s.trim())
    .filter((s) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s));
}

function smtpReadLine(socket, timeoutMs) {
  return new Promise((resolve, reject) => {
    let buf = '';
    const onData = (chunk) => {
      buf += chunk.toString('utf8');
      const parts = buf.split(/\r?\n/);
      buf = parts.pop() || '';
      for (const line of parts) {
        if (/^\d{3}[\s-]/.test(line)) {
          cleanup();
          resolve(line);
          return;
        }
      }
    };
    const onErr = (err) => {
      cleanup();
      reject(err);
    };
    const t = setTimeout(() => {
      cleanup();
      reject(new Error('smtp_timeout'));
    }, timeoutMs || 20000);
    const cleanup = () => {
      clearTimeout(t);
      socket.removeListener('data', onData);
      socket.removeListener('error', onErr);
    };
    socket.on('data', onData);
    socket.on('error', onErr);
  });
}

function smtpExpect(socket, okPrefix) {
  return smtpReadLine(socket).then((line) => {
    if (!String(line).startsWith(String(okPrefix))) {
      throw new Error('smtp: ' + line);
    }
    return line;
  });
}

function smtpWrite(socket, line) {
  socket.write(line + '\r\n');
}

function sendSmtpMail({ to, bcc, subject, text, replyTo }) {
  const host = process.env.SMTP_HOST || 'smtp.hostinger.com';
  const port = parseInt(process.env.SMTP_PORT || '465', 10);
  const user = (process.env.SMTP_USER || process.env.SMTP_FROM || 'reservas@checkin24hs.com').trim();
  const pass = (process.env.SMTP_PASS || '').trim();
  const from = (process.env.SMTP_FROM || user).trim();
  const recipients = [...parseEmailList(to), ...parseEmailList(bcc || process.env.MAIL_BCC || from)];
  const unique = [...new Set(recipients)];
  if (!pass) return Promise.reject(new Error('SMTP_PASS no configurado'));
  if (!unique.length) return Promise.reject(new Error('Sin destinatarios'));
  const safeSubject = String(subject || '').replace(/[\r\n]+/g, ' ').slice(0, 200);
  const safeText = String(text || '').replace(/\r\n/g, '\n').replace(/\n/g, '\r\n').slice(0, 20000);
  const headers = [
    'From: Checkin24hs Reservas <' + from + '>',
    'To: ' + parseEmailList(to).join(', '),
    parseEmailList(bcc || process.env.MAIL_BCC || from).length
      ? 'Bcc: ' + parseEmailList(bcc || process.env.MAIL_BCC || from).join(', ')
      : '',
    replyTo ? 'Reply-To: ' + String(replyTo).replace(/[\r\n]+/g, '') : '',
    'Subject: =?UTF-8?B?' + Buffer.from(safeSubject, 'utf8').toString('base64') + '?=',
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: 8bit',
  ].filter(Boolean);

  return new Promise((resolve, reject) => {
    const socket = tls.connect({ host, port, servername: host }, async () => {
      try {
        await smtpExpect(socket, '220');
        smtpWrite(socket, 'EHLO checkin24hs.com');
        // EHLO can send several 250- then 250
        let ehlo = '';
        for (let i = 0; i < 12; i++) {
          ehlo = await smtpReadLine(socket);
          if (ehlo.startsWith('250 ')) break;
          if (!ehlo.startsWith('250')) throw new Error('smtp ehlo: ' + ehlo);
        }
        smtpWrite(socket, 'AUTH LOGIN');
        await smtpExpect(socket, '334');
        smtpWrite(socket, Buffer.from(user, 'utf8').toString('base64'));
        await smtpExpect(socket, '334');
        smtpWrite(socket, Buffer.from(pass, 'utf8').toString('base64'));
        await smtpExpect(socket, '235');
        smtpWrite(socket, 'MAIL FROM:<' + from + '>');
        await smtpExpect(socket, '250');
        for (const rcpt of unique) {
          smtpWrite(socket, 'RCPT TO:<' + rcpt + '>');
          await smtpExpect(socket, '250');
        }
        smtpWrite(socket, 'DATA');
        await smtpExpect(socket, '354');
        socket.write(headers.join('\r\n') + '\r\n\r\n' + safeText.replace(/^\./gm, '..') + '\r\n.\r\n');
        await smtpExpect(socket, '250');
        smtpWrite(socket, 'QUIT');
        socket.end();
        resolve({ ok: true, to: parseEmailList(to), bcc: parseEmailList(bcc || process.env.MAIL_BCC || from) });
      } catch (err) {
        try { socket.destroy(); } catch (_) {}
        reject(err);
      }
    });
    socket.setTimeout(25000, () => {
      socket.destroy();
      reject(new Error('smtp_timeout'));
    });
    socket.on('error', reject);
  });
}

function readJsonBody(req, limit) {
  const max = limit || 50000;
  return new Promise((resolve, reject) => {
    const chunks = [];
    let n = 0;
    req.on('data', (c) => {
      n += c.length;
      if (n > max) {
        reject(new Error('body_too_large'));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on('end', () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}'));
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

function serveFile(res, filePath, contentType, isText, extraHeaders) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    const headers = { 'Content-Type': contentType, ...extraHeaders };
    res.writeHead(200, headers);
    res.end(data, isText ? 'utf-8' : undefined);
  });
}

function serveDashboard(res) {
  const indexPath = path.join(rootDir, 'dashboard.html');
  serveFile(res, indexPath, 'text/html', true, noCacheHeaders);
}

const server = http.createServer((req, res) => {
  let urlPath = (req.url || '/').split('?')[0];
  // Normalizar: quitar barra final
  if (urlPath.length > 1 && urlPath.endsWith('/')) urlPath = urlPath.slice(0, -1);

  // Rutas alternativas /v81/, /v174/, etc. para evitar caché del navegador (misma app, path distinto)
  const versionRoute = urlPath.match(/^\/v(\d+)(\/|$)/);
  if (versionRoute) {
    urlPath = urlPath.replace(/^\/v\d+\/?/, '/') || '/';
  }

  // Proxy WhatsApp: /whatsapp-send, /api/whatsapp-send (por si Traefik solo reenvía /api/*)
  const isProxySend = urlPath === '/whatsapp-send' || urlPath === '/api/whatsapp-send' || urlPath.endsWith('/whatsapp-send');
  const isProxyAudio = urlPath === '/whatsapp-send-audio' || urlPath === '/api/whatsapp-send-audio' || urlPath.endsWith('/whatsapp-send-audio');
  if (req.method === 'OPTIONS' && (isProxySend || isProxyAudio)) {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Max-Age': '86400'
    });
    res.end();
    return;
  }
  if (req.method === 'POST' && (isProxySend || isProxyAudio)) {
    const targetPath = isProxyAudio ? '/api/send-audio' : '/api/send';
    let body = [];
    req.on('data', (chunk) => body.push(chunk));
    req.on('end', () => {
      const rawBody = Buffer.concat(body);
      const targetUrl = new URL(WHATSAPP_PROXY_TARGET + targetPath);
      const opts = {
        hostname: targetUrl.hostname,
        port: targetUrl.port || 443,
        path: targetUrl.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': rawBody.length
        }
      };
      const proxyReq = https.request(opts, (proxyRes) => {
        res.writeHead(proxyRes.statusCode || 200, {
          'Content-Type': proxyRes.headers['content-type'] || 'application/json'
        });
        proxyRes.pipe(res);
      });
      proxyReq.on('error', (err) => {
        console.error('Proxy WhatsApp error:', err.message);
        res.writeHead(502, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Proxy error: ' + err.message }));
      });
      proxyReq.end(rawBody);
    });
    return;
  }

  // Proxy estado / QR WhatsApp por línea (misma origen que dashboard → sin CORS, funciona aunque Traefik público falle)
  const waStatusMatch = urlPath.match(/^\/api\/whatsapp-status\/(\d+)$/);
  if (req.method === 'GET' && waStatusMatch) {
    proxyWhatsAppGet(waStatusMatch[1], '/api/status', { Accept: 'application/json' }, res);
    return;
  }
  const waQrMatch = urlPath.match(/^\/api\/whatsapp-qr\/(\d+)$/);
  if (req.method === 'GET' && waQrMatch) {
    proxyWhatsAppGet(waQrMatch[1], '/api/qr', {
      Accept: 'text/html,application/json',
      'User-Agent': req.headers['user-agent'] || 'Mozilla/5.0',
    }, res);
    return;
  }

  if (req.method === 'GET' && (urlPath === '/api/hotel-mail/ready' || urlPath.endsWith('/hotel-mail/ready'))) {
    sendPlainJson(res, 200, {
      ok: true,
      configured: smtpConfigured(),
      from: process.env.SMTP_FROM || process.env.SMTP_USER || 'reservas@checkin24hs.com',
    });
    return;
  }

  if (req.method === 'OPTIONS' && (urlPath === '/api/hotel-mail' || urlPath.endsWith('/hotel-mail'))) {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    res.end();
    return;
  }

  if (req.method === 'POST' && (urlPath === '/api/hotel-mail' || urlPath.endsWith('/hotel-mail'))) {
    readJsonBody(req)
      .then((body) => {
        const to = parseEmailList(body && body.to);
        const kind = String((body && body.kind) || '').toLowerCase();
        if (!to.length) {
          sendPlainJson(res, 400, { ok: false, error: 'Falta el email del hotel' });
          return null;
        }
        if (!['anular', 'modificar', 'consulta'].includes(kind)) {
          sendPlainJson(res, 400, { ok: false, error: 'Acción inválida' });
          return null;
        }
        if (!smtpConfigured()) {
          sendPlainJson(res, 503, { ok: false, error: 'SMTP no configurado en el dashboard (SMTP_USER / SMTP_PASS)' });
          return null;
        }
        const bcc = process.env.MAIL_BCC || process.env.SMTP_FROM || process.env.SMTP_USER || 'reservas@checkin24hs.com';
        return sendSmtpMail({
          to: to.join(', '),
          bcc,
          subject: body.subject,
          text: body.text,
          replyTo: body.replyTo,
        }).then((sent) => {
          console.log('[hotel-mail]', kind, sent.to.join(','), (body && body.code) || '');
          sendPlainJson(res, 200, { ok: true, ...sent, kind });
        });
      })
      .catch((err) => {
        console.error('[hotel-mail]', err.message);
        sendPlainJson(res, 500, { ok: false, error: err.message || 'No se pudo enviar' });
      });
    return;
  }

  // / → dashboard.html
  if (urlPath === '/' || urlPath === '/index.html') {
    serveDashboard(res);
    return;
  }

  // /build_id.txt — diagnóstico: qué BUILD_ID tiene la imagen que está sirviendo (sin caché)
  if (urlPath === '/build_id.txt') {
    const p = path.join(rootDir, 'build_id.txt');
    if (fs.existsSync(p)) {
      serveFile(res, p, 'text/plain', true, noCacheHeaders);
    } else {
      res.writeHead(404, { ...noCacheHeaders });
      res.end('build_id.txt not found');
    }
    return;
  }

  // /supabase-config.js (credenciales; sin caché)
  if (urlPath === '/supabase-config.js') {
    const p = path.join(rootDir, 'supabase-config.js');
    if (fs.existsSync(p)) {
      serveFile(res, p, 'text/javascript', true, noCacheHeaders);
    } else {
      res.writeHead(404, { ...noCacheHeaders });
      res.end('supabase-config.js not found');
    }
    return;
  }

  // /supabase-client.js (sin caché para que coincida con el build)
  if (urlPath === '/supabase-client.js') {
    const p = path.join(rootDir, 'supabase-client.js');
    serveFile(res, p, 'text/javascript', true, noCacheHeaders);
    return;
  }

  // /logo.png (opcional)
  if (urlPath === '/logo.png') {
    const p = path.join(rootDir, 'logo.png');
    if (!fs.existsSync(p)) {
      res.writeHead(404);
      res.end();
      return;
    }
    serveFile(res, p, 'image/png', false);
    return;
  }

  // /og-cotizar.jpg — Prioridad: 1) og-cotizar.jpg en la misma carpeta (bind mount), 2) hotel-images
  if (urlPath.startsWith('/og-cotizar.jpg')) {
    try {
      const selectedHotel = process.env.OG_COTIZAR_IMAGE || null;
      const hotelImagesDir = path.join(rootDir, 'hotel-images');
      // Prioridad 0: imagen en la misma carpeta que server.js (ideal para bind mount en /root/checkin24hs/)
      const localOgPath = path.join(rootDir, 'og-cotizar.jpg');
      const customPaths = [
        localOgPath,
        path.join(hotelImagesDir, 'og-preview.jpg'),
      ];

      const findHotels = (dir) => {
        const hotels = [];
        try {
          if (!fs.existsSync(dir)) return hotels;
          const entries = fs.readdirSync(dir, { withFileTypes: true });
          entries.forEach((e) => {
            if (e.isDirectory() && e.name.startsWith('hotel-')) {
              const main = path.join(dir, e.name, 'main.jpg');
              if (fs.existsSync(main)) hotels.push(e.name);
            }
          });
        } catch (_) {}
        return hotels.sort();
      };

      const allHotels = findHotels(hotelImagesDir);
      const possiblePaths = [...customPaths];
      if (selectedHotel) {
        possiblePaths.push(path.join(hotelImagesDir, selectedHotel, 'main.jpg'));
      }
      allHotels.forEach((h) => {
        if (!selectedHotel || h !== selectedHotel) {
          possiblePaths.push(path.join(hotelImagesDir, h, 'main.jpg'));
        }
      });

      let imagePath = null;
      for (const p of possiblePaths) {
        if (fs.existsSync(p)) { imagePath = p; break; }
      }
      if (!imagePath) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Imagen de preview no encontrada' }));
        return;
      }
      fs.readFile(imagePath, (err, content) => {
        if (err) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Error al leer imagen' }));
          return;
        }
        res.writeHead(200, {
          'Content-Type': 'image/jpeg',
          'Cache-Control': 'public, max-age=86400',
        });
        res.end(content);
      });
      return;
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Error al servir imagen' }));
      return;
    }
  }

  // Evitar path traversal
  if (urlPath.includes('..')) {
    res.writeHead(400);
    res.end('Bad request');
    return;
  }

  // SPA fallback: cualquier otra ruta → dashboard.html (client-side routing)
  serveDashboard(res);
});

server.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Dashboard (dashboard.html) en http://0.0.0.0:${port}/`);
});
