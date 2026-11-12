-- Banners de la landing /barcelo para Dashboard → Banners del sitio.
-- NO ejecutar hasta que German lo confirme. Este script no se corre en el deploy.
-- imagen_url queda vacía a propósito: /barcelo mantiene el recuadro actual
-- hasta que se suba una foto (desktop y, si se quiere, mobile) desde el Dashboard.
-- imagen_url es NOT NULL; la cadena vacía cumple el constraint.
-- Idempotente: no inserta si ya existe el mismo tipo_link + link_destino
-- (en el hero, el mismo tipo_link = 'barcelo').

INSERT INTO public.slider_ofertas
  (titulo, texto_boton, imagen_url, imagen_url_mobile, link_destino, tipo_link, orden, activo)
SELECT v.titulo, NULL, '', NULL, v.link_destino, v.tipo_link, v.orden, true
FROM (VALUES
  -- Hero Home + landing /barcelo (ya soportado por la web: tipo barcelo)
  ('Exclusivo Barceló',          NULL,                     'barcelo',          10),
  -- Encabezados de país (recuadro "Hoteles en …")
  ('República Dominicana',       'republica-dominicana',   'barcelo_seccion',  20),
  ('México',                     'mexico',                 'barcelo_seccion',  21),
  ('Costa Rica',                 'costa-rica',             'barcelo_seccion',  22),
  ('Aruba',                      'aruba',                  'barcelo_seccion',  23),
  ('Nicaragua',                  'nicaragua',              'barcelo_seccion',  24),
  -- Destinos (subtítulos cuando un país tiene más de uno; si el país no tiene
  -- foto y es un solo destino, la web puede usar esta imagen en el encabezado)
  ('Punta Cana',                 'punta-cana',             'barcelo_seccion',  30),
  ('Cancún',                     'cancun',                 'barcelo_seccion',  31),
  ('Riviera Maya',               'riviera-maya',           'barcelo_seccion',  32),
  ('Playa del Carmen',           'playa-del-carmen',       'barcelo_seccion',  33),
  ('Puerto Vallarta',            'puerto-vallarta',        'barcelo_seccion',  34),
  ('Papagayo',                   'papagayo',               'barcelo_seccion',  35),
  ('Tamarindo',                  'tamarindo',              'barcelo_seccion',  36),
  ('Tambor',                     'tambor',                 'barcelo_seccion',  37),
  ('Palm Beach',                 'palm-beach',             'barcelo_seccion',  38),
  ('Montelimar',                 'montelimar',             'barcelo_seccion',  39)
) AS v(titulo, link_destino, tipo_link, orden)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.slider_ofertas s
  WHERE s.tipo_link = v.tipo_link
    AND COALESCE(s.link_destino, '') = COALESCE(v.link_destino, '')
);
