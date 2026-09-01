-- Corrige aviso Security Advisor: vista SECURITY DEFINER.
-- La vista pasa a security_invoker = true (respeta RLS del usuario que consulta).

CREATE OR REPLACE VIEW public.user_hotel_preferences_view
WITH (security_invoker = true) AS
SELECT
  i.user_id,
  i.hotel_id,
  i.phone,
  i.interest_count,
  i.first_interest_at,
  i.last_interest_at,
  i.source,
  i.whatsapp_instance,
  COALESCE(h.name, 'Hotel') AS hotel_name
FROM public.user_hotel_interests i
LEFT JOIN public.hotels h ON h.id = i.hotel_id;

GRANT SELECT ON public.user_hotel_preferences_view TO anon, authenticated;
