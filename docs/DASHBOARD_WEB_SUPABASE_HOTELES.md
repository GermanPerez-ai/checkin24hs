# Dashboard y Web: misma fuente de datos (Supabase)

La **web pública** (www.checkin24hs.com) y el **dashboard** (dashboard.checkin24hs.com) usan la misma tabla en Supabase: **`hotels`**.

## Flujo

1. **Dashboard**  
   - Al abrir la tabla de hoteles, carga desde Supabase (`getHotels()`).  
   - Al crear o editar un hotel (nombre, ubicación, fotos, etc.), guarda en Supabase (`createHotel` / `updateHotel`).

2. **Web (www.checkin24hs.com)**  
   - Lee siempre desde Supabase (`from('hotels')`).  
   - Cualquier cambio que hagas en el dashboard (fotos, nombre, descripción, etc.) se verá en la web al recargar.

## Qué tenés que tener hecho

1. **Supabase configurado en el dashboard**  
   - En el dashboard debe estar cargado `supabase-config.js` (o la config que use) con la URL y la anon key del mismo proyecto de Supabase.

2. **Migración de columnas para la web**  
   - En Supabase, ejecutá el contenido de **`supabase-migrations/021_web_hotels_columns.sql`** (si no lo hiciste ya).  
   - Así la tabla `hotels` tiene `imagen_principal`, `galeria_fotos`, `slug`, `pais`, `region`, `ciudad`, etc., que usa la web.

3. **RLS para lectura pública**  
   - La web usa la **anon key** para leer.  
   - Tiene que existir una política que permita **SELECT** para el rol **anon** en la tabla `hotels` (por ejemplo la de **`supabase-migrations/010_hotels_rls_select.sql`**).

4. **Build de la web con variables de Supabase**  
   - La web se construye con `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` (build args o .env en build).  
   - Sin eso, la web no puede conectar con Supabase y no muestra hoteles.

## Cambios hechos en el código

- En **`crm/supabase-client.js`**: al **crear** o **actualizar** un hotel, además de `images`, se rellenan **`imagen_principal`**, **`galeria_fotos`**, **`slug`**, **`puntuacion_num`** y **`precio_desde`** para que la web muestre fotos, URL amigable y precios sin cambios extra en el dashboard.

## Resumen

- Editás hoteles (y fotos) en el **dashboard** → se guarda en **Supabase** → la **web** los muestra porque lee de la misma tabla.  
- Asegurate de tener la migración 021 aplicada, RLS para anon en `hotels` y la web construida con las variables de Supabase.
