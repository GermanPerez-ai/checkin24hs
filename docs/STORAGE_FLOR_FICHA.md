# Bucket Supabase para Ficha Flor (imágenes y PDFs)

Para que la subida desde el Dashboard funcione, hay que crear el bucket **y** las políticas RLS en Supabase Storage. Si no, al subir una imagen/PDF aparece: *"new row violates row-level security policy"*.

## Pasos (una sola vez)

### 1. Crear el bucket

1. Entrá a **Supabase** → tu proyecto → **Storage** (menú izquierdo).
2. Clic en **New bucket**.
3. **Name:** `flor-ficha` (tiene que ser exactamente ese nombre).
4. Marcá **Public bucket** (para que las URLs de las imágenes y PDFs sean accesibles sin login).
5. Guardá.

### 2. Crear las políticas RLS (obligatorio para que funcione "Subir")

Por defecto Storage no permite subidas sin políticas RLS. Tenés que ejecutar el SQL que las crea:

1. En Supabase, andá a **SQL Editor** → **New query**.
2. Abrí en tu proyecto el archivo `supabase-migrations/009_storage_flor_ficha_rls.sql`.
3. Copiá todo el contenido y pegálo en el editor.
4. Clic en **Run**.

Eso crea políticas que permiten a la app (anon) **insertar**, **leer**, **actualizar** y **borrar** objetos en el bucket `flor-ficha`. Después de eso, el botón **Subir** del Dashboard debería funcionar sin el error de RLS.

Si tu bucket tiene otro **id** (UUID) en lugar del nombre `flor-ficha`, en el SQL reemplazá `bucket_id = 'flor-ficha'` por `bucket_id = (SELECT id FROM storage.buckets WHERE name = 'flor-ficha')` en todas las políticas.

---

Listo. Desde el Dashboard (Hotels → Editar hotel → Ficha Flor) vas a poder usar **Subir** en cada campo de imagen o PDF; el archivo se sube a este bucket y la URL se guarda sola en el hotel.

**Estructura interna:** los archivos se guardan como `{hotelId o "nuevo"}/{campo}_{timestamp}.{ext}` (ej. `abc-123/habitacion_1700000000.jpg`). Podés cambiar temporadas subiendo un archivo nuevo: se genera una nueva URL y al guardar el hotel queda actualizada.
