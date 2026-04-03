# Solución: Error IMAP por certificado SSL autofirmado

## Problema detectado

El script de verificación mostró:

- **Conectividad:** El contenedor **sí** puede conectar a `mail.checkin24hs.com:993`.
- **SSL:** Al probar con `openssl s_client` aparece:
  - `verify error:num=18:self-signed certificate`
  - `CN=srv1152402.hstgr.cloud`

Es decir: Dovecot usa un **certificado autofirmado** con CN `srv1152402.hstgr.cloud`, pero Roundcube se conecta a `mail.checkin24hs.com`. PHP/Roundcube **rechaza** la conexión por verificación SSL (certificado autofirmado y nombre distinto).

Por eso ves "Error de conexión con el servidor IMAP" aunque el puerto 993 sea accesible.

---

## Opción 1: Desactivar verificación SSL en Roundcube (rápida)

Así Roundcube acepta el certificado autofirmado. Es una solución práctica para entornos controlados; en producción es mejor usar un certificado válido (Opción 2).

### Paso 1: Archivo de configuración en el servidor

**Opción rápida (copiar y pegar todo en el servidor):** crea el archivo dentro del contenedor y prueba el login:

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec "$CONTAINER_ID" bash -c 'cat > /var/www/html/config/config.ssl.inc.php << "ENDCONFIG"
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
ENDCONFIG'
echo "Listo. Prueba iniciar sesion en https://webmail.checkin24hs.com"
```

Si Roundcube no carga automáticamente `config.ssl.inc.php`, prueba con el nombre `config.local.php` (algunas imágenes lo incluyen):

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec "$CONTAINER_ID" bash -c 'cat > /var/www/html/config/config.local.php << "ENDCONFIG"
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
ENDCONFIG'
```

**Alternativa:** crear el archivo en el host (por ejemplo en `~/checkin24hs/`):

```bash
cd ~/checkin24hs

cat > roundcube-config-ssl-autofirmado.inc.php << 'EOF'
<?php
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
EOF
```

### Paso 2: Incluir este archivo en Roundcube

Roundcube carga `config.inc.php` y suele incluir archivos extra desde el directorio `config/`. Hay que hacer que este archivo se cargue dentro del contenedor.

**Opción A – Montar el archivo con EasyPanel (recomendado)**

1. En EasyPanel → Servicio **webmail** → pestaña **Volúmenes** (o **Storage** / **Mounts**).
2. Añade un volumen tipo **Bind mount**:
   - **Host:** ruta al archivo, por ejemplo: `/root/checkin24hs/roundcube-config-ssl-autofirmado.inc.php`
   - **Contenedor:** `/var/www/html/config/config.ssl.inc.php`
3. Guarda y redespliega/reinicia el servicio.

Si EasyPanel no permite montar un archivo suelto, monta la carpeta:

- **Host:** `/root/checkin24hs/` (carpeta donde está el `.inc.php`)
- **Contenedor:** `/var/www/html/config/extra`  
  y dentro del contenedor el archivo debe estar como `/var/www/html/config/extra/roundcube-config-ssl-autofirmado.inc.php`.  
  Luego en Roundcube habría que asegurarse de que ese archivo se incluye (por ejemplo desde `config.inc.php` o desde el script de entrada del contenedor; depende de la imagen).

**Opción B – Copiar dentro del contenedor (se pierde al recrear el contenedor)**

Solo para probar rápido:

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker cp roundcube-config-ssl-autofirmado.inc.php "$CONTAINER_ID:/var/www/html/config/config.ssl.inc.php"
```

Luego reinicia el servicio webmail desde EasyPanel. Si la imagen de Roundcube incluye automáticamente `config.ssl.inc.php` (o cualquier `*.inc.php` en `config/`), debería aplicarse. Si no, habría que usar montaje (Opción A) o una imagen personalizada.

### Paso 3: Comprobar que Roundcube carga el archivo

Entra al contenedor y revisa que el archivo existe y que PHP lo puede cargar:

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec "$CONTAINER_ID" ls -la /var/www/html/config/config.ssl.inc.php
docker exec "$CONTAINER_ID" php -r "
\$config = array();
include '/var/www/html/config/config.ssl.inc.php';
var_dump(isset(\$config['imap_conn_options']));
"
```

Si no hay errores y muestra `bool(true)`, la configuración está cargada.

### Paso 4: Reiniciar el servicio

En EasyPanel: **Implementar** / **Reiniciar** el servicio webmail, o:

```bash
docker service update --force checkin24hs_webmail
```

Espera unos 30 segundos y prueba de nuevo el inicio de sesión en el webmail.

---

## Opción 2: Certificado válido en Dovecot (recomendado a largo plazo)

Así no hace falta desactivar la verificación SSL en Roundcube.

1. Obtener certificado para `mail.checkin24hs.com` (por ejemplo Let's Encrypt):
   ```bash
   sudo certbot certonly --standalone -d mail.checkin24hs.com
   ```
2. Configurar Dovecot para usar ese certificado (rutas típicas):
   - Certificado: `/etc/letsencrypt/live/mail.checkin24hs.com/fullchain.pem`
   - Clave: `/etc/letsencrypt/live/mail.checkin24hs.com/privkey.pem`
3. Reiniciar Dovecot:
   ```bash
   sudo systemctl restart dovecot
   ```

Cuando el certificado tenga CN/SAN `mail.checkin24hs.com`, Roundcube podrá conectarse sin desactivar la verificación SSL.

---

## Resumen

- **Causa del error:** Certificado SSL de Dovecot autofirmado y con CN `srv1152402.hstgr.cloud`, mientras Roundcube se conecta a `mail.checkin24hs.com` y verifica el certificado.
- **Solución rápida:** Añadir en Roundcube `imap_conn_options` y `smtp_conn_options` con `verify_peer` y `verify_peer_name` en `false` y `allow_self_signed` en `true`, mediante un archivo de config montado o incluido en el contenedor (Opción 1).
- **Solución recomendada a futuro:** Poner en Dovecot un certificado válido para `mail.checkin24hs.com` (Opción 2).
