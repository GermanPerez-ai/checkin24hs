-- Landing pages de promociones (checkin24hs.com/promo/:slug)
-- Varias promos activas a la vez; contenido editable sin redeploy.

CREATE TABLE IF NOT EXISTS public.landing_promos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL,
  titulo TEXT NOT NULL,
  subtitulo TEXT,
  hotel_nombre TEXT,
  hotel_id UUID REFERENCES public.hotels(id) ON DELETE SET NULL,
  badge TEXT,
  precio_texto TEXT,
  beneficios TEXT,
  cuerpo TEXT,
  imagen_hero TEXT,
  imagen_hero_mobile TEXT,
  cta_whatsapp TEXT NOT NULL DEFAULT 'Consultar por WhatsApp',
  mensaje_whatsapp TEXT,
  vigencia_hasta DATE,
  activo BOOLEAN NOT NULL DEFAULT true,
  orden INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT landing_promos_slug_unique UNIQUE (slug)
);

CREATE INDEX IF NOT EXISTS idx_landing_promos_activo_orden
  ON public.landing_promos (activo, orden ASC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_landing_promos_slug
  ON public.landing_promos (slug);

ALTER TABLE public.landing_promos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "landing_promos_select_public" ON public.landing_promos;
CREATE POLICY "landing_promos_select_public"
ON public.landing_promos FOR SELECT TO anon, authenticated
USING (activo = true);

-- Dashboard (anon key) puede gestionar como novedades/testimonios
DROP POLICY IF EXISTS "landing_promos_all_anon" ON public.landing_promos;
CREATE POLICY "landing_promos_all_anon"
ON public.landing_promos FOR ALL TO anon
USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "landing_promos_all_authenticated" ON public.landing_promos;
CREATE POLICY "landing_promos_all_authenticated"
ON public.landing_promos FOR ALL TO authenticated
USING (true) WITH CHECK (true);

COMMENT ON TABLE public.landing_promos IS
  'Landings de venta /promo/:slug. CTA WhatsApp + captura email (newsletter).';

COMMENT ON COLUMN public.landing_promos.beneficios IS
  'Una ventaja por línea (se muestra como lista).';

COMMENT ON COLUMN public.landing_promos.mensaje_whatsapp IS
  'Texto prellenado en wa.me; si vacío se arma desde titulo/hotel.';

-- Nombre opcional en suscripciones (landings de venta)
ALTER TABLE public.newsletter_subscribers
  ADD COLUMN IF NOT EXISTS nombre TEXT;

-- Ejemplo (desactivable). Cambiá imagen/slug al publicar.
INSERT INTO public.landing_promos (
  slug, titulo, subtitulo, hotel_nombre, badge, precio_texto, beneficios, cuerpo,
  cta_whatsapp, mensaje_whatsapp, activo, orden
) VALUES (
  'ejemplo-termas',
  'Escapada termal con tarifa especial',
  'Reservá con Checkin24hs y te armamos la mejor combinación de fechas y habitación.',
  'Hotel Termas Puyehue Wellness & Spa Resort',
  'Oferta Checkin24hs',
  'Consultá valores actualizados por WhatsApp',
  E'Asesoría personalizada sin compromiso\nMejores fechas según tu viaje\nConfirmación rápida por WhatsApp\nOfertas vigentes del hotel',
  'Dejanos tu consulta y un asesor de Checkin24hs te responde con opciones concretas: fechas, pax y tipo de habitación.',
  'Quiero esta promo por WhatsApp',
  'Hola, vi la promo en checkin24hs.com/promo/ejemplo-termas y quiero más info',
  false,
  0
)
ON CONFLICT (slug) DO NOTHING;
