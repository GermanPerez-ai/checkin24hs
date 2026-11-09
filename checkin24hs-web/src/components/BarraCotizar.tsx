import { useEffect, useRef, useState } from 'react';
import { buildWhatsAppTextUrl } from '../config';
import styles from './BarraCotizar.module.css';

function todayISO(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function addDaysISO(iso: string, days: number): string {
  const d = new Date(`${iso}T12:00:00`);
  d.setDate(d.getDate() + days);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function formatDMY(iso: string): string {
  const [y, m, d] = iso.split('-');
  if (!y || !m || !d) return iso;
  return `${d}/${m}/${y}`;
}

type TipoViaje = 'ocio' | 'negocios';

export function BarraCotizar() {
  const minDate = todayISO();
  const [destino, setDestino] = useState('');
  const [checkin, setCheckin] = useState('');
  const [checkout, setCheckout] = useState('');
  const [habitaciones, setHabitaciones] = useState(1);
  const [adultos, setAdultos] = useState(2);
  const [ninos, setNinos] = useState(0);
  const [tipo, setTipo] = useState<TipoViaje>('ocio');
  const [openGuests, setOpenGuests] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const guestsRef = useRef<HTMLDivElement>(null);

  const huespedes = adultos + ninos;
  const guestsLabel = `${habitaciones} habitación${habitaciones === 1 ? '' : 'es'} para / ${huespedes} huésped${huespedes === 1 ? '' : 'es'}`;
  const checkoutMin = checkin ? addDaysISO(checkin, 1) : addDaysISO(minDate, 1);

  useEffect(() => {
    if (!openGuests) return;
    const onDoc = (e: MouseEvent) => {
      if (guestsRef.current && !guestsRef.current.contains(e.target as Node)) {
        setOpenGuests(false);
      }
    };
    document.addEventListener('mousedown', onDoc);
    return () => document.removeEventListener('mousedown', onDoc);
  }, [openGuests]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const dest = destino.trim();
    if (!dest) {
      setError('Ingresá un destino.');
      return;
    }
    if (!checkin || !checkout) {
      setError('Elegí check-in y check-out.');
      return;
    }
    if (checkin < minDate) {
      setError('El check-in no puede ser una fecha pasada.');
      return;
    }
    if (checkout <= checkin) {
      setError('El check-out debe ser posterior al check-in.');
      return;
    }
    setError(null);
    const msg =
      `Hola! Quiero cotizar: Destino ${dest}, ` +
      `Check-in ${formatDMY(checkin)}, Check-out ${formatDMY(checkout)}, ` +
      `${habitaciones} ${habitaciones === 1 ? 'habitación' : 'habitaciones'}, ` +
      `${adultos} adulto${adultos === 1 ? '' : 's'}, ${ninos} niño${ninos === 1 ? '' : 's'}, ` +
      `Viaje de ${tipo === 'ocio' ? 'ocio' : 'negocios'}`;
    window.open(buildWhatsAppTextUrl(msg), '_blank', 'noopener,noreferrer');
  };

  return (
    <section className={styles.section} aria-label="Cotizar viaje">
      <div className="container">
        <form className={styles.card} onSubmit={handleSubmit}>
          <div className={styles.row}>
            <label className={`${styles.field} ${styles.destino}`}>
              <span className={styles.fieldLabel}>Destino</span>
              <span className={styles.destinoWrap}>
                <input
                  type="text"
                  className={styles.input}
                  value={destino}
                  onChange={(e) => {
                    setDestino(e.target.value);
                    if (error) setError(null);
                  }}
                  placeholder="San Carlos de Bariloche, Argentina"
                  aria-label="Destino"
                  autoComplete="off"
                />
                {destino && (
                  <button
                    type="button"
                    className={styles.clear}
                    onClick={() => setDestino('')}
                    aria-label="Borrar destino"
                  >
                    ×
                  </button>
                )}
              </span>
            </label>

            <div className={styles.datesCol}>
              <span className={styles.fieldLabel}>Fechas</span>
              <div className={styles.dates}>
                <label className={styles.dateHalf}>
                  <span className={styles.dateMini}>Check-in</span>
                  <input
                    type="date"
                    className={styles.input}
                    value={checkin}
                    min={minDate}
                    onChange={(e) => {
                      const next = e.target.value;
                      setCheckin(next);
                      if (checkout && next && checkout <= next) {
                        setCheckout(addDaysISO(next, 1));
                      }
                      if (error) setError(null);
                    }}
                    aria-label="Check-in"
                    required
                  />
                </label>
                <span className={styles.dateSplit} aria-hidden>
                  |
                </span>
                <label className={styles.dateHalf}>
                  <span className={styles.dateMini}>Check-out</span>
                  <input
                    type="date"
                    className={styles.input}
                    value={checkout}
                    min={checkoutMin}
                    onChange={(e) => {
                      setCheckout(e.target.value);
                      if (error) setError(null);
                    }}
                    aria-label="Check-out"
                    required
                  />
                </label>
              </div>
            </div>

            <div className={styles.guests} ref={guestsRef}>
              <span className={styles.fieldLabel}>Huéspedes</span>
              <button
                type="button"
                className={styles.guestsTrigger}
                aria-expanded={openGuests}
                aria-haspopup="dialog"
                onClick={() => setOpenGuests((v) => !v)}
              >
                {guestsLabel}
              </button>
              {openGuests && (
                <div className={styles.guestsPanel} role="dialog" aria-label="Habitaciones y huéspedes">
                  <div className={styles.stepRow}>
                    <span>Habitaciones</span>
                    <div className={styles.stepper}>
                      <button type="button" onClick={() => setHabitaciones((n) => Math.max(1, n - 1))} aria-label="Menos habitaciones">−</button>
                      <span>{habitaciones}</span>
                      <button type="button" onClick={() => setHabitaciones((n) => Math.min(8, n + 1))} aria-label="Más habitaciones">+</button>
                    </div>
                  </div>
                  <div className={styles.stepRow}>
                    <span>Adultos</span>
                    <div className={styles.stepper}>
                      <button type="button" onClick={() => setAdultos((n) => Math.max(1, n - 1))} aria-label="Menos adultos">−</button>
                      <span>{adultos}</span>
                      <button type="button" onClick={() => setAdultos((n) => Math.min(20, n + 1))} aria-label="Más adultos">+</button>
                    </div>
                  </div>
                  <div className={styles.stepRow}>
                    <span>Niños</span>
                    <div className={styles.stepper}>
                      <button type="button" onClick={() => setNinos((n) => Math.max(0, n - 1))} aria-label="Menos niños">−</button>
                      <span>{ninos}</span>
                      <button type="button" onClick={() => setNinos((n) => Math.min(10, n + 1))} aria-label="Más niños">+</button>
                    </div>
                  </div>
                  <button type="button" className={styles.guestsDone} onClick={() => setOpenGuests(false)}>
                    Listo
                  </button>
                </div>
              )}
            </div>

            <button type="submit" className={styles.buscar}>
              Buscar
            </button>
          </div>

          <fieldset className={styles.tipo}>
            <legend className="sr-only">Tipo de viaje</legend>
            <label className={styles.radio}>
              <input
                type="radio"
                name="tipo-viaje"
                value="ocio"
                checked={tipo === 'ocio'}
                onChange={() => setTipo('ocio')}
              />
              Ocio
            </label>
            <label className={styles.radio}>
              <input
                type="radio"
                name="tipo-viaje"
                value="negocios"
                checked={tipo === 'negocios'}
                onChange={() => setTipo('negocios')}
              />
              Negocios
            </label>
          </fieldset>

          {error && (
            <p className={styles.error} role="alert">
              {error}
            </p>
          )}
        </form>
      </div>
    </section>
  );
}
