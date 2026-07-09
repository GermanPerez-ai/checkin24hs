-- Eliminar del JSON flor_info los campos de programas, servicios Flor y archivos por temporada
-- (ya no se editan desde el dashboard). No toca flor_info.description, img_general, etc.
-- No elimina el bucket flor-ficha (sigue usándose para imágenes de hoteles).

UPDATE public.hotels
SET flor_info = flor_info
  - 'detalles_programas'
  - 'servicios_json'
  - 'spa_verano'
  - 'spa_invierno'
  - 'carta_restaurante_verano'
  - 'carta_restaurante_invierno'
  - 'excursiones_verano'
  - 'excursiones_invierno'
  - 'instagram_verano'
  - 'instagram_invierno'
  - 'pdf_menu_spa'
  - 'pdf_menu_resto'
  - 'pdf_programas'
WHERE flor_info IS NOT NULL
  AND flor_info <> '{}'::jsonb;
