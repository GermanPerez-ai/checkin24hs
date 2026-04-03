# Solución 401 Webmail (Error conexión IMAP)

## Qué significa el 401

Al iniciar sesión en **webmail.checkin24hs.com** aparece **401 Unauthorized** o **"Error de conexión con el servidor IMAP"**. Suele deberse a:

1. **Certificado SSL autofirmado**: Roundcube intenta conectar a `mail.checkin24hs.com:993` pero el servidor IMAP (Dovecot) usa un certificado autofirmado (CN distinto). PHP rechaza la conexión y Roundcube muestra 401/error de conexión.
2. **Opciones SSL no cargadas**: Aunque exista `config.ssl.inc.php` en el contenedor, muchas imágenes Docker **no incluyen** ese archivo desde `config.inc.php`, así que `imap_conn_options` nunca se aplica.

## Solución rápida (en el servidor)

Ejecuta el script que añade las opciones SSL **directamente al final** de `config.inc.php`:

```bash
./APLICAR_FIX_401_WEBMAIL.sh
```

Si no tienes el script en el servidor, puedes hacerlo a mano:

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID bash -c 'cat >> /var/www/html/config/config.inc.php << "END"
// Fix 401: certificado autofirmado
$config["imap_conn_options"] = array("ssl" => array("verify_peer" => false, "verify_peer_name" => false, "allow_self_signed" => true));
$config["smtp_conn_options"]  = array("ssl" => array("verify_peer" => false, "verify_peer_name" => false, "allow_self_signed" => true));
END'
```

Luego prueba de nuevo el login en el webmail.

## Si sigue el 401

1. **Credenciales**: Confirma usuario y contraseña (ej. `reservas@checkin24hs.com`). Prueba desde otro cliente (Thunderbird, Outlook) con el mismo usuario para descartar cuenta bloqueada o contraseña incorrecta.
2. **Variables de entorno en EasyPanel**: Deben estar así, sin duplicados:
   - `ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com`
   - `ROUNDCUBEMAIL_DEFAULT_PORT=993`
   - `ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true`
   - Sin prefijo `ssl://` en el host.
3. **Probar puerto 143 (STARTTLS)**: En EasyPanel prueba:
   - `ROUNDCUBEMAIL_DEFAULT_HOST=tls://mail.checkin24hs.com`
   - `ROUNDCUBEMAIL_DEFAULT_PORT=143`
   - `ROUNDCUBEMAIL_DEFAULT_HOST_SSL=false`
   Guarda, Implementar, espera 30 s y prueba el login.
4. **Logs**: Revisa logs del contenedor al intentar login:
   ```bash
   docker logs $(docker ps -q -f name=webmail) -f
   ```
   Busca "SSL", "certificate verify failed", "Empty startup greeting".

## Hacer el fix permanente

Si al **recrear el servicio** (update, rebuild) se pierde el cambio en `config.inc.php`:

- **Opción A**: Volver a ejecutar `APLICAR_FIX_401_WEBMAIL.sh` después de cada recreación.
- **Opción B**: En EasyPanel, montar un volumen con un archivo de config que sí se cargue (por ejemplo `config.custom.php` con `imap_conn_options` y `smtp_conn_options`), si la imagen lo incluye desde `config.inc.php`.
- **Opción C (recomendada a largo plazo)**: Instalar un certificado SSL válido para `mail.checkin24hs.com` en el servidor de correo (Dovecot) y quitar las opciones de verificación desactivada en Roundcube.

## Resumen

| Causa frecuente | Acción |
|----------------|--------|
| Certificado autofirmado no aceptado | Ejecutar `APLICAR_FIX_401_WEBMAIL.sh` (añade `imap_conn_options` en `config.inc.php`) |
| Credenciales incorrectas | Verificar usuario/contraseña y estado de la cuenta en el servidor de correo |
| Puerto 993 problemático | Probar 143 con `tls://mail.checkin24hs.com` en las variables de entorno |
