import styles from './SobreNosotros.module.css';

export function SobreNosotros() {
  return (
    <section id="sobre-nosotros" className={styles.section}>
      <div className="container">
        <h2 className={styles.title}>Sobre nosotros</h2>
        <div className={styles.content}>
          <p>
            Tu puente experto hacia los mejores destinos de la Patagonia.
          </p>
          <p>
            En <strong>Checkin24hs</strong>, somos tus anfitriones en el sur. Nos especializamos en una selección exclusiva
            de alojamientos de primer nivel en la Patagonia argentina y chilena.
          </p>
          <p>
            <strong>Una década de trayectoria nos avala.</strong> Llevamos 10 años en el mercado conectando viajeros con
            experiencias inolvidables en la cordillera. Durante este tiempo, hemos consolidado un portfolio que integra
            distinguidos hoteles de estándar internacional y los destinos más exclusivos de la Patagonia.
          </p>
          <p>
            Cada establecimiento, desde el prestigioso Hotel Termas de Puyehue hasta la magia de Huilo-Huilo o la nieve
            virgen de Corralco, ha sido elegido personalmente bajo estrictos criterios de calidad, ubicación estratégica
            y calidez en el servicio.
          </p>
          <p>
            <strong>Nuestros pilares:</strong>
          </p>
          <ul className={styles.pilares}>
            <li>
              <strong>Conocimiento real del terreno:</strong> Conocemos cada rincón, desde los senderos del Parque
              Futangue hasta el estado de los pasos fronterizos en tiempo real.
            </li>
            <li>
              <strong>Atención a tu medida:</strong> Te acompañamos en todo el proceso con cotizaciones sin compromiso
              y un asesoramiento humano que marca la diferencia.
            </li>
            <li>
              <strong>Tecnología al servicio del viajero:</strong> Sumamos a nuestra experiencia la rapidez de nuestra
              asistente Flor IA, para que tus consultas y reservas sean simples, seguras y sin vueltas.
            </li>
          </ul>
          <p>
            En Checkin24hs, transformamos una estadía en un recuerdo para toda la vida. Tu próximo viaje empieza con una
            recomendación basada en 10 años de experiencia.
          </p>
        </div>
      </div>
    </section>
  );
}
