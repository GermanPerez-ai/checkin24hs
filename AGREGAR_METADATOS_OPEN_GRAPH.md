# 📸 Agregar Metadatos Open Graph para Preview con Imagen

## 🎯 Objetivo
Agregar metadatos Open Graph a la página del cotizador para que cuando se comparta el enlace en WhatsApp, aparezca una imagen en el preview.

## ✅ Cambio Realizado

Se agregaron metadatos Open Graph a `cotizador-cliente.html`:

- `og:title` - Título del preview
- `og:description` - Descripción del preview
- `og:image` - URL de la imagen (usando una imagen de hotel)
- `og:url` - URL de la página
- `twitter:card` - Para compatibilidad con Twitter
- `meta description` - Descripción estándar

## 📋 Imagen Usada

Por defecto se usa: `https://cotizar.checkin24hs.com/hotel-images/hotel-1-puyehue/main.jpg`

**Nota:** Esta imagen debe estar accesible públicamente. Si la imagen no está disponible en esa URL, puedes:

1. **Cambiar la URL de la imagen** a una que esté disponible públicamente
2. **Subir una imagen específica** para el cotizador
3. **Usar una imagen de otro hotel** que esté disponible

## 🔧 Personalizar la Imagen

Si quieres usar otra imagen, edita `cotizador-cliente.html` y cambia:

```html
<meta property="og:image" content="https://cotizar.checkin24hs.com/TU_IMAGEN_AQUI.jpg">
```

**Requisitos de la imagen:**
- Debe estar accesible públicamente (HTTPS)
- Tamaño recomendado: 1200x630 píxeles
- Formato: JPG o PNG
- Tamaño máximo: 5MB

## 🚀 Próximos Pasos

1. **Subir el cambio a GitHub:**
   ```powershell
   git add cotizador-cliente.html
   git commit -m "Agregar metadatos Open Graph para preview con imagen"
   git push origin main
   ```

2. **Hacer redeploy del servicio del cotizador** en EasyPanel

3. **Probar el preview:**
   - Comparte el enlace `https://cotizar.checkin24hs.com/` en WhatsApp
   - Debería aparecer con imagen ahora

## 🔍 Verificar que Funciona

Puedes verificar los metadatos usando:

1. **Facebook Sharing Debugger:**
   https://developers.facebook.com/tools/debug/

2. **Twitter Card Validator:**
   https://cards-dev.twitter.com/validator

3. **WhatsApp:** Simplemente comparte el enlace y verifica que aparezca la imagen

## ⚠️ Nota Importante

La imagen debe estar accesible públicamente. Si `https://cotizar.checkin24hs.com/hotel-images/hotel-1-puyehue/main.jpg` no está disponible, necesitas:

1. Asegurarte de que las imágenes de hoteles estén servidas públicamente
2. O cambiar la URL a una imagen que sí esté disponible (por ejemplo, un logo o imagen genérica)
