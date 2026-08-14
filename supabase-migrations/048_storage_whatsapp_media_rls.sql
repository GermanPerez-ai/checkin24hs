-- Bucket público para media de chats WhatsApp (audio, imagen, video, PDF)
-- El servidor Baileys sube archivos; el dashboard los muestra vía media_url.

INSERT INTO storage.buckets (id, name, public)
SELECT 'whatsapp-media', 'whatsapp-media', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'whatsapp-media');

DROP POLICY IF EXISTS "whatsapp_media_public_read" ON storage.objects;
CREATE POLICY "whatsapp_media_public_read"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'whatsapp-media');

DROP POLICY IF EXISTS "whatsapp_media_anon_insert" ON storage.objects;
CREATE POLICY "whatsapp_media_anon_insert"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'whatsapp-media');

DROP POLICY IF EXISTS "whatsapp_media_anon_update" ON storage.objects;
CREATE POLICY "whatsapp_media_anon_update"
ON storage.objects FOR UPDATE TO anon
USING (bucket_id = 'whatsapp-media');
