# ✅ Checklist Final Antes de Implementar Webmail

## 📋 Verificación Completa

### ✅ 1. Puntos de Montaje (Ya Configurados Correctamente)

Tienes estos volúmenes configurados:
- ✅ `html` → `/var/www/html`
- ✅ `config` → `/var/roundcube/config`
- ✅ `db` → `/var/roundcube/db`

**Estado**: ✅ Correcto, no necesitas cambiar nada aquí.

### ⚠️ 2. Recursos (VERIFICAR)

Ve a **"Recursos"** en el menú lateral y verifica:

- [ ] **Reserva de memoria**: `512` MB (NO 0)
- [ ] **Límite de memoria**: `1024` MB (NO 0)
- [ ] **Reserva de CPU**: `0.5` (NO 0)
- [ ] **Límite de CPU**: `1.0` (NO 0)

**Si están en 0, cámbialos a los valores indicados y GUARDA.**

### ⚠️ 3. Dominios (VERIFICAR)

Ve a **"Dominios"** en el menú lateral y verifica:

- [ ] **Puerto**: `8080` (NO 80)
- [ ] **Protocolo**: `HTTP`
- [ ] **Host**: `webmail.checkin24hs.com`

**Si el puerto es 80, cámbialo a 8080 y GUARDA.**

### ✅ 4. Variables de Entorno (Ya Configuradas)

Tienes estas variables:
- ✅ `ROUNDCUBEMAIL_DEFAULT_HOST=72.61.58.240`
- ✅ `ROUNDCUBEMAIL_DEFAULT_PORT=143`
- ✅ `ROUNDCUBEMAIL_SMTP_SERVER=72.61.58.240`
- ✅ `ROUNDCUBEMAIL_SMTP_PORT=587`
- ✅ `ROUNDCUBEMAIL_PLUGINS=archive,zipdownload`
- ✅ `ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=5M`

**Estado**: ✅ Correcto, no necesitas cambiar nada.

### ✅ 5. Fuente (Imagen Docker)

- ✅ `roundcube/roundcubemail:1.6.11-apache`

**Estado**: ✅ Correcto.

## 🚀 Pasos Finales

1. ✅ **Verifica "Recursos"** → Configura memoria y CPU si están en 0
2. ✅ **Verifica "Dominios"** → Cambia puerto a 8080 si es 80
3. ✅ **Haz clic en "Implementar"** (botón verde grande)
4. ✅ **Espera 1-2 minutos**
5. ✅ **Observa los logs** en "Registros"

## 🔍 Qué Observar Después de Implementar

### Señales de Éxito ✅
- El punto rojo cambia a **verde**
- Los recursos muestran valores (CPU > 0%, Memoria > 0 B)
- Los logs muestran mensajes como "Server started" o "Ready"
- Puedes acceder a `webmail.checkin24hs.com`

### Señales de Problema ❌
- El contenedor se mata ("Killed")
- Los recursos siguen en 0
- Errores en los logs como:
  - "Out of memory"
  - "Port already in use"
  - "Cannot bind to port"

## 🆘 Si Sigue Fallando

1. **Ve a "Registros"** y haz clic en "Actualizar registros"
2. **Copia los últimos 50-100 líneas** de logs
3. **Busca específicamente**:
   - "Killed"
   - "Out of memory"
   - "Port"
   - "Error"

Con esa información podremos identificar el problema exacto.

