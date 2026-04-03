# 🔒 Guía: Mover Claves de API al Backend

## ❓ ¿Para qué sirve?

### **Problema Actual:**
Las claves de API están expuestas en el código del frontend (dashboard.html), lo que significa:
- ❌ Cualquiera puede ver el código fuente y robar tus claves
- ❌ Cualquiera puede usar tu API Key de Gemini (gastando tu cuota)
- ❌ Riesgo de seguridad alto

### **Solución:**
Mover las claves al backend (servidor) para que:
- ✅ Las claves NUNCA se expongan al navegador
- ✅ Solo tu servidor puede usar las claves
- ✅ Control total sobre quién puede acceder
- ✅ Seguridad mejorada

---

## 📋 PASO 1: Configurar Variables de Entorno en el Backend

### 1.1 Crear archivo `.env` en el servidor

Crea un archivo `.env` en la raíz del proyecto (al mismo nivel que `server.js`):

```env
# API Keys (NUNCA compartir este archivo)
GEMINI_API_KEY=tu_api_key_de_gemini_aquí
GEMINI_MODEL=gemini-2.5-flash

# Supabase (clave pública - OK en frontend, pero mejor en backend)
SUPABASE_URL=https://lmoeuyasuuyqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=tu_clave_anon_de_supabase
```

### 1.2 Instalar dotenv (si no lo tienes)

```bash
npm install dotenv
```

### 1.3 Cargar variables de entorno en server.js

Agrega esto al inicio de `server.js`:

```javascript
require('dotenv').config();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
```

---

## 📋 PASO 2: Crear Endpoints en el Backend

Agrega estos endpoints en `server.js` para que el dashboard los use:

### 2.1 Endpoint para llamar a Gemini

```javascript
// Endpoint para generar contenido con Gemini (proxy seguro)
app.post('/api/gemini/generate', async (req, res) => {
    try {
        const { prompt, model, maxTokens } = req.body;
        
        if (!GEMINI_API_KEY) {
            return res.status(500).json({ 
                error: 'GEMINI_API_KEY no configurada en el servidor' 
            });
        }
        
        const modelToUse = model || GEMINI_MODEL;
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelToUse}:generateContent?key=${GEMINI_API_KEY}`;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: { 
                    maxOutputTokens: maxTokens || 500 
                }
            })
        });
        
        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('Error llamando a Gemini:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para listar modelos disponibles
app.get('/api/gemini/models', async (req, res) => {
    try {
        if (!GEMINI_API_KEY) {
            return res.status(500).json({ 
                error: 'GEMINI_API_KEY no configurada' 
            });
        }
        
        const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}`;
        const response = await fetch(url);
        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('Error listando modelos:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para probar la API Key (sin exponer la clave)
app.post('/api/gemini/test', async (req, res) => {
    try {
        if (!GEMINI_API_KEY) {
            return res.status(500).json({ 
                error: 'GEMINI_API_KEY no configurada',
                configured: false
            });
        }
        
        // Probar con un mensaje simple
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: 'Responde solo con: OK' }] }],
                generationConfig: { maxOutputTokens: 10 }
            })
        });
        
        const data = await response.json();
        
        if (data.error) {
            return res.status(400).json({ 
                error: data.error.message,
                configured: true,
                valid: false
            });
        }
        
        res.json({ 
            success: true,
            configured: true,
            valid: true,
            model: GEMINI_MODEL
        });
    } catch (error) {
        res.status(500).json({ 
            error: error.message,
            configured: true,
            valid: false
        });
    }
});
```

---

## 📋 PASO 3: Modificar el Dashboard para Usar el Backend

### 3.1 Cambiar las llamadas directas a Gemini

**ANTES (código inseguro):**
```javascript
const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
const response = await fetch(geminiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({...})
});
```

**DESPUÉS (código seguro):**
```javascript
// Llamar a tu backend en lugar de directamente a Gemini
const response = await fetch('/api/gemini/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        prompt: tuPrompt,
        model: modeloSeleccionado,
        maxTokens: 500
    })
});
```

### 3.2 Modificar función de prueba de conexión

En `dashboard.html`, busca la función `testAIConfig` y cámbiala para usar el backend:

```javascript
window.testAIConfig = async function() {
    // Ya no necesitas que el usuario ingrese la API Key
    // El servidor la tiene configurada
    
    alert('🔄 Probando conexión con Gemini a través del servidor...');
    
    try {
        const response = await fetch('/api/gemini/test', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('✅ ¡Conexión exitosa!\n\nLa API Key está configurada correctamente en el servidor.');
        } else {
            alert('❌ Error: ' + data.error);
        }
    } catch (error) {
        alert('❌ Error de conexión: ' + error.message);
    }
};
```

---

## 📋 PASO 4: Eliminar Campos de API Key del Frontend

### 4.1 Ocultar o eliminar el campo de API Key

En `dashboard.html`, puedes:
- **Opción 1:** Ocultar el campo (pero mantenerlo en el HTML por si acaso)
- **Opción 2:** Mostrar un mensaje informativo

```html
<!-- ANTES -->
<input type="password" id="ai-api-key" placeholder="Tu API key...">

<!-- DESPUÉS -->
<div style="padding: 12px; background: #e3f2fd; border-radius: 8px; color: #1976d2;">
    ✅ La API Key está configurada de forma segura en el servidor
</div>
```

---

## 📋 PASO 5: Actualizar .gitignore

Asegúrate de que `.gitignore` incluya:

```
.env
.env.local
*.env
```

Esto previene que las claves se suban por error a GitHub.

---

## ✅ VENTAJAS DE ESTE CAMBIO

1. **Seguridad:**
   - Las claves nunca se exponen al navegador
   - Solo el servidor tiene acceso a las claves

2. **Control:**
   - Puedes limitar quién puede usar la API
   - Puedes agregar autenticación al endpoint
   - Puedes registrar todas las llamadas

3. **Flexibilidad:**
   - Puedes cambiar la API Key sin tocar el frontend
   - Puedes usar diferentes claves para diferentes ambientes
   - Puedes agregar rate limiting (límite de uso)

---

## 🔧 EJEMPLO COMPLETO: server.js

```javascript
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();

// Cargar variables de entorno
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

app.use(cors());
app.use(express.json());

// Endpoint seguro para Gemini
app.post('/api/gemini/generate', async (req, res) => {
    try {
        if (!GEMINI_API_KEY) {
            return res.status(500).json({ error: 'API Key no configurada' });
        }
        
        const { prompt, model, maxTokens } = req.body;
        const modelToUse = model || GEMINI_MODEL;
        
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelToUse}:generateContent?key=${GEMINI_API_KEY}`;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: { maxOutputTokens: maxTokens || 500 }
            })
        });
        
        const data = await response.json();
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✅ Servidor escuchando en puerto ${PORT}`);
    console.log(`🔑 GEMINI_API_KEY: ${GEMINI_API_KEY ? '✅ Configurada' : '❌ NO configurada'}`);
});
```

---

## 📝 RESUMEN

1. ✅ Crea archivo `.env` con tus claves
2. ✅ Instala `dotenv` y cárgalo en `server.js`
3. ✅ Crea endpoints `/api/gemini/*` en el backend
4. ✅ Modifica el dashboard para usar esos endpoints
5. ✅ Elimina campos de API Key del frontend
6. ✅ Agrega `.env` al `.gitignore`

**Resultado:** Las claves están seguras en el servidor y nunca se exponen al navegador.
