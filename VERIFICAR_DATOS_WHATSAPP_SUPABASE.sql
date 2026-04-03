-- ============================================
-- VERIFICAR DATOS DE WHATSAPP EN SUPABASE
-- ============================================
-- Este script verifica que los mensajes y conversaciones
-- se estén guardando correctamente en Supabase
-- ============================================

-- ============================================
-- 1. VERIFICAR CONVERSACIONES CREADAS
-- ============================================
SELECT 
    'CONVERSACIONES CREADAS' as seccion,
    COUNT(*) as total_conversaciones
FROM whatsapp_conversations;

-- Ver detalles de las conversaciones
SELECT 
    id,
    external_id as telefono,
    status,
    metadata->>'name' as nombre,
    metadata->>'whatsapp_instance' as instancia,
    created_at,
    updated_at
FROM whatsapp_conversations
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 2. VERIFICAR MENSAJES GUARDADOS
-- ============================================
SELECT 
    'MENSAJES GUARDADOS' as seccion,
    COUNT(*) as total_mensajes,
    COUNT(DISTINCT conversation_id) as conversaciones_con_mensajes,
    COUNT(CASE WHEN direction = 'inbound' THEN 1 END) as mensajes_recibidos,
    COUNT(CASE WHEN direction = 'outbound' THEN 1 END) as mensajes_enviados
FROM whatsapp_messages;

-- Ver últimos mensajes con detalles
SELECT 
    id,
    conversation_id,
    direction,
    sender,
    recipient,
    LEFT(message, 50) as mensaje_preview,
    created_at
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 20;

-- =============================================
-- 3. VERIFICAR RELACIÓN CONVERSACIONES-MENSAJES
-- ============================================
-- Verificar que todos los mensajes tengan una conversación válida
SELECT 
    'VERIFICACIÓN DE INTEGRIDAD' as seccion,
    COUNT(*) as total_mensajes,
    COUNT(DISTINCT m.conversation_id) as conversaciones_referenciadas,
    COUNT(DISTINCT c.id) as conversaciones_existentes,
    COUNT(*) - COUNT(c.id) as mensajes_con_conversacion_inexistente
FROM whatsapp_messages m
LEFT JOIN whatsapp_conversations c ON m.conversation_id = c.id;

-- Mensajes que NO tienen conversación (debería ser 0)
SELECT 
    m.id,
    m.conversation_id,
    m.direction,
    m.sender,
    m.message,
    m.created_at
FROM whatsapp_messages m
LEFT JOIN whatsapp_conversations c ON m.conversation_id = c.id
WHERE c.id IS NULL
LIMIT 10;

-- ============================================
-- 4. ESTADÍSTICAS POR CONVERSACIÓN
-- ============================================
SELECT 
    c.external_id as telefono,
    c.metadata->>'name' as nombre,
    COUNT(m.id) as total_mensajes,
    COUNT(CASE WHEN m.direction = 'inbound' THEN 1 END) as recibidos,
    COUNT(CASE WHEN m.direction = 'outbound' THEN 1 END) as enviados,
    MAX(m.created_at) as ultimo_mensaje
FROM whatsapp_conversations c
LEFT JOIN whatsapp_messages m ON c.id = m.conversation_id
GROUP BY c.id, c.external_id, c.metadata->>'name'
ORDER BY ultimo_mensaje DESC
LIMIT 10;

-- ============================================
-- 5. VERIFICAR COLUMNAS REQUERIDAS
-- ============================================
-- Verificar que no haya mensajes con columnas requeridas nulas
SELECT 
    'MENSAJES CON CAMPOS NULOS' as seccion,
    COUNT(*) as total,
    COUNT(CASE WHEN conversation_id IS NULL THEN 1 END) as sin_conversation_id,
    COUNT(CASE WHEN direction IS NULL THEN 1 END) as sin_direction,
    COUNT(CASE WHEN message IS NULL THEN 1 END) as sin_message,
    COUNT(CASE WHEN sender IS NULL THEN 1 END) as sin_sender,
    COUNT(CASE WHEN recipient IS NULL THEN 1 END) as sin_recipient
FROM whatsapp_messages;

-- ============================================
-- 6. ÚLTIMOS MENSAJES CON CONTEXTO COMPLETO
-- ============================================
SELECT 
    c.external_id as telefono,
    c.metadata->>'name' as nombre_contacto,
    m.direction,
    m.sender,
    m.recipient,
    m.message,
    m.created_at
FROM whatsapp_messages m
JOIN whatsapp_conversations c ON m.conversation_id = c.id
ORDER BY m.created_at DESC
LIMIT 10;
