-- ============================================
-- FILTRO DE SPAM PARA CHATS DE WHATSAPP EN SUPABASE
-- Ejecutar este script en Supabase SQL Editor
-- ============================================

-- 1. Crear función para identificar chats spam
CREATE OR REPLACE FUNCTION is_spam_chat(phone_text TEXT, name_text TEXT DEFAULT '')
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        phone_text ILIKE '%status@broadcast%' OR
        phone_text ILIKE '%broadcast%' OR
        phone_text ILIKE '%status.broadcast%' OR
        phone_text ILIKE '%@lid%' OR
        phone_text ILIKE '%@newsletter%' OR
        phone_text ILIKE '%@g.us%' OR
        phone_text ILIKE '%gid%' OR
        phone_text ILIKE '%group%' OR
        phone_text ILIKE '%grupo%' OR
        phone_text ILIKE '%notify%' OR
        phone_text ILIKE '%notification%' OR
        phone_text ILIKE '%system%' OR
        phone_text ILIKE '%server%' OR
        phone_text ILIKE '%bot%' OR
        phone_text ILIKE '%automated%' OR
        phone_text ILIKE '%auto-reply%' OR
        COALESCE(name_text, '') ILIKE '%status@broadcast%' OR
        COALESCE(name_text, '') ILIKE '%broadcast%' OR
        COALESCE(name_text, '') ILIKE '%gid%' OR
        COALESCE(name_text, '') ILIKE '%group%' OR
        COALESCE(name_text, '') ILIKE '%grupo%' OR
        COALESCE(name_text, '') ILIKE '%notify%' OR
        COALESCE(name_text, '') ILIKE '%notification%' OR
        COALESCE(name_text, '') ILIKE '%system%' OR
        COALESCE(name_text, '') ILIKE '%server%' OR
        COALESCE(name_text, '') ILIKE '%bot%' OR
        COALESCE(name_text, '') ILIKE '%automated%' OR
        COALESCE(name_text, '') ILIKE '%auto-reply%'
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2. Crear vista filtrada (recomendado - no modifica datos)
CREATE OR REPLACE VIEW whatsapp_chats_no_spam AS
SELECT *
FROM whatsapp_chats
WHERE NOT is_spam_chat(phone, COALESCE(name, ''))
ORDER BY last_message_time DESC NULLS LAST;

-- 3. Ver estadísticas de spam
SELECT 
    COUNT(*) as total_chats,
    COUNT(*) FILTER (WHERE is_spam_chat(phone, COALESCE(name, ''))) as spam_chats,
    COUNT(*) FILTER (WHERE NOT is_spam_chat(phone, COALESCE(name, ''))) as valid_chats,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_spam_chat(phone, COALESCE(name, ''))) / COUNT(*), 2) as spam_percentage
FROM whatsapp_chats;

-- 4. Ver ejemplos de chats spam (para verificar)
SELECT id, phone, name, last_message, last_message_time
FROM whatsapp_chats
WHERE is_spam_chat(phone, COALESCE(name, ''))
ORDER BY last_message_time DESC
LIMIT 20;

-- 5. OPCIÓN: Marcar chats como spam (agregar columna is_spam)
-- Descomentar si quieres marcar los chats como spam
/*
ALTER TABLE whatsapp_chats 
ADD COLUMN IF NOT EXISTS is_spam BOOLEAN DEFAULT FALSE;

UPDATE whatsapp_chats
SET is_spam = is_spam_chat(phone, COALESCE(name, ''))
WHERE is_spam IS FALSE OR is_spam IS NULL;

CREATE INDEX IF NOT EXISTS idx_whatsapp_chats_is_spam ON whatsapp_chats(is_spam);
*/

-- 6. OPCIÓN: Eliminar chats spam permanentemente (¡CUIDADO!)
-- Descomentar SOLO si estás seguro de querer eliminar los chats spam
/*
-- Primero, eliminar mensajes de chats spam
DELETE FROM whatsapp_messages
WHERE chat_id IN (
    SELECT id FROM whatsapp_chats WHERE is_spam_chat(phone, COALESCE(name, ''))
);

-- Luego, eliminar los chats spam
DELETE FROM whatsapp_chats
WHERE is_spam_chat(phone, COALESCE(name, ''));

-- Verificar cuántos se eliminaron
SELECT COUNT(*) as deleted_chats FROM whatsapp_chats WHERE is_spam_chat(phone, COALESCE(name, ''));
*/

