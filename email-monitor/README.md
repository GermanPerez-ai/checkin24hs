# 📧 Monitor de Correo con Notificación WhatsApp - Checkin24hs

Servicio de monitoreo automatizado del correo **reservas@checkin24hs.com** que detecta respuestas relacionadas con reservas y las notifica al equipo por WhatsApp.

## 🎯 Funcionalidad

1. **Monitoreo IMAP**: Revisa periódicamente la bandeja de entrada de reservas@checkin24hs.com (alojado en Hostinger)
2. **Filtrado inteligente**: Identifica solo respuestas/hilos relacionados con reservas (modificaciones, anulaciones, confirmaciones, vouchers, cupos, etc.)
3. **Extracción de información**: Obtiene remitente (hotel/proveedor), asunto y texto principal sin citas ni firmas
4. **Resumen ejecutivo**: Genera un resumen corto con IA (opcional) o resumen simple
5. **Notificación WhatsApp**: Envía al grupo del equipo usando la infraestructura Baileys existente
6. **Control de duplicados**: Registra cada correo procesado en Supabase para no notificar dos veces

## ⚙️ Requisitos Previos

- Node.js 18 o superior
- Servidor de WhatsApp con Baileys funcionando (carpeta `whatsapp-server-baileys/`)
- Acceso a Supabase (URL y service role key)
- Contraseña del correo reservas@checkin24hs.com

## 📦 Instalación

```bash
cd email-monitor
npm install
```

## 🔧 Configuración

### 1. Variables de entorno

Copia el archivo de ejemplo y configura las variables:

```bash
cp .env.example .env
nano .env
```

#### Variables esenciales:

```bash
# IMAP - Hostinger (correo reservas@checkin24hs.com)
IMAP_HOST=imap.hostinger.com
IMAP_PORT=993
IMAP_USER=reservas@checkin24hs.com
IMAP_PASS=TU_CONTRASEÑA_AQUÍ
IMAP_SECURE=1

# Supabase
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_ROLE_KEY_AQUÍ

# WhatsApp
WHATSAPP_API_URL=http://localhost:3001
WHATSAPP_GROUP_ID=TU_GROUP_ID_AQUÍ

# IA (opcional - mejora los resúmenes)
GEMINI_API_KEY=TU_API_KEY_AQUÍ
```

### 2. Base de datos (Supabase)

Ejecuta la migración en el SQL Editor de Supabase:

```bash
supabase-migrations/088_email_monitor_notifications.sql
```

Esto crea la tabla `email_monitor_notifications` para controlar duplicados.

### 3. Obtener el ID del grupo de WhatsApp

Hay dos formas de obtener el ID del grupo:

#### Opción A: Desde los logs del servidor Baileys

1. Agrega este código temporal al servidor de WhatsApp (`whatsapp-server-baileys.js`) después de conectarse:

```javascript
// Temporal: listar grupos
const groups = await sock.groupFetchAllParticipating();
console.log('📱 Grupos disponibles:');
Object.values(groups).forEach(group => {
    console.log(`   ${group.subject}: ${group.id}`);
});
```

2. Reinicia el servidor y busca en los logs el nombre de tu grupo. El ID tiene formato: `120363123456789012@g.us`

#### Opción B: Desde un mensaje del grupo

1. En el dashboard de WhatsApp, cuando llegue un mensaje del grupo, revisa los logs del servidor
2. El `remoteJid` del mensaje es el ID del grupo
3. Busca líneas como: `Mensaje de grupo: 120363123456789012@g.us`

#### Opción C: Usando un script helper

Crea un archivo temporal `get-group-id.js` en la carpeta del servidor WhatsApp:

```javascript
const { default: makeWASocket, useMultiFileAuthState } = require('@whiskeysockets/baileys');

async function getGroups() {
    const { state } = await useMultiFileAuthState('./auth_info_baileys_1');
    const sock = makeWASocket({ auth: state });
    
    sock.ev.on('connection.update', async (update) => {
        if (update.connection === 'open') {
            const groups = await sock.groupFetchAllParticipating();
            console.log('\n📱 Grupos de WhatsApp:\n');
            Object.values(groups).forEach(group => {
                console.log(`${group.subject}`);
                console.log(`   ID: ${group.id}\n`);
            });
            process.exit(0);
        }
    });
}

getGroups();
```

Ejecutar: `node get-group-id.js`

### 4. API Key de Gemini (Opcional)

Si quieres resúmenes con IA:

1. Ve a [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Crea una API key
3. Agrégala a tu `.env`: `GEMINI_API_KEY=tu_key_aquí`

**Sin API key**: el servicio funciona igual pero usa resúmenes simples.

## 🚀 Uso

### Modo prueba (dry-run)

Revisa qué correos detectaría sin enviar notificaciones:

```bash
npm run dry-run
```

o

```bash
node monitor.js --dry-run
```

### Modo producción

```bash
npm start
```

o

```bash
node monitor.js
```

### Ejecutar tests

```bash
npm test
```

Esto ejecuta:
- `test-filter.js`: Prueba el filtrado con correos de ejemplo
- `test-parser.js`: Prueba la extracción y limpieza de texto

## ⏰ Automatización con Cron

Para revisar el correo cada 15 minutos:

```bash
crontab -e
```

Agrega:

```bash
*/15 * * * * cd /ruta/completa/email-monitor && /usr/bin/node monitor.js >> /var/log/email-monitor.log 2>&1
```

**Importante**: Usa la ruta completa al directorio y a `node`.

### Con PM2 (Recomendado)

Si usas PM2 para el servidor de WhatsApp, puedes agregar el monitor:

```bash
pm2 start monitor.js --name email-monitor --cron "*/15 * * * *"
pm2 save
```

## 🐳 Despliegue con Docker/Easypanel

Si usas Easypanel (como el servidor WhatsApp):

### 1. Agregar al Dockerfile existente

Si tienes un Dockerfile para el backend, agrega:

```dockerfile
# Copiar monitor de email
COPY email-monitor /app/email-monitor
WORKDIR /app/email-monitor
RUN npm install

# Script de inicio que corre ambos servicios
COPY start-services.sh /app/
RUN chmod +x /app/start-services.sh
CMD ["/app/start-services.sh"]
```

### 2. Script de inicio (`start-services.sh`)

```bash
#!/bin/bash

# Iniciar monitor de email en background (cada 15 min)
(while true; do
    cd /app/email-monitor && node monitor.js
    sleep 900  # 15 minutos
done) &

# Iniciar servidor principal
cd /app
npm start
```

### 3. Variables de entorno en Easypanel

Agrega las variables de entorno en la configuración del servicio:

```
IMAP_PASS=tu_password
SUPABASE_SERVICE_ROLE_KEY=tu_key
WHATSAPP_GROUP_ID=120363123456789012@g.us
GEMINI_API_KEY=tu_key_opcional
```

## 🔍 Palabras Clave

El servicio detecta correos que contengan:

- reserva
- modificación / modificacion
- anulación / anulacion
- cancelación / cancelacion
- voucher
- cupo
- confirmación / confirmacion

Personaliza agregando más en `.env`:

```bash
FILTER_KEYWORDS=reserva,modificación,anulación,cancelación,voucher,cupo,confirmación,custom1,custom2
```

## 📊 Formato de Notificación

Las notificaciones en WhatsApp tienen este formato:

```
📧 Nueva respuesta sobre reserva

📨 De: Hotel Puyehue
📧 Email: reservas@puyehue.cl
📋 Asunto: Re: Consulta modificación reserva #VK5LDY

💬 Resumen:
Hotel Puyehue: Confirmó modificación de fechas

📝 Mensaje:
Estimados, confirmamos la modificación...
[texto del correo sin citas ni firmas]

⏰ 31/10/2026 10:45:23
```

## 🛠️ Troubleshooting

### Error: "IMAP_PASS no configurado"

Verifica que el archivo `.env` exista y tenga la contraseña configurada.

### Error: "WhatsApp no está conectado"

1. Verifica que el servidor de Baileys esté corriendo:
   ```bash
   pm2 status whatsapp-1
   ```
2. Verifica el puerto en `WHATSAPP_API_URL` (default: 3001)
3. Revisa los logs del servidor WhatsApp

### Error: "AUTHENTICATIONFAILED" (IMAP)

La contraseña de Hostinger es incorrecta. Verifica:
1. Usuario correcto: `reservas@checkin24hs.com` (sin dominio extra)
2. Contraseña correcta en `.env`
3. Que la cuenta no esté bloqueada

### No detecta correos

1. Ejecuta en modo dry-run para ver qué encuentra:
   ```bash
   node monitor.js --dry-run
   ```
2. Revisa que `IMAP_SINCE_DAYS` sea suficiente (default: 7 días)
3. Verifica las palabras clave en `FILTER_KEYWORDS`

### Los resúmenes con IA no funcionan

1. Verifica que `GEMINI_API_KEY` esté configurada
2. Revisa los logs por errores de API
3. El servicio funciona igual sin IA (resúmenes simples)

### Duplicados

El servicio registra cada correo por `message_id` en Supabase. Si un correo se notifica dos veces:

1. Verifica la conexión a Supabase
2. Revisa la tabla `email_monitor_notifications`
3. El campo `message_id` debe ser único

## 📝 Estructura de Archivos

```
email-monitor/
├── README.md                 # Este archivo
├── package.json              # Dependencias
├── .env.example              # Plantilla de configuración
├── .env                      # Tu configuración (no subir a git)
├── monitor.js                # Servicio principal
├── test-filter.js            # Tests de filtrado
└── test-parser.js            # Tests de parseo
```

## 🔒 Seguridad

**⚠️ IMPORTANTE**: 

- **NO subir** el archivo `.env` a git
- **NO compartir** públicamente las API keys
- Usar `SUPABASE_SERVICE_ROLE_KEY` solo en el servidor (no en frontend)
- El `.gitignore` ya incluye `.env`

## 📚 Logs y Auditoría

Todos los correos procesados se guardan en `email_monitor_notifications`:

```sql
SELECT 
    notified_at,
    from_addr,
    subject,
    summary,
    status
FROM email_monitor_notifications
ORDER BY notified_at DESC
LIMIT 50;
```

## 🔄 Actualización del Servicio

Para actualizar el código:

```bash
cd email-monitor
git pull
npm install
pm2 restart email-monitor  # Si usas PM2
```

## 🆘 Soporte

Para problemas:

1. Revisa los logs:
   ```bash
   pm2 logs email-monitor        # Si usas PM2
   tail -f /var/log/email-monitor.log  # Si usas cron
   ```

2. Ejecuta en modo dry-run para debug:
   ```bash
   node monitor.js --dry-run
   ```

3. Verifica la configuración:
   ```bash
   cat .env | grep -v "PASS\|KEY"  # Ver config sin passwords
   ```

## ✅ Checklist de Configuración

Antes de pasar a producción, verifica:

- [ ] Archivo `.env` creado con todas las variables
- [ ] Contraseña de Hostinger correcta
- [ ] Migración de Supabase ejecutada
- [ ] Servidor de WhatsApp funcionando
- [ ] ID del grupo de WhatsApp obtenido
- [ ] Tests pasando (`npm test`)
- [ ] Dry-run exitoso con correos reales
- [ ] Cron/PM2 configurado para ejecución periódica
- [ ] Logs funcionando correctamente

## 📖 Más Información

- Servidor WhatsApp Baileys: `../whatsapp-server-baileys/README.md`
- Migraciones Supabase: `../supabase-migrations/`
- Script de sync de reservas: `../scripts/email-reservations/`
