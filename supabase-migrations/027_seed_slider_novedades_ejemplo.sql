-- ============================================
-- Datos de ejemplo: slider de ofertas y novedades
-- Ejecutar en Supabase → SQL Editor para ver el Home con contenido.
-- Después podés editarlos o borrarlos desde el Dashboard o con DELETE.
-- ============================================

-- Slider de ofertas (3 slides de ejemplo)
INSERT INTO public.slider_ofertas (titulo, imagen_url, imagen_url_mobile, link_destino, tipo_link, texto_boton, orden, activo)
VALUES
  (
    'Bariloche y la Patagonia',
    'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=1200',
    NULL,
    '/?ciudad=Bariloche',
    'busqueda',
    'Ver alojamientos',
    1,
    true
  ),
  (
    'Chateá con Flor y encontrá tu alojamiento',
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200',
    NULL,
    '#flor',
    'flor',
    'Chateá con Flor IA',
    2,
    true
  ),
  (
    'Ofertas de temporada',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200',
    NULL,
    NULL,
    'url',
    'Ver más',
    3,
    true
  )
ON CONFLICT DO NOTHING;

-- Novedades (4 notas de ejemplo)
INSERT INTO public.novedades (titulo, resumen, imagen_miniatura, fecha_publicacion, slug)
VALUES
  (
    'Nueva temporada en la Patagonia',
    'Te contamos las mejores fechas y tips para reservar en Bariloche, El Bolsón y la región.',
    'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
    NOW() - INTERVAL '2 days',
    'nueva-temporada-patagonia'
  ),
  (
    'Guía rápida: qué hacer en Bariloche',
    'Cerro Catedral, chocolate, trekking y más. Un resumen de lo que no te podés perder.',
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
    NOW() - INTERVAL '5 days',
    'guia-bariloche'
  ),
  (
    'Alojamientos con desayuno incluido',
    'Listado de hoteles y cabañas que incluyen desayuno en la tarifa.',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=600',
    NOW() - INTERVAL '10 days',
    'desayuno-incluido'
  ),
  (
    'Cómo reservar con Flor',
    'Flor es nuestra asistente por WhatsApp y web: preguntale fechas, precios y disponibilidad.',
    'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600',
    NOW() - INTERVAL '15 days',
    'reservar-con-flor'
  )
ON CONFLICT (slug) WHERE (slug IS NOT NULL) DO NOTHING;

-- Nota: Si ejecutás el script dos veces, el slider puede duplicar slides (borralos si pasa).
-- Novedades no se duplican gracias a ON CONFLICT (slug).
-- Para borrar los ejemplos: DELETE FROM public.slider_ofertas; DELETE FROM public.novedades;
