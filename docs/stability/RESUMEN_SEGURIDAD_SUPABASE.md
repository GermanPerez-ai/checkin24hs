# 🔐 Resumen: Seguridad de Supabase - Endpoints en Backend

## ✅ Implementación Completa

### Endpoints de Supabase Creados en Backend

Se han creado endpoints genéricos en `server.js` para operaciones de Supabase que usan la clave **service_role** (más segura) en lugar de la clave anon del frontend.

---

## 📋 Endpoints Disponibles

### 1. **GET `/api/supabase/:table`** - Consultar
Consulta registros de una tabla.

**Parámetros:**
- `table`: Nombre de la tabla (hotels, reservations, quotes, expenses, etc.)
- `select` (query): Columnas a seleccionar (default: '*')
- `filter` (query): Filtros JSON (ej: `{"status":"Activo"}`)
- `order` (query): Ordenamiento (ej: `created_at:desc`)
- `limit` (query): Límite de resultados (máx: 1000)

**Ejemplo:**
```javascript
// Obtener todos los hoteles
fetch('/api/supabase/hotels')

// Obtener hoteles activos ordenados por fecha
fetch('/api/supabase/hotels?filter={"status":"Activo"}&order=created_at:desc')

// Obtener solo nombre y ubicación
fetch('/api/supabase/hotels?select=name,location')
```

---

### 2. **POST `/api/supabase/:table`** - Insertar
Inserta uno o varios registros en una tabla.

**Parámetros:**
- `table`: Nombre de la tabla
- Body: Objeto o array de objetos a insertar

**Ejemplo:**
```javascript
// Insertar un hotel
fetch('/api/supabase/hotels', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        name: 'Hotel Ejemplo',
        location: 'Santiago',
        status: 'Activo'
    })
})

// Insertar múltiples registros
fetch('/api/supabase/reservations', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify([
        { code: 'RES001', hotel_id: '...' },
        { code: 'RES002', hotel_id: '...' }
    ])
})
```

---

### 3. **PUT `/api/supabase/:table/:id`** - Actualizar
Actualiza un registro por ID.

**Parámetros:**
- `table`: Nombre de la tabla
- `id`: ID del registro a actualizar
- Body: Objeto con los campos a actualizar

**Ejemplo:**
```javascript
fetch('/api/supabase/hotels/123e4567-e89b-12d3-a456-426614174000', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        name: 'Hotel Actualizado',
        status: 'Inactivo'
    })
})
```

---

### 4. **DELETE `/api/supabase/:table/:id`** - Eliminar
Elimina un registro por ID.

**Parámetros:**
- `table`: Nombre de la tabla
- `id`: ID del registro a eliminar

**Ejemplo:**
```javascript
fetch('/api/supabase/hotels/123e4567-e89b-12d3-a456-426614174000', {
    method: 'DELETE'
})
```

---

### 5. **GET `/api/supabase/test`** - Probar Conexión
Prueba la conexión con Supabase.

**Respuesta:**
```json
{
    "success": true,
    "configured": true,
    "connected": true,
    "message": "Conexión exitosa con Supabase"
}
```

---

## 🔒 Seguridad Implementada

### ✅ Clave Service Role en Backend

- ✅ **Backend:** Usa `SUPABASE_SERVICE_KEY` del archivo `.env`
- ✅ **Frontend:** Ya NO necesita la clave anon directamente
- ✅ **Ventaja:** Más permisos y control desde el backend

### ✅ Validación de Tablas

Solo permite operaciones en tablas permitidas:
- `hotels`
- `reservations`
- `quotes`
- `expenses`
- `checkin24hs_users`
- `clientesDB`
- `users`

### ✅ Protecciones Adicionales

- Límite de 1000 registros por consulta
- Validación de filtros JSON
- Manejo de errores robusto
- Logging de errores

---

## 🔒 Variables de Entorno Requeridas

Agregar al archivo `.env` del servidor:

```env
# Supabase (URL ya puede estar en frontend, pero backend usa service_role)
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_SERVICE_KEY=tu_service_role_key_aqui
# O alternativamente:
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key_aqui
```

**⚠️ IMPORTANTE:**
- La clave `SUPABASE_SERVICE_KEY` es **PRIVADA** y debe estar solo en el backend
- **NUNCA** exponerla en el frontend
- Se obtiene en: Supabase Dashboard → Settings → API → `service_role` key

---

## 📦 Dependencia Requerida

Instalar Supabase en el servidor:

```bash
npm install @supabase/supabase-js
```

El código verifica si está instalado y muestra advertencias si no lo está.

---

## 🔄 Migración del Frontend

### Opción 1: Usar Endpoints del Backend (Recomendado)

Modificar `supabase-client.js` para usar los endpoints del backend en lugar de llamadas directas:

```javascript
// ANTES (directo a Supabase)
async getHotels() {
    const { data, error } = await this.client
        .from('hotels')
        .select('*');
    return data;
}

// DESPUÉS (a través del backend)
async getHotels() {
    const response = await fetch('/api/supabase/hotels');
    const data = await response.json();
    return data;
}
```

### Opción 2: Mantener Frontend (Híbrido)

- Mantener llamadas directas desde el frontend para operaciones simples
- Usar endpoints del backend para operaciones críticas o que requieren más permisos
- El código ya tiene fallback a `localStorage`

---

## ✅ Beneficios

1. **Seguridad:**
   - La clave service_role nunca se expone al cliente
   - Validaciones adicionales en el backend
   - Control de acceso a tablas

2. **Control:**
   - Puedes agregar validaciones antes de guardar
   - Puedes implementar rate limiting
   - Puedes registrar todas las operaciones

3. **Flexibilidad:**
   - Puedes transformar datos antes de guardar
   - Puedes agregar lógica de negocio
   - Puedes combinar con otras APIs

---

## ⚠️ Notas Importantes

### Clave Anon vs Service Role

- **Anon Key:** Diseñada para usar en frontend, tiene permisos limitados por RLS
- **Service Role Key:** Clave privada con permisos completos, solo para backend

### Recomendación

Para máxima seguridad, usar **SOLO** los endpoints del backend y eliminar la clave anon del frontend. Esto requiere:

1. Modificar `supabase-client.js` para usar `/api/supabase/*`
2. Eliminar `supabase-config.js` del frontend (o vaciar la clave anon)
3. Agregar autenticación a los endpoints si es necesario

---

## 📋 Próximos Pasos

1. ✅ Endpoints de backend creados
2. ⏳ Instalar `@supabase/supabase-js` en el servidor
3. ⏳ Agregar `SUPABASE_SERVICE_KEY` al `.env` del servidor
4. ⏳ Probar endpoints desde el frontend
5. ⏳ Opcional: Migrar `supabase-client.js` para usar endpoints del backend

---

**Última actualización:** 2026-01-17
**Build:** #40
**Estado:** ✅ Implementado (pendiente de probar)
