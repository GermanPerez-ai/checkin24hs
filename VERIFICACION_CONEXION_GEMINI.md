# 🔍 Verificación: Conexión de Gemini

## 📋 Resumen de Conexión

Gemini se conecta a la **API de Google Generative Language** usando una API Key.

---

## 🌐 URL de la API

**Endpoint principal:**
```
https://generativelanguage.googleapis.com/v1beta/models/{MODELO}:generateContent?key={API_KEY}
```

**Endpoint para listar modelos:**
```
https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}
```

---

## 🔑 Configuración de la API Key

### Variable de Entorno

La API Key se configura mediante la variable de entorno:
- **Nombre:** `GEMINI_API_KEY`
- **Formato:** `AIzaSy...` (empieza con `AIza`)
- **Origen:** Google AI Studio (https://aistudio.google.com/)

### Modelo por Defecto

- **Variable:** `GEMINI_MODEL`
- **Valor por defecto:** `gemini-2.5-flash`
- **Modelos alternativos:** `gemini-2.0-flash`, `gemini-1.5-flash`

---

## 📍 Dónde se Usa Gemini

### 1. Servidor WhatsApp (`whatsapp-server/whatsapp-server-baileys.js`)

**Línea 583:**
```javascript
`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${CONFIG.GEMINI_API_KEY}`
```

**Configuración:**
- Lee `GEMINI_API_KEY` desde `process.env.GEMINI_API_KEY`
- Modelo: `gemini-2.5-flash` (por defecto)
- Usado para: Responder mensajes de WhatsApp con Flor IA

**Variables de entorno necesarias:**
- `GEMINI_API_KEY` - API Key de Gemini
- `GEMINI_MODEL` - Modelo a usar (opcional, default: `gemini-2.5-flash`)

---

### 2. Servidor Dashboard (`server.js`)

**Línea 504:**
```javascript
`https://generativelanguage.googleapis.com/v1beta/models/${modelToUse}:generateContent?key=${GEMINI_API_KEY}`
```

**Endpoints:**
- `POST /api/gemini/generate` - Generar contenido
- `GET /api/gemini/models` - Listar modelos disponibles
- `POST /api/gemini/test` - Probar conexión

**Configuración:**
- Lee `GEMINI_API_KEY` desde `process.env.GEMINI_API_KEY`
- Modelo: `gemini-2.5-flash` (por defecto)
- Usado para: Pruebas y generación desde el dashboard

---

### 3. Dashboard Frontend (`dashboard.html`)

**Línea 22806:**
```javascript
`https://generativelanguage.googleapis.com/v1beta/models/${modelToUse}:generateContent?key=${apiKey}`
```

**Uso:**
- Prueba de conexión desde la interfaz
- La API Key se obtiene del campo de configuración en Flor IA → IA

**Nota:** El dashboard puede usar la API Key configurada en la interfaz O llamar al endpoint del servidor (`/api/gemini/test`)

---

### 4. CRM (`crm/flor-ai-service.js`)

**Línea 630:**
```javascript
`https://generativelanguage.googleapis.com/v1beta/models/${cleanModel}:generateContent?key=${this.config.apiKey}`
```

**Uso:**
- Respuestas de Flor IA desde el CRM
- La API Key se configura en la interfaz del CRM

---

## 🔍 Dónde Está Configurada la API Key

### En EasyPanel (Servicios)

El servicio de WhatsApp necesita la variable `GEMINI_API_KEY` en sus variables de entorno:

1. **Servicio WhatsApp:** `checkin24hs_whatsapp` (puerto 3001)

**Configuración en EasyPanel:**
- Ve al servicio → Pestaña "Entorno" o "Environment"
- Agrega variable: `GEMINI_API_KEY=tu_clave_aqui`
- Agrega variable: `GEMINI_MODEL=gemini-2.5-flash` (opcional)

---

### En el Dashboard (Interfaz)

La API Key también se puede configurar desde la interfaz:

1. Ve a: `https://dashboard.checkin24hs.com`
2. Flor IA → Pestaña "🤖 IA"
3. Campo "API Key" → Pega tu clave de Gemini
4. Guarda la configuración

**Nota:** Esta configuración se guarda en Supabase (`flor_general_config`) y puede ser usada por el servidor WhatsApp.

---

## ✅ Verificación de Conexión

### Verificar desde el Servidor

```bash
# Verificar que la variable está configurada
docker service inspect checkin24hs_whatsapp --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | grep GEMINI

# Ver logs del servicio para verificar conexión
docker service logs checkin24hs_whatsapp --tail 50 | grep -i gemini
```

### Verificar desde el Dashboard

1. Ve a: `https://dashboard.checkin24hs.com`
2. Flor IA → Pestaña "🤖 IA"
3. Haz clic en "Probar Conexión"
4. Debe mostrar: "✅ ¡Conexión exitosa!"

---

## 🔒 Seguridad

### ✅ Buenas Prácticas Implementadas

1. **API Key en Backend:** La API Key se lee desde variables de entorno, NO está hardcodeada
2. **Endpoints Protegidos:** El dashboard usa endpoints del servidor (`/api/gemini/*`) en lugar de llamar directamente
3. **No Exposición:** La API Key no se expone en el código fuente

### ⚠️ Verificaciones Necesarias

1. **Verificar que NO está en el código:**
   ```bash
   # Buscar API keys hardcodeadas (no debería encontrar nada)
   grep -r "AIzaSy" --include="*.js" --include="*.html" | grep -v ".md" | grep -v "backups"
   ```

2. **Verificar que está en variables de entorno:**
   - En EasyPanel, verifica que `GEMINI_API_KEY` esté configurada
   - NO debe estar en archivos `.env` subidos a GitHub

---

## 📊 Resumen de Conexiones

| Servicio | Archivo | Endpoint | API Key Source |
|----------|---------|----------|----------------|
| WhatsApp Server | `whatsapp-server/whatsapp-server-baileys.js` | `generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` | `process.env.GEMINI_API_KEY` |
| Dashboard Server | `server.js` | `generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` | `process.env.GEMINI_API_KEY` |
| Dashboard Frontend | `dashboard.html` | `generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` | Campo de configuración UI |
| CRM | `crm/flor-ai-service.js` | `generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` | Campo de configuración UI |

---

## 🔍 Comandos para Verificar

### Verificar API Key en Servicios

```bash
# Verificar en el servicio WhatsApp
docker service inspect checkin24hs_whatsapp --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | grep GEMINI
```

### Verificar Logs de Conexión

```bash
# Ver logs de conexión a Gemini
docker service logs checkin24hs_whatsapp --tail 100 | grep -iE "gemini|api.*key|429|403|400"
```

---

## ✅ Conclusión

**Gemini se conecta a:**
- **URL:** `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
- **Método:** POST
- **Autenticación:** API Key en query parameter (`?key={API_KEY}`)
- **API Key:** Se obtiene de `process.env.GEMINI_API_KEY` o desde configuración en UI

**Servicios que usan Gemini:**
1. ✅ Servidor WhatsApp (Flor IA para responder mensajes)
2. ✅ Dashboard (pruebas y generación)
3. ✅ CRM (respuestas de Flor IA)
