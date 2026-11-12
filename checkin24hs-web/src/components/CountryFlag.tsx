import type { FlagCode } from '../data/barceloLanding';
import styles from './CountryFlag.module.css';

/** Banderas geométricas en SVG (sin emoji: en Windows Chrome no se ven). */
const FLAGS: Record<FlagCode, { title: string; svg: JSX.Element }> = {
  do: {
    title: 'República Dominicana',
    svg: (
      <svg viewBox="0 0 16 10" aria-hidden="true" focusable="false">
        <rect width="16" height="10" fill="#fff" />
        <rect width="6.8" height="4.15" fill="#002d62" />
        <rect x="9.2" width="6.8" height="4.15" fill="#ce1126" />
        <rect y="5.85" width="6.8" height="4.15" fill="#ce1126" />
        <rect x="9.2" y="5.85" width="6.8" height="4.15" fill="#002d62" />
      </svg>
    ),
  },
  mx: {
    title: 'México',
    svg: (
      <svg viewBox="0 0 16 10" aria-hidden="true" focusable="false">
        <rect width="16" height="10" fill="#fff" />
        <rect width="5.33" height="10" fill="#006847" />
        <rect x="10.67" width="5.33" height="10" fill="#ce1126" />
      </svg>
    ),
  },
  cr: {
    title: 'Costa Rica',
    svg: (
      <svg viewBox="0 0 16 10" aria-hidden="true" focusable="false">
        <rect width="16" height="10" fill="#002b7f" />
        <rect y="1.67" width="16" height="6.66" fill="#fff" />
        <rect y="3.33" width="16" height="3.34" fill="#ce1126" />
      </svg>
    ),
  },
  aw: {
    title: 'Aruba',
    svg: (
      <svg viewBox="0 0 16 10" aria-hidden="true" focusable="false">
        <rect width="16" height="10" fill="#418fde" />
        <rect y="6.15" width="16" height="0.7" fill="#ffd100" />
        <rect y="7.15" width="16" height="0.7" fill="#ffd100" />
        <polygon
          fill="#ef3340"
          stroke="#fff"
          strokeWidth="0.25"
          points="3.2,1.35 3.55,2.35 4.6,2.35 3.75,2.95 4.1,3.95 3.2,3.35 2.3,3.95 2.65,2.95 1.8,2.35 2.85,2.35"
        />
      </svg>
    ),
  },
  ni: {
    title: 'Nicaragua',
    svg: (
      <svg viewBox="0 0 16 10" aria-hidden="true" focusable="false">
        <rect width="16" height="10" fill="#0067c6" />
        <rect y="3.33" width="16" height="3.34" fill="#fff" />
      </svg>
    ),
  },
};

export function CountryFlag({
  code,
  title,
  className,
}: {
  code?: FlagCode;
  title?: string;
  className?: string;
}) {
  if (!code || !FLAGS[code]) return null;
  const flag = FLAGS[code];
  return (
    <span
      className={`${styles.flag}${className ? ` ${className}` : ''}`}
      role="img"
      aria-label={title || flag.title}
      title={title || flag.title}
    >
      {flag.svg}
    </span>
  );
}
