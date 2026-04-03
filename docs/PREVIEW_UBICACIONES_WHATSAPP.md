# Previsualización de ubicaciones en WhatsApp (Flor)

## Problema

Al enviar el enlace de Google Maps (`maps.app.goo.gl`) en la respuesta de Flor, WhatsApp muestra un recuadro genérico (logo de Google Maps) en lugar de la imagen del hotel, lo que afecta la estética del mensaje.

## Solución implementada: "Combo visual"

Cuando Flor responde con **ubicación** y el mensaje incluye un **link de Google Maps**, el sistema:

1. **Detecta** si el texto contiene una URL de Maps (`maps.app.goo.gl`, `goo.gl/maps`, `google.com/maps`).
2. **Busca** en Supabase el hotel cuyo campo **"Cómo Llegar"** (`transport`) o **"Ubicación Maps"** (`ubicacion_maps`) en `flor_info` contenga esa misma URL.
3. Si encuentra el hotel y tiene **imagen principal** (`flor_info.img_general`):
   - **Mensaje 1:** Se envía la **imagen del hotel** con un pie de foto breve: `📍 [Nombre del Hotel]\n\nTe comparto la ubicación.`
   - **Mensaje 2:** Se envía el **texto completo** con la ubicación y el link de Maps/Waze.

Así el usuario ve primero la foto de la propiedad y luego el texto con el enlace.

## Ubicación dinámica (link por hotel)

- El link de Maps debe estar configurado **por hotel** en el Dashboard de Flor:
  - **Campo "Cómo Llegar"** (Flor / Transport): puede incluir texto + URL de Maps.
  - **Campo "Ubicación Maps" / Google Maps**: se guarda en `flor_info.ubicacion_maps` y también se usa para el combo.
- El servidor siempre usa el link que está guardado en **flor_info** de ese hotel (transport o ubicacion_maps), no un link genérico.

## Requisitos en el Dashboard

1. **Imagen principal del hotel**  
   Debe estar cargada (URL o subida). Se guarda en el hotel y también en **flor_info.img_general** al guardar el hotel, para que el combo tenga miniatura.

2. **Link de Google Maps**  
   En el formulario del hotel:
   - **Google Maps / Ubicación Maps:** pegar la URL (ej. `https://maps.app.goo.gl/...`). Se guarda en `flor_info.ubicacion_maps`.
   - **Cómo Llegar (Flor):** puede contener instrucciones y, si se desea, la misma URL de Maps. Se guarda en `flor_info.transport`.

Si el hotel tiene **img_general** y el mensaje de Flor incluye un link de Maps que coincide con ese hotel, se aplica el combo (imagen + texto).

## Archivos tocados

- **whatsapp-server/whatsapp-server-baileys.js**
  - `esLinkMaps(url)` – detecta si una URL es de Google Maps.
  - `buscarHotelPorMapsLinkEnTexto(texto)` – obtiene el hotel (y su imagen) asociado al link de Maps en el texto.
  - `prepararComboUbicacionConImagen(texto)` – devuelve el objeto para enviar en dos mensajes (imagen + texto).
  - `prepararMensajeFlorParaEnvio(texto)` – si hay combo de ubicación, lo usa; si no, mensaje normal o cotización con imagen.
  - Flujo de envío: si `mensajeParaEnvio.sendAsCombo` es true, se envía primero la imagen con caption y luego el texto con el link.
- **dashboard.html / deploy/dashboard.html**
  - Al guardar el hotel, se añade **flor_info.img_general** con la imagen principal (`mainImage`) para que el servidor pueda usarla en el combo.

## preview_url (Business API)

En la **API oficial de WhatsApp Business** se puede enviar el mensaje de texto con `preview_url: true` para que se genere la vista previa del enlace. En este proyecto se usa **Baileys** (API no oficial). Baileys genera previews automáticamente cuando el mensaje contiene una URL; el problema es que los enlaces cortos de Google Maps no siempre exponen una `og:image` útil. Por eso se implementó el **combo imagen + texto** en lugar de depender solo del preview del link.

## Resumen

| Requisito                         | Implementación                                                                 |
|----------------------------------|---------------------------------------------------------------------------------|
| Miniatura de la propiedad        | Imagen del hotel desde `flor_info.img_general` (imagen principal del Dashboard) |
| Descripción / caption            | Pie de foto: "📍 [Hotel]\n\nTe comparto la ubicación."                          |
| Mensaje 2 con link               | Texto completo de Flor con link de Maps (y Waze si se agrega)                  |
| Link desde "Cómo Llegar"         | Link tomado de `flor_info.ubicacion_maps` o `flor_info.transport` por hotel    |
