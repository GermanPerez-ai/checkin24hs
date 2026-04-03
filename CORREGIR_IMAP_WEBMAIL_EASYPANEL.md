# Corrección Rápida: Error IMAP Webmail

## 🔍 Problema Identificado

El script de verificación mostró estos problemas:

1. ❌ **`ROUNDCUBEMAIL_DEFAULT_HOST=ssl://srv1152402.hstgr.cloud`** - Formato incorrecto (no debe tener prefijo `ssl://`)
2. ❌ **`ROUNDCUBEMAIL_DEFAULT_HOST_SSL=ssl`** - Debe ser `true` o `false`, no `ssl`
3. ⚠️ **`ROUNDCUBEMAIL_SMTP_SERVER=localhost`** - Debería usar el dominio correcto

## ✅ Solución Rápida (EasyPanel)

### Opción 1: Usar el Script Automático

```bash
chmod +x CORREGIR_CONFIGURACION_IMAP_WEBMAIL.sh
./CORREGIR_CONFIGURACION_IMAP_WEBMAIL.sh
```

### Opción 2: Configuración Manual en EasyPanel

1. **Accede a EasyPanel:**
   - Ve a **Servicios** → Busca **`webmail`**
   - Haz clic en el servicio para editarlo

2. **Ve a "Variables de Entorno" o "Environment Variables"**

3. **Edita las siguientes variables:**

   | Variable | Valor Actual (Incorrecto) | Valor Correcto |
   |----------|---------------------------|----------------|
   | `ROUNDCUBEMAIL_DEFAULT_HOST` | `ssl://srv1152402.hstgr.cloud` | `mail.checkin24hs.com` |
   | `ROUNDCUBEMAIL_DEFAULT_HOST_SSL` | `ssl` | `true` |
   | `ROUNDCUBEMAIL_SMTP_SERVER` | `localhost` | `mail.checkin24hs.com` |
   | `ROUNDCUBEMAIL_DEFAULT_PORT` | `993` | `993` (ya está correcto) |

4. **Configuración completa recomendada:**

   ```env
   ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
   ROUNDCUBEMAIL_DEFAULT_PORT=993
   ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
   ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
   ROUNDCUBEMAIL_SMTP_PORT=587
   ROUNDCUBEMAIL_SMTP_USER=%u
   ROUNDCUBEMAIL_SMTP_PASS=%p
   ```

5. **Guarda los cambios**

6. **Reinicia el servicio:**
   ```bash
   docker service update --force checkin24hs_webmail
   ```

7. **Espera 30 segundos** y prueba iniciar sesión de nuevo

---

## 🔍 Verificación Post-Corrección

Después de aplicar los cambios, ejecuta el script de verificación nuevamente:

```bash
./VERIFICAR_ERROR_IMAP_WEBMAIL.sh
```

Deberías ver:
- ✅ `ROUNDCUBEMAIL_DEFAULT_HOST: mail.checkin24hs.com` (sin prefijo `ssl://`)
- ✅ `ROUNDCUBEMAIL_DEFAULT_HOST_SSL: true` (no `ssl`)
- ✅ `ROUNDCUBEMAIL_SMTP_SERVER: mail.checkin24hs.com` (no `localhost`)

---

## 📊 Análisis del Problema

### ¿Por qué fallaba?

1. **Formato incorrecto del host:**
   - `ssl://srv1152402.hstgr.cloud` es un formato incorrecto
   - Roundcube espera solo el hostname, y el SSL se configura con `ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true`
   - El prefijo `ssl://` puede causar que Roundcube intente conectarse de forma incorrecta

2. **Valor incorrecto de SSL:**
   - `ROUNDCUBEMAIL_DEFAULT_HOST_SSL=ssl` no es un valor válido
   - Debe ser `true` o `false` (boolean)
   - Esto puede causar que Roundcube no active SSL correctamente

3. **Dominio externo vs local:**
   - El webmail intentaba conectarse a `srv1152402.hstgr.cloud` que puede no resolver correctamente desde dentro del contenedor
   - `mail.checkin24hs.com` resuelve correctamente (según el diagnóstico) y apunta a `72.61.58.240`

### Estado del Servidor de Correo

✅ **Buenas noticias:**
- Dovecot está corriendo (servidor IMAP)
- Postfix está corriendo (servidor SMTP)
- Los puertos 993 (IMAP SSL) y 143 (IMAP) están escuchando
- La conectividad externa funciona (`mail.checkin24hs.com:993` es accesible)

El problema era solo de configuración del webmail, no del servidor de correo.

---

## 🚨 Si el Problema Persiste

Si después de aplicar estos cambios el error continúa:

1. **Verifica los logs del webmail:**
   ```bash
   docker service logs checkin24hs_webmail --tail 100 | grep -i imap
   ```

2. **Verifica que el servidor de correo acepte conexiones:**
   ```bash
   # Desde el servidor
   telnet localhost 993
   # O
   openssl s_client -connect localhost:993
   ```

3. **Verifica las credenciales:**
   - Asegúrate de que la cuenta `reservas@checkin24hs.com` exista en el servidor
   - Verifica que la contraseña sea correcta

4. **Prueba conectarte directamente desde el contenedor:**
   ```bash
   CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
   docker exec $CONTAINER_ID telnet mail.checkin24hs.com 993
   ```

---

## 📝 Notas Importantes

- El servidor de correo está funcionando correctamente (Dovecot y Postfix activos)
- Los puertos están abiertos y escuchando
- El problema era únicamente la configuración incorrecta del webmail
- Después de corregir, el webmail debería poder conectarse correctamente
