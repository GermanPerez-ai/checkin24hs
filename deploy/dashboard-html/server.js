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

const WHATSAPP_PROXY_TARGET = 'https://whatsapp.checkin24hs.com';

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
