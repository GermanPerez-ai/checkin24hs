# 🔑 Guía Paso a Paso: Cómo Obtener API Keys para Flor

Esta guía te explica cómo obtener una API key gratuita para usar con Flor. Tienes dos opciones principales:

## 🆓 Opción 1: Google Gemini (RECOMENDADO - GRATIS)

Google Gemini ofrece un plan gratuito generoso que es perfecto para empezar.

### Paso 1: Crear una cuenta en Google AI Studio
1. Ve a: **https://aistudio.google.com/**
2. Inicia sesión con tu cuenta de Google (si no tienes una, créala en **https://accounts.google.com/signup**)
3. Acepta los términos y condiciones

### Paso 2: Obtener tu API Key
1. Una vez dentro de Google AI Studio, haz clic en **"Get API Key"** (Obtener clave de API)
2. Haz clic en **"Create API Key"** (Crear clave de API)
3. Selecciona un proyecto de Google Cloud (o crea uno nuevo si es la primera vez)
4. **¡Listo!** Tu API key aparecerá en pantalla. Cópiala inmediatamente porque solo se muestra una vez.

**Ejemplo de API key de Gemini:**
```
AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Paso 3: Configurar en Flor
1. Abre `crm.html` en tu navegador
2. Ve a **"Configurar Flor"** → pestaña **"🤖 Inteligencia Artificial"**
3. Marca **"Habilitar respuestas con IA"**
4. Selecciona **"Google Gemini - GRATIS"** en el proveedor
5. Pega tu API key en el campo **"API Key"**
6. En **"Modelo"**, escribe: `gemini-1.5-flash` (recomendado) o `gemini-1.5-pro`
7. Haz clic en **"Guardar Configuración de IA"**
8. Prueba la conexión con **"Probar Conexión"**

### Límites Gratuitos de Gemini:
- **60 solicitudes por minuto**
- **1,500 solicitudes por día**
- **32,000 tokens por solicitud**

Esto es más que suficiente para uso personal o de prueba.

---

## 💰 Opción 2: OpenAI (Plan Gratuito con Créditos)

OpenAI ofrece créditos gratuitos al registrarte, pero después requiere pago.

### Paso 1: Crear cuenta en OpenAI
1. Ve a: **https://platform.openai.com/**
2. Haz clic en **"Sign up"** (Registrarse)
3. Completa el formulario con tu email o usa tu cuenta de Google/Microsoft
4. Verifica tu email

### Paso 2: Agregar método de pago (requerido para API)
⚠️ **Nota:** Aunque OpenAI requiere agregar un método de pago, te dan **$5 USD de créditos gratis** al registrarte. No se te cobrará nada hasta que uses esos créditos.

1. Una vez dentro, ve a **"Settings"** (Configuración) → **"Billing"** (Facturación)
2. Haz clic en **"Add payment method"** (Agregar método de pago)
3. Agrega una tarjeta de crédito o débito
4. **No se te cobrará nada** hasta que uses los $5 USD de créditos gratis

### Paso 3: Obtener tu API Key
1. Ve a: **https://platform.openai.com/api-keys**
2. Haz clic en **"Create new secret key"** (Crear nueva clave secreta)
3. Dale un nombre (ej: "Flor Chatbot")
4. Haz clic en **"Create secret key"**
5. **¡IMPORTANTE!** Copia la API key inmediatamente. Se verá así:
   ```
   sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   ⚠️ **No podrás verla de nuevo**, así que guárdala en un lugar seguro.

### Paso 4: Configurar en Flor
1. Abre `crm.html` en tu navegador
2. Ve a **"Configurar Flor"** → pestaña **"🤖 Inteligencia Artificial"**
3. Marca **"Habilitar respuestas con IA"**
4. Selecciona **"OpenAI (GPT-4, GPT-3.5)"** en el proveedor
5. Pega tu API key en el campo **"API Key"**
6. En **"Modelo"**, escribe: `gpt-4o-mini` (más económico) o `gpt-3.5-turbo`
7. Haz clic en **"Guardar Configuración de IA"**
8. Prueba la conexión con **"Probar Conexión"**

### Precios de OpenAI (después de los créditos gratis):
- **gpt-4o-mini**: $0.15 por 1M tokens de entrada, $0.60 por 1M tokens de salida
- **gpt-3.5-turbo**: $0.50 por 1M tokens de entrada, $1.50 por 1M tokens de salida

---

## 🎯 Recomendación

**Para empezar, usa Google Gemini** porque:
- ✅ Es completamente gratis sin necesidad de tarjeta
- ✅ Tiene límites generosos
- ✅ Funciona muy bien para chatbots
- ✅ No requiere método de pago

**Usa OpenAI si:**
- Necesitas respuestas más avanzadas
- Ya tienes una cuenta configurada
- Estás dispuesto a pagar después de los créditos gratis

---

## 🔧 Configuración en Flor

Una vez que tengas tu API key:

1. **Abre el CRM**: `crm.html`
2. **Ve a Configurar Flor**: Menú lateral → "Configurar Flor"
3. **Pestaña de IA**: Haz clic en "🤖 Inteligencia Artificial"
4. **Habilita IA**: Marca el checkbox "Habilitar respuestas con IA"
5. **Selecciona proveedor**: Elige Gemini u OpenAI
6. **Pega tu API Key**: En el campo correspondiente
7. **Configura el modelo**:
   - Gemini: `gemini-1.5-flash` (recomendado) o `gemini-1.5-pro`
   - OpenAI: `gpt-4o-mini` (recomendado) o `gpt-3.5-turbo`
8. **Guarda**: Haz clic en "Guardar Configuración de IA"
9. **Prueba**: Haz clic en "Probar Conexión" para verificar que funciona

---

## ❓ Preguntas Frecuentes

**¿Mi API key es segura?**
- Sí, se guarda solo en tu navegador (localStorage). Nunca se envía a servidores externos.

**¿Puedo cambiar de proveedor después?**
- Sí, puedes cambiar en cualquier momento desde la configuración.

**¿Qué pasa si se acaban los créditos/límites?**
- Flor automáticamente usará el sistema de reglas como respaldo. No se romperá nada.

**¿Puedo usar ambos proveedores a la vez?**
- No, solo puedes usar uno a la vez. Pero puedes cambiar fácilmente entre ellos.

---

## 🆘 Problemas Comunes

**Error: "API key inválida"**
- Verifica que copiaste la API key completa sin espacios
- Asegúrate de que la API key esté activa en el proveedor

**Error: "CORS" o "Network error"**
- Algunos navegadores bloquean las llamadas directas a APIs
- Prueba en otro navegador o configura un proxy

**No responde con IA**
- Verifica que el checkbox "Habilitar respuestas con IA" esté marcado
- Revisa la consola del navegador (F12) para ver errores
- Prueba la conexión con el botón "Probar Conexión"

---

¡Listo! Ya tienes todo lo necesario para que Flor responda con IA. 🎉

