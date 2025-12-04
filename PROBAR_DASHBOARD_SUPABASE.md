# 🧪 Probar el Dashboard con Supabase

## ✅ Estado Actual

- ✅ Tablas creadas en Supabase (todas en inglés)
- ✅ Credenciales configuradas en `supabase-config.js`
- ✅ Scripts de Supabase incluidos en `dashboard.html`
- ✅ Código JavaScript listo para guardar en la nube

---

## 🚀 Pasos para Probar

### Paso 1: Abrir el Dashboard

1. **Abre el archivo** `dashboard.html` en tu navegador
   - Haz doble clic en el archivo, o
   - Arrastra el archivo al navegador

2. **Abre la Consola del Navegador**
   - Presiona **`F12`** o **`Ctrl+Shift+I`**
   - Ve a la pestaña **"Console"** (Consola)

### Paso 2: Verificar Conexión con Supabase

En la consola, deberías ver mensajes como:

```
✅ Cliente de Supabase inicializado correctamente
✅ Conexión con Supabase verificada correctamente
💾 Los datos se guardarán en la nube automáticamente
```

**Si ves esto:** ✅ Todo está funcionando correctamente

**Si ves errores:**
- Revisa las credenciales en `supabase-config.js`
- Verifica que las tablas existan en Supabase

### Paso 3: Iniciar Sesión

1. **Ingresa al dashboard** con tus credenciales de administrador
2. Deberías ver el dashboard principal

### Paso 4: Crear un Hotel de Prueba

1. Ve a la sección **"Hoteles"** en el menú lateral
2. Haz clic en **"Agregar Nuevo Hotel"**
3. **Llena los datos:**
   - Nombre: "Hotel de Prueba Supabase"
   - Ubicación: "Ciudad de Prueba"
   - Descripción: "Hotel para probar Supabase"
   - Precio: 100
4. Haz clic en **"Guardar"**

### Paso 5: Verificar en Supabase

1. **Abre Supabase** en tu navegador
2. Ve a **Table Editor**
3. Selecciona la tabla **`hotels`**
4. **Deberías ver** el hotel que acabas de crear

**Si ves el hotel:** ✅ ¡Funciona! Los datos se están guardando en la nube

**Si no ves el hotel:**
- Revisa la consola del navegador por errores
- Verifica que la tabla `hotels` exista en Supabase
- Revisa que las credenciales sean correctas

---

## 🔍 Verificar en la Consola

Mientras creas el hotel, en la consola deberías ver mensajes como:

```
☁️ Guardando hotel en Supabase...
✅ Hotel guardado en Supabase correctamente
```

Si ves errores, cópialos y me los muestras.

---

## 📋 Pruebas Adicionales

### Probar Reservas

1. Crea una reserva en el dashboard
2. Verifica que aparezca en la tabla `reservations` de Supabase

### Probar Cotizaciones

1. Crea una cotización en el dashboard
2. Verifica que aparezca en la tabla `quotes` de Supabase

### Probar Gastos

1. Crea un gasto en el dashboard
2. Verifica que aparezca en la tabla `expenses` de Supabase

---

## ⚠️ Solución de Problemas

### Error: "Supabase no está inicializado"

**Causa:** El script de Supabase CDN no se está cargando

**Solución:** Verifica que el script de Supabase CDN esté incluido en `dashboard.html`

### Error: "relation does not exist"

**Causa:** Las tablas no existen o tienen nombres diferentes

**Solución:** 
- Verifica en Supabase Table Editor que las tablas existan
- Los nombres deben ser: `hotels`, `reservations`, `quotes`, `expenses`, `system_users`, `dashboard_admins`

### Los datos no aparecen en Supabase

**Causa:** Puede haber un error al guardar

**Solución:**
- Abre la consola del navegador y revisa los errores
- Verifica que las credenciales sean correctas
- Revisa que Row Level Security (RLS) no esté bloqueando las inserciones

---

## 🎯 Siguiente Paso

Una vez que confirmes que todo funciona:
1. ✅ Los datos se guardan en Supabase
2. ✅ Los datos se cargan desde Supabase
3. ✅ El dashboard funciona correctamente

¡Tu sistema estará completamente configurado! 🎉

---

¿Necesitas ayuda con algún paso? ¡Avísame! 🚀

