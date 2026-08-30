-- Storage landing-promos: permitir también rol authenticated
-- (el dashboard manda JWT de sesión; las policies viejas solo cubrían anon)

DROP POLICY IF EXISTS "landing_promos allow authenticated insert" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow authenticated select" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow authenticated update" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow authenticated delete" ON storage.objects;

CREATE POLICY "landing_promos allow authenticated insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id::text FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);

CREATE POLICY "landing_promos allow authenticated select"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id::text FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);

CREATE POLICY "landing_promos allow authenticated update"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id::text FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
)
WITH CHECK (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id::text FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);

CREATE POLICY "landing_promos allow authenticated delete"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id::text FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);

-- Asegurar bucket público con id = name (evita mismatch UUID vs 'landing-promos')
INSERT INTO storage.buckets (id, name, public)
VALUES ('landing-promos', 'landing-promos', true)
ON CONFLICT (id) DO UPDATE SET public = true, name = EXCLUDED.name;
