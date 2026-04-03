# 🔧 Solución: Webmail VERDE pero Bad Gateway

## ✅ Estado Actual

- ✅ Servicio en **VERDE** (corriendo)
- ✅ Recursos configurados correctamente (512/1024 MB, 0.5/1 CPU)
- ✅ Puerto configurado en **80** (correcto)
- ❌ Pero sigue dando **Bad Gateway**

## 🎯 Soluciones (En Orden)

### Solución 1: Reiniciar el Servicio

A veces el servicio necesita reiniciarse para aplicar cambios:

1. En EasyPanel, ve a **webmail**
2. Haz clic en el botón de **restart** (flecha circular ↻)
3. Espera **10-15 segundos**
4. Intenta acceder a `https://webmail.checkin24hs.com`

---

### Solución 2: Verificar los Logs

1. En EasyPanel, ve a la sección **"Registros"** (abajo)
2. Haz clic en **"Actualizar registros"** (botón refresh)
3. Revisa los últimos mensajes buscando:
   - `502 Bad Gateway`
   - `Connection refused`
   - `upstream timed out`
   - `Service is not reachable`

**Si ves alguno de estos errores**, comparte los últimos 10-15 líneas de logs.

---

### Solución 3: Forzar Nueva Implementación

A veces necesitas forzar una nueva implementación:

1. Haz clic en el botón verde **"Implementar"**
2. Espera **1-2 minutos**
3. Observa los logs para ver el progreso
4. Verifica que el servicio siga en **VERDE**
5. Intenta acceder al webmail

---

### Solución 4: Verificar Variables de Entorno

1. Ve a **"Entorno"** (menú lateral)
2. Verifica que tengas estas variables:
   ```
   ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
   ROUNDCUBEMAIL_DEFAULT_PORT=993
   ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
   ROUNDCUBEMAIL_SMTP_PORT=587
   ```
3. Si faltan, agrégalas
4. **Guarda** los cambios
5. Haz clic en **"Implementar"**

---

### Solución 5: Verificar la Fuente (Docker Image)

1. Ve a **"Fuente"** (menú lateral)
2. Verifica que la imagen sea:
   ```
   roundcube/roundcubemail:1.6.11-apache
   ```
3. Si está correcta, no cambies nada
4. Si necesitas cambiarla, haz clic en **"Implementar"** después

---

## 🔍 Diagnóstico Detallado

### Verificar en los Logs:

1. Ve a **"Registros"**
2. Busca mensajes que indiquen:
   - ✅ `Apache/2.4` → Apache está corriendo
   - ✅ `ROUNDCUBEMAIL has been successfully copied` → Roundcube instalado
   - ❌ `502 Bad Gateway` → Problema de proxy
   - ❌ `Connection refused` → Puerto no accesible
   - ❌ `upstream timed out` → Timeout de conexión

---

## 🚀 Pasos Recomendados (En Orden)

1. **Reiniciar el servicio** (botón restart ↻)
2. **Esperar 15 segundos**
3. **Intentar acceder** al webmail
4. Si sigue sin funcionar:
   - **Ver logs** para identificar el error específico
   - **Forzar implementación** (botón "Implementar")
   - **Verificar variables de entorno**

---

## ⚠️ Posibles Causas

Si el servicio está VERDE pero sigue 502:

1. **Problema de red interna**: Nginx no puede conectar al contenedor
2. **Apache no responde**: El contenedor corre pero Apache no está escuchando
3. **Configuración de proxy**: Traefik/Nginx mal configurado
4. **Cache del navegador**: Intenta en modo incógnito o limpia la caché

---

## 🆘 Si Nada Funciona

1. **Copia los últimos 20-30 líneas de logs**
2. **Comparte**:
   - ¿Qué errores aparecen en los logs?
   - ¿Cuándo empezó el problema?
   - ¿Funcionaba antes y dejó de funcionar?

Con esa información podremos identificar el problema exacto.



