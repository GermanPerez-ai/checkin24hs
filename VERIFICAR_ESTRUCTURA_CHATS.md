# 🔍 Verificar Estructura de Chats en Supabase

## 📋 Pasos de Diagnóstico

### Paso 1: Ejecutar Script de Diagnóstico

**En Supabase SQL Editor, ejecuta:**

```sql
-- Ver archivo: DIAGNOSTICO_CHATS_SUPABASE.sql
```

O ejecuta estos comandos uno por uno:

```sql
-- 1. Verificar tablas existentes
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND (table_name LIKE '%whatsapp%' OR table_name LIKE '%conversation%')
ORDER BY table_name;

-- 2. Contar chats y mensajes
SELECT 
    (SELECT COUNT(*) FROM whatsapp_chats) as total_chats,
    (SELECT COUNT(*) FROM whatsapp_messages) as total_mensajes;

-- 3. Ver últimos chats
SELECT id, phone, name, last_message, last_message_time, created_at
FROM whatsapp_chats
ORDER BY created_at DESC
LIMIT 10;

-- 4. Ver últimos mensajes
SELECT id, chat_id, phone, LEFT(message, 50) as mensaje, is_from_me, created_at
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 10;

-- 5. Verificar mensajes sin chat válido
SELECT wm.id, wm.phone, wm.chat_id, wm.created_at,
       CASE WHEN wc.id IS NULL THEN '❌ SIN CHAT' ELSE '✅ OK' END as estado
FROM whatsapp_messages wm
LEFT JOIN whatsapp_chats wc ON wc.id = wm.chat_id
WHERE wc.id IS NULL
ORDER BY wm.created_at DESC
LIMIT 10;
```

---

### Paso 2: Verificar Logs del Servidor

**En el servidor, ejecuta:**

```bash
# Ver logs recientes del servidor WhatsApp
docker logs checkin24hs_whatsapp --tail 100 | grep -E "(chat|conversation|guardar|Supabase)"
```

**Busca estos mensajes:**
- `✅ Nuevo chat creado en whatsapp_chats` - ✅ Correcto
- `✅ Chat existente encontrado en whatsapp_chats` - ✅ Correcto
- `✅ Mensaje guardado en whatsapp_messages` - ✅ Correcto
- `✅ Chat actualizado en whatsapp_chats` - ✅ Correcto
- `❌ Error` o `⚠️ Error` - ❌ Problema

---

### Paso 3: Probar Envío de Mensaje

1. **Envía un mensaje de prueba a Flor por WhatsApp**
2. **Espera 5-10 segundos**
3. **Ejecuta en Supabase:**

```sql
-- Ver si se creó el chat
SELECT * FROM whatsapp_chats 
WHERE phone = 'TU_NUMERO_DE_PRUEBA'
ORDER BY created_at DESC
LIMIT 1;

-- Ver si se guardó el mensaje
SELECT * FROM whatsapp_messages 
WHERE phone = 'TU_NUMERO_DE_PRUEBA'
ORDER BY created_at DESC
LIMIT 5;
```

---

## 🐛 Problemas Comunes

### Problema 1: Chats se crean pero no aparecen en dashboard

**Causa:** El dashboard busca en `whatsapp_chats` pero los chats se crean en `whatsapp_conversations`.

**Solución:** Ya corregido - ahora siempre se crea en `whatsapp_chats` primero.

---

### Problema 2: Mensajes se guardan pero chats no se actualizan

**Causa:** El `chat_id` del mensaje no coincide con ningún `id` en `whatsapp_chats`.

**Verificar:**
```sql
SELECT wm.chat_id, COUNT(*) as mensajes
FROM whatsapp_messages wm
LEFT JOIN whatsapp_chats wc ON wc.id = wm.chat_id
WHERE wc.id IS NULL
GROUP BY wm.chat_id;
```

---

### Problema 3: Tabla `whatsapp_chats` no existe

**Solución:** Ejecutar la migración:

```sql
-- Ver archivo: supabase-migrations/001_whatsapp_tables.sql
```

---

## ✅ Resultado Esperado

Después de corregir:

1. ✅ Los chats se crean en `whatsapp_chats`
2. ✅ Los mensajes se guardan con `chat_id` válido
3. ✅ El dashboard muestra los contactos y conversaciones
4. ✅ Los chats se actualizan automáticamente cuando llegan nuevos mensajes
