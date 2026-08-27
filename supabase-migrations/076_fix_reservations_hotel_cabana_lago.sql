-- Reparar reservas: Cabaña Del Lago Puerto Varas → Puyehue / Corralco
-- Ejecutar en Supabase → SQL Editor.
-- NO hardcodear UUID de Puyehue: se toma del catálogo hotels por nombre.

-- 0) Ver IDs reales (copiá el de Puyehue si querés setear HOTEL_ID_PUYEHUE en el sync)
SELECT id, name
FROM hotels
WHERE name ILIKE '%puyehue%'
   OR name ILIKE '%corralco%'
   OR name ILIKE '%caba%lago%'
ORDER BY name;

-- 1) Puyehue: códigos alfanuméricos tipo VHQ6GU / agent puyehue
UPDATE reservations r
SET
  hotel_id = h.id,
  hotel_name = h.name,
  updated_at = NOW()
FROM hotels h
WHERE h.name ILIKE '%puyehue%'
  AND h.name NOT ILIKE '%aguas%calientes%'
  AND (
    r.hotel_id = '1ed56145-a679-4feb-b943-cc880276152e'
    OR r.hotel_name ILIKE '%caba%lago%'
    OR (r.hotel_name ILIKE '%puerto varas%' AND r.hotel_name NOT ILIKE '%puyehue%')
  )
  AND (
    r.reservation_code ~ '^[A-Za-z][A-Za-z0-9]{3,9}$'
    OR COALESCE(r.agent_name, '') ILIKE '%puyehue%'
  );

-- 2) Corralco: códigos numéricos tipo 2602135 / agent corralco
UPDATE reservations r
SET
  hotel_id = h.id,
  hotel_name = h.name,
  updated_at = NOW()
FROM hotels h
WHERE h.name ILIKE '%corralco%'
  AND (
    r.hotel_id = '1ed56145-a679-4feb-b943-cc880276152e'
    OR r.hotel_name ILIKE '%caba%lago%'
    OR (
      r.hotel_name ILIKE '%puerto varas%'
      AND r.hotel_name NOT ILIKE '%puyehue%'
      AND r.hotel_name NOT ILIKE '%corralco%'
    )
  )
  AND (
    r.reservation_code ~ '^[0-9]{6,8}$'
    OR COALESCE(r.agent_name, '') ILIKE '%corralco%'
  );

-- 3) Verificar
SELECT reservation_code, hotel_name, hotel_id, agent_name, total_amount
FROM reservations
WHERE hotel_name ILIKE '%caba%lago%'
   OR hotel_name ILIKE '%puyehue%'
   OR hotel_name ILIKE '%corralco%'
ORDER BY updated_at DESC
LIMIT 40;
