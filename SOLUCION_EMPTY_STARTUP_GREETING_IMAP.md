# Solución: "Empty startup greeting" IMAP (Roundcube)

## Qué significa

Roundcube conecta a `mail.checkin24hs.com:993` pero **no recibe el saludo IMAP** del servidor. Suele deberse a:

1. **SSL/TLS**: certificado autofirmado o handshake incorrecto.
2. **`imap_conn_options` no cargado**: si `config.local.php` no se incluye, Roundcube sigue verificando el certificado y la conexión puede cerrarse antes del saludo.

## 1. Comprobar si Roundcube carga config.local.php

En el servidor:

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID cat /var/www/html/config/config.inc.php | tail -30
```

Busca líneas con `include`, `require` o `config.local`. Si no aparece `config.local.php`, la imagen no lo carga.

## 2. Probar IMAP por puerto 143 (STARTTLS)

A veces 993 (SSL implícito) falla y 143 (STARTTLS) funciona. En **EasyPanel** → webmail → **Variables de entorno**, prueba:

```
ROUNDCUBEMAIL_DEFAULT_HOST=tls://mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=143
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=false
```

Guarda, **Implementar**, espera 30 s y prueba el login de nuevo.

## 3. Forzar que se cargue la config SSL (sobrescribir config.docker.inc.php)

Si la imagen no carga `config.local.php`, hay que tocar la config que sí usa. La imagen Roundcube Docker suele generar **config.docker.inc.php** desde las variables de entorno. No conviene editarlo a mano porque se regenera al reiniciar.

Otra opción: **montar** un archivo nuestro que sí se cargue. Por ejemplo, si en `config.inc.php` hay algo como:

```php
if (file_exists(__DIR__ . '/config.custom.php')) {
    include __DIR__ . '/config.custom.php';
}
```

crear `config.custom.php` con `imap_conn_options` y montarlo en el contenedor (volumen en EasyPanel).

## 4. Añadir imap_conn_options al final de config.inc.php (prueba rápida)

Solo para comprobar si el problema es SSL, dentro del contenedor:

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID bash -c 'echo "
// Fix SSL self-signed
\$config[\"imap_conn_options\"] = array(
    \"ssl\" => array(
        \"verify_peer\" => false,
        \"verify_peer_name\" => false,
        \"allow_self_signed\" => true,
    ),
);
\$config[\"smtp_conn_options\"] = array(
    \"ssl\" => array(
        \"verify_peer\" => false,
        \"verify_peer_name\" => false,
        \"allow_self_signed\" => true,
    ),
);
" >> /var/www/html/config/config.inc.php'
```

Reinicia el servicio (`docker service update --force checkin24hs_webmail`), espera 30 s y prueba el login.  
**Nota:** Si `config.inc.php` se regenera al reiniciar, este cambio se pierde; entonces hace falta un volumen con un archivo de config propio.

## 5. Resumen

- "Empty startup greeting" = conexión a 993 establecida pero sin saludo IMAP, muchas veces por SSL.
- Asegurar que `imap_conn_options` (verify_peer false, allow_self_signed) se cargue (config.local.php, config.custom.php o al final de config.inc.php).
- Probar también puerto 143 con `tls://mail.checkin24hs.com` por si 993 es el problema.
