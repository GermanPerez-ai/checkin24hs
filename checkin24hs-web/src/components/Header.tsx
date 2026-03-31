import { Link, useLocation } from 'react-router-dom';
import styles from './Header.module.css';

function scrollToSection(hash: string) {
  const id = hash.replace('#', '');
  if (!id) return;
  window.history.replaceState(null, '', `${window.location.pathname || '/'}${window.location.search || ''}#${id}`);
  const el = document.getElementById(id);
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

export function Header() {
  const location = useLocation();
  const isHome = location.pathname === '/';

  return (
    <header className={styles.header}>
      <div className="container">
        <div className={styles.inner}>
          <Link to="/" className={styles.logo}>
            Checkin24hs
          </Link>
          <nav className={styles.nav}>
            <Link to="/">Inicio</Link>
            {isHome ? (
              <>
                <button type="button" className={styles.navLink} onClick={() => scrollToSection('destinos')}>Destinos</button>
                <button type="button" className={styles.navLink} onClick={() => scrollToSection('novedades')}>Novedades</button>
                <button type="button" className={styles.navLink} onClick={() => scrollToSection('sobre-nosotros')}>Nosotros</button>
              </>
            ) : (
              <>
                <Link to="/#destinos">Destinos</Link>
                <Link to="/#novedades">Novedades</Link>
                <Link to="/#sobre-nosotros">Nosotros</Link>
              </>
            )}
          </nav>
        </div>
      </div>
    </header>
  );
}
