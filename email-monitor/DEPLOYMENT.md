# 🚀 Guía de Despliegue - Monitor de Correo

Guía paso a paso para desplegar el monitor de correo junto al servidor de WhatsApp Baileys existente.

## 📋 Opciones de Despliegue

### Opción 1: PM2 (Recomendado para VPS)

Si ya usas PM2 para el servidor de WhatsApp, esta es la forma más simple.

#### 1. Configurar el servicio

```bash
# Ir al directorio del monitor
cd /ruta/completa/checkin24hs/email-monitor

# Configurar variables de entorno
cp .env.example .env
nano .env
```

#### 2. Agregar al ecosystem de PM2

Edita `whatsapp-server-baileys/ecosystem.config.js` y agrega:

```javascript
{
  name: 'email-monitor',
  script: path.join(__dirname, '..', 'email-monitor', 'monitor.js'),
  cwd: path.join(__dirname, '..', 'email-monitor'),
  env: {
    NODE_ENV: 'production'
  },
  cron_restart: '*/15 * * * *',  // Cada 15 minutos
  autorestart: false,  // No reiniciar automáticamente (cron lo hace)
  error_file: path.join(__dirname, 'logs', 'email-monitor-error.log'),
  out_file: path.join(__dirname, 'logs', 'email-monitor-out.log'),
  log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
  merge_logs: true
}
```

#### 3. Iniciar el servicio

```bash
cd /ruta/completa/checkin24hs/whatsapp-server-baileys
pm2 reload ecosystem.config.js
pm2 save
```

#### 4. Verificar

```bash
pm2 status
pm2 logs email-monitor
```

### Opción 2: Cron (Alternativa simple)

Si no usas PM2, usa cron:

```bash
crontab -e
```

Agrega:

```bash
*/15 * * * * cd /ruta/completa/checkin24hs/email-monitor && /usr/bin/node monitor.js >> /var/log/email-monitor.log 2>&1
```

### Opción 3: Docker/Easypanel (Con el servidor WhatsApp)

Si despliegas todo con Docker:

#### 1. Modificar el Dockerfile

Agrega al Dockerfile existente del servidor de WhatsApp:

```dockerfile
# Agregar monitor de email
WORKDIR /app
COPY email-monitor ./email-monitor
WORKDIR /app/email-monitor
RUN npm install --production

# Volver al directorio principal
WORKDIR /app
```

#### 2. Crear script de inicio combinado

Crea `start-all-services.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Iniciando servicios de Checkin24hs..."

# Función para manejar señales de terminación
cleanup() {
    echo "🛑 Deteniendo servicios..."
    kill $EMAIL_MONITOR_PID 2>/dev/null || true
    kill $WHATSAPP_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Iniciar monitor de email en background (loop cada 15 min)
(
    while true; do
        echo "📧 Ejecutando monitor de correo..."
        cd /app/email-monitor && node monitor.js
        if [ $? -ne 0 ]; then
            echo "⚠️  Monitor de correo falló, reintentando en 15 min..."
        fi
        sleep 900  # 15 minutos
    done
) &
EMAIL_MONITOR_PID=$!
echo "✅ Monitor de correo iniciado (PID: $EMAIL_MONITOR_PID)"

# Iniciar servidor de WhatsApp
cd /app/whatsapp-server
node whatsapp-server-baileys.js &
WHATSAPP_PID=$!
echo "✅ Servidor WhatsApp iniciado (PID: $WHATSAPP_PID)"

# Esperar a que algún proceso termine
wait $WHATSAPP_PID
```

#### 3. Actualizar CMD del Dockerfile

```dockerfile
COPY start-all-services.sh /app/
RUN chmod +x /app/start-all-services.sh
CMD ["/app/start-all-services.sh"]
```

#### 4. Variables de entorno en Easypanel

En la configuración del servicio, agrega:

```
# Existentes (WhatsApp)
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
GEMINI_API_KEY=...
WHATSAPP_API_KEY=...  # ⚠️ LA MISMA que el servidor WhatsApp (PR #2)

# Nuevas (Monitor de Email)
IMAP_HOST=imap.hostinger.com
IMAP_PORT=993
IMAP_USER=reservas@checkin24hs.com
IMAP_PASS=tu_password_hostinger
IMAP_SECURE=1
WHATSAPP_API_KEY=tu_api_key_whatsapp  # Misma que el servidor
WHATSAPP_GROUP_ID=120363123456789012@g.us
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key
```

**⚠️ Notas importantes**:
- Para `SUPABASE_SERVICE_ROLE_KEY`, usa la key de servicio (no la anon key)
- `WHATSAPP_API_KEY` debe ser **exactamente igual** en el servidor WhatsApp y el monitor (ver PR #2)

## 🔐 Configuración de Credenciales

### 1. Contraseña de Hostinger

Obtén la contraseña del correo `reservas@checkin24hs.com`:

1. Ingresa al panel de Hostinger: https://hpanel.hostinger.com
2. Ve a Emails → Cuentas de correo
3. Busca `reservas@checkin24hs.com`
4. Copia o resetea la contraseña

### 2. Service Role Key de Supabase

1. Ve al dashboard de Supabase: https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Ve a Settings → API
4. Copia la `service_role` key (NO la `anon` key)
5. ⚠️ Esta key tiene permisos totales, manéjala con cuidado

### 3. API Key del servidor de WhatsApp

**Importante**: Esta es la clave de seguridad agregada en el PR #2.

1. Debe ser la **misma** `WHATSAPP_API_KEY` que configuraste en el servidor de WhatsApp
2. Si aún no la generaste:
   ```bash
   openssl rand -base64 32
   ```
3. Configurala en **ambos** servicios:
   - Servidor WhatsApp: `WHATSAPP_API_KEY`
   - Monitor de email: `WHATSAPP_API_KEY`

**⚠️ Si no coincide**: Las notificaciones fallarán con error 403 Forbidden.

### 4. ID del Grupo de WhatsApp

Ver `README.md` sección "Obtener el ID del grupo de WhatsApp" o ejecutar:

```bash
node get-whatsapp-group-id.js
```

### 5. API Key de Gemini (Opcional)

1. Ve a: https://aistudio.google.com/app/apikey
2. Crea una API key nueva
3. Copia la key

## 📊 Monitoreo y Logs

### Ver logs en PM2

```bash
# Logs en tiempo real
pm2 logs email-monitor

# Últimas 100 líneas
pm2 logs email-monitor --lines 100

# Solo errores
pm2 logs email-monitor --err
```

### Ver logs en cron

```bash
tail -f /var/log/email-monitor.log
```

### Ver logs en Docker/Easypanel

```bash
# Logs del contenedor
docker logs -f nombre-del-contenedor

# O desde Easypanel UI
# Services → Tu servicio → Logs
```

### Verificar en Supabase

```sql
-- Ver últimos correos procesados
SELECT 
    notified_at,
    from_addr,
    subject,
    summary,
    status
FROM email_monitor_notifications
ORDER BY notified_at DESC
LIMIT 20;

-- Contar por estado
SELECT status, COUNT(*) 
FROM email_monitor_notifications 
GROUP BY status;

-- Ver errores recientes
SELECT 
    notified_at,
    from_addr,
    subject,
    error_detail
FROM email_monitor_notifications
WHERE status = 'error'
ORDER BY notified_at DESC
LIMIT 10;
```

## 🧪 Testing en Producción

Antes de activar el cron/loop, prueba manualmente:

```bash
# 1. Dry-run (no envía nada)
cd /ruta/completa/email-monitor
node monitor.js --dry-run

# 2. Ejecutar una vez (envía de verdad)
node monitor.js

# 3. Verificar que llegó al grupo de WhatsApp

# 4. Verificar en Supabase que se guardó
```

## 🔄 Actualización del Servicio

Cuando actualices el código:

```bash
# Con PM2
cd /ruta/completa/checkin24hs/email-monitor
git pull
npm install
pm2 restart email-monitor

# Con cron
# No hace falta reiniciar nada, el cron usará el código nuevo

# Con Docker
# Rebuild y redeploy del contenedor
```

## ⚡ Frecuencia de Ejecución

Por defecto, el servicio revisa el correo cada **15 minutos**. Para cambiar:

### En PM2 (ecosystem.config.js)

```javascript
cron_restart: '*/15 * * * *',  // Cada 15 min
// cron_restart: '*/30 * * * *',  // Cada 30 min
// cron_restart: '0 * * * *',  // Cada hora
```

### En cron

```bash
*/15 * * * * ...  # Cada 15 min
*/30 * * * * ...  # Cada 30 min
0 * * * * ...     # Cada hora
```

### En el script de inicio (Docker)

```bash
sleep 900   # 15 minutos (900 segundos)
# sleep 1800  # 30 minutos
# sleep 3600  # 1 hora
```

## 🛡️ Seguridad

### ¿Qué credenciales NO subir a git?

- `.env` (ignorado por .gitignore)
- Passwords de Hostinger
- Service role key de Supabase
- API keys de Gemini

### ¿Cómo manejar secretos en producción?

1. **VPS/PM2**: Variables en archivo `.env` local (fuera de git)
2. **Easypanel**: Variables de entorno en la UI
3. **Docker**: Variables de entorno o Docker secrets

## 🐛 Troubleshooting Común

### El servicio no encuentra el grupo

```bash
# Verificar que el grupo ID sea correcto
echo $WHATSAPP_GROUP_ID
# Debe tener formato: 120363123456789012@g.us

# Verificar que el servidor de WhatsApp esté conectado
# (requiere API key desde PR #2)
curl -H "x-api-key: TU_API_KEY" http://localhost:3001/api/status
```

### Error 401 Unauthorized / 403 Forbidden

El servidor de WhatsApp ahora requiere autenticación (PR #2):

```bash
# Verificar que la API key esté configurada
echo $WHATSAPP_API_KEY

# Verificar que coincida con la del servidor WhatsApp
# Comparar con la variable en el servicio whatsapp-server-baileys

# Test manual con curl
curl -H "x-api-key: TU_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"number":"120363XXX@g.us","text":"Test"}' \
     http://localhost:3001/api/send
```

**Solución**: Asegurate que `WHATSAPP_API_KEY` sea **exactamente igual** en ambos servicios.

### No detecta correos nuevos

```bash
# Aumentar días de búsqueda temporalmente
IMAP_SINCE_DAYS=30 node monitor.js --dry-run
```

### Error de IMAP "Too many connections"

Hostinger limita conexiones simultáneas. Opciones:

1. Aumentar el intervalo (cada 30 min en vez de 15)
2. No ejecutar múltiples instancias simultáneas
3. Verificar que no haya otros servicios conectados al mismo correo

### Resúmenes con IA no funcionan

Es opcional. Si falla:
1. Verifica la API key de Gemini
2. El servicio funciona igual con resúmenes simples
3. Revisa límites de uso de la API

## ✅ Checklist Post-Despliegue

- [ ] Servicio corriendo (PM2/cron/Docker)
- [ ] Logs funcionando sin errores
- [ ] Primera ejecución manual exitosa
- [ ] Notificación recibida en el grupo de WhatsApp
- [ ] Registro guardado en Supabase
- [ ] Cron/loop configurado para ejecución periódica
- [ ] Logs monitoreados por errores

## 📞 Contacto

Si algo falla, revisa:

1. Logs del servicio
2. Logs del servidor de WhatsApp
3. Tabla `email_monitor_notifications` en Supabase
4. Ejecutar con `--dry-run` para debug
