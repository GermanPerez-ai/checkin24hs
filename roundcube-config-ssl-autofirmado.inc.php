<?php
/**
 * Roundcube: permitir certificado SSL autofirmado en IMAP/SMTP
 * Usar solo si el servidor de correo tiene certificado autofirmado o CN distinto al host.
 * Seguridad: desactiva la verificación SSL; en producción es mejor usar un certificado válido.
 */
$config['imap_conn_options'] = array(
    'ssl' => array(
        'verify_peer'       => false,
        'verify_peer_name'  => false,
        'allow_self_signed' => true,
    ),
);
$config['smtp_conn_options'] = array(
    'ssl' => array(
        'verify_peer'       => false,
        'verify_peer_name'  => false,
        'allow_self_signed' => true,
    ),
);
