# 🔑 Configurar Token de GitHub en EasyPanel

## ⚠️ ¿Necesitas el Token?

**Solo necesitas el token si tu repositorio es PRIVADO.**

Si tu repositorio es **PÚBLICO**, puedes **ignorar el mensaje** y hacer el deploy normalmente.

---

## 🔍 Verificar si el Repositorio es Público o Privado

### Opción 1: Desde GitHub

1. Ve a: `https://github.com/GermanPerez-ai/checkin24hs`
2. Si puedes ver el código **sin iniciar sesión** → Es **PÚBLICO** ✅
3. Si te pide iniciar sesión → Es **PRIVADO** 🔒

### Opción 2: Desde el Navegador en Modo Incógnito

1. Abre una ventana de incógnito (`Ctrl + Shift + N`)
2. Ve a: `https://github.com/GermanPerez-ai/checkin24hs`
3. Si puedes ver el código → Es **PÚBLICO** ✅
4. Si no puedes verlo → Es **PRIVADO** 🔒

---

## ✅ Si el Repositorio es PÚBLICO

**Puedes ignorar el mensaje y hacer el deploy normalmente:**

1. Haz clic en **"Guardar"** en la sección "Fuente"
2. Ve a la pestaña **"Deploy"** o **"Implementar"**
3. Haz clic en **"Deploy"** o **"Redeploy"**
4. El deploy debería funcionar sin problemas

---

## 🔒 Si el Repositorio es PRIVADO

Necesitas configurar un token de GitHub:

### Paso 1: Crear Token en GitHub

1. Ve a GitHub: `https://github.com/settings/tokens`
2. Haz clic en **"Generate new token"** → **"Generate new token (classic)"**
3. Configura:
   - **Note:** `EasyPanel Deploy Token`
   - **Expiration:** `No expiration` (o la fecha que prefieras)
   - **Scopes:** Marca solo:
     - ✅ `repo` (Full control of private repositories)
4. Haz clic en **"Generate token"**
5. **COPIA EL TOKEN** (solo se muestra una vez)

### Paso 2: Configurar Token en EasyPanel

1. En EasyPanel, ve a **"Ajustes"** o **"Settings"** (icono de engranaje en la esquina superior derecha)
2. Busca la sección **"GitHub"** o **"Integrations"**
3. Pega el token en el campo **"GitHub Token"**
4. Haz clic en **"Guardar"** o **"Save"**

### Paso 3: Volver al Servicio Dashboard

1. Regresa al servicio `dashboard`
2. Ve a la pestaña **"Fuente"**
3. Haz clic en **"Guardar"** (para que EasyPanel use el token)
4. Ve a **"Deploy"** y haz clic en **"Deploy"**

---

## 🎯 Recomendación

**Si el repositorio es público**, simplemente:
1. Haz clic en **"Guardar"** en "Fuente"
2. Ve a **"Deploy"** y haz clic en **"Deploy"**
3. El mensaje del token es solo una advertencia, no bloquea el deploy de repos públicos

---

## ❓ ¿Cómo Saber si Funcionó?

Después de hacer clic en "Deploy", deberías ver:
- ✅ Un mensaje de "Build iniciado" o "Deploy iniciado"
- ✅ Logs de construcción apareciendo
- ✅ El proceso completándose en 3-5 minutos

Si ves un error relacionado con "authentication" o "token", entonces sí necesitas configurar el token.
