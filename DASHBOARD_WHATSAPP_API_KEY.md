# 🔐 Dashboard Producción: Configurar API Keys WhatsApp

## Problema Resuelto

El dashboard de producción (`deploy/dashboard-html/`) ahora está listo para funcionar con `REQUIRE_API_KEY=true` en los servidores WhatsApp.

**Antes**: El dashboard llamaba directamente a los servidores WhatsApp sin API key → fallaba con 401/403.

**Ahora**: 
- El navegador llama al proxy local del dashboard (`/whatsapp-send`, `/whatsapp-send-audio`, `/whatsapp-send-media`)
- El servidor Node.js (`server.js`) agrega la API key y reenvía al servidor WhatsApp
- La API key nunca llega al navegador del usuario

---

## 📋 Cambios Realizados

### 1. `deploy/dashboard-html/server.js`

✅ **API keys por instancia** con fallback a clave principal:
```javascript
WHATSAPP_API_KEY        // Clave principal (todas las instancias)
WHATSAPP1_API_KEY       // Específica para L1 (opcional)
WHATSAPP2_API_KEY       // Específica para L2 (opcional)
WHATSAPP3_API_KEY       // Específica para L3 (opcional)
WHATSAPP4_API_KEY       // Específica para L4 (opcional)
```

✅ **Endpoints proxy con API key**:
- `/whatsapp-send` → `https://whatsapp.checkin24hs.com/api/send` + header `x-api-key`
- `/whatsapp-send-audio` → `.../api/send-audio` + header `x-api-key`
- `/whatsapp-send-media` → `.../api/send-media` + header `x-api-key` **(NUEVO)**
- `/api/whatsapp-status/:n` → instancia N `/api/status` + header `x-api-key`
- `/api/whatsapp-qr/:n` → instancia N `/api/qr` + header `x-api-key`

### 2. `deploy/dashboard.html`

✅ **Interceptor automático** que redirige transparentemente:
```javascript
// Llamadas del navegador:
fetch('https://whatsapp.checkin24hs.com/api/send', ...)
fetch('https://whatsapp2.checkin24hs.com/api/send-audio', ...)

// Son interceptadas y redirigidas a:
fetch('/whatsapp-send', ...)
fetch('/whatsapp-send-audio', ...)
```

✅ **BUILD_ID actualizado**: 284 → **285**

---

## 🚀 Pasos para Desplegar (German)

### Paso 1: Configurar Variables de Entorno

El servicio Docker Swarm del dashboard necesita la API key de WhatsApp. Hay dos formas:

#### Opción A: Desde Easypanel (RECOMENDADO)

1. Abrí Easypanel → Servicios → **dashboard** (checkin24hs_dashboard)
2. Pestaña **Environment** o **Variables de Entorno**
3. Agregá:

```bash
WHATSAPP_API_KEY=<tu_clave_secreta_aqui>
```

**Opcional** - Si cada línea WhatsApp tiene su propia clave:
```bash
WHATSAPP_API_KEY=<clave_por_defecto>
WHATSAPP1_API_KEY=<clave_L1>
WHATSAPP2_API_KEY=<clave_L2>
WHATSAPP3_API_KEY=<clave_L3>
WHATSAPP4_API_KEY=<clave_L4>
```

4. **Guardá** los cambios (Easypanel reiniciará el servicio automáticamente)

#### Opción B: Por SSH con docker service update

Si NO usás el botón "Implementar" de Easypanel, configurá desde SSH:

```bash
# Conectate por SSH al servidor
ssh root@api1.checkin24hs.com

# Agregá la variable de entorno
docker service update \
  --env-add "WHATSAPP_API_KEY=<tu_clave_secreta_aqui>" \
  checkin24hs_dashboard

# Opcional: Variables específicas por línea
docker service update \
  --env-add "WHATSAPP1_API_KEY=<clave_L1>" \
  --env-add "WHATSAPP2_API_KEY=<clave_L2>" \
  --env-add "WHATSAPP3_API_KEY=<clave_L3>" \
  --env-add "WHATSAPP4_API_KEY=<clave_L4>" \
  checkin24hs_dashboard
```

---

### Paso 2: Deploy del Dashboard

Después de configurar las variables, desplegá la nueva imagen:

```bash
# Conectate por SSH
ssh root@api1.checkin24hs.com

# Ejecutá el script de deploy
cd /root/checkin24hs
bash scripts/deploy_dashboard_servidor.sh
```

El script hace:
1. `git pull` desde GitHub (trae tus cambios)
2. Construye imagen Docker con BUILD_ID **285**
3. Actualiza el servicio `checkin24hs_dashboard` con la nueva imagen

---

### Paso 3: Habilitar REQUIRE_API_KEY en WhatsApp

Una vez que el dashboard esté desplegado Y funcionando:

1. En Easypanel → Servicios → **whatsapp-server-baileys**
2. Environment → Cambiá:

```bash
REQUIRE_API_KEY=true
```

3. Reiniciá el servicio WhatsApp
4. Verificá en logs: "🔒 Autenticación por API key habilitada"

---

### Paso 4: Verificación

#### Test 1: Dashboard funciona (llamadas proxeadas)

1. Abrí `https://dashboard.checkin24hs.com`
2. Recargá con Ctrl+Shift+R (forzar bypass caché)
3. Abrí consola del navegador (F12)
4. Buscá: `🔒 WhatsApp API Proxy interceptor configurado`
5. Intentá enviar un mensaje de prueba desde un chat
6. ✅ Debería funcionar sin errores

En la consola deberías ver:
```
🔒 Proxeando llamada WhatsApp: https://whatsapp.checkin24hs.com/api/send → /whatsapp-send
```

#### Test 2: Build correcto desplegado

Abrí `https://dashboard.checkin24hs.com/build_id.txt` en el navegador.

**Esperado**: `285`

Si ves `284` o menos → el dashboard NO se actualizó (problema de caché o deploy falló).

#### Test 3: Logs del servidor Node.js

```bash
docker service logs checkin24hs_dashboard --tail 50
```

**Esperado**:
```
🔒 Dashboard proxy con API key habilitada
   L1: clave principal
   L2: clave principal
   L3: clave principal
   L4: clave principal
🚀 Dashboard (dashboard.html) en http://0.0.0.0:3000/
```

Si ves:
```
⚠️⚠️⚠️ ADVERTENCIA DE SEGURIDAD ⚠️⚠️⚠️
WHATSAPP_API_KEY no configurada.
```
→ La variable NO se configuró correctamente. Volvé al **Paso 1**.

---

## 🔍 Diagnóstico de Problemas

### Problema 1: Dashboard envía mensajes pero da error 401

**Causa**: El servidor Node.js del dashboard NO tiene la API key configurada.

**Solución**:
1. Verificá en Easypanel que `WHATSAPP_API_KEY` esté configurada
2. Reiniciá el servicio dashboard
3. Revisá logs: `docker service logs checkin24hs_dashboard --tail 20`

### Problema 2: Dashboard da error 502 al enviar mensajes

**Causa**: El servidor WhatsApp está caído o no responde.

**Solución**:
1. Verificá estado del servidor WhatsApp: `curl https://whatsapp.checkin24hs.com/api/health`
2. Revisá logs: `docker service logs checkin24hs_whatsapp --tail 50`

### Problema 3: Build_id.txt sigue mostrando 284

**Causa**: La imagen Docker NO se actualizó.

**Solución**:
```bash
# En el servidor
cd /root/checkin24hs
git pull
bash scripts/deploy_dashboard_servidor.sh --no-cache
```

Si sigue fallando:
```bash
# Forzar rebuild sin caché
docker build -f deploy/dashboard-html/Dockerfile \
  --build-arg BUILD_ID=285 \
  --no-cache \
  -t easypanel/checkin24hs/dashboard:285 .
  
docker service update --force --image easypanel/checkin24hs/dashboard:285 checkin24hs_dashboard
```

### Problema 4: Interceptor no redirige las llamadas

**Causa**: El navegador tiene el dashboard.html viejo en caché.

**Solución**:
1. Abrí DevTools (F12)
2. Network tab → tick "Disable cache"
3. Recargá con Ctrl+Shift+F5 (hard reload)
4. Verificá en consola: `window.DASHBOARD_BUILD_NUMBER` debe ser **285**

---

## 📊 Cómo Funciona Técnicamente

### Flujo de una Llamada Protegida

```
┌─────────────┐
│  Navegador  │
│  (usuario)  │
└──────┬──────┘
       │
       │ fetch('https://whatsapp.checkin24hs.com/api/send', {
       │   method: 'POST',
       │   body: JSON.stringify({ number: '54911...', text: 'Hola' })
       │ })
       │
       ▼
┌──────────────────────────────────┐
│  Interceptor (dashboard.html)    │
│  Detecta: whatsapp*.checkin24hs  │
│  Reescribe: /whatsapp-send       │
└──────┬───────────────────────────┘
       │
       │ fetch('/whatsapp-send', {
       │   method: 'POST',
       │   body: JSON.stringify({ number: '54911...', text: 'Hola' })
       │ })
       │
       ▼
┌────────────────────────────────────────┐
│  Proxy Node.js (server.js)             │
│  Lee: WHATSAPP_API_KEY del entorno     │
│  Agrega: headers['x-api-key'] = clave  │
└──────┬─────────────────────────────────┘
       │
       │ https.request('https://whatsapp.checkin24hs.com/api/send', {
       │   method: 'POST',
       │   headers: {
       │     'Content-Type': 'application/json',
       │     'x-api-key': 'clave_secreta_aqui'
       │   },
       │   body: JSON.stringify({ number: '54911...', text: 'Hola' })
       │ })
       │
       ▼
┌──────────────────────────────────┐
│  Servidor WhatsApp (Baileys)     │
│  Valida: x-api-key == API_KEY    │
│  Si OK → Envía mensaje           │
│  Si NO → 401/403 Unauthorized    │
└──────────────────────────────────┘
```

**Resultado**: La API key NUNCA llega al navegador del usuario. Solo viaja entre el servidor Node.js del dashboard y el servidor WhatsApp.

---

## ✅ Checklist Final

Antes de cerrar el deploy:

- [ ] `WHATSAPP_API_KEY` configurada en Easypanel o por SSH
- [ ] Dashboard desplegado con `bash scripts/deploy_dashboard_servidor.sh`
- [ ] Build ID es **285**: verificar en `https://dashboard.checkin24hs.com/build_id.txt`
- [ ] Logs del dashboard muestran: "🔒 Dashboard proxy con API key habilitada"
- [ ] `REQUIRE_API_KEY=true` en servidores WhatsApp
- [ ] Dashboard puede enviar mensajes sin error 401/403
- [ ] Consola del navegador muestra: "🔒 WhatsApp API Proxy interceptor configurado"
- [ ] `window.DASHBOARD_BUILD_NUMBER === 285` en consola del navegador

---

## 📝 Resumen para German

**Qué cambió**:
- El dashboard ahora usa un proxy backend para comunicarse con WhatsApp
- La API key se agrega en el servidor Node.js, no en el navegador
- Las llamadas directas al servidor WhatsApp son interceptadas automáticamente

**Qué hacer**:
1. Configurar `WHATSAPP_API_KEY` en el servicio dashboard (Easypanel o SSH)
2. Ejecutar `bash scripts/deploy_dashboard_servidor.sh` por SSH
3. Verificar que build_id.txt muestre **285**
4. Cambiar `REQUIRE_API_KEY=true` en servidores WhatsApp
5. Probar enviar mensajes desde el dashboard

**Si falla**:
- Revisar logs: `docker service logs checkin24hs_dashboard --tail 50`
- Verificar que la API key esté configurada (debe aparecer en logs al arrancar)
- Forzar hard reload del navegador (Ctrl+Shift+R)

---

**Creado**: 31 de Octubre de 2026  
**Rama**: `cursor/dashboard-whatsapp-api-key-production-f520`  
**BUILD_ID**: 285
