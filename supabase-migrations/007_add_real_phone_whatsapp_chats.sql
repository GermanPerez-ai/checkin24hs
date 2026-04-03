-- Número de teléfono real para mostrar en el dashboard (cuando el chat se creó con LID)
-- Ejecutar en Supabase SQL Editor

ALTER TABLE whatsapp_chats
ADD COLUMN IF NOT EXISTS real_phone VARCHAR(50);

COMMENT ON COLUMN whatsapp_chats.real_phone IS 'Número real del contacto (ej. +5492944535477). Cuando el chat viene por LID, el servidor lo resuelve y guarda aquí para mostrarlo en el dashboard.';

-- Opcional: rellenar real_phone desde el último mensaje del chat cuando phone en el mensaje parece número real
-- (Útil si ya tenés mensajes guardados con el número real y el chat tiene LID en phone.)
-- Descomentar y ejecutar en Supabase SQL Editor si aplica:
/*
UPDATE whatsapp_chats c
SET real_phone = sub.phone
FROM (
    SELECT DISTINCT ON (m.chat_id) m.chat_id,
        TRIM(BOTH FROM m.phone) AS phone
    FROM whatsapp_messages m
    WHERE m.phone ~ '^\+?[0-9]{10,15}$' AND m.phone NOT LIKE '%@%'
    ORDER BY m.chat_id, m.created_at DESC NULLS LAST
) sub
WHERE c.id = sub.chat_id AND (c.real_phone IS NULL OR c.real_phone = '') AND sub.phone IS NOT NULL;
*/
