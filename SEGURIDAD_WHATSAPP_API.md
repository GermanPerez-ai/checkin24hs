# 🔒 Autenticación API WhatsApp - Guía de Implementación

## Resumen de Cambios

Se implementó **autenticación por API key** para el servidor WhatsApp con Baileys. Antes de este cambio, **CUALQUIER PERSONA** con acceso a la URL `https://whatsapp.checkin24hs.com` podía:

- ✅ ~~Enviar mensajes por WhatsApp~~ → **Ahora BLOQUEADO sin API key**
- ✅ ~~Leer chats~~ → **Ahora BLOQUEADO sin API key**
- ✅ ~~Ver el código QR de conexión~~ → **Ahora BLOQUEADO sin API key**
- ✅ ~~Controlar la sesión de WhatsApp~~ → **Ahora BLOQUEADO sin API key**
- ✅ ~~Ver el estado de conexión~~ → **Ahora BLOQUEADO sin API key**

### Endpoints Protegidos

Los siguientes endpoints ahora requieren autenticación:

- `POST /api/send` - Enviar mensajes
- `POST /api/send-audio` - Enviar notas de voz
- `POST /api/send-media` - Enviar imágenes/documentos/videos
- `GET /api/qr` - Ver código QR de conexión
- `GET /api/status` - Ver estado de conexión
- `POST /api/flor/process` - Procesar con Flor IA

### Endpoints Sin Protección

Solo el endpoint de salud permanece público (sin datos sensibles):

- `GET /api/health` - Estado básico del servidor (sin información de sesión)

---

## 📋 Pasos para German en Easypanel

### 1. Generar API Key

Genera una clave segura aleatoria. Puedes usar cualquiera de estos métodos:

**Opción A - Desde terminal Linux/Mac:**
```bash
openssl rand -base64 32
```

**Opción B - Desde PowerShell (Windows):**
```powershell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```

**Opción C - Online (solo si estás en una red segura):**
https://www.random.org/strings/?num=1&len=32&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new

**Ejemplo de clave generada:**
```
3K7mP9qR2sT4uV6wX8yZ0aB1cD2eF3gH
```

⚠️ **IMPORTANTE**: Guarda esta clave en un lugar seguro (LastPass, 1Password, etc). La necesitarás en varios lugares.

---

### 2. Configurar Variables de Entorno en Easypanel

Debes configurar la variable `WHATSAPP_API_KEY` en **TODOS** los servicios que se comunican con el servidor WhatsApp.

#### A. Servidor WhatsApp (whatsapp-server-baileys)

1. En Easypanel, abre el servicio **whatsapp-server-baileys**
2. Ve a la pestaña **Environment** o **Variables de Entorno**
3. Agrega las siguientes variables:

```bash
WHATSAPP_API_KEY=3K7mP9qR2sT4uV6wX8yZ0aB1cD2eF3gH
REQUIRE_API_KEY=true
NODE_ENV=production
```

#### B. Site Monitor (scripts/site-monitor)

Si tienes el monitor de sitios desplegado como servicio:

1. Abre el servicio del **site-monitor**
2. Agrega la variable:

```bash
WHATSAPP_API_KEY=3K7mP9qR2sT4uV6wX8yZ0aB1cD2eF3gH
```

#### C. Dashboard (serve-dashboard / dashboard service)

El dashboard usa un proxy backend para no exponer la clave en el navegador:

1. Abre el servicio **dashboard** (serve-dashboard.js)
2. Agrega las variables:

```bash
WHATSAPP_API_KEY=3K7mP9qR2sT4uV6wX8yZ0aB1cD2eF3gH
WHATSAPP_API_URL=https://whatsapp.checkin24hs.com
```

**IMPORTANTE - Actualizar dashboard.html**:

El dashboard.html debe usar el adapter que intercepta las llamadas automáticamente. Agrega esta línea al **inicio** del `<body>` en dashboard.html (antes de cualquier otro script):

```html
<script src="./whatsapp-proxy-adapter.js"></script>
```

El archivo `whatsapp-proxy-adapter.js` ya está incluido en el repositorio. Este script intercepta automáticamente todas las llamadas a `https://whatsapp.checkin24hs.com/api/*` y las redirige a `/api/whatsapp-proxy/*` (el proxy local).

**ALTERNATIVA - Si no quieres modificar dashboard.html**:

Puedes servir el dashboard.html con el adapter inyectado automáticamente modificando serve-dashboard.js. Esto ya está documentado en el código del adapter.

---

### 3. Orden de Despliegue (Para NO Cortar el Servicio)

⚠️ **IMPORTANTE**: Sigue este orden exacto para evitar interrupciones:

#### Paso 1: Preparación (Sin Deploy)
```
1. Ten la API key generada y guardada
2. Lee esta guía completa antes de empezar
```

#### Paso 2: Actualizar Servidor WhatsApp
```
1. Configura las variables de entorno en whatsapp-server-baileys:
   - WHATSAPP_API_KEY=<tu-clave>
   - NODE_ENV=production
   - REQUIRE_API_KEY=true

2. Haz el deploy/restart del servicio whatsapp-server-baileys

3. Espera 30 segundos para que el servidor arranque

4. Verifica que el servidor arrancó correctamente:
   - Revisa los logs en Easypanel
   - Debe aparecer: "🔒 Autenticación por API key habilitada"
   - NO debe aparecer: "CRITICAL SECURITY ERROR"

⚠️ Si ves "CRITICAL SECURITY ERROR", el servidor NO arrancó porque falta la API key.
```

#### Paso 3: Actualizar Dashboard
```
1. Configura las variables de entorno en el servicio dashboard:
   - WHATSAPP_API_KEY=<tu-clave>
   - WHATSAPP_API_URL=https://whatsapp.checkin24hs.com

2. Haz el deploy/restart del servicio dashboard

3. Verifica que el dashboard funciona:
   - Abre https://dashboard.checkin24hs.com
   - Intenta enviar un mensaje de prueba
```

#### Paso 4: Actualizar Site Monitor (si está desplegado)
```
1. Configura WHATSAPP_API_KEY en el servicio site-monitor

2. Haz el deploy/restart del servicio

3. Verifica en los logs que no hay errores de autenticación
```

---

### 4. Verificación de Seguridad

Después del deploy, verifica que la autenticación funciona:

#### Test 1: Sin API Key (debe fallar)
```bash
curl https://whatsapp.checkin24hs.com/api/status
```

**Respuesta esperada (401 Unauthorized):**
```json
{
  "error": "No autorizado",
  "message": "Se requiere API key. Usa el header x-api-key o Authorization: Bearer <key>"
}
```

#### Test 2: Con API Key Incorrecta (debe fallar)
```bash
curl -H "x-api-key: clave-incorrecta" https://whatsapp.checkin24hs.com/api/status
```

**Respuesta esperada (403 Forbidden):**
```json
{
  "error": "Prohibido",
  "message": "API key inválida"
}
```

#### Test 3: Con API Key Correcta (debe funcionar)
```bash
curl -H "x-api-key: 3K7mP9qR2sT4uV6wX8yZ0aB1cD2eF3gH" https://whatsapp.checkin24hs.com/api/status
```

**Respuesta esperada (200 OK):**
```json
{
  "connected": true,
  "whatsapp": "connected",
  "flor": "active",
  ...
}
```

#### Test 4: Health Endpoint (debe funcionar sin API key)
```bash
curl https://whatsapp.checkin24hs.com/api/health
```

**Respuesta esperada (200 OK):**
```json
{
  "status": "ok",
  "instance": 1,
  ...
}
```

---

## 🚨 Problemas Comunes y Soluciones

### Problema 1: "CRITICAL SECURITY ERROR" en los logs

**Causa**: La variable `WHATSAPP_API_KEY` no está configurada o está vacía.

**Solución**:
1. Verifica que configuraste `WHATSAPP_API_KEY` en Easypanel
2. Verifica que no tiene espacios al inicio o al final
3. Reinicia el servicio

### Problema 2: Dashboard no puede enviar mensajes (Error 401 o 403)

**Causa**: El dashboard no tiene la API key configurada o está llamando directamente al servidor WhatsApp en lugar de usar el proxy.

**Solución**:
1. Verifica que `WHATSAPP_API_KEY` esté configurada en el servicio dashboard
2. Verifica que `WHATSAPP_API_URL` apunte a `https://whatsapp.checkin24hs.com`
3. Verifica en el código del dashboard que usa rutas `/api/whatsapp-proxy/*` en lugar de llamar directamente a `https://whatsapp.checkin24hs.com/api/*`

### Problema 3: Monitor no puede enviar alertas

**Causa**: El monitor no tiene la API key configurada.

**Solución**:
1. Agrega `WHATSAPP_API_KEY` al servicio site-monitor en Easypanel
2. Reinicia el servicio

### Problema 4: Olvidé la API key

**Causa**: No guardaste la clave.

**Solución**:
1. Genera una NUEVA clave
2. Configúrala en TODOS los servicios de nuevo
3. Esta vez guárdala en un gestor de contraseñas

---

## 📊 Consideraciones de CORS y Puerto 3001

### CORS

El servidor WhatsApp ya tiene CORS configurado para aceptar peticiones desde:
- `https://dashboard.checkin24hs.com`
- `https://www.checkin24hs.com`
- `https://checkin24hs.com`
- `https://cotizar.checkin24hs.com`
- Cualquier subdominio de `checkin24hs.com`
- Easypanel (por hostname)

**CORS NO es protección de seguridad**: CORS solo protege en navegadores. Cualquiera puede hacer peticiones desde `curl`, Postman, o un script de Python ignorando CORS completamente.

La **API key** es la verdadera protección: funciona en navegadores, en backend, en scripts, en TODAS las peticiones HTTP.

### Puerto 3001 Directo

**Recomendación**: Evaluar si el puerto 3001 debe estar expuesto públicamente.

**Opción 1 (MÁS SEGURA)**: Bloquear puerto 3001 en el firewall y usar solo Traefik:
```
✅ https://whatsapp.checkin24hs.com → Traefik → 3001 (interno)
❌ http://api1.checkin24hs.com:3001 → BLOQUEADO por firewall
```

**Opción 2 (ACTUAL)**: Dejar puerto 3001 abierto pero con API key:
```
✅ https://whatsapp.checkin24hs.com → Traefik → 3001 (con API key)
✅ http://api1.checkin24hs.com:3001 → 3001 directo (con API key)
```

Ambas opciones son seguras siempre que la API key esté configurada. La Opción 1 es marginalmente más segura (defensa en profundidad).

---

## 🔐 Seguridad Técnica Implementada

### Comparación en Tiempo Constante

El código usa comparación en tiempo constante para prevenir **timing attacks**:

```javascript
function constantTimeCompare(a, b) {
    if (a.length !== b.length) return false;
    let mismatch = 0;
    for (let i = 0; i < a.length; i++) {
        mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    return mismatch === 0;
}
```

Esto significa que la comparación siempre tarda el mismo tiempo, sea la clave correcta o incorrecta. Un atacante no puede usar el tiempo de respuesta para adivinar la clave carácter por carácter.

### Fail-Safe en Producción

Si la variable `WHATSAPP_API_KEY` no está configurada y `REQUIRE_API_KEY=true` o `NODE_ENV=production`, el servidor **NO arranca** y muestra un error crítico.

Esto previene que el servidor quede expuesto accidentalmente si German olvida configurar la clave después de un redeploy.

### Proxy Backend para Frontend

El dashboard NO expone la API key en el navegador. En su lugar:

1. El navegador llama a `/api/whatsapp-proxy/send` (en el mismo servidor del dashboard)
2. El servidor del dashboard (Node.js) agrega la API key del backend
3. El servidor del dashboard reenvía la petición a `https://whatsapp.checkin24hs.com/api/send`
4. La API key nunca llega al navegador del usuario

---

## 📝 Cambios en el Código

### Archivos Modificados

1. **whatsapp-server/whatsapp-server-baileys.js**
   - ➕ Middleware `requireApiKey` con comparación en tiempo constante
   - ➕ Validación de `WHATSAPP_API_KEY` al arrancar
   - ➕ Protección en `/api/send`, `/api/send-audio`, `/api/send-media`, `/api/qr`, `/api/status`, `/api/flor/process`
   - ➕ Header `x-api-key` en CORS permitidos

2. **scripts/site-monitor/monitor.js**
   - ➕ Lee `WHATSAPP_API_KEY` de variables de entorno
   - ➕ Agrega header `x-api-key` en todas las llamadas a WhatsApp API

3. **serve-dashboard.js**
   - ➕ Endpoints de proxy: `/api/whatsapp-proxy/*`
   - ➕ Lee `WHATSAPP_API_KEY` de variables de entorno
   - ➕ Reenvía peticiones con la API key sin exponerla al navegador

---

## ✅ Checklist Final

Antes de cerrar este ticket, verifica:

- [ ] API key generada y guardada en gestor de contraseñas
- [ ] `WHATSAPP_API_KEY` configurada en whatsapp-server-baileys
- [ ] `WHATSAPP_API_KEY` configurada en dashboard service
- [ ] `WHATSAPP_API_KEY` configurada en site-monitor (si existe)
- [ ] Servidor WhatsApp arrancó correctamente (log: "🔒 Autenticación por API key habilitada")
- [ ] Dashboard funciona y puede enviar mensajes
- [ ] Site monitor puede enviar alertas
- [ ] Test de seguridad: curl sin API key devuelve 401 ✅
- [ ] Test de seguridad: curl con API key incorrecta devuelve 403 ✅
- [ ] Test de seguridad: curl con API key correcta devuelve 200 ✅
- [ ] Test de salud: /api/health funciona sin API key ✅

---

## 🎯 Resumen para German

**Antes**: Cualquiera podía enviar mensajes de WhatsApp sin permiso.

**Ahora**: Solo quien tenga la clave secreta (API key) puede usar el servidor WhatsApp.

**Qué hacer**:
1. Genera una clave secreta
2. Ponla en Easypanel en los 3 servicios (whatsapp, dashboard, monitor)
3. Reinicia los servicios en orden: primero whatsapp, luego dashboard, luego monitor
4. Prueba que funciona

**Si algo falla**:
1. Revisa los logs en Easypanel
2. Verifica que la clave sea exactamente igual en todos los servicios
3. Verifica que el servidor whatsapp arrancó (debe decir "🔒 Autenticación por API key habilitada")

---

**Creado por**: Cursor Agent  
**Fecha**: 31 de Octubre de 2026  
**Rama**: `cursor/whatsapp-api-authentication-f520`
