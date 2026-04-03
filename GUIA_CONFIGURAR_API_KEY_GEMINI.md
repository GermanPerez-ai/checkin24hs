# 🔑 Guía: Configurar API Key de Gemini para Flor IA

## 📋 Paso 1: Obtener API Key de Gemini

### 1.1 Ir a Google AI Studio

1. Abre tu navegador
2. Ve a: **https://makersuite.google.com/app/apikey**
3. O busca: "Google AI Studio API Key"

### 1.2 Iniciar Sesión

1. Haz clic en **"Sign in"** o **"Iniciar sesión"**
2. Usa tu cuenta de Google (la que quieras usar)
3. Acepta los términos si te los pide

### 1.3 Crear API Key

1. Haz clic en el botón **"Create API Key"** o **"Crear API Key"**
2. Selecciona un proyecto (o crea uno nuevo)
3. **¡Listo!** Se generará tu API Key

### 1.4 Copiar la API Key

Tu API Key se verá así:
```
AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567
```

**⚠️ IMPORTANTE:**
- Copia la clave completa
- Guárdala en un lugar seguro
- No la compartas públicamente
- Es GRATUITA hasta cierto límite de uso

---

## 📋 Paso 2: Configurar en el Dashboard

### 2.1 Abrir el Dashboard

1. Ve a: **https://dashboard.checkin24hs.com**
2. Inicia sesión con tus credenciales

### 2.2 Navegar a Flor IA

1. En el menú lateral izquierdo, busca **"Flor IA"**
2. Haz clic en **"Flor IA"**

### 2.3 Ir a la Pestaña de IA

1. Verás varias pestañas en la parte superior:
   - 💬 Chats
   - 📚 Conocimiento
   - 🤖 **IA** ← Haz clic aquí
   - 💬 Respuestas
   - 📋 Políticas

2. Haz clic en la pestaña **"🤖 IA"**

### 2.4 Configurar la IA

Verás una sección con estas opciones:

#### ✅ Habilitar respuestas con IA
- Marca esta casilla para activar Flor IA

#### Seleccionar Proveedor
- Selecciona: **"Google Gemini"**

#### API Key
- Pega tu API Key de Gemini aquí
- Debe empezar con `AIza...`

#### Modelo
- Selecciona: **"gemini-2.5-flash"** o **"gemini-2.0-flash"**
- Estos son los modelos más rápidos y económicos

#### Otros parámetros (opcionales)
- **Temperature**: 0.7 (balance entre creatividad y consistencia)
- **Max Tokens**: 500 (longitud máxima de respuesta)

### 2.5 Guardar Configuración

1. Haz clic en el botón **"Guardar"** o **"Save"**
2. Espera a que aparezca un mensaje de confirmación

### 2.6 Probar Conexión

1. Haz clic en **"Probar Conexión"** o **"Test Connection"**
2. Deberías ver un mensaje como:
   - ✅ "Conexión exitosa"
   - ✅ "API Key válida"
   - O similar

Si hay un error:
- Verifica que la API Key esté correcta
- Verifica que no tenga espacios al inicio/final
- Verifica tu conexión a internet

---

## 📋 Paso 3: Verificar que Funciona

### 3.1 Enviar Mensaje de Prueba

1. Abre WhatsApp en tu teléfono
2. Envía un mensaje al número conectado:
   ```
   Hola, ¿qué hoteles tienen?
   ```

### 3.2 Verificar la Respuesta

Flor debería responder con:
- ✅ Lista de hoteles disponibles
- ✅ Información educativa sobre cada uno
- ✅ Ubicación y características destacadas
- ✅ Formato visual (con emojis y estructura clara)

### 3.3 Revisar Logs (Opcional)

Si quieres ver qué está pasando en el servidor:

```powershell
ssh root@72.61.58.240 "CONTAINER=`$(docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1); docker logs `$CONTAINER -f | grep -i 'gemini\|flor\|respuesta'"
```

---

## ✅ Checklist de Configuración

- [ ] API Key de Gemini obtenida
- [ ] API Key copiada correctamente
- [ ] Dashboard abierto
- [ ] Pestaña "🤖 IA" seleccionada
- [ ] "Habilitar respuestas con IA" marcado
- [ ] "Google Gemini" seleccionado
- [ ] API Key pegada en el campo correspondiente
- [ ] Modelo seleccionado (gemini-2.5-flash)
- [ ] Configuración guardada
- [ ] Conexión probada exitosamente
- [ ] Mensaje de prueba enviado por WhatsApp
- [ ] Flor respondió correctamente

---

## 🆘 Solución de Problemas

### Error: "API Key inválida"
- Verifica que copiaste la clave completa
- Verifica que no tenga espacios
- Verifica que empiece con `AIza`

### Error: "Conexión fallida"
- Verifica tu conexión a internet
- Verifica que la API Key esté activa
- Intenta crear una nueva API Key

### Error: "Límite de uso excedido"
- La API Key gratuita tiene límites
- Espera unas horas o crea una nueva cuenta

### Flor no responde
- Verifica que "Habilitar respuestas con IA" esté marcado
- Verifica que el servicio de WhatsApp esté activo
- Revisa los logs del servidor

---

## 📚 Información Adicional

### Límites de la API Gratuita

- **Gemini 2.5 Flash**: ~15 RPM (requests por minuto)
- **Gemini 2.0 Flash**: ~15 RPM
- Suficiente para uso normal de WhatsApp

### Costos

- **Gratis** hasta cierto límite mensual
- Después, muy económico (centavos por 1000 requests)
- Para uso normal de WhatsApp, probablemente nunca pagarás

---

**¡Una vez configurada la API Key, Flor estará lista para responder!** 🚀

