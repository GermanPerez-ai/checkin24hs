-- Rellenar real_phone en whatsapp_chats desde whatsapp_messages
-- Útil cuando el chat tiene phone = LID (ej. 95283883040898) pero en mensajes sí está el número real.
-- Ejecutar en Supabase → SQL Editor.

UPDATE whatsapp_chats c
SET real_phone = TRIM(BOTH FROM sub.phone),
    updated_at = NOW()
FROM (
    SELECT DISTINCT ON (m.chat_id) m.chat_id,
        TRIM(BOTH FROM m.phone) AS phone
    FROM whatsapp_messages m
    WHERE m.phone ~ '^\+?[0-9]{10,15}$' AND m.phone NOT LIKE '%@%'
    ORDER BY m.chat_id, m.created_at DESC NULLS LAST
) sub
WHERE c.id = sub.chat_id
  AND (c.real_phone IS NULL OR c.real_phone = '')
  AND sub.phone IS NOT NULL;

-- Ver cuántos chats quedaron con real_phone rellenado:
-- SELECT id, name, phone, real_phone FROM whatsapp_chats ORDER BY last_message_time DESC NULLS LAST LIMIT 20;
