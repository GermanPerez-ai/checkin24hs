import styles from './BarceloHeader.module.css';

export function BarceloHeader() {
  return (
    <section className={styles.section} aria-label="Exclusivo Barceló">
      <div className="container">
        <div className={styles.media}>
          <img
            src="/exclusivo-barcelo.png"
            alt="Barceló Hotels & Resorts"
            className={styles.bg}
          />
          <div className={styles.overlay} />
        </div>
      </div>
    </section>
  );
}
