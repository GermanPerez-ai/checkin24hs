-- Vincular landings web con promociones del dashboard (tabla promotions).
-- Evita huérfanos al renombrar/editar/borrar: se actualiza o desactiva la misma landing.

ALTER TABLE public.landing_promos
  ADD COLUMN IF NOT EXISTS source_promotion_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS idx_landing_promos_source_promotion_id
  ON public.landing_promos (source_promotion_id)
  WHERE source_promotion_id IS NOT NULL;

COMMENT ON COLUMN public.landing_promos.source_promotion_id IS
  'ID de public.promotions cuando la landing se creó desde Hoteles → Promociones.';
