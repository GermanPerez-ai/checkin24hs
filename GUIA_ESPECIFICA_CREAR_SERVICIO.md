# 📋 Guía Específica: Crear Servicio Dashboard

## 🎯 Desde la Pantalla Actual

Estás viendo la pantalla de "Dominios" del servicio `dashboard`. Sigue estos pasos:

---

## Paso 1: Hacer Clic en "+ Servicio"

1. **Mira la parte superior derecha** de la pantalla
2. Verás tres botones:
   - `+ Servicio` (este es el que necesitas)
   - `Plantillas`
   - Un icono con tres líneas
3. **Haz clic en `+ Servicio`**
4. Se abrirá un modal para crear un nuevo servicio

---

## Paso 2: En el Modal que se Abre

### 2.1 Nombre y Proyecto

1. **"Seleccionar proyecto"** (dropdown en la parte superior):
   - Selecciona: `checkin24hs`

2. **"Nombre del servicio"** (campo de texto):
   - Escribe: `dashboard-new` o `dashboard2` (temporalmente, para que no entre en conflicto)
   - **NO** uses `dashboard` todavía porque ya existe

3. **Tipo de servicio**:
   - Selecciona: **"Aplicación"** o **"App"**

4. Haz clic en **"Crear"** o **"Siguiente"**

---

## Paso 3: Configurar la Fuente

Después de crear el servicio, verás varias pestañas. Ve a la pestaña **"Fuente"** (en el menú lateral izquierdo):

### Si usas GitHub:

1. Haz clic en la pestaña **"Github"**
2. Selecciona tu repositorio: `Checkin24hs`
3. Selecciona la rama: `main`

4. **Busca estos campos** (pueden estar en diferentes lugares):
   - **"Build Path"** o **"Ruta de compilación"**:
     - Escribe: `/deploy`
   - **"Dockerfile Path"** o **"Ruta del Dockerfile"**:
     - Escribe: `Dockerfile`
     - O si está en la carpeta deploy: `deploy/Dockerfile`

### Si no ves "Build Path" o "Dockerfile Path":

1. Busca un botón **"Configuración avanzada"** o **"Advanced"**
2. O busca una sección **"Build Settings"** o **"Configuración de Build"**
3. O busca en la parte inferior del formulario campos adicionales

---

## Paso 4: Configurar el Puerto

1. Busca la pestaña **"Puertos"** o **"Ports"** (en el menú lateral izquierdo)
2. O busca una sección de **"Recursos"** o **"Resources"**
3. **Agrega un puerto**:
   - Haz clic en **"+"** o **"Agregar puerto"**
   - **Puerto interno**: `80`
   - **Puerto externo**: Puede estar vacío o ser `80`

---

## Paso 5: Variables de Entorno

1. Ve a la pestaña **"Entorno"** o **"Environment"** (en el menú lateral izquierdo)
2. En el campo de texto grande, escribe:
   ```
   PORT=80
   ```
3. Haz clic en **"Guardar"** (si hay un botón)

---

## Paso 6: Implementar

1. Haz clic en el botón verde **"Implementar"** o **"Deploy"** (en la parte superior)
2. Espera a que se construya (puede tardar varios minutos)
3. Verás los logs de construcción en la pantalla

---

## Paso 7: Agregar el Dominio

Una vez que el servicio esté corriendo:

1. Ve a la pestaña **"Dominios"** (en el menú lateral izquierdo)
2. Haz clic en **"Agregar dominio"** (botón en la parte inferior)
3. Ingresa: `dashboard.checkin24hs.com`
4. EasyPanel debería generar automáticamente el destino
5. **Verifica que el destino sea**: `http://dashboard-new:80/` o `http://dashboard2:80/` (dependiendo del nombre que usaste)

---

## 🔍 Si No Encuentras los Campos

**Build Path y Dockerfile Path** pueden estar en:
- La pestaña "Fuente" → Sección "Configuración avanzada"
- O en un botón "Mostrar más opciones"
- O en la parte inferior del formulario de GitHub/Git

**Puerto** puede estar en:
- Pestaña "Puertos" (en el menú lateral)
- Pestaña "Recursos" (en el menú lateral)
- O en la configuración general del servicio

---

**Haz clic en `+ Servicio` (arriba a la derecha) y dime qué ves en el modal que se abre.**
