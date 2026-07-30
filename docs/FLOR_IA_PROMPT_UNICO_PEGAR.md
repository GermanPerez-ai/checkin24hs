# Flor IA – Prompt único para pegar (Dashboard / Supabase)

**Versión actual:** V4.1 "Asesoría y Destinos" — ver `docs/flor-prompt-v41.txt` y `supabase-migrations/061_flor_prompt_v41_asesoria_y_destinos.sql`

Este es el **texto único** del Prompt General de Flor IA, alineado con:

- **Function calling**: Flor usa `consultarCatalogoHoteles` para datos de hoteles.
- **Cotización a medida**: ante precios de un hotel elegido, pedir fechas, noches, huéspedes y edades (sin PDFs/catálogos).
- **Indecisión**: si no sabe qué hotel elegir, derivar a https://www.checkin24hs.com/
- **Hand-off** a asesor cuando el cliente ya dio los datos o pide asesor.

Podés usarlo en **Dashboard → Flor IA → Configuración → Prompt General**: pegá `docs/flor-prompt-v41.txt` y guardá.

Para actualizar Supabase desde terminal: `node scripts/update-flor-prompt-supabase.js`
