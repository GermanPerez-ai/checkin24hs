# ⚙️ Configuración Necesaria - German

Este documento lista **TODO lo que necesitás configurar** para que el monitor de correo funcione.

## 🔐 1. Credenciales que necesitás conseguir

### A. Contraseña del correo (Hostinger)

**¿Qué es?** La contraseña de `reservas@checkin24hs.com`

**¿Dónde la consigo?**
1. Entrá a https://hpanel.hostinger.com
2. Ingresá con tu usuario de Hostinger
3. Andá a: **Emails** → **Cuentas de correo**
4. Buscá `reservas@checkin24hs.com`
5. Podés copiar la contraseña actual o crear una nueva

**⚠️ Importante:** Esta contraseña NO debe estar en el código. Va solo en el archivo `.env` del servidor.

### B. Service Role Key de Supabase

**¿Qué es?** Una clave especial de Supabase con permisos totales (la usamos para guardar los correos procesados)

**¿Dónde la consigo?**
1. Entrá a https://supabase.com/dashboard
2. Seleccioná tu proyecto de Checkin24hs
3. Andá a: **Settings** → **API**
4. Copiá la clave que dice **`service_role`** (NO la `anon`)

**⚠️ Cuidado:** Esta key tiene acceso total a la base. No la compartas ni la subas a git.

### C. API Key del servidor de WhatsApp

**¿Qué es?** Una clave de seguridad para autenticarte con el servidor de WhatsApp (agregada en PR #2)

**¿Dónde la consigo?**
Es la **misma API key** que configuraste para el servidor de WhatsApp en el PR #2.

Si todavía no la generaste:
1. Generá una clave segura (32 caracteres):
   ```bash
   openssl rand -base64 32
   ```
2. Guardala en un lugar seguro (LastPass, 1Password, etc)
3. Configurala como `WHATSAPP_API_KEY` en el servidor de WhatsApp
4. Usá la **misma clave** aquí

**⚠️ Importante:** La API key debe ser exactamente la misma que tiene el servidor de WhatsApp. Si no coincide, las notificaciones fallarán con error 403 Forbidden.

### D. ID del grupo de WhatsApp

**¿Qué es?** El identificador único del grupo donde querés recibir las notificaciones

**¿Cómo lo consigo?** Hay 3 formas:

**Opción 1 - La más fácil (desde los logs):**
1. Desde tu celular que está conectado a WhatsApp Web, enviá cualquier mensaje al grupo donde querés las notificaciones
2. En el servidor, mirá los logs del servicio de WhatsApp:
   ```bash
   pm2 logs whatsapp-1 --lines 50
   ```
3. Buscá una línea que diga algo como: `Mensaje recibido de: 120363123456789012@g.us`
4. Ese ID (con formato `120363...@g.us`) es el que necesitás

**Opción 2 - Con el script helper:**
```bash
cd /ruta/al/proyecto/email-monitor
node get-whatsapp-group-id.js
```
El script te guía paso a paso.

**Opción 3 - Agregando código temporal:**
Ver `README.md` sección "Obtener el ID del grupo"

### E. API Key de Gemini (OPCIONAL)

**¿Qué es?** Una clave para usar la IA de Google que genera resúmenes mejores

**¿Es obligatoria?** NO. Sin esta clave, el sistema funciona igual pero con resúmenes simples.

**¿Dónde la consigo?**
1. Entrá a https://aistudio.google.com/app/apikey
2. Iniciá sesión con una cuenta de Google
3. Creá una API key nueva
4. Copiala

**💡 Consejo:** Probá el sistema primero sin esta key, después la agregás si querés mejores resúmenes.

## 📝 2. Configurar el archivo .env

Una vez que tenés todas las credenciales:

```bash
# En el servidor, andá a la carpeta del monitor
cd /ruta/completa/checkin24hs/email-monitor

# Copiá el archivo de ejemplo
cp .env.example .env

# Editalo con tus credenciales
nano .env
```

Completá estos valores:

```bash
# ===== HOSTINGER =====
IMAP_PASS=TU_PASSWORD_AQUÍ

# ===== SUPABASE =====
SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_ROLE_KEY_AQUÍ

# ===== WHATSAPP =====
WHATSAPP_API_KEY=LA_MISMA_QUE_EL_SERVIDOR_WHATSAPP
WHATSAPP_GROUP_ID=120363123456789012@g.us

# ===== IA (opcional) =====
GEMINI_API_KEY=TU_API_KEY_AQUÍ_SI_QUERÉS
```

**⚠️ Lo que NO necesitás cambiar:**
- `IMAP_HOST`: ya está configurado con Hostinger
- `IMAP_USER`: ya es `reservas@checkin24hs.com`
- `SUPABASE_URL`: ya está configurado
- `WHATSAPP_API_URL`: en producción usa `https://whatsapp.checkin24hs.com` (los servicios corren en Docker Swarm, localhost:3001 NO es accesible desde el host)

## 🗄️ 3. Ejecutar la migración de base de datos

El monitor necesita una tabla en Supabase para controlar duplicados:

1. Entrá a Supabase: https://supabase.com/dashboard
2. Seleccioná tu proyecto
3. Andá a **SQL Editor**
4. Abrí el archivo `supabase-migrations/088_email_monitor_notifications.sql`
5. Copiá todo el contenido
6. Pegalo en el SQL Editor
7. Clickeá **Run**

Esto crea la tabla `email_monitor_notifications`.

## 🧪 4. Probar que funciona

Antes de ponerlo en producción:

```bash
# Ir a la carpeta
cd /ruta/completa/checkin24hs/email-monitor

# Instalar dependencias (primera vez)
npm install

# Ejecutar tests
npm test

# Probar en modo dry-run (no envía mensajes, solo muestra qué haría)
node monitor.js --dry-run
```

Si ves que detecta correos y muestra qué enviaría, está funcionando bien.

Ahora probá de verdad (envía un mensaje al grupo):

```bash
node monitor.js
```

Verificá que:
- ✅ No tira errores
- ✅ Si hay correos de reservas, los detecta
- ✅ Llega la notificación al grupo de WhatsApp
- ✅ Se guarda en Supabase (revisá la tabla `email_monitor_notifications`)

## 🚀 5. Poner en producción

**Opción A: Con PM2 (recomendado si ya lo usás para WhatsApp)**

```bash
cd /ruta/completa/checkin24hs/whatsapp-server-baileys

# Editá el ecosystem.config.js
nano ecosystem.config.js
```

Agregá esta app al array de apps (hay un ejemplo en `email-monitor/ecosystem.config.example.js`):

```javascript
{
  name: 'email-monitor',
  script: path.join(__dirname, '..', 'email-monitor', 'monitor.js'),
  cwd: path.join(__dirname, '..', 'email-monitor'),
  cron_restart: '*/15 * * * *',  // Cada 15 minutos
  autorestart: false,
  error_file: path.join(__dirname, 'logs', 'email-monitor-error.log'),
  out_file: path.join(__dirname, 'logs', 'email-monitor-out.log'),
  merge_logs: true
}
```

Luego:

```bash
pm2 reload ecosystem.config.js
pm2 save
pm2 status  # Verificar que aparece email-monitor
```

**Opción B: Con cron (más simple)**

```bash
crontab -e
```

Agregá:

```bash
*/15 * * * * cd /ruta/completa/checkin24hs/email-monitor && /usr/bin/node monitor.js >> /var/log/email-monitor.log 2>&1
```

(Reemplazá `/ruta/completa` con la ruta real)

## 📊 6. Monitorear que funciona

Para ver los logs:

**Con PM2:**
```bash
pm2 logs email-monitor
```

**Con cron:**
```bash
tail -f /var/log/email-monitor.log
```

Para ver qué se procesó en Supabase:

```sql
SELECT 
    notified_at,
    from_addr,
    subject,
    summary,
    status
FROM email_monitor_notifications
ORDER BY notified_at DESC
LIMIT 20;
```

## ❓ Preguntas Frecuentes

### ¿Cada cuánto revisa el correo?

Cada 15 minutos por defecto. Podés cambiarlo en el cron/PM2.

### ¿Qué pasa si llega el mismo correo dos veces?

No pasa nada. El sistema lo detecta por `message_id` y solo notifica la primera vez.

### ¿Puedo cambiar el grupo de WhatsApp después?

Sí, solo cambiá `WHATSAPP_GROUP_ID` en el `.env` y reiniciá el servicio.

### ¿Funciona con múltiples grupos?

No, por ahora solo un grupo. Si necesitás múltiples grupos, tendrías que correr múltiples instancias con diferentes configuraciones.

### ¿Los resúmenes con IA cuestan plata?

Gemini tiene un plan gratuito generoso. Para este uso (pocos correos por día) no deberías tener problemas. Podés monitorearlo en https://aistudio.google.com

### ¿Qué pasa si el servidor de WhatsApp no está conectado?

El monitor intenta enviar y guarda el error en Supabase. Cuando el WhatsApp se reconecte, no reenvía automáticamente (evita duplicados). Los correos quedan registrados con status `error`.

### ¿Y si Hostinger bloquea las conexiones?

Hostinger tiene límites de conexiones IMAP simultáneas. Por eso el monitor:
1. Se conecta, revisa, y se desconecta (no mantiene conexión abierta)
2. Solo revisa cada 15 minutos (no todo el tiempo)
3. Si necesitás más frecuencia, hablá con Hostinger sobre los límites

## 🆘 Si algo falla

1. **Ver los logs**: `pm2 logs email-monitor` o `tail -f /var/log/email-monitor.log`
2. **Ejecutar en dry-run**: `node monitor.js --dry-run`
3. **Revisar tests**: `npm test`
4. **Ver documentación completa**: `README.md` y `DEPLOYMENT.md`

## ✅ Resumen: Lo mínimo que necesitás

1. ✅ Contraseña de Hostinger (para IMAP)
2. ✅ Service role key de Supabase
3. ✅ API key del servidor de WhatsApp (misma del PR #2)
4. ✅ ID del grupo de WhatsApp
5. ✅ Completar el `.env`
6. ✅ Ejecutar la migración SQL
7. ✅ Probar con `--dry-run`
8. ✅ Configurar PM2 o cron
9. ✅ Monitorear que funciona

**Tiempo estimado de configuración:** 15-30 minutos

**¿Necesitás ayuda?** Revisá la documentación completa en `README.md` o los logs del sistema.
