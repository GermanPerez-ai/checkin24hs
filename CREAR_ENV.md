# 📝 Instrucciones para Crear el Archivo .env

## ⚠️ IMPORTANTE: Sigue estos pasos exactamente

### PASO 1: Crear el archivo `.env`

El archivo `.env` debe crearse en la **raíz del proyecto** (misma carpeta donde está `server.js`).

### PASO 2: Contenido del archivo

Copia este contenido exacto (reemplaza `tu_api_key_de_gemini_aquí` con tu API Key real):

```env
GEMINI_API_KEY=tu_api_key_de_gemini_aquí
GEMINI_MODEL=gemini-2.5-flash
```

**Ejemplo con una API Key real:**
```env
GEMINI_API_KEY=AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567
GEMINI_MODEL=gemini-2.5-flash
```

### PASO 3: Nombre del archivo

- ✅ **Correcto:** `.env` (con punto al inicio)
- ❌ **Incorrecto:** `.env.txt`
- ❌ **Incorrecto:** `env`
- ❌ **Incorrecto:** `.env.txt.bak`

### PASO 4: Ubicación

El archivo debe estar en:
```
C:\Users\German\Downloads\Checkin24hs\.env
```

(Misma carpeta donde están `server.js` y `dashboard.html`)

---

## 💡 Cómo crear el archivo en diferentes editores

### VS Code
1. Presiona `Ctrl+N` (nuevo archivo)
2. Pega el contenido
3. Presiona `Ctrl+S` (guardar)
4. En el nombre del archivo, escribe: `.env`
5. Guarda

### Notepad
1. Abre Notepad
2. Pega el contenido
3. Ve a "Guardar como..."
4. En "Tipo de archivo" selecciona "Todos los archivos (*.*)"
5. En el nombre escribe: `.env` (con el punto al inicio)
6. Guarda en `C:\Users\German\Downloads\Checkin24hs\`

### Notepad++
1. Abre Notepad++
2. Pega el contenido
3. Ve a "Archivo" → "Guardar como..."
4. En "Tipo" selecciona "Todos los tipos"
5. En el nombre escribe: `.env`
6. Guarda en la carpeta del proyecto

---

## ✅ Verificación

Después de crear el archivo:

1. **Verifica que existe:**
   - Debe estar en la misma carpeta que `server.js`
   - Debe llamarse exactamente `.env` (puede que esté oculto en el explorador)

2. **Verifica el contenido:**
   - Debe tener exactamente 2 líneas
   - La primera: `GEMINI_API_KEY=tu_clave_aquí` (sin espacios alrededor del `=`)
   - La segunda: `GEMINI_MODEL=gemini-2.5-flash`

3. **Prueba el servidor:**
   ```bash
   node server.js
   ```
   Deberías ver: `🔑 GEMINI_API_KEY: ✅ Configurada`

---

## 🔒 Seguridad

- ⚠️ **NO subas el archivo `.env` a GitHub** (ya está en `.gitignore`)
- ⚠️ **NO compartas tu API Key**
- ⚠️ **NO la pegues en chats o emails**

---

## 📋 Checklist

- [ ] Archivo `.env` creado en la raíz del proyecto
- [ ] Contiene `GEMINI_API_KEY=tu_clave_real`
- [ ] Contiene `GEMINI_MODEL=gemini-2.5-flash`
- [ ] No tiene extensión `.txt`
- [ ] Probado que el servidor lo lee correctamente
