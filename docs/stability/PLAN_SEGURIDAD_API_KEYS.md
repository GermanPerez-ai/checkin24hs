# 🔐 Plan: Seguridad de Claves de API - Mover al Backend

## 📊 Auditoría: Claves de API Expuestas

### 🔴 Problemas Encontrados:

#### 1. **Gemini API** - ⚠️ PARCIALMENTE SEGURO
- ✅ **Backend:** Ya tiene endpoints (`/api/gemini/generate`, `/api/gemini/test`)
- ✅ **Frontend:** Ya usa `/api/gemini/test` para pruebas
- ⚠️ **Problema:** `flor-ai-service.js` usa la API key directamente (si se carga en frontend)

#### 2. **OpenAI API** - ❌ EXPUESTO
- ❌ **Problema:** Llamadas directas desde frontend (línea 24358)
- ❌ Usa `apiKey` del frontend directamente
- ✅ **Solución:** Crear endpoint `/api/openai/generate` en backend

#### 3. **Anthropic (Claude) API** - ❌ EXPUESTO
- ❌ **Problema:** Llamadas directas desde frontend (línea 24372)
- ❌ Usa `apiKey` del frontend directamente
- ✅ **Solución:** Crear endpoint `/api/claude/generate` en backend

#### 4. **Supabase ANON_KEY** - ✅ SEGURO (por diseño)
- ✅ Supabase está diseñado para usar la clave anon en el cliente
- ✅ La clave anon tiene permisos limitados (RLS)
- ⚠️ **Verificar:** Que no esté hardcodeada en el código

---

## 🎯 Plan de Acción

### Paso 1: Crear Endpoints en Backend (server.js)

#### 1.1 Endpoint para OpenAI

```javascript
// Endpoint para generar contenido con OpenAI
app.post('/api/openai/generate', async (req, res) => {
    try {
        const { prompt, model, maxTokens } = req.body;
        
        const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
        
        if (!OPENAI_API_KEY) {
            return res.status(500).json({ 
                error: 'OPENAI_API_KEY no configurada en el servidor' 
            });
        }
        
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${OPENAI_API_KEY}`
            },
            body: JSON.stringify({
                model: model || 'gpt-4o-mini',
                messages: [{ role: 'user', content: prompt }],
                max_tokens: maxTokens || 500
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            return res.status(response.status).json({ 
                error: data.error?.message || 'Error llamando a OpenAI' 
            });
        }
        
        res.json(data);
    } catch (error) {
        console.error('❌ Error llamando a OpenAI:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para probar OpenAI
app.post('/api/openai/test', async (req, res) => {
    try {
        const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
        
        if (!OPENAI_API_KEY) {
            return res.status(500).json({ 
                error: 'OPENAI_API_KEY no configurada',
                configured: false
            });
        }
        
        // Probar con un mensaje simple
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${OPENAI_API_KEY}`
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
                messages: [{ role: 'user', content: 'Responde solo con: OK' }],
                max_tokens: 10
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            return res.status(400).json({ 
                error: data.error?.message || 'Error en OpenAI',
                configured: true,
                valid: false
            });
        }
        
        res.json({ 
            success: true,
            configured: true,
            valid: true,
            model: 'gpt-4o-mini'
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

#### 1.2 Endpoint para Anthropic (Claude)

```javascript
// Endpoint para generar contenido con Claude
app.post('/api/claude/generate', async (req, res) => {
    try {
        const { prompt, model, maxTokens } = req.body;
        
        const CLAUDE_API_KEY = process.env.CLAUDE_API_KEY || process.env.ANTHROPIC_API_KEY || '';
        
        if (!CLAUDE_API_KEY) {
            return res.status(500).json({ 
                error: 'CLAUDE_API_KEY no configurada en el servidor' 
            });
        }
        
        const response = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': CLAUDE_API_KEY,
                'anthropic-version': '2023-06-01'
            },
            body: JSON.stringify({
                model: model || 'claude-3-haiku-20240307',
                max_tokens: maxTokens || 500,
                messages: [{ role: 'user', content: prompt }]
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            return res.status(response.status).json({ 
                error: data.error?.message || 'Error llamando a Claude' 
            });
        }
        
        res.json(data);
    } catch (error) {
        console.error('❌ Error llamando a Claude:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para probar Claude
app.post('/api/claude/test', async (req, res) => {
    try {
        const CLAUDE_API_KEY = process.env.CLAUDE_API_KEY || process.env.ANTHROPIC_API_KEY || '';
        
        if (!CLAUDE_API_KEY) {
            return res.status(500).json({ 
                error: 'CLAUDE_API_KEY no configurada',
                configured: false
            });
        }
        
        // Probar con un mensaje simple
        const response = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': CLAUDE_API_KEY,
                'anthropic-version': '2023-06-01'
            },
            body: JSON.stringify({
                model: 'claude-3-haiku-20240307',
                max_tokens: 10,
                messages: [{ role: 'user', content: 'Responde solo con: OK' }]
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            return res.status(400).json({ 
                error: data.error?.message || 'Error en Claude',
                configured: true,
                valid: false
            });
        }
        
        res.json({ 
            success: true,
            configured: true,
            valid: true,
            model: 'claude-3-haiku-20240307'
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

### Paso 2: Modificar Frontend (dashboard.html)

#### 2.1 Actualizar función `testAIConfig()`

**ANTES:**
```javascript
} else if (provider === 'openai') {
    response = await fetch('https://api.openai.com/v1/chat/completions', {
        headers: {
            'Authorization': `Bearer ${apiKey}` // ❌ API key expuesta
        },
        ...
    });
}
```

**DESPUÉS:**
```javascript
} else if (provider === 'openai') {
    // Usar endpoint seguro del servidor
    const response = await fetch('/api/openai/test', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    });
    
    const data = await response.json();
    // ... manejar respuesta
}
```

---

### Paso 3: Actualizar función `sendMessageToFlor()` (si existe)

Si hay una función que envía mensajes a Flor IA directamente desde el frontend, debe usar el endpoint del backend.

**ANTES:**
```javascript
const response = await fetch(`https://generativelanguage.googleapis.com/...?key=${apiKey}`, ...);
```

**DESPUÉS:**
```javascript
const response = await fetch('/api/gemini/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt, model, maxTokens })
});
```

---

### Paso 4: Verificar `flor-ai-service.js`

Si `flor-ai-service.js` se carga en el frontend, debe modificarse para usar el backend en lugar de la API key directamente.

---

## 📋 Checklist de Implementación

- [ ] Crear endpoint `/api/openai/generate` en server.js
- [ ] Crear endpoint `/api/openai/test` en server.js
- [ ] Crear endpoint `/api/claude/generate` en server.js
- [ ] Crear endpoint `/api/claude/test` en server.js
- [ ] Actualizar `testAIConfig()` en dashboard.html para usar endpoints del backend
- [ ] Buscar y actualizar todas las llamadas directas a OpenAI
- [ ] Buscar y actualizar todas las llamadas directas a Anthropic
- [ ] Verificar que `flor-ai-service.js` use el backend (si se carga en frontend)
- [ ] Verificar que no haya claves hardcodeadas en el código
- [ ] Actualizar documentación sobre variables de entorno requeridas

---

## 🔒 Variables de Entorno Requeridas

Agregar al archivo `.env` del servidor:

```env
# Gemini API (ya existe)
GEMINI_API_KEY=tu_clave_aqui

# OpenAI API (nueva)
OPENAI_API_KEY=tu_clave_aqui

# Anthropic/Claude API (nueva)
CLAUDE_API_KEY=tu_clave_aqui
# O
ANTHROPIC_API_KEY=tu_clave_aqui
```

---

## ✅ Beneficios

1. **Seguridad:** Las claves nunca se exponen al cliente
2. **Control:** El servidor controla el uso de las APIs
3. **Rate Limiting:** Puedes implementar límites de uso
4. **Logging:** Puedes registrar todas las llamadas a APIs
5. **Monitoreo:** Puedes monitorear el uso de las APIs

---

**¿Empezamos con la implementación?**
