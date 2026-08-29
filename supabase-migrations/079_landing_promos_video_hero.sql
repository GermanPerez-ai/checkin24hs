-- Video de fondo en landings /promo/:slug
ALTER TABLE public.landing_promos
  ADD COLUMN IF NOT EXISTS video_hero TEXT;

COMMENT ON COLUMN public.landing_promos.video_hero IS
  'URL pública MP4/WebM para hero en loop (muted). imagen_hero queda como poster/fallback.';
