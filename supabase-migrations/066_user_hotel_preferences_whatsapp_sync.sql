-- Sync WhatsApp → Usuarios + historial de hoteles de interés (perfil de preferencias)
-- Ejecutar en Supabase SQL Editor.

-- 1) Columnas útiles en users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS last_activity timestamptz;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS last_hotel_id uuid REFERENCES public.hotels(id) ON DELETE SET NULL;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS whatsapp_instance integer;

COMMENT ON COLUMN public.users.last_hotel_id IS
  'Último hotel consultado por WhatsApp/Flor (atajo para listado Usuarios).';

-- Permitir email null si hoy es NOT NULL (usuarios solo-teléfono de WhatsApp)
DO $$
BEGIN
  BEGIN
    ALTER TABLE public.users ALTER COLUMN email DROP NOT NULL;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'email ya nullable o no se pudo alterar: %', SQLERRM;
  END;
END $$;

-- 2) Historial / perfil de preferencias (varios hoteles en el tiempo)
CREATE TABLE IF NOT EXISTS public.user_hotel_interests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  hotel_id uuid NOT NULL REFERENCES public.hotels(id) ON DELETE CASCADE,
  phone text,
  whatsapp_instance integer,
  source text NOT NULL DEFAULT 'whatsapp',
  interest_count integer NOT NULL DEFAULT 1,
  first_interest_at timestamptz NOT NULL DEFAULT now(),
  last_interest_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, hotel_id)
);

CREATE INDEX IF NOT EXISTS idx_user_hotel_interests_user
  ON public.user_hotel_interests (user_id);

CREATE INDEX IF NOT EXISTS idx_user_hotel_interests_hotel
  ON public.user_hotel_interests (hotel_id);

CREATE INDEX IF NOT EXISTS idx_user_hotel_interests_last
  ON public.user_hotel_interests (last_interest_at DESC);

COMMENT ON TABLE public.user_hotel_interests IS
  'Perfil de preferencias: cada hotel que el contacto consultó (acumula count + fechas).';

ALTER TABLE public.user_hotel_interests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "permitir_todo_user_hotel_interests" ON public.user_hotel_interests;
CREATE POLICY "permitir_todo_user_hotel_interests"
  ON public.user_hotel_interests FOR ALL
  USING (true) WITH CHECK (true);

-- 3) Vista cómoda para el dashboard
CREATE OR REPLACE VIEW public.user_hotel_preferences_view AS
SELECT
  i.user_id,
  i.hotel_id,
  i.phone,
  i.interest_count,
  i.first_interest_at,
  i.last_interest_at,
  i.source,
  i.whatsapp_instance,
  COALESCE(h.name, 'Hotel') AS hotel_name
FROM public.user_hotel_interests i
LEFT JOIN public.hotels h ON h.id = i.hotel_id;

GRANT SELECT ON public.user_hotel_preferences_view TO anon, authenticated;

-- Upsert de interés (idempotente por user+hotel)
CREATE OR REPLACE FUNCTION public.record_user_hotel_interest(
  p_user_id uuid,
  p_hotel_id uuid,
  p_phone text DEFAULT NULL,
  p_instance integer DEFAULT NULL,
  p_source text DEFAULT 'whatsapp'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS NULL OR p_hotel_id IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO user_hotel_interests (
    user_id, hotel_id, phone, whatsapp_instance, source,
    interest_count, first_interest_at, last_interest_at
  ) VALUES (
    p_user_id, p_hotel_id, p_phone, p_instance, COALESCE(p_source, 'whatsapp'),
    1, now(), now()
  )
  ON CONFLICT (user_id, hotel_id) DO UPDATE SET
    interest_count = user_hotel_interests.interest_count + 1,
    last_interest_at = now(),
    phone = COALESCE(EXCLUDED.phone, user_hotel_interests.phone),
    whatsapp_instance = COALESCE(EXCLUDED.whatsapp_instance, user_hotel_interests.whatsapp_instance),
    source = COALESCE(EXCLUDED.source, user_hotel_interests.source);

  UPDATE users
  SET last_hotel_id = p_hotel_id,
      last_activity = now(),
      updated_at = now(),
      whatsapp_instance = COALESCE(p_instance, whatsapp_instance)
  WHERE id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.record_user_hotel_interest(uuid, uuid, text, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_user_hotel_interest(uuid, uuid, text, integer, text) TO anon, authenticated;
