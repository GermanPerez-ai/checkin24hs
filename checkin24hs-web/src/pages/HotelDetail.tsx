import { useEffect, useState, type ReactNode } from 'react';
import { useParams, Link } from 'react-router-dom';
import { buildWhatsAppConsultaUrl } from '../config';
import { supabase } from '../lib/supabase';
import type { FichaWeb, Hotel } from '../types';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { HotelGallery } from '../components/HotelGallery';
import { useFlorContext } from '../context/FlorContext';
import styles from './HotelDetail.module.css';

function hasText(v: string | null | undefined): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

function parsePuntajeNum(raw: string | number | null | undefined): number {
  if (typeof raw === 'number') return Number.isFinite(raw) ? raw : 0;
  if (raw == null) return 0;
  const m = String(raw).replace(',', '.').match(/(\d+(?:\.\d+)?)/);
  if (!m) return 0;
  const n = parseFloat(m[1]);
  return Number.isFinite(n) ? n : 0;
}

function shortenOpinionLabel(nombre: string): string {
  let n = nombre.trim();
  n = n.replace(/\([^)]*\/\s*10[^)]*\)/gi, '').trim();
  n = n.replace(/^(destacado|opiniones de los clientes|puntuaci[oó]n general)\s*:?\s*/i, '').trim();
  n = n.replace(/^valoraci[oó]n sobresaliente en\s+/i, '').trim();
  if (n.length > 48) {
    const parts = n.split(/,\s*/);
    n = (parts[parts.length - 1] || n).trim();
  }
  if (n.length > 48) n = `${n.slice(0, 45).trim()}…`;
  return n || 'Puntuación';
}

/** Extrae nombre limpio + puntaje desde "Limpieza | 9.4", "Limpieza: 9,4/10", etc. */
function normalizeOpinion(c: { nombre?: string | null; puntaje?: number | string | null } | string) {
  if (typeof c === 'string') {
    return normalizeOpinion({ nombre: c, puntaje: null });
  }
  let nombre = (c.nombre || '').trim();
  let puntaje = parsePuntajeNum(c.puntaje);
  if (puntaje <= 0) {
    // "… (9,0/10 Excelente)" o "… 9,0/10" en cualquier parte del texto
    const inText = nombre.match(/(\d+[.,]\d+|\d+)\s*\/\s*10/);
    if (inText) {
      puntaje = parsePuntajeNum(inText[1]);
    } else {
      const atEnd = nombre.match(/(\d+[.,]\d+|\d+)\s*$/);
      if (atEnd) {
        puntaje = parsePuntajeNum(atEnd[1]);
        nombre = nombre.slice(0, atEnd.index).replace(/[\s:|–—\-]+$/, '').trim();
      }
    }
  }
  return { nombre: shortenOpinionLabel(nombre), puntaje: puntaje > 0 ? puntaje : 0 };
}

/** Saca categorías reales tipo "Limpieza (9,8/10)" desde párrafos mal cargados. */
function extractCategoriasFromText(text: string): { nombre: string; puntaje: number }[] {
  if (!hasText(text)) return [];
  const out: { nombre: string; puntaje: number }[] = [];
  const seen = new Set<string>();

  const reParen = /([A-Za-zÁÉÍÓÚÜáéíóúüñÑ][^()\n]{1,70}?)\s*\((\d+[.,]\d+|\d+)\s*\/\s*10\)/gi;
  let m: RegExpExecArray | null;
  while ((m = reParen.exec(text)) !== null) {
    const puntaje = parsePuntajeNum(m[2]);
    let nombre = shortenOpinionLabel(m[1]);
    // Evitar títulos genéricos sin categoría útil
    if (/^opiniones de los clientes$/i.test(nombre)) nombre = 'Puntuación general';
    const key = nombre.toLowerCase();
    if (puntaje <= 0 || seen.has(key)) continue;
    seen.add(key);
    out.push({ nombre, puntaje });
  }

  if (!out.some((c) => /general/i.test(c.nombre))) {
    const g =
      text.match(/puntuaci[oó]n\s+general\s*:?\s*(\d+[.,]\d+|\d+)\s*\/\s*10/i) ||
      text.match(/\((\d+[.,]\d+|\d+)\s*\/\s*10\s*excelente\)/i) ||
      text.match(/booking\s*:?\s*(\d+[.,]\d+|\d+)\s*\/\s*10/i);
    if (g) {
      const puntaje = parsePuntajeNum(g[1]);
      if (puntaje > 0 && !seen.has('puntuación general')) {
        out.unshift({ nombre: 'Puntuación general', puntaje });
      }
    }
  }

  return out;
}

/** Arma categorías usables para barras verdes (tolera datos mal cargados del dashboard). */
function buildOpinionCategorias(ficha: FichaWeb): { nombre: string; puntaje: number }[] {
  const raw = (ficha.opiniones?.categorias || [])
    .map((c) => normalizeOpinion(c as { nombre?: string | null; puntaje?: number | string | null } | string))
    .filter((c) => hasText(c.nombre));

  const blob = [ficha.opiniones?.resumen || '', ...raw.map((c) => c.nombre)].join('\n');
  const fromText = extractCategoriasFromText(blob);
  if (fromText.length > 0) return fromText;

  // Fallback: solo filas con puntaje > 0
  return raw.filter((c) => c.puntaje > 0);
}

function isFichaEmpty(f: FichaWeb | null | undefined): boolean {
  if (!f || typeof f !== 'object') return true;
  if (hasText(f.sobre_propiedad) || hasText(f.zona) || hasText(f.como_desplazarse)) return false;
  if (Array.isArray(f.servicios) && f.servicios.some((s) => hasText(s))) return false;
  if (Array.isArray(f.cerca) && f.cerca.some((c) => hasText(c?.lugar))) return false;
  if (f.opiniones?.categorias?.some((c) => hasText(c?.nombre))) return false;
  if (hasText(f.opiniones?.resumen)) return false;
  const dt = f.detalles_tecnicos;
  if (dt && Object.values(dt).some((v) => hasText(v))) return false;
  const pol = f.politicas;
  if (pol && Object.values(pol).some((v) => hasText(v))) return false;
  const info = f.informacion_importante;
  if (info && Object.values(info).some((v) => hasText(v))) return false;
  return true;
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>{title}</h2>
      {children}
    </section>
  );
}

function Prose({ htmlOrText }: { htmlOrText: string }) {
  const looksHtml = /<[a-z][\s\S]*>/i.test(htmlOrText);
  if (looksHtml) {
    return <div className={styles.prose} dangerouslySetInnerHTML={{ __html: htmlOrText }} />;
  }
  return (
    <div className={styles.prose}>
      {htmlOrText.split(/\n\n+/).map((p, i) => (
        <p key={i}>{p.trim()}</p>
      ))}
    </div>
  );
}

function SubBlocks({
  items,
}: {
  items: { label: string; value: string | null | undefined }[];
}) {
  const visible = items.filter((i) => hasText(i.value));
  if (!visible.length) return null;
  return (
    <div className={styles.subBlocks}>
      {visible.map((item) => (
        <div key={item.label} className={styles.subBlock}>
          <h3 className={styles.subTitle}>{item.label}</h3>
          <Prose htmlOrText={item.value!} />
        </div>
      ))}
    </div>
  );
}

function PolicyTable({
  rows,
}: {
  rows: { label: string; value: string | null | undefined }[];
}) {
  const visible = rows.filter((r) => hasText(r.value));
  if (!visible.length) return null;
  return (
    <table className={styles.policyTable}>
      <tbody>
        {visible.map((r) => (
          <tr key={r.label}>
            <th scope="row">{r.label}</th>
            <td>{r.value}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function FichaModular({ ficha }: { ficha: FichaWeb }) {
  const servicios = (ficha.servicios || []).map((s) => s.trim()).filter(Boolean);
  const cerca = (ficha.cerca || []).filter((c) => hasText(c?.lugar));
  const categorias = buildOpinionCategorias(ficha);
  const maxScore = categorias.some((c) => c.puntaje > 5) ? 10 : 5;
  // Si las "categorías" eran párrafos enteros, el resumen útil ya está en esas barras; no repetir prosa rota
  const resumenLimpio =
    hasText(ficha.opiniones?.resumen) && ficha.opiniones!.resumen!.trim().length < 280
      ? ficha.opiniones!.resumen!.trim()
      : null;

  return (
    <div className={styles.ficha}>
      {hasText(ficha.sobre_propiedad) && (
        <Section title="Sobre la propiedad">
          <Prose htmlOrText={ficha.sobre_propiedad} />
        </Section>
      )}

      {servicios.length > 0 && (
        <Section title="Servicios principales">
          <ul className={styles.serviceList}>
            {servicios.map((s) => (
              <li key={s} className={styles.serviceItem}>
                <span className={styles.serviceIcon} aria-hidden />
                {s}
              </li>
            ))}
          </ul>
        </Section>
      )}

      {(categorias.length > 0 || !!resumenLimpio) && (
        <Section title="Opiniones de los clientes">
          {resumenLimpio && (
            <p className={styles.opinionResumen}>{resumenLimpio}</p>
          )}
          {categorias.length > 0 && (
            <ul className={styles.opinionList}>
              {categorias.map((c) => {
                const scoreBase = c.puntaje > 5 || maxScore === 10 ? 10 : maxScore;
                const pct = Math.max(0, Math.min(100, (c.puntaje / scoreBase) * 100));
                return (
                  <li key={`${c.nombre}-${c.puntaje}`} className={styles.opinionRow}>
                    <span className={styles.opinionLabel}>{c.nombre}</span>
                    <div className={styles.opinionBarTrack} aria-hidden>
                      <div className={styles.opinionBarFill} style={{ width: `${pct}%` }} />
                    </div>
                    <span className={styles.opinionScore}>{c.puntaje.toFixed(1)}</span>
                  </li>
                );
              })}
            </ul>
          )}
        </Section>
      )}

      {hasText(ficha.zona) && (
        <Section title="Información sobre la zona">
          <Prose htmlOrText={ficha.zona} />
        </Section>
      )}

      {cerca.length > 0 && (
        <Section title="¿Qué hay cerca?">
          <ul className={styles.cercaList}>
            {cerca.map((c) => (
              <li key={`${c.lugar}-${c.distancia}`} className={styles.cercaRow}>
                <span className={styles.cercaLugar}>{c.lugar}</span>
                {hasText(c.distancia) && <span className={styles.cercaDist}>{c.distancia}</span>}
              </li>
            ))}
          </ul>
        </Section>
      )}

      {hasText(ficha.como_desplazarse) && (
        <Section title="Cómo desplazarse">
          <Prose htmlOrText={ficha.como_desplazarse} />
        </Section>
      )}

      {(() => {
        const items = [
          { label: 'Acerca del alojamiento', value: ficha.detalles_tecnicos?.alojamiento },
          { label: 'Acerca de las habitaciones', value: ficha.detalles_tecnicos?.habitaciones },
          { label: 'Sobre las piscinas', value: ficha.detalles_tecnicos?.piscinas },
          { label: 'Restaurantes', value: ficha.detalles_tecnicos?.restaurantes },
          { label: 'Aparcamiento', value: ficha.detalles_tecnicos?.aparcamiento },
          { label: 'Internet', value: ficha.detalles_tecnicos?.internet },
        ];
        if (!items.some((i) => hasText(i.value))) return null;
        return (
          <Section title="Detalles técnicos">
            <SubBlocks items={items} />
          </Section>
        );
      })()}

      {(() => {
        const rows = [
          { label: 'Check-in', value: ficha.politicas?.check_in },
          { label: 'Check-out', value: ficha.politicas?.check_out },
          { label: 'Mascotas', value: ficha.politicas?.mascotas },
          { label: 'Niños', value: ficha.politicas?.ninos },
        ];
        if (!rows.some((r) => hasText(r.value))) return null;
        return (
          <Section title="Políticas">
            <PolicyTable rows={rows} />
          </Section>
        );
      })()}

      {(() => {
        const items = [
          { label: 'Tasas', value: ficha.informacion_importante?.tasas },
          { label: 'IVA', value: ficha.informacion_importante?.iva },
          { label: 'Extras opcionales', value: ficha.informacion_importante?.extras },
          { label: 'Detalles de seguridad', value: ficha.informacion_importante?.seguridad },
          { label: 'Servicios especiales', value: ficha.informacion_importante?.servicios_especiales },
          { label: 'Aviso legal', value: ficha.informacion_importante?.aviso_legal },
        ];
        if (!items.some((i) => hasText(i.value))) return null;
        return (
          <Section title="Información importante">
            <SubBlocks items={items} />
          </Section>
        );
      })()}
    </div>
  );
}

export function HotelDetail() {
  const { slug } = useParams<{ slug: string }>();
  const [hotel, setHotel] = useState<Hotel | null>(null);
  const [loading, setLoading] = useState(true);
  const { setContext } = useFlorContext();

  useEffect(() => {
    if (!slug || !supabase) {
      setLoading(false);
      return;
    }
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(slug);
    let q = supabase.from('hotels').select('*').or('status.eq.active,status.eq.activo,status.eq.Activo,status.is.null');
    q = isUuid ? q.eq('id', slug) : q.eq('slug', slug);
    q.maybeSingle()
      .then(({ data, error }) => {
        if (error && error.code !== 'PGRST116') {
          setLoading(false);
          return;
        }
        setHotel((data as Hotel) || null);
        setLoading(false);
      });
  }, [slug]);

  useEffect(() => {
    if (hotel) {
      setContext({
        hotelSlug: hotel.slug || slug || undefined,
        hotelName: hotel.name,
        kind: 'hotel',
      });
    }
    return () => setContext(undefined);
  }, [hotel, slug, setContext]);

  const imagenPrincipal = hotel?.imagen_principal
    || (Array.isArray(hotel?.galeria_fotos) && hotel?.galeria_fotos?.length ? hotel.galeria_fotos[0] : null)
    || (Array.isArray(hotel?.images) && hotel?.images?.length ? hotel.images[0] : null)
    || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800';

  const galeriaRaw = (hotel?.galeria_fotos && Array.isArray(hotel.galeria_fotos) ? hotel.galeria_fotos : hotel?.images) || [];
  const allPhotos = [
    hotel?.imagen_principal,
    ...galeriaRaw,
    ...(Array.isArray(hotel?.images) ? hotel.images : []),
    imagenPrincipal,
  ].filter(Boolean) as string[];
  const puntuacion = hotel?.puntuacion_num ?? hotel?.rating ?? null;
  const locationLabel = hotel
    ? ([hotel.ciudad, hotel.region, hotel.pais].filter(Boolean).join(', ') || hotel.location || hotel.name)
    : '';

  if (loading) {
    return (
      <>
        <Header />
        <main className="container"><p>Cargando…</p></main>
        <Footer />
      </>
    );
  }

  if (!hotel) {
    return (
      <>
        <Header />
        <main className="container">
          <p>No encontramos ese alojamiento.</p>
          <Link to="/">Volver al inicio</Link>
        </main>
        <Footer />
      </>
    );
  }

  const ficha = hotel.ficha_web;
  const useFicha = !isFichaEmpty(ficha);

  return (
    <>
      <Header />
      <main className={styles.main}>
        <div className="container">
          <nav className={styles.breadcrumb}>
            <Link to="/">Inicio</Link>
            <span>/</span>
            <span>{hotel.name}</span>
          </nav>
          <HotelGallery
            images={allPhotos}
            hotelName={hotel.name}
            coordinates={hotel.coordinates}
            googleMapsUrl={hotel.google_maps}
            locationLabel={locationLabel}
            badge={
              puntuacion != null ? (
                <span className={styles.badge}>
                  {puntuacion.toFixed(1)} {hotel.puntuacion_texto || ''}
                  {hotel.cantidad_opiniones != null && hotel.cantidad_opiniones > 0 && (
                    <> · {hotel.cantidad_opiniones} opiniones</>
                  )}
                </span>
              ) : undefined
            }
          />
          <div className={styles.content}>
            <h1 className={styles.title}>{hotel.name}</h1>
            <p className={styles.location}>
              {[hotel.ciudad, hotel.region, hotel.pais].filter(Boolean).join(' · ') || hotel.location || '—'}
            </p>
            <a
              href={buildWhatsAppConsultaUrl(hotel.name, 'hotel')}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.btnContacto}
            >
              Contactanos
            </a>

            {useFicha ? (
              <FichaModular ficha={ficha!} />
            ) : (
              hotel.description && (
                <div className={styles.desc} dangerouslySetInnerHTML={{ __html: hotel.description }} />
              )
            )}

            <div className={styles.amenities}>
              {hotel.wifi && <span className={styles.amenity}>Wi‑Fi</span>}
              {hotel.desayuno && <span className={styles.amenity}>Desayuno</span>}
              {hotel.piscina && <span className={styles.amenity}>Piscina</span>}
              {hotel.estacionamiento && <span className={styles.amenity}>Estacionamiento</span>}
              {hotel.calefaccion && <span className={styles.amenity}>Calefacción</span>}
              {hotel.pet_friendly && <span className={styles.amenity}>Pet friendly</span>}
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
