import { Link, useLocation } from 'react-router-dom';
import styles from './Header.module.css';

const NAV = [
  { to: '/', label: 'Inicio' },
  { to: '/argentina', label: 'Argentina' },
  { to: '/chile', label: 'Chile' },
  { to: '/internacionales', label: 'Internacionales' },
] as const;

export function Header() {
  const location = useLocation();

  return (
    <header className={styles.header}>
      <div className="container">
        <div className={styles.inner}>
          <Link to="/" className={styles.logo}>
            Checkin24hs
          </Link>
          <nav className={styles.nav} aria-label="Principal">
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
        </div>
      </div>
    </header>
  );
}
