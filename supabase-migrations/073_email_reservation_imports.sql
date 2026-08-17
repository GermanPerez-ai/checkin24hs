-- Tracking de mails de reserva ya procesados (evita duplicados)
-- Ejecutar en Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS public.email_reservation_imports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id TEXT NOT NULL,
    reservation_code TEXT,
    hotel_key TEXT NOT NULL DEFAULT 'huilo',
    subject TEXT,
    from_addr TEXT,
    status TEXT NOT NULL DEFAULT 'imported'
        CHECK (status IN ('imported', 'skipped', 'error')),
    error_detail TEXT,
    processed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_email_reservation_imports_message_id
    ON public.email_reservation_imports (message_id);

CREATE INDEX IF NOT EXISTS idx_email_reservation_imports_code
    ON public.email_reservation_imports (reservation_code);

ALTER TABLE public.email_reservation_imports ENABLE ROW LEVEL SECURITY;

-- El sync en el servidor usa service_role o anon con políticas (mismo patrón que otras tablas ops)
DROP POLICY IF EXISTS "email_imports_all_anon" ON public.email_reservation_imports;
CREATE POLICY "email_imports_all_anon"
ON public.email_reservation_imports FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "email_imports_all_authenticated" ON public.email_reservation_imports;
CREATE POLICY "email_imports_all_authenticated"
ON public.email_reservation_imports FOR ALL TO authenticated USING (true) WITH CHECK (true);

COMMENT ON TABLE public.email_reservation_imports IS
  'Mails de confirmación ya leídos (IMAP reservas@). Evita reimportar.';
