#!/bin/bash
# Ejecuta este script en tu PC (donde está el repo) para crear el script en el servidor vía SSH.
# Uso: ./CREAR_VERIFICAR_IMAP_EN_SERVIDOR.sh [usuario@servidor]
# Ejemplo: ./CREAR_VERIFICAR_IMAP_EN_SERVIDOR.sh root@srv1152402

SERV="${1:-root@srv1152402}"
SCRIPT_NAME="VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh"

cat << 'SCRIPT_END' | ssh "$SERV" "cat > ~/checkin24hs/$SCRIPT_NAME"
#!/bin/bash

echo "=========================================="
echo "VERIFICACION CONTENEDOR ACTUAL IMAP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"

CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "No se encontro contenedor activo"
    exit 1
fi

echo "Contenedor actual: $CONTAINER_ID"
echo ""

echo "1. Variables de entorno dentro del contenedor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" env | grep -iE "ROUNDCUBE" | sort
echo ""

echo "2. Configuracion actual de Roundcube:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" cat /var/www/html/config/config.docker.inc.php 2>/dev/null | grep -E "imap_host|smtp_host"
echo ""

echo "3. Probando conectividad desde el contenedor:"
echo "----------------------------------------"
echo "   mail.checkin24hs.com:993..."
docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null && echo "   OK" || echo "   FALLO"
echo "   localhost:993..."
docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/localhost/993" 2>/dev/null && echo "   OK" || echo "   FALLO"
echo "   72.61.58.240:993..."
docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/72.61.58.240/993" 2>/dev/null && echo "   OK" || echo "   FALLO"
echo ""

echo "4. Resolucion DNS desde el contenedor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" getent hosts mail.checkin24hs.com 2>/dev/null || docker exec "$CONTAINER_ID" nslookup mail.checkin24hs.com 2>/dev/null
echo ""

echo "5. Conexion SSL directa mail.checkin24hs.com:993:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" timeout 5 openssl s_client -connect mail.checkin24hs.com:993 -quiet 2>&1 | head -3 || echo "   No se pudo conectar"
echo ""

echo "6. Logs del contenedor (errores IMAP):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 30 2>&1 | grep -iE "imap|error|failed|connection" || echo "   Sin errores recientes"
echo ""

echo "7. Red del contenedor:"
echo "----------------------------------------"
docker inspect "$CONTAINER_ID" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} IP: {{$v.IPAddress}} {{end}}' 2>/dev/null
echo ""

echo "8. Ping desde contenedor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" ping -c 2 -W 2 mail.checkin24hs.com >/dev/null 2>&1 && echo "   Ping mail.checkin24hs.com OK" || echo "   Ping mail.checkin24hs.com FALLO"
echo ""

echo "=========================================="
echo "DIAGNOSTICO"
echo "=========================================="
if docker exec "$CONTAINER_ID" timeout 3 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null; then
    echo "El contenedor PUEDE conectarse a mail.checkin24hs.com:993"
    echo "Si el error persiste: certificados SSL, credenciales o servidor IMAP."
else
    echo "El contenedor NO PUEDE conectarse a mail.checkin24hs.com:993"
    echo "SOLUCION: En EasyPanel cambia a localhost:"
    echo "  ROUNDCUBEMAIL_DEFAULT_HOST=localhost"
    echo "  ROUNDCUBEMAIL_SMTP_SERVER=localhost"
    echo "Luego: docker service update --force $SERVICE_NAME"
fi
echo "=========================================="
SCRIPT_END

ssh "$SERV" "chmod +x ~/checkin24hs/$SCRIPT_NAME && echo Creado: ~/checkin24hs/$SCRIPT_NAME"
