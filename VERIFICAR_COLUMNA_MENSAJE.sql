-- ============================================
-- VERIFICAR COLUMNA DE MENSAJE
-- ============================================
-- Este script verifica qué columna contiene el texto del mensaje
-- y si tiene valores guardados
-- ============================================

-- 1. Ver todas las columnas de whatsapp_messages
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 2. Verificar si existe columna 'message'
SELECT 
    'COLUMNA MESSAGE' as verificacion,
    COUNT(*) as existe
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'whatsapp_messages'
  AND column_name = 'message';

-- 3. Verificar si existe columna 'body'
SELECT 
    'COLUMNA BODY' as verificacion,
    COUNT(*) as existe
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'whatsapp_messages'
  AND column_name = 'body';

-- 4. Ver valores de la columna 'message' (si existe)
SELECT 
    id,
    conversation_id,
    direction,
    message,
    LEFT(message, 100) as message_preview,
    created_at
FROM whatsapp_messages
WHERE message IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 5. Ver valores de la columna 'body' (si existe)
SELECT 
    id,
    conversation_id,
    direction,
    body,
    LEFT(body, 100) as body_preview,
    created_at
FROM whatsapp_messages
WHERE body IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 6. Contar mensajes con y sin contenido
SELECT 
    'ESTADISTICAS' as seccion,
    COUNT(*) as total_mensajes,
    COUNT(CASE WHEN message IS NOT NULL AND message != '' THEN 1 END) as con_message,
    COUNT(CASE WHEN message IS NULL OR message = '' THEN 1 END) as sin_message,
    COUNT(CASE WHEN body IS NOT NULL AND body != '' THEN 1 END) as con_body,
    COUNT(CASE WHEN body IS NULL OR body = '' THEN 1 END) as sin_body
FROM whatsapp_messages;
