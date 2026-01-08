# 🎤📸 Flor - Capacidades Multimodales

## 📋 Descripción

Flor ahora es un **Agente de Conversación Multimodal** que puede:
- 🎤 **Escuchar e interpretar audios** enviados por los clientes
- 📸 **Ver e interpretar imágenes** enviadas por los clientes
- 📤 **Enviar imágenes proactivamente** cuando la consulta lo justifique

## 🎤 Protocolo de Audio (Escuchar e Interpretar)

### Funcionamiento

1. **Prioridad**: El audio se trata como texto. Si el audio es una pregunta, se extrae la pregunta clave y se responde de forma concisa (manteniendo la regla de las 3 frases).

2. **Velocidad y Precisión**: La transcripción e interpretación es lo más rápida posible debido a la impaciencia del cliente.

3. **Límites de Audio**: 
   - Si el audio excede los **45 segundos** o es de **mala calidad**, se activa el fallback con la siguiente respuesta estandarizada:
   
   > "Disculpa, el audio no fue del todo claro. Para atenderte con la rapidez que mereces, ¿podrías enviarme tu consulta por escrito, o prefieres que te conecte con un agente ahora mismo?"

### Proveedores de Transcripción

Flor soporta múltiples proveedores de transcripción:

- **Browser (Web Speech API)**: Gratis, sin API key (limitado a reconocimiento en tiempo real)
- **Google Cloud Speech-to-Text**: Requiere API key de Google Cloud
- **Azure Speech Services**: Requiere API key de Azure

### Configuración

```javascript
// Configurar servicio de audio
florMultimodalService.configure({
    audio: {
        enabled: true,
        provider: 'browser', // 'browser', 'google', 'azure'
        apiKey: 'tu-api-key', // Solo necesario para google/azure
        maxDuration: 45, // segundos
        fallbackMessage: 'Mensaje personalizado...'
    }
});
```

## 📸 Protocolo de Imágenes (Ver e Interpretar)

### Uso Principal

La imagen se utiliza principalmente para:
- **Identificación de producto**: Si el cliente envía una foto de un tipo de habitación
- **Identificación de problema**: Si el cliente envía una foto de un error en su reserva
- **Comparación con Base de Conocimiento**: Flor compara la imagen con la información disponible (ej: Tipo de habitación "Suite Premium") y responde sobre el dato relevante

### Ejemplo de Uso

Si el cliente envía una foto de una habitación, Flor:
1. Analiza la imagen usando visión artificial
2. Identifica elementos relevantes (hotel, habitación, servicios)
3. Compara con la Base de Conocimiento
4. Responde: "La Suite Premium que nos muestras incluye desayuno y tiene un costo de..."

### Regla de Seguridad

⚠️ **Nunca almacenar o utilizar imágenes de clientes** (personas, documentos) para otra cosa que no sea la respuesta inmediata a su consulta.

### Proveedores de Análisis de Imágenes

- **Browser**: Análisis básico (solo dimensiones)
- **Google Cloud Vision**: Requiere API key
- **Azure Computer Vision**: Requiere API key
- **OpenAI Vision (GPT-4 Vision)**: Requiere API key de OpenAI

### Configuración

```javascript
// Configurar servicio de imágenes
florMultimodalService.configure({
    image: {
        enabled: true,
        provider: 'browser', // 'browser', 'google', 'azure', 'openai'
        apiKey: 'tu-api-key', // Solo necesario para proveedores externos
        maxSize: 10 * 1024 * 1024 // 10MB
    }
});
```

## 📤 Protocolo de Envío de Imágenes (Salida/Integración)

Flor está autorizada a enviar imágenes solo bajo las siguientes condiciones:

### Motivo 1: Solicitud de Información Visual

**Condición**: Si el cliente pregunta por la apariencia de un hotel o habitación específica.

**Acción**: El bot llama al API interno `GET /api/hoteles/imagen/{nombre_hotel}` para enviar la foto oficial correspondiente.

**Ejemplo**:
- Cliente: "¿Cómo se ve el Hotel Terma de Puyehue?"
- Flor: Responde con información y envía la imagen principal del hotel

### Motivo 2: Documentación de Soporte

**Condición**: Si el cliente solicita un documento estándar (Ej: un mapa de ubicación o una infografía de servicios).

**Acción**: Enviar el archivo pre-aprobado y almacenado para esa consulta.

### Regla de Tono

El envío de imágenes debe ser **funcional, no decorativo**.

## 🔧 Integración Técnica

### Endpoint de Imágenes

El servidor incluye el endpoint:

```
GET /api/hoteles/imagen/:nombre_hotel?type=main
```

**Parámetros**:
- `nombre_hotel`: Nombre del hotel (ej: "Hotel Terma de Puyehue")
- `type`: Tipo de imagen (`main`, `gallery-1`, `gallery-2`, etc.)

**Respuesta**:
```json
{
    "success": true,
    "hotel": "Hotel Terma de Puyehue",
    "imageUrl": "/hotel-images/hotel-1-puyehue/main.jpg",
    "type": "main"
}
```

### Estructura de Archivos

Las imágenes se almacenan en:
```
hotel-images/
├── hotel-1-puyehue/
│   ├── main.jpg
│   ├── gallery-1.jpg
│   └── gallery-2.jpg
├── hotel-2-huilo-huilo/
│   └── ...
```

### Uso en el Código

```javascript
// En flor-agent.js
const imageUrl = await agent.getHotelImageUrl(hotelId, hotelName, 'main');

// En flor-chatbot.html
if (response.sendImage) {
    const imageUrl = await agent.getHotelImageUrl(
        response.sendImage.hotelId,
        response.sendImage.hotelName,
        response.sendImage.type
    );
    addBotImage(imageUrl, `Foto de ${response.sendImage.hotelName}`);
}
```

## 🚀 Uso en la Interfaz

### Enviar Audio

1. El usuario hace clic en el botón de micrófono 🎤
2. Selecciona un archivo de audio
3. Flor transcribe el audio automáticamente
4. Procesa la transcripción como un mensaje de texto normal

### Enviar Imagen

1. El usuario hace clic en el botón de imagen 📸
2. Selecciona una imagen
3. Flor analiza la imagen automáticamente
4. Usa la descripción de la imagen para generar una respuesta contextualizada

### Recibir Imagen del Bot

Cuando Flor determina que debe enviar una imagen:
1. Muestra la respuesta de texto
2. Automáticamente carga y muestra la imagen del hotel
3. El usuario puede hacer clic en la imagen para verla en tamaño completo

## 📝 Archivos Modificados/Creados

### Nuevos Archivos

- `flor-multimodal-service.js`: Servicio principal para procesamiento de audio e imágenes

### Archivos Modificados

- `flor-agent.js`: Agregado soporte para procesar audio e imágenes
- `flor-chatbot.html`: Agregados botones para enviar audio e imágenes, y visualización de imágenes
- `flor-ai-service.js`: Agregado soporte para análisis de imágenes en respuestas de IA
- `server.js`: Agregado endpoint `GET /api/hoteles/imagen/:nombre_hotel`

## ⚙️ Configuración Avanzada

### Habilitar Google Cloud Speech-to-Text

```javascript
florMultimodalService.configure({
    audio: {
        provider: 'google',
        apiKey: 'TU_GOOGLE_CLOUD_API_KEY'
    }
});
```

### Habilitar OpenAI Vision

```javascript
florMultimodalService.configure({
    image: {
        provider: 'openai',
        apiKey: 'TU_OPENAI_API_KEY'
    }
});
```

### Habilitar Azure Services

```javascript
florMultimodalService.configure({
    audio: {
        provider: 'azure',
        apiKey: 'TU_AZURE_SPEECH_KEY',
        region: 'eastus'
    },
    image: {
        provider: 'azure',
        apiKey: 'TU_AZURE_VISION_KEY',
        region: 'eastus'
    }
});
```

## 🔍 Debugging

### Ver logs de procesamiento

Los logs se muestran en la consola del navegador:

```
[Flor Multimodal] 🎤 Procesando audio...
[Flor Multimodal] ✅ Audio transcrito: "¿Cuánto cuesta una noche en Puyehue?"
[Flor Agent] 📸 Procesando imagen...
[Flor Agent] ✅ Imagen analizada: "Hotel con piscina y vista a montañas"
```

### Verificar configuración

```javascript
console.log(florMultimodalService.config);
```

## 📚 Referencias

- [Google Cloud Speech-to-Text](https://cloud.google.com/speech-to-text)
- [Azure Speech Services](https://azure.microsoft.com/services/cognitive-services/speech-services/)
- [Google Cloud Vision](https://cloud.google.com/vision)
- [Azure Computer Vision](https://azure.microsoft.com/services/cognitive-services/computer-vision/)
- [OpenAI Vision API](https://platform.openai.com/docs/guides/vision)

