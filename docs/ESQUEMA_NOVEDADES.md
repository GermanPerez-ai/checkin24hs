# Esquema y flujo: Novedades (etiqueta_boton y slug)

## Orden de migraciones

Ejecutar en Supabase en este orden:

| Archivo | Qué hace |
|---------|----------|
| `022_web_novedades.sql` | Crea tabla `novedades` (titulo, resumen, imagen_miniatura, fecha_publicacion, cuerpo_nota, slug, created_at, updated_at) |
| `028_novedades_dashboard_rls.sql` | RLS para que el dashboard (anon) pueda INSERT/UPDATE/DELETE |
| `029_storage_novedades_rls.sql` | Bucket Storage "novedades" y políticas para subir imágenes/videos |
| `034_novedades_imagen_miniatura_mobile.sql` | Columna `imagen_miniatura_mobile` |
| `035_novedades_video_miniatura.sql` | Columna `video_miniatura` |
| **`036_novedades_etiqueta_boton.sql`** | Columna `etiqueta_boton` y relleno para filas existentes |

**Si el botón en la web sigue mostrando "Ver más" o el slug viejo:** asegurate de haber ejecutado **036** en el proyecto de Supabase. Sin esa columna, el backend ignora o falla al guardar `etiqueta_boton`.

---

## Esquema final de `public.novedades`

| Columna | Tipo | Uso |
|---------|------|-----|
| id | UUID PK | Identificador único |
| titulo | TEXT NOT NULL | Título de la novedad |
| resumen | TEXT | Resumen (tarjeta y detalle) |
| imagen_miniatura | TEXT | URL imagen principal |
| imagen_miniatura_mobile | TEXT | URL imagen móvil (opcional) |
| video_miniatura | TEXT | URL video (opcional; en tarjeta reemplaza imagen) |
| fecha_publicacion | TIMESTAMPTZ | Orden y fecha mostrada |
| cuerpo_nota | TEXT | HTML/texto del detalle |
| **slug** | TEXT UNIQUE | **Solo para la URL** (ej. `informacion`, `promo-2`). Único, sin espacios ni caracteres raros. |
| **etiqueta_boton** | TEXT | **Texto del botón en la tarjeta** (ej. "INFORMACION", "CUPOS LIMITADOS"). Se guarda tal cual. |
| created_at / updated_at | TIMESTAMPTZ | Auditoría |

- **URL de la novedad:** siempre usa `slug` (ej. `/novedad/informacion`).
- **Texto del botón en la tarjeta:** usa `etiqueta_boton` si tiene valor; si está vacío o NULL, la web muestra **"Ver más"**.

---

## Flujo Dashboard → Supabase → Web

1. **Dashboard (dashboard.html)**  
   - Un solo campo: "Texto del botón (opcional)" → input `#novedadSlug`.  
   - Al guardar:  
     - `slugInput` = valor tal cual del input → se envía como **etiqueta_boton**.  
     - `slug` = versión sanitizada para URL (solo letras, números, guiones). Si queda vacío o ya existe, se genera uno único desde el título + timestamp.  
   - createNovedad/updateNovedad envían: `slug`, `etiqueta_boton: slugInput || null`, y el resto de campos.

2. **Supabase (supabase-client.js)**  
   - `createNovedad(row)`: inserta explícitamente `etiqueta_boton: row.etiqueta_boton != null ? row.etiqueta_boton : null`.  
   - `updateNovedad(id, updates)`: hace `.update({ ...updates, updated_at })`, así que `etiqueta_boton` se persiste si viene en `updates`.  
   - `getNovedades()`: `select('*')`, devuelve todas las columnas, incluida `etiqueta_boton`.

3. **Web (checkin24hs-web)**  
   - **Novedades.tsx:** pide `slug, etiqueta_boton` (y demás). En la tarjeta:  
     - Si `etiqueta_boton` tiene valor (no null y no solo espacios) → se muestra ese texto en el botón.  
     - Si no → se muestra **"Ver más"**.  
   - El enlace de la tarjeta es siempre `to={/novedad/${n.slug || n.id}}` (URL por slug).  
   - **NovedadDetail.tsx:** resuelve por `slug` o por `id` (UUID); no usa `etiqueta_boton` en la página de detalle.

---

## Comprobación rápida

- [ ] Migración **036** ejecutada en Supabase (columna `etiqueta_boton` existe).  
- [ ] En el dashboard, al editar una novedad el campo "Texto del botón" muestra el valor guardado (o vacío).  
- [ ] Después de guardar con un texto (ej. "INFORMACION"), la lista del dashboard muestra ese texto en la columna correspondiente.  
- [ ] En la web pública, la tarjeta muestra ese texto en el botón y el enlace abre `/novedad/<slug>`.

Si todo eso se cumple y el botón sigue igual, revisar caché del navegador o que la web esté leyendo del mismo proyecto Supabase que el dashboard.
