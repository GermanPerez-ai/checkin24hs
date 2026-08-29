-- Bucket Storage "landing-promos" (imágenes hero de /promo/:slug)
--
-- RECOMENDADO si el INSERT falla:
--   1) Storage → New bucket → Name: landing-promos → Public → Create
--   2) Ejecutá solo desde "DROP POLICY" hacia abajo.

INSERT INTO storage.buckets (id, name, public)
SELECT gen_random_uuid(), 'landing-promos', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'landing-promos');

DROP POLICY IF EXISTS "landing_promos allow anon insert" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow anon select" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow anon update" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow anon delete" ON storage.objects;

CREATE POLICY "landing_promos allow anon insert"
ON storage.objects FOR INSERT TO anon
WITH CHECK (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)::text
);

CREATE POLICY "landing_promos allow anon select"
ON storage.objects FOR SELECT TO anon
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)::text
);

CREATE POLICY "landing_promos allow anon update"
ON storage.objects FOR UPDATE TO anon
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)::text
)
WITH CHECK (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)::text
);

CREATE POLICY "landing_promos allow anon delete"
ON storage.objects FOR DELETE TO anon
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)::text
);
