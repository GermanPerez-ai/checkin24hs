# Error "Failed to fetch" al cargar alojamientos (www.checkin24hs.com)

Si en la web aparece **"Error al cargar alojamientos: TypeError: Failed to fetch"**, la petición a Supabase no está llegando o el navegador la bloquea.

## Causas habituales

1. **Dominio no permitido en Supabase**  
   En el dashboard de Supabase: **Authentication** → **URL Configuration**  
   - **Site URL:** `https://www.checkin24hs.com` (o la que uses).  
   - **Redirect URLs:** añadí `https://www.checkin24hs.com`, `https://www.checkin24hs.com/**`, `https://checkin24hs.com`, `https://checkin24hs.com/**`.  
   La API (anon) suele aceptar cualquier origen; si tenés restricciones extra, revisá que el dominio de la web esté permitido.

2. **Web construida sin variables de Supabase**  
   La web debe construirse con **VITE_SUPABASE_URL** y **VITE_SUPABASE_ANON_KEY** (build args o .env en el build). Si faltan, no hay cliente de Supabase y puede aparecer otro error; si la URL está mal, puede fallar la petición (Failed to fetch).  
   Revisá en el servidor que el `docker build` (o EasyPanel) pase esos build-args.

3. **Red o firewall**  
   Que el navegador no pueda conectar con `https://lmoeuyasuvoqhtvhkyia.supabase.co` (o tu URL de proyecto). Probar desde otra red o dispositivo.

4. **HTTPS / contenido mixto**  
   Si la web se sirve por HTTPS y en el código hubiera una URL de Supabase en HTTP, el navegador puede bloquear. Siempre usar **https://** para la URL del proyecto en Supabase.

## Qué revisar

- En **Supabase** → **Project Settings** → **API**: que **Project URL** sea `https://...supabase.co` y que la **anon key** sea la que usás en el build.  
- En la web en producción: F12 → **Network** → recargar y ver si la petición a `rest/v1/hotels` aparece y con qué status (4xx, 5xx, bloqueada, etc.).  
- Que en el build de la web estén definidos **VITE_SUPABASE_URL** y **VITE_SUPABASE_ANON_KEY**.
