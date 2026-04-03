# 🔗 Configurar URL Base para WhatsApp Server

## 📋 Descripción

Ahora el servidor de WhatsApp soporta configurar una URL base explícita, lo que mejora:
- ✅ Logging más claro
- ✅ Referencias a endpoints más precisas
- ✅ Configuración más flexible

## ⚙️ Configuración

### Opción 1: Variable de Entorno `BASE_URL` (Recomendado)

En EasyPanel, agrega esta variable de entorno:

```bash
BASE_URL=https://api1.checkin24hs.com
```

### Opción 2: Variable de Entorno `SERVER_URL` (Alternativa)

También puedes usar:

```bash
SERVER_URL=https://api1.checkin24hs.com
```

### Opción 3: Auto-detección

Si no configuras ninguna URL, el servidor construirá automáticamente:
- `http://0.0.0.0:3001` (por defecto)
- O usa `HOST` y `PROTOCOL` si están configurados

## 📝 Ejemplo de Configuración en EasyPanel

Ve a **Servicios** → **whatsapp** → **Entorno** y agrega:

```bash
PORT=3001
INSTANCE_NUMBER=1
BASE_URL=https://api1.checkin24hs.com
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=tu_key_aqui
GEMINI_API_KEY=tu_key_aqui
```

## ✅ Beneficios

1. **Logging mejorado**: Los logs mostrarán la URL base configurada
2. **Endpoints claros**: Se mostrarán las URLs completas de los endpoints
3. **Configuración flexible**: Fácil de cambiar según el entorno

## 🔍 Verificación

Después de configurar, los logs mostrarán:

```
✅ Servidor iniciado en puerto 3001
📱 Instancia WhatsApp: 1
🌐 Servidor escuchando en 0.0.0.0:3001 (accesible desde cualquier interfaz)
🔗 URL base configurada: https://api1.checkin24hs.com
📋 Endpoints disponibles:
   - GET  https://api1.checkin24hs.com/api/health
   - GET  https://api1.checkin24hs.com/api/status
   - GET  https://api1.checkin24hs.com/api/qr
```

## 💡 Nota

La URL base es solo para **logging y referencias**. El servidor siempre escucha en `0.0.0.0:PORT` para ser accesible desde Traefik y otros servicios.
