# Solucionar Error de Login en Webmail

## Problema Identificado

El webmail está funcionando correctamente, pero **no puede autenticarse con el servidor IMAP**:

```
IMAP Error: Login failed for reservas@checkin24hs.com against 72.61.58.240
AUTHENTICATE PLAIN: Authentication failed.
```

## Causas Posibles

1. **Credenciales incorrectas** - Usuario o contraseña incorrectos
2. **Servidor IMAP no configurado** - No hay servidor de correo corriendo
3. **Configuración incorrecta** - El webmail está apuntando a la IP incorrecta
4. **Puertos bloqueados** - Los puertos IMAP (993, 143) no están accesibles

## Soluciones

### Solución 1: Verificar Configuración del Servidor IMAP

El webmail está intentando conectarse a `72.61.58.240` (IP del servidor). Verifica:

1. **¿Tienes un servidor de correo configurado?**
   ```bash
   # Verificar servicios de correo
   docker ps | grep -iE "mail|postfix|dovecot"
   systemctl list-units --type=service | grep -iE "postfix|dovecot"
   ```

2. **Si NO tienes servidor de correo:**
   - Necesitas configurar uno (Postfix + Dovecot) O
   - Cambiar la configuración del webmail para usar un servidor de correo externo

### Solución 2: Verificar Variables de Entorno en EasyPanel

En EasyPanel → Servicio `webmail` → "Variables de Entorno", verifica:

```
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
```

**Si el servidor de correo está en otra IP o dominio**, cambia `ROUNDCUBEMAIL_DEFAULT_HOST` a la IP o dominio correcto.

### Solución 3: Verificar Credenciales

El error muestra que está intentando iniciar sesión con `reservas@checkin24hs.com`. Verifica:

1. **¿Existe esta cuenta de correo?**
2. **¿La contraseña es correcta?**
3. **¿El servidor de correo acepta esta cuenta?**

### Solución 4: Verificar Conectividad con el Servidor IMAP

```bash
# Verificar que los puertos IMAP estén abiertos
telnet 72.61.58.240 993
# O
nc -zv 72.61.58.240 993
```

### Solución 5: Configurar Servidor de Correo (Si no existe)

Si no tienes un servidor de correo configurado, necesitas:

1. **Instalar y configurar Postfix + Dovecot** O
2. **Usar un servicio de correo externo** (Gmail, Outlook, etc.) y configurar el webmail para usarlo

## Verificación

Después de aplicar las soluciones:

```bash
# Ver logs del webmail
docker service logs checkin24hs_webmail --tail 50 | grep -iE "login|imap|error"

# Intentar iniciar sesión desde el navegador
# http://webmail.checkin24hs.com
```

## Nota Importante

El **Gateway Timeout** probablemente ocurrió porque el servidor IMAP tardó mucho en responder (o no respondió). Una vez que configures correctamente el servidor de correo o las credenciales, el problema debería resolverse.

## Próximos Pasos

1. Verifica si tienes un servidor de correo configurado
2. Si no lo tienes, decide si quieres instalarlo o usar uno externo
3. Verifica las variables de entorno en EasyPanel
4. Prueba iniciar sesión con credenciales correctas






