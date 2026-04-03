# Vaciar chats e interacciones (base limpia)

Para dejar la base de datos y el dashboard sin datos de chats ni interacciones de Flor.

## 1. Vaciar Supabase

1. Entrá a **Supabase** → tu proyecto → **SQL Editor**.
2. Abrí el archivo `supabase-migrations/013_vaciar_chats_e_interacciones.sql` (o copiá su contenido).
3. Pegá el SQL en el editor y ejecutá **Run**.

Eso borra todos los registros de:

- `whatsapp_messages` (y tablas que la referencian, ej. `whatsapp_media`)
- `whatsapp_chats`
- `flor_interactions`
- `whatsapp_conversations` (si existe)

Las tablas siguen existiendo; solo se vacían.

## 2. Vaciar caché del dashboard

1. Entrá al **dashboard** (HTML) y andá a la sección **Chats**.
2. Clic en **Vaciar caché de chats** (o en **Actualizar**).
3. La lista de conversaciones debería quedar vacía y cargar solo desde Supabase.

Si no ves el botón "Vaciar caché de chats", podés limpiar a mano en el navegador:

- **F12** → pestaña **Application** (o **Almacenamiento**) → **Local Storage** → borrá la clave `flor_active_chats`.
- Luego en Chats hacé clic en **Actualizar**.

## Resumen

| Dónde              | Qué hacer |
|--------------------|-----------|
| Supabase SQL Editor| Ejecutar `013_vaciar_chats_e_interacciones.sql` |
| Dashboard → Chats  | Clic en **Vaciar caché de chats** o **Actualizar** |

Después de esto, los nuevos chats e interacciones se irán llenando de nuevo cuando el servidor WhatsApp reciba y guarde mensajes.
