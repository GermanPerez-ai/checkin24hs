# Migrar Promociones a Supabase

## Pasos para migrar promociones desde localStorage a Supabase

### 1. Ejecutar la migración SQL en Supabase

1. Ve a tu proyecto en Supabase
2. Abre el **SQL Editor**
3. Copia y pega el contenido del archivo `supabase-migrations/004_create_promotions_table.sql`
4. Ejecuta el script

### 2. Actualizar el código

Los archivos ya están actualizados:
- ✅ `supabase-client.js` - Agregadas funciones para manejar promociones
- ✅ `cotizador-cliente.html` - Busca promociones en Supabase como fallback

### 3. Migrar promociones existentes

Abre la consola del navegador en el dashboard y ejecuta:

```javascript
// Migrar todas las promociones desde localStorage a Supabase
if (window.supabaseClient && window.supabaseClient.isInitialized()) {
    window.supabaseClient.migratePromotionsFromLocalStorage()
        .then(result => {
            console.log('✅ Migración completada:', result);
        })
        .catch(error => {
            console.error('❌ Error en migración:', error);
        });
} else {
    console.error('❌ Supabase no está inicializado');
}
```

### 4. Actualizar el dashboard para guardar en Supabase

Después de la migración, el dashboard debería guardar nuevas promociones directamente en Supabase en lugar de solo localStorage.

### Notas importantes

- Las promociones se guardarán en Supabase con la estructura:
  - `hotel_id` (UUID) - Referencia al hotel
  - `name` - Nombre de la promoción
  - `type` - Tipo de promoción
  - `description` - Descripción
  - `discount` - Porcentaje de descuento
  - `start_date` - Fecha de inicio
  - `end_date` - Fecha de fin
  - `status` - Estado (active, inactive, expired)

- El cotizador buscará primero en localStorage, y si no encuentra, buscará en Supabase automáticamente.
