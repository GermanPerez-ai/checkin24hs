-- ============================================
-- Bucket Storage "novedades" + políticas RLS
-- ============================================
-- Para que el Dashboard pueda subir imágenes miniatura de novedades.
-- Crea el bucket si no existe y luego las políticas.

-- Crear el bucket "novedades" (público) si no existe.
-- En Supabase Cloud el id suele ser UUID; si el INSERT falla, creá el bucket a mano:
-- Storage → New bucket → nombre "novedades" → Public → Create.
INSERT INTO storage.buckets (name, public)
SELECT 'novedades', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'novedades');

DROP POLICY IF EXISTS "novedades allow anon insert" ON storage.objects;
DROP POLICY IF EXISTS "novedades allow anon select" ON storage.objects;
DROP POLICY IF EXISTS "novedades allow anon update" ON storage.objects;
DROP POLICY IF EXISTS "novedades allow anon delete" ON storage.objects;

CREATE POLICY "novedades allow anon insert"
ON storage.objects FOR INSERT TO anon
WITH CHECK (
  bucket_id = 'novedades'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'novedades' LIMIT 1)
);

CREATE POLICY "novedades allow anon select"
ON storage.objects FOR SELECT TO anon
USING (
  bucket_id = 'novedades'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'novedades' LIMIT 1)
);

CREATE POLICY "novedades allow anon update"
ON storage.objects FOR UPDATE TO anon
USING (
  bucket_id = 'novedades'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'novedades' LIMIT 1)
)
WITH CHECK (
  bucket_id = 'novedades'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'novedades' LIMIT 1)
);

CREATE POLICY "novedades allow anon delete"
ON storage.objects FOR DELETE TO anon
USING (
  bucket_id = 'novedades'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'novedades' LIMIT 1)
);
