-- Unificar saludo de Flor web con WhatsApp: actualizar flor_responses.saludo en system_config.
-- Así la web muestra el mismo saludo que WhatsApp aunque el JS esté en caché (v3.0.1).
-- Ejecutar en Supabase SQL Editor o aplicar como migración.

UPDATE public.system_config
SET value = jsonb_set(
    COALESCE(value::jsonb, '{}'::jsonb),
    '{saludo}',
    to_jsonb('¡Hola! Soy **Flor 🌸**, tu asistente de **Checkin24hs**. Estoy aquí para ayudarte a planificar tu escapada ideal hacia el relax y la naturaleza de la Patagonia. 🏔️✨ ¿Tenés algún hotel en mente (como Puyehue o Huilo Huilo) o te gustaría que te recomiende un refugio mágico para descansar?'::text)
)::text,
    updated_at = NOW()
WHERE key = 'flor_responses';

-- Si no existía la fila flor_responses, crearla solo con el saludo (el resto se puede editar en el Dashboard)
INSERT INTO public.system_config (key, value, updated_at)
SELECT 'flor_responses', '{"saludo": "¡Hola! Soy **Flor 🌸**, tu asistente de **Checkin24hs**. Estoy aquí para ayudarte a planificar tu escapada ideal hacia el relax y la naturaleza de la Patagonia. 🏔️✨ ¿Tenés algún hotel en mente (como Puyehue o Huilo Huilo) o te gustaría que te recomiende un refugio mágico para descansar?"}', NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.system_config WHERE key = 'flor_responses');
