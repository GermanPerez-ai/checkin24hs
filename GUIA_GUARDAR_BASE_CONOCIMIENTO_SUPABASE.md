# 📚 Guía: Guardar Base de Conocimiento en Supabase

## 🎯 Objetivo

Para que Flor use la base de conocimiento completa del dashboard, necesitas guardarla en Supabase. El servidor de WhatsApp ahora carga esta información automáticamente.

## ✅ Pasos para Guardar la Base de Conocimiento

### Paso 1: Configurar la Base de Conocimiento en el Dashboard

1. Abre el **dashboard** en tu navegador
2. Ve a la pestaña **"Flor"** → **"Base de Conocimiento"**
3. Selecciona un hotel del selector
4. Completa la información:
   - **Descripción ampliada**
   - **Dirección**
   - **Tipos de habitación**
   - **Políticas**
   - **Información adicional**
5. Haz clic en **"Guardar"**

### Paso 2: Guardar en Supabase (Nuevo)

Necesitas agregar una función en el dashboard para guardar la base de conocimiento en Supabase. 

**Opción A: Guardar Manualmente desde la Consola**

1. Abre el **dashboard** en el navegador
2. Abre la **consola del navegador** (F12)
3. Ejecuta este código:

```javascript
// Obtener toda la base de conocimiento
const allKnowledge = JSON.parse(localStorage.getItem('flor_hotel_knowledge') || '{}');

// Guardar en Supabase
if (typeof supabaseClient !== 'undefined' && supabaseClient.isInitialized()) {
    supabaseClient.client
        .from('system_config')
        .upsert({
            key: 'flor_hotel_knowledge',
            value: JSON.stringify(allKnowledge)
        })
        .then(({ data, error }) => {
            if (error) {
                console.error('❌ Error guardando:', error);
            } else {
                console.log('✅ Base de conocimiento guardada en Supabase');
            }
        });
} else {
    console.error('❌ Supabase no está inicializado');
}
```

### Paso 3: Verificar que se Guardó

1. En Supabase, ve a la tabla `system_config`
2. Busca la fila con `key = 'flor_hotel_knowledge'`
3. Verifica que el `value` contenga la información de los hoteles

### Paso 4: Recargar en el Servidor de WhatsApp

El servidor carga la base de conocimiento automáticamente al iniciar, pero puedes recargarla manualmente:

1. Accede a `http://IP_DEL_SERVIDOR:3001/api/flor/reload-knowledge`
2. O haz una petición POST a ese endpoint
3. El servidor recargará la base de conocimiento desde Supabase

## 🔧 Solución Automática (Recomendado)

Para que se guarde automáticamente, necesitas modificar el código del dashboard para que guarde en Supabase cada vez que actualices la base de conocimiento.

## 📋 Verificación

Después de guardar:

1. **Reinicia el servidor de WhatsApp** (o recarga la base de conocimiento)
2. **Envía un mensaje de prueba** a WhatsApp
3. **Verifica que Flor responda** con la información de la base de conocimiento
4. **Revisa los logs** del servidor para ver si cargó la base de conocimiento

## 🆘 Si No Funciona

1. **Verifica que Supabase esté configurado** correctamente
2. **Verifica que la tabla `system_config` exista** en Supabase
3. **Revisa los logs** del servidor de WhatsApp para ver errores
4. **Verifica que el servidor tenga acceso** a Supabase

