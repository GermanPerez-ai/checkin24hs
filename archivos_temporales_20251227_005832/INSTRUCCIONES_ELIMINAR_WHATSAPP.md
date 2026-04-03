# 🗑️ Instrucciones para Eliminar WhatsApp de Supabase

Este documento te guía paso a paso para eliminar completamente todo lo relacionado con WhatsApp de tu base de datos Supabase.

## ⚠️ ADVERTENCIA IMPORTANTE

**Esta operación es IRREVERSIBLE**. Una vez que ejecutes el script, todos los datos relacionados con WhatsApp se perderán permanentemente:
- Todos los chats de WhatsApp
- Todos los mensajes de WhatsApp
- Todas las conexiones de WhatsApp
- Todas las estadísticas e interacciones relacionadas

**Asegúrate de hacer un backup si necesitas conservar algún dato.**

## 📋 Pasos para Eliminar WhatsApp

### Paso 1: Acceder a Supabase Dashboard

1. Abre tu navegador y ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Inicia sesión con tu cuenta
3. Selecciona el proyecto **checkin24hs** (o el nombre de tu proyecto)

### Paso 2: Abrir el SQL Editor

1. En el menú lateral izquierdo, haz clic en **"SQL Editor"** (Editor SQL)
2. Haz clic en **"New query"** (Nueva consulta) o en el botón **"+"** para crear una nueva consulta

### Paso 3: Copiar el Script

1. Abre el archivo `ELIMINAR_WHATSAPP_SUPABASE.sql` que está en tu carpeta del proyecto
2. Copia **TODO** el contenido del archivo (Ctrl+A, luego Ctrl+C)
3. Pégalo en el editor SQL de Supabase (Ctrl+V)

### Paso 4: Revisar el Script

Antes de ejecutar, revisa el script para asegurarte de que:

- ✅ Elimina las tablas: `whatsapp_chats`, `whatsapp_messages`, `whatsapp_connections`
- ✅ Elimina las vistas: `flor_stats`, `flor_intents`
- ✅ Elimina los triggers relacionados
- ✅ Elimina las políticas RLS relacionadas
- ✅ Elimina los índices relacionados

**⚠️ NOTA IMPORTANTE sobre `flor_interactions`:**

El script tiene comentadas las líneas que eliminan `flor_interactions` porque esta tabla podría ser usada para otras funcionalidades además de WhatsApp. 

- Si **SOLO** usas `flor_interactions` para WhatsApp, descomenta las líneas relacionadas (quita los `--` al inicio)
- Si usas `flor_interactions` para otras cosas, **NO** descomentes esas líneas

### Paso 5: Ejecutar el Script

1. Una vez que hayas revisado el script, haz clic en el botón **"Run"** (Ejecutar) o presiona `Ctrl+Enter`
2. Espera a que se complete la ejecución (puede tardar unos segundos)
3. Verifica que no haya errores en la salida

### Paso 6: Verificar la Eliminación

El script incluye consultas de verificación al final. Deberías ver:

- **0 filas** en la consulta de tablas (no debería haber tablas con "whatsapp" en el nombre)
- **0 filas** en la consulta de vistas (no debería haber vistas con "flor" relacionadas a WhatsApp)

Si ves alguna tabla o vista, significa que algo no se eliminó correctamente.

## 🔍 Verificación Manual (Opcional)

Si quieres verificar manualmente que todo se eliminó:

### Verificar Tablas
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND (table_name LIKE '%whatsapp%' OR table_name LIKE '%flor_interactions%')
ORDER BY table_name;
```

### Verificar Vistas
```sql
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public' 
  AND table_name LIKE '%flor%'
ORDER BY table_name;
```

### Verificar Políticas RLS
```sql
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename LIKE '%whatsapp%'
ORDER BY tablename, policyname;
```

## ✅ Después de Eliminar

Una vez que hayas eliminado todo de Supabase:

1. **Limpia la caché del navegador** (Ctrl+Shift+Delete) para asegurarte de que no queden referencias en el código del frontend
2. **Verifica que el dashboard funcione correctamente** sin errores relacionados con WhatsApp
3. El error 404 de `whatsapp_connections` debería desaparecer

## 🆘 Si Algo Sale Mal

Si por alguna razón el script falla o necesitas ayuda:

1. **No entres en pánico**: Los errores suelen ser por dependencias o porque algo ya no existe
2. **Revisa los mensajes de error**: Te dirán exactamente qué falló
3. **Ejecuta las consultas de verificación** para ver qué quedó pendiente
4. **Elimina manualmente** lo que quede usando comandos SQL individuales

## 📝 Notas Adicionales

- El script usa `IF EXISTS` y `CASCADE` para evitar errores si algo ya no existe
- El orden de eliminación es importante: primero triggers, luego políticas, luego vistas, luego índices, y finalmente tablas
- Si tienes datos importantes en `flor_interactions` que NO son de WhatsApp, asegúrate de NO eliminar esa tabla

---

**¿Listo para eliminar WhatsApp?** Sigue los pasos anteriores y ejecuta el script. 🚀

