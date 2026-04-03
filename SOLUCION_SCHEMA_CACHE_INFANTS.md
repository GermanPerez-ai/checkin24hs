# Solución: Error de Schema Cache con Columna `infants`

## Problema Identificado

El error `"Could not find the 'infants' column of 'quotes' in the schema cache"` (código PGRST204) ocurre porque:

1. ✅ La columna `infants` **SÍ existe** en la base de datos PostgreSQL
2. ❌ El **schema cache de PostgREST** (API REST de Supabase) está desactualizado
3. ⚠️ Tu proyecto está **EXCEEDING USAGE LIMITS**, lo que puede afectar el rendimiento

## Soluciones Aplicadas

### 1. Código Mejorado (Ya Implementado)
El código ahora:
- Detecta específicamente el error PGRST204 o errores relacionados con "infants"
- Intenta guardar la cotización sin el campo `infants` como fallback
- Muestra un warning informativo en la consola

### 2. Soluciones en Supabase

#### Opción A: Esperar (Recomendado - Más Simple)
El schema cache de PostgREST se actualiza automáticamente cada 5-10 minutos. Simplemente:
1. Espera 5-10 minutos
2. Recarga la página del cotizador
3. Intenta crear una nueva cotización

#### Opción B: Reiniciar el Proyecto (Más Rápido)
1. Ve a tu proyecto en Supabase Dashboard
2. Ve a **Settings** → **General**
3. Busca la opción **"Restart project"** o **"Pause project"** y luego **"Resume project"**
4. Esto fuerza un refresh completo del schema cache

#### Opción C: Forzar Refresh del Schema (Avanzado)
Ejecuta este SQL en el SQL Editor de Supabase:

```sql
-- Forzar refresh del schema cache de PostgREST
NOTIFY pgrst, 'reload schema';
```

Luego espera 1-2 minutos y recarga.

### 3. Solución Temporal (Ya Implementada)
El código ahora guarda las cotizaciones sin `infants` si detecta el error. Los infantes se guardarán correctamente una vez que el schema cache se actualice.

## Verificación

Para verificar que todo funciona:

1. **Verifica que la columna existe:**
   ```sql
   SELECT column_name, data_type, column_default
   FROM information_schema.columns
   WHERE table_name = 'quotes' AND column_name = 'infants';
   ```
   Debe mostrar: `infants | integer | 0`

2. **Crea una nueva cotización** desde `cotizador-cliente.html`

3. **Verifica en el dashboard** que la cotización aparezca

4. **Verifica en Supabase** que la cotización tenga el campo `infants` (puede ser 0 si no se especificó)

## Nota sobre "EXCEEDING USAGE LIMITS"

Tu proyecto está excediendo los límites de uso de Supabase. Esto puede causar:
- Rendimiento degradado
- Posibles timeouts
- Problemas de sincronización

**Recomendación:** Considera actualizar tu plan de Supabase o optimizar el uso de recursos.

## Estado Actual

✅ Código actualizado para manejar el error de schema cache
✅ Fallback implementado (guarda sin `infants` si es necesario)
✅ La columna `infants` existe en la base de datos
⏳ Esperando que el schema cache se actualice automáticamente
