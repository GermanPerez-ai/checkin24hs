import { useState, useMemo, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { DayPicker } from 'react-day-picker';
import { es } from 'date-fns/locale';
import type { DateRange } from 'react-day-picker';
import styles from './Buscador.module.css';

function useMediaQuery(query: string): boolean {
  const [match, setMatch] = useState(() =>
    typeof window !== 'undefined' ? window.matchMedia(query).matches : false
  );
  useEffect(() => {
    const m = window.matchMedia(query);
    const handler = () => setMatch(m.matches);
    m.addEventListener('change', handler);
    setMatch(m.matches);
    return () => m.removeEventListener('change', handler);
  }, [query]);
  return match;
}

const PAISES = ['Argentina', 'Chile'];
const CIUDADES: Record<string, string[]> = {
  Argentina: ['Bariloche', 'Villa La Angostura', 'San Martín de los Andes', 'CABA', 'Patagonia'],
  Chile: ['Pucón', 'Puyehue', 'Futangue', 'Termas'],
};

function formatFechasDisplay(checkin: string, checkout: string): string {
  if (!checkin) return 'Seleccionar fechas';
  const from = new Date(checkin + 'T12:00:00');
  const to = checkout ? new Date(checkout + 'T12:00:00') : from;
  const opts: Intl.DateTimeFormatOptions = { weekday: 'short', day: 'numeric', month: 'short' };
  const a = from.toLocaleDateString('es', opts);
  const b = to.toLocaleDateString('es', opts);
  return checkout ? `${a} - ${b}` : a;
}

function parsePaxFromUrl(searchParams: URLSearchParams): { adultos: number; ninos: number; infantes: number } {
  const a = Math.min(20, Math.max(1, parseInt(searchParams.get('adultos') || '', 10) || 2));
  const n = Math.min(10, Math.max(0, parseInt(searchParams.get('ninos') || '', 10) || 0));
  const i = Math.min(5, Math.max(0, parseInt(searchParams.get('infantes') || '', 10) || 0));
  const pax = parseInt(searchParams.get('pax') || '', 10);
  if (pax >= 1 && a === 2 && n === 0 && i === 0) {
    return { adultos: Math.min(20, pax), ninos: 0, infantes: 0 };
  }
  return { adultos: a, ninos: n, infantes: i };
}

export function Buscador() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [pais, setPais] = useState(searchParams.get('pais') || '');
  const [ciudad, setCiudad] = useState(searchParams.get('ciudad') || '');
  const [checkin, setCheckin] = useState(searchParams.get('checkin') || '');
  const [checkout, setCheckout] = useState(searchParams.get('checkout') || '');
  const fromUrl = parsePaxFromUrl(searchParams);
  const [adultos, setAdultos] = useState(fromUrl.adultos);
  const [ninos, setNinos] = useState(fromUrl.ninos);
  const [infantes, setInfantes] = useState(fromUrl.infantes);
  const [showCalendar, setShowCalendar] = useState(false);
  const [showHuespedes, setShowHuespedes] = useState(false);
  const isMobile = useMediaQuery('(max-width: 768px)');

  const totalHuespedes = adultos + ninos + infantes;
  const huespedesLabel =
    totalHuespedes === 0
      ? 'Huéspedes'
      : infantes === 0 && ninos === 0
        ? `${adultos} ${adultos === 1 ? 'adulto' : 'adultos'}`
        : [adultos && `${adultos} adulto${adultos !== 1 ? 's' : ''}`, ninos && `${ninos} niño${ninos !== 1 ? 's' : ''}`, infantes && `${infantes} infante${infantes !== 1 ? 's' : ''}`].filter(Boolean).join(', ');

  const ciudades = pais ? (CIUDADES[pais] || []) : [];

  useEffect(() => {
    const next = parsePaxFromUrl(searchParams);
    setAdultos(next.adultos);
    setNinos(next.ninos);
    setInfantes(next.infantes);
  }, [searchParams.get('adultos'), searchParams.get('ninos'), searchParams.get('infantes'), searchParams.get('pax')]);

  const range: DateRange | undefined = useMemo(() => {
    if (!checkin) return undefined;
    const from = new Date(checkin + 'T12:00:00');
    const to = checkout ? new Date(checkout + 'T12:00:00') : from;
    return { from, to: checkout ? to : from };
  }, [checkin, checkout]);

  const handleRangeSelect = (r: DateRange | undefined) => {
    if (r?.from) {
      setCheckin(r.from.toISOString().slice(0, 10));
      setCheckout(r.to ? r.to.toISOString().slice(0, 10) : '');
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const params = new URLSearchParams();
    if (pais) params.set('pais', pais);
    if (ciudad) params.set('ciudad', ciudad);
    if (checkin) params.set('checkin', checkin);
    if (checkout) params.set('checkout', checkout);
    if (totalHuespedes) params.set('pax', String(totalHuespedes));
    if (adultos) params.set('adultos', String(adultos));
    if (ninos) params.set('ninos', String(ninos));
    if (infantes) params.set('infantes', String(infantes));
    navigate(`/?${params.toString()}`);
  };

  return (
    <section className={styles.buscador} aria-label="Buscar alojamiento">
      <div className="container">
        <form onSubmit={handleSubmit} className={styles.form}>
          <div className={styles.row}>
            <label className={styles.label}>
              <span className="sr-only">País</span>
              <select
                value={pais}
                onChange={(e) => { setPais(e.target.value); setCiudad(''); }}
                className={styles.select}
                aria-label="País"
              >
                <option value="">País</option>
                {PAISES.map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
            </label>
            <label className={styles.label}>
              <span className="sr-only">Ciudad</span>
              <select
                value={ciudad}
                onChange={(e) => setCiudad(e.target.value)}
                className={styles.select}
                disabled={!pais}
                aria-label="Ciudad"
              >
                <option value="">Ciudad / Región</option>
                {ciudades.map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </label>
            <label className={styles.label}>
              <span className="sr-only">Fechas</span>
              <button
                type="button"
                onClick={() => setShowCalendar(true)}
                className={styles.fechasTrigger}
                aria-label="Seleccionar fechas de entrada y salida"
              >
                <span className={styles.fechasIcon} aria-hidden>📅</span>
                {formatFechasDisplay(checkin, checkout)}
              </button>
            </label>
            <label className={styles.label}>
              <span className="sr-only">Huéspedes</span>
              <div className={styles.huespedesWrap}>
                <button
                  type="button"
                  onClick={() => setShowHuespedes((v) => !v)}
                  className={styles.fechasTrigger}
                  aria-label="Seleccionar huéspedes"
                  aria-expanded={showHuespedes}
                >
                  <span className={styles.fechasIcon} aria-hidden>👤</span>
                  {huespedesLabel}
                </button>
                {showHuespedes && (
                  <>
                    <div className={styles.huespedesBackdrop} onClick={() => setShowHuespedes(false)} />
                    <div className={styles.huespedesPanel}>
                      <div className={styles.huespedesRow}>
                        <span>Adultos</span>
                        <div className={styles.huespedesStepper}>
                          <button type="button" onClick={() => setAdultos((n) => Math.max(1, n - 1))} aria-label="Menos adultos">−</button>
                          <span>{adultos}</span>
                          <button type="button" onClick={() => setAdultos((n) => Math.min(20, n + 1))} aria-label="Más adultos">+</button>
                        </div>
                      </div>
                      <div className={styles.huespedesRow}>
                        <span>Niños</span>
                        <div className={styles.huespedesStepper}>
                          <button type="button" onClick={() => setNinos((n) => Math.max(0, n - 1))} aria-label="Menos niños">−</button>
                          <span>{ninos}</span>
                          <button type="button" onClick={() => setNinos((n) => Math.min(10, n + 1))} aria-label="Más niños">+</button>
                        </div>
                      </div>
                      <div className={styles.huespedesRow}>
                        <span>Infantes</span>
                        <div className={styles.huespedesStepper}>
                          <button type="button" onClick={() => setInfantes((n) => Math.max(0, n - 1))} aria-label="Menos infantes">−</button>
                          <span>{infantes}</span>
                          <button type="button" onClick={() => setInfantes((n) => Math.min(5, n + 1))} aria-label="Más infantes">+</button>
                        </div>
                      </div>
                      <button type="button" onClick={() => setShowHuespedes(false)} className={styles.huespedesCerrar}>
                        Listo
                      </button>
                    </div>
                  </>
                )}
              </div>
            </label>
            <button type="submit" className={styles.btn}>
              Buscar
            </button>
          </div>
        </form>
      </div>

      {showCalendar && (
        <div className={styles.calendarOverlay} role="dialog" aria-modal="true" aria-label="Calendario de fechas">
          <div className={styles.calendarBackdrop} onClick={() => setShowCalendar(false)} />
          <div className={styles.calendarModal}>
            <div className={styles.calendarHeader}>
              <button
                type="button"
                onClick={() => setShowCalendar(false)}
                className={styles.calendarClose}
                aria-label="Cerrar"
              >
                ✕
              </button>
              <h3 className={styles.calendarTitle}>Calendario</h3>
            </div>
            {range?.from && (
              <p className={styles.calendarRangeLabel}>
                {range.from.toLocaleDateString('es', { weekday: 'short', day: 'numeric', month: 'short' })}
                {range.to && range.to.getTime() !== range.from.getTime() && (
                  <> → {range.to.toLocaleDateString('es', { weekday: 'short', day: 'numeric', month: 'short' })}</>
                )}
              </p>
            )}
            <DayPicker
              mode="range"
              locale={es}
              selected={range}
              onSelect={handleRangeSelect}
              numberOfMonths={isMobile ? 1 : 2}
              className={styles.dayPicker}
              disabled={{ before: new Date() }}
            />
            <div className={styles.calendarActions}>
              <button
                type="button"
                onClick={() => setShowCalendar(false)}
                className={styles.calendarListo}
              >
                Listo
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}
