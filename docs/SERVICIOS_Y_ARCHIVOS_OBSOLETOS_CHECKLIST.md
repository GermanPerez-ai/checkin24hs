# Checklist: 502 Flor API y errores de Supabase (contenido obsoleto)

Si ves **502 Bad Gateway** al usar el chat Flor y **"invalid input syntax for type uuid"** en Supabase, es por:

1. **flor-api** no puede hablar con WhatsApp (variable `WHATSAPP_URL` incorrecta).
2. La **web** (www.checkin24hs.com) sigue sirviendo **archivos viejos** (flor-learning-system.js?v=3.0.0 y HTML antiguo), por eso el navegador usa código obsoleto.

---

## En el servidor (orden recomendado)

### 1. Arreglar 502 (flor-api → WhatsApp)

```bash
docker service update --env-add WHATSAPP_URL=http://checkin24hs_whatsapp:3001 checkin24hs_flor-api
```

Comprobar: abrir el chat en www y enviar un mensaje; no debería aparecer 502.

---

### 2. Arreglar error UUID en Supabase (mientras la web siga con JS viejo)

En **Supabase → SQL Editor** ejecutá:

```sql
-- Hace que id acepte cualquier string (el JS viejo manda "interaction_xxx")
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'flor_interactions' AND column_name = 'id'
    AND data_type = 'uuid'
  ) THEN
    ALTER TABLE public.flor_interactions ALTER COLUMN id TYPE TEXT USING id::text;
  END IF;
END $$;
```

(O el contenido del archivo `supabase-migrations/032_flor_interactions_id_text.sql`.)

Así el insert deja de dar 400 aunque el navegador siga cargando el JS antiguo.

---

### 3. Actualizar la web para que deje de servir archivos obsoletos

La web que responde por **www.checkin24hs.com** puede ser **checkin24hs_web** o **checkin24hs_appwebcheckin24hs**. Hay que **reconstruir** la imagen desde `checkin24hs-web` y **actualizar** ese servicio.

```bash
cd ~/checkin24hs && git pull
cd checkin24hs-web
docker build -t easypanel/checkin24hs/web:latest .
```

Luego actualizar **el servicio que tenga el router de www** (probá ambos si no estás seguro):

```bash
docker service update --image easypanel/checkin24hs/web:latest checkin24hs_web
docker service update --image easypanel/checkin24hs/web:latest checkin24hs_appwebcheckin24hs
```

**Importante:** Si la web usa variables de build (VITE_SUPABASE_URL, etc.), esa imagen debe generarse desde EasyPanel o pasando los ARG; en ese caso hacé solo **Redeploy** del servicio web desde EasyPanel (después de hacer push del código nuevo).

Después de actualizar la web:

- El HTML cargará `flor-learning-system.js?v=3.0.1` (nuevo).
- El nuevo JS usa `crypto.randomUUID()` para el id y no envía `response_length`; los errores de Supabase deberían desaparecer.

Probar en **ventana de incógnito** para evitar caché.

---

## Resumen

| Problema | Causa | Acción |
|----------|--------|--------|
| 502 al usar Flor API | flor-api no alcanza WhatsApp | `docker service update --env-add WHATSAPP_URL=http://checkin24hs_whatsapp:3001 checkin24hs_flor-api` |
| "invalid input syntax for type uuid" | Tabla con id UUID + JS viejo que manda "interaction_xxx" | Ejecutar 032 en Supabase (id → TEXT) |
| Sigue cargando .js?v=3.0.0 | La web sirve build antiguo | Rebuild + update de checkin24hs_web o checkin24hs_appwebcheckin24hs (o redeploy desde EasyPanel) |

Los “contenedores/archivos obsoletos” son: (1) la **imagen del servicio web** que no tiene el HTML/JS nuevo, y (2) **flor-api** con `WHATSAPP_URL` antigua. Con los pasos de arriba se corrigen ambos.
