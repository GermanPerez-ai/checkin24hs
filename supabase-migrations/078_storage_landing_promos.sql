-- Bucket Storage para imágenes de landings /promo/:slug
-- Ejecutar en Supabase SQL Editor (o crear el bucket a mano: Storage → New → landing-promos → Public).

INSERT INTO storage.buckets (name, public)
SELECT 'landing-promos', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'landing-promos');

DROP POLICY IF EXISTS "landing_promos allow anon insert" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow anon select" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow anon update" ON storage.objects;
DROP POLICY IF EXISTS "landing_promos allow anon delete" ON storage.objects;

CREATE POLICY "landing_promos allow anon insert"
ON storage.objects FOR INSERT TO anon
WITH CHECK (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);

CREATE POLICY "landing_promos allow anon select"
ON storage.objects FOR SELECT TO anon
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);

CREATE POLICY "landing_promos allow anon update"
ON storage.objects FOR UPDATE TO anon
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
)
WITH CHECK (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);

CREATE POLICY "landing_promos allow anon delete"
ON storage.objects FOR DELETE TO anon
USING (
  bucket_id = 'landing-promos'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'landing-promos' LIMIT 1)
);
