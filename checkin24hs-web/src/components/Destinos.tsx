import styles from './Destinos.module.css';

const DESTINOS = [
  {
    id: 'bariloche',
    nombre: 'Bariloche',
    resumen: 'San Carlos de Bariloche es la puerta de entrada a la Patagonia argentina. Rodeada de lagos, bosques y cerros, ofrece esquí en invierno, trekking y chocolate artesanal todo el año. Ideal para naturaleza y gastronomía.',
  },
  {
    id: 'villa-la-angostura',
    nombre: 'Villa La Angostura',
    resumen: 'Villa La Angostura, en la provincia de Neuquén, es un pueblo de montaña junto al lago Nahuel Huapi. Conocido por sus bosques de arrayanes, playas de arena volcánica y ambiente tranquilo, perfecto para desconectar.',
  },
  {
    id: 'san-martin-andes',
    nombre: 'San Martín de los Andes',
    resumen: 'San Martín de los Andes combina lago, montaña y bosque en la Patagonia neuquina. Base para el Parque Nacional Lanín, esquí en Chapelco y deportes náuticos en el Lago Lácar. Destino ideal para aventura y relax.',
  },
];

export function Destinos() {
  return (
    <section id="destinos" className={styles.section}>
      <div className="container">
        <h2 className={styles.title}>Destinos destacados</h2>
        <div className={styles.grid}>
          {DESTINOS.map((d) => (
            <div key={d.id} className={styles.card} data-destino={d.id}>
              <h3 className={styles.cardTitle}>{d.nombre}</h3>
              <p className={styles.resumen}>{d.resumen}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
