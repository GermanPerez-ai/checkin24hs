import styles from './HeroHome.module.css';

const HERO_IMAGE = 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1600&h=700&fit=crop';

export function HeroHome() {
  return (
    <section className={styles.hero} aria-label="Presentación">
      <img src={HERO_IMAGE} alt="" className={styles.bg} />
      <div className={styles.overlay} />
      <div className={`container ${styles.content}`}>
        <h1 className={styles.title}>Tu próximo viaje, diseñado por expertos</h1>
        <p className={styles.subtitle}>
          Agente de viajes integral · Patagonia, Argentina y destinos internacionales
        </p>
      </div>
    </section>
  );
}
