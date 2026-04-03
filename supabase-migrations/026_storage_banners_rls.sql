-- ============================================
-- Políticas RLS para bucket Storage "banners"
-- ============================================
-- Sin estas políticas, la subida desde el Dashboard falla con:
-- "new row violates row-level security policy"
--
-- Ejecutar en Supabase: SQL Editor → New query → pegar y Run.
-- El bucket "banners" debe existir antes (Storage → New bucket → banners, Public).

DROP POLICY IF EXISTS "banners allow anon insert" ON storage.objects;
DROP POLICY IF EXISTS "banners allow anon select" ON storage.objects;
DROP POLICY IF EXISTS "banners allow anon update" ON storage.objects;
DROP POLICY IF EXISTS "banners allow anon delete" ON storage.objects;

-- Permitir a anon INSERTAR (subir) en el bucket banners
CREATE POLICY "banners allow anon insert"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'banners'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'banners' LIMIT 1)
);

-- Permitir a anon LEER (URLs públicas para la web)
CREATE POLICY "banners allow anon select"
ON storage.objects
FOR SELECT
TO anon
USING (
  bucket_id = 'banners'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'banners' LIMIT 1)
);

-- Permitir a anon ACTUALIZAR (upsert)
CREATE POLICY "banners allow anon update"
ON storage.objects
FOR UPDATE
TO anon
USING (
  bucket_id = 'banners'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'banners' LIMIT 1)
)
WITH CHECK (
  bucket_id = 'banners'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'banners' LIMIT 1)
);

-- Permitir a anon ELIMINAR (desde el Dashboard)
CREATE POLICY "banners allow anon delete"
ON storage.objects
FOR DELETE
TO anon
USING (
  bucket_id = 'banners'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'banners' LIMIT 1)
);
