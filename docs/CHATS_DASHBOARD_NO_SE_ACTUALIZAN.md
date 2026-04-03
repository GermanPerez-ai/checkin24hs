# Chats en el dashboard no se actualizan

## Dashboard local: asegurate de cargar la versión nueva (sin caché)

Si trabajás con el dashboard en local (`node servir_dashboard_local.js` y http://localhost:3000):

1. **Forzá una recarga sin caché:** `Ctrl+Shift+R` (o Cmd+Shift+R en Mac). Así el navegador carga el `dashboard.html` actualizado (botón Actualizar que refresca también el panel de mensajes, y polling cada 15s).
2. Si sigue igual: F12 → pestaña **Application** → **Storage** → **Clear site data** para localhost, y volvé a abrir http://localhost:3000.
3. En la consola (F12 → Console), al hacer clic en **Actualizar** o al abrir un chat deberías ver algo como: `📥 Mensajes cargados para chat ... : N mensajes`. Si sale **0 mensajes** pero la lista izquierda muestra actividad, puede haber un tema de columnas (`chat_id` vs `conversation_id`) o de RLS en Supabase.

## Qué está pasando

El dashboard muestra la lista de chats desde Supabase (`whatsapp_chats`). Para que la lista se actualice **sola** cuando llegan mensajes nuevos, se usan dos mecanismos:

1. **Supabase Realtime** – el navegador se suscribe a cambios en `whatsapp_chats` y `whatsapp_messages`; cuando hay INSERT/UPDATE, el dashboard recarga la lista.
2. **Polling de respaldo** – si Realtime no está activo o falla, la lista se refresca **cada 15 segundos** mientras estés en la sección Chats.

## Si la lista no se actualiza en tiempo real

### 1. Comprobar el polling (15 s)

- Entrá a la sección **Chats** del dashboard.
- Esperá unos 15 segundos sin cambiar de sección (o hacé clic en **Actualizar**).
- La lista debería refrescarse sola. Si después de ~15 s ves chats nuevos, el problema es solo Realtime.

### 2. Habilitar Supabase Realtime (actualización al instante)

Para que la lista se actualice en cuanto llega un mensaje, las tablas tienen que estar en la **publicación de Realtime** de Supabase:

1. Entrá al **Supabase Dashboard** del proyecto.
2. **Database** → **Replication** (o **Publications**).
3. Abrí la publicación **supabase_realtime**.
4. Añadí las tablas:
   - `whatsapp_chats`
   - `whatsapp_messages`

O desde **SQL Editor** ejecutá:

```sql
-- Habilitar Realtime para chats y mensajes de WhatsApp
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_chats;
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_messages;
```

(Si alguna tabla ya está en la publicación, Supabase devolverá un error tipo "already member"; podés ignorarlo.)

### 3. Verificar que el servidor WhatsApp escribe en Supabase

Si la lista no cambia ni con el refresh cada 30 s:

- Revisá que el servicio **checkin24hs_whatsapp** esté corriendo y con **SUPABASE_URL** y **SUPABASE_ANON_KEY** (o equivalente) configurados.
- En los logs del servidor deberías ver líneas como:
  - `✅ Mensaje guardado en whatsapp_messages`
  - `✅ Chat actualizado en whatsapp_chats`

Si no aparecen, el backend no está guardando en Supabase y por eso el dashboard no tiene datos nuevos.

### 4. Consola del navegador (F12)

En la pestaña Chats, en la consola podés ver:

- `📱 X chats cargados desde Supabase` – la carga inicial y cada refresh (cada 30 s o por Realtime).
- `✅ Suscripciones en tiempo real activas para chats` – Realtime intentó suscribirse.
- Errores de Supabase o de red – ayudan a ver si falla la conexión o Realtime.

## Resumen

| Síntoma | Qué hacer |
|--------|-----------|
| No se actualiza nunca | Revisar que el servidor WhatsApp guarde en Supabase y que el dashboard tenga bien la URL/anon key de Supabase. |
| Se actualiza cada ~15 s pero no al instante | Habilitar Realtime para `whatsapp_chats` y `whatsapp_messages` (paso 2). |
| Ni siquiera a los 15 s | Ver logs del servidor y consola del navegador; revisar RLS/permisos de las tablas en Supabase. Si los logs muestran "✅ Chat actualizado en whatsapp_chats", los datos están en Supabase: asegurate de haber desplegado el dashboard con el polling y de no tener RLS que bloquee SELECT. |
