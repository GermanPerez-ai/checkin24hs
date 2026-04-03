# Configurar Variables de Entorno del Webmail Correctamente

## Configuración Actual (Incorrecta)

```
ROUNDCUBEMAIL_DEFAULT_HOST=72.61.58.240
ROUNDCUBEMAIL_SMTP_SERVER=72.61.58.240
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=false
ROUNDCUBEMAIL_SMTP_PORT=587
```

## Problemas Identificados

1. **Usa IP directa** en lugar del dominio `mail.checkin24hs.com`
2. **SSL deshabilitado** (`ROUNDCUBEMAIL_DEFAULT_HOST_SSL=false`) - debería ser `true` si usas puerto 993
3. **Falta el puerto IMAP** (`ROUNDCUBEMAIL_DEFAULT_PORT`)

## Configuración Correcta

En EasyPanel → Servicio `webmail` → "Variables de Entorno", cambia a:

### Opción 1: Con SSL (Recomendado)

```
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_SMTP_USER=%u
ROUNDCUBEMAIL_SMTP_PASS=%p
```

### Opción 2: Sin SSL (Si el servidor no soporta SSL)

```
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=143
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=false
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_SMTP_USER=%u
ROUNDCUBEMAIL_SMTP_PASS=%p
```

## Pasos para Configurar

1. **Ve a EasyPanel → Servicio `webmail`**
2. **Ve a "Variables de Entorno" o "Environment Variables"**
3. **Edita cada variable:**
   - `ROUNDCUBEMAIL_DEFAULT_HOST`: Cambia de `72.61.58.240` a `mail.checkin24hs.com`
   - `ROUNDCUBEMAIL_DEFAULT_PORT`: Agrega `993` (si usas SSL) o `143` (sin SSL)
   - `ROUNDCUBEMAIL_DEFAULT_HOST_SSL`: Cambia a `true` (si usas puerto 993)
   - `ROUNDCUBEMAIL_SMTP_SERVER`: Cambia de `72.61.58.240` a `mail.checkin24hs.com`
4. **Guarda los cambios**
5. **Reinicia el servicio:**
   ```bash
   docker service update --force checkin24hs_webmail
   ```

## Verificar Servidor de Correo

Antes de cambiar, verifica qué puertos soporta tu servidor:

```bash
# Verificar puertos IMAP
nc -zv 72.61.58.240 993  # IMAP SSL
nc -zv 72.61.58.240 143  # IMAP sin SSL

# Verificar puertos SMTP
nc -zv 72.61.58.240 587  # SMTP
nc -zv 72.61.58.240 465  # SMTP SSL
```

**Si el puerto 993 responde:** Usa la Opción 1 (con SSL)
**Si solo el puerto 143 responde:** Usa la Opción 2 (sin SSL)

## Después de Configurar

1. Espera 30 segundos
2. Intenta iniciar sesión en `http://webmail.checkin24hs.com`
3. Usa las credenciales correctas de tu cuenta de correo

## Nota sobre el Error de Login

El error "nombre o contraseña inválida" puede ser porque:
- Las credenciales son incorrectas
- El servidor de correo no tiene configurada la cuenta `reservas@checkin24hs.com`
- El servidor de correo no está funcionando correctamente

Después de cambiar las variables, el webmail debería poder conectarse correctamente al servidor de correo.


















