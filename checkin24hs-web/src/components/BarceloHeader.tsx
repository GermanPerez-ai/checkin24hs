import styles from './BarceloHeader.module.css';

export function BarceloHeader() {
  return (
    <div className={styles.header}>
      <img src="/exclusivo-barcelo.png" alt="Barceló Hotels & Resorts" className={styles.bg} />
      <div className={styles.overlay} />
    </div>
  );
}
