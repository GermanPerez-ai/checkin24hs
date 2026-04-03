-- Extender tabla hotels con flor_info (una sola fuente de verdad para Flor IA).
-- No se crea tabla duplicada fichas_hoteles; todo vive en hotels.flor_info.
-- Ejecutar en Supabase SQL Editor.

-- Asegurar que hotels tiene columna flor_info (JSONB) para datos de Flor
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS flor_info JSONB DEFAULT '{}';

-- Comentario para documentar la estructura esperada de flor_info (sin duplicar datos):
-- flor_info puede contener:
--   description, services, excursions, prices, policies, transport, contact (existentes)
--   alias_busqueda (text): sinónimos y errores de tipeo, ej. "Puyehue, Guilo, Wilo"
--   narrativa_poetica (text): descripción poética/emocional (o usar description)
--   detalles_programas (jsonb): [{ nombre, incluye, politica_ninos }]
--   servicios_json (jsonb): { wifi: bool, mascotas: text, spa: bool }
--   gastronomia_info (text), tips_agencia (text)
--   img_habitacion, img_spa, img_cuadro_programas (text URLs)
--   pdf_menu_resto, pdf_menu_spa, pdf_programas (text URLs)
--   link_cotizacion (text): siempre https://cotizar.checkin24hs.com/
-- ubicacion_maps: usar columna existente del hotel (google_maps o location) si existe.
