# 📋 Guía Paso a Paso: Crear Tablas en Supabase

## 🎯 Objetivo
Crear todas las tablas necesarias para el dashboard en Supabase.

## 📝 Pasos Detallados

### Paso 1: Ir al SQL Editor

1. **En Supabase**, en el menú lateral izquierdo
2. **Busca el ícono** que dice **"SQL Editor"** o tiene un símbolo `<>`
   - Está en la parte superior del menú lateral
   - Tiene un ícono de código o editor
3. **Haz clic** en "SQL Editor"

### Paso 2: Crear Nueva Consulta

1. En el SQL Editor, haz clic en el botón **"New query"** o **"Nueva consulta"**
   - Está en la parte superior izquierda
   - O simplemente empieza a escribir en el editor

### Paso 3: Abrir el Archivo SQL

1. En tu computadora, abre el archivo `create-tables.sql`
   - Está en la carpeta `Checkin24hs`
   - Es un archivo de texto con extensión `.sql`

### Paso 4: Copiar el SQL

1. **Selecciona TODO** el contenido del archivo `create-tables.sql`
   - Presiona `Ctrl+A` para seleccionar todo
   - O arrastra desde el inicio hasta el final

2. **Copia** el contenido
   - Presiona `Ctrl+C`
   - O clic derecho → Copiar

### Paso 5: Pegar en Supabase

1. **En el SQL Editor de Supabase**, haz clic en el área de texto grande
2. **Pega** el contenido
   - Presiona `Ctrl+V`
   - O clic derecho → Pegar

### Paso 6: Ejecutar el SQL

1. **Revisa** que todo el SQL esté pegado correctamente
   - Deberías ver muchas líneas de código SQL
   - Empezando con `CREATE TABLE hotels`

2. **Ejecuta** el SQL:
   - Haz clic en el botón **"Run"** (Ejecutar) en la esquina inferior derecha
   - O presiona `Ctrl+Enter`
   - O haz clic en el botón con el ícono de "play" ▶️

### Paso 7: Verificar Resultado

Deberías ver uno de estos mensajes:

✅ **Éxito:**
```
Success. No rows returned
```
O simplemente ver que el mensaje dice que se ejecutó correctamente.

❌ **Error:**
Si ves un error, puede ser porque:
- Las tablas ya existen (no es grave, puedes continuar)
- Hay un error de sintaxis (revisa que copiaste todo correctamente)

### Paso 8: Verificar que las Tablas se Crearon

1. En el menú lateral izquierdo de Supabase, haz clic en **"Table Editor"** o **"Editor de Tablas"**
   - Tiene un ícono de tabla/grid

2. Deberías ver estas 6 tablas:
   - ✅ `hotels` - Hoteles
   - ✅ `reservations` - Reservas
   - ✅ `quotes` - Cotizaciones
   - ✅ `expenses` - Gastos
   - ✅ `system_users` - Usuarios del sistema
   - ✅ `dashboard_admins` - Administradores

## 🎉 ¡Listo!

Una vez que veas las 6 tablas en el Table Editor, ¡todo está listo!

## ❓ Problemas Comunes

### Error: "relation already exists"
- **Significa**: Las tablas ya existen
- **Solución**: No es un problema, puedes continuar
- Las tablas ya están creadas

### Error: "syntax error"
- **Significa**: Hay un error en el SQL
- **Solución**: 
  1. Asegúrate de haber copiado TODO el contenido
  2. No dejes ninguna línea sin copiar
  3. Copia de nuevo desde el principio

### No veo las tablas
- **Solución**: 
  1. Refresca la página de Supabase
  2. Ve a Table Editor de nuevo
  3. Si aún no aparecen, ejecuta el SQL de nuevo

## 📞 ¿Necesitas Ayuda?

Si tienes problemas, puedes:
1. Compartir la captura de pantalla del error
2. Decirme qué mensaje ves después de ejecutar
3. Describir qué paso está fallando

¡Estoy aquí para ayudarte! 🚀

