-- Métricas ops completas (puntos 2–8): datos listos, embudo, ticket, origen, picos, abandono, recontactos 7/30
-- Ejecutar en Supabase SQL Editor (después o en lugar de 067: REPLACE de la misma RPC).

-- ─── Columnas de soporte ───────────────────────────────────────────────────
ALTER TABLE public.whatsapp_chats
  ADD COLUMN IF NOT EXISTS travel_data jsonb,
  ADD COLUMN IF NOT EXISTS datos_ready_at timestamptz,
  ADD COLUMN IF NOT EXISTS asked_travel_data_at timestamptz,
  ADD COLUMN IF NOT EXISTS handoff_at timestamptz,
  ADD COLUMN IF NOT EXISTS prompt_variant text DEFAULT 'v4.2',
  ADD COLUMN IF NOT EXISTS lead_origin text;

COMMENT ON COLUMN public.whatsapp_chats.travel_data IS
  'JSON: check_in, check_out, nights, adults, children, children_ages — datos de viaje detectados.';
COMMENT ON COLUMN public.whatsapp_chats.datos_ready_at IS
  'Primera vez que el chat tuvo fechas/noches/pax suficientes para cotizar.';
COMMENT ON COLUMN public.whatsapp_chats.asked_travel_data_at IS
  'Primera vez que Flor pidió fechas/noches/pax.';
COMMENT ON COLUMN public.whatsapp_chats.handoff_at IS
  'Primera derivación a humano (transfer/asesor).';
COMMENT ON COLUMN public.whatsapp_chats.prompt_variant IS
  'Variante de prompt Flor (ej. v4.2) para A/B abandono.';
COMMENT ON COLUMN public.whatsapp_chats.lead_origin IS
  'Origen del lead si se conoce (utm, ads, web, referido).';

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS lead_origin text;

ALTER TABLE public.site_pageviews
  ADD COLUMN IF NOT EXISTS session_id text,
  ADD COLUMN IF NOT EXISTS utm_source text,
  ADD COLUMN IF NOT EXISTS utm_medium text,
  ADD COLUMN IF NOT EXISTS utm_campaign text;

-- Alinear visitor_id: si insertan session_id, rellenar visitor_id
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'site_pageviews' AND column_name = 'visitor_id'
  ) THEN
    UPDATE public.site_pageviews
    SET visitor_id = COALESCE(NULLIF(visitor_id, ''), session_id)
    WHERE (visitor_id IS NULL OR visitor_id = '') AND session_id IS NOT NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS whatsapp_chats_datos_ready_at_idx
  ON public.whatsapp_chats (datos_ready_at)
  WHERE datos_ready_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS whatsapp_chats_handoff_at_idx
  ON public.whatsapp_chats (handoff_at)
  WHERE handoff_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS site_pageviews_utm_source_idx
  ON public.site_pageviews (created_at, utm_source);

-- Política insert: permitir visitor_id O session_id
DROP POLICY IF EXISTS "anon_insert_site_pageviews" ON public.site_pageviews;
CREATE POLICY "anon_insert_site_pageviews"
  ON public.site_pageviews
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    (
      (visitor_id IS NOT NULL AND length(visitor_id) >= 8 AND length(visitor_id) <= 80)
      OR (session_id IS NOT NULL AND length(session_id) >= 8 AND length(session_id) <= 80)
    )
  );

-- Visitas + top UTM/origen
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
    'pageviews', (
      SELECT count(*)::int FROM site_pageviews
      WHERE created_at >= p_from AND created_at < p_to
    ),
    'visitors', (
      SELECT count(DISTINCT COALESCE(NULLIF(visitor_id, ''), session_id))::int
      FROM site_pageviews
      WHERE created_at >= p_from AND created_at < p_to
        AND COALESCE(NULLIF(visitor_id, ''), session_id) IS NOT NULL
    ),
    'top_utm', COALESCE((
      SELECT json_agg(row_to_json(t) ORDER BY t.hits DESC)
      FROM (
        SELECT
          COALESCE(NULLIF(trim(utm_source), ''), '(directo/sin utm)') AS source,
          count(*)::int AS hits,
          count(DISTINCT COALESCE(NULLIF(visitor_id, ''), session_id))::int AS visitors
        FROM site_pageviews
        WHERE created_at >= p_from AND created_at < p_to
        GROUP BY 1
        ORDER BY hits DESC
        LIMIT 5
      ) t
    ), '[]'::json)
  );
$$;

REVOKE ALL ON FUNCTION public.site_visit_stats(timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.site_visit_stats(timestamptz, timestamptz) TO anon, authenticated;

-- ─── RPC ops completa ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.whatsapp_ops_daily_stats(
  p_from timestamptz,
  p_to timestamptz
)
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_has_flor boolean;
  v_has_channel boolean;
  v_has_datos_ready boolean;
  v_has_message_body boolean;
  v_result json;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'is_from_flor'
  ) INTO v_has_flor;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'whatsapp_chats' AND column_name = 'channel'
  ) INTO v_has_channel;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'whatsapp_chats' AND column_name = 'datos_ready_at'
  ) INTO v_has_datos_ready;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'whatsapp_messages' AND column_name = 'message'
  ) INTO v_has_message_body;

  WITH
  chats_filtered AS (
    SELECT *
    FROM whatsapp_chats c
    WHERE c.created_at >= p_from AND c.created_at < p_to
      AND (
        NOT v_has_channel
        OR COALESCE(c.channel, 'whatsapp') = 'whatsapp'
      )
  ),
  inbound AS (
    SELECT
      m.id,
      m.chat_id,
      COALESCE(m.whatsapp_instance, 1)::int AS line,
      COALESCE(m.sent_at, m.created_at) AS ts,
      regexp_replace(COALESCE(m.phone, ''), '\D', '', 'g') AS phone_digits,
      CASE WHEN v_has_message_body THEN COALESCE(m.message, m.body, '') ELSE COALESCE(m.body, '') END AS body
    FROM whatsapp_messages m
    WHERE COALESCE(m.is_from_me, false) = false
      AND COALESCE(m.sent_at, m.created_at) >= p_from
      AND COALESCE(m.sent_at, m.created_at) < p_to
      AND m.chat_id IS NOT NULL
  ),
  human_out AS (
    SELECT
      m.chat_id,
      COALESCE(m.whatsapp_instance, 1)::int AS line,
      COALESCE(m.sent_at, m.created_at) AS ts
    FROM whatsapp_messages m
    WHERE COALESCE(m.is_from_me, false) = true
      AND (
        NOT v_has_flor
        OR COALESCE(m.is_from_flor, false) = false
      )
      AND m.chat_id IS NOT NULL
  ),
  flor_out AS (
    SELECT
      m.chat_id,
      COALESCE(m.whatsapp_instance, 1)::int AS line,
      COALESCE(m.sent_at, m.created_at) AS ts
    FROM whatsapp_messages m
    WHERE COALESCE(m.is_from_me, false) = true
      AND v_has_flor
      AND COALESCE(m.is_from_flor, false) = true
      AND m.chat_id IS NOT NULL
  ),
  line_phones AS (
    SELECT DISTINCT ON (line)
      line,
      phone
    FROM (
      SELECT
        COALESCE(m.whatsapp_instance, 1)::int AS line,
        regexp_replace(COALESCE(m.sender, ''), '\D', '', 'g') AS phone,
        COALESCE(m.sent_at, m.created_at) AS ts
      FROM whatsapp_messages m
      WHERE COALESCE(m.is_from_me, false) = true
        AND m.sender IS NOT NULL
        AND length(regexp_replace(COALESCE(m.sender, ''), '\D', '', 'g')) BETWEEN 10 AND 15
    ) s
    WHERE phone !~ '^bot'
    ORDER BY line, ts DESC
  ),
  human_pairs AS (
    SELECT
      i.line,
      EXTRACT(EPOCH FROM (nxt.ts - i.ts))::numeric AS response_sec
    FROM inbound i
    CROSS JOIN LATERAL (
      SELECT o.ts
      FROM human_out o
      WHERE o.chat_id = i.chat_id AND o.ts > i.ts
      ORDER BY o.ts
      LIMIT 1
    ) nxt
  ),
  human_pairs_ok AS (
    SELECT * FROM human_pairs
    WHERE response_sec IS NOT NULL AND response_sec >= 0 AND response_sec < 86400
  ),
  flor_pairs AS (
    SELECT
      i.line,
      EXTRACT(EPOCH FROM (nxt.ts - i.ts))::numeric AS response_sec
    FROM inbound i
    CROSS JOIN LATERAL (
      SELECT o.ts
      FROM flor_out o
      WHERE o.chat_id = i.chat_id AND o.ts > i.ts
      ORDER BY o.ts
      LIMIT 1
    ) nxt
    WHERE v_has_flor
  ),
  flor_pairs_ok AS (
    SELECT * FROM flor_pairs
    WHERE response_sec IS NOT NULL AND response_sec >= 0 AND response_sec < 86400
  ),
  human_sla AS (
    SELECT
      hp.line,
      COALESCE(lp.phone, '') AS phone,
      count(*)::int AS measured,
      ROUND(AVG(hp.response_sec))::int AS avg_sec,
      ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY hp.response_sec))::numeric)::int AS median_sec,
      count(*) FILTER (WHERE hp.response_sec > 300)::int AS over_5min,
      count(*) FILTER (WHERE hp.response_sec > 900)::int AS over_15min
    FROM human_pairs_ok hp
    LEFT JOIN line_phones lp ON lp.line = hp.line
    GROUP BY hp.line, lp.phone
  ),
  flor_sla AS (
    SELECT
      fp.line,
      COALESCE(lp.phone, '') AS phone,
      count(*)::int AS measured,
      ROUND(AVG(fp.response_sec))::int AS avg_sec
    FROM flor_pairs_ok fp
    LEFT JOIN line_phones lp ON lp.line = fp.line
    GROUP BY fp.line, lp.phone
  ),
  -- Heurística datos listos en texto entrante (histórico) + columna datos_ready_at
  inbound_datos_flags AS (
    SELECT
      i.chat_id,
      i.line,
      (
        (i.body ~* '\d{1,2}[/\-.]\d{1,2}([/\-.]\d{2,4})?')
        OR i.body ~* '(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)'
        OR i.body ~* '(check.?in|entrada|llegamos|del\s+\d{1,2})'
      ) AS has_date,
      (
        i.body ~* '\d+\s*noches?'
        OR i.body ~* '(una|dos|tres|cuatro|cinco|seis|siete)\s*noches?'
      ) AS has_nights,
      (
        i.body ~* '\d+\s*(adultos?|personas?|pax|hu[eé]spedes?)'
        OR i.body ~* '(somos|vamos)\s+\d+'
        OR i.body ~* '\d+\s*adult'
      ) AS has_pax
    FROM inbound i
  ),
  chats_datos_heuristic AS (
    SELECT chat_id, line
    FROM inbound_datos_flags
    GROUP BY chat_id, line
    HAVING
      (bool_or(has_date)::int + bool_or(has_nights)::int + bool_or(has_pax)::int) >= 2
  ),
  chats_datos_col AS (
    SELECT c.id AS chat_id, COALESCE(c.whatsapp_instance, 1)::int AS line
    FROM whatsapp_chats c
    WHERE v_has_datos_ready
      AND c.datos_ready_at IS NOT NULL
      AND c.datos_ready_at >= p_from AND c.datos_ready_at < p_to
  ),
  chats_datos_ready AS (
    SELECT DISTINCT chat_id, line FROM (
      SELECT * FROM chats_datos_heuristic
      UNION
      SELECT * FROM chats_datos_col
    ) u
  ),
  active_chat_ids AS (
    SELECT DISTINCT chat_id, line FROM inbound
  ),
  datos_ready_stats AS (
    SELECT
      (SELECT count(*)::int FROM active_chat_ids) AS active_chats,
      (SELECT count(*)::int FROM chats_datos_ready) AS chats_datos_ready,
      CASE
        WHEN (SELECT count(*) FROM active_chat_ids) = 0 THEN 0
        ELSE ROUND(
          100.0 * (SELECT count(*) FROM chats_datos_ready)::numeric
          / (SELECT count(*) FROM active_chat_ids)::numeric
        )::int
      END AS pct_datos_ready
  ),
  handoffs AS (
    SELECT
      f.line,
      count(DISTINCT f.chat_id)::int AS handoffs
    FROM flor_out f
    WHERE f.ts >= p_from AND f.ts < p_to
      AND EXISTS (
        SELECT 1 FROM human_out h
        WHERE h.chat_id = f.chat_id AND h.ts > f.ts AND h.ts < p_to
      )
    GROUP BY f.line
  ),
  handoff_phones AS (
    SELECT DISTINCT
      regexp_replace(COALESCE(c.real_phone, c.phone, ''), '\D', '', 'g') AS phone_digits
    FROM flor_out f
    JOIN whatsapp_chats c ON c.id = f.chat_id
    WHERE f.ts >= p_from AND f.ts < p_to
      AND EXISTS (
        SELECT 1 FROM human_out h
        WHERE h.chat_id = f.chat_id AND h.ts > f.ts AND h.ts < (p_to + interval '3 days')
      )
    UNION
    SELECT DISTINCT
      regexp_replace(COALESCE(c.real_phone, c.phone, ''), '\D', '', 'g')
    FROM whatsapp_chats c
    WHERE c.handoff_at IS NOT NULL
      AND c.handoff_at >= p_from AND c.handoff_at < p_to
  ),
  wa_phones_day AS (
    SELECT DISTINCT phone_digits
    FROM inbound
    WHERE length(phone_digits) >= 10
  ),
  quote_norm AS (
    SELECT
      q.id,
      regexp_replace(COALESCE(q.customer_phone, ''), '\D', '', 'g') AS phone_digits,
      q.total,
      q.check_in,
      q.check_out,
      q.contact_origin,
      q.status,
      q.created_at,
      CASE
        WHEN q.check_in IS NOT NULL AND q.check_out IS NOT NULL AND q.check_out > q.check_in
        THEN (q.check_out::date - q.check_in::date)
        ELSE NULL
      END AS nights
    FROM quotes q
    WHERE q.created_at >= p_from AND q.created_at < (p_to + interval '3 days')
  ),
  res_norm AS (
    SELECT
      r.id,
      regexp_replace(COALESCE(r.customer_phone, ''), '\D', '', 'g') AS phone_digits,
      r.total_amount,
      r.check_in,
      r.check_out,
      r.status,
      r.created_at,
      CASE
        WHEN r.check_in IS NOT NULL AND r.check_out IS NOT NULL AND r.check_out > r.check_in
        THEN (r.check_out::date - r.check_in::date)
        ELSE NULL
      END AS nights
    FROM reservations r
    WHERE r.created_at >= p_from AND r.created_at < (p_to + interval '7 days')
      AND COALESCE(r.status, '') NOT ILIKE '%cancel%'
  ),
  funnel AS (
    SELECT
      (SELECT count(*)::int FROM handoff_phones WHERE length(phone_digits) >= 10) AS handoffs,
      (SELECT count(DISTINCT q.phone_digits)::int
       FROM quote_norm q
       WHERE length(q.phone_digits) >= 10
         AND (
           q.phone_digits IN (SELECT phone_digits FROM handoff_phones WHERE length(phone_digits) >= 10)
           OR q.phone_digits IN (SELECT phone_digits FROM wa_phones_day)
           OR COALESCE(q.contact_origin, '') ILIKE '%whatsapp%'
         )
         AND q.created_at >= p_from AND q.created_at < (p_to + interval '3 days')
      ) AS quotes,
      (SELECT count(DISTINCT r.phone_digits)::int
       FROM res_norm r
       WHERE length(r.phone_digits) >= 10
         AND (
           r.phone_digits IN (SELECT phone_digits FROM handoff_phones WHERE length(phone_digits) >= 10)
           OR r.phone_digits IN (SELECT phone_digits FROM wa_phones_day)
           OR r.phone_digits IN (
             SELECT phone_digits FROM quote_norm
             WHERE length(phone_digits) >= 10
               AND (
                 phone_digits IN (SELECT phone_digits FROM wa_phones_day)
                 OR COALESCE(contact_origin, '') ILIKE '%whatsapp%'
               )
           )
         )
         AND r.created_at >= p_from AND r.created_at < (p_to + interval '7 days')
      ) AS reservations
  ),
  ticket_stats AS (
    SELECT
      count(*)::int AS quotes_n,
      ROUND(AVG(total) FILTER (WHERE total IS NOT NULL AND total > 0))::numeric AS avg_ticket,
      ROUND(AVG(nights) FILTER (WHERE nights IS NOT NULL AND nights > 0 AND nights < 60))::numeric AS avg_nights
    FROM quote_norm q
    WHERE q.created_at >= p_from AND q.created_at < p_to
      AND (
        q.phone_digits IN (SELECT phone_digits FROM wa_phones_day)
        OR COALESCE(q.contact_origin, '') ILIKE '%whatsapp%'
        OR q.phone_digits IN (SELECT phone_digits FROM handoff_phones)
      )
  ),
  ticket_res AS (
    SELECT
      count(*)::int AS reservations_n,
      ROUND(AVG(total_amount) FILTER (WHERE total_amount IS NOT NULL AND total_amount > 0))::numeric AS avg_ticket_res,
      ROUND(AVG(nights) FILTER (WHERE nights IS NOT NULL AND nights > 0 AND nights < 60))::numeric AS avg_nights_res
    FROM res_norm r
    WHERE r.created_at >= p_from AND r.created_at < p_to
  ),
  origins AS (
    SELECT
      COALESCE(NULLIF(trim(lower(contact_origin)), ''), '(sin origen)') AS origin,
      count(*)::int AS hits
    FROM quote_norm
    WHERE created_at >= p_from AND created_at < p_to
    GROUP BY 1
    ORDER BY hits DESC
    LIMIT 8
  ),
  peak_hours AS (
    SELECT
      EXTRACT(HOUR FROM (ts AT TIME ZONE 'America/Argentina/Buenos_Aires'))::int AS hour,
      count(*)::int AS inbound
    FROM inbound
    GROUP BY 1
    ORDER BY inbound DESC, hour
    LIMIT 5
  ),
  -- Abandono: chats activos del día sin datos listos
  chat_inbound_counts AS (
    SELECT chat_id, line, count(*)::int AS n_in, min(ts) AS first_ts, max(ts) AS last_ts
    FROM inbound
    GROUP BY chat_id, line
  ),
  abandon AS (
    SELECT
      count(*) FILTER (
        WHERE cic.n_in <= 2
          AND cic.chat_id NOT IN (SELECT chat_id FROM chats_datos_ready)
          AND cic.last_ts < (p_to - interval '2 hours')
      )::int AS short_abandon,
      count(*) FILTER (
        WHERE cic.n_in >= 3
          AND cic.chat_id NOT IN (SELECT chat_id FROM chats_datos_ready)
          AND cic.last_ts < (p_to - interval '2 hours')
      )::int AS long_abandon,
      count(*) FILTER (
        WHERE EXISTS (
          SELECT 1 FROM whatsapp_chats c
          WHERE c.id = cic.chat_id AND c.asked_travel_data_at IS NOT NULL
            AND c.asked_travel_data_at >= p_from AND c.asked_travel_data_at < p_to
            AND c.datos_ready_at IS NULL
        )
      )::int AS asked_no_datos,
      count(*)::int AS active_for_abandon
    FROM chat_inbound_counts cic
  ),
  abandon_by_variant AS (
    SELECT
      COALESCE(NULLIF(trim(c.prompt_variant), ''), 'v4.2') AS variant,
      count(DISTINCT cic.chat_id)::int AS chats,
      count(DISTINCT cic.chat_id) FILTER (
        WHERE cic.chat_id NOT IN (SELECT chat_id FROM chats_datos_ready)
          AND cic.last_ts < (p_to - interval '2 hours')
      )::int AS abandoned
    FROM chat_inbound_counts cic
    LEFT JOIN whatsapp_chats c ON c.id = cic.chat_id
    GROUP BY 1
  ),
  recontacts AS (
    SELECT
      count(DISTINCT m.phone_digits) FILTER (
        WHERE EXISTS (
          SELECT 1 FROM whatsapp_messages m0
          WHERE regexp_replace(COALESCE(m0.phone, ''), '\D', '', 'g') = m.phone_digits
            AND COALESCE(m0.is_from_me, false) = false
            AND COALESCE(m0.sent_at, m0.created_at) < p_from
        )
      )::int AS any_prior,
      count(DISTINCT m.phone_digits) FILTER (
        WHERE EXISTS (
          SELECT 1 FROM whatsapp_messages m0
          WHERE regexp_replace(COALESCE(m0.phone, ''), '\D', '', 'g') = m.phone_digits
            AND COALESCE(m0.is_from_me, false) = false
            AND COALESCE(m0.sent_at, m0.created_at) >= (p_from - interval '7 days')
            AND COALESCE(m0.sent_at, m0.created_at) < p_from
        )
      )::int AS d7,
      count(DISTINCT m.phone_digits) FILTER (
        WHERE EXISTS (
          SELECT 1 FROM whatsapp_messages m0
          WHERE regexp_replace(COALESCE(m0.phone, ''), '\D', '', 'g') = m.phone_digits
            AND COALESCE(m0.is_from_me, false) = false
            AND COALESCE(m0.sent_at, m0.created_at) >= (p_from - interval '30 days')
            AND COALESCE(m0.sent_at, m0.created_at) < p_from
        )
      )::int AS d30
    FROM (SELECT DISTINCT phone_digits FROM inbound WHERE length(phone_digits) >= 10) m
  ),
  top_hotels AS (
    SELECT COALESCE(h.name, 'Hotel') AS hotel_name,
           count(*)::int AS hits
    FROM flor_interactions i
    LEFT JOIN hotels h ON h.id = i.hotel_id
    WHERE i.created_at >= p_from
      AND i.created_at < p_to
      AND i.hotel_id IS NOT NULL
    GROUP BY COALESCE(h.name, 'Hotel')
    ORDER BY hits DESC
    LIMIT 5
  ),
  chats_with_hotel AS (
    SELECT count(*)::int AS n
    FROM whatsapp_chats c
    WHERE c.current_hotel_id IS NOT NULL
      AND c.updated_at >= p_from AND c.updated_at < p_to
      AND (
        NOT v_has_channel
        OR COALESCE(c.channel, 'whatsapp') = 'whatsapp'
      )
  )
  SELECT json_build_object(
    'new_chats_total', (SELECT count(*)::int FROM chats_filtered),
    'new_chats_by_line', COALESCE((
      SELECT json_agg(row_to_json(t) ORDER BY t.line)
      FROM (
        SELECT COALESCE(whatsapp_instance, 1)::int AS line, count(*)::int AS new_chats
        FROM chats_filtered
        GROUP BY COALESCE(whatsapp_instance, 1)
      ) t
    ), '[]'::json),
    'inbound_messages_total', (SELECT count(*)::int FROM inbound),
    'inbound_by_line', COALESCE((
      SELECT json_agg(row_to_json(t) ORDER BY t.line)
      FROM (
        SELECT line, count(*)::int AS inbound_messages
        FROM inbound
        GROUP BY line
      ) t
    ), '[]'::json),
    'active_chats_with_inbound', (SELECT count(DISTINCT chat_id)::int FROM inbound),
    'chats_with_hotel', (SELECT n FROM chats_with_hotel),
    'datos_ready', (SELECT row_to_json(datos_ready_stats) FROM datos_ready_stats),
    'recontacts', (SELECT any_prior FROM recontacts),
    'recontacts_7d', (SELECT d7 FROM recontacts),
    'recontacts_30d', (SELECT d30 FROM recontacts),
    'handoffs_total', (SELECT COALESCE(sum(handoffs), 0)::int FROM handoffs),
    'handoffs_by_line', COALESCE((SELECT json_agg(row_to_json(handoffs) ORDER BY line) FROM handoffs), '[]'::json),
    'funnel', (SELECT row_to_json(funnel) FROM funnel),
    'ticket', json_build_object(
      'quotes_n', (SELECT quotes_n FROM ticket_stats),
      'avg_ticket', (SELECT avg_ticket FROM ticket_stats),
      'avg_nights', (SELECT avg_nights FROM ticket_stats),
      'reservations_n', (SELECT reservations_n FROM ticket_res),
      'avg_ticket_res', (SELECT avg_ticket_res FROM ticket_res),
      'avg_nights_res', (SELECT avg_nights_res FROM ticket_res)
    ),
    'origins', COALESCE((SELECT json_agg(row_to_json(origins)) FROM origins), '[]'::json),
    'peak_hours', COALESCE((SELECT json_agg(row_to_json(peak_hours)) FROM peak_hours), '[]'::json),
    'abandon', (SELECT row_to_json(abandon) FROM abandon),
    'abandon_by_variant', COALESCE((SELECT json_agg(row_to_json(abandon_by_variant)) FROM abandon_by_variant), '[]'::json),
    'line_phones', COALESCE((SELECT json_agg(row_to_json(line_phones) ORDER BY line) FROM line_phones), '[]'::json),
    'human_sla_by_line', COALESCE((SELECT json_agg(row_to_json(human_sla) ORDER BY line) FROM human_sla), '[]'::json),
    'flor_sla_by_line', COALESCE((SELECT json_agg(row_to_json(flor_sla) ORDER BY line) FROM flor_sla), '[]'::json),
    'top_hotels', COALESCE((SELECT json_agg(row_to_json(top_hotels)) FROM top_hotels), '[]'::json),
    'sla_threshold_sec', 300
  ) INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.whatsapp_ops_daily_stats(timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.whatsapp_ops_daily_stats(timestamptz, timestamptz) TO anon, authenticated;

COMMENT ON FUNCTION public.whatsapp_ops_daily_stats IS
  'Ops digest: SLA, datos listos, embudo handoff→quote→reserva, ticket/noches, origen, picos, abandono V4.2, recontactos 7/30.';
