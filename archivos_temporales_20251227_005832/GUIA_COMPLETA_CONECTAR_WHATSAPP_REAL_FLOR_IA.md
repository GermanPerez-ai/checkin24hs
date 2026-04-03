# 📱 Guía Completa: Conectar WhatsApp Real con Flor IA

## 🎯 Objetivo

Conectar tu número de WhatsApp real para que **Flor IA responda automáticamente** a los mensajes que recibas.

---

## ✅ Paso 1: Verificar que el Servidor de WhatsApp Esté Corriendo

### 1.1. En EasyPanel

1. **Abre EasyPanel** y ve al proyecto **"checkin24hs"**
2. **Busca el servicio** `whatsapp` o `whatsapp-api`
3. **Verifica** que esté en **🟢 VERDE (Running)**
   - Si está en 🔴 ROJO, haz clic en **"Start"** o **"Implementar"**
   - Si está en 🟡 AMARILLO, espera unos segundos o reinícialo

### 1.2. Verificar que el Servidor Responda

Abre en tu navegador:
```
https://configwp.checkin24hs.com/api1/api/status
```

Deberías ver algo como:
```json
{
  "status": "disconnected" o "connected",
  "instance": 1
}
```

Si ves un error, el servidor no está corriendo correctamente.

---

## 📱 Paso 2: Conectar WhatsApp desde el Dashboard

### 2.1. Abrir el Dashboard

1. **Abre** `https://dashboard.checkin24hs.com`
2. **Inicia sesión** si es necesario

### 2.2. Ir a la Sección de WhatsApp

1. **En el menú lateral**, haz clic en **"Flor IA"**
2. **Haz clic** en la pestaña **"📱 WhatsApp"**

### 2.3. Configurar URL del Servidor (si no lo has hecho)

1. **Verás un campo** que dice **"🌐 URL del Servidor WhatsApp:"**
2. **Ingresa**: `https://configwp.checkin24hs.com`
   - O si prefieres usar la IP: `http://72.61.58.240`
3. **Haz clic** en **"Guardar URL"**

### 2.4. Conectar WhatsApp 1

1. **Haz clic** en el botón **"Conectar"** en la tarjeta **"WhatsApp 1"**
2. **Espera** 5-10 segundos
3. **Aparecerá un código QR** en la tarjeta
4. **El estado cambiará** a "Conectando..." y mostrará el QR

---

## 📸 Paso 3: Escanear el QR con WhatsApp

### 3.1. En tu Teléfono

1. **Abre WhatsApp** en tu teléfono
2. **Toca** los **tres puntos** (⋮) en la esquina superior derecha
3. **Selecciona** **"Dispositivos vinculados"** o **"Linked Devices"**
4. **Toca** **"Vincular un dispositivo"** o **"Link a Device"**

### 3.2. Escanear el QR

1. **Apunta la cámara** del teléfono al código QR que aparece en la tarjeta "WhatsApp 1"
2. **Espera** a que WhatsApp lo escanee (puede tardar 5-10 segundos)
3. **Confirma** en tu teléfono si te pregunta
4. **El estado cambiará** automáticamente a "Conectado" en el dashboard (puede tardar 10-20 segundos)

---

## ✅ Paso 4: Verificar que Flor IA Esté Habilitada

### 4.1. Verificar Configuración del Servidor

El servidor de WhatsApp tiene estas configuraciones por defecto:
- ✅ `AUTO_REPLY: true` - Respuestas automáticas activadas
- ✅ `FLOR_ENABLED: true` - Flor habilitada
- ✅ `USE_GEMINI_AI: true` - Usa Gemini IA (si está configurada)

**Estas configuraciones ya están activadas por defecto**, así que Flor IA debería responder automáticamente.

### 4.2. Verificar que Gemini IA Esté Configurada (Opcional pero Recomendado)

Para que Flor IA responda de forma más inteligente, puedes configurar Gemini IA:

1. **En el dashboard**, ve a **"Flor IA"** → **"🤖 IA"**
2. **Busca** el campo **"API Key de Gemini"**
3. **Ingresa** tu API Key de Google Gemini
   - Si no tienes una, puedes obtenerla en: https://makersuite.google.com/app/apikey
4. **Haz clic** en **"Guardar"**

**Nota:** Si no configuras Gemini IA, Flor IA usará respuestas predefinidas (también funcionan, pero son menos inteligentes).

---

## 🧪 Paso 5: Probar que Funcione

### 5.1. Enviar un Mensaje de Prueba

1. **Desde otro número de WhatsApp** (o WhatsApp Web), envía un mensaje al número que acabas de conectar
2. **Espera** 5-10 segundos
3. **Flor IA debería responder automáticamente**

### 5.2. Verificar en el Dashboard

1. **En el dashboard**, ve a **"Flor IA"** → **"💬 Chats"**
2. **Deberías ver** el mensaje que enviaste y la respuesta de Flor IA
3. **También puedes ver** las interacciones en **"🤖 Interacciones"**

---

## 🔍 Verificar Logs del Servidor (Si No Funciona)

Si Flor IA no responde, verifica los logs del servidor:

### En EasyPanel:

1. **Ve al servicio** `whatsapp` o `whatsapp-api`
2. **Haz clic** en **"Logs"** o **"Ver logs"**
3. **Busca** mensajes como:
   - `📨 Mensaje recibido de...`
   - `🌸 Futura Flor respondió:...`
   - O errores si hay algún problema

### Desde el Terminal (SSH):

```bash
# Ver logs del servicio de WhatsApp
docker logs checkin24hs_whatsapp-api.1.[ID_DEL_CONTENEDOR] --tail 50

# O si tienes acceso directo al servidor
cd /ruta/al/whatsapp-server
tail -f logs/whatsapp.log
```

---

## 🛠️ Solución de Problemas Comunes

### ❌ Flor IA No Responde

**Posibles causas y soluciones:**

1. **Flor IA no está habilitada**
   - Verifica que `FLOR_ENABLED: true` en el servidor
   - Verifica que `AUTO_REPLY: true` en el servidor

2. **El mensaje viene de un agente**
   - Si el número está en `AGENT_NUMBERS`, Flor IA no responderá automáticamente
   - Esto es intencional para que los agentes puedan responder manualmente

3. **El servidor no está procesando mensajes**
   - Verifica los logs del servidor
   - Reinicia el servicio si es necesario

### ❌ El QR No Aparece

**Solución:**
1. Verifica que el servicio esté corriendo en EasyPanel
2. Verifica que la URL del servidor sea correcta
3. Abre la consola del navegador (F12) y revisa si hay errores
4. Espera 10-15 segundos, a veces tarda en generar el QR

### ❌ El Estado No Cambia a "Conectado"

**Solución:**
1. Espera 10-20 segundos, a veces tarda en actualizar
2. Refresca la página (F5)
3. Verifica que el QR se haya escaneado correctamente
4. Verifica los logs del servidor

### ❌ Los Mensajes No Llegan al Dashboard

**Solución:**
1. Verifica que Supabase esté configurado correctamente
2. Verifica que el dashboard esté suscrito a mensajes en tiempo real
3. Abre la consola del navegador (F12) y busca errores de conexión

---

## 📋 Checklist Completo

### Antes de Conectar:
- [ ] El servicio de WhatsApp está corriendo en EasyPanel
- [ ] Puedo acceder a `https://configwp.checkin24hs.com/api1/api/status`
- [ ] Tengo acceso al dashboard

### Durante la Conexión:
- [ ] Configuré la URL del servidor en el dashboard
- [ ] Guardé la URL (hice clic en "Guardar URL")
- [ ] Puedo hacer clic en "Conectar" en WhatsApp 1
- [ ] Aparece un QR
- [ ] Puedo escanear el QR con WhatsApp
- [ ] El estado cambia a "Conectado"

### Después de Conectar:
- [ ] Puedo enviar mensajes al número conectado
- [ ] Flor IA responde automáticamente
- [ ] Los mensajes aparecen en el dashboard
- [ ] Las interacciones se registran

---

## 🎉 ¡Listo!

Una vez que todo esté configurado:

- ✅ **Flor IA responderá automáticamente** a los mensajes que recibas
- ✅ **Los chats se guardarán** en Supabase
- ✅ **Podrás ver las interacciones** en el dashboard
- ✅ **Flor IA aprenderá** de las conversaciones

---

## 💡 Notas Importantes

1. **Un número por instancia**: Cada instancia de WhatsApp (1, 2, 3, 4) puede tener un número diferente conectado
2. **Flor IA funciona automáticamente**: Una vez conectado, no necesitas hacer nada más
3. **Los agentes no reciben respuestas automáticas**: Si un número está en la lista de agentes, Flor IA no responderá automáticamente
4. **Gemini IA mejora las respuestas**: Si configuras Gemini IA, las respuestas serán más inteligentes y naturales
5. **La base de conocimiento se actualiza**: Flor IA usa la información de hoteles que configures en el dashboard

---

## 📞 ¿Necesitas Ayuda?

Si tienes problemas en algún paso, dime:
1. **En qué paso estás**
2. **Qué error ves** (si hay alguno)
3. **Qué aparece en los logs** (si puedes verlos)

¡Y te ayudo a solucionarlo! 🚀


