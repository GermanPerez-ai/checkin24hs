# Dashboard: "No se pudo conectar al servidor WhatsApp" (pero /qr dice Conectado)

## Qué pasa

- **whatsapp.checkin24hs.com/qr** → muestra "Conectado" y el teléfono (el servidor WhatsApp está bien).
- **Dashboard → Flor IA → Estado** → muestra "No se pudo conectar al servidor WhatsApp".

El dashboard hace `fetch(whatsappServerUrl + '/api/status')` desde el navegador. Si ese request falla, muestra ese mensaje.

---

## Causas habituales

### 1. CORS (origen del dashboard no permitido)

El servidor WhatsApp solo acepta peticiones desde ciertos orígenes. Si abrís el dashboard desde una URL que no está en la lista (por ejemplo otro dominio de EasyPanel), el navegador bloquea la respuesta y el dashboard cae en "No se pudo conectar".

**Qué hacer:**
- Abrí el dashboard desde **https://dashboard.checkin24hs.com** (o la URL que tengas configurada en Traefik para el dashboard).
- En el código del servidor WhatsApp ya se permiten orígenes que contengan `dashboard`, `easypanel` o `checkin24hs`. Si usás otra URL, habría que agregarla en `allowedOrigins` en `whatsapp-server-baileys.js`.

### 2. /api/status no llega al servicio (Traefik)

Si **/api** no está enrutado al mismo servicio que **/qr**, el request a `https://whatsapp.checkin24hs.com/api/status` puede dar 404 o ir a otro backend.

**Qué hacer en el servidor:**
- Aplicar los labels de Traefik para WhatsApp (incluido el router que manda todo el host al puerto 3001), por ejemplo:
  `bash scripts/aplicar_traefik_whatsapp_servidor.sh`
- O ejecutar el `docker service update` con todos los labels de WhatsApp (incl. `whatsapp-root`).

Así tanto `/qr` como `/api/status` son servidos por el mismo contenedor.

### 3. URL de WhatsApp en el dashboard

Si el dashboard usa otra URL (por ejemplo HTTP o otro dominio), el fetch va a un sitio que no es tu WhatsApp.

**Qué revisar:**
- En el HTML del dashboard, `DASHBOARD_CONFIG.whatsappServerUrl` debe ser `https://whatsapp.checkin24hs.com` (sin barra final).
- Si usás `localStorage` o `getServerURL()`, que no esté guardada una URL distinta.

---

## Comprobar /api/status desde el servidor

En el servidor (SSH):

```bash
curl -s -o /dev/null -w "%{http_code}" -H "Accept: application/json" https://whatsapp.checkin24hs.com/api/status
```

Debería devolver **200**. Si devuelve 404, el problema es el enrutado (Traefik). Si devuelve 200 y el dashboard sigue fallando, el problema es CORS o la URL que usa el dashboard.

Desde el navegador (consola F12 en la pestaña del dashboard):

```javascript
fetch('https://whatsapp.checkin24hs.com/api/status', { headers: { 'Accept': 'application/json' } })
  .then(r => r.json())
  .then(d => console.log('Estado:', d))
  .catch(e => console.error('Error:', e));
```

Si ves "Estado: { connected: true, ... }", el backend responde bien y el fallo es solo en la lógica o el origen que usa la sección "Estado" del dashboard.

---

## Flor no responde con su prompt

Si WhatsApp está conectado pero Flor no contesta:

1. **Logs del servicio WhatsApp** (en el servidor):
   ```bash
   docker service logs -f checkin24hs_whatsapp --tail 100
   ```
   Buscar errores de Gemini (API key, cuota, 429) o de Supabase.

2. **Variables de entorno:** que estén definidas `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` (o las que use el servicio) en el stack/contenedor de WhatsApp.

3. **Prompt y configuración:** que en Supabase (o en el dashboard) el Prompt General y la configuración de Flor IA estén guardados y que el modelo sea el correcto (por ejemplo `gemini-2.0-flash`).

4. **Que los mensajes lleguen al servidor:** en los logs deberían aparecer líneas al recibir mensajes entrantes; si no aparecen, el problema puede ser número, webhook o enrutado de WhatsApp.
