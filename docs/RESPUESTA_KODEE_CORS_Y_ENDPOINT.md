# Respuesta para Kodee (Hostinger) – endpoint y “módulo Chats”

## Aclaración importante

En nuestro código **no** llamamos a `POST https://dashboard.checkin24hs.com/api/whatsapp-send`.  
Llamamos a **`https://whatsapp.checkin24hs.com/api/send`** (servidor WhatsApp, no el dashboard).  
El 404 que viste en la captura puede ser de una versión anterior del dashboard o de otra petición (por ejemplo un proxy que ya no usamos).

No tenemos dos backends: “Chats” es la **interfaz** del dashboard que muestra las conversaciones del **mismo** servidor WhatsApp. Para que un mensaje “aparezca en Chats” y llegue al cliente, la única vía es llamar a la API de ese servidor (`whatsapp.checkin24hs.com/api/send`). No existe un endpoint “interno de chats” distinto al que podamos redirigir cuando el usuario elige “enviar por chat”.

Por tanto, el fallo se corrige con **CORS** en la respuesta de `whatsapp.checkin24hs.com` (o en el proxy que lo expone), no cambiando a otro endpoint ni a una función “sendQuoteToChat” interna.

---

## Fragmento de código actual (donde se decide el envío)

### 1. Botón y entrada: solo hay un flujo (“Guardar y Enviar al Cliente”)

No hay selector de canal (whatsapp vs chat). Un solo botón llama a `saveAndSendViewQuote(quoteId)`:

```html
<button onclick="saveAndSendViewQuote('${quoteId}')" class="form-button" ...>
    Guardar y Enviar al Cliente
</button>
```

### 2. Función que guarda y envía (resumida)

```javascript
// Función para guardar y enviar cotización desde el modal de ver detalles
async function saveAndSendViewQuote(quoteId) {
    await saveViewQuoteChanges(quoteId);
    // ... carga quote desde Supabase/localStorage, normaliza precios, valida hotel y teléfono ...

    if (quote.clientPhone) {
        const whatsappMessage = formatWhatsAppMessage(quote);
        const cleanPhone = quote.clientPhone.replace(/\D/g, '');
        // ...
        try {
            // Enviar por la API del servidor WhatsApp → el mensaje aparece en la sección Chats (Flor IA)
            const result = await sendViaServerAPI(cleanPhone, whatsappMessage);
            // ... actualizar estado, notificación, cerrar modal ...
        } catch (error) {
            // ... copiar mensaje al portapapeles, ofrecer wa.me si falla ...
        }
    }
}
```

### 3. Función que hace la llamada HTTP (aquí se ve el endpoint real)

```javascript
async function sendViaServerAPI(phoneNumber, message) {
    if (!phoneNumber || !message) throw new Error('Número de teléfono y mensaje son requeridos');

    // getServerURL() devuelve https://whatsapp.checkin24hs.com (no el dashboard)
    const serverUrl = getServerURL();
    if (!serverUrl) throw new Error('No hay configuración de WhatsApp ni servidor disponible.');

    const sendUrl = serverUrl + '/api/send';   // → https://whatsapp.checkin24hs.com/api/send
    console.log('📡 Enviando mensaje vía API WhatsApp (por Chats):', serverUrl);

    const response = await fetch(sendUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ number: phoneNumber, text: message }),
        signal: controller.signal
    });
    // ...
}
```

### 4. De dónde sale la URL del servidor (no es el dashboard)

```javascript
function getServerURL() {
    const stored = localStorage.getItem('whatsappServerURL');
    if (stored && stored.trim() !== '') return stored.trim();
    const cfg = window.DASHBOARD_CONFIG;
    if (cfg && cfg.whatsappServerUrl && cfg.whatsappServerUrl.trim() !== '') {
        return cfg.whatsappServerUrl.trim();   // p.ej. 'https://whatsapp.checkin24hs.com'
    }
    return null;
}
```

Y en la configuración:

```javascript
window.DASHBOARD_CONFIG = {
    whatsappServerUrl: 'https://whatsapp.checkin24hs.com',
    dashboardBaseUrl: 'https://dashboard.checkin24hs.com',
    // ...
};
```

---

## Resumen para Kodee

| Lo que se piensa | Lo que hace el código realmente |
|------------------|----------------------------------|
| Se llama a `dashboard.checkin24hs.com/api/whatsapp-send` | Se llama a **`whatsapp.checkin24hs.com/api/send`** (getServerURL() + '/api/send') |
| Hay que elegir “chat” vs “whatsapp” y llamar a otro endpoint para chat | No hay selector; “enviar por Chats” = llamar a esa misma API (no hay backend de chats aparte) |
| El fallo se arregla cambiando a otro endpoint / otra función | El fallo es **CORS**: el navegador bloquea la petición desde `dashboard.checkin24hs.com` a `whatsapp.checkin24hs.com` porque la respuesta no incluye `Access-Control-Allow-Origin` |

Lo que necesitamos es que las respuestas de **`whatsapp.checkin24hs.com`** (o del proxy que lo expone en el panel) incluyan las cabeceras CORS adecuadas para el origen `https://dashboard.checkin24hs.com` (OPTIONS y POST). Con eso, el mismo código que ya tenemos haría que el mensaje se envíe y aparezca en la sección Chats.

---

## Respuesta final para pegar a Kodee (copiar todo el bloque siguiente)

---

Hola Kodee,

En nuestra app **no existe un backend de “Chat” separado de WhatsApp**. La sección “Chats” (Flor IA) en el dashboard es solo la **interfaz** que muestra las conversaciones del **mismo** servidor WhatsApp (`whatsapp.checkin24hs.com`). No hay otra API ni endpoint “interno de chats” a la que llamar. Para que un mensaje **aparezca en Chats** y llegue al cliente, la única vía técnica es llamar a la API de ese servidor: `POST https://whatsapp.checkin24hs.com/api/send`. Por tanto, si implementáramos `sendQuoteToChat()` como sugieres, esa función **tendría que llamar a la misma API** (o a un proxy que acabe en ella); no hay otro destino.

No hay selector de canal en el código: un solo botón “Guardar y Enviar al Cliente” y una sola ruta de envío. El fragmento real es este:

**1) Botón (no hay canalEnvio):**
```html
<button onclick="saveAndSendViewQuote('${quoteId}')" ...>Guardar y Enviar al Cliente</button>
```

**2) saveAndSendViewQuote (resumido) – solo llama a sendViaServerAPI:**
```javascript
async function saveAndSendViewQuote(quoteId) {
    await saveViewQuoteChanges(quoteId);
    // ... carga quote, normaliza precios, valida hotel y teléfono ...
    if (quote.clientPhone) {
        const whatsappMessage = formatWhatsAppMessage(quote);
        const cleanPhone = quote.clientPhone.replace(/\D/g, '');
        try {
            const result = await sendViaServerAPI(cleanPhone, whatsappMessage);  // única llamada de envío
            // ... actualizar estado, notificación ...
        } catch (error) { /* fallback: portapapeles + ofrecer wa.me */ }
    }
}
```

**3) sendViaServerAPI – llama a whatsapp.checkin24hs.com, no al dashboard:**
```javascript
async function sendViaServerAPI(phoneNumber, message) {
    const serverUrl = getServerURL();  // devuelve https://whatsapp.checkin24hs.com
    const sendUrl = serverUrl + '/api/send';  // → https://whatsapp.checkin24hs.com/api/send
    const response = await fetch(sendUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ number: phoneNumber, text: message })
    });
    // ...
}
function getServerURL() {
    const stored = localStorage.getItem('whatsappServerURL');
    if (stored && stored.trim() !== '') return stored.trim();
    return (window.DASHBOARD_CONFIG && window.DASHBOARD_CONFIG.whatsappServerUrl) || null;
}
// DASHBOARD_CONFIG.whatsappServerUrl = 'https://whatsapp.checkin24hs.com'
```

**Conclusión:** No llamamos a `dashboard.checkin24hs.com/api/whatsapp-send`. Llamamos a `whatsapp.checkin24hs.com/api/send`. El bloqueo viene del navegador por **CORS** (la respuesta no incluye `Access-Control-Allow-Origin` para el origen del dashboard). Separar “Chat” y “WhatsApp” en el código no resuelve nada porque para “Chat” no tenemos otro backend: el mensaje en Chats **es** el que se envía por esa API. Lo que necesitamos es que las respuestas de `whatsapp.checkin24hs.com` (o del proxy que lo expone) tengan las cabeceras CORS correctas para `https://dashboard.checkin24hs.com`. ¿Podéis revisar en el panel que ese dominio/proxy devuelva CORS para ese origen en OPTIONS y POST?

---

## Actualización: cabeceras sugeridas por Kodee (incorporadas)

Usamos **EasyPanel con Traefik**. Se añadieron las cabeceras que Kodee indicó:

- En **docker-compose.easypanel.yml**: middleware `whatsapp-cors` con `Access-Control-Allow-Origin`, `Allow-Methods`, `Allow-Headers`, **`Access-Control-Allow-Credentials: true`** (vía customResponseHeaders), `accessControlMaxAge`, `addVaryHeader`.
- En **scripts/aplicar_cors_whatsapp_servidor.sh**: mismo bloque para aplicar por SSH al servicio `checkin24hs_whatsapp`.

Comprobar en el navegador (Network → petición a `/api/send`): en OPTIONS y POST, Response Headers deben incluir `Access-Control-Allow-Origin: https://dashboard.checkin24hs.com`.

---

## Checklist de verificación (según Kodee)

Después del redeploy en EasyPanel:

1. **Network** → filtrar por `send` → revisar **OPTIONS** y **POST** a `/api/send`.
2. En **Response Headers** de ambas peticiones confirmar:
   - `Access-Control-Allow-Origin: https://dashboard.checkin24hs.com`
   - Si usás cookies o `withCredentials`: `Access-Control-Allow-Credentials: true`
3. Si los headers se ven bien pero el navegador sigue bloqueando: en **Consola** copiar el mensaje exacto de CORS (a veces falla por un header faltante, ej. `Vary` o `Allow-Headers` incompleto) y pasárselo a Kodee.
4. Cuando tengas la captura de Network (headers de OPTIONS y POST), enviarla a Kodee para que confirme si la configuración está correcta o qué ajustar.

---
