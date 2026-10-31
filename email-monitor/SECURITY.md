# 🔐 Consideraciones de Seguridad - Email Monitor

## ✅ Protecciones Implementadas

### 1. Control de Duplicados con Race Condition Prevention

El sistema registra cada correo en Supabase **ANTES** de enviarlo a WhatsApp:

```javascript
// Primero: registrar con status 'processing'
await markAsProcessed(info, summary, 'processing');

// Luego: enviar a WhatsApp
await sendWhatsAppNotification(info, summary);

// Finalmente: actualizar a 'notified'
await updateProcessedStatus(messageId, 'notified');
```

**Beneficio**: Si dos instancias se ejecutan simultáneamente, la segunda falla en el INSERT por unique constraint y no envía el mensaje duplicado.

### 2. Filtrado Estricto de Correos

El monitor solo procesa correos que cumplan **AMBAS** condiciones:

1. **Contiene palabras clave** relacionadas con reservas (reserva, modificación, anulación, voucher, etc.)
2. **Es una respuesta/hilo**: tiene header `In-Reply-To` o `References`

**Beneficio**: Evita falsos positivos de newsletters o emails masivos que mencionen "reserva".

### 3. Credenciales Seguras

Todas las credenciales sensibles están en variables de entorno:

```bash
IMAP_PASS=          # Contraseña del correo
SUPABASE_SERVICE_ROLE_KEY=  # Key con acceso total a Supabase
GEMINI_API_KEY=     # API key de Google (opcional)
WHATSAPP_GROUP_ID=  # ID del grupo (no sensible, pero privado)
```

- ✅ `.gitignore` incluye `.env`
- ✅ `.env.example` solo tiene placeholders
- ✅ Documentación advierte NO subir credenciales

### 4. Logs Limitados

Los logs **NO** incluyen:
- ❌ Contraseñas o API keys
- ❌ Contenido completo de correos (solo primeros 200 chars en dry-run)
- ❌ Datos sensibles de clientes

Los logs **SÍ** incluyen (necesario para debugging):
- ✅ Dirección de email del remitente
- ✅ Asunto del correo
- ✅ Resumen generado

### 5. Modo Read-Only en IMAP

El monitor **NUNCA**:
- ❌ Marca correos como leídos
- ❌ Mueve correos de carpeta
- ❌ Elimina correos
- ❌ Modifica headers

Solo descarga (`fetchOne`) y lee el contenido.

### 6. RLS (Row Level Security) en Supabase

La tabla `email_monitor_notifications` tiene:
- ✅ RLS habilitado
- ✅ Políticas para `anon` y `authenticated`
- ⚠️ El servicio usa `service_role` que bypassa RLS (necesario para el monitor)

**Nota**: Las políticas son útiles si en el futuro se quiere consultar la tabla desde el dashboard.

## ⚠️ Consideraciones Adicionales

### 1. Service Role Key

La `SUPABASE_SERVICE_ROLE_KEY` tiene acceso total a la base de datos:

- ✅ **Usar solo en el servidor** (nunca en frontend)
- ✅ **No compartir** ni subir a repositorios públicos
- ✅ **Rotar** si se compromete

### 2. API de Gemini

La API key se pasa en la URL del request a Google:

```javascript
https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}
```

Esto es el método estándar de la API de Gemini. La key viaja por HTTPS (cifrado).

### 3. Límites de Texto

Para evitar enviar datos sensibles extensos:

- Texto del correo: limitado a 1500 chars al procesarlo
- Texto para Gemini: limitado a 800 chars
- Texto en dry-run logs: limitado a 200 chars

### 4. No Hay Autenticación en el Endpoint WhatsApp

El servidor de WhatsApp (`/api/send`) **NO tiene autenticación** por diseño:

- ⚠️ Cualquiera con acceso a la red puede enviar mensajes
- ✅ El monitor corre en la misma red privada (localhost:3001)
- 💡 Si el WhatsApp server está expuesto públicamente, agregar autenticación

## 🔍 Auditoría de Seguridad

### Información Loggeada (visible en logs del servidor):

```
✅ Email del remitente (ej: reservas@hotel.com)
✅ Asunto del correo
✅ Resumen ejecutivo
⚠️ Primeros 200 chars del mensaje (solo en dry-run)
❌ Contraseñas, API keys, service role key
```

### Información en Supabase:

```sql
SELECT 
  message_id,        -- ID único del correo
  from_addr,         -- Email del remitente
  subject,           -- Asunto
  summary,           -- Resumen generado
  status,            -- processing/notified/error
  error_detail,      -- Mensaje de error si falla
  notified_at        -- Timestamp
FROM email_monitor_notifications;
```

**Datos NO almacenados**: contenido completo del correo, contraseñas, datos de clientes.

## 📋 Checklist de Seguridad

Antes de desplegar en producción:

- [ ] Archivo `.env` creado y protegido (permisos 600)
- [ ] Todas las credenciales configuradas
- [ ] `.env` **NO** está en git
- [ ] Service role key **NO** está en código ni en variables públicas
- [ ] Probado con `--dry-run` primero
- [ ] Logs revisados por información sensible
- [ ] Servidor WhatsApp en red privada (localhost) o con autenticación

## 🆘 En Caso de Compromiso

Si una credencial se filtra:

### IMAP_PASS comprometida:
1. Cambiar contraseña en Hostinger inmediatamente
2. Actualizar `.env` en el servidor
3. Reiniciar el servicio

### SUPABASE_SERVICE_ROLE_KEY comprometida:
1. Ir a Supabase Dashboard → Settings → API
2. Rotar la service role key
3. Actualizar `.env` en todos los servicios que la usan
4. Auditar logs de Supabase por accesos no autorizados

### GEMINI_API_KEY comprometida:
1. Revocar la key en Google AI Studio
2. Crear una nueva
3. Actualizar `.env`

---

**Última actualización**: 31 Oct 2026
