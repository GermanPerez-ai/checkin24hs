# 📋 Instrucciones: Después de Modificar Localmente

## ✅ Cambios Realizados Localmente

Se han realizado los siguientes cambios en tu código local:

1. ✅ **`server.js`** - Agregado soporte para variables de entorno y endpoints de Gemini API
2. ✅ **`dashboard.html`** - Modificado para usar endpoints del servidor en lugar de llamadas directas

---

## 🔧 PASO 1: Instalar dotenv (si no lo tienes)

Abre una terminal en `C:\Users\German\Downloads\Checkin24hs` y ejecuta:

```bash
npm install dotenv
```

---

## 🔧 PASO 2: Crear archivo `.env` local

Crea un archivo `.env` en la raíz del proyecto (al mismo nivel que `server.js`) con este contenido:

```env
# API Keys (SOLO PARA DESARROLLO LOCAL - NO SUBIR A GITHUB)
GEMINI_API_KEY=tu_api_key_de_gemini_aquí
GEMINI_MODEL=gemini-2.5-flash

# Supabase (opcional - ya están configuradas en supabase-config.js)
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=tu_clave_anon_de_supabase
```

**⚠️ IMPORTANTE:** Reemplaza `tu_api_key_de_gemini_aquí` con tu API Key real de Gemini.

---

## 🔧 PASO 3: Probar Localmente

### 3.1 Iniciar el servidor

```bash
cd C:\Users\German\Downloads\Checkin24hs
node server.js
```

Deberías ver en la consola:
```
🚀 Servidor iniciado en http://0.0.0.0:3000
📊 API disponible en http://0.0.0.0:3000/api/puyehue-quote
🌐 Frontend disponible en http://0.0.0.0:3000
🔑 GEMINI_API_KEY: ✅ Configurada
🤖 Modelo Gemini: gemini-2.5-flash
```

### 3.2 Abrir el dashboard

Abre tu navegador y ve a:
```
http://localhost:3000
```

### 3.3 Probar la funcionalidad

1. Ve a la sección **"Flor IA"**
2. Haz clic en la pestaña **"🤖 IA"**
3. Haz clic en el botón **"Probar Conexión"**
4. Debería funcionar sin necesidad de ingresar la API Key

---

## 📤 PASO 4: Subir Cambios a GitHub

### 4.1 Verificar qué archivos se van a subir

```bash
git status
```

**Debes ver:**
- ✅ `dashboard.html` (modificado)
- ✅ `server.js` (modificado)
- ❌ `.env` (NO debe aparecer - está ignorado)

### 4.2 Agregar archivos al staging

```bash
git add dashboard.html server.js
```

### 4.3 Hacer commit

```bash
git commit -m "Mover API Keys al backend - Seguridad mejorada"
```

### 4.4 Subir a GitHub

```bash
git push origin main
```

(O `git push origin master` si tu rama se llama `master`)

---

## 🖥️ PASO 5: Configurar en el Servidor de Producción

⚠️ **CRÍTICO:** Cuando subas el código al servidor, necesitarás configurar las variables de entorno.

### 5.1 Conectar al servidor

Conéctate al servidor vía SSH (ajusta los datos según tu configuración):

```bash
ssh usuario@tu-servidor.com
```

### 5.2 Ir al directorio del proyecto

```bash
cd /ruta/al/proyecto
```

### 5.3 Instalar dotenv (si no está instalado)

```bash
npm install dotenv
```

### 5.4 Crear archivo `.env` en el servidor

```bash
nano .env
```

Pega este contenido (con tus claves reales):

```env
GEMINI_API_KEY=tu_api_key_de_gemini_produccion
GEMINI_MODEL=gemini-2.5-flash
```

Guarda y salir:
- Presiona `Ctrl + X`
- Presiona `Y` para confirmar
- Presiona `Enter` para salir

### 5.5 Reiniciar el servidor

**Si usas PM2:**
```bash
pm2 restart server.js
```

**Si usas otro método:**
```bash
# Detener el servidor actual (Ctrl+C) y reiniciar
node server.js
```

### 5.6 Verificar que funciona

Abre tu navegador y ve al dashboard en producción. Prueba la funcionalidad de "Probar Conexión" en la sección Flor IA.

---

## ✅ CHECKLIST FINAL

- [ ] Instalé `dotenv` localmente
- [ ] Creé archivo `.env` local con mi API Key
- [ ] Probé localmente (`node server.js` → `http://localhost:3000`)
- [ ] Verifiqué que "Probar Conexión" funciona sin ingresar API Key
- [ ] Verifiqué `git status` y NO aparece `.env`
- [ ] Hice commit y push a GitHub
- [ ] Creé archivo `.env` en el servidor de producción
- [ ] Reinicié el servidor de producción
- [ ] Verifiqué que funciona en producción

---

## ❓ PROBLEMAS COMUNES

### Error: "GEMINI_API_KEY no configurada"
**Solución:** Verifica que el archivo `.env` existe y tiene la variable `GEMINI_API_KEY=tu_clave`

### Error: "Cannot find module 'dotenv'"
**Solución:** Ejecuta `npm install dotenv` en el directorio del proyecto

### Error: "Error de conexión" al probar
**Solución:** 
1. Verifica que el servidor está corriendo (`node server.js`)
2. Verifica que estás accediendo a `http://localhost:3000` (no `file:///`)
3. Verifica que la API Key en `.env` es válida

### El archivo `.env` aparece en `git status`
**Solución:** Verifica que `.gitignore` incluye `.env`. Si no, agrégalo y haz `git rm --cached .env` (sin el flag --cached si quieres eliminarlo completamente del historial, pero cuidado).

---

## 📝 RESUMEN

**Cambios realizados:**
- ✅ `server.js` ahora carga variables de entorno y tiene endpoints `/api/gemini/*`
- ✅ `dashboard.html` ahora usa los endpoints del servidor (no llama directamente a Gemini)
- ✅ Campo de API Key oculto en el frontend (mostrando mensaje informativo)

**Lo que TÚ debes hacer:**
1. Instalar `dotenv`: `npm install dotenv`
2. Crear `.env` local con tu API Key
3. Probar localmente
4. Subir cambios a GitHub (`.env` NO se sube)
5. Crear `.env` en el servidor de producción
6. Reiniciar el servidor

**¡Listo! Las claves están seguras.** 🔒
