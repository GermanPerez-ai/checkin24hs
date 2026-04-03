# Ejecutar Migración: Agregar Columna CODE a Tabla QUOTES

## 📋 Pasos para Ejecutar la Migración en Supabase

### 1. Acceder a Supabase SQL Editor

1. Inicia sesión en tu proyecto de Supabase: https://app.supabase.com
2. Selecciona tu proyecto
3. En el menú lateral izquierdo, haz clic en **"SQL Editor"** (o "Editor SQL")

### 2. Ejecutar la Migración

1. Haz clic en **"New query"** (Nueva consulta)
2. Copia y pega el siguiente código SQL:

```sql
-- ============================================
-- MIGRACIÓN: Agregar columna CODE a tabla QUOTES
-- Ejecutar en Supabase SQL Editor
-- ============================================
-- Esta migración agrega la columna 'code' a la tabla quotes
-- para almacenar códigos únicos de 5 caracteres (2 números + 3 letras mayúsculas)

-- Agregar columna code si no existe
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS code VARCHAR(5);

-- Crear índice único para asegurar que los códigos sean únicos
CREATE UNIQUE INDEX IF NOT EXISTS idx_quotes_code ON quotes(code) WHERE code IS NOT NULL;

-- Crear índice para búsquedas rápidas por código
CREATE INDEX IF NOT EXISTS idx_quotes_code_search ON quotes(code);

-- Comentario de la columna
COMMENT ON COLUMN quotes.code IS 'Código único de 5 caracteres (2 números + 3 letras mayúsculas) para identificar cotizaciones';
```

3. Haz clic en **"Run"** (Ejecutar) o presiona `Ctrl+Enter` (Windows) / `Cmd+Enter` (Mac)
4. Deberías ver un mensaje de éxito: ✅ "Success. No rows returned"

### 3. Verificar que la Migración se Ejecutó Correctamente

Ejecuta esta consulta para verificar que la columna existe:

```sql
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'quotes' AND column_name = 'code';
```

Deberías ver:
- `column_name`: `code`
- `data_type`: `character varying`
- `character_maximum_length`: `5`

### 4. Verificar los Índices Creados

Ejecuta esta consulta para verificar los índices:

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'quotes' AND indexname LIKE '%code%';
```

Deberías ver 2 índices:
- `idx_quotes_code` (índice único)
- `idx_quotes_code_search` (índice de búsqueda)

## ✅ Confirmación

Una vez ejecutada la migración:
- ✅ La columna `code` estará disponible en la tabla `quotes`
- ✅ Los códigos nuevos se guardarán automáticamente cuando se creen cotizaciones
- ✅ El código aparecerá en la tabla del dashboard

## 🚨 Si Ocurre un Error

Si ves algún error al ejecutar la migración:

1. **Error: "relation 'quotes' does not exist"**
   - La tabla `quotes` no existe. Primero ejecuta `create-tables.sql` o `create-tables-safe.sql`

2. **Error: "column 'code' already exists"**
   - Ya existe la columna, la migración fue parcial. Ejecuta solo las partes faltantes (índices)

3. **Error de permisos**
   - Asegúrate de tener permisos de administrador en el proyecto de Supabase

## 📝 Nota Importante

- Las cotizaciones antiguas sin código seguirán funcionando
- Solo las cotizaciones nuevas tendrán código automáticamente
- Si quieres agregar códigos a cotizaciones existentes, deberás actualizarlas manualmente
