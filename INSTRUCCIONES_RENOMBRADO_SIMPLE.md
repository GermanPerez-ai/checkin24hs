# 🔄 Renombrar Tablas - Versión Simple

## 📋 Situación Actual

Las tablas todavía están en español. Los scripts anteriores no funcionaron. Ahora tenemos un script **más simple y directo** que debería funcionar.

## ✅ Script Simple

He creado `RENOMBRAR_TABLAS_SIMPLE.sql` que:
- ✅ No usa bloques DO complejos
- ✅ Solo usa `ALTER TABLE ... RENAME TO` directo
- ✅ Usa comillas dobles para tablas con espacios
- ✅ Es más fácil de depurar si hay errores

## 🚀 Pasos para Ejecutar

### Paso 1: Abrir el Script

El archivo `RENOMBRAR_TABLAS_SIMPLE.sql` está abierto en Notepad.

### Paso 2: Copiar el SQL

1. Selecciona todo: **`Ctrl+A`**
2. Copia: **`Ctrl+C`**

### Paso 3: Ejecutar en Supabase

1. Ve a **Supabase SQL Editor**
2. **Crea una nueva consulta** (nuevo tab o borra el anterior)
3. **Pega el SQL**: **`Ctrl+V`**
4. **Ejecuta**: Botón **"Ejecutar"** o **`Ctrl+Enter`**

### Paso 4: Revisar Resultados

- **Si dice "Éxito"**: ✅ Las tablas se renombraron
- **Si hay errores**: Aparecerán mensajes específicos que podemos revisar

### Paso 5: Verificar

Después de ejecutar, ejecuta de nuevo `verificar-despues-renombrar.sql` para confirmar que las tablas ahora están en inglés.

---

## ⚠️ Nota Importante

Si alguna tabla ya está renombrada o no existe, puede dar un error. **Eso está bien**, solo significa que esa tabla ya está lista o no existe.

El script intentará renombrar todas las tablas, y las que ya estén en inglés simplemente darán error (que podemos ignorar).

---

## 📝 Tablas que se Renombrarán

| Español | Inglés |
|---------|--------|
| `hoteles` | `hotels` |
| `reservas` | `reservations` |
| `cotizaciones` | `quotes` |
| `gastos` | `expenses` |
| `usuarios del sistema` | `system_users` |
| `administradores del panel de control` | `dashboard_admins` |

---

¡Ejecuta el script y dime qué resultado ves! 🚀

