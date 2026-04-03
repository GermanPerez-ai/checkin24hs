# Imágenes de hoteles en Supabase Storage (sin Base64)

Todas las imágenes de hoteles (principal, galería) se guardan en **Supabase Storage** (bucket `flor-ficha`) y en la base solo se persisten **URLs públicas**. Así Flor no recibe Base64 y "enviar imagen del hotel" funciona con la URL.

---

## 1. Comportamiento actual del panel (dashboard.html)

- **Imagen principal:** Al elegir "Seleccionar desde Disco" se sube a Storage → `hotel-images/{hotelId}/img_general_*.jpg` y se guarda la URL. Si falla Storage, se usa Base64 como fallback.
- **Galería de fotos:** Al elegir archivos para la galería, cada imagen se sube a Storage → `hotel-images/{hotelId}/galeria_*.jpg` y se guardan solo URLs. Si falla, se usa Base64 para esa imagen.
- **Al guardar el hotel:** Si quedó algún Base64 (imagen principal o galería), antes de enviar a Supabase se sube ese Base64 a Storage y se reemplaza por la URL. El resultado final en la base es solo URLs (cuando Supabase está configurado).

Rutas en Storage:
- `hotel-images/{hotelId}/img_general_*.jpg` — imagen principal
- `hotel-images/{hotelId}/galeria_*_*.jpg` — galería

---

## 2. Requisitos en Supabase

1. **Bucket:** Creá el bucket **`flor-ficha`** (público) si no existe.
2. **RLS:** Ejecutá `supabase-migrations/009_storage_flor_ficha_rls.sql` para permitir subidas y lecturas desde el dashboard.

---

## 2. Migrar imágenes que ya están en Base64

Si tenés hoteles con `img_general` en Base64 y querés pasarlos a Storage de una vez:

1. Asegurate de tener el bucket **`flor-ficha`** y las políticas RLS (paso 1 y 2 de la sección anterior).

2. Configurá las variables de entorno (reemplazá con los valores de tu proyecto):
   - `SUPABASE_URL`: URL del proyecto (ej. `https://xxxx.supabase.co`)
   - `SUPABASE_SERVICE_ROLE_KEY`: clave “service_role” de Supabase (Settings → API), para poder actualizar la tabla `hotels`.  
     Si tu RLS permite que `anon` actualice `hotels`, podés usar `SUPABASE_ANON_KEY` en su lugar.

3. Ejecutá el script (desde la raíz del repo):
   ```bash
   cd whatsapp-server && node ../scripts/migrar_img_general_base64_a_storage.js
   ```
   Si en la raíz tenés `@supabase/supabase-js` instalado:
   ```bash
   node scripts/migrar_img_general_base64_a_storage.js
   ```

4. El script:
   - Lista hoteles con `flor_info.img_general` en Base64.
   - Sube cada imagen a `flor-ficha` → `hotel-images/{id}/img_general.jpg` (o .png).
   - Actualiza `flor_info.img_general` con la URL pública.

Después de esto, Flor recibe solo URLs en el payload y “enviar imagen del hotel” sigue funcionando con esa URL.
