# 🔍 Verificar Interacciones en Dashboard e Integraciones

## 🐛 Problema

Los chats no aparecen en la sección "Integraciones" aunque se guardan. Necesitas verificar:
1. La sección Chat y si hace conexión con Supabase
2. Si hay tablas antiguas del CRM en Supabase

---

## ✅ Verificación Paso a Paso

### Paso 1: Verificar Logs del Servidor

**Ejecuta en el servidor:**

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# Ver logs de guardado de interacciones
docker logs $CONTAINER_ID --tail 200 | grep -iE "Interacción guardada|flor_interactions|guardarFlorInteraction"
```

**Busca:**
- `🌸 Interacción guardada en flor_interactions (ID: ...)`
- `❌ Error guardando en flor_interactions`

---

### Paso 2: Verificar en Supabase Directamente

**Accede a Supabase y ejecuta estas consultas SQL:**

```sql
-- 1. Verificar que la tabla existe
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'flor_interactions'
) as tabla_existe;

-- 2. Contar interacciones
SELECT COUNT(*) as total FROM flor_interactions;

-- 3. Ver últimas 10 interacciones
SELECT * FROM flor_interactions
ORDER BY created_at DESC
LIMIT 10;

-- 4. Verificar estructura de la tabla
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'flor_interactions'
ORDER BY ordinal_position;
```

---

### Paso 3: Verificar Tablas Antiguas del CRM

**Ejecuta en Supabase SQL Editor:**

```sql
-- Buscar tablas que puedan ser del CRM antiguo
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'interactions',
    'crm_interactions',
    'chat_interactions',
    'flor_chat_interactions'
  );
```

**Si encuentras tablas antiguas:**
- Pueden estar causando confusión
- La tabla correcta es `flor_interactions`
- Considera eliminar o renombrar las tablas antiguas

---

### Paso 4: Verificar desde el Dashboard

**En el navegador:**

1. **Abre el dashboard:** `http://72.61.58.240:3000`
2. **Abre la consola del navegador (F12)**
3. **Ve a la pestaña "Interacciones"**
4. **Busca en la consola:**
   - `🌸 X interacciones cargadas desde Supabase`
   - `❌ Error obteniendo interacciones`
   - `⚠️ Supabase no está inicializado`

5. **Ejecuta en la consola:**
   ```javascript
   // Verificar conexión con Supabase
   window.supabaseClient.isInitialized()
   
   // Intentar cargar interacciones
   window.supabaseClient.getFlorInteractions(10).then(console.log).catch(console.error)
   ```

---

### Paso 5: Verificar Sección Chat

**En el dashboard:**

1. **Ve a la sección "Chats"**
2. **Abre la consola del navegador (F12)**
3. **Busca en la consola:**
   - `✅ Chats cargados: X`
   - `❌ Error cargando chats`
   - `⚠️ Supabase no está inicializado`

4. **Ejecuta en la consola:**
   ```javascript
   // Verificar conexión
   window.supabaseClient.isInitialized()
   
   // Intentar cargar chats
   window.supabaseClient.getWhatsAppChats(10).then(console.log).catch(console.error)
   ```

---

## 🔧 Soluciones Comunes

### Problema 1: Tabla flor_interactions no existe

**Solución:** Crear la tabla en Supabase:

```sql
-- Ejecutar en Supabase SQL Editor
-- (Ver archivo supabase-migrations/001_whatsapp_tables.sql)
```

---

### Problema 2: Row Level Security (RLS) bloqueando acceso

**Solución:** Verificar políticas RLS:

```sql
-- Ver políticas actuales
SELECT * FROM pg_policies
WHERE tablename = 'flor_interactions';

-- Si no hay políticas, crear una que permita todo
CREATE POLICY "Permitir todo en flor_interactions" 
ON flor_interactions FOR ALL USING (true);
```

---

### Problema 3: Supabase no está inicializado en el dashboard

**Solución:** Verificar configuración de Supabase en `dashboard.html`:

1. Busca la inicialización de `window.supabaseClient`
2. Verifica que las credenciales de Supabase estén correctas
3. Verifica en la consola del navegador si hay errores de inicialización

---

### Problema 4: Tablas antiguas del CRM causando confusión

**Solución:** Si hay tablas antiguas:

1. **Verifica qué datos tienen:**
   ```sql
   SELECT COUNT(*) FROM interactions; -- Si existe
   SELECT COUNT(*) FROM crm_interactions; -- Si existe
   ```

2. **Si están vacías o son antiguas, puedes eliminarlas:**
   ```sql
   -- CUIDADO: Solo si estás seguro de que no se usan
   -- DROP TABLE IF EXISTS interactions;
   -- DROP TABLE IF EXISTS crm_interactions;
   ```

---

## 📝 Scripts de Diagnóstico

He creado scripts para diagnosticar automáticamente:

**En el servidor:**
```bash
chmod +x /tmp/DIAGNOSTICAR_INTERACCIONES_COMPLETO.sh
/tmp/DIAGNOSTICAR_INTERACCIONES_COMPLETO.sh
```

**En Supabase SQL Editor:**
- Ejecuta el contenido de `VERIFICAR_TABLAS_SUPABASE.sql`

---

## 🔍 Próximos Pasos

1. Ejecuta el script de diagnóstico en el servidor
2. Ejecuta las consultas SQL en Supabase
3. Verifica desde el dashboard (consola del navegador)
4. Comparte los resultados para identificar el problema específico
