# 📸 Configurar Supabase Storage para Imágenes

## 🎯 Objetivo

Configurar Supabase Storage para poder subir imágenes desde el dashboard y almacenarlas en la nube.

---

## 📋 Paso 1: Crear Bucket en Supabase

1. **Ve a Supabase Dashboard**
   - Abre: https://supabase.com/dashboard
   - Selecciona tu proyecto

2. **Ir a Storage**
   - En el menú lateral izquierdo, haz clic en **"Storage"** (ícono de carpeta)
   - O ve a: https://supabase.com/dashboard/project/[tu-proyecto]/storage

3. **Crear nuevo bucket**
   - Haz clic en **"New bucket"** o **"Crear bucket"**
   - Configura el bucket:
     - **Name**: `hotel-images` (debe ser minúsculas, sin espacios)
     - **Public bucket**: ✅ **Marca esta casilla** (para que las imágenes sean accesibles públicamente)
     - **File size limit**: `5242880` (5MB - ajusta según necesites)
     - **Allowed MIME types**: Deja vacío o agrega: `image/jpeg,image/png,image/webp,image/gif`
   - Haz clic en **"Create bucket"**

---

## 🔓 Paso 2: Configurar Políticas de Acceso (RLS)

Después de crear el bucket, necesitas configurar las políticas para permitir lectura y escritura:

1. **Ve a Storage → Policies**
   - Haz clic en el bucket `hotel-images` que acabas de crear
   - Ve a la pestaña **"Policies"** o **"Políticas"**

2. **Crear política para lectura (SELECT)**
   - Haz clic en **"New policy"**
   - Selecciona **"For full customization"**
   - Nombre: `Allow public read access`
   - Tipo: **SELECT**
   - Política:
   ```sql
   (bucket_id = 'hotel-images'::text)
   ```
   - Haz clic en **"Review"** y luego **"Save policy"**

3. **Crear política para escritura (INSERT)**
   - Haz clic en **"New policy"**
   - Selecciona **"For full customization"**
   - Nombre: `Allow authenticated insert`
   - Tipo: **INSERT**
   - Política:
   ```sql
   (bucket_id = 'hotel-images'::text)
   ```
   - Haz clic en **"Review"** y luego **"Save policy"**

---

## ✅ Paso 3: Verificar Configuración

1. **Verifica que el bucket existe**
   - Deberías ver `hotel-images` en la lista de buckets
   - Debe estar marcado como **"Public"**

2. **Prueba subir una imagen manualmente**
   - Haz clic en el bucket `hotel-images`
   - Haz clic en **"Upload file"** o **"Subir archivo"**
   - Sube una imagen de prueba
   - Verifica que puedas ver la imagen

---

## 🚀 Paso 4: Usar en el Dashboard

Una vez configurado, la función `uploadImages()` en el dashboard funcionará automáticamente.

1. **Abre el dashboard**
2. **Ve a Hoteles → Editar hotel**
3. **Abre el gestor de imágenes**
4. **Selecciona imágenes y haz clic en "Subir"**

Las imágenes se guardarán automáticamente en Supabase Storage y estarán disponibles públicamente.

---

## 🔗 Obtener URL de Imagen

Las imágenes subidas estarán disponibles en:
```
https://[tu-proyecto].supabase.co/storage/v1/object/public/hotel-images/[ruta]
```

Ejemplo:
```
https://lmoeuyasuvoqhtvhkyia.supabase.co/storage/v1/object/public/hotel-images/hotel-1/main.jpg
```

---

## ⚠️ Solución de Problemas

### Error: "new row violates row-level security policy"
- **Solución**: Verifica que las políticas RLS estén configuradas correctamente

### Error: "Bucket not found"
- **Solución**: Asegúrate de que el bucket se llame exactamente `hotel-images` (minúsculas)

### Las imágenes no se cargan
- **Solución**: Verifica que el bucket esté marcado como "Public"

---

## 📝 Nota

Si prefieres usar archivos locales en lugar de Supabase Storage:
- Puedes seguir usando la carpeta `hotel-images/` manualmente
- Las imágenes se cargarán desde esa carpeta
- No necesitas configurar Supabase Storage

¡Avísame cuando hayas creado el bucket para continuar! 🚀

