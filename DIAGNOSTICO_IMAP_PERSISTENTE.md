# Diagnóstico: Error IMAP Persistente

## 📋 Situación Actual

Las variables de entorno en EasyPanel están **correctamente configuradas**:

```
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
```

Sin embargo, el error de conexión IMAP persiste.

## 🔍 Posibles Causas

### 1. El Servicio No Se Ha Reiniciado

**Problema:** Los cambios en las variables de entorno no se aplicaron al contenedor.

**Solución:**
```bash
docker service update --force checkin24hs_webmail
```

Espera 30 segundos y verifica de nuevo.

---

### 2. Problema de Red Docker

**Problema:** El contenedor del webmail no puede acceder al servidor IMAP debido a la configuración de red.

**Verificación:**
```bash
# Verificar conectividad desde el contenedor
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID telnet mail.checkin24hs.com 993
```

**Solución:**
- Si el contenedor no puede conectarse, verifica que ambos servicios estén en la misma red Docker
- O usa `localhost` en lugar de `mail.checkin24hs.com` si el servidor de correo está en el mismo host

---

### 3. Configuración Interna del Contenedor

**Problema:** Roundcube puede tener una configuración interna que sobrescribe las variables de entorno.

**Verificación:**
```bash
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID cat /var/www/html/config/config.docker.inc.php
docker exec $CONTAINER_ID cat /var/www/html/config/config.inc.php | grep -i imap
```

**Solución:**
- Si el archivo de configuración tiene valores diferentes, puede ser necesario modificar el archivo directamente o usar un volumen montado

---

### 4. Problema con Certificados SSL

**Problema:** El servidor IMAP puede estar rechazando conexiones SSL por problemas de certificados.

**Verificación:**
```bash
# Probar conexión SSL directa
openssl s_client -connect mail.checkin24hs.com:993 -showcerts

# Desde el contenedor
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID openssl s_client -connect mail.checkin24hs.com:993 -quiet
```

**Solución:**
- Si hay errores de certificado, puedes deshabilitar la verificación SSL temporalmente (no recomendado para producción)
- O configurar certificados correctos en el servidor de correo

---

### 5. Firewall o Reglas de Red

**Problema:** El firewall puede estar bloqueando conexiones desde el contenedor hacia el servidor IMAP.

**Verificación:**
```bash
# Verificar reglas de firewall
iptables -L -n | grep 993
ufw status | grep 993

# Verificar si el contenedor puede salir
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID ping -c 2 mail.checkin24hs.com
```

---

### 6. El Servidor IMAP No Acepta Conexiones desde el Contenedor

**Problema:** Dovecot puede estar configurado para aceptar conexiones solo desde localhost o IPs específicas.

**Verificación:**
```bash
# Verificar configuración de Dovecot
cat /etc/dovecot/dovecot.conf | grep -i listen
cat /etc/dovecot/conf.d/10-master.conf | grep -i listen
```

**Solución:**
- Asegúrate de que Dovecot esté escuchando en `0.0.0.0:993` y no solo en `127.0.0.1:993`
- O configura el webmail para usar `localhost` si están en el mismo host

---

## 🚀 Pasos de Diagnóstico Recomendados

1. **Ejecuta el script de verificación del contenedor:**
   ```bash
   chmod +x VERIFICAR_CONFIGURACION_CONTENEDOR_IMAP.sh
   ./VERIFICAR_CONFIGURACION_CONTENEDOR_IMAP.sh
   ```

2. **Reinicia el servicio para asegurar que los cambios se aplicaron:**
   ```bash
   docker service update --force checkin24hs_webmail
   ```

3. **Verifica los logs en tiempo real:**
   ```bash
   docker service logs -f checkin24hs_webmail
   ```
   Luego intenta iniciar sesión desde el navegador y observa los errores.

4. **Prueba conectividad directa desde el contenedor:**
   ```bash
   CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
   docker exec $CONTAINER_ID bash -c "timeout 5 bash -c 'echo > /dev/tcp/mail.checkin24hs.com/993' && echo '✅ Conectividad OK' || echo '❌ Sin conectividad'"
   ```

5. **Si el contenedor no puede conectarse a mail.checkin24hs.com, prueba con localhost:**
   - Cambia temporalmente `ROUNDCUBEMAIL_DEFAULT_HOST` a `localhost` en EasyPanel
   - Reinicia el servicio
   - Prueba de nuevo

---

## 🔧 Solución Alternativa: Usar localhost

Si el servidor de correo está en el mismo servidor que el webmail, puedes usar `localhost`:

**En EasyPanel, cambia:**
```
ROUNDCUBEMAIL_DEFAULT_HOST=localhost
ROUNDCUBEMAIL_SMTP_SERVER=localhost
```

**Luego reinicia:**
```bash
docker service update --force checkin24hs_webmail
```

Esto evita problemas de red Docker y DNS.

---

## 📝 Información para Depuración

Si el problema persiste, recopila esta información:

```bash
# 1. Variables del servicio
docker service inspect checkin24hs_webmail --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s\n" .}}{{end}}' | grep ROUNDCUBE

# 2. Variables del contenedor
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID env | grep ROUNDCUBE

# 3. Configuración interna
docker exec $CONTAINER_ID cat /var/www/html/config/config.docker.inc.php

# 4. Logs de errores
docker service logs checkin24hs_webmail --tail 100 | grep -i imap

# 5. Conectividad
docker exec $CONTAINER_ID timeout 5 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" && echo "OK" || echo "FAIL"

# 6. Estado del servidor de correo
systemctl status dovecot
netstat -tuln | grep 993
```
