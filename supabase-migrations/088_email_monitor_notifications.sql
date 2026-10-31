-- Tabla para tracking de correos ya notificados por WhatsApp
-- Evita enviar duplicados al grupo del equipo

CREATE TABLE IF NOT EXISTS public.email_monitor_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id TEXT NOT NULL,
    from_addr TEXT,
    subject TEXT,
    summary TEXT,
    notified_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'notified'
        CHECK (status IN ('processing', 'notified', 'error', 'skipped')),
    error_detail TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice único por message_id para evitar duplicados
CREATE UNIQUE INDEX IF NOT EXISTS idx_email_monitor_notifications_message_id
    ON public.email_monitor_notifications (message_id);

-- Índice por fecha para queries de auditoría
CREATE INDEX IF NOT EXISTS idx_email_monitor_notifications_notified_at
    ON public.email_monitor_notifications (notified_at DESC);

-- RLS: solo anon y authenticated (el servicio usa service_role o anon con políticas)
ALTER TABLE public.email_monitor_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "email_monitor_all_anon" ON public.email_monitor_notifications;
CREATE POLICY "email_monitor_all_anon"
ON public.email_monitor_notifications FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "email_monitor_all_authenticated" ON public.email_monitor_notifications;
CREATE POLICY "email_monitor_all_authenticated"
ON public.email_monitor_notifications FOR ALL TO authenticated USING (true) WITH CHECK (true);

COMMENT ON TABLE public.email_monitor_notifications IS
  'Correos de reservas ya notificados al grupo de WhatsApp. Evita duplicados.';
