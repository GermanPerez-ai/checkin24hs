import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import styles from './Institucional.module.css';

const FOTO_INSTITUCIONAL =
  'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=400&fit=crop';

export function Institucional() {
  const [open, setOpen] = useState(false);
  const location = useLocation();

  useEffect(() => {
    if (location.hash === '#sobre-nosotros') {
      setOpen(true);
    }
  }, [location.hash]);

  return (
    <section id="sobre-nosotros" className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <div className={styles.headerText}>
            <button
              type="button"
              className={styles.toggle}
              onClick={() => setOpen((v) => !v)}
              aria-expanded={open}
              aria-controls="institucional-content"
            >
              <h2 className={styles.title}>Somos Checkin24hs: +10 años juntos</h2>
              <span className={`${styles.arrow} ${open ? styles.arrowOpen : ''}`} aria-hidden>
                ›
              </span>
            </button>
            <p className={styles.subtitle}>Tu viaje, diseñado por quienes conocemos el terreno.</p>
          </div>
          <img
            src={FOTO_INSTITUCIONAL}
            alt="Checkin24hs"
            className={styles.foto}
            width={160}
            height={160}
          />
        </div>

        <div
          id="institucional-content"
          className={`${styles.content} ${open ? styles.contentOpen : styles.contentClosed}`}
          hidden={!open}
        >
          <p>
            En <strong>Checkin24hs</strong>, hace más de una década empezamos este camino con un objetivo claro:
            que tus vacaciones no sean solo un viaje, sino una experiencia inolvidable.
          </p>
          <p>
            En Checkin24hs no somos una agencia más. Nacimos en la cordillera, trabajando codo a codo con los mejores
            hoteles de Chile, lo que nos permitió convertirnos en especialistas en la zona. Ese fue nuestro punto de
            partida y, hasta hoy, es uno de nuestros pilares fundamentales. A lo largo de estos 10 años, hemos aprendido
            que no hay dos viajeros iguales; por eso, nuestra forma de trabajar es distinta.
          </p>

          <h3 className={styles.pilaresTitle}>¿Qué nos define?</h3>

          <ul className={styles.pilares}>
            <li>
              <strong>Raíces en Chile y Argentina:</strong> Conocemos cada rincón de los destinos que ofrecemos. Desde
              la calidez de los hoteles con los que comenzamos nuestra trayectoria en Chile, hasta los paisajes de
              nuestra querida Bariloche y los mejores resorts del Caribe y Brasil. Recomendamos solo lo que conocemos y
              sabemos que cumple con los estándares que vos merecés.
            </li>
            <li>
              <strong>Selección Personal:</strong> No trabajamos con catálogos masivos sin sentido. Cada hotel, paquete
              y destino que encontrás en nuestra web es parte de &quot;Nuestros elegidos del mes&quot;, porque sabemos
              que la calidad está en los detalles y que nuestra reputación se basa en la experiencia de quienes ya nos
              eligieron.
            </li>
            <li>
              <strong>Acompañamiento:</strong> Estar certificado como Agente de Viajes no es solo un título; es nuestro
              compromiso con vos para diseñarte el itinerario perfecto, gestionando todo —desde la hotelería en Chile
              hasta tu próximo destino internacional— para que solo te ocupes de disfrutar.
            </li>
          </ul>

          <p>
            Más de una década conectando personas con sus lugares favoritos nos da la experiencia, pero tu confianza es
            lo que nos hace seguir creciendo.
          </p>
          <p>
            <strong>Gracias por ser parte de estos 10 años. Estamos listos para planear tu próxima aventura.</strong>
          </p>
        </div>
      </div>
    </section>
  );
}
