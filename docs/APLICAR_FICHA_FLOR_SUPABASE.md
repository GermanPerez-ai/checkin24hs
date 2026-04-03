# Aplicar la Ficha Flor en Supabase

No hace falta “pasar código” a Supabase. La ficha de hoteles para Flor **ya está en tu código** (dashboard + servidor). En Supabase solo tenés que **ejecutar la migración** y, si querés subir archivos desde el panel, **crear el bucket** de Storage.

---

## 1. Migración en Supabase (obligatorio, una vez)

La “ficha hoteles” es la columna **`flor_info`** en la tabla **`hotels`** (no hay tabla aparte `fichas_hoteles`).

1. Entrá a **Supabase** → tu proyecto → **SQL Editor**.
2. Abrí el archivo **`supabase-migrations/008_hotels_flor_info_jsonb.sql`** de este repo y copiá su contenido.
3. Pegalo en el editor y ejecutá (Run).

Contenido (por si no tenés el archivo a mano):

```sql
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS flor_info JSONB DEFAULT '{}';
```

Con eso la tabla `hotels` queda con la columna `flor_info` donde se guarda alias, programas, servicios, gastronomía, tips, URLs de imágenes/PDFs, etc.

---

## 2. Bucket para subir imágenes/PDFs (opcional)

Si querés usar **Subir** en el panel para imágenes y PDFs de la ficha Flor:

1. Supabase → **Storage** → **New bucket**.
2. Nombre: **`flor-ficha`** (exactamente así).
3. Marcá **Public bucket**.
4. Guardar.

Detalle: **`docs/STORAGE_FLOR_FICHA.md`**.

---

## 3. ¿El código ya está listo para Supabase?

**Sí.** Con lo que hicimos:

- El **dashboard** ya envía **`flor_info`** al crear y al editar hoteles (objetos `hotelForSupabase` y `updatesForSupabase` con `flor_info: hotelData.florInfo`).
- La **subida** desde el panel sube a Supabase Storage (bucket `flor-ficha`) y escribe la URL en el campo; al guardar el hotel, esa URL queda en `flor_info`.
- El **servidor** de Flor ya lee `flor_info` de la tabla `hotels` (búsqueda por alias, URLs para PDF/imagen, etc.).

No tenés que modificar nada más en el código para “aplicarlo a Supabase”: solo ejecutar la migración (y crear el bucket si querés subir archivos).

---

## Resumen

| Paso | Dónde | Qué hacer |
|------|--------|-----------|
| 1 | Supabase → SQL Editor | Ejecutar `008_hotels_flor_info_jsonb.sql` (agregar columna `flor_info` a `hotels`). |
| 2 | Supabase → Storage | Crear bucket público `flor-ficha` (solo si vas a usar “Subir” en el panel). |
| 3 | Dashboard | Nada: ya guarda y lee `flor_info`; la subida ya usa Supabase Storage. |

Después de eso, desde el panel podés cargar y editar la ficha Flor por hotel (alias, programas, servicios, URLs o archivos subidos) y Flor usará esos datos en Supabase.
