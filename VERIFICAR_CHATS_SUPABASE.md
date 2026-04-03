# 🔍 Verificar Chats en Supabase - Diagnóstico

## 📋 Problema Identificado

El servidor de WhatsApp está guardando mensajes pero los chats no aparecen en el dashboard. Posibles causas:

1. **El servidor crea chats en `whatsapp_conversations` pero no en `whatsapp_chats`**
2. **Los mensajes se guardan pero los chats no se actualizan correctamente**
3. **Problema con la estructura de las tablas en Supabase**

---

## 🔧 Verificación Paso a Paso

### Paso 1: Verificar Tablas en Supabase

**Ejecuta en Supabase SQL Editor:**

```sql
-- 1. Verificar si existen las tablas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND (table_name LIKE '%whatsapp%' OR table_name LIKE '%conversation%')
ORDER BY table_name;

-- 2. Ver estructura de whatsapp_chats
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'whatsapp_chats'
ORDER BY ordinal_position;

-- 3. Ver estructura de whatsapp_messages
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'whatsapp_messages'
ORDER BY ordinal_position;

-- 4. Contar chats y mensajes
SELECT 
    (SELECT COUNT(*) FROM whatsapp_chats) as total_chats,
    (SELECT COUNT(*) FROM whatsapp_messages) as total_mensajes;

-- 5. Ver últimos chats creados
SELECT id, phone, name, last_message, last_message_time, created_at, whatsapp_instance
FROM whatsapp_chats
ORDER BY created_at DESC
LIMIT 10;

-- 6. Ver últimos mensajes
SELECT id, chat_id, phone, message, is_from_me, created_at, whatsapp_instance
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 10;

-- 7. Verificar si hay chats sin mensajes
SELECT wc.id, wc.phone, wc.name, COUNT(wm.id) as mensajes_count
FROM whatsapp_chats wc
LEFT JOIN whatsapp_messages wm ON wm.chat_id = wc.id
GROUP BY wc.id, wc.phone, wc.name
ORDER BY mensajes_count ASC, wc.created_at DESC
LIMIT 10;

-- 8. Verificar si hay mensajes sin chat_id válido
SELECT wm.id, wm.phone, wm.chat_id, wm.message, wm.created_at,
       CASE WHEN wc.id IS NULL THEN 'SIN CHAT' ELSE 'OK' END as estado
FROM whatsapp_messages wm
LEFT JOIN whatsapp_chats wc ON wc.id = wm.chat_id
ORDER BY wm.created_at DESC
LIMIT 10;
```

---

### Paso 2: Verificar Logs del Servidor WhatsApp

**En el servidor, ejecuta:**

```bash
# Ver logs del contenedor de WhatsApp
docker logs checkin24hs_whatsapp --tail 50 | grep -E "(guardar|chat|conversation|Supabase|error)"
```

**Busca mensajes como:**
- `✅ Nueva conversación creada en whatsapp_conversations`
- `✅ Nuevo chat creado en whatsapp_chats`
- `✅ Mensaje guardado en whatsapp_messages`
- `✅ Chat actualizado en whatsapp_chats`
- `❌ Error` o `⚠️ Error`

---

### Paso 3: Verificar Configuración del Servidor

**Verifica que el servidor tenga configurado:**

```bash
# En el servidor, verificar variables de entorno
docker exec checkin24hs_whatsapp env | grep -E "(SUPABASE|SAVE_TO_SUPABASE)"
```

**Debe mostrar:**
- `SUPABASE_URL=...`
- `SUPABASE_ANON_KEY=...`
- `SAVE_TO_SUPABASE=true` (o similar)

---

## 🐛 Problemas Comunes y Soluciones

### Problema 1: Chats se crean en `whatsapp_conversations` pero no en `whatsapp_chats`

**Solución:** El servidor debe crear/actualizar en ambas tablas o solo en `whatsapp_chats`.

**Verificar:**
```sql
-- Ver si hay datos en whatsapp_conversations
SELECT COUNT(*) FROM whatsapp_conversations;
SELECT * FROM whatsapp_conversations LIMIT 5;
```

---

### Problema 2: Mensajes se guardan pero no se actualiza `whatsapp_chats`

**Solución:** Verificar que la función `guardarMensaje()` esté actualizando `whatsapp_chats` correctamente.

**Verificar en logs:**
```bash
docker logs checkin24hs_whatsapp --tail 100 | grep "Chat actualizado"
```

---

### Problema 3: Estructura de tablas incorrecta

**Solución:** Ejecutar la migración de Supabase para crear/actualizar las tablas.

**Ver archivo:** `supabase-migrations/001_whatsapp_tables.sql`

---

## 📊 Script de Diagnóstico Completo

He creado un script SQL completo en: `DIAGNOSTICO_CHATS_SUPABASE.sql`

Ejecútalo en Supabase SQL Editor para obtener un reporte completo.
