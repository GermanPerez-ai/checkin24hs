-- Eliminar chat(s) sin número real (ej. LAURA VALERIA con solo LID)
-- Ejecutar en Supabase → SQL Editor
-- Los mensajes se borran solos por ON DELETE CASCADE en whatsapp_messages.chat_id

-- Vista previa (ejecutar primero):
-- SELECT id, name, phone, real_phone, last_message_time
-- FROM whatsapp_chats
-- WHERE name ILIKE '%LAURA%VALERIA%'
-- ORDER BY last_message_time DESC;

DELETE FROM whatsapp_chats
WHERE name ILIKE '%LAURA VALERIA%'
  AND (real_phone IS NULL OR TRIM(real_phone) = '')
  AND (
    phone IS NULL
    OR phone LIKE '%@lid%'
    OR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) >= 14
  );

-- Verificación:
-- SELECT id, name, phone, real_phone FROM whatsapp_chats WHERE name ILIKE '%LAURA%';
