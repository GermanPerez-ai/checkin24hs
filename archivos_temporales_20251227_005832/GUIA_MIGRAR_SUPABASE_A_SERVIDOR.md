# Guía: Migrar de Supabase a Base de Datos Propia en Servidor

## ✅ Respuesta Corta

**Sí, puedes crear tu propia base de datos en el servidor con EasyPanel y migrar toda la información de Supabase.** Es totalmente factible, pero requiere algunos pasos.

## 🎯 Opciones de Base de Datos en EasyPanel

EasyPanel soporta varios tipos de bases de datos:

### 1. **PostgreSQL** (Recomendado) ⭐
- ✅ Compatible con Supabase (Supabase usa PostgreSQL)
- ✅ Migración más fácil
- ✅ Mismo lenguaje SQL
- ✅ Mejor rendimiento local

### 2. **MySQL/MariaDB**
- ✅ Fácil de usar
- ⚠️ Requiere cambios en el código (diferente sintaxis SQL)
- ⚠️ Algunas funciones de PostgreSQL no existen

### 3. **MongoDB**
- ⚠️ Requiere cambios grandes en el código (NoSQL)
- ⚠️ No recomendado si ya tienes datos estructurados

## 📋 Plan de Migración

### Fase 1: Crear Base de Datos en EasyPanel

1. **Ve a EasyPanel** → **New Service** → **Database**
2. **Elige PostgreSQL**
3. **Configuración:**
   ```
   Nombre: checkin24hs_db
   Usuario: checkin24hs_user
   Contraseña: [genera una segura]
   Puerto: 5432 (interno)
   ```
4. **Guarda y espera a que inicie**

### Fase 2: Exportar Datos de Supabase

#### Opción A: Exportar desde Supabase Dashboard
1. Ve a tu proyecto en Supabase
2. **Database** → **Backups**
3. Descarga el backup completo (SQL dump)

#### Opción B: Exportar tabla por tabla
```bash
# Instalar pg_dump si no lo tienes
# Luego exportar cada tabla:

# Exportar estructura y datos
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres -t whatsapp_messages > whatsapp_messages.sql
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres -t whatsapp_chats > whatsapp_chats.sql
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres -t users > users.sql
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres -t hotels > hotels.sql
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres -t flor_interactions > flor_interactions.sql
# ... etc para todas las tablas
```

#### Opción C: Usar script de migración
```javascript
// migrar-datos.js
// Conecta a Supabase, lee todos los datos, los inserta en tu nueva BD
```

### Fase 3: Importar Datos a tu Base de Datos

```bash
# Conectarte a tu nueva base de datos
psql -h localhost -U checkin24hs_user -d checkin24hs_db

# O desde el contenedor de PostgreSQL
docker exec -i <nombre_contenedor_postgres> psql -U checkin24hs_user -d checkin24hs_db < backup_completo.sql
```

### Fase 4: Actualizar Código

Necesitarás cambiar las URLs de conexión en varios archivos:

#### 1. `whatsapp-server/whatsapp-server.js`
```javascript
// ANTES (Supabase)
const supabase = createClient(
    'https://lmoeuyasuvoqhtvhkyia.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
);

// DESPUÉS (PostgreSQL directo)
const { Pool } = require('pg');
const pool = new Pool({
    host: process.env.DB_HOST || 'checkin24hs_db', // Nombre del servicio en Docker
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'checkin24hs_db',
    user: process.env.DB_USER || 'checkin24hs_user',
    password: process.env.DB_PASSWORD
});
```

#### 2. `supabase-client.js`
Cambiar todas las llamadas de Supabase a consultas SQL directas:
```javascript
// ANTES
const { data } = await supabase
    .from('users')
    .select('*');

// DESPUÉS
const { rows } = await pool.query('SELECT * FROM users');
```

#### 3. `dashboard.html` y `crm.html`
Cambiar las llamadas a Supabase por llamadas a tu API backend.

### Fase 5: Crear API Backend (Opcional pero Recomendado)

En lugar de que el frontend se conecte directamente a la BD, crea un API:

```javascript
// server-api.js
const express = require('express');
const { Pool } = require('pg');
const app = express();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD
});

// Endpoint para obtener usuarios
app.get('/api/users', async (req, res) => {
    const { rows } = await pool.query('SELECT * FROM users');
    res.json(rows);
});

// Endpoint para obtener mensajes de WhatsApp
app.get('/api/whatsapp/messages', async (req, res) => {
    const { rows } = await pool.query('SELECT * FROM whatsapp_messages ORDER BY created_at DESC');
    res.json(rows);
});

// ... más endpoints
```

## 🔄 Ventajas y Desventajas

### ✅ Ventajas de Base de Datos Propia

1. **Control Total**
   - Tú decides cuándo hacer backups
   - Sin límites de espacio (según tu servidor)
   - Sin límites de requests

2. **Costo**
   - Gratis (solo el servidor que ya tienes)
   - Sin costos adicionales de Supabase

3. **Rendimiento**
   - Más rápido (misma red local)
   - Sin latencia de red externa

4. **Privacidad**
   - Datos completamente en tu servidor
   - Sin terceros

### ⚠️ Desventajas

1. **Mantenimiento**
   - Tú debes hacer backups manualmente
   - Tú debes actualizar PostgreSQL
   - Tú debes monitorear el espacio

2. **Escalabilidad**
   - Limitado por tu servidor
   - Si el servidor cae, todo cae

3. **Tiempo de Desarrollo**
   - Requiere cambiar código
   - Requiere crear API backend
   - Requiere migrar datos

4. **Funciones de Supabase**
   - Pierdes autenticación de Supabase
   - Pierdes storage de archivos
   - Pierdes funciones serverless

## 📝 Checklist de Migración

- [ ] Crear base de datos PostgreSQL en EasyPanel
- [ ] Exportar todos los datos de Supabase
- [ ] Importar datos a nueva base de datos
- [ ] Verificar que todos los datos se importaron correctamente
- [ ] Actualizar `whatsapp-server.js` para usar PostgreSQL directo
- [ ] Actualizar `supabase-client.js` o crear nuevo cliente de BD
- [ ] Crear API backend (opcional pero recomendado)
- [ ] Actualizar `dashboard.html` para usar nueva API
- [ ] Actualizar `crm.html` para usar nueva API
- [ ] Probar todas las funcionalidades
- [ ] Configurar backups automáticos
- [ ] Documentar nueva configuración

## 🛠️ Scripts de Ayuda

Puedo crear scripts para:
1. **Exportar datos de Supabase** (tabla por tabla)
2. **Importar datos a PostgreSQL** (con verificación)
3. **Migrar código** (cambiar Supabase por PostgreSQL)
4. **Crear API backend** (endpoints básicos)

## 💡 Recomendación

**Para empezar:**
1. Mantén Supabase funcionando
2. Crea la base de datos en tu servidor
3. Configura sincronización bidireccional (escribe en ambas)
4. Prueba que todo funciona
5. Migra gradualmente
6. Cuando estés seguro, desconecta Supabase

**Esto te permite:**
- ✅ No perder datos durante la migración
- ✅ Probar sin riesgo
- ✅ Volver atrás si algo falla
- ✅ Migrar gradualmente

## 📚 Próximos Pasos

Si decides migrar, puedo ayudarte a:
1. Crear scripts de exportación/importación
2. Crear el cliente de PostgreSQL
3. Crear la API backend
4. Actualizar el código del Dashboard y CRM
5. Configurar backups automáticos

¿Quieres que prepare los scripts de migración ahora o prefieres hacerlo más adelante?






