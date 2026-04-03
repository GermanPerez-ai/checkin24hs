# Solución: Error de Conexión con el Servidor IMAP

## 🔍 Problema

El webmail muestra el error: **"Error de conexión con el servidor IMAP"** al intentar iniciar sesión.

## 📋 Diagnóstico

Primero, ejecuta el script de verificación para identificar el problema:

### En Linux/Mac:
```bash
chmod +x VERIFICAR_ERROR_IMAP_WEBMAIL.sh
./VERIFICAR_ERROR_IMAP_WEBMAIL.sh
```

### En Windows (PowerShell):
```powershell
.\verificar-error-imap-webmail.ps1
```

## 🔧 Soluciones Comunes

### Solución 1: Configuración Incorrecta de Variables de Entorno

**Problema:** El webmail está configurado para usar una IP directa o falta el puerto IMAP.

**Solución:**

1. **Accede a EasyPanel:**
   - Ve a **Servicios** → Busca el servicio **`webmail`**
   - Haz clic en el servicio para editarlo

2. **Ve a "Variables de Entorno" o "Environment Variables"**

3. **Verifica y configura las siguientes variables:**

   ```env
   ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
   ROUNDCUBEMAIL_DEFAULT_PORT=993
   ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
   ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
   ROUNDCUBEMAIL_SMTP_PORT=587
   ROUNDCUBEMAIL_SMTP_USER=%u
   ROUNDCUBEMAIL_SMTP_PASS=%p
   ```

   **Nota:** Si tu servidor de correo no soporta SSL, usa:
   ```env
   ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
   ROUNDCUBEMAIL_DEFAULT_PORT=143
   ROUNDCUBEMAIL_DEFAULT_HOST_SSL=false
   ```

4. **Guarda los cambios**

5. **Reinicia el servicio:**
   ```bash
   docker service update --force checkin24hs_webmail
   ```

6. **Espera 30 segundos** y prueba iniciar sesión de nuevo

---

### Solución 2: No Hay Servidor de Correo Configurado

**Problema:** No existe un servidor de correo (IMAP) corriendo en el servidor.

**Verificación:**

```bash
# Verificar servicios de correo en Docker
docker ps | grep -iE "mail|postfix|dovecot"

# Verificar servicios del sistema
systemctl list-units --type=service | grep -iE "postfix|dovecot"

# Verificar puertos IMAP
nc -zv mail.checkin24hs.com 993  # IMAP SSL
nc -zv mail.checkin24hs.com 143  # IMAP sin SSL
```

**Opciones:**

#### Opción A: Instalar un Servidor de Correo

Si necesitas un servidor de correo propio, puedes instalar **Postfix + Dovecot**:

1. Instalar Postfix y Dovecot
2. Configurar los dominios y cuentas de correo
3. Configurar los certificados SSL para IMAP
4. Asegurar que los puertos 993 (IMAP SSL) y 587 (SMTP) estén abiertos

#### Opción B: Usar un Servidor de Correo Externo

Si ya tienes un servicio de correo externo (Gmail, Outlook, otro proveedor), configura el webmail para usarlo:

1. En EasyPanel → Servicio `webmail` → Variables de Entorno
2. Configura las variables con los datos de tu servidor externo:

   ```env
   ROUNDCUBEMAIL_DEFAULT_HOST=imap.gmail.com
   ROUNDCUBEMAIL_DEFAULT_PORT=993
   ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
   ROUNDCUBEMAIL_SMTP_SERVER=smtp.gmail.com
   ROUNDCUBEMAIL_SMTP_PORT=587
   ```

3. Reinicia el servicio

---

### Solución 3: Problemas de Conectividad

**Problema:** El servidor IMAP no es accesible desde el contenedor del webmail.

**Verificación:**

```bash
# Desde el servidor, verifica conectividad
telnet mail.checkin24hs.com 993
# O
nc -zv mail.checkin24hs.com 993
```

**Soluciones:**

1. **Verificar firewall:**
   - Asegúrate de que el puerto 993 (o 143) esté abierto
   - Verifica las reglas de firewall del servidor

2. **Verificar red Docker:**
   - Asegúrate de que el contenedor del webmail pueda acceder a la red donde está el servidor de correo
   - Verifica que ambos servicios estén en la misma red Docker si es necesario

3. **Verificar DNS:**
   ```bash
   # Verificar que el dominio resuelva correctamente
   dig mail.checkin24hs.com
   nslookup mail.checkin24hs.com
   ```

---

### Solución 4: Credenciales Incorrectas

**Problema:** Las credenciales de la cuenta de correo son incorrectas.

**Verificación:**

1. Verifica que la cuenta `reservas@checkin24hs.com` exista en el servidor de correo
2. Verifica que la contraseña sea correcta
3. Si es necesario, resetea la contraseña de la cuenta

**Nota:** El error "Error de conexión con el servidor IMAP" generalmente indica un problema de conectividad, no de autenticación. Si el problema es de credenciales, normalmente verías un error diferente como "Nombre o contraseña inválida".

---

## 📝 Checklist de Verificación

Usa este checklist para verificar que todo esté configurado correctamente:

- [ ] El servicio `webmail` está corriendo en EasyPanel
- [ ] Las variables de entorno están configuradas correctamente:
  - [ ] `ROUNDCUBEMAIL_DEFAULT_HOST` apunta al servidor correcto
  - [ ] `ROUNDCUBEMAIL_DEFAULT_PORT` está configurado (993 o 143)
  - [ ] `ROUNDCUBEMAIL_DEFAULT_HOST_SSL` está configurado según el puerto
- [ ] Existe un servidor de correo accesible
- [ ] Los puertos IMAP (993 o 143) están abiertos y accesibles
- [ ] El DNS resuelve correctamente (`mail.checkin24hs.com`)
- [ ] Las credenciales de la cuenta de correo son correctas
- [ ] El servicio webmail se reinició después de cambiar la configuración

---

## 🚀 Pasos Rápidos de Solución

Si quieres una solución rápida, sigue estos pasos:

1. **Ejecuta el script de verificación:**
   ```bash
   ./VERIFICAR_ERROR_IMAP_WEBMAIL.sh
   ```

2. **Revisa el diagnóstico** y sigue las recomendaciones

3. **Si el problema es de configuración:**
   - Ve a EasyPanel → Servicio `webmail` → Variables de Entorno
   - Asegúrate de tener estas variables:
     ```
     ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
     ROUNDCUBEMAIL_DEFAULT_PORT=993
     ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
     ```
   - Guarda y reinicia el servicio

4. **Si el problema es que no hay servidor de correo:**
   - Decide si instalarás uno propio o usarás uno externo
   - Configura las variables según tu elección

5. **Prueba iniciar sesión de nuevo** en `https://webmail.checkin24hs.com`

---

## 📞 Información Adicional

- **Servicio webmail:** `checkin24hs_webmail`
- **Dominio webmail:** `webmail.checkin24hs.com`
- **Servidor IMAP esperado:** `mail.checkin24hs.com`
- **Puertos comunes:** 993 (IMAP SSL), 143 (IMAP), 587 (SMTP)

Si después de seguir estos pasos el problema persiste, revisa los logs del servicio para obtener más información:

```bash
docker service logs checkin24hs_webmail --tail 100
```
