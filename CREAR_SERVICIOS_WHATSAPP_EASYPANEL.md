# 🚀 Guía: Crear Servicios de WhatsApp en EasyPanel

## 🎯 Objetivo

Crear 4 servicios de WhatsApp en EasyPanel desde cero, configurándolos correctamente para que funcionen con el dashboard.

---

## 📋 Paso 1: Crear el Primer Servicio (whatsapp - Instancia 1)

### 1.1. Crear el Servicio

1. **Abre EasyPanel**
2. **Ve a tu proyecto** (o créalo si no existe)
3. **Haz clic en "+"** o **"Crear Servicio"** o **"New Service"**
4. **Nombre del servicio**: `whatsapp`
5. **Tipo de servicio**: Node.js (o el que corresponda)
6. **Haz clic en "Crear"** o **"Create"**

### 1.2. Configurar Variables de Entorno

1. **Haz clic en el servicio `whatsapp`** que acabas de crear
2. **Ve a "Variables de Entorno"** o **"Environment Variables"**
3. **Haz clic en "Agregar Variable"** o **"Add Variable"** para cada una:

#### Variable 1: INSTANCE_NUMBER
```
Nombre: INSTANCE_NUMBER
Valor: 1
```

#### Variable 2: PORT
```
Nombre: PORT
Valor: 3001
```

#### Variable 3: SUPABASE_URL
```
Nombre: SUPABASE_URL
Valor: https://lmoeuyasuvoqhtvhkyia.supabase.co
```

#### Variable 4: SUPABASE_ANON_KEY
```
Nombre: SUPABASE_ANON_KEY
Valor: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

#### Variable 5: GEMINI_API_KEY (Opcional)
```
Nombre: GEMINI_API_KEY
Valor: tu_api_key_de_gemini_aqui
```
*(Solo si tienes una API key de Google Gemini para la IA)*

### 1.3. Configurar Puerto

1. **Ve a la sección "Puertos"** o **"Ports"**
2. **Configura**:
   - **Puerto Interno**: `3001`
   - **Puerto Externo**: `3001` (o déjalo automático)
   - **Protocolo**: `HTTP`

### 1.4. Configurar Comando de Inicio

1. **Ve a la sección "Start Command"** o **"Comando de Inicio"**
2. **Ingresa**:
```bash
node whatsapp-server.js
```

### 1.5. Guardar y Iniciar

1. **Haz clic en "Guardar"** o **"Save"**
2. **Haz clic en "Iniciar"** o **"Start"**
3. **Espera unos segundos**
4. **Verifica que el servicio esté en VERDE (Running)**

---

## 📋 Paso 2: Crear el Segundo Servicio (whatsapp2 - Instancia 2)

### 2.1. Crear el Servicio

1. **Haz clic en "+"** o **"Crear Servicio"**
2. **Nombre del servicio**: `whatsapp2`
3. **Tipo de servicio**: Node.js
4. **Haz clic en "Crear"**

### 2.2. Configurar Variables de Entorno

Agrega las mismas variables que en el Paso 1.2, pero con estos valores:

- **INSTANCE_NUMBER**: `2`
- **PORT**: `3002`
- **SUPABASE_URL**: `https://lmoeuyasuvoqhtvhkyia.supabase.co`
- **SUPABASE_ANON_KEY**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4`
- **GEMINI_API_KEY**: (opcional, misma que antes)

### 2.3. Configurar Puerto

- **Puerto Interno**: `3002`
- **Puerto Externo**: `3002`
- **Protocolo**: `HTTP`

### 2.4. Configurar Comando de Inicio

```bash
node whatsapp-server.js
```

### 2.5. Guardar y Iniciar

1. Guarda los cambios
2. Inicia el servicio
3. Verifica que esté en verde

---

## 📋 Paso 3: Crear el Tercer Servicio (whatsapp3 - Instancia 3)

### 3.1. Crear el Servicio

1. **Nombre**: `whatsapp3`
2. **Tipo**: Node.js

### 3.2. Configurar Variables de Entorno

- **INSTANCE_NUMBER**: `3`
- **PORT**: `3003`
- **SUPABASE_URL**: `https://lmoeuyasuvoqhtvhkyia.supabase.co`
- **SUPABASE_ANON_KEY**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4`
- **GEMINI_API_KEY**: (opcional)

### 3.3. Configurar Puerto

- **Puerto Interno**: `3003`
- **Puerto Externo**: `3003`
- **Protocolo**: `HTTP`

### 3.4. Configurar Comando de Inicio

```bash
node whatsapp-server.js
```

### 3.5. Guardar y Iniciar

---

## 📋 Paso 4: Crear el Cuarto Servicio (whatsapp4 - Instancia 4)

### 4.1. Crear el Servicio

1. **Nombre**: `whatsapp4`
2. **Tipo**: Node.js

### 4.2. Configurar Variables de Entorno

- **INSTANCE_NUMBER**: `4`
- **PORT**: `3004`
- **SUPABASE_URL**: `https://lmoeuyasuvoqhtvhkyia.supabase.co`
- **SUPABASE_ANON_KEY**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4`
- **GEMINI_API_KEY**: (opcional)

### 4.3. Configurar Puerto

- **Puerto Interno**: `3004`
- **Puerto Externo**: `3004`
- **Protocolo**: `HTTP`

### 4.4. Configurar Comando de Inicio

```bash
node whatsapp-server.js
```

### 4.5. Guardar y Iniciar

---

## ✅ Paso 5: Verificar que Todo Esté Funcionando

### 5.1. Verificar Estado de los Servicios

En EasyPanel, verifica que los 4 servicios estén:
- ✅ **VERDE** (Running/Corriendo)
- ✅ Sin errores en los logs

### 5.2. Verificar Logs

Para cada servicio:
1. Haz clic en el servicio
2. Ve a la pestaña **"Logs"**
3. Deberías ver mensajes como:
   - "WhatsApp server iniciado en puerto 3001" (o 3002, 3003, 3004)
   - "Server listening on port..."
   - O un código QR si es la primera vez

### 5.3. Probar la Conexión

Desde la terminal de EasyPanel o desde tu servidor:

```bash
curl http://localhost:3001/api/status  # Instancia 1
curl http://localhost:3002/api/status  # Instancia 2
curl http://localhost:3003/api/status  # Instancia 3
curl http://localhost:3004/api/status  # Instancia 4
```

Cada uno debería responder con un JSON indicando el estado.

---

## 🌐 Opción: Usar DNS de Hostinger (Subdominios)

Ya que tienes los DNS configurados en Hostinger, puedes usar los subdominios en lugar de la IP directa.

### Configuración en el Dashboard

En lugar de usar `http://72.61.58.240`, puedes usar:

- **Opción 1 (IP directa)**: `http://72.61.58.240`
- **Opción 2 (Subdominios)**: `http://whatsapp.checkin24hs.com` (pero necesitarías configurar el proxy/nginx)

**Recomendación**: Por ahora, usa la **IP directa** (`http://72.61.58.240`) en el dashboard, ya que es más simple y los DNS de Hostinger ya están apuntando correctamente a esa IP.

---

## 📊 Resumen de Configuración

| Servicio | INSTANCE_NUMBER | PORT | Puerto Interno | Estado Esperado |
|----------|-----------------|------|----------------|-----------------|
| whatsapp | 1 | 3001 | 3001 | ✅ Verde (Running) |
| whatsapp2 | 2 | 3002 | 3002 | ✅ Verde (Running) |
| whatsapp3 | 3 | 3003 | 3003 | ✅ Verde (Running) |
| whatsapp4 | 4 | 3004 | 3004 | ✅ Verde (Running) |

---

## 🚀 Paso 6: Conectar desde el Dashboard

Una vez que todos los servicios estén corriendo:

1. **Abre el Dashboard**: Ve a tu dashboard de Checkin24hs
2. **Ve a Flor IA**: Menú lateral → **"Flor IA"**
3. **Abre pestaña WhatsApp**: Haz clic en **"📱 WhatsApp"**
4. **Configura URL**: En "URL del Servidor WhatsApp", ingresa: `http://72.61.58.240`
5. **Abre modal**: Haz clic en **"Conectar Múltiples WhatsApp (hasta 4)"**
6. **Conecta cada instancia**: Haz clic en **"🔗 Conectar"** en cada tarjeta
7. **Escanear QR**: Escanea cada QR con WhatsApp desde tu teléfono

---

## 🆘 Solución de Problemas

### ❌ El servicio no inicia

**Solución**:
1. Revisa los logs del servicio
2. Verifica que todas las variables de entorno estén configuradas
3. Verifica que el archivo `whatsapp-server.js` exista
4. Verifica que no haya otro proceso usando el puerto

### ❌ Error: "Puerto ya en uso"

**Solución**:
1. Detén otros servicios que puedan estar usando el puerto
2. O cambia el puerto del servicio (pero también actualiza la configuración)

### ❌ Error: "INSTANCE_NUMBER no definido"

**Solución**:
1. Verifica que la variable de entorno `INSTANCE_NUMBER` esté configurada
2. Asegúrate de que el valor sea correcto (1, 2, 3, o 4)
3. Reinicia el servicio después de agregar la variable

### ❌ Error: "Failed to fetch" en el Dashboard

**Solución**:
1. Verifica que el servicio esté corriendo (verde) en EasyPanel
2. Verifica que la URL en el dashboard sea: `http://72.61.58.240` (sin puerto)
3. Verifica que el puerto esté configurado correctamente
4. Prueba acceder a `http://72.61.58.240:3001/api/status` desde el navegador

---

## 📝 Checklist Final

Antes de conectar desde el dashboard, verifica:

- [ ] Servicio `whatsapp` creado con INSTANCE_NUMBER=1, PORT=3001
- [ ] Servicio `whatsapp2` creado con INSTANCE_NUMBER=2, PORT=3002
- [ ] Servicio `whatsapp3` creado con INSTANCE_NUMBER=3, PORT=3003
- [ ] Servicio `whatsapp4` creado con INSTANCE_NUMBER=4, PORT=3004
- [ ] Todos los servicios tienen SUPABASE_URL y SUPABASE_ANON_KEY configurados
- [ ] Todos los puertos están configurados correctamente (3001, 3002, 3003, 3004)
- [ ] Todos los servicios están en verde (Running) en EasyPanel
- [ ] No hay errores en los logs de ningún servicio
- [ ] Los servicios responden en `/api/status`

---

## 🎉 ¡Listo!

Una vez completados todos los pasos, tus servicios de WhatsApp estarán listos para conectarse desde el dashboard. Cada instancia funcionará de forma independiente y usará Flor IA para responder automáticamente.

