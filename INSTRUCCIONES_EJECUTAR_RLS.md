# 📋 Instrucciones para Ejecutar el Script RLS

## 🚀 Pasos Rápidos

1. **Abre Supabase Dashboard:**
   - Ve a tu proyecto en [supabase.com](https://supabase.com)
   - Inicia sesión si es necesario

2. **Abre el SQL Editor:**
   - En el menú lateral izquierdo, haz clic en **"SQL Editor"** (Editor SQL)
   - O usa el atajo: busca "SQL" en la barra de búsqueda

3. **Crea un nuevo query:**
   - Haz clic en el botón **"New query"** (Nueva consulta) o **"+"**

4. **Copia y pega el script:**
   - Abre el archivo `script_rls_completo.sql`
   - Selecciona TODO el contenido (Ctrl+A)
   - Copia (Ctrl+C)
   - Pega en el editor SQL de Supabase (Ctrl+V)

5. **Ejecuta el script:**
   - Haz clic en el botón **"Run"** (Ejecutar) o presiona `Ctrl+Enter`
   - Espera a que termine (debería tomar unos segundos)

6. **Verifica que funcionó:**
   - Deberías ver un mensaje de éxito
   - Si hay errores, revisa que las tablas existan

## ✅ Verificación

Después de ejecutar el script, verifica en la consola del navegador del dashboard:

```javascript
// Recargar la página
location.reload();

// Probar obtener chats
const chats = await window.supabaseClient.getWhatsAppChats(10);
console.log('✅ Chats obtenidos:', chats.length, chats);

// Probar obtener interacciones
const interactions = await window.supabaseClient.getFlorInteractions(10);
console.log('✅ Interacciones obtenidas:', interactions.length, interactions);
```

## 🎯 Qué Hace el Script

El script:
- ✅ Habilita RLS en las 3 tablas principales
- ✅ Crea políticas de SELECT (lectura) para todas
- ✅ Crea políticas de INSERT (inserción) para todas
- ✅ Crea políticas de UPDATE (actualización) para todas
- ✅ Crea políticas de DELETE (eliminación) para todas
- ✅ Elimina políticas duplicadas si existen

## ⚠️ Si Hay Errores

### Error: "relation does not exist"
- La tabla no existe. Verifica que las tablas estén creadas en Supabase.

### Error: "policy already exists"
- Ya existe una política con ese nombre. El script intenta eliminarla primero, pero si persiste, elimínala manualmente desde el dashboard.

### Error: "permission denied"
- Verifica que tengas permisos de administrador en el proyecto de Supabase.

## 📸 Captura de Pantalla

Si necesitas ayuda visual:
1. Ve a **Table Editor** > Selecciona una tabla (ej: `whatsapp_chats`)
2. Ve a la pestaña **"Policies"**
3. Deberías ver 4 políticas listadas (SELECT, INSERT, UPDATE, DELETE)

