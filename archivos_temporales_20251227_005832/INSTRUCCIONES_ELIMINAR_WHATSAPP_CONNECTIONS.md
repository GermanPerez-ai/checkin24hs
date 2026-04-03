# 🗑️ Instrucciones para Eliminar Solo whatsapp_connections

Este documento te guía para eliminar únicamente la tabla `whatsapp_connections` de Supabase, que está causando el error 404.

## ⚠️ ADVERTENCIA

**Esta operación es IRREVERSIBLE**. Una vez que ejecutes el script, todos los datos de `whatsapp_connections` se perderán permanentemente.

## 📋 Pasos para Eliminar whatsapp_connections

### Paso 1: Acceder a Supabase Dashboard

1. Abre tu navegador y ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Inicia sesión con tu cuenta
3. Selecciona el proyecto **checkin24hs** (o el nombre de tu proyecto)

### Paso 2: Abrir el SQL Editor

1. En el menú lateral izquierdo, haz clic en **"SQL Editor"** (Editor SQL)
2. Haz clic en **"New query"** (Nueva consulta) o en el botón **"+"** para crear una nueva consulta

### Paso 3: Copiar el Script

1. Abre el archivo `ELIMINAR_WHATSAPP_CONNECTIONS.sql` que está en tu carpeta del proyecto
2. Copia **TODO** el contenido del archivo (Ctrl+A, luego Ctrl+C)
3. Pégalo en el editor SQL de Supabase (Ctrl+V)

### Paso 4: Ejecutar el Script

1. Haz clic en el botón **"Run"** (Ejecutar) o presiona `Ctrl+Enter`
2. Espera a que se complete la ejecución (puede tardar unos segundos)
3. Verifica que veas el mensaje: **"✅ La tabla whatsapp_connections ha sido eliminada correctamente"**

### Paso 5: Verificar

Después de ejecutar, el error 404 de `whatsapp_connections` debería desaparecer. 

Puedes verificar manualmente ejecutando esta consulta:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'whatsapp_connections';
```

Si la tabla fue eliminada correctamente, esta consulta debería devolver **0 filas**.

## ✅ Después de Eliminar

1. **Limpia la caché del navegador** (Ctrl+Shift+Delete) para asegurarte de que no queden referencias en el código del frontend
2. **Recarga el dashboard** (Ctrl+Shift+R para hard refresh)
3. **Verifica que el error 404 haya desaparecido** de la consola del navegador

## 🆘 Si Algo Sale Mal

Si por alguna razón el script falla:

1. **Revisa los mensajes de error**: Te dirán exactamente qué falló
2. **Verifica si la tabla existe**: Ejecuta la consulta de verificación manual
3. **Si la tabla no existe**: Eso está bien, significa que ya fue eliminada anteriormente

---

**¿Listo para eliminar whatsapp_connections?** Sigue los pasos anteriores y ejecuta el script. 🚀

