-- Contador de visitas web (para digest diario por WhatsApp)
-- Alternativa simple a GA4: primera persona, datos en tu Supabase.

CREATE TABLE IF NOT EXISTS public.site_pageviews (
  id bigserial PRIMARY KEY,
  visitor_id text NOT NULL,
  path text,
  referrer text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS site_pageviews_created_at_idx ON public.site_pageviews (created_at DESC);
CREATE INDEX IF NOT EXISTS site_pageviews_visitor_day_idx ON public.site_pageviews (created_at, visitor_id);

ALTER TABLE public.site_pageviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_insert_site_pageviews" ON public.site_pageviews;
CREATE POLICY "anon_insert_site_pageviews"
  ON public.site_pageviews
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    visitor_id IS NOT NULL
    AND length(visitor_id) >= 8
    AND length(visitor_id) <= 80
  );

-- Nadie lee filas crudas con anon (solo la función de stats)
DROP POLICY IF EXISTS "no_select_site_pageviews" ON public.site_pageviews;

CREATE OR REPLACE FUNCTION public.site_visit_stats(
  p_from timestamptz,
  p_to timestamptz
)
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT json_build_object(
    'pageviews', (SELECT count(*)::int FROM site_pageviews WHERE created_at >= p_from AND created_at < p_to),
    'visitors', (SELECT count(DISTINCT visitor_id)::int FROM site_pageviews WHERE created_at >= p_from AND created_at < p_to)
  );
$$;

REVOKE ALL ON FUNCTION public.site_visit_stats(timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.site_visit_stats(timestamptz, timestamptz) TO anon, authenticated;

COMMENT ON TABLE public.site_pageviews IS 'Pageviews web www — visitor_id anónimo (cookie local). Digest WhatsApp usa site_visit_stats.';

GRANT INSERT ON public.site_pageviews TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.site_pageviews_id_seq TO anon, authenticated;
