-- Asegurar que flor_interactions tenga response_length (por si la tabla se creó sin ella).
-- Así el JS antiguo (flor-learning-system.js que envía response_length) deja de dar 400.
-- Idempotente: no falla si la columna ya existe.

ALTER TABLE public.flor_interactions
ADD COLUMN IF NOT EXISTS response_length INTEGER;

COMMENT ON COLUMN public.flor_interactions.response_length IS 'Longitud de bot_response; opcional, para compatibilidad con cliente antiguo.';
