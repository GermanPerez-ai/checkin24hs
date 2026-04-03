# 📚 Guía: Configurar la IA para la Mejor Enseñanza

## 🎯 Objetivo

Configurar Flor IA para que responda de forma educativa, ayudando a los clientes a tomar mejores decisiones sobre sus viajes.

---

## 🔧 Configuración en el Dashboard

### Paso 1: Acceder a la Configuración de Flor IA

1. Abre el dashboard: `https://dashboard.checkin24hs.com`
2. Ve a la sección **"Flor IA"** en el menú lateral
3. Haz clic en la pestaña **"🤖 IA"**

### Paso 2: Configurar el Proveedor de IA

**Opción Recomendada: Google Gemini (GRATIS)**

1. ✅ Marca la casilla **"Habilitar respuestas con IA"**
2. Selecciona **"Google Gemini"** como proveedor
3. Ingresa tu **API Key** de Gemini:
   - Obtén una API key gratuita en: https://makersuite.google.com/app/apikey
   - Copia la clave y pégala en el campo **"API Key"**
4. Modelo recomendado: **`gemini-2.5-flash`** o **`gemini-2.0-flash`**
5. Haz clic en **"Guardar"**

**Otras Opciones:**
- **OpenAI GPT-4**: Más potente pero requiere pago
- **Claude**: Buena calidad pero requiere pago

---

## 📝 Configuración del Prompt del Sistema

El prompt del sistema ya está optimizado para enseñanza en los archivos:
- `flor-ai-service.js` (desarrollo)
- `deploy/flor-ai-service.js` (producción)

### Características Incluidas:

✅ **Filosofía Educativa**: La IA enseña, no solo informa
✅ **Técnicas de Enseñanza**: Comparación, ejemplos, beneficios explicados
✅ **Contexto Educativo**: Explica el "por qué" detrás de cada recomendación
✅ **Anticipación**: Ofrece información adicional relevante

---

## 🎨 Personalizar las Respuestas

### 1. Configurar Personalidad (Pestaña "General")

En la sección **"⚙️ Configuración General"**:

- **Nombre del Agente**: `Flor`
- **Rol**: `Agente Multimodal de Conversación`
- **Personalidad**: `Amable, eficiente y profesional, educadora`

### 2. Configurar Respuestas (Pestaña "Respuestas")

Puedes personalizar mensajes específicos:

- **Cuando no entiende**: Personaliza el mensaje de fallback
- **Transferir a humano**: Mensaje cuando se escala a agente
- **Despedida**: Mensaje de cierre de conversación

### 3. Configurar Conocimiento (Pestaña "Conocimiento")

Para cada hotel, puedes agregar:

- **Descripción detallada**: Información educativa sobre el hotel
- **Servicios e instalaciones**: Explicación de qué incluye cada servicio
- **Excursiones y actividades**: Qué hacer y por qué es especial
- **Información de precios**: Explicación de cómo funcionan las tarifas
- **Políticas**: Condiciones explicadas de forma clara
- **Cómo llegar**: Instrucciones detalladas

---

## 🚀 Mejoras Implementadas

### ✅ Cambios Realizados:

1. **Misión Principal**: La IA ahora tiene como objetivo educar, no solo informar
2. **Técnicas de Enseñanza**: 
   - Comparación entre opciones
   - Ejemplos concretos
   - Explicación de beneficios
   - Consejos prácticos
   - Preguntas guiadas

3. **Estructura Educativa**:
   - Respuesta directa primero
   - Contexto educativo después ("¿Sabías que...?")
   - Información adicional relevante

4. **Ejemplo de Respuesta Mejorada**: Incluido en el prompt

---

## 📋 Ejemplo de Respuesta Educativa

**Antes:**
```
Hotel Terma de Puyehue está en Osorno. Tiene spa termal.
```

**Después (con enseñanza):**
```
**🏨 Hotel Terma de Puyehue**

📍 **Ubicación:** Osorno, Los Lagos, Chile

Este hotel es perfecto si buscas relajación. Sus aguas termales naturales tienen propiedades terapéuticas reconocidas.

💡 **¿Sabías que?** Las termas ayudan a aliviar dolores musculares y mejoran la circulación. Por eso es ideal para después de actividades físicas.

🎯 **Servicios incluidos:**
• Acceso ilimitado al spa termal
• Desayuno buffet con productos locales
• Wi-Fi en todas las áreas

💰 **Sobre los precios:** Las tarifas varían según temporada. En verano suelen ser más altas, pero incluyen más actividades al aire libre.
```

---

## 🔄 Aplicar los Cambios

### Opción 1: Si ya tienes el código actualizado

Los cambios ya están en:
- ✅ `flor-ai-service.js` (desarrollo)
- ✅ `deploy/flor-ai-service.js` (producción)

Solo necesitas:
1. Reiniciar el servidor de WhatsApp (si es necesario)
2. La configuración se aplicará automáticamente

### Opción 2: Si necesitas subir los cambios

1. Sube `flor-ai-service.js` al servidor
2. Reinicia el servicio de WhatsApp
3. Prueba con una consulta de ejemplo

---

## 💡 Consejos para Mejores Respuestas

### 1. Completa la Base de Conocimiento

- Agrega descripciones detalladas de cada hotel
- Incluye información sobre servicios y sus beneficios
- Explica políticas de forma clara
- Agrega tips y consejos prácticos

### 2. Usa Información del Sitio Web

- Si el hotel tiene sitio web, la IA lo usará como fuente
- Asegúrate de que las URLs de los hoteles estén actualizadas

### 3. Personaliza las Respuestas por Hotel

- Cada hotel puede tener información específica en la pestaña "Conocimiento"
- Agrega detalles únicos que ayuden a educar al cliente

---

## 🧪 Probar la Configuración

1. Conecta WhatsApp
2. Envía un mensaje de prueba: "¿Qué hoteles tienen?"
3. Verifica que la respuesta:
   - ✅ Sea educativa (explica, no solo lista)
   - ✅ Incluya contexto útil
   - ✅ Use formato visual (emojis, negritas)
   - ✅ Sea concisa pero completa

---

## 📊 Parámetros Avanzados (Opcional)

Si quieres ajustar parámetros técnicos de la IA, puedes modificar en `flor-ai-service.js`:

```javascript
// En la función callGemini o callOpenAI
temperature: 0.7,  // Creatividad (0.0-1.0)
maxTokens: 500,    // Longitud máxima de respuesta
```

**Recomendaciones:**
- **Temperature**: 0.7-0.8 para respuestas creativas pero consistentes
- **Max Tokens**: 200-500 para respuestas concisas pero completas

---

## ✅ Checklist de Configuración

- [ ] API Key de Gemini configurada
- [ ] IA habilitada en el dashboard
- [ ] Modelo seleccionado (gemini-2.5-flash recomendado)
- [ ] Base de conocimiento completa para cada hotel
- [ ] Personalidad configurada como "educadora"
- [ ] Respuestas personalizadas configuradas
- [ ] Probado con mensajes de ejemplo

---

## 🆘 Solución de Problemas

**Problema**: La IA no responde con suficiente detalle
- **Solución**: Verifica que la base de conocimiento esté completa

**Problema**: Las respuestas son muy largas
- **Solución**: El prompt ya limita a 150-200 palabras. Si es necesario, ajusta `maxTokens`

**Problema**: No usa información educativa
- **Solución**: Asegúrate de que los hoteles tengan descripciones detalladas en la pestaña "Conocimiento"

---

## 📚 Recursos Adicionales

- **Documentación de Gemini**: https://ai.google.dev/docs
- **Mejores Prácticas de Prompts**: https://ai.google.dev/docs/prompt_best_practices
- **Dashboard de Configuración**: `https://dashboard.checkin24hs.com` → Flor IA

---

**Última actualización**: Los cambios ya están implementados en el código. Solo necesitas configurar la API Key en el dashboard.


