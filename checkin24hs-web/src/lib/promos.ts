import type { LandingPromo } from '../types';

export function promoBeneficiosList(beneficios: string | null | undefined): string[] {
  if (!beneficios) return [];
  return String(beneficios)
    .split(/\r?\n|•|\u2022/)
    .map((l) => l.replace(/^[-–—*]\s*/, '').trim())
    .filter(Boolean);
}

export function promoVigente(promo: Pick<LandingPromo, 'vigencia_hasta' | 'activo'>): boolean {
  if (!promo.activo) return false;
  if (!promo.vigencia_hasta) return true;
  const end = new Date(`${promo.vigencia_hasta}T23:59:59`);
  return !Number.isNaN(end.getTime()) && end.getTime() >= Date.now();
}

export function formatPromoVigencia(isoDate: string | null | undefined): string | null {
  if (!isoDate) return null;
  try {
    return new Date(`${isoDate}T12:00:00`).toLocaleDateString('es-AR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  } catch {
    return isoDate;
  }
}
