#!/bin/bash
# Aplicar fix 401 / Error conexión IMAP: añadir imap_conn_options y smtp_conn_options
# directamente al final de config.inc.php para que Roundcube acepte el certificado autofirmado.
# Ejecutar en el servidor donde corre el servicio checkin24hs_webmail.

set -e
SERVICE_NAME="checkin24hs_webmail"
CONFIG_PATH="/var/www/html/config/config.inc.php"

CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
  echo "No se encontró contenedor webmail. ¿El servicio está corriendo?"
  exit 1
fi

echo "Contenedor webmail: $CONTAINER_ID"
echo ""

# ¿Ya tiene imap_conn_options?
if docker exec "$CONTAINER_ID" grep -q 'imap_conn_options' "$CONFIG_PATH" 2>/dev/null; then
  echo "Ya existe imap_conn_options en config.inc.php. No se añade nada."
  docker exec "$CONTAINER_ID" grep -A 8 'imap_conn_options' "$CONFIG_PATH" | head -12
  exit 0
fi

echo "Añadiendo opciones SSL (certificado autofirmado) al final de config.inc.php..."
docker exec "$CONTAINER_ID" bash -c "cat >> $CONFIG_PATH << 'ENDPHP'
// Fix 401: permitir certificado SSL autofirmado (mail.checkin24hs.com)
\$config['imap_conn_options'] = array(
    'ssl' => array(
        'verify_peer'       => false,
        'verify_peer_name'  => false,
        'allow_self_signed' => true,
    ),
);
\$config['smtp_conn_options'] = array(
    'ssl' => array(
        'verify_peer'       => false,
        'verify_peer_name'  => false,
        'allow_self_signed' => true,
    ),
);
ENDPHP"

echo ""
echo "Verificación (últimas líneas de config.inc.php):"
docker exec "$CONTAINER_ID" tail -20 "$CONFIG_PATH"
echo ""
echo "Listo. Prueba iniciar sesión en el webmail de nuevo."
echo "Si el contenedor se recrea y se pierde el cambio, ejecuta este script otra vez o configura un volumen con config.custom.php (ver SOLUCION_401_WEBMAIL.md)."
