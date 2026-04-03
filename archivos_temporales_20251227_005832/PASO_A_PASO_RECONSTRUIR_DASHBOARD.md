# 📋 Paso a Paso: Reconstruir Dashboard desde GitHub

## 🎯 Objetivo

Actualizar el dashboard para que use el código más reciente de GitHub, no la versión vieja.

## 📝 Pasos Detallados

### Paso 1: Ir al Servicio Dashboard

1. **Abre EasyPanel** en tu navegador
2. En el **menú lateral izquierdo**, busca la sección **"SERVICIOS"** o **"SERVICES"**
3. **Haz clic en "dashboard"** (debería estar en la lista de servicios)

### Paso 2: Ir a la Sección "Fuente"

1. En la página del servicio dashboard, busca en el **menú lateral izquierdo** (dentro de la página del servicio)
2. Busca una opción que diga:
   - **"Fuente"** (en español)
   - **"Source"** (en inglés)
   - O un icono que parezca una carpeta o código
3. **Haz clic en "Fuente"** o **"Source"**

### Paso 3: Verificar la Configuración

En la página de "Fuente", deberías ver campos como:

- **Tipo** o **Type**: Debe decir "GitHub" o "Github"
- **Propietario** o **Owner**: Debe decir `GermanPerez-ai` (o tu usuario de GitHub)
- **Repositorio** o **Repository**: Debe decir `checkin24hs`
- **Rama** o **Branch**: Debe decir `main`
- **Ruta de compilación** o **Build Path**: **ESTO ES LO MÁS IMPORTANTE**

### Paso 4: Cambiar la Ruta de Compilación

1. **Busca el campo "Ruta de compilación"** o **"Build Path"**
2. **Haz clic en ese campo** para editarlo
3. **Borra** lo que haya escrito (puede ser `/`, `/deploy`, o algo similar)
4. **Escribe exactamente**: `/checkin24hs-admin`
5. **NO** pongas espacio al final, solo: `/checkin24hs-admin`

### Paso 5: Guardar

1. **Busca el botón "Guardar"** (verde) en la parte inferior de la página
2. **Haz clic en "Guardar"**
3. **Espera** unos segundos a que se guarde

### Paso 6: Reconstruir

Después de guardar, busca uno de estos botones:

- **"Reconstruir"** o **"Rebuild"**
- **"Sincronizar"** o **"Sync"**
- **"Actualizar"** o **"Update"**
- **"Implementar"** o **"Deploy"**

**Haz clic en ese botón** para forzar la reconstrucción desde GitHub.

### Paso 7: Esperar

1. **Espera** a que termine la reconstrucción (puede tardar 2-5 minutos)
2. Verás un mensaje de "Building" o "Construyendo"
3. Cuando termine, debería decir "Running" o "Corriendo" en verde

### Paso 8: Limpiar Cache del Navegador

1. **Abre una ventana de incógnito** en tu navegador:
   - Chrome/Edge: `Ctrl+Shift+N`
   - Firefox: `Ctrl+Shift+P`
2. **O limpia la cache**:
   - Presiona `Ctrl+Shift+Delete`
   - Selecciona "Imágenes y archivos en caché"
   - Haz clic en "Borrar datos"
3. **Accede de nuevo** a `https://dashboard.checkin24hs.com`

## 🆘 Si No Encuentras "Fuente"

Si no ves la opción "Fuente" en el menú lateral:

1. **Busca en la parte superior** de la página del servicio
2. Puede haber **pestañas** como: "General", "Fuente", "Variables", etc.
3. **Haz clic en la pestaña "Fuente"**

## 🆘 Si No Hay Botón de Reconstruir

Si no encuentras un botón de "Reconstruir":

1. **Ve a "Implementaciones"** o **"Deployments"** en el menú lateral
2. **Busca un botón "+"** o **"Nueva Implementación"**
3. **O simplemente haz clic en "Implementar"** en la parte superior de la página

## ✅ Verificación

Después de todo esto:

1. El servicio debería reconstruirse
2. Los logs deberían mostrar que está descargando desde GitHub
3. El dashboard debería mostrar la versión actualizada (no los datos de prueba viejos)

---

**Si en algún paso no sabes dónde hacer clic, dime qué ves en la pantalla y te guío más específicamente.**

