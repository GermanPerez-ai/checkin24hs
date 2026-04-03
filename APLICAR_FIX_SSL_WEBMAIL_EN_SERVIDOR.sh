#!/bin/bash
# Aplicar fix SSL (certificado autofirmado) en el contenedor webmail.
# Ejecutar en el servidor. El cambio se pierde si el contenedor se recrea;
# para que sea permanente, configura un volumen en EasyPanel (ver SOLUCION_IMAP_CERTIFICADO_SSL_AUTOFIRMADO.md).

set -e
SERVICE_NAME="checkin24hs_webmail"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
  echo "No se encontro contenedor webmail."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_HOST="${SCRIPT_DIR}/roundcube-config-ssl-autofirmado.inc.php"
CONFIG_CONTAINER="/var/www/html/config/config.ssl.inc.php"

if [ -f "$CONFIG_HOST" ]; then
  echo "Copiando $CONFIG_HOST al contenedor como $CONFIG_CONTAINER..."
  docker cp "$CONFIG_HOST" "$CONTAINER_ID:$CONFIG_CONTAINER"
else
  echo "Creando config directamente en el contenedor..."
  docker exec "$CONTAINER_ID" bash -c 'cat > /var/www/html/config/config.ssl.inc.php << "INNER"
<?php
$config["imap_conn_options"] = array(
    "ssl" => array(
        "verify_peer"       => false,
        "verify_peer_name"  => false,
        "allow_self_signed" => true,
    ),
);
$config["smtp_conn_options"] = array(
    "ssl" => array(
        "verify_peer"       => false,
        "verify_peer_name"  => false,
        "allow_self_signed" => true,
    ),
);
INNER'
fi

echo ""
echo "Verificando archivo en el contenedor:"
docker exec "$CONTAINER_ID" head -8 "$CONFIG_CONTAINER"
echo ""
echo "Listo. Prueba iniciar sesion en el webmail."
echo "Nota: Si recreas el servicio, vuelve a ejecutar este script o configura un volumen en EasyPanel."
echo "Ver: SOLUCION_IMAP_CERTIFICADO_SSL_AUTOFIRMADO.md"
