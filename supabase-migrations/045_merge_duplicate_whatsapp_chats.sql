-- ============================================
-- Fusionar chats WhatsApp duplicados (mismo móvil, distinto phone/LID en whatsapp_chats)
-- Ejecutar en Supabase SQL Editor (revisar el SELECT de vista previa antes del COMMIT)
-- ============================================

-- Vista previa: cuántos duplicados hay (ejecutar solo esto primero)
-- WITH keys AS (
--   SELECT
--     id,
--     whatsapp_instance,
--     COALESCE(
--       NULLIF(REGEXP_REPLACE(real_phone, '[^0-9]', '', 'g'), ''),
--       CASE WHEN phone NOT LIKE '%@%' AND phone NOT LIKE '%lid%'
--         THEN NULLIF(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), '')
--         ELSE NULL END
--     ) AS phone_digits,
--     last_message_time,
--     name,
--     phone,
--     real_phone
--   FROM whatsapp_chats
--   WHERE COALESCE(channel, 'whatsapp') = 'whatsapp'
-- )
-- SELECT phone_digits, whatsapp_instance, COUNT(*) AS cnt,
--        ARRAY_AGG(id::text ORDER BY last_message_time DESC NULLS LAST) AS chat_ids
-- FROM keys
-- WHERE phone_digits IS NOT NULL
--   AND LENGTH(phone_digits) BETWEEN 10 AND 13
--   AND phone_digits NOT LIKE '133%'
--   AND phone_digits NOT LIKE '125%'
--   AND phone_digits NOT LIKE '382%'
-- GROUP BY phone_digits, whatsapp_instance
-- HAVING COUNT(*) > 1
-- ORDER BY cnt DESC;

BEGIN;

CREATE INDEX IF NOT EXISTS idx_whatsapp_chats_real_phone_instance
  ON whatsapp_chats (real_phone, whatsapp_instance);

CREATE TEMP TABLE chat_merge_map ON COMMIT DROP AS
WITH keys AS (
  SELECT
    id,
    whatsapp_instance,
    COALESCE(
      NULLIF(REGEXP_REPLACE(real_phone, '[^0-9]', '', 'g'), ''),
      CASE WHEN phone NOT LIKE '%@%' AND phone NOT LIKE '%lid%'
        THEN NULLIF(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), '')
        ELSE NULL END
    ) AS phone_digits,
    last_message_time,
    created_at,
    real_phone
  FROM whatsapp_chats
  WHERE COALESCE(channel, 'whatsapp') = 'whatsapp'
),
ranked AS (
  SELECT
    id,
    phone_digits,
    whatsapp_instance,
    ROW_NUMBER() OVER (
      PARTITION BY phone_digits, whatsapp_instance
      ORDER BY
        CASE WHEN real_phone IS NOT NULL AND LENGTH(REGEXP_REPLACE(real_phone, '[^0-9]', '', 'g')) BETWEEN 10 AND 13 THEN 0 ELSE 1 END,
        last_message_time DESC NULLS LAST,
        created_at DESC NULLS LAST
    ) AS rn
  FROM keys
  WHERE phone_digits IS NOT NULL
    AND LENGTH(phone_digits) BETWEEN 10 AND 13
    AND phone_digits NOT LIKE '133%'
    AND phone_digits NOT LIKE '125%'
    AND phone_digits NOT LIKE '382%'
),
keepers AS (
  SELECT id AS keep_id, phone_digits, whatsapp_instance FROM ranked WHERE rn = 1
)
SELECT r.id AS dup_id, k.keep_id
FROM ranked r
JOIN keepers k
  ON r.phone_digits = k.phone_digits AND r.whatsapp_instance = k.whatsapp_instance
WHERE r.rn > 1;

-- Mover mensajes al chat que se conserva
UPDATE whatsapp_messages m
SET chat_id = cm.keep_id
FROM chat_merge_map cm
WHERE m.chat_id = cm.dup_id;

-- conversation_id (si existe en el esquema)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'conversation_id'
  ) THEN
    UPDATE whatsapp_messages m
    SET conversation_id = cm.keep_id
    FROM chat_merge_map cm
    WHERE m.conversation_id = cm.dup_id;
  END IF;
END $$;

-- Sumar no leídos al chat conservado
UPDATE whatsapp_chats k
SET unread_count = COALESCE(k.unread_count, 0) + sub.extra_unread
FROM (
  SELECT cm.keep_id, SUM(COALESCE(c.unread_count, 0)) AS extra_unread
  FROM chat_merge_map cm
  JOIN whatsapp_chats c ON c.id = cm.dup_id
  GROUP BY cm.keep_id
) sub
WHERE k.id = sub.keep_id;

-- Eliminar filas duplicadas
DELETE FROM whatsapp_chats c
USING chat_merge_map cm
WHERE c.id = cm.dup_id;

COMMIT;

-- Verificación posterior:
-- SELECT COUNT(*) FROM whatsapp_chats WHERE COALESCE(channel,'whatsapp') = 'whatsapp';
