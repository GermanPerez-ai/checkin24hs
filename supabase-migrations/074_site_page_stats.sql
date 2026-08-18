-- Páginas más vistas (dashboard). Resuelve hotel/pack/novedad al nombre.
-- Ejecutar en Supabase SQL Editor (reemplaza la función si ya corriste 074).

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
  WITH raw AS (
    SELECT
      created_at,
      visitor_id,
      session_id,
      utm_source,
      referrer,
      split_part(COALESCE(NULLIF(trim(path), ''), '/'), '?', 1) AS path_clean
    FROM site_pageviews
    WHERE created_at >= p_from AND created_at < p_to
  ),
  named AS (
    SELECT
      r.*,
      CASE
        WHEN r.path_clean ~ '^/hotel/' THEN 'hotel'
        WHEN r.path_clean ~ '^/pack/' THEN 'pack'
        WHEN r.path_clean ~ '^/novedad/' THEN 'novedad'
        ELSE 'page'
      END AS kind,
      CASE
        WHEN r.path_clean ~ '^/hotel/' THEN replace(replace(regexp_replace(r.path_clean, '^/hotel/', ''), '%20', ' '), '+', ' ')
        WHEN r.path_clean ~ '^/pack/' THEN replace(replace(regexp_replace(r.path_clean, '^/pack/', ''), '%20', ' '), '+', ' ')
        WHEN r.path_clean ~ '^/novedad/' THEN replace(replace(regexp_replace(r.path_clean, '^/novedad/', ''), '%20', ' '), '+', ' ')
        ELSE NULL
      END AS slug_key
    FROM raw r
  ),
  labeled AS (
    SELECT
      n.created_at,
      n.visitor_id,
      n.session_id,
      n.utm_source,
      n.referrer,
      n.path_clean AS path,
      CASE
        WHEN n.kind = 'hotel' THEN 'Hotel: ' || COALESCE(NULLIF(trim(h.name), ''), n.slug_key)
        WHEN n.kind = 'pack' THEN 'Pack: ' || COALESCE(NULLIF(trim(hp.name), ''), n.slug_key)
        WHEN n.kind = 'novedad' THEN 'Novedad: ' || COALESCE(NULLIF(trim(nv.titulo), ''), n.slug_key)
        WHEN n.path_clean IN ('/', '') THEN 'Inicio'
        WHEN n.path_clean = '/packs' THEN 'Listado de packs'
        WHEN n.path_clean = '/chile' THEN 'Destinos Chile'
        WHEN n.path_clean = '/argentina' THEN 'Destinos Argentina'
        WHEN n.path_clean = '/internacionales' THEN 'Destinos internacionales'
        ELSE n.path_clean
      END AS label
    FROM named n
    LEFT JOIN hotels h
      ON n.kind = 'hotel'
     AND (
       h.slug = n.slug_key
       OR lower(h.slug) = lower(n.slug_key)
       OR h.id::text = n.slug_key
     )
    LEFT JOIN hotels hp
      ON n.kind = 'pack'
     AND (
       hp.slug = n.slug_key
       OR lower(hp.slug) = lower(n.slug_key)
       OR hp.id::text = n.slug_key
     )
    LEFT JOIN novedades nv
      ON n.kind = 'novedad'
     AND (
       nv.slug = n.slug_key
       OR lower(nv.slug) = lower(n.slug_key)
       OR nv.id::text = n.slug_key
     )
  )
  SELECT json_build_object(
    'pageviews', (SELECT count(*)::int FROM labeled),
    'visitors', (
      SELECT count(DISTINCT COALESCE(NULLIF(visitor_id, ''), session_id))::int
      FROM labeled
      WHERE COALESCE(NULLIF(visitor_id, ''), session_id) IS NOT NULL
    ),
    'top_pages', COALESCE((
      SELECT json_agg(row_to_json(t) ORDER BY t.views DESC)
      FROM (
        SELECT
          label,
          min(path) AS path,
          count(*)::int AS views,
          count(DISTINCT COALESCE(NULLIF(visitor_id, ''), session_id))::int AS visitors
        FROM labeled
        GROUP BY label
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
        FROM labeled
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
          path,
          label,
          COALESCE(NULLIF(trim(utm_source), ''), '') AS utm_source,
          left(COALESCE(referrer, ''), 200) AS referrer
        FROM labeled
        ORDER BY created_at DESC
        LIMIT 80
      ) r
    ), '[]'::json)
  );
$$;

REVOKE ALL ON FUNCTION public.site_page_stats(timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.site_page_stats(timestamptz, timestamptz) TO anon, authenticated;

COMMENT ON FUNCTION public.site_page_stats IS
  'Ranking de páginas www para el dashboard; /hotel y /pack se muestran con el nombre.';
