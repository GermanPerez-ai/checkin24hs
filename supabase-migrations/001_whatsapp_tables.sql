-- ============================================
-- TABLAS PARA WHATSAPP - FLOR IA
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- Tabla de chats de WhatsApp (conversaciones)
CREATE TABLE IF NOT EXISTS whatsapp_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(50) NOT NULL,
    name VARCHAR(255),
    last_message TEXT,
    last_message_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    unread_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active', -- active, archived, blocked
    whatsapp_instance INTEGER DEFAULT 1, -- 1, 2, 3, 4 para las diferentes conexiones
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Referencia al usuario si existe
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de mensajes de WhatsApp
CREATE TABLE IF NOT EXISTS whatsapp_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES whatsapp_chats(id) ON DELETE CASCADE,
    phone VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text', -- text, image, audio, video, document
    media_url TEXT,
    is_from_me BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    whatsapp_instance INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de interacciones para aprendizaje de Flor
CREATE TABLE IF NOT EXISTS flor_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(50) NOT NULL,
    user_message TEXT NOT NULL,
    bot_response TEXT NOT NULL,
    intent VARCHAR(100), -- consulta_hotel, reserva, precio, saludo, etc.
    success BOOLEAN DEFAULT true,
    used_ai BOOLEAN DEFAULT false, -- Si usó Gemini o respuesta predefinida
    ai_model VARCHAR(50), -- gemini-1.5-flash, etc.
    hotel_id UUID REFERENCES hotels(id) ON DELETE SET NULL,
    feedback_rating INTEGER, -- 1-5 rating si el usuario da feedback
    response_time_ms INTEGER, -- Tiempo de respuesta en milisegundos
    whatsapp_instance INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_whatsapp_chats_phone ON whatsapp_chats(phone);
CREATE INDEX IF NOT EXISTS idx_whatsapp_chats_user_id ON whatsapp_chats(user_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_chat_id ON whatsapp_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_phone ON whatsapp_messages(phone);
CREATE INDEX IF NOT EXISTS idx_flor_interactions_phone ON flor_interactions(phone);
CREATE INDEX IF NOT EXISTS idx_flor_interactions_intent ON flor_interactions(intent);
CREATE INDEX IF NOT EXISTS idx_flor_interactions_created ON flor_interactions(created_at);

-- Habilitar Row Level Security
ALTER TABLE whatsapp_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE flor_interactions ENABLE ROW LEVEL SECURITY;

-- Políticas de acceso (permitir todo para el anon key - ajustar según necesidad)
CREATE POLICY "Permitir todo en whatsapp_chats" ON whatsapp_chats FOR ALL USING (true);
CREATE POLICY "Permitir todo en whatsapp_messages" ON whatsapp_messages FOR ALL USING (true);
CREATE POLICY "Permitir todo en flor_interactions" ON flor_interactions FOR ALL USING (true);

-- Vista para estadísticas de Flor
CREATE OR REPLACE VIEW flor_stats AS
SELECT 
    DATE(created_at) as fecha,
    COUNT(*) as total_interacciones,
    COUNT(DISTINCT phone) as usuarios_unicos,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as exitosas,
    SUM(CASE WHEN used_ai THEN 1 ELSE 0 END) as con_ia,
    AVG(response_time_ms) as tiempo_respuesta_promedio
FROM flor_interactions
GROUP BY DATE(created_at)
ORDER BY fecha DESC;

-- Vista para intents más comunes
CREATE OR REPLACE VIEW flor_intents AS
SELECT 
    intent,
    COUNT(*) as total,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as exitosos,
    ROUND(100.0 * SUM(CASE WHEN success THEN 1 ELSE 0 END) / COUNT(*), 1) as tasa_exito
FROM flor_interactions
WHERE intent IS NOT NULL
GROUP BY intent
ORDER BY total DESC;

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_whatsapp_chats_updated_at BEFORE UPDATE ON whatsapp_chats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


