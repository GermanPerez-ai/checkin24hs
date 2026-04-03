-- ============================================
-- CONSULTAR CONEXIONES ACTIVAS DE WHATSAPP
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- Ver todas las conexiones de WhatsApp
SELECT 
    card_number AS "Número",
    status AS "Estado",
    phone AS "Teléfono",
    name AS "Nombre",
    CASE 
        WHEN connected_at IS NOT NULL THEN connected_at::text
        ELSE '-'
    END AS "Conectado el",
    CASE 
        WHEN updated_at IS NOT NULL THEN updated_at::text
        ELSE '-'
    END AS "Última actualización"
FROM whatsapp_cards
ORDER BY card_number;

-- Resumen de conexiones activas
SELECT 
    COUNT(*) FILTER (WHERE status = 'connected') AS "Conexiones activas",
    COUNT(*) FILTER (WHERE status = 'connecting') AS "Conectando",
    COUNT(*) FILTER (WHERE status = 'disconnected') AS "Desconectadas",
    COUNT(*) AS "Total"
FROM whatsapp_cards;

-- Detalle de conexiones activas solamente
SELECT 
    card_number AS "Número",
    phone AS "Teléfono",
    name AS "Nombre",
    connected_at AS "Conectado el"
FROM whatsapp_cards
WHERE status = 'connected'
ORDER BY card_number;




