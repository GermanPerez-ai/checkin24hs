import { Link } from 'react-router-dom';
import { buildCotizadorUrl, buildWhatsAppConsultaUrl } from '../config';
import { getReservaDirectaUrl, openReservaPopup } from '../lib/hoteles';
import { formatPackPrice } from '../lib/packs';
import type { Hotel } from '../types';
import styles from './HotelCard.module.css';
import packStyles from './PackCard.module.css';

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

function getPrecio(h: Hotel): number | null {
  const raw = h.precio_desde != null ? h.precio_desde : h.price;
  if (raw == null) return null;
  const n = Number(raw);
  if (!Number.isFinite(n) || n <= 0) return null;
  return n;
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
  const precio = getPrecio(hotel);
  const precioLabel = formatPackPrice(precio, 'USD');
  const metodoVenta = hotel.metodo_venta || 'cotizacion';
  const cotizarUrl = buildCotizadorUrl({ hotel_id: hotel.id });
  const isCarousel = variant === 'carousel';
  const waUrl = buildWhatsAppConsultaUrl(hotel.name, 'hotel');
  const reservaUrl = getReservaDirectaUrl(hotel);
  const showReservarCarousel = isCarousel && !!reservaUrl;
  const paisLabel = getPaisLabel(hotel);
  const destinoLabel =
    [paisLabel || hotel.pais, hotel.ciudad].filter(Boolean).join(' · ') || hotel.location || null;
  const ubicacionLinea = [hotel.ciudad, hotel.pais].filter(Boolean).join(' · ') || hotel.location || null;

  if (isCarousel) {
    return (
      <article className={packStyles.card}>
        <Link to={`/hotel/${slug}`} className={styles.overlayHit} aria-label={hotel.name}>
          <img src={imgUrl} alt="" className={packStyles.bg} />
          <div className={packStyles.shade} />
        </Link>
        <div className={`${packStyles.top} ${styles.overlayFore}`}>
          <h3 className={packStyles.title}>{hotel.name}</h3>
          {ubicacionLinea && (
            <div className={packStyles.meta}>
              <span className={packStyles.metaItem}>
                <span className={packStyles.icon} aria-hidden>
                  📍
                </span>
                {ubicacionLinea}
              </span>
            </div>
          )}
        </div>
        <div className={`${packStyles.bottom} ${styles.overlayFore}`}>
          <div className={packStyles.priceBlock}>
            {destinoLabel && <span className={packStyles.ubicacion}>{destinoLabel}</span>}
            {precioLabel && (
              <>
                <span className={packStyles.desde}>Desde</span>
                <span className={packStyles.amount}>{precioLabel}</span>
                <span className={packStyles.por}>Por noche</span>
              </>
            )}
          </div>
          <div className={`${packStyles.ctaCol} ${styles.overlayActions}`}>
            {showReservarCarousel && (
              <button
                type="button"
                className={packStyles.cta}
                onClick={() => openReservaPopup(reservaUrl!)}
              >
                Reservar
              </button>
            )}
            <a
              href={waUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.btnWaOverlay}
            >
              Hablar con asesor
            </a>
          </div>
        </div>
      </article>
    );
  }

  return (
    <article className={styles.card}>
      <Link to={`/hotel/${slug}`} className={styles.imageWrap}>
        <img src={imgUrl} alt={hotel.name} className={styles.image} />
      </Link>
      <div className={styles.body}>
        <div className={styles.location}>
          {[hotel.ciudad, hotel.region, hotel.pais].filter(Boolean).join(' · ') || hotel.location || '—'}
        </div>
        <h2 className={styles.title}>
          <Link to={`/hotel/${slug}`}>{hotel.name}</Link>
        </h2>
        <div className={styles.amenities}>
          {hotel.wifi && <span className={styles.amenity} title="Wi‑Fi">Wi‑Fi</span>}
          {hotel.desayuno && <span className={styles.amenity} title="Desayuno">Desayuno</span>}
          {hotel.piscina && <span className={styles.amenity} title="Piscina">Piscina</span>}
          {hotel.estacionamiento && <span className={styles.amenity} title="Estacionamiento">Parking</span>}
          {hotel.pet_friendly && <span className={styles.amenity} title="Pet friendly">Mascotas</span>}
        </div>
        <div className={styles.footer}>
          {precioLabel && (
            <span className={styles.precio}>
              Desde <strong>{precioLabel}</strong>
            </span>
          )}
          {metodoVenta === 'directa' && hotel.url_reserva_directa ? (
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
