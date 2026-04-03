# Configurar Webmail Correctamente

## Problema

El webmail está intentando conectarse a `72.61.58.240` (IP directa) pero debería usar `mail.checkin24hs.com` (el registro DNS que tienes configurado).

## Solución: Configurar Variables de Entorno en EasyPanel

### Paso 1: Verificar Configuración Actual

En EasyPanel → Servicio `webmail` → "Variables de Entorno", verifica qué valores tienen:

- `ROUNDCUBEMAIL_DEFAULT_HOST`
- `ROUNDCUBEMAIL_SMTP_SERVER`

### Paso 2: Configurar Correctamente

Si los valores están en `72.61.58.240`, cámbialos a `mail.checkin24hs.com`:

**Variables de Entorno Recomendadas:**

```
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_SMTP_USER=%u
ROUNDCUBEMAIL_SMTP_PASS=%p
```

### Paso 3: Guardar y Reiniciar

1. Guarda los cambios en EasyPanel
2. Reinicia el servicio:
   ```bash
   docker service update --force checkin24hs_webmail
   ```
3. Espera 30 segundos
4. Intenta iniciar sesión de nuevo

## Verificar Servidor de Correo

Antes de configurar el webmail, verifica si tienes un servidor de correo:

```bash
# Ver servicios de correo
docker ps | grep -iE "mail|postfix|dovecot"
systemctl list-units --type=service | grep -iE "postfix|dovecot"

# Verificar puertos
nc -zv 72.61.58.240 993  # IMAP SSL
nc -zv 72.61.58.240 143  # IMAP
nc -zv 72.61.58.240 587  # SMTP
```

## Si NO Tienes Servidor de Correo

Si los puertos están libres, necesitas:

1. **Instalar un servidor de correo** (Postfix + Dovecot) O
2. **Usar un servicio de correo externo** y configurar el webmail para usarlo

## Si SÍ Tienes Servidor de Correo

Solo necesitas configurar las variables de entorno en EasyPanel para usar `mail.checkin24hs.com` en lugar de la IP directa.


















