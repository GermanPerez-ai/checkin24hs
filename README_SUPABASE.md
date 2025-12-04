# 🚀 Integración de Supabase - Checkin24hs

## ✅ Archivos Creados

1. **`supabase-config.js`** - Configuración con tus credenciales
2. **`supabase-client.js`** - Cliente con todas las funciones para interactuar con Supabase
3. **`migrate-to-supabase.js`** - Script para migrar datos de localStorage a Supabase
4. **`create-tables.sql`** - SQL para crear las tablas en Supabase
5. **`INSTRUCCIONES_SUPABASE.md`** - Guía paso a paso para configurar

## 📋 Pasos Rápidos para Activar

### 1. Crear cuenta en Supabase (5 minutos)

1. Ve a: https://supabase.com
2. Inicia sesión con GitHub
3. Crea un nuevo proyecto:
   - Nombre: `checkin24hs`
   - Región: South America (São Paulo) - Recomendado
   - Plan: **Free**
   - ⚠️ **GUARDA LA CONTRASEÑA** de la base de datos

### 2. Obtener credenciales (2 minutos)

1. En Supabase, ve a **Settings** → **API**
2. Copia:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. Configurar archivo (1 minuto)

Abre `supabase-config.js` y reemplaza:

```javascript
const SUPABASE_CONFIG = {
    url: 'TU_PROJECT_URL_AQUI',      // ← Pega tu URL
    anonKey: 'TU_ANON_KEY_AQUI'      // ← Pega tu anon key
};
```

### 4. Crear tablas (2 minutos)

1. En Supabase, ve a **SQL Editor**
2. Haz clic en **"New query"**
3. Copia y pega todo el contenido de `create-tables.sql`
4. Haz clic en **"Run"**

### 5. Verificar (1 minuto)

1. Abre `dashboard.html` en tu navegador
2. Abre la consola (F12)
3. Deberías ver: `✅ Cliente de Supabase inicializado correctamente`

## 🎉 ¡Listo!

Ahora todos los datos se guardarán automáticamente en la nube.

## 🔄 Migrar Datos Existentes

Si ya tienes datos en localStorage y quieres migrarlos:

1. Abre la consola del navegador (F12)
2. Ejecuta: `migrateToSupabase()`
3. Espera a que termine la migración

## 📊 Cómo Funciona

### Sistema Híbrido (Backup Automático)

El sistema funciona de forma híbrida:

1. **Intenta guardar en Supabase** (nube) primero
2. **Si falla, guarda en localStorage** como respaldo
3. **Sincroniza automáticamente** entre ambos

Esto garantiza que:
- ✅ Los datos siempre se guarden (aunque Supabase falle)
- ✅ Tengas un backup local en localStorage
- ✅ Los datos se sincronicen con la nube cuando esté disponible

## 🔍 Verificar que Funciona

1. Crea un hotel en el dashboard
2. Ve a Supabase → **Table Editor** → **hotels**
3. Deberías ver el hotel que acabas de crear

## 🛠️ Funciones Disponibles

Todas las funciones están en `window.supabaseClient`:

```javascript
// Hoteles
await window.supabaseClient.getHotels()
await window.supabaseClient.createHotel({ name: '...', ... })
await window.supabaseClient.updateHotel(id, { ... })
await window.supabaseClient.deleteHotel(id)

// Reservas
await window.supabaseClient.getReservations()
await window.supabaseClient.createReservation({ ... })

// Cotizaciones
await window.supabaseClient.getQuotes()
await window.supabaseClient.createQuote({ ... })

// Gastos
await window.supabaseClient.getExpenses()
await window.supabaseClient.createExpense({ ... })

// Y más...
```

## ❓ Preguntas Frecuentes

### ¿Qué pasa si Supabase está caído?
- Los datos se guardan en localStorage como respaldo
- Cuando Supabase vuelva, se sincronizarán automáticamente

### ¿Se pierden los datos si limpio el caché?
- **NO**, porque los datos están en la nube (Supabase)
- Solo se pierden si también borras la base de datos de Supabase

### ¿Puedo usar Supabase y localStorage al mismo tiempo?
- **SÍ**, es exactamente lo que hace el sistema
- Guarda en ambos para máxima seguridad

### ¿Cuánto cuesta Supabase?
- **Plan Free**: Gratis para siempre
- 500MB de base de datos
- 1GB de storage
- Suficiente para proyectos pequeños/medianos

## 🚨 Importante

- ⚠️ No compartas tus credenciales de Supabase públicamente
- ⚠️ No subas `supabase-config.js` a GitHub con credenciales reales
- ✅ Usa variables de entorno en producción
- ✅ Activa Row Level Security (RLS) cuando estés listo

## 📚 Documentación

- Guía completa: `GUIA_BASE_DATOS_NUBE.md`
- Instrucciones: `INSTRUCCIONES_SUPABASE.md`
- Supabase Docs: https://supabase.com/docs

