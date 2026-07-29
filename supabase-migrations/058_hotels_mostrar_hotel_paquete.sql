-- Publicación dual: hotel y/o pack en la web.
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE public.hotels
  ADD COLUMN IF NOT EXISTS mostrar_como_hotel BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS mostrar_como_paquete BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.hotels.mostrar_como_hotel IS
  'Si true, aparece en páginas de destino (Argentina/Chile/Internacionales) como alojamiento';
COMMENT ON COLUMN public.hotels.mostrar_como_paquete IS
  'Si true, aparece en /packs con tarjeta y ficha de pack';

-- Migrar desde tipo_producto existente
UPDATE public.hotels
SET
  mostrar_como_hotel = CASE WHEN COALESCE(tipo_producto, 'hotel') = 'paquete' THEN false ELSE true END,
  mostrar_como_paquete = CASE WHEN COALESCE(tipo_producto, 'hotel') = 'paquete' THEN true ELSE false END
WHERE mostrar_como_hotel IS NULL
   OR mostrar_como_paquete IS NULL
   OR (
     -- Re-sincronizar filas que aún no se tocaron (defaults) y tienen tipo_producto
     mostrar_como_hotel = true
     AND mostrar_como_paquete = false
     AND tipo_producto = 'paquete'
   );

-- Asegurar not-null práctico
UPDATE public.hotels SET mostrar_como_hotel = true WHERE mostrar_como_hotel IS NULL;
UPDATE public.hotels SET mostrar_como_paquete = false WHERE mostrar_como_paquete IS NULL;
