-- Asegurar que whatsapp_messages.phone NO tenga valor por defecto.
-- Si en el Dashboard se configuró por error "varchar" (o cualquier string) como Default Value,
-- este script lo quita para que el valor siempre venga del insert del servidor (número real E.164).
-- Ejecutar en Supabase SQL Editor si el campo phone se estaba llenando con "varchar".

ALTER TABLE public.whatsapp_messages
    ALTER COLUMN phone DROP DEFAULT;
