# 📊 Guía para Verificar Datos de WhatsApp en Supabase

## 🎯 Objetivo
Verificar que los mensajes y conversaciones se estén guardando correctamente en Supabase después del deploy.

## 📋 Pasos para Verificar

### 1. Abrir Supabase SQL Editor
1. Ve a tu proyecto en Supabase
2. Haz clic en **"SQL Editor"** en el menú lateral
3. Haz clic en **"New query"**

### 2. Ejecutar el Script de Verificación
1. Copia el contenido de `VERIFICAR_DATOS_WHATSAPP_SUPABASE.sql`
2. Pégalo en el editor SQL
3. Haz clic en **"Run"** (o presiona `Ctrl + Enter`)

### 3. Interpretar los Resultados

#### ✅ **Sección 1: Conversaciones Creadas**
- **Qué verificar**: Debe mostrar al menos 1 conversación
- **Qué significa**: Las conversaciones se están creando correctamente con `external_id`

#### ✅ **Sección 2: Mensajes Guardados**
- **Qué verificar**: 
  - `total_mensajes` > 0
  - `mensajes_recibidos` > 0 (mensajes que recibiste)
  - `mensajes_enviados` > 0 (respuestas de Flor IA)
- **Qué significa**: Los mensajes se están guardando correctamente

#### ✅ **Sección 3: Verificación de Integridad**
- **Qué verificar**: 
  - `mensajes_con_conversacion_inexistente` debe ser **0**
  - Si hay mensajes sin conversación, hay un problema con las foreign keys
- **Qué significa**: Todos los mensajes están correctamente relacionados con sus conversaciones

#### ✅ **Sección 4: Estadísticas por Conversación**
- **Qué verificar**: 
  - Debe mostrar tu número de teléfono
  - `total_mensajes` debe ser > 0
  - Debe haber tanto `recibidos` como `enviados`
- **Qué significa**: La conversación está activa y guardando ambos tipos de mensajes

#### ✅ **Sección 5: Verificar Columnas Requeridas**
- **Qué verificar**: Todos los contadores deben ser **0**
- **Qué significa**: No hay mensajes con campos requeridos nulos

#### ✅ **Sección 6: Últimos Mensajes con Contexto**
- **Qué verificar**: 
  - Debe mostrar tus mensajes recientes
  - Debe mostrar las respuestas de Flor IA
  - `direction` debe alternar entre `inbound` y `outbound`
- **Qué significa**: Los mensajes se están guardando con toda la información necesaria

## 🔍 Verificación Manual Rápida

Si prefieres verificar manualmente:

### Ver Conversaciones
```sql
SELECT * FROM whatsapp_conversations ORDER BY created_at DESC LIMIT 5;
```

### Ver Mensajes
```sql
SELECT * FROM whatsapp_messages ORDER BY created_at DESC LIMIT 10;
```

### Ver Mensajes de una Conversación Específica
```sql
SELECT 
    m.*,
    c.external_id as telefono
FROM whatsapp_messages m
JOIN whatsapp_conversations c ON m.conversation_id = c.id
WHERE c.external_id = 'TU_NUMERO_AQUI'
ORDER BY m.created_at DESC;
```

## ⚠️ Problemas Comunes

### ❌ No hay conversaciones
- **Causa**: El código no está creando conversaciones
- **Solución**: Verificar logs del servidor para ver errores

### ❌ No hay mensajes
- **Causa**: Los mensajes no se están guardando
- **Solución**: Verificar que `SUPABASE_URL` y `SUPABASE_ANON_KEY` estén configurados en EasyPanel

### ❌ Mensajes sin conversación
- **Causa**: Error en la función `obtenerOcrearChatId`
- **Solución**: Verificar logs del servidor para ver errores al crear conversaciones

### ❌ Campos nulos en mensajes
- **Causa**: El código no está proporcionando todos los campos requeridos
- **Solución**: Verificar la función `guardarMensaje` en el código

## 📊 Resultado Esperado

Después de ejecutar el script, deberías ver:

✅ **Al menos 1 conversación** creada  
✅ **Múltiples mensajes** guardados (recibidos y enviados)  
✅ **0 mensajes con conversación inexistente**  
✅ **0 campos nulos** en columnas requeridas  
✅ **Mensajes recientes** visibles con contexto completo  

## 🎉 Si Todo Está Correcto

¡Felicidades! El sistema está funcionando correctamente:
- ✅ WhatsApp conectado
- ✅ Mensajes guardándose en Supabase
- ✅ Flor IA respondiendo
- ✅ Conversaciones creadas correctamente
- ✅ Foreign keys funcionando

## 📝 Notas

- Los mensajes se guardan en tiempo real cuando llegan
- Las conversaciones se crean automáticamente al recibir el primer mensaje
- El `external_id` en `whatsapp_conversations` es el número de teléfono (formato: `280671952093251@lid`)
