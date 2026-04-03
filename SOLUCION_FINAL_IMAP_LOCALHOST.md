# Solución Final: Error IMAP - Usar localhost

## 🔍 Problema Identificado

A pesar de que las variables de entorno están correctas en EasyPanel:
- ✅ `ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com`
- ✅ `ROUNDCUBEMAIL_DEFAULT_PORT=993`
- ✅ `ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true`

Los logs antiguos muestran intentos de conexión a `srv1152402.hstgr.cloud`, y el contenedor actual puede tener problemas de conectividad de red Docker para acceder a `mail.checkin24hs.com` desde dentro del contenedor.

## ✅ Solución: Usar localhost

Como el servidor de correo (Dovecot) está corriendo en el mismo servidor que el webmail, la solución más confiable es usar `localhost` en lugar del dominio externo.

### Pasos en EasyPanel:

1. **Ve a EasyPanel → Servicios → `webmail`**

2. **Ve a "Variables de Entorno"**

3. **Cambia estas variables:**

   ```
   ROUNDCUBEMAIL_DEFAULT_HOST=localhost
   ROUNDCUBEMAIL_SMTP_SERVER=localhost
   ```

   **Mantén las demás igual:**
   ```
   ROUNDCUBEMAIL_DEFAULT_PORT=993
   ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
   ROUNDCUBEMAIL_SMTP_PORT=587
   ```

4. **Haz clic en "Guardar"**

5. **Haz clic en "Implementar" (botón verde)** o ejecuta:
   ```bash
   docker service update --force checkin24hs_webmail
   ```

6. **Espera 30 segundos** y prueba iniciar sesión de nuevo

---

## 🔍 Verificación Post-Corrección

Después de aplicar los cambios, ejecuta:

```bash
chmod +x VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
./VERIFICAR_CONTENEDOR_ACTUAL_IMAP.sh
```

Este script verificará:
- ✅ Si las variables se aplicaron correctamente
- ✅ Si el contenedor puede conectarse a localhost:993
- ✅ Los logs del contenedor actual
- ✅ La configuración de Roundcube

---

## 📊 ¿Por qué localhost?

1. **Evita problemas de red Docker:** El contenedor puede tener restricciones para acceder a dominios externos
2. **Más rápido:** No hay resolución DNS ni routing externo
3. **Más confiable:** La conexión es directa al servidor local
4. **Mismo servidor:** Dovecot está en el mismo host, así que `localhost` es correcto

---

## 🚨 Si el Problema Persiste con localhost

Si después de cambiar a `localhost` el error continúa:

### 1. Verifica que Dovecot esté escuchando correctamente:

```bash
# Verificar que Dovecot escucha en todas las interfaces
netstat -tuln | grep 993
# Debe mostrar: 0.0.0.0:993 (no solo 127.0.0.1:993)

# Verificar configuración de Dovecot
grep -r "listen" /etc/dovecot/conf.d/ | grep -i "993\|imap"
```

### 2. Verifica los logs de Dovecot:

```bash
# Ver logs de Dovecot
journalctl -u dovecot -f

# O si está en archivo
tail -f /var/log/dovecot/dovecot.log
```

### 3. Prueba conexión directa desde el contenedor:

```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID openssl s_client -connect localhost:993 -quiet
```

### 4. Verifica credenciales:

Asegúrate de que:
- La cuenta `reservas@checkin24hs.com` existe en el servidor
- La contraseña es correcta
- La cuenta está activa en Dovecot

---

## 📝 Configuración Final Recomendada

En EasyPanel, estas son las variables recomendadas:

```env
ROUNDCUBEMAIL_DEFAULT_HOST=localhost
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
ROUNDCUBEMAIL_SMTP_SERVER=localhost
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_SMTP_USER=%u
ROUNDCUBEMAIL_SMTP_PASS=%p
```

---

## 🔄 Alternativa: Si Necesitas Usar el Dominio

Si por alguna razón necesitas usar `mail.checkin24hs.com` en lugar de `localhost`:

1. **Verifica conectividad desde el contenedor:**
   ```bash
   CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
   docker exec $CONTAINER_ID telnet mail.checkin24hs.com 993
   ```

2. **Si no puede conectarse, verifica la red Docker:**
   - Asegúrate de que el contenedor tenga acceso a la red del host
   - O usa `host.docker.internal` si está disponible
   - O configura la red Docker en modo `host`

3. **Verifica DNS desde el contenedor:**
   ```bash
   docker exec $CONTAINER_ID nslookup mail.checkin24hs.com
   ```

Pero en la mayoría de los casos, `localhost` es la solución más simple y confiable.
