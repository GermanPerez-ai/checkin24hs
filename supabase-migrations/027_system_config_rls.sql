-- Permitir que el chat de Flor en la web (y el Dashboard) lean la configuración de IA desde system_config.
-- Sin esta política, el iframe del chat (anon) no puede leer flor_ai_config y la IA no se vincula.

CREATE TABLE IF NOT EXISTS public.system_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "system_config_select_anon" ON public.system_config;
CREATE POLICY "system_config_select_anon"
ON public.system_config FOR SELECT TO anon
USING (true);

DROP POLICY IF EXISTS "system_config_select_authenticated" ON public.system_config;
CREATE POLICY "system_config_select_authenticated"
ON public.system_config FOR SELECT TO authenticated
USING (true);

-- Permitir al Dashboard (anon) insertar/actualizar para guardar flor_ai_config, flor_general_config, etc.
DROP POLICY IF EXISTS "system_config_insert_anon" ON public.system_config;
CREATE POLICY "system_config_insert_anon"
ON public.system_config FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "system_config_update_anon" ON public.system_config;
CREATE POLICY "system_config_update_anon"
ON public.system_config FOR UPDATE TO anon USING (true);

COMMENT ON TABLE public.system_config IS 'Configuración global (Flor IA, respuestas, etc.). flor_ai_config = JSON con apiKey, provider, model.';
