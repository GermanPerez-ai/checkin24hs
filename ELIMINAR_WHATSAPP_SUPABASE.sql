-- ============================================
-- ELIMINAR DATOS DE WHATSAPP EN SUPABASE
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- ⚠️ ADVERTENCIA: Esto eliminará TODOS los datos de WhatsApp
-- Asegúrate de hacer un backup antes si necesitas conservar información

-- Opción 1: Eliminar solo los estados de conexión (recomendado)
-- Esto mantiene los mensajes pero resetea las conexiones
UPDATE whatsapp_cards 
SET 
    status = 'disconnected',
    phone = '-',
    name = '-',
    qr = NULL,
    qr_data = NULL,
    connection_id = NULL,
    connected_at = NULL,
    updated_at = NOW();

-- Opción 2: Eliminar completamente los registros de conexión
-- Descomenta las siguientes líneas si quieres eliminar todo:
-- DELETE FROM whatsapp_cards;

-- Opción 3: Eliminar también mensajes y chats (CUIDADO - irreversible)
-- Descomenta si quieres eliminar TODO:
-- DELETE FROM whatsapp_messages;
-- DELETE FROM whatsapp_chats;
-- DELETE FROM whatsapp_cards;

-- Verificar que se eliminó
SELECT 
    card_number AS "Número",
    status AS "Estado",
    phone AS "Teléfono"
FROM whatsapp_cards
ORDER BY card_number;
