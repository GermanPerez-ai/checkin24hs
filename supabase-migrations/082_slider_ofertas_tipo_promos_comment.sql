-- Documentar tipo_link = 'promos' (banner de landings /promo, no va al carrusel Home)
COMMENT ON COLUMN public.slider_ofertas.tipo_link IS
  'url | hotel | flor | promos. promos = banner de Promos en landings /promo/:slug (excluido del carrusel Home).';
COMMENT ON COLUMN public.slider_ofertas.texto_boton IS
  'Texto del botón (ej. Chateá con Flor IA, Ver Hoteles, Ofertas). tipo_link=flor abre Flor; tipo_link=promos va a /promos.';
