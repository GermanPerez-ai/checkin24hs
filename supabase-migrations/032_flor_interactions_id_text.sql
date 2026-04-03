-- Asegurar que flor_interactions.id sea TEXT (acepta cualquier string, p. ej. UUID o interaction_xxx).
-- Si en tu proyecto la columna se creó como UUID, este script la pasa a TEXT para compatibilidad con el cliente.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'flor_interactions' AND column_name = 'id'
    AND data_type = 'uuid'
  ) THEN
    ALTER TABLE public.flor_interactions ALTER COLUMN id TYPE TEXT USING id::text;
  END IF;
END $$;
