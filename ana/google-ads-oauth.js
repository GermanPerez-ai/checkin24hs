'use strict';
/**
 * Un solo uso en tu PC: genera GOOGLE_ADS_REFRESH_TOKEN.
 * No lo corras en el VPS. No pegues el token en el chat.
 *
 * 1. Google Cloud Console → OAuth client (Desktop o Web, redirect http://127.0.0.1:8765/callback)
 * 2. GOOGLE_ADS_CLIENT_ID y GOOGLE_ADS_CLIENT_SECRET en el entorno
 * 3. node google-ads-oauth.js
 */
const http = require('http');
const { URL } = require('url');

const PORT = 8765;
const CLIENT_ID = String(process.env.GOOGLE_ADS_CLIENT_ID || '').trim();
const CLIENT_SECRET = String(process.env.GOOGLE_ADS_CLIENT_SECRET || '').trim();
const REDIRECT = `http://127.0.0.1:${PORT}/callback`;
const SCOPE = 'https://www.googleapis.com/auth/adwords';

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.error('Definí GOOGLE_ADS_CLIENT_ID y GOOGLE_ADS_CLIENT_SECRET y volvé a correr.');
  process.exit(1);
}

const authUrl =
  'https://accounts.google.com/o/oauth2/v2/auth?' +
  new URLSearchParams({
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT,
    response_type: 'code',
    scope: SCOPE,
    access_type: 'offline',
    prompt: 'consent',
  }).toString();

const server = http.createServer(async (req, res) => {
  const u = new URL(req.url, REDIRECT);
  if (u.pathname !== '/callback') {
    res.writeHead(404);
    res.end();
    return;
  }
  const code = u.searchParams.get('code');
  const err = u.searchParams.get('error');
  if (err || !code) {
    res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('No llegó el código OAuth.');
    return;
  }
  try {
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        redirect_uri: REDIRECT,
        grant_type: 'authorization_code',
      }),
    });
    const json = await tokenRes.json();
    if (!json.refresh_token) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Google no devolvió refresh_token. Revisá prompt=consent y el tipo de cliente OAuth.');
      console.error(json);
      server.close();
      return;
    }
    console.log('\nGOOGLE_ADS_REFRESH_TOKEN=' + json.refresh_token);
    console.log('\nCargalo en EasyPanel / docker service. No lo subas a git.\n');
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Listo. El refresh token está en la terminal. Podés cerrar esta pestaña.');
    server.close();
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(String(e.message || e));
    server.close();
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log('Abrí esta URL y autorizá la cuenta de Google Ads:\n');
  console.log(authUrl);
  console.log('\nEsperando callback en', REDIRECT);
});
