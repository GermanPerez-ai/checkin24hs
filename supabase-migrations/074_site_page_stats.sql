-- Páginas más vistas (dashboard). Anon no puede SELECT site_pageviews; usa esta RPC.
-- Ejecutar en Supabase SQL Editor.

CREATE OR REPLACE FUNCTION public.site_page_stats(
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
    'pageviews', (
      SELECT count(*)::int
      FROM site_pageviews
      WHERE created_at >= p_from AND created_at < p_to
    ),
    'visitors', (
      SELECT count(DISTINCT COALESCE(NULLIF(visitor_id, ''), session_id))::int
      FROM site_pageviews
      WHERE created_at >= p_from AND created_at < p_to
        AND COALESCE(NULLIF(visitor_id, ''), session_id) IS NOT NULL
    ),
    'top_pages', COALESCE((
      SELECT json_agg(row_to_json(t) ORDER BY t.views DESC)
      FROM (
        SELECT
          COALESCE(NULLIF(trim(path), ''), '/') AS path,
          count(*)::int AS views,
          count(DISTINCT COALESCE(NULLIF(visitor_id, ''), session_id))::int AS visitors
        FROM site_pageviews
        WHERE created_at >= p_from AND created_at < p_to
        GROUP BY 1
        ORDER BY views DESC
        LIMIT 50
      ) t
    ), '[]'::json),
    'top_utm', COALESCE((
      SELECT json_agg(row_to_json(u) ORDER BY u.hits DESC)
      FROM (
        SELECT
          COALESCE(NULLIF(trim(utm_source), ''), '(directo/sin utm)') AS source,
          count(*)::int AS hits,
          count(DISTINCT COALESCE(NULLIF(visitor_id, ''), session_id))::int AS visitors
        FROM site_pageviews
        WHERE created_at >= p_from AND created_at < p_to
        GROUP BY 1
        ORDER BY hits DESC
        LIMIT 8
      ) u
    ), '[]'::json),
    'recent', COALESCE((
      SELECT json_agg(row_to_json(r))
      FROM (
        SELECT
          created_at,
          COALESCE(NULLIF(trim(path), ''), '/') AS path,
          COALESCE(NULLIF(trim(utm_source), ''), '') AS utm_source,
          left(COALESCE(referrer, ''), 200) AS referrer
        FROM site_pageviews
        WHERE created_at >= p_from AND created_at < p_to
        ORDER BY created_at DESC
        LIMIT 80
      ) r
    ), '[]'::json)
  );
$$;

REVOKE ALL ON FUNCTION public.site_page_stats(timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.site_page_stats(timestamptz, timestamptz) TO anon, authenticated;

COMMENT ON FUNCTION public.site_page_stats IS
  'Ranking de páginas y visitas recientes (www) para el dashboard. Sin IDs de visitante.';
