-- Ops diarias WhatsApp: chats + SLA respuesta humana por línea/número + hoteles + hand-offs
-- Para el digest del monitor. Ejecutar en Supabase SQL Editor.

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
      COALESCE(m.sent_at, m.created_at) AS ts
    FROM whatsapp_messages m
    WHERE COALESCE(m.is_from_me, false) = false
      AND COALESCE(m.sent_at, m.created_at) >= p_from
      AND COALESCE(m.sent_at, m.created_at) < p_to
      AND m.chat_id IS NOT NULL
  ),
  -- Salidas humanas (empleado): is_from_me y NO Flor
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
  -- Número de WhatsApp del negocio por línea (sender en mensajes propios)
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
        AND regexp_replace(COALESCE(m.sender, ''), '\D', '', 'g') NOT LIKE 'bot%'
    ) s
    WHERE phone !~ '^bot'
    ORDER BY line, ts DESC
  ),
  -- Por cada mensaje del cliente: tiempo hasta la 1ª respuesta HUMANA posterior
  human_pairs AS (
    SELECT
      i.line,
      EXTRACT(EPOCH FROM (nxt.ts - i.ts))::numeric AS response_sec
    FROM inbound i
    CROSS JOIN LATERAL (
      SELECT o.ts
      FROM human_out o
      WHERE o.chat_id = i.chat_id
        AND o.ts > i.ts
      ORDER BY o.ts
      LIMIT 1
    ) nxt
  ),
  flor_pairs AS (
    SELECT
      i.line,
      EXTRACT(EPOCH FROM (nxt.ts - i.ts))::numeric AS response_sec
    FROM inbound i
    CROSS JOIN LATERAL (
      SELECT o.ts
      FROM flor_out o
      WHERE o.chat_id = i.chat_id
        AND o.ts > i.ts
      ORDER BY o.ts
      LIMIT 1
    ) nxt
    WHERE v_has_flor
  ),
  human_pairs_ok AS (
    SELECT * FROM human_pairs
    WHERE response_sec IS NOT NULL AND response_sec >= 0 AND response_sec < 86400
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
  -- Hand-off: Flor respondió y después hubo mensaje humano en el mismo chat (día)
  handoffs AS (
    SELECT
      f.line,
      count(DISTINCT f.chat_id)::int AS handoff_count
    FROM flor_out f
    WHERE f.ts >= p_from AND f.ts < p_to
      AND EXISTS (
        SELECT 1 FROM human_out h
        WHERE h.chat_id = f.chat_id
          AND h.ts > f.ts
          AND h.ts < p_to
      )
    GROUP BY f.line
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
  ),
  recontacts AS (
    SELECT count(DISTINCT m.phone)::int AS n
    FROM whatsapp_messages m
    WHERE COALESCE(m.is_from_me, false) = false
      AND COALESCE(m.sent_at, m.created_at) >= p_from
      AND COALESCE(m.sent_at, m.created_at) < p_to
      AND m.phone IS NOT NULL
      AND length(regexp_replace(COALESCE(m.phone, ''), '\D', '', 'g')) >= 10
      AND EXISTS (
        SELECT 1 FROM whatsapp_messages m0
        WHERE m0.phone = m.phone
          AND COALESCE(m0.is_from_me, false) = false
          AND COALESCE(m0.sent_at, m0.created_at) < p_from
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
    'active_chats_with_inbound', (
      SELECT count(DISTINCT chat_id)::int FROM inbound
    ),
    'chats_with_hotel', (SELECT n FROM chats_with_hotel),
    'recontacts', (SELECT n FROM recontacts),
    'handoffs_total', (SELECT COALESCE(sum(handoff_count), 0)::int FROM handoffs),
    'handoffs_by_line', COALESCE((
      SELECT json_agg(json_build_object('line', h.line, 'handoffs', h.handoff_count) ORDER BY h.line)
      FROM handoffs h
    ), '[]'::json),
    'line_phones', COALESCE((SELECT json_agg(row_to_json(lp) ORDER BY lp.line) FROM line_phones lp), '[]'::json),
    'human_sla_by_line', COALESCE((SELECT json_agg(row_to_json(hs) ORDER BY hs.line) FROM human_sla hs), '[]'::json),
    'flor_sla_by_line', COALESCE((SELECT json_agg(row_to_json(fs) ORDER BY fs.line) FROM flor_sla fs), '[]'::json),
    'top_hotels', COALESCE((SELECT json_agg(row_to_json(th)) FROM top_hotels th), '[]'::json),
    'sla_threshold_sec', 300
  ) INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.whatsapp_ops_daily_stats(timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.whatsapp_ops_daily_stats(timestamptz, timestamptz) TO anon, authenticated;

COMMENT ON FUNCTION public.whatsapp_ops_daily_stats IS
  'Digest ops: chats, hand-offs, top hoteles, SLA respuesta humana (promedio y >5min) por línea/número WhatsApp.';
