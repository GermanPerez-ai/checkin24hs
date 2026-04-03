/**
 * Sirve el dashboard desde tu PC (raíz del repo).
 * Uso: desde la raíz del repo ejecutá: node servir_dashboard_local.js
 * Luego abrí http://localhost:3000
 * Para exponerlo online: en otra terminal ejecutá ngrok http 3000 y usá la URL que te da.
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const port = process.env.PORT || 3000;
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
  'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
  'Pragma': 'no-cache',
  'Expires': '0',
};

function serveFile(res, filePath, contentType, isText, extraHeaders) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    const headers = { 'Content-Type': contentType, ...(extraHeaders || {}) };
    res.writeHead(200, headers);
    res.end(data, isText ? 'utf-8' : undefined);
  });
}

function serveDashboard(res) {
  const indexPath = path.join(rootDir, 'dashboard.html');
  serveFile(res, indexPath, 'text/html', true, noCacheHeaders);
}

const server = http.createServer((req, res) => {
  const urlPath = (req.url || '/').split('?')[0];

  if (urlPath === '/' || urlPath === '/index.html') {
    serveDashboard(res);
    return;
  }

  if (urlPath === '/supabase-client.js') {
    const p = path.join(rootDir, 'supabase-client.js');
    serveFile(res, p, 'text/javascript', true, noCacheHeaders);
    return;
  }

  if (urlPath === '/logo.png') {
    const p = path.join(rootDir, 'deploy', 'logo.png');
    if (!fs.existsSync(p)) {
      res.writeHead(404);
      res.end();
      return;
    }
    serveFile(res, p, 'image/png', false);
    return;
  }

  if (urlPath.startsWith('/og-cotizar.jpg')) {
    const localOg = path.join(rootDir, 'hotel-images', 'hotel-images', 'og-preview.jpg');
    const p = fs.existsSync(localOg) ? localOg : path.join(rootDir, 'deploy', 'logo.png');
    if (!fs.existsSync(p)) {
      res.writeHead(404);
      res.end();
      return;
    }
    serveFile(res, p, 'image/jpeg', false);
    return;
  }

  if (urlPath.includes('..')) {
    res.writeHead(400);
    res.end('Bad request');
    return;
  }

  serveDashboard(res);
});

server.listen(port, '0.0.0.0', () => {
  console.log('');
  console.log('  Dashboard LOCAL en:  http://localhost:' + port + '/');
  console.log('  Para exponerlo online: ejecutá en otra terminal  npx ngrok http ' + port);
  console.log('');
});
