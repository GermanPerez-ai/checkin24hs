# 📱 Guía: Conectar WhatsApp Existentes en EasyPanel

## ✅ Respuesta Rápida

**SÍ, puedes usar tus servicios existentes** (`whatsapp`, `whatsapp2`, `whatsapp3`, `whatsapp4`). Solo necesitas configurarlos correctamente.

## 🔧 Paso 1: Verificar y Configurar los Servicios Existentes

Para cada uno de tus servicios en EasyPanel, verifica y configura lo siguiente:

### 📋 Mapeo de Servicios

| Servicio en EasyPanel | Instancia | Puerto | INSTANCE_NUMBER | PORT |
|----------------------|-----------|-------|-----------------|------|
| `whatsapp` | 1 | 3001 | 1 | 3001 |
| `whatsapp2` | 2 | 3002 | 2 | 3002 |
| `whatsapp3` | 3 | 3003 | 3 | 3003 |
| `whatsapp4` | 4 | 3004 | 4 | 3004 |

### ⚙️ Configuración en EasyPanel

Para cada servicio, ve a **Variables de Entorno** y asegúrate de tener:

#### Para `whatsapp` (Instancia 1):
```env
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
GEMINI_API_KEY=tu_api_key_de_gemini  # Opcional
```

#### Para `whatsapp2` (Instancia 2):
```env
INSTANCE_NUMBER=2
PORT=3002
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
GEMINI_API_KEY=tu_api_key_de_gemini  # Opcional
```

#### Para `whatsapp3` (Instancia 3):
```env
INSTANCE_NUMBER=3
PORT=3003
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
GEMINI_API_KEY=tu_api_key_de_gemini  # Opcional
```

#### Para `whatsapp4` (Instancia 4):
```env
INSTANCE_NUMBER=4
PORT=3004
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
GEMINI_API_KEY=tu_api_key_de_gemini  # Opcional
```

### 🔌 Configuración de Puertos

Para cada servicio, verifica que el **puerto interno** esté configurado correctamente:

- `whatsapp` → Puerto interno: **3001**
- `whatsapp2` → Puerto interno: **3002**
- `whatsapp3` → Puerto interno: **3003**
- `whatsapp4` → Puerto interno: **3004**

## 🚀 Paso 2: Conectar desde el Dashboard

1. **Abre el Dashboard**: Ve a tu dashboard de Checkin24hs
2. **Ve a Flor IA**: En el menú lateral, haz clic en **"Flor IA"**
3. **Abre la pestaña WhatsApp**: Haz clic en la pestaña verde **"📱 WhatsApp"**
4. **Configura la URL del servidor**: 
   - En el campo **"URL del Servidor WhatsApp"**, ingresa: `http://72.61.58.240`
   - (El sistema automáticamente agregará los puertos :3001, :3002, :3003, :3004)
5. **Abre el modal**: Haz clic en el botón verde **"Conectar Múltiples WhatsApp (hasta 4)"**
6. **Conecta cada instancia**:
   - Verás 4 tarjetas: "WhatsApp 1", "WhatsApp 2", "WhatsApp 3", "WhatsApp 4"
   - Haz clic en **"🔗 Conectar"** en cada tarjeta
   - Se generará un código QR para cada instancia
   - Escanea cada QR con WhatsApp desde tu teléfono

## 📱 Paso 3: Escanear los Códigos QR

1. **Abre WhatsApp** en tu teléfono
2. **Ve a Configuración** → **Dispositivos vinculados** → **Vincular un dispositivo**
3. **Escanear el QR** que aparece en el modal para la Instancia 1
4. **Repite el proceso** para las otras 3 instancias (cada una tiene su propio QR)

## ✅ Verificación

Después de conectar, cada tarjeta mostrará:
- ✅ **Estado**: "Conectado" (en verde)
- 📱 **Número**: El número de teléfono conectado
- 👤 **Usuario**: El nombre del usuario
- 🕐 **Última actividad**: Cuándo fue la última conexión

## 🔄 Si Necesitas Reiniciar una Conexión

1. Haz clic en **"🔌 Desconectar"** en la tarjeta correspondiente
2. Espera unos segundos
3. Haz clic en **"🔗 Conectar"** nuevamente
4. Se generará un nuevo QR para escanear

## ⚠️ Notas Importantes

1. **Cada servicio debe estar corriendo**: Verifica que todos los servicios estén en **verde (Running)** en EasyPanel
2. **Puertos únicos**: Cada servicio debe tener un puerto diferente (3001, 3002, 3003, 3004)
3. **INSTANCE_NUMBER es crítico**: Esta variable le dice a cada servicio qué instancia es
4. **Un QR por instancia**: Cada número de WhatsApp necesita escanear su propio QR
5. **Flor IA funciona en todas**: Una vez conectadas, todas las instancias usarán Flor IA para responder automáticamente

## 🆘 Solución de Problemas

### Si un servicio no se conecta:
1. Verifica que el servicio esté **Running** en EasyPanel
2. Verifica que el puerto esté correcto (3001, 3002, 3003, 3004)
3. Verifica que `INSTANCE_NUMBER` y `PORT` estén configurados correctamente
4. Revisa los logs del servicio en EasyPanel

### Si el QR no aparece:
1. Elimina la carpeta `.wwebjs_auth` desde el File Manager de EasyPanel para ese servicio
2. Reinicia el servicio
3. Intenta conectar nuevamente desde el dashboard

### Si aparece "Error: Servidor no responde":
1. Verifica que el servicio esté corriendo en EasyPanel
2. Verifica que el puerto esté abierto y accesible
3. Verifica la URL del servidor en el dashboard (debe ser `http://72.61.58.240`)

## 📝 Checklist

- [ ] Servicio `whatsapp` configurado con INSTANCE_NUMBER=1 y PORT=3001
- [ ] Servicio `whatsapp2` configurado con INSTANCE_NUMBER=2 y PORT=3002
- [ ] Servicio `whatsapp3` configurado con INSTANCE_NUMBER=3 y PORT=3003
- [ ] Servicio `whatsapp4` configurado con INSTANCE_NUMBER=4 y PORT=3004
- [ ] Todos los servicios en verde (Running) en EasyPanel
- [ ] URL del servidor configurada en el dashboard: `http://72.61.58.240`
- [ ] Modal de WhatsApp abierto desde el dashboard
- [ ] Cada instancia conectada y QR escaneado

## 🎉 ¡Listo!

Una vez que todos los servicios estén conectados:
- ✅ Cada número de WhatsApp funcionará independientemente
- ✅ Flor IA responderá automáticamente en todas las instancias
- ✅ Los chats se guardarán en Supabase
- ✅ Podrás ver el estado de cada conexión desde el dashboard

