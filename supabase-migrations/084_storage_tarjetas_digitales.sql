-- ============================================
-- Storage bucket "tarjetas-digitales" para avatares
-- ============================================
-- Si el INSERT falla, creá el bucket a mano:
-- Storage → New bucket → nombre "tarjetas-digitales" → Public → Create.
-- Luego ejecutá solo las políticas de abajo.

INSERT INTO storage.buckets (id, name, public)
SELECT 'tarjetas-digitales', 'tarjetas-digitales', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'tarjetas-digitales');

DROP POLICY IF EXISTS "tarjetas-digitales allow anon insert" ON storage.objects;
DROP POLICY IF EXISTS "tarjetas-digitales allow anon select" ON storage.objects;
DROP POLICY IF EXISTS "tarjetas-digitales allow anon update" ON storage.objects;
DROP POLICY IF EXISTS "tarjetas-digitales allow anon delete" ON storage.objects;

CREATE POLICY "tarjetas-digitales allow anon insert"
ON storage.objects FOR INSERT TO anon
WITH CHECK (
  bucket_id = 'tarjetas-digitales'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'tarjetas-digitales' LIMIT 1)
);

CREATE POLICY "tarjetas-digitales allow anon select"
ON storage.objects FOR SELECT TO anon
USING (
  bucket_id = 'tarjetas-digitales'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'tarjetas-digitales' LIMIT 1)
);

CREATE POLICY "tarjetas-digitales allow anon update"
ON storage.objects FOR UPDATE TO anon
USING (
  bucket_id = 'tarjetas-digitales'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'tarjetas-digitales' LIMIT 1)
)
WITH CHECK (
  bucket_id = 'tarjetas-digitales'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'tarjetas-digitales' LIMIT 1)
);

CREATE POLICY "tarjetas-digitales allow anon delete"
ON storage.objects FOR DELETE TO anon
USING (
  bucket_id = 'tarjetas-digitales'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'tarjetas-digitales' LIMIT 1)
);
