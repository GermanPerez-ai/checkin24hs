#!/bin/sh
# Ejecutar en el servidor desde la raíz del repo: sh deploy/dashboard-html/write-server-js.sh
# Escribe el server.js correcto para dashboard.html.

cd "$(dirname "$0")/../.." || exit 1
mkdir -p deploy/dashboard-html

cat > deploy/dashboard-html/server.js << 'ENDOFJS'
/**
 * Servidor para dashboard.html (Usuario + Contraseña).
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 3000;
const rootDir = __dirname;

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
};

function serveFile(res, filePath, contentType, isText) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data, isText ? 'utf-8' : undefined);
  });
}

function serveDashboard(res) {
  serveFile(res, path.join(rootDir, 'dashboard.html'), 'text/html', true);
}

const server = http.createServer((req, res) => {
  const urlPath = (req.url || '/').split('?')[0];

  if (urlPath === '/' || urlPath === '/index.html') {
    serveDashboard(res);
    return;
  }
  if (urlPath === '/supabase-client.js') {
    serveFile(res, path.join(rootDir, 'supabase-client.js'), 'text/javascript', true);
    return;
  }
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
  if (urlPath.startsWith('/og-cotizar.jpg')) {
    try {
      const hotelImagesDir = path.join(rootDir, 'hotel-images');
      let imagePath = null;
      if (fs.existsSync(path.join(hotelImagesDir, 'og-preview.jpg'))) {
        imagePath = path.join(hotelImagesDir, 'og-preview.jpg');
      } else {
        try {
          const entries = fs.readdirSync(hotelImagesDir, { withFileTypes: true });
          for (const e of entries) {
            if (e.isDirectory() && e.name.startsWith('hotel-')) {
              const main = path.join(hotelImagesDir, e.name, 'main.jpg');
              if (fs.existsSync(main)) {
                imagePath = main;
                break;
              }
            }
          }
        } catch (_) {}
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
  if (urlPath.includes('..')) {
    res.writeHead(400);
    res.end('Bad request');
    return;
  }
  serveDashboard(res);
});

server.listen(port, '0.0.0.0', () => {
  console.log('Dashboard (dashboard.html) en http://0.0.0.0:' + port + '/');
});
ENDOFJS

echo "OK: deploy/dashboard-html/server.js escrito. Reconstruye la imagen y actualiza el servicio."
