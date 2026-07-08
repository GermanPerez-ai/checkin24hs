import { Link } from 'react-router-dom';
import { buildCotizadorUrl, buildWhatsAppConsultaUrl } from '../config';
import { getReservaDirectaUrl, isHotelTermasPuyehue, openReservaPopup } from '../lib/hoteles';
import type { Hotel } from '../types';
import styles from './HotelCard.module.css';

function getImageUrl(h: Hotel): string {
  if (h.imagen_principal) return h.imagen_principal;
  const galeria = h.galeria_fotos;
  if (Array.isArray(galeria) && galeria.length) return galeria[0];
  if (h.images && Array.isArray(h.images) && h.images.length) return h.images[0];
  return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600';
}

function getSlug(h: Hotel): string {
  if (h.slug) return h.slug;
  return h.id;
}

function getPuntuacion(h: Hotel): number | null {
  if (h.puntuacion_num != null) return Number(h.puntuacion_num);
  if (h.rating != null) return Number(h.rating);
  return null;
}

function getPrecio(h: Hotel): number | null {
  if (h.precio_desde != null) return Number(h.precio_desde);
  if (h.price != null) return Number(h.price);
  return null;
}

/** País para título del carrusel: Argentina | Chile | Internacional */
function getPaisLabel(h: Hotel): string | null {
  const raw = (h.pais || '').trim();
  if (/^argentina$/i.test(raw)) return 'Argentina';
  if (/^chile$/i.test(raw)) return 'Chile';
  if (/^internacional/i.test(raw)) return 'Internacional';
  const loc = (h.location || '').toLowerCase();
  if (raw) {
    if (/argentina/i.test(raw) || /argentina/.test(loc)) return 'Argentina';
    if (/chile/i.test(raw) || /chile/.test(loc)) return 'Chile';
    return 'Internacional';
  }
  if (/argentina/.test(loc)) return 'Argentina';
  if (/chile/.test(loc)) return 'Chile';
  return null;
}

export function HotelCard({ hotel, variant = 'default' }: { hotel: Hotel; variant?: 'default' | 'carousel' }) {
  const slug = getSlug(hotel);
  const imgUrl = getImageUrl(hotel);
  const puntuacion = getPuntuacion(hotel);
  const precio = getPrecio(hotel);
  const metodoVenta = hotel.metodo_venta || 'cotizacion';
  const cotizarUrl = buildCotizadorUrl({ hotel_id: hotel.id });
  const isCarousel = variant === 'carousel';
  const waUrl = buildWhatsAppConsultaUrl(hotel.name);
  const reservaUrl = getReservaDirectaUrl(hotel);
  const showReservarCarousel = isCarousel && isHotelTermasPuyehue(hotel) && !!reservaUrl;
  const paisLabel = getPaisLabel(hotel);
  const tituloCarrusel = paisLabel ? `${paisLabel} - ${hotel.name}` : hotel.name;
  const descripcionBreve = hotel.description
    ? String(hotel.description).replace(/\s+/g, ' ').trim().slice(0, 90)
    : null;

  return (
    <article className={`${styles.card} ${isCarousel ? styles.cardCarousel : ''}`}>
      <Link to={`/hotel/${slug}`} className={styles.imageWrap}>
        <img src={imgUrl} alt={hotel.name} className={styles.image} />
        {puntuacion != null && (
          <span className={styles.badge}>
            {puntuacion.toFixed(1)} {hotel.puntuacion_texto || ''}
          </span>
        )}
      </Link>
      <div className={styles.body}>
        {!isCarousel && (
        <div className={styles.location}>
          {[hotel.ciudad, hotel.region, hotel.pais].filter(Boolean).join(' · ') || hotel.location || '—'}
        </div>
        )}
        <h2 className={styles.title}>
          <Link to={`/hotel/${slug}`}>{isCarousel ? tituloCarrusel : hotel.name}</Link>
        </h2>
        {isCarousel && descripcionBreve && (
          <p className={styles.descripcionBreve}>{descripcionBreve}</p>
        )}
        {!isCarousel && (
        <div className={styles.amenities}>
          {hotel.wifi && <span className={styles.amenity} title="Wi‑Fi">Wi‑Fi</span>}
          {hotel.desayuno && <span className={styles.amenity} title="Desayuno">Desayuno</span>}
          {hotel.piscina && <span className={styles.amenity} title="Piscina">Piscina</span>}
          {hotel.estacionamiento && <span className={styles.amenity} title="Estacionamiento">Parking</span>}
          {hotel.pet_friendly && <span className={styles.amenity} title="Pet friendly">Mascotas</span>}
        </div>
        )}
        <div className={isCarousel ? styles.footerCarousel : styles.footer}>
          {!isCarousel && precio != null && (
            <span className={styles.precio}>
              Desde <strong>${precio.toLocaleString('es-AR')}</strong>
            </span>
          )}
          {isCarousel ? (
            <div className={styles.carouselActions}>
              {showReservarCarousel && (
                <button
                  type="button"
                  className={styles.btnReservar}
                  onClick={() => openReservaPopup(reservaUrl!)}
                >
                  Reservar
                </button>
              )}
              <a
                href={waUrl}
                target="_blank"
                rel="noopener noreferrer"
                className={styles.btnWa}
              >
                Hablar con asesor
              </a>
            </div>
          ) : metodoVenta === 'directa' && hotel.url_reserva_directa ? (
            <a
              href={hotel.url_reserva_directa}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.btnSec}
            >
              Reservar
            </a>
          ) : (
            <a href={cotizarUrl} className={styles.btnPrim}>
              Cotizar
            </a>
          )}
        </div>
      </div>
    </article>
  );
}
