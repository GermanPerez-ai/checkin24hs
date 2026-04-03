# 📋 Instrucciones para Verificar y Actualizar Tablas en Supabase

## 🎯 Objetivo

Verificar que todas las tablas necesarias para el dashboard estén creadas en Supabase y actualizarlas con las columnas e índices que falten, **sin duplicar datos existentes**.

## 📊 Tablas que se Verifican

El sistema necesita estas tablas:

1. **hotels** - Hoteles del sistema
2. **reservations** - Reservas
3. **quotes** - Cotizaciones
4. **expenses** - Gastos
5. **system_users** - Usuarios del sistema
6. **dashboard_admins** - Administradores del dashboard
7. **agents** - Agentes de viajes
8. **users** - Usuarios (puede ser alias de system_users)
9. **system_config** - Configuración del sistema

## 🔍 Paso 1: Verificar Estado Actual (Solo Lectura)

**Antes de hacer cambios**, verifica qué tablas existen y cuáles faltan:

1. Abre **Supabase Dashboard**: https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Ve a **SQL Editor** (Editor SQL)
4. Abre el archivo: `VERIFICAR_ESTADO_TABLAS_SUPABASE.sql`
5. Copia todo el contenido
6. Pégalo en el editor SQL
7. Haz clic en **"Run"** (Ejecutar)

**Resultado esperado:**
- Verás una lista de todas las tablas con su estado (✅ Existe / ❌ No existe)
- Verás las columnas de cada tabla
- Verás los índices existentes
- Verás el conteo de registros en cada tabla

## 🔧 Paso 2: Actualizar Tablas (Si es Necesario)

**Solo si faltan tablas o columnas**, ejecuta el script de actualización:

1. En el mismo **SQL Editor** de Supabase
2. Abre el archivo: `VERIFICAR_Y_ACTUALIZAR_TABLAS_SUPABASE.sql`
3. Copia todo el contenido
4. Pégalo en el editor SQL
5. Haz clic en **"Run"** (Ejecutar)

**Este script:**
- ✅ Crea las tablas que faltan
- ✅ Agrega columnas que falten a las tablas existentes
- ✅ Crea índices que falten
- ✅ **NO elimina datos existentes**
- ✅ **NO duplica datos**

**Resultado esperado:**
- Verás mensajes como:
  - `📦 Creando tabla: hotels`
  - `✅ Tabla reservations ya existe`
  - `➕ Agregada columna: amenities`
  - `➕ Creado índice: idx_reservations_hotel`
- Al final verás un resumen con el estado de todas las tablas

## ⚠️ Importante

### ✅ Seguro de Ejecutar

- El script **NO elimina** datos existentes
- El script **NO duplica** datos
- Solo **crea** lo que falta
- Solo **agrega** columnas que no existen

### 🔒 Backup Recomendado

Aunque el script es seguro, siempre es recomendable hacer un backup antes de cambios importantes:

1. En Supabase Dashboard, ve a **Database** → **Backups**
2. Crea un backup manual si es posible
3. O exporta los datos importantes manualmente

## 📝 Estructura de Cada Tabla

### hotels
- `id`, `name`, `location`, `description`, `rating`, `price`, `status`
- `amenities` (JSONB), `images` (JSONB), `coordinates` (JSONB)
- `google_maps`, `created_at`, `updated_at`

### reservations
- `id`, `code`, `hotel_id`, `customer_name`, `customer_email`, `customer_phone`
- `check_in`, `check_out`, `adults`, `children`, `total_amount`, `status`, `notes`
- `created_at`, `updated_at`

### quotes
- `id`, `customer_name`, `customer_email`, `customer_phone`, `hotel_id`
- `check_in`, `check_out`, `adults`, `children`, `total`, `status`, `notes`
- `created_at`, `updated_at`

### expenses
- `id`, `date`, `type`, `category`, `subcategory`, `description`
- `amount`, `exchange_rate`, `usd_amount`
- `created_at`, `updated_at`

### system_users
- `id`, `name`, `email`, `phone`, `status`, `tipo_cuenta`
- `birth_day`, `birth_month`
- `created_at`, `updated_at`

### dashboard_admins
- `id`, `username`, `password_hash`, `name`, `email`, `role`, `status`
- `last_login`, `created_at`, `updated_at`

### agents
- `id`, `code`, `name`, `agency`, `status`, `active`, `commission_rate`, `notes`
- `created_at`, `updated_at`

### users
- Similar a `system_users` (puede ser la misma tabla o un alias)

### system_config
- `id`, `key`, `value`, `description`
- `created_at`, `updated_at`

## 🐛 Solución de Problemas

### Error: "relation already exists"
- **Significado**: La tabla ya existe (esto es normal)
- **Solución**: El script detecta esto automáticamente y continúa

### Error: "column already exists"
- **Significado**: La columna ya existe (esto es normal)
- **Solución**: El script verifica antes de agregar columnas

### Error: "duplicate key value"
- **Significado**: Intentaste insertar un registro duplicado
- **Solución**: Este script NO inserta datos, solo crea estructura. Si ves este error, revisa tus datos manualmente.

### Error de permisos
- **Significado**: No tienes permisos para crear tablas
- **Solución**: Asegúrate de estar usando la cuenta de administrador del proyecto

## ✅ Verificación Final

Después de ejecutar el script de actualización:

1. Ejecuta nuevamente `VERIFICAR_ESTADO_TABLAS_SUPABASE.sql`
2. Verifica que todas las tablas muestren **✅ Existe**
3. Verifica que las columnas necesarias estén presentes
4. Verifica que los índices se hayan creado

## 📞 Soporte

Si encuentras algún problema:
1. Revisa los mensajes de error en el SQL Editor
2. Verifica que tengas permisos de administrador
3. Revisa la consola del navegador (F12) cuando uses el dashboard

---

**Última actualización**: Diciembre 2025

