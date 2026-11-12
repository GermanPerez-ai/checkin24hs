/**
 * Verifica el orden por país/zona y las etiquetas de las 17 fichas reales
 * del catálogo (sin tocar la DB). No inventa los 8 hoteles de México
 * que no están cargados.
 */
import {
  agruparPorPais,
  etiquetaUbicacion,
  ordenarBarcelo,
  paisDeHotel,
  zonaDeHotel,
} from '../src/lib/barcelo';
import type { Hotel } from '../src/types';

type Ficha = {
  name: string;
  pais: string;
  region: string | null;
  ciudad: string | null;
  location: string;
  expectPais: string;
  expectZona: string;
  expectLabel: string;
};

const CATALOGO: Ficha[] = [
  {
    name: 'Barceló Aruba - All Inclusive.',
    pais: 'Caribe',
    region: 'Aruba',
    ciudad: null,
    location: 'J.E. Irausquin Boulevard 83, Palm Beach, Noord, Aruba.',
    expectPais: 'Aruba',
    expectZona: 'Palm Beach',
    expectLabel: 'Aruba · Palm Beach',
  },
  {
    name: 'Barceló Bávaro Beach - Adults Only - All Inclusive',
    pais: 'Caribe',
    region: 'República Dominicana',
    ciudad: null,
    location: 'Calle Principal Hotel Barceló Km. 1, Punta Cana 03177, República Dominicana',
    expectPais: 'República Dominicana',
    expectZona: 'Punta Cana',
    expectLabel: 'República Dominicana · Punta Cana',
  },
  {
    name: 'Barceló Bávaro Palace - All Inclusive',
    pais: 'Caribe',
    region: 'República Dominicana',
    ciudad: null,
    location: 'Carretera Bávaro, Km. 1, P.O. Box 3177, Bavaro, Higuey, Punta Cana 23301 , a 3,5 km de Centro',
    expectPais: 'República Dominicana',
    expectZona: 'Punta Cana',
    expectLabel: 'República Dominicana · Punta Cana',
  },
  {
    name: 'Occidental Caribe - All Inclusive',
    pais: 'Caribe',
    region: 'República Dominicana',
    ciudad: null,
    location: 'Carretera El Macao Playa Arena Gorda, Punta Cana 23301, República Dominicana',
    expectPais: 'República Dominicana',
    expectZona: 'Punta Cana',
    expectLabel: 'República Dominicana · Punta Cana',
  },
  {
    name: 'Occidental Punta Cana - All Inclusive',
    pais: 'Caribe',
    region: 'República Dominicana',
    ciudad: null,
    location: 'Av. España, Punta Cana 23301, República Dominicana',
    expectPais: 'República Dominicana',
    expectZona: 'Punta Cana',
    expectLabel: 'República Dominicana · Punta Cana',
  },
  {
    name: 'Barceló Tambor',
    pais: 'Costa Rica',
    region: null,
    ciudad: null,
    location: 'Ruta Nacional Secundaria 160 771, Provincia de Puntarenas, Tambor, Playa, 11500, Costa Rica',
    expectPais: 'Costa Rica',
    expectZona: 'Tambor',
    expectLabel: 'Costa Rica · Tambor',
  },
  {
    name: 'Occidental Papagayo - All Inclusive Adults Only',
    pais: 'Costa Rica',
    region: null,
    ciudad: null,
    location: '255 Blvd. Playa Hermosa 800 metros al norte 48-5000 Golfo Guanacaste Province, Guanacaste Province, 50503, Costa Rica',
    expectPais: 'Costa Rica',
    expectZona: 'Papagayo',
    expectLabel: 'Costa Rica · Papagayo',
  },
  {
    name: 'Occidental Tamarindo - All Inclusive',
    pais: 'Costa Rica',
    region: null,
    ciudad: null,
    location: 'Avenida España Calle Playa Langosta, Provincia de Guanacaste, Tamarindo, 50309, Costa Rica',
    expectPais: 'Costa Rica',
    expectZona: 'Tamarindo',
    expectLabel: 'Costa Rica · Tamarindo',
  },
  {
    name: 'Occidental Tucancún All Inclusive',
    pais: 'México',
    region: 'Cancún',
    ciudad: null,
    location: 'Boulevard Kukulcán Km 14, Lote 24, Zona Hotelera, Cancún 77500, Quintana Roo, México.',
    expectPais: 'México',
    expectZona: 'Cancún',
    expectLabel: 'México · Cancún',
  },
  {
    name: 'Occidental at Xcaret Destination',
    pais: 'México',
    region: 'Playa del Carmen',
    ciudad: null,
    location: 'Camino a Xcaret Carretera Federal Chetumal - Puerto, Avenida Benito Juárez, 282, 77710 Playa del Carmen, Q.R., México',
    expectPais: 'México',
    expectZona: 'Playa del Carmen',
    expectLabel: 'México · Playa del Carmen',
  },
  {
    name: 'Royal Hideaway Playacar - Adults only',
    pais: 'México',
    region: 'Playa del Carmen',
    ciudad: null,
    location: 'P.º Xaman - Ha Calle, Playacar, 77710 Playa del Carmen, Q.R., México',
    expectPais: 'México',
    expectZona: 'Playa del Carmen',
    expectLabel: 'México · Playa del Carmen',
  },
  {
    name: 'Barceló Puerto Vallarta - All Inclusive',
    pais: 'México',
    region: 'Puerto Vallarta',
    ciudad: null,
    location: 'Manzanillo - Puerto Vallarta Km. 11,5, Zona Hotelera Sur, 48300 Mismaloya, Jal., México',
    expectPais: 'México',
    expectZona: 'Puerto Vallarta',
    expectLabel: 'México · Puerto Vallarta',
  },
  {
    name: 'Barceló Maya Colonial - All Inclusive',
    pais: 'México',
    region: 'Riviera Maya',
    ciudad: null,
    location: 'Chetumal-Cancun Km. 266,3 Xpuha Carretera, Puerto Juárez Xpu-Há, 77750 Riviera Maya, Q.R., México',
    expectPais: 'México',
    expectZona: 'Riviera Maya',
    expectLabel: 'México · Riviera Maya',
  },
  {
    name: 'Barceló Maya Grand Resort',
    pais: 'México',
    region: 'Riviera Maya',
    ciudad: null,
    location: 'Chetumal-Cancun Carretera Puerto Juárez Km. 266,3 Xpu-Há, 77750 Playa del Carmen, Q.R., México',
    expectPais: 'México',
    expectZona: 'Riviera Maya',
    expectLabel: 'México · Riviera Maya',
  },
  {
    name: 'Barceló Maya Palace - All Inclusive',
    pais: 'México',
    region: 'Riviera Maya',
    ciudad: null,
    location: 'Carretera Tulum-Playa del Carmen Km. 266 Chetumal 3 Calle Margarita Maza Xpu-Há, 77750 Riviera Maya, Q.R., México',
    expectPais: 'México',
    expectZona: 'Riviera Maya',
    expectLabel: 'México · Riviera Maya',
  },
  {
    name: 'Barceló Maya Riviera - All Inclusive Adults only',
    pais: 'México',
    region: 'Riviera Maya',
    ciudad: null,
    location: 'Carretera Chetumal Puerto Juárez, Carr. Tulum - Cancún Km. 266,3, 77734 Xpu Ha, Q.R., México',
    expectPais: 'México',
    expectZona: 'Riviera Maya',
    expectLabel: 'México · Riviera Maya',
  },
  {
    name: 'Barceló Montelimar - All Inclusive',
    pais: 'Nicaragua',
    region: null,
    ciudad: null,
    location: 'Km. 65, Carretera San Rafael del Sur-Masachapa, Montelimar 16700, Nicaragua',
    expectPais: 'Nicaragua',
    expectZona: 'Montelimar',
    expectLabel: 'Nicaragua · Montelimar',
  },
];

const EXCLUIDOS = [
  'Occidental Cozumel',
  'Allegro Playacar',
  'Occidental Nuevo Vallarta',
  'Barceló Ixtapa',
  'Occidental Costa Cancún',
  'Allegro Cozumel',
  'Barceló Huatulco',
  'Barceló Karmina',
];

function asHotel(f: Ficha, i: number): Hotel {
  return {
    id: String(i),
    name: f.name,
    pais: f.pais,
    region: f.region,
    ciudad: f.ciudad,
    location: f.location,
    grupo_barcelo: true,
  } as Hotel;
}

let failed = 0;
function assert(cond: boolean, msg: string) {
  if (!cond) {
    failed += 1;
    console.error('FAIL:', msg);
  }
}

const hotels = CATALOGO.map(asHotel);

for (const f of CATALOGO) {
  const h = asHotel(f, 0);
  const pais = paisDeHotel(h);
  const zona = zonaDeHotel(h);
  const et = etiquetaUbicacion(h);
  assert(pais.label === f.expectPais, `${f.name}: país "${pais.label}" != "${f.expectPais}"`);
  assert(zona.label === f.expectZona, `${f.name}: zona "${zona.label}" != "${f.expectZona}"`);
  assert(et.label === f.expectLabel, `${f.name}: etiqueta "${et.label}" != "${f.expectLabel}"`);
  assert(!!et.flag, `${f.name}: falta flag`);
}

const ordered = ordenarBarcelo(hotels);
const names = ordered.map((h) => h.name);
const paisOrder = ['República Dominicana', 'México', 'Costa Rica', 'Aruba', 'Nicaragua'];
const seenPaises: string[] = [];
for (const h of ordered) {
  const p = paisDeHotel(h).label;
  if (seenPaises[seenPaises.length - 1] !== p) seenPaises.push(p);
}
assert(JSON.stringify(seenPaises) === JSON.stringify(paisOrder), `orden países: ${seenPaises.join(' | ')}`);

const grupos = agruparPorPais(ordered);
assert(grupos.map((g) => g.label).join('|') === paisOrder.join('|'), `grupos: ${grupos.map((g) => g.label).join('|')}`);

const mx = grupos.find((g) => g.id === 'mexico')!;
assert(
  mx.destinos.map((d) => d.label).join('|') === 'Cancún|Riviera Maya|Playa del Carmen|Puerto Vallarta',
  `México destinos: ${mx.destinos.map((d) => d.label).join('|')}`
);
assert(mx.destinos.find((d) => d.id === 'playa-del-carmen')!.hotels[0].name.startsWith('Royal Hideaway'), 'Playacar: Royal Hideaway primero');
assert(mx.destinos.find((d) => d.id === 'riviera-maya')!.hotels[0].name.includes('Maya Riviera'), 'Maya: Riviera primero');

const cr = grupos.find((g) => g.id === 'costa-rica')!;
assert(
  cr.destinos.map((d) => d.label).join('|') === 'Papagayo|Tamarindo|Tambor',
  `Costa Rica destinos: ${cr.destinos.map((d) => d.label).join('|')}`
);

const catalogoNorm = new Set(CATALOGO.map((f) => f.name.toLowerCase()));
for (const ex of EXCLUIDOS) {
  assert(!catalogoNorm.has(ex.toLowerCase()), `excluido aparece en catálogo fixture: ${ex}`);
  assert(!names.some((n) => n.toLowerCase() === ex.toLowerCase()), `excluido aparece en orden: ${ex}`);
}
assert(ordered.length === 17, `esperaba 17 hoteles, hay ${ordered.length}`);

if (failed) {
  console.error(`\n${failed} chequeo(s) fallaron`);
  process.exit(1);
}
console.log('OK: 17 hoteles, orden RD → México → Costa Rica → Aruba → Nicaragua');
console.log(
  grupos
    .map((g) => `${g.label}: ${g.destinos.map((d) => `${d.label} (${d.hotels.length})`).join(', ')}`)
    .join('\n')
);
