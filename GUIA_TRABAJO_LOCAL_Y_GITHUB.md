# 🔧 Guía: Trabajar Localmente y Subir a GitHub

## 📋 PASO A PASO

### **PASO 1: Preparar el entorno local**

#### 1.1 Verificar que tienes Node.js instalado

```bash
node --version
npm --version
```

#### 1.2 Instalar dependencias (si no lo has hecho)

```bash
cd C:\Users\German\Downloads\Checkin24hs
npm install dotenv express cors
```

#### 1.3 Crear archivo `.env` local

Crea un archivo `.env` en la raíz del proyecto con tus claves:

```env
# API Keys (SOLO PARA DESARROLLO LOCAL - NO SUBIR A GITHUB)
GEMINI_API_KEY=tu_api_key_aquí
GEMINI_MODEL=gemini-2.5-flash

# Supabase
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=tu_clave_anon_aquí
```

⚠️ **IMPORTANTE:** Este archivo `.env` NO se subirá a GitHub (está en `.gitignore`).

---

### **PASO 2: Modificar `server.js` para agregar endpoints**

Agrega estas líneas al inicio de `server.js` (después de `const app = express();`):

```javascript
// Cargar variables de entorno (AGREGAR ESTO)
require('dotenv').config();
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
```

Luego, agrega estos endpoints ANTES de la línea `app.use(express.static(...))`:

```javascript
// ============================================
// ENDPOINTS PARA GEMINI API (SEGUROS)
// ============================================

// Endpoint para generar contenido con Gemini
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
        console.error('❌ Error llamando a Gemini:', error);
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
        console.error('❌ Error listando modelos:', error);
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

### **PASO 3: Modificar `dashboard.html`**

#### 3.1 Buscar y modificar la función `testAIConfig`

Busca esta función (alrededor de la línea 23596) y cámbiala para usar el backend:

**ANTES:**
```javascript
window.testAIConfig = async function() {
    const provider = document.getElementById('ai-provider')?.value || 'gemini';
    const apiKey = document.getElementById('ai-api-key')?.value || '';
    // ... código que usa apiKey directamente ...
```

**DESPUÉS:**
```javascript
window.testAIConfig = async function() {
    const provider = document.getElementById('ai-provider')?.value || 'gemini';
    
    // Ya no necesitamos apiKey del frontend - el servidor la tiene
    alert('🔄 Probando conexión con Gemini a través del servidor...');
    
    try {
        const response = await fetch('/api/gemini/test', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('✅ ¡Conexión exitosa!\n\nLa API Key está configurada correctamente en el servidor.\n\nModelo: ' + data.model);
        } else if (data.configured === false) {
            alert('❌ Error: La API Key no está configurada en el servidor.\n\nPor favor, configura GEMINI_API_KEY en el archivo .env del servidor.');
        } else {
            alert('❌ Error: ' + data.error);
        }
    } catch (error) {
        alert('❌ Error de conexión: ' + error.message + '\n\nAsegúrate de que el servidor esté corriendo (node server.js)');
    }
};
```

#### 3.2 Modificar `saveAIConfig` para no guardar API Key

Busca la función `saveAIConfig` (alrededor de la línea 23557) y modifica para que NO guarde la API Key:

**ANTES:**
```javascript
const config = {
    apiKey: document.getElementById('ai-api-key')?.value || '',
    // ...
};
```

**DESPUÉS:**
```javascript
const config = {
    // apiKey: document.getElementById('ai-api-key')?.value || '', // Ya no se guarda - está en el servidor
    // ...
};
```

#### 3.3 Ocultar o cambiar el campo de API Key en el HTML

Busca el campo de API Key (alrededor de la línea 3607) y cámbialo:

**ANTES:**
```html
<input type="password" id="ai-api-key" style="..." placeholder="Tu API key...">
```

**DESPUÉS:**
```html
<!-- Campo oculto o mensaje informativo -->
<div id="ai-api-key-info" style="padding: 12px; background: #e3f2fd; border-radius: 8px; color: #1976d2; margin-bottom: 8px;">
    ✅ La API Key está configurada de forma segura en el servidor
    <br><small style="color: #666;">Configurada en: <code>.env</code> del servidor</small>
</div>
<input type="hidden" id="ai-api-key" value="">
```

#### 3.4 Modificar otras funciones que usan Gemini directamente

Busca todas las llamadas directas a `https://generativelanguage.googleapis.com` y cámbialas para usar `/api/gemini/generate`.

---

### **PASO 4: Probar localmente**

#### 4.1 Iniciar el servidor

Abre una terminal en `C:\Users\German\Downloads\Checkin24hs` y ejecuta:

```bash
node server.js
```

Deberías ver:
```
✅ Servidor escuchando en puerto 3000
🔑 GEMINI_API_KEY: ✅ Configurada
```

#### 4.2 Abrir el dashboard en el navegador

Abre tu navegador y ve a:
```
http://localhost:3000
```

#### 4.3 Probar la funcionalidad

1. Ve a la sección **"Flor IA"**
2. Haz clic en **"Probar Conexión"**
3. Debería funcionar sin necesidad de ingresar la API Key

---

### **PASO 5: Verificar `.gitignore`**

Asegúrate de que `.gitignore` incluya:

```
.env
.env.local
*.env
node_modules/
```

Esto previene que las claves se suban a GitHub.

---

### **PASO 6: Subir cambios a GitHub**

#### 6.1 Verificar qué archivos se van a subir

```bash
git status
```

**Debes ver:**
- ✅ `dashboard.html` (modificado)
- ✅ `server.js` (modificado)
- ❌ `.env` (NO debe aparecer - está ignorado)

#### 6.2 Agregar archivos al staging

```bash
git add dashboard.html server.js
```

#### 6.3 Hacer commit

```bash
git commit -m "Mover API Keys al backend - Seguridad mejorada"
```

#### 6.4 Subir a GitHub

```bash
git push origin main
```

(O `git push origin master` si tu rama se llama `master`)

---

### **PASO 7: Configurar `.env` en el servidor de producción**

⚠️ **IMPORTANTE:** Cuando subas el código al servidor de producción, necesitarás:

1. **Crear el archivo `.env` en el servidor** (no se sube automáticamente)
2. **Agregar las mismas variables de entorno** que en local
3. **Reiniciar el servidor** para que cargue las nuevas variables

**Ejemplo en el servidor:**
```bash
# Conectarte al servidor vía SSH
ssh usuario@tu-servidor.com

# Ir al directorio del proyecto
cd /ruta/al/proyecto

# Crear archivo .env
nano .env

# Pegar las variables (igual que en local)
GEMINI_API_KEY=tu_api_key_produccion
GEMINI_MODEL=gemini-2.5-flash
...

# Guardar y salir (Ctrl+X, luego Y, luego Enter)

# Reiniciar el servidor
pm2 restart server.js
# O si usas otro método:
node server.js
```

---

## ✅ CHECKLIST ANTES DE SUBIR

- [ ] Modificaste `server.js` para agregar los endpoints `/api/gemini/*`
- [ ] Modificaste `dashboard.html` para usar `/api/gemini/*` en lugar de llamadas directas
- [ ] Ocultaste/eliminaste el campo de API Key del frontend
- [ ] Creaste archivo `.env` local (NO se sube a GitHub)
- [ ] Verificaste que `.gitignore` incluye `.env`
- [ ] Probaste localmente y funciona (`http://localhost:3000`)
- [ ] Verificaste `git status` y NO aparece `.env`
- [ ] Hiciste commit y push a GitHub

---

## 🔍 COMANDOS ÚTILES

```bash
# Ver qué archivos cambiaron
git status

# Ver diferencias en un archivo
git diff dashboard.html

# Verificar que .env está ignorado
git status --ignored

# Revertir cambios (si algo sale mal)
git checkout -- dashboard.html
```

---

## ❓ PREGUNTAS FRECUENTES

**P: ¿Puedo seguir trabajando en `file:///` sin servidor?**
R: No, porque las llamadas a `/api/gemini/*` requieren un servidor. Debes usar `http://localhost:3000` después de iniciar `node server.js`.

**P: ¿Cómo sé si mi `.env` está ignorado?**
R: Ejecuta `git status --ignored`. Si aparece `.env` en la lista de ignorados, está bien.

**P: ¿Qué pasa si olvido agregar `.env` al `.gitignore`?**
R: Si haces `git add .env` por error, las claves se subirán a GitHub. **BORRA** ese commit inmediatamente y agrega `.env` al `.gitignore`.

**P: ¿Cómo actualizo el `.env` en producción?**
R: Conecta al servidor vía SSH, edita el archivo `.env`, guarda, y reinicia el servidor.

---

## 📝 RESUMEN

1. ✅ Modifica `server.js` - Agrega endpoints `/api/gemini/*`
2. ✅ Modifica `dashboard.html` - Usa los endpoints en lugar de llamadas directas
3. ✅ Crea `.env` local - NO lo subas a GitHub
4. ✅ Prueba localmente - `node server.js` → `http://localhost:3000`
5. ✅ Sube a GitHub - `git add`, `git commit`, `git push`
6. ✅ Configura `.env` en producción - Cópialo al servidor manualmente

**¡Listo! Las claves están seguras y nunca se exponen al navegador.** 🔒
