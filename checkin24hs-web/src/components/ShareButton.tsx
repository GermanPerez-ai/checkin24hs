import type { ButtonHTMLAttributes } from 'react';

/** Ícono compartir (nodos / share). */
export function ShareIcon({ size = 22 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <circle cx="18" cy="5" r="3" stroke="currentColor" strokeWidth="2" />
      <circle cx="6" cy="12" r="3" stroke="currentColor" strokeWidth="2" />
      <circle cx="18" cy="19" r="3" stroke="currentColor" strokeWidth="2" />
      <path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  label?: string;
};

export function ShareButton({ label = 'Compartir', className, ...rest }: Props) {
  return (
    <button type="button" className={className} aria-label={label} title={label} {...rest}>
      <ShareIcon />
    </button>
  );
}
