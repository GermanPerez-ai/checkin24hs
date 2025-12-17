# 📱 Guía Paso a Paso: Configurar WhatsApp en EasyPanel

## 🎯 Objetivo

Configurar 4 servicios de WhatsApp en EasyPanel para que funcionen con el dashboard de Checkin24hs.

## 📋 Paso 1: Acceder a EasyPanel

1. Abre tu navegador y ve a tu panel de EasyPanel
2. Inicia sesión con tus credenciales
3. Busca el proyecto **"Checkin24hs"** o crea uno nuevo si no existe

## 🔧 Paso 2: Configurar el Primer Servicio (whatsapp - Instancia 1)

### 2.1. Editar el Servicio `whatsapp`

1. En la lista de servicios, encuentra **`whatsapp`**
2. Haz clic en el servicio para editarlo
3. Si no existe, haz clic en **"+"** o **"Crear Servicio"** y crea uno llamado `whatsapp`

### 2.2. Configurar Variables de Entorno

1. Ve a la sección **"Variables de Entorno"** o **"Environment Variables"**
2. Haz clic en **"Agregar Variable"** o **"Add Variable"** para cada una:

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

### 2.3. Configurar Puerto

1. Ve a la sección **"Puertos"** o **"Ports"**
2. Configura:
   - **Puerto Interno**: `3001`
   - **Puerto Externo**: `3001` (o déjalo automático)
   - **Protocolo**: `HTTP`

### 2.4. Configurar Comando de Inicio

1. Ve a la sección **"Start Command"** o **"Comando de Inicio"**
2. Ingresa:
```bash
node whatsapp-server.js
```

O si usas PM2:
```bash
pm2 start whatsapp-server.js --name "whatsapp-instance-1" --update-env
```

### 2.5. Guardar y Reiniciar

1. Haz clic en **"Guardar"** o **"Save"**
2. Si el servicio está corriendo, haz clic en **"Reiniciar"** o **"Restart"**
3. Si no está corriendo, haz clic en **"Iniciar"** o **"Start"**

## 🔧 Paso 3: Configurar el Segundo Servicio (whatsapp2 - Instancia 2)

### 3.1. Editar el Servicio `whatsapp2`

1. En la lista de servicios, encuentra **`whatsapp2`**
2. Haz clic en el servicio para editarlo
3. Si no existe, créalo con el nombre `whatsapp2`

### 3.2. Configurar Variables de Entorno

Agrega las mismas variables que en el Paso 2.2, pero con estos valores:

#### Variable 1: INSTANCE_NUMBER
```
Nombre: INSTANCE_NUMBER
Valor: 2
```

#### Variable 2: PORT
```
Nombre: PORT
Valor: 3002
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

### 3.3. Configurar Puerto

- **Puerto Interno**: `3002`
- **Puerto Externo**: `3002` (o automático)
- **Protocolo**: `HTTP`

### 3.4. Configurar Comando de Inicio

```bash
node whatsapp-server.js
```

O con PM2:
```bash
pm2 start whatsapp-server.js --name "whatsapp-instance-2" --update-env
```

### 3.5. Guardar y Reiniciar

1. Guarda los cambios
2. Reinicia o inicia el servicio

## 🔧 Paso 4: Configurar el Tercer Servicio (whatsapp3 - Instancia 3)

### 4.1. Editar el Servicio `whatsapp3`

1. Encuentra o crea el servicio **`whatsapp3`**

### 4.2. Configurar Variables de Entorno

- **INSTANCE_NUMBER**: `3`
- **PORT**: `3003`
- **SUPABASE_URL**: `https://lmoeuyasuvoqhtvhkyia.supabase.co`
- **SUPABASE_ANON_KEY**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4`
- **GEMINI_API_KEY**: (opcional, misma que antes)

### 4.3. Configurar Puerto

- **Puerto Interno**: `3003`
- **Puerto Externo**: `3003`
- **Protocolo**: `HTTP`

### 4.4. Configurar Comando de Inicio

```bash
node whatsapp-server.js
```

O con PM2:
```bash
pm2 start whatsapp-server.js --name "whatsapp-instance-3" --update-env
```

### 4.5. Guardar y Reiniciar

## 🔧 Paso 5: Configurar el Cuarto Servicio (whatsapp4 - Instancia 4)

### 5.1. Editar el Servicio `whatsapp4`

1. Encuentra o crea el servicio **`whatsapp4`**

### 5.2. Configurar Variables de Entorno

- **INSTANCE_NUMBER**: `4`
- **PORT**: `3004`
- **SUPABASE_URL**: `https://lmoeuyasuvoqhtvhkyia.supabase.co`
- **SUPABASE_ANON_KEY**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4`
- **GEMINI_API_KEY**: (opcional)

### 5.3. Configurar Puerto

- **Puerto Interno**: `3004`
- **Puerto Externo**: `3004`
- **Protocolo**: `HTTP`

### 5.4. Configurar Comando de Inicio

```bash
node whatsapp-server.js
```

O con PM2:
```bash
pm2 start whatsapp-server.js --name "whatsapp-instance-4" --update-env
```

### 5.5. Guardar y Reiniciar

## ✅ Paso 6: Verificar que Todo Esté Funcionando

### 6.1. Verificar Estado de los Servicios

En EasyPanel, verifica que los 4 servicios estén:
- ✅ **Verde** (Running/Corriendo)
- ✅ Sin errores en los logs

### 6.2. Verificar Logs

Para cada servicio:
1. Haz clic en el servicio
2. Ve a la pestaña **"Logs"** o **"Registros"**
3. Verifica que no haya errores
4. Deberías ver mensajes como:
   - "WhatsApp server iniciado en puerto 3001"
   - "Esperando conexión..."
   - O un código QR si es la primera vez

### 6.3. Verificar que los Puertos Estén Abiertos

Desde la terminal de EasyPanel o desde tu servidor, puedes probar:

```bash
curl http://localhost:3001/api/status
curl http://localhost:3002/api/status
curl http://localhost:3003/api/status
curl http://localhost:3004/api/status
```

Cada uno debería responder con un JSON indicando el estado.

## 📊 Resumen de Configuración

| Servicio | INSTANCE_NUMBER | PORT | Puerto Interno |
|----------|-----------------|------|----------------|
| whatsapp | 1 | 3001 | 3001 |
| whatsapp2 | 2 | 3002 | 3002 |
| whatsapp3 | 3 | 3003 | 3003 |
| whatsapp4 | 4 | 3004 | 3004 |

## 🚀 Paso 7: Conectar desde el Dashboard

Una vez que todos los servicios estén corriendo:

1. **Abre el Dashboard**: Ve a tu dashboard de Checkin24hs
2. **Ve a Flor IA**: Menú lateral → **"Flor IA"**
3. **Abre pestaña WhatsApp**: Haz clic en **"📱 WhatsApp"**
4. **Configura URL**: En "URL del Servidor WhatsApp", ingresa: `http://72.61.58.240`
5. **Abre modal**: Haz clic en **"Conectar Múltiples WhatsApp (hasta 4)"**
6. **Conecta cada instancia**: Haz clic en **"🔗 Conectar"** en cada tarjeta
7. **Escanear QR**: Escanea cada QR con WhatsApp desde tu teléfono

## 🆘 Solución de Problemas Comunes

### ❌ Error: "Puerto ya en uso"

**Solución**: 
- Verifica que no haya otro servicio usando el mismo puerto
- Detén el servicio que está usando el puerto
- Reinicia el servicio

### ❌ Error: "INSTANCE_NUMBER no definido"

**Solución**:
- Verifica que la variable de entorno `INSTANCE_NUMBER` esté configurada
- Asegúrate de que el valor sea correcto (1, 2, 3, o 4)
- Reinicia el servicio después de agregar la variable

### ❌ Error: "No se puede conectar a Supabase"

**Solución**:
- Verifica que `SUPABASE_URL` y `SUPABASE_ANON_KEY` estén correctos
- Verifica que no haya espacios extra en los valores
- Reinicia el servicio

### ❌ El servicio no inicia

**Solución**:
1. Revisa los logs del servicio
2. Verifica que el archivo `whatsapp-server.js` exista
3. Verifica que todas las variables de entorno estén configuradas
4. Verifica que el puerto no esté en uso

### ❌ El QR no aparece

**Solución**:
1. Elimina la carpeta `.wwebjs_auth` desde el File Manager de EasyPanel
2. Reinicia el servicio
3. Espera unos segundos y revisa los logs
4. El QR debería aparecer en los logs o en el dashboard

## 📝 Checklist Final

Antes de conectar desde el dashboard, verifica:

- [ ] Servicio `whatsapp` configurado con INSTANCE_NUMBER=1, PORT=3001
- [ ] Servicio `whatsapp2` configurado con INSTANCE_NUMBER=2, PORT=3002
- [ ] Servicio `whatsapp3` configurado con INSTANCE_NUMBER=3, PORT=3003
- [ ] Servicio `whatsapp4` configurado con INSTANCE_NUMBER=4, PORT=3004
- [ ] Todos los servicios tienen SUPABASE_URL y SUPABASE_ANON_KEY configurados
- [ ] Todos los puertos están configurados correctamente (3001, 3002, 3003, 3004)
- [ ] Todos los servicios están en verde (Running) en EasyPanel
- [ ] No hay errores en los logs de ningún servicio
- [ ] Los servicios responden en `/api/status`

## 🎉 ¡Listo!

Una vez completados todos los pasos, tus servicios de WhatsApp estarán listos para conectarse desde el dashboard. Cada instancia funcionará de forma independiente y usará Flor IA para responder automáticamente.

