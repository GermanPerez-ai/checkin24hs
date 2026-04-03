# 🔧 Configurar Variables de Entorno para WhatsApp en EasyPanel

## Problema Actual

Los logs muestran estos errores:
- ❌ `Invalid API key` (Supabase)
- ❌ `Request failed with status code 404` (Gemini)

Esto significa que las variables de entorno no están configuradas en EasyPanel.

## Variables Requeridas

Ve a **EasyPanel** → **Servicio `whatsapp`** → **Pestaña "Variables"** o **"Environment"** y agrega:

### 1. Variables de Supabase

```
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

**Nota:** Si tienes una clave diferente en tu archivo `.env`, usa esa.

### 2. Variable de Gemini (Flor IA)

```
GEMINI_API_KEY=TU_CLAVE_DE_GEMINI_AQUI
```

**Nota:** Reemplaza `TU_CLAVE_DE_GEMINI_AQUI` con tu clave real de Gemini API.

### 3. Variables Opcionales (ya configuradas)

Estas ya están configuradas en el código o en el servicio:
- `PORT=3001` (ya configurado)
- `INSTANCE_NUMBER=1` (ya configurado)
- `BASE_URL=https://whatsapp.checkin24hs.com` (ya configurado)

## Pasos en EasyPanel

1. Ve al servicio `whatsapp` en EasyPanel
2. Abre la pestaña **"Variables"** o **"Entorno"** o **"Environment"**
3. Haz clic en **"Agregar Variable"** o **"Add Variable"**
4. Agrega cada variable:
   - **Nombre:** `SUPABASE_URL`
   - **Valor:** `https://lmoeuyasuvoqhtvhkyia.supabase.co`
   - Repite para `SUPABASE_ANON_KEY` y `GEMINI_API_KEY`
5. **Guarda** los cambios
6. **Reinicia el servicio** o haz un **redeploy**

## Verificar que Funcionó

Después de configurar las variables y reiniciar, verifica en los logs:

```bash
docker service logs checkin24hs_whatsapp --tail 50
```

Deberías ver:
- ✅ Sin errores de "Invalid API key"
- ✅ Sin errores 404 de Gemini
- ✅ Mensajes guardándose en Supabase
- ✅ Flor respondiendo a mensajes

## Si el Estado No se Actualiza en la Página

Si WhatsApp está conectado (según los logs) pero la página no muestra "Conectado":

1. **Refresca la página** (`https://whatsapp.checkin24hs.com/status`)
2. **Espera 30 segundos** (la página se auto-refresca cada 30 segundos)
3. Si sigue sin actualizar, verifica que el endpoint `/api/status` devuelva el estado correcto:
   ```bash
   curl https://whatsapp.checkin24hs.com/api/status
   ```

Deberías ver `"connected": true` y `"whatsapp": "connected"` si está conectado.
