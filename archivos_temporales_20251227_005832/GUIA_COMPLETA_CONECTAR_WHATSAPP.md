# 📱 Guía Completa: Conectar WhatsApp y Obtener Códigos QR

## 🎯 Objetivo

Conectar hasta 4 números de WhatsApp desde el dashboard, obtener los códigos QR y escanearlos con tus teléfonos para que Flor IA responda automáticamente.

---

## ✅ Paso 1: Verificar Servicios en EasyPanel (IMPORTANTE)

**ANTES de conectar desde el dashboard, asegúrate de que los servicios estén corriendo:**

1. **Ve a EasyPanel** → Proyecto "checkin24hs"
2. **Verifica** que existan estos servicios:
   - `whatsapp` o `whatsapp-1` (Puerto 3001)
   - `whatsapp2` o `whatsapp-2` (Puerto 3002)
   - `whatsapp3` o `whatsapp-3` (Puerto 3003)
   - `whatsapp4` o `whatsapp-4` (Puerto 3004)

3. **Verifica** que todos estén en **🟢 VERDE (Running)**
   - Si alguno está en 🔴 ROJO o 🟡 AMARILLO, necesitas arreglarlo primero

4. **Si NO existen los servicios**, necesitas crearlos primero (ver `GUIA_IMPLEMENTAR_WHATSAPP_MULTIPLE_EASYPANEL.md`)

---

## 📱 Paso 2: Configurar URL del Servidor en el Dashboard

### 2.1. Abrir el Dashboard

1. **Abre** `dashboard.checkin24hs.com` en tu navegador
2. **Inicia sesión** si es necesario

### 2.2. Ir a la Sección de WhatsApp

1. **En el menú lateral**, busca y haz clic en **"Flor IA"**
2. **Haz clic** en la pestaña verde **"📱 WhatsApp"**

### 2.3. Configurar URL del Servidor

1. **Verás un campo** que dice **"🌐 URL del Servidor WhatsApp:"**
2. **Ingresa**: `http://72.61.58.240`
   - (Esta es la IP de tu servidor)
   - El sistema automáticamente agregará los puertos `:3001`, `:3002`, `:3003`, `:3004`

3. **Haz clic** en el botón **"Guardar URL"**
4. **Verás** un mensaje: "✅ URL del servidor guardada correctamente"

---

## 🔗 Paso 3: Conectar Cada Instancia y Obtener QR

Después de configurar la URL, verás **4 tarjetas**:
- WhatsApp 1
- WhatsApp 2
- WhatsApp 3
- WhatsApp 4

### Para WhatsApp 1:

1. **Haz clic** en el botón **"🔗 Conectar"** en la tarjeta "WhatsApp 1"
2. **Espera** 5-10 segundos
3. **Aparecerá un código QR** en la tarjeta
4. **El estado cambiará** a "Generando código QR..." y luego mostrará el QR

### Para WhatsApp 2, 3 y 4:

1. **Repite el mismo proceso** para cada tarjeta
2. **Cada una generará su propio QR único**
3. **NO cierres el modal** hasta escanear todos los QR que necesites

---

## 📸 Paso 4: Escanear los Códigos QR con WhatsApp

### En tu Teléfono:

1. **Abre WhatsApp** en tu teléfono
2. **Toca** los **tres puntos** (⋮) en la esquina superior derecha
3. **Selecciona** **"Dispositivos vinculados"** o **"Linked Devices"**
4. **Toca** **"Vincular un dispositivo"** o **"Link a Device"**

### Escanear el Primer QR (WhatsApp 1):

1. **Apunta la cámara** del teléfono al código QR que aparece en la tarjeta "WhatsApp 1"
2. **Espera** a que WhatsApp lo escanee (puede tardar 5-10 segundos)
3. **Confirma** en tu teléfono si te pregunta
4. **El estado cambiará** automáticamente a "Conectado" en el dashboard (puede tardar 10-20 segundos)

### Escanear los Otros QR:

1. **Repite el proceso** para WhatsApp 2, 3 y 4
2. **Cada número de teléfono** necesita escanear su propio QR
3. **Si quieres conectar el mismo número** a múltiples instancias, puedes hacerlo (pero no es recomendado)

---

## ✅ Paso 5: Verificar que Están Conectados

Después de escanear cada QR, deberías ver:

- ✅ **Estado**: Cambia de "Esperando conexión" a **"Conectado"** (en verde)
- 📱 **Número**: Aparece el número de teléfono conectado (ej: +5491123456789)
- 👤 **Nombre**: Aparece el nombre del usuario de WhatsApp
- 🕐 **Última actividad**: Muestra cuándo fue la última conexión

---

## 🔄 Si Necesitas Reiniciar una Conexión

Si un WhatsApp se desconecta o quieres cambiar el número:

1. **Haz clic** en **"Desconectar"** en la tarjeta correspondiente
2. **Espera** unos segundos
3. **Haz clic** en **"🔗 Conectar"** nuevamente
4. **Se generará un nuevo QR** para escanear

---

## 🆘 Solución de Problemas

### ❌ El QR no aparece cuando hago clic en "Conectar"

**Solución:**
1. Verifica que el servicio correspondiente esté en **verde (Running)** en EasyPanel
2. Verifica que la URL del servidor sea correcta: `http://72.61.58.240`
3. Abre la consola del navegador (`F12`) y revisa si hay errores
4. Espera 10-15 segundos, a veces tarda en generar el QR
5. Verifica que hayas guardado la URL del servidor (botón "Guardar URL")

### ❌ Aparece "Error: Servidor no responde"

**Solución:**
1. Verifica que el servicio esté corriendo en EasyPanel
2. Verifica que el puerto esté correcto (3001, 3002, 3003, 3004)
3. Verifica la URL del servidor en el dashboard (debe ser `http://72.61.58.240`)
4. Revisa los logs del servicio en EasyPanel
5. Prueba acceder directamente: `http://72.61.58.240:3001/api/status` (debe responder)

### ❌ El QR aparece pero no puedo escanearlo

**Solución:**
1. Asegúrate de que el QR esté completamente visible en la pantalla
2. Acerca o aleja la cámara del teléfono
3. Asegúrate de tener buena iluminación
4. Intenta refrescar la página y generar un nuevo QR
5. Verifica que WhatsApp tenga permisos de cámara

### ❌ El estado no cambia a "Conectado" después de escanear

**Solución:**
1. Espera 10-20 segundos, a veces tarda en actualizar
2. Refresca la página (`F5`)
3. Verifica que el servicio esté corriendo en EasyPanel
4. Revisa los logs del servicio para ver si hay errores
5. Verifica que el QR se haya escaneado correctamente (WhatsApp debe mostrar "Dispositivo vinculado")

---

## 📋 Checklist Completo

### Antes de Conectar:
- [ ] Los 4 servicios están creados en EasyPanel
- [ ] Todos los servicios están en verde (Running)
- [ ] Las variables de entorno están configuradas
- [ ] Los puertos están configurados (3001, 3002, 3003, 3004)

### Durante la Conexión:
- [ ] Puedo acceder a Flor IA → WhatsApp en el dashboard
- [ ] Configuré la URL del servidor: `http://72.61.58.240`
- [ ] Guardé la URL (hice clic en "Guardar URL")
- [ ] Puedo hacer clic en "Conectar" en cada tarjeta
- [ ] Aparece un QR para cada instancia
- [ ] Puedo escanear los QR con WhatsApp
- [ ] El estado cambia a "Conectado" después de escanear

---

## 💡 Notas Importantes

1. **Cada instancia es independiente**: Cada WhatsApp tiene su propia sesión
2. **Un QR por instancia**: Cada número necesita escanear su propio QR
3. **Flor IA funciona automáticamente**: Una vez conectados, Flor IA responderá automáticamente
4. **Los QR expiran**: Si no escaneas en 2-3 minutos, necesitas generar uno nuevo
5. **Puedes conectar el mismo número**: Técnicamente puedes conectar el mismo número a múltiples instancias, pero no es recomendado
6. **La URL se guarda automáticamente**: Una vez que guardes la URL, se recordará para la próxima vez

---

## 🎉 ¡Listo!

Una vez que todos los WhatsApp estén conectados:
- ✅ Flor IA responderá automáticamente a los mensajes
- ✅ Los chats se guardarán en Supabase
- ✅ Podrás ver las interacciones en el dashboard
- ✅ Cada instancia funcionará independientemente

---

## 📝 Resumen Rápido

1. ✅ Verifica servicios en EasyPanel (deben estar en verde)
2. ✅ Abre dashboard → Flor IA → WhatsApp
3. ✅ Configura URL: `http://72.61.58.240` y guarda
4. ✅ Haz clic en "Conectar" en cada tarjeta
5. ✅ Escanea cada QR con WhatsApp
6. ✅ Verifica que el estado cambie a "Conectado"

---

¿Necesitas ayuda con algún paso específico? ¡Dime en qué paso estás y te ayudo!



