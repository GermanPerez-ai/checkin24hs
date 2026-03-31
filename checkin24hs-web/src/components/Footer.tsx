import styles from './Footer.module.css';

const REDES = [
  { name: 'Instagram', url: 'https://instagram.com/checkin24hs', icon: '📷' },
  { name: 'Facebook', url: 'https://facebook.com/checkin24hs', icon: '👍' },
];

export function Footer() {
  return (
    <footer className={styles.footer}>
      <div className="container">
        <div className={styles.grid}>
          <div>
            <strong className={styles.brand}>Checkin24hs</strong>
            <p className={styles.about}>
              Expertos en alojamientos de Patagonia y Buenos Aires. Te ayudamos a encontrar y reservar tu próxima estadía.
            </p>
          </div>
          <div>
            <div className={styles.redes}>
              {REDES.map((r) => (
                <a
                  key={r.name}
                  href={r.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.redLink}
                  aria-label={r.name}
                >
                  {r.icon} {r.name}
                </a>
              ))}
            </div>
          </div>
        </div>
        <div className={styles.legales}>
          <p>
            © {new Date().getFullYear()} Checkin24hs. Todas las imágenes son propiedad de los establecimientos o están utilizadas con fines ilustrativos.
          </p>
          <p className={styles.buildInfo} title="Para verificar que el deploy es el último">
            Build: {typeof __BUILD_TIME__ !== 'undefined' ? new Date(__BUILD_TIME__).toLocaleString('es-AR', { dateStyle: 'short', timeStyle: 'short' }) : '—'}
          </p>
        </div>
      </div>
    </footer>
  );
}
