# Flor IA – Campañas de marketing

Cambios para que Flor maneje campañas de marketing como el bot anterior.

## 1. Lectura de promociones (Dashboard)

- **consultarCatalogoHoteles** ahora incluye las **promociones activas** de la tabla **promotions** vinculadas a cada hotel.
- Se usa la tabla `promotions` (hotel_id, name, type, description, discount, start_date, end_date, status).
- Solo se devuelven promociones con `status = 'active'` y cuya fecha actual esté entre `start_date` y `end_date`.
- Cada hotel en la respuesta de la herramienta tiene un array **promociones** con nombre, tipo, descripción, descuento y fechas.

## 2. Multimodalidad (anuncios fb.me / instagram.com / facebook.com)

- Cuando el mensaje del cliente contiene un enlace a **fb.me**, **instagram.com** o **facebook.com/share** (anuncio), Flor:
  1. Obtiene el preview del enlace (título, descripción, **imagen**).
  2. Descarga la imagen y la envía a **Gemini 2.0 Flash** en base64 (multimodal).
  3. **Reset de contexto:** Se limpia el historial de sesión de ese usuario para que Flor no mezcle hoteles (ej. no responder Huilo Huilo si la imagen es de Puyehue).
  4. **Prioridad multimodal:** Gemini recibe la instrucción: "Analizá esta imagen publicitaria. Identificá el hotel (Puyehue, Corralco o Huilo Huilo) y respondé basándote EXCLUSIVAMENTE en ese hotel. IGNORÁ el historial previo; priorizá solo lo que ves en esta imagen."
  5. Se llama **consultarCatalogoHoteles** con el nombre del hotel identificado en la imagen.

- **Imagen enviada por el usuario:** Si el cliente envía una foto (con o sin caption), el servidor la descarga con Baileys (`downloadMediaMessage`), la envía a Gemini en base64 y Flor puede identificar si es Puyehue, Corralco o Huilo Huilo y responder sobre ese hotel.

## 3. Seguimiento de campaña (palabras clave)

- Si el mensaje contiene palabras clave de campaña (**25% OFF**, **Black Friday**, **Invierno**, **descuento**, **promoción**, **promo**, **oferta**, **campaña**), Flor:
  - Recibe un hint en el contexto: priorizar en la respuesta las **promociones activas** (campo `promociones` de consultarCatalogoHoteles) y adaptar el mensaje a la oferta (descuentos, fechas, beneficios).

## 4. Formato de respuesta (estilo bot anterior + Flor)

- En las reglas de Flor se indica:
  - Usar **iconos con mesura** (📍 mapa, ✅ beneficios, 🏔️ destino).
  - **Puntos claros con viñetas** cuando se enumeren opciones o beneficios.
  - Si el hotel tiene **ubicacion_maps**, incluir el link de mapas en la respuesta.
  - Mantener el **tono narrativo** de Flor (calidez, profesional).
  - Si el cliente menciona campañas, **priorizar** la información de promociones activas.

## Despliegue

- Subir los cambios del servidor (whatsapp-server-baileys.js) y hacer **redeploy** del servicio WhatsApp en EasyPanel.
- La tabla **promotions** debe existir en Supabase y tener datos (creada con `004_create_promotions_table.sql`). RLS debe permitir SELECT para el rol que usa el servidor.
