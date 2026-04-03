-- flor_interactions.phone es NOT NULL en migraciones antiguas (001); el JS viejo no envía phone.
-- Default 'web' + permitir NULL para que los inserts sin phone no fallen.

ALTER TABLE public.flor_interactions
ALTER COLUMN phone SET DEFAULT 'web';

ALTER TABLE public.flor_interactions
ALTER COLUMN phone DROP NOT NULL;

COMMENT ON COLUMN public.flor_interactions.phone IS 'Origen: web, número WhatsApp, etc. Default web para visitantes del chat en la web.';
