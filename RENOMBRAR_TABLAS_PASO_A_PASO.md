# 🔄 Renombrar Tablas: Español → Inglés

## ⚠️ Problema Detectado

Las tablas en Supabase tienen nombres en **español**, pero el código JavaScript espera nombres en **inglés**:

| ❌ Nombre Actual (Español) | ✅ Nombre Correcto (Inglés) |
|---------------------------|----------------------------|
| `hoteles` | `hotels` |
| `reservas` | `reservations` |
| `cotizaciones` | `quotes` |
| `gastos` | `expenses` |
| `usuarios_del_sistema` | `system_users` |
| `dashboard_admins` | ✅ Ya está correcto |

## ✅ Solución: Renombrar las Tablas

He creado un script SQL que renombra todas las tablas automáticamente.

---

## 📋 Pasos para Renombrar

### Paso 1: Abrir el Script SQL

1. **Busca el archivo** `renombrar-tablas-espanol-a-ingles.sql` en tu carpeta
2. **Abre el archivo** (puedo abrirlo por ti si quieres)

### Paso 2: Copiar el SQL

1. En el archivo abierto:
   - Presiona **`Ctrl+A`** (selecciona todo)
   - Presiona **`Ctrl+C`** (copia)

### Paso 3: Ejecutar en Supabase

1. **Ve a Supabase SQL Editor**
   - Si ya estás ahí, perfecto
   - Si no, menú lateral → ícono `<>` → "SQL Editor"

2. **Crear nueva consulta**:
   - Haz clic en **"New query"** o **"Nueva consulta"**
   - O simplemente borra el SQL anterior

3. **Pegar el SQL**:
   - Pega el contenido: **`Ctrl+V`**

4. **Ejecutar**:
   - Haz clic en **"Run"** o presiona **`Ctrl+Enter`**

### Paso 4: Verificar

1. **Ve a Table Editor** (menú lateral → ícono `📋`)
2. **Deberías ver** las tablas con nombres en inglés:
   - ✅ `hotels` (antes `hoteles`)
   - ✅ `reservations` (antes `reservas`)
   - ✅ `quotes` (antes `cotizaciones`)
   - ✅ `expenses` (antes `gastos`)
   - ✅ `system_users` (antes `usuarios_del_sistema`)
   - ✅ `dashboard_admins` (sin cambios)

---

## 🎯 ¿Qué hace este Script?

Usa `ALTER TABLE ... RENAME TO` para cambiar los nombres de las tablas sin perder los datos.

**Es seguro:**
- ✅ No borra datos
- ✅ No afecta la estructura de las tablas
- ✅ Solo cambia el nombre

---

## ⚠️ Importante

- **No ejecutes este script dos veces** (daría error si ya no existe el nombre antiguo)
- **Los datos se conservan** - solo cambia el nombre de la tabla
- **Las relaciones se mantienen** - las claves foráneas siguen funcionando

---

## 🚀 Después de Renombrar

Una vez que las tablas tengan los nombres correctos:
1. ✅ El dashboard podrá conectarse a Supabase
2. ✅ Los datos se guardarán en la nube
3. ✅ Todo funcionará correctamente

¿Necesitas ayuda con algún paso? ¡Avísame! 🎉

