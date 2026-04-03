# Crear script de verificación IMAP en el servidor

El script no está en el servidor. Puedes crearlo de dos formas:

---

## Opción 1: Crear el archivo pegando el contenido (recomendado)

En el servidor, ejecuta:

```bash
cd ~/checkin24hs
nano VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
```

Pega todo el contenido que está abajo (entre las líneas "---INICIO---" y "---FIN---"), guarda con `Ctrl+O`, `Enter`, y sale con `Ctrl+X`.

Luego:

```bash
chmod +x VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
./VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
```

---

## Opción 2: Crear el archivo con un solo comando (copiar y pegar todo el bloque)

Conéctate al servidor y ejecuta **todo** este bloque en la terminal (una sola vez):

```bash
cd ~/checkin24hs

cat > VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh << 'EOF'
#!/bin/bash
SERVICE_NAME="checkin24hs_webmail"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
[ -z "$CONTAINER_ID" ] && { echo "No contenedor webmail"; exit 1; }
echo "Contenedor: $CONTAINER_ID"
echo "1. Variables ROUNDCUBE en contenedor:"
docker exec "$CONTAINER_ID" env | grep ROUNDCUBE | sort
echo ""
echo "2. config.docker.inc.php (imap/smtp):"
docker exec "$CONTAINER_ID" cat /var/www/html/config/config.docker.inc.php 2>/dev/null | grep -E "imap_host|smtp_host"
echo ""
echo "3. Conectividad desde contenedor:"
docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null && echo "  mail.checkin24hs.com:993 OK" || echo "  mail.checkin24hs.com:993 FALLO"
docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/localhost/993" 2>/dev/null && echo "  localhost:993 OK" || echo "  localhost:993 FALLO"
echo ""
echo "4. DNS desde contenedor:"
docker exec "$CONTAINER_ID" getent hosts mail.checkin24hs.com 2>/dev/null || echo "  No se pudo resolver"
echo ""
echo "5. Ultimos logs IMAP/error:"
docker logs "$CONTAINER_ID" --tail 20 2>&1 | grep -iE "imap|error" || echo "  Sin errores recientes"
echo ""
echo "=== DIAGNOSTICO ==="
if docker exec "$CONTAINER_ID" timeout 3 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null; then
  echo "Contenedor PUEDE conectar a mail.checkin24hs.com:993"
else
  echo "Contenedor NO puede conectar. Usa localhost en EasyPanel:"
  echo "  ROUNDCUBEMAIL_DEFAULT_HOST=localhost"
  echo "  ROUNDCUBEMAIL_SMTP_SERVER=localhost"
  echo "  docker service update --force $SERVICE_NAME"
fi
EOF

chmod +x VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
./VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
```

Eso crea el script, lo hace ejecutable y lo ejecuta.

---

## Opción 3: Subir el script desde tu PC

Si tienes el repo en tu PC (por ejemplo en `C:\Users\German\Downloads\Checkin24hs`):

1. Asegúrate de que existe el archivo `VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh` en esa carpeta.
2. Desde PowerShell o CMD (en la carpeta del proyecto):
   ```bash
   scp VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh root@srv1152402:~/checkin24hs/
   ```
3. En el servidor:
   ```bash
   cd ~/checkin24hs
   chmod +x VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
   ./VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
   ```

(En Windows también puedes usar WinSCP para arrastrar el archivo a `~/checkin24hs/`.)
