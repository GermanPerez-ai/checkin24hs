# Fix: número sin "9" (Argentina) y ventana/estado al enviar cotización

## Problemas

1. **Número sin 9 después de +54**: Se enviaba `542944210725` en lugar de `5492944210725`, por eso no llegaba al WhatsApp en Argentina.
2. **Ventana no se cierra / Estado sigue "Pendiente"**: El PATCH a Supabase fallaba con `PGRST204` porque la tabla `quotes` no tiene la columna `sent_at`.

---

## Cambios realizados

### 1. Backend WhatsApp (número Argentina)

**Archivo:** `whatsapp-server/whatsapp-server-baileys.js`

- `normalizarNumeroParaEnvio()` ahora también normaliza cuando el número tiene **12 dígitos** (54 + 10 dígitos sin 9): se inserta el 9 y queda 549 + 10 = 13 dígitos.
- Antes solo se normalizaba con 11 dígitos; `542944210725` tiene 12, por eso no se corregía.

**Qué tenés que hacer:** Redesplegar el servicio WhatsApp (EasyPanel o `docker service update --force checkin24hs_whatsapp` después de construir la imagen con el código nuevo).

### 2. Columna `sent_at` en Supabase

**Archivo:** `supabase-migrations/019_quotes_add_sent_at.sql`

- Migración que agrega la columna `sent_at` (timestamptz) a la tabla `quotes`.
- Con esto el dashboard puede actualizar "enviado" y la fecha de envío sin error, se cierra el modal y el estado pasa a "Enviado".

**Qué tenés que hacer:** Ejecutar la migración en tu proyecto de Supabase:

1. En el dashboard de Supabase: **SQL Editor**.
2. Pegar el contenido de `supabase-migrations/019_quotes_add_sent_at.sql`:

```sql
ALTER TABLE quotes
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ;

COMMENT ON COLUMN quotes.sent_at IS 'Fecha y hora en que se envió la cotización al cliente (p. ej. por WhatsApp).';
```

3. Ejecutar (Run).

### 3. Frontend (deploy)

En `deploy/dashboard.html` ya existe `normalizarTelefonoArgentina()` y `sendViaServerAPI` envía `numParaEnvio` (número ya normalizado). Si el dashboard que servís es el de `deploy/`, no hace falta cambiar nada más ahí para el 9.

---

## Orden recomendado

1. **Supabase:** Ejecutar la migración `019_quotes_add_sent_at.sql` (agregar columna `sent_at`).
2. **Servidor WhatsApp:** Subir el código actualizado del backend y redesplegar el servicio (o construir imagen y `docker service update`).
3. Probar de nuevo "Guardar y Enviar al Cliente": el número debería llegar con 9 y el modal cerrarse con estado "Enviado".
