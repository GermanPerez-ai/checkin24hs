import { buildWhatsAppConsultaUrl } from '../config';
import styles from './WhatsAppCta.module.css';

type Props = {
  mensajeProducto?: string;
  titulo?: string;
  textoBoton?: string;
};

export function WhatsAppCta({
  mensajeProducto = 'consulta general',
  titulo = '¿Necesitás ayuda personalizada?',
  textoBoton = 'Escribinos por WhatsApp',
}: Props) {
  const href = buildWhatsAppConsultaUrl(mensajeProducto);

  return (
    <section className={styles.section} aria-label="Contacto WhatsApp">
      <div className="container">
        <div className={styles.box}>
          <h2 className={styles.title}>{titulo}</h2>
          <p className={styles.text}>
            Un asesor de Checkin24hs te ayuda a diseñar tu viaje sin compromiso.
          </p>
          <a
            href={href}
            target="_blank"
            rel="noopener noreferrer"
            className={styles.btn}
          >
            {textoBoton}
          </a>
        </div>
      </div>
    </section>
  );
}
