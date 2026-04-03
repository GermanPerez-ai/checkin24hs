-- ============================================
-- Políticas RLS para bucket Storage "flor-ficha"
-- ============================================
-- Sin estas políticas, la subida desde el Dashboard falla con:
-- "new row violates row-level security policy"
--
-- Ejecutar en Supabase: SQL Editor → New query → pegar y Run.
-- El bucket "flor-ficha" debe existir antes (Storage → New bucket → flor-ficha, Public).
--
-- bucket_id puede ser el nombre 'flor-ficha' o el UUID del bucket según el proyecto.

-- Quitar políticas anteriores si existen (para poder re-ejecutar el script)
DROP POLICY IF EXISTS "flor-ficha allow anon insert" ON storage.objects;
DROP POLICY IF EXISTS "flor-ficha allow anon select" ON storage.objects;
DROP POLICY IF EXISTS "flor-ficha allow anon update" ON storage.objects;
DROP POLICY IF EXISTS "flor-ficha allow anon delete" ON storage.objects;

-- Permitir a cualquiera (anon) INSERTAR (subir) en el bucket flor-ficha
CREATE POLICY "flor-ficha allow anon insert"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'flor-ficha'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'flor-ficha' LIMIT 1)
);

-- Permitir a cualquiera (anon) LEER archivos del bucket (para URLs públicas)
CREATE POLICY "flor-ficha allow anon select"
ON storage.objects
FOR SELECT
TO anon
USING (
  bucket_id = 'flor-ficha'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'flor-ficha' LIMIT 1)
);

-- Permitir a cualquiera (anon) ACTUALIZAR (por si usás upsert)
CREATE POLICY "flor-ficha allow anon update"
ON storage.objects
FOR UPDATE
TO anon
USING (
  bucket_id = 'flor-ficha'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'flor-ficha' LIMIT 1)
)
WITH CHECK (
  bucket_id = 'flor-ficha'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'flor-ficha' LIMIT 1)
);

-- Opcional: permitir DELETE para poder borrar archivos desde el panel
CREATE POLICY "flor-ficha allow anon delete"
ON storage.objects
FOR DELETE
TO anon
USING (
  bucket_id = 'flor-ficha'
  OR bucket_id = (SELECT id FROM storage.buckets WHERE name = 'flor-ficha' LIMIT 1)
);
