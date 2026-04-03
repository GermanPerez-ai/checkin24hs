-- ============================================
-- CREAR TABLA whatsapp_cards EN SUPABASE
-- ============================================
-- Ejecuta este SQL en Supabase SQL Editor
-- Ruta: Supabase Dashboard > SQL Editor > New Query

CREATE TABLE IF NOT EXISTS public.whatsapp_cards (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    card_number integer NOT NULL UNIQUE,
    status text DEFAULT 'disconnected',
    phone text DEFAULT '-',
    name text DEFAULT '-',
    qr text,
    qr_data text,
    connection_id text,
    connected_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Crear índice para búsquedas rápidas por número de tarjeta
CREATE INDEX IF NOT EXISTS idx_whatsapp_cards_card_number ON public.whatsapp_cards(card_number);

-- Habilitar Row Level Security (RLS) - opcional
ALTER TABLE public.whatsapp_cards ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura/escritura a usuarios autenticados
-- Ajusta según tus necesidades de seguridad
CREATE POLICY "Allow authenticated users to manage whatsapp_cards"
    ON public.whatsapp_cards
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Política para permitir lectura pública (si es necesario)
-- CREATE POLICY "Allow public read access to whatsapp_cards"
--     ON public.whatsapp_cards
--     FOR SELECT
--     TO anon
--     USING (true);

-- Comentarios para documentación
COMMENT ON TABLE public.whatsapp_cards IS 'Almacena la configuración y estado de las conexiones WhatsApp por tarjeta';
COMMENT ON COLUMN public.whatsapp_cards.card_number IS 'Número de tarjeta WhatsApp (1-4)';
COMMENT ON COLUMN public.whatsapp_cards.status IS 'Estado de conexión: disconnected, connecting, connected';
COMMENT ON COLUMN public.whatsapp_cards.qr IS 'Código QR en formato base64 o URL';
COMMENT ON COLUMN public.whatsapp_cards.connected_at IS 'Fecha y hora de la última conexión exitosa';

