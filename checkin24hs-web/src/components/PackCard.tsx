import { Link } from 'react-router-dom';
import type { MouseEvent } from 'react';
import { ShareButton } from './ShareButton';
import {
  formatPackPrice,
  getFichaPack,
  getHotelImageUrl,
  getHotelSlug,
  getPackEtiquetaUbicacion,
  getPackPrecio,
} from '../lib/packs';
import { absolutePackUrl, sharePackUrl } from '../lib/share';
import type { Hotel } from '../types';
import styles from './PackCard.module.css';

export function PackCard({ hotel }: { hotel: Hotel }) {
  const slug = getHotelSlug(hotel);
  const img = getHotelImageUrl(hotel);
  const fp = getFichaPack(hotel);
  const noches = fp.noches != null ? Number(fp.noches) : null;
  const destinos = fp.destinos_count != null ? Number(fp.destinos_count) : 1;
  const precio = getPackPrecio(hotel);
  const precioLabel = formatPackPrice(precio, fp.moneda);
  const ubicacion = getPackEtiquetaUbicacion(hotel);
  const href = `/pack/${encodeURIComponent(slug)}`;

  const onShare = async (e: MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    const url = absolutePackUrl(href);
    const result = await sharePackUrl({
      url,
      title: hotel.name,
      text: `Mirá este pack: ${hotel.name}`,
    });
    if (result === 'copied') {
      window.alert('Link copiado al portapapeles');
    }
  };

  return (
    <Link
      to={href}
      className={styles.card}
      aria-label={`Ver pack ${hotel.name}`}
    >
      <img src={img} alt="" className={styles.bg} />
      <div className={styles.shade} />
      <div className={styles.top}>
        <h3 className={styles.title}>{hotel.name}</h3>
        <div className={styles.meta}>
          <span className={styles.metaItem}>
            <span className={styles.icon} aria-hidden>
              📍
            </span>
            {destinos} DESTINO{destinos === 1 ? '' : 'S'}
          </span>
          {noches != null && Number.isFinite(noches) && (
            <span className={styles.metaItem}>
              <span className={styles.icon} aria-hidden>
                🌙
              </span>
              {noches} NOCHE{noches === 1 ? '' : 'S'}
            </span>
          )}
        </div>
      </div>
      <div className={styles.bottom}>
        <div className={styles.priceBlock}>
          {ubicacion && <span className={styles.ubicacion}>{ubicacion}</span>}
          {precioLabel && (
            <>
              <span className={styles.desde}>Desde</span>
              <span className={styles.amount}>{precioLabel}</span>
              <span className={styles.por}>Por persona</span>
            </>
          )}
        </div>
        <div className={styles.ctaCol}>
          <ShareButton className={styles.shareBtn} onClick={onShare} />
          <span className={styles.cta}>¡Quiero ir!</span>
        </div>
      </div>
    </Link>
  );
}
