import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import styles from './HotelGallery.module.css';

type Coords = { lat: number; lng: number };

function parseCoords(raw: unknown): Coords | null {
  if (!raw || typeof raw !== 'object') return null;
  const o = raw as Record<string, unknown>;
  const lat = Number(o.lat ?? o.latitude);
  const lng = Number(o.lng ?? o.lon ?? o.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return { lat, lng };
}

function uniqueUrls(urls: (string | null | undefined)[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const u of urls) {
    if (!u || typeof u !== 'string') continue;
    const t = u.trim();
    if (!t || seen.has(t)) continue;
    seen.add(t);
    out.push(t);
  }
  return out;
}

type Props = {
  images: string[];
  hotelName: string;
  coordinates?: unknown;
  googleMapsUrl?: string | null;
  locationLabel?: string;
  badge?: ReactNode;
};

export function HotelGallery({
  images,
  hotelName,
  coordinates,
  googleMapsUrl,
  locationLabel,
  badge,
}: Props) {
  const photos = useMemo(() => uniqueUrls(images), [images]);
  const coords = useMemo(() => parseCoords(coordinates), [coordinates]);
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [index, setIndex] = useState(0);
  const thumbRef = useRef<HTMLDivElement>(null);

  const mapHref = googleMapsUrl?.trim()
    || (coords ? `https://www.google.com/maps?q=${coords.lat},${coords.lng}` : null)
    || (locationLabel ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(locationLabel)}` : null);

  const mapEmbed = coords
    ? `https://www.openstreetmap.org/export/embed.html?bbox=${coords.lng - 0.04}%2C${coords.lat - 0.03}%2C${coords.lng + 0.04}%2C${coords.lat + 0.03}&layer=mapnik&marker=${coords.lat}%2C${coords.lng}`
    : locationLabel
      ? `https://maps.google.com/maps?q=${encodeURIComponent(locationLabel)}&z=12&output=embed`
      : null;

  const openAt = useCallback((i: number) => {
    if (!photos.length) return;
    setIndex(Math.max(0, Math.min(i, photos.length - 1)));
    setLightboxOpen(true);
  }, [photos.length]);

  const close = useCallback(() => setLightboxOpen(false), []);

  const go = useCallback((delta: number) => {
    setIndex((i) => {
      if (!photos.length) return 0;
      return (i + delta + photos.length) % photos.length;
    });
  }, [photos.length]);

  useEffect(() => {
    if (!lightboxOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
      if (e.key === 'ArrowLeft') go(-1);
      if (e.key === 'ArrowRight') go(1);
    };
    document.addEventListener('keydown', onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = prev;
    };
  }, [lightboxOpen, close, go]);

  useEffect(() => {
    if (!lightboxOpen || !thumbRef.current) return;
    const active = thumbRef.current.querySelector(`[data-idx="${index}"]`) as HTMLElement | null;
    active?.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
  }, [index, lightboxOpen]);

  if (!photos.length) return null;

  const moreCount = Math.max(0, photos.length - 4);
  const slot1 = photos[0];
  const slot2 = photos[1] || photos[0];
  const slot3 = photos[2] || photos[0];
  const slot4 = photos[3] || photos[Math.min(1, photos.length - 1)] || photos[0];

  return (
    <>
      <div className={styles.mosaic} role="region" aria-label={`Galería de ${hotelName}`}>
        <button type="button" className={`${styles.tile} ${styles.tileMain}`} onClick={() => openAt(0)}>
          <img src={slot1} alt={`${hotelName} — foto 1`} />
          {badge}
        </button>

        <button type="button" className={`${styles.tile} ${styles.tileTopMid}`} onClick={() => openAt(1 % photos.length)}>
          <img src={slot2} alt={`${hotelName} — foto 2`} />
        </button>

        <div className={`${styles.tile} ${styles.tileMap}`}>
          {mapEmbed ? (
            <>
              <iframe
                title={`Mapa de ${hotelName}`}
                src={mapEmbed}
                className={styles.mapFrame}
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
              />
              {mapHref && (
                <a
                  href={mapHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.mapBtn}
                  onClick={(e) => e.stopPropagation()}
                >
                  Ampliar mapa
                </a>
              )}
            </>
          ) : (
            <button type="button" className={styles.mapFallback} onClick={() => openAt(Math.min(2, photos.length - 1))}>
              <img src={slot3} alt={`${hotelName} — foto 3`} />
            </button>
          )}
        </div>

        <button type="button" className={`${styles.tile} ${styles.tileBotMid}`} onClick={() => openAt(2 % photos.length)}>
          <img src={slot3} alt={`${hotelName} — foto 3`} />
        </button>

        <button
          type="button"
          className={`${styles.tile} ${styles.tileMore}`}
          onClick={() => openAt(Math.min(3, photos.length - 1))}
        >
          <img src={slot4} alt={`${hotelName} — más fotos`} />
          {moreCount > 0 && (
            <span className={styles.moreOverlay}>
              <span className={styles.moreIcon} aria-hidden>
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
                  <rect x="3" y="5" width="10" height="8" rx="1.5" stroke="currentColor" strokeWidth="1.8" />
                  <rect x="11" y="11" width="10" height="8" rx="1.5" stroke="currentColor" strokeWidth="1.8" />
                </svg>
              </span>
              <span>{moreCount} fotos más</span>
            </span>
          )}
        </button>
      </div>

      {lightboxOpen && (
        <div className={styles.lightbox} role="dialog" aria-modal="true" aria-label="Galería de fotos">
          <div className={styles.lbTop}>
            <span className={styles.lbCounter}>
              {index + 1} / {photos.length}
            </span>
            <button type="button" className={styles.lbClose} onClick={close} aria-label="Cerrar">
              ×
            </button>
          </div>

          <button type="button" className={`${styles.lbNav} ${styles.lbPrev}`} onClick={() => go(-1)} aria-label="Anterior">
            ‹
          </button>
          <div className={styles.lbStage}>
            <img src={photos[index]} alt={`${hotelName} — foto ${index + 1}`} className={styles.lbImg} />
          </div>
          <button type="button" className={`${styles.lbNav} ${styles.lbNext}`} onClick={() => go(1)} aria-label="Siguiente">
            ›
          </button>

          <div className={styles.lbThumbs} ref={thumbRef}>
            {photos.map((url, i) => (
              <button
                key={`${url}-${i}`}
                type="button"
                data-idx={i}
                className={`${styles.lbThumb} ${i === index ? styles.lbThumbActive : ''}`}
                onClick={() => setIndex(i)}
              >
                <img src={url} alt="" />
              </button>
            ))}
          </div>
        </div>
      )}
    </>
  );
}
