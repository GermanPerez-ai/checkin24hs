import { Link } from 'react-router-dom';
import { SELECTOR_DESTINOS } from '../data/destinoPaises';
import styles from './SelectorDestinos.module.css';

export function SelectorDestinos() {
  return (
    <section className={styles.section} id="destinos" aria-label="Elegí tu destino">
      <div className="container">
        <div className={styles.grid}>
          {SELECTOR_DESTINOS.map((d) => (
            <Link key={d.slug} to={`/${d.slug}`} className={styles.card}>
              <img src={d.imagen} alt="" className={styles.img} />
              <div className={styles.overlay} />
              <div className={styles.body}>
                <span className={styles.label}>{d.label}</span>
                <span className={styles.resumen}>{d.resumen}</span>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
