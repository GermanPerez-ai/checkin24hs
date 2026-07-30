# Flor IA Prompt V4.0 — Cotización a Medida

Texto para **Supabase** (`system_config` → `flor_general_config` → `promptGeneral`).

Archivos:
- `docs/flor-prompt-v40.txt`
- `supabase-migrations/060_flor_prompt_v40_cotizacion_a_medida.sql`
- Script: `node scripts/update-flor-prompt-supabase.js`

## Cambio clave vs V3.6

Ante precios/tarifas: **no** enviar link de cotizador ni PDFs. Pedir fechas, noches, huéspedes y edades; luego hand-off a asesor.
