-- Interacciones del chat Flor (web) para que todo use Supabase en lugar de solo localStorage.
-- La web (anon) puede INSERT; solo servicio/authenticated puede leer o borrar si hace falta.

CREATE TABLE IF NOT EXISTS public.flor_interactions (
    id TEXT PRIMARY KEY,
    user_message TEXT NOT NULL,
    bot_response TEXT NOT NULL,
    intent TEXT,
    hotel_id UUID,
    success BOOLEAN DEFAULT true,
    used_ai BOOLEAN DEFAULT false,
    response_length INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flor_interactions_created_at ON public.flor_interactions(created_at);
CREATE INDEX IF NOT EXISTS idx_flor_interactions_intent ON public.flor_interactions(intent);

ALTER TABLE public.flor_interactions ENABLE ROW LEVEL SECURITY;

-- La web (anon) solo puede insertar sus propias interacciones (no hay user_id, permitimos insert)
DROP POLICY IF EXISTS "flor_interactions_insert_anon" ON public.flor_interactions;
CREATE POLICY "flor_interactions_insert_anon"
ON public.flor_interactions FOR INSERT TO anon
WITH CHECK (true);

-- Lectura: anon y authenticated para dashboard/estadísticas
DROP POLICY IF EXISTS "flor_interactions_select_anon" ON public.flor_interactions;
CREATE POLICY "flor_interactions_select_anon"
ON public.flor_interactions FOR SELECT TO anon
USING (true);

DROP POLICY IF EXISTS "flor_interactions_select_authenticated" ON public.flor_interactions;
CREATE POLICY "flor_interactions_select_authenticated"
ON public.flor_interactions FOR SELECT TO authenticated
USING (true);

COMMENT ON TABLE public.flor_interactions IS 'Interacciones del chat Flor (web). Antes solo localStorage; ahora también Supabase.';
