-- Stats diarias de chats/mensajes WhatsApp por línea (para digest del monitor)
-- Líneas = whatsapp_instance (1..4)

CREATE OR REPLACE FUNCTION public.whatsapp_daily_chat_stats(
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
    'new_chats_total', (
      SELECT count(*)::int
      FROM whatsapp_chats
      WHERE created_at >= p_from
        AND created_at < p_to
        AND COALESCE(channel, 'whatsapp') = 'whatsapp'
    ),
    'new_chats_by_line', (
      SELECT COALESCE(json_agg(row_to_json(t) ORDER BY t.line), '[]'::json)
      FROM (
        SELECT COALESCE(whatsapp_instance, 1)::int AS line,
               count(*)::int AS new_chats
        FROM whatsapp_chats
        WHERE created_at >= p_from
          AND created_at < p_to
          AND COALESCE(channel, 'whatsapp') = 'whatsapp'
        GROUP BY COALESCE(whatsapp_instance, 1)
      ) t
    ),
    'inbound_messages_total', (
      SELECT count(*)::int
      FROM whatsapp_messages
      WHERE COALESCE(sent_at, created_at) >= p_from
        AND COALESCE(sent_at, created_at) < p_to
        AND COALESCE(is_from_me, false) = false
    ),
    'inbound_by_line', (
      SELECT COALESCE(json_agg(row_to_json(t) ORDER BY t.line), '[]'::json)
      FROM (
        SELECT COALESCE(whatsapp_instance, 1)::int AS line,
               count(*)::int AS inbound_messages
        FROM whatsapp_messages
        WHERE COALESCE(sent_at, created_at) >= p_from
          AND COALESCE(sent_at, created_at) < p_to
          AND COALESCE(is_from_me, false) = false
        GROUP BY COALESCE(whatsapp_instance, 1)
      ) t
    ),
    'active_chats_with_inbound', (
      SELECT count(DISTINCT chat_id)::int
      FROM whatsapp_messages
      WHERE COALESCE(sent_at, created_at) >= p_from
        AND COALESCE(sent_at, created_at) < p_to
        AND COALESCE(is_from_me, false) = false
        AND chat_id IS NOT NULL
    )
  );
$$;

REVOKE ALL ON FUNCTION public.whatsapp_daily_chat_stats(timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.whatsapp_daily_chat_stats(timestamptz, timestamptz) TO anon, authenticated;

COMMENT ON FUNCTION public.whatsapp_daily_chat_stats IS
  'Resumen diario WhatsApp por línea para el site-monitor (digest WhatsApp).';
