/**
 * Configuración de la landing exclusiva Barceló (/barcelo).
 *
 * ÚNICO lugar para editar el orden destacado de hoteles. Cada entrada se
 * compara (sin acentos ni mayúsculas) contra hotels.name del catálogo real de
 * Supabase. Si un hotel de esta lista no está cargado en el catálogo, se
 * ignora: la landing NUNCA inventa hoteles.
 *
 * Orden de la landing:
 *  1) País, de más a menos popular para el mercado argentino (Trends/OTA).
 *  2) Dentro del país, destino/zona por popularidad.
 *  3) Dentro del destino, esta shortlist (Excel México). El resto, por nombre.
 *
 * Si un hotel de esta lista no está cargado en el catálogo, se ignora:
 * la landing NUNCA inventa hoteles. Los 8 de México que no están en el
 * catálogo (Cozumel, Allegro Playacar, Nuevo Vallarta, Ixtapa, Costa Cancún,
 * Allegro Cozumel, Huatulco, Karmina) siguen afuera.
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

export type FlagCode = 'do' | 'mx' | 'cr' | 'aw' | 'ni';

export type BarceloPais = {
  id: string;
  label: string;
  flag: FlagCode;
  /** Nombres de país (ya normalizados) que identifican esta entrada. */
  aliases: string[];
};

/**
 * Países del grupo, de más a menos popular para viajeros desde Argentina.
 * República Dominicana (Punta Cana) lidera la demanda de Caribe all inclusive;
 * México (Cancún / Riviera Maya / Playa del Carmen / Puerto Vallarta) sigue;
 * Costa Rica, Aruba y Nicaragua, en ese orden, tienen menos volumen de búsqueda.
 */
export const BARCELO_PAISES: BarceloPais[] = [
  {
    id: 'republica-dominicana',
    label: 'República Dominicana',
    flag: 'do',
    aliases: ['republica dominicana', 'republica dominicana rd', 'dominican republic', 'dominicana'],
  },
  {
    id: 'mexico',
    label: 'México',
    flag: 'mx',
    aliases: ['mexico'],
  },
  {
    id: 'costa-rica',
    label: 'Costa Rica',
    flag: 'cr',
    aliases: ['costa rica'],
  },
  {
    id: 'aruba',
    label: 'Aruba',
    flag: 'aw',
    aliases: ['aruba'],
  },
  {
    id: 'nicaragua',
    label: 'Nicaragua',
    flag: 'ni',
    aliases: ['nicaragua'],
  },
];

export type BarceloZona = {
  id: string;
  label: string;
  paisId: string;
  /** Fragmentos en región, ciudad, location o nombre (normalizados). */
  match: string[];
};

/**
 * Destinos/zonas, de más a menos popular dentro de cada país (mercado AR).
 * México: Cancún, Riviera Maya, Playa del Carmen, Puerto Vallarta.
 * Costa Rica: Papagayo, Tamarindo, Tambor.
 */
export const BARCELO_ZONAS: BarceloZona[] = [
  // República Dominicana
  { id: 'punta-cana', label: 'Punta Cana', paisId: 'republica-dominicana', match: ['punta cana', 'bavaro', 'higüey', 'higuey', 'macao', 'arena gorda'] },
  // México
  { id: 'cancun', label: 'Cancún', paisId: 'mexico', match: ['cancun', 'tucancun', 'kukulcan'] },
  { id: 'riviera-maya', label: 'Riviera Maya', paisId: 'mexico', match: ['riviera maya', 'xpu ha', 'xpuha', 'maya palace', 'maya riviera', 'maya colonial', 'maya grand'] },
  { id: 'playa-del-carmen', label: 'Playa del Carmen', paisId: 'mexico', match: ['playa del carmen', 'playacar', 'xcaret'] },
  { id: 'puerto-vallarta', label: 'Puerto Vallarta', paisId: 'mexico', match: ['puerto vallarta', 'mismaloya'] },
  // Costa Rica
  { id: 'papagayo', label: 'Papagayo', paisId: 'costa-rica', match: ['papagayo', 'playa hermosa'] },
  { id: 'tamarindo', label: 'Tamarindo', paisId: 'costa-rica', match: ['tamarindo', 'playa langosta'] },
  { id: 'tambor', label: 'Tambor', paisId: 'costa-rica', match: ['tambor'] },
  // Aruba
  { id: 'palm-beach', label: 'Palm Beach', paisId: 'aruba', match: ['palm beach', 'noord', 'irausquin'] },
  // Nicaragua
  { id: 'montelimar', label: 'Montelimar', paisId: 'nicaragua', match: ['montelimar', 'masachapa'] },
];
