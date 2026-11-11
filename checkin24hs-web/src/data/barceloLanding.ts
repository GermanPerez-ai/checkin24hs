/**
 * Configuración de la landing exclusiva Barceló (/barcelo).
 *
 * ÚNICO lugar para editar el orden destacado de hoteles. Cada entrada se
 * compara (sin acentos ni mayúsculas) contra hotels.name del catálogo real de
 * Supabase. Si un hotel de esta lista no está cargado en el catálogo, se
 * ignora: la landing NUNCA inventa hoteles.
 *
 * Fuente del orden: comparacion_hoteles_mexico.xlsx → hoja "Shortlist recomendada"
 * (7 prioritarios, 4 secundarios, 4 no priorizar). Los hoteles del grupo que
 * estén en el catálogo pero no figuren aquí se muestran después, por nombre.
 */

export type BarceloDestacado = {
  /** Etiqueta legible (solo documentación / depuración). */
  etiqueta: string;
  /** Fragmentos de nombre que identifican al hotel en el catálogo (normalizados). */
  match: string[];
  nivel: 'prioritario' | 'secundario' | 'no-priorizar';
};

export const BARCELO_DESTACADOS: BarceloDestacado[] = [
  // ── Prioritarios ────────────────────────────────────────────────
  { etiqueta: 'Royal Hideaway Playacar', match: ['royal hideaway playacar'], nivel: 'prioritario' },
  // Complejo Barceló Maya: Riviera, Palace y Colonial comparten instalaciones.
  // Si en el catálogo solo existe la ficha paraguas "Barceló Maya Grand Resort",
  // ocupa este lugar. No se inventan otras propiedades Maya.
  { etiqueta: 'Barceló Maya Riviera', match: ['barcelo maya riviera'], nivel: 'prioritario' },
  { etiqueta: 'Barceló Maya Palace', match: ['barcelo maya palace'], nivel: 'prioritario' },
  { etiqueta: 'Barceló Maya Colonial', match: ['barcelo maya colonial'], nivel: 'prioritario' },
  { etiqueta: 'Barceló Maya Grand Resort (complejo)', match: ['barcelo maya grand resort'], nivel: 'prioritario' },
  { etiqueta: 'Occidental at Xcaret Destination', match: ['occidental at xcaret', 'occidental xcaret'], nivel: 'prioritario' },
  { etiqueta: 'Occidental Tucancún', match: ['occidental tucancun'], nivel: 'prioritario' },
  { etiqueta: 'Barceló Puerto Vallarta', match: ['barcelo puerto vallarta'], nivel: 'prioritario' },
  // ── Secundarios ─────────────────────────────────────────────────
  { etiqueta: 'Occidental Cozumel', match: ['occidental cozumel'], nivel: 'secundario' },
  { etiqueta: 'Allegro Playacar', match: ['allegro playacar'], nivel: 'secundario' },
  { etiqueta: 'Occidental Nuevo Vallarta', match: ['occidental nuevo vallarta'], nivel: 'secundario' },
  { etiqueta: 'Barceló Ixtapa', match: ['barcelo ixtapa'], nivel: 'secundario' },
  // ── No priorizar (se muestran igual, al final del orden destacado) ─
  { etiqueta: 'Occidental Costa Cancún', match: ['occidental costa cancun'], nivel: 'no-priorizar' },
  { etiqueta: 'Allegro Cozumel', match: ['allegro cozumel'], nivel: 'no-priorizar' },
  { etiqueta: 'Barceló Huatulco', match: ['barcelo huatulco'], nivel: 'no-priorizar' },
  { etiqueta: 'Barceló Karmina', match: ['barcelo karmina'], nivel: 'no-priorizar' },
];

/**
 * Marcas del grupo Barceló reconocidas por nombre (además del flag
 * hotels.grupo_barcelo que se marca desde el Dashboard).
 */
export const BARCELO_MARCAS = ['barcelo', 'occidental', 'allegro', 'royal hideaway'];

export type PerfilBarcelo = 'parejas' | 'familias' | 'solo-adultos';

export const BARCELO_PERFILES: { id: PerfilBarcelo; label: string }[] = [
  { id: 'parejas', label: 'Parejas' },
  { id: 'familias', label: 'Familias' },
  { id: 'solo-adultos', label: 'Solo adultos' },
];

/**
 * Palabras clave usadas para los filtros (sobre nombre + ficha_web + descripción).
 * No hay columna de "perfil" en la tabla hotels: se usa lo que ya cargan las fichas.
 */
export const BARCELO_KEYWORDS = {
  soloAdultos: ['adults only', 'adult only', 'solo adultos', 'exclusiva para adultos', 'exclusivo para adultos', 'no se permiten menores'],
  familias: ['bienvenidos ninos', 'bienvenidos de todas las edades', 'club infantil', 'kids club', 'barcy club', 'miniclub', 'mini club', 'familias', 'familiar'],
  parejas: ['pareja', 'luna de miel', 'romantic', 'romantica', 'romantico'],
};
