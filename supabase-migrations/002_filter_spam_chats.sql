-- ============================================
-- FILTRO DE SPAM PARA CHATS DE WHATSAPP
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- Opción 1: Crear una función que identifique si un chat es spam
CREATE OR REPLACE FUNCTION is_spam_chat(phone_text TEXT, name_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Patrones de spam conocidos
    RETURN (
        phone_text LIKE '%status@broadcast%' OR
        phone_text LIKE '%broadcast%' OR
        phone_text LIKE '%status.broadcast%' OR
        phone_text LIKE '%@lid%' OR
        phone_text LIKE '%@newsletter%' OR
        phone_text LIKE '%@g.us%' OR
        name_text LIKE '%status@broadcast%' OR
        name_text LIKE '%broadcast%' OR
        name_text LIKE '%status.broadcast%'
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Opción 2: Crear una vista que excluya automáticamente los chats spam
CREATE OR REPLACE VIEW whatsapp_chats_filtered AS
SELECT *
FROM whatsapp_chats
WHERE NOT is_spam_chat(phone, COALESCE(name, ''))
ORDER BY last_message_time DESC NULLS LAST;

-- Opción 3: Agregar una columna 'is_spam' a la tabla (opcional, para marcar spam)
-- Descomentar si quieres marcar los chats como spam en lugar de solo filtrarlos
/*
ALTER TABLE whatsapp_chats 
ADD COLUMN IF NOT EXISTS is_spam BOOLEAN DEFAULT FALSE;

-- Marcar chats existentes como spam
UPDATE whatsapp_chats
SET is_spam = TRUE
WHERE is_spam_chat(phone, COALESCE(name, ''));

-- Crear índice para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_whatsapp_chats_is_spam ON whatsapp_chats(is_spam);
*/

-- Opción 4: Función para eliminar chats spam (¡CUIDADO! Elimina permanentemente)
-- Descomentar solo si estás seguro de querer eliminar los chats spam
/*
CREATE OR REPLACE FUNCTION delete_spam_chats()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM whatsapp_chats
    WHERE is_spam_chat(phone, COALESCE(name, ''));
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Para ejecutar la eliminación:
-- SELECT delete_spam_chats();
*/

-- Verificar cuántos chats spam hay
SELECT 
    COUNT(*) as total_chats,
    COUNT(*) FILTER (WHERE is_spam_chat(phone, COALESCE(name, ''))) as spam_chats,
    COUNT(*) FILTER (WHERE NOT is_spam_chat(phone, COALESCE(name, ''))) as valid_chats
FROM whatsapp_chats;

-- Ver ejemplos de chats spam
SELECT id, phone, name, last_message_time
FROM whatsapp_chats
WHERE is_spam_chat(phone, COALESCE(name, ''))
ORDER BY last_message_time DESC
LIMIT 10;


