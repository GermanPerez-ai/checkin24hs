# Flor IA: transcripción de audios de WhatsApp

Flor ahora responde a mensajes de **audio/voice** de WhatsApp: transcribe el audio con Gemini y usa el texto en el mismo flujo que las consultas por escrito (consultarCatalogoHoteles, etc.).

---

## Qué se implementó

1. **Detección de audio/voice**  
   El servidor detecta cuando el mensaje es `audioMessage` o `pttMessage` (nota de voz). Esos mensajes ya no se ignoran.

2. **Guardado con `message_type`**  
   En `whatsapp_messages` se guarda `message_type: 'audio'` para los mensajes de audio/voice (si la tabla tiene la columna).

3. **Transcripción con Gemini 2.0 Flash**  
   Se usa la misma API de Gemini (multimodal) que para imágenes: el audio se envía como `inlineData` (base64 + mimeType) con el prompt *"Transcribe this voice message to text..."*.  
   Formatos soportados por Gemini: `audio/ogg`, `audio/mp3`, `audio/wav`, `audio/aac`, `audio/flac`. WhatsApp suele enviar voz en `audio/ogg`.

4. **Flujo de respuesta**  
   El texto transcrito reemplaza `[Audio]` en el mensaje combinado y se pasa a **procesarConFlor** (mismo flujo que consultarCatalogoHoteles). Flor responde por texto en WhatsApp como con cualquier consulta escrita.

5. **Logs**  
   En consola del servidor se ve:
   - `🎙️ Audio recibido -> Transcripción: [texto del usuario]`  
   cuando la transcripción funciona.
   - `🎙️ Audio recibido -> Transcripción: (fallo o vacío)`  
   cuando Gemini no devuelve texto.

6. **Fallback si falla la transcripción**  
   Si no se puede transcribir (error de descarga, error de API o respuesta vacía), Flor envía el mensaje configurado en `FLOR_RESPONSES_DEFAULTS.audioFallback` (ej.: *"Disculpa, el audio no fue del todo claro. ¿Podrías enviarme tu consulta por escrito...?"*).

---

## Dónde está el código

- **Archivo:** `whatsapp-server/whatsapp-server-baileys.js`
- **Función de transcripción:** `transcribeAudioWithGemini(audioBase64, mimeType)`
- **Detección de audio:** en el bucle de mensajes entrantes, `message.audioMessage || message.pttMessage`
- **Procesamiento:** en `processPending`, bloque "3) Si el usuario envió audio/voice"

---

## Cómo probar

1. Enviar una nota de voz por WhatsApp al número conectado.
2. Revisar los logs del servidor: debe aparecer `🎙️ Audio recibido -> Transcripción: ...` con el texto.
3. Flor debe responder por texto como si el usuario hubiera escrito esa frase.

---

## Requisitos

- **GEMINI_API_KEY** configurada en el servidor (igual que para texto/imagen).
- Modelo usado para transcripción: el mismo que Flor (`CONFIG.GEMINI_MODEL`, por defecto `gemini-3.1-flash-lite-preview`).  
  Gemini 2.0 Flash soporta audio como entrada multimodal.
