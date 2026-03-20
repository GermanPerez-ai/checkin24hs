-- Rellenar hotel_name en filas viejas donde hay hotel_id pero hotel_name es NULL
-- (el dashboard antes podía ocultarlas si no resolvía el nombre).

UPDATE public.quotes q
SET hotel_name = h.name
FROM public.hotels h
WHERE q.hotel_id = h.id
  AND (q.hotel_name IS NULL OR TRIM(q.hotel_name) = '');

-- Verificar (opcional):
-- SELECT id, code, hotel_id, hotel_name FROM quotes ORDER BY created_at DESC LIMIT 30;
