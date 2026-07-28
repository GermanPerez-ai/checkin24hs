import { useEffect, useId, useRef, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import styles from './Header.module.css';

const NAV = [
  { to: '/', label: 'Inicio' },
  { to: '/argentina', label: 'Argentina' },
  { to: '/chile', label: 'Chile' },
  { to: '/internacionales', label: 'Internacionales' },
  { to: '/packs', label: 'Packs' },
] as const;

export function Header() {
  const location = useLocation();
  const [menuOpen, setMenuOpen] = useState(false);
  const menuId = useId();
  const wrapRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMenuOpen(false);
  }, [location.pathname]);

  useEffect(() => {
    if (!menuOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setMenuOpen(false);
    };
    const onPointer = (e: MouseEvent | TouchEvent) => {
      const el = wrapRef.current;
      if (el && e.target instanceof Node && !el.contains(e.target)) {
        setMenuOpen(false);
      }
    };
    document.addEventListener('keydown', onKey);
    document.addEventListener('mousedown', onPointer);
    document.addEventListener('touchstart', onPointer);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('mousedown', onPointer);
      document.removeEventListener('touchstart', onPointer);
    };
  }, [menuOpen]);

  return (
    <header className={styles.header}>
      <div className="container">
        <div className={styles.inner} ref={wrapRef}>
          <Link to="/" className={styles.logo}>
            Checkin24hs
          </Link>

          <nav className={styles.navDesktop} aria-label="Principal">
            {NAV.map(({ to, label }) => (
              <Link
                key={to}
                to={to}
                className={location.pathname === to ? styles.navActive : undefined}
                aria-current={location.pathname === to ? 'page' : undefined}
              >
                {label}
              </Link>
            ))}
          </nav>

          <button
            type="button"
            className={styles.burger}
            aria-label={menuOpen ? 'Cerrar menú' : 'Abrir menú'}
            aria-expanded={menuOpen}
            aria-controls={menuId}
            onClick={() => setMenuOpen((o) => !o)}
          >
            <span className={styles.burgerLine} />
            <span className={styles.burgerLine} />
            <span className={styles.burgerLine} />
          </button>

          <nav
            id={menuId}
            className={`${styles.navMobile} ${menuOpen ? styles.navMobileOpen : ''}`}
            aria-label="Menú móvil"
            hidden={!menuOpen}
          >
            {NAV.map(({ to, label }) => (
              <Link
                key={to}
                to={to}
                className={location.pathname === to ? styles.navActive : undefined}
                aria-current={location.pathname === to ? 'page' : undefined}
                onClick={() => setMenuOpen(false)}
              >
                {label}
              </Link>
            ))}
          </nav>
        </div>
      </div>
    </header>
  );
}
