-- ============================================
-- Reactivar Hotel Llao Llao (dashboard + web pública)
-- Ejecutar en Supabase: SQL Editor → New query → Run
-- ============================================

UPDATE public.hotels
SET
    status = 'active',
    updated_at = NOW()
WHERE (
    name ILIKE '%llao%llao%'
    OR name ILIKE '%llao llao%'
    OR slug ILIKE '%llao%'
)
AND (
    status IS NULL
    OR status ILIKE 'inactiv%'
    OR status ILIKE 'manten%'
    OR status NOT IN ('active', 'activo', 'Activo')
);

-- Columna is_active (si existe en la tabla)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'hotels'
          AND column_name = 'is_active'
    ) THEN
        UPDATE public.hotels
        SET is_active = true, updated_at = NOW()
        WHERE name ILIKE '%llao%'
           OR slug ILIKE '%llao%';
    END IF;
END $$;

-- Verificación (tu tabla hotels usa "status", no columna is_active)
SELECT id, name, slug, status, updated_at
FROM public.hotels
WHERE name ILIKE '%llao%' OR slug ILIKE '%llao%'
ORDER BY name;
