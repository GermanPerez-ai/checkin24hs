# 📸 Guía: Subir Imágenes para Hoteles

## ✅ Funcionalidad Implementada

Ya puedes subir imágenes cuando creas o editas un hotel. Las imágenes se guardan directamente en la base de datos del hotel.

---

## 🚀 Cómo Subir Imágenes

### Opción 1: Imagen Principal

1. **Abre el formulario** de crear o editar hotel
2. **Busca el campo** "Imagen Principal"
3. **Haz clic en "Seleccionar"**
   - Se abrirá el **Gestor de Imágenes**
4. **En el gestor:**
   - Haz clic en **"Seleccionar archivo"** (o arrastra imágenes)
   - Selecciona una o varias imágenes desde tu computadora
   - Haz clic en **"Subir"**
   - Las imágenes aparecerán en "Imágenes Disponibles"
   - **Haz clic en una imagen** para seleccionarla
   - Haz clic en **"Aplicar Selección"**
5. ✅ La imagen se agregará al campo "Imagen Principal"

### Opción 2: Galería de Fotos

1. **Abre el formulario** de crear o editar hotel
2. **Busca el campo** "Galería de Fotos"
3. **Haz clic en "Seleccionar"**
   - Se abrirá el **Gestor de Imágenes**
4. **En el gestor:**
   - Haz clic en **"Seleccionar archivo"** (o arrastra imágenes)
   - Selecciona hasta **10 imágenes** desde tu computadora
   - Haz clic en **"Subir"**
   - Las imágenes aparecerán en "Imágenes Disponibles"
   - **Haz clic en las imágenes** que quieras agregar (puedes seleccionar múltiples)
   - Haz clic en **"Aplicar Selección"**
5. ✅ Las imágenes se agregarán a la galería

---

## 📋 Características

### ✅ Lo que Funciona

- ✅ Subir múltiples imágenes a la vez
- ✅ Vista previa de imágenes antes de seleccionar
- ✅ Imagen principal: 1 imagen máxima
- ✅ Galería: hasta 10 imágenes
- ✅ Las imágenes se guardan en la base de datos
- ✅ Vista previa en el formulario
- ✅ Validación de tamaño (máximo 5MB por imagen)
- ✅ Validación de formato (solo imágenes: JPG, PNG, etc.)

### ⚠️ Limitaciones Actuales

- Las imágenes se guardan como **base64** en la base de datos
- Esto funciona perfectamente, pero si tienes muchas imágenes grandes, puede aumentar el tamaño de la base de datos
- **Futuro:** Podremos migrar a Supabase Storage para mejor rendimiento

---

## 🎯 Pasos Detallados

### Paso 1: Abrir el Formulario

1. Ve a la sección **"Hoteles"** en el dashboard
2. Haz clic en **"Agregar Nuevo Hotel"** o **"Editar"** en un hotel existente

### Paso 2: Subir Imágenes

1. En el formulario, busca **"Imagen Principal"** o **"Galería de Fotos"**
2. Haz clic en el botón **"Seleccionar"**
3. Se abrirá el **Gestor de Imágenes**

### Paso 3: En el Gestor de Imágenes

1. **Subir imágenes:**
   - Haz clic en el campo de archivo o arrastra imágenes
   - Selecciona las imágenes desde tu computadora
   - Haz clic en **"Subir"**
   - Espera a que se procesen (verás mensajes en la consola)

2. **Seleccionar imágenes:**
   - Las imágenes subidas aparecerán en **"Imágenes Disponibles"**
   - Haz clic en una imagen para seleccionarla
   - Las imágenes seleccionadas aparecerán en **"Imágenes Seleccionadas"**
   - Puedes hacer clic nuevamente para deseleccionar

3. **Aplicar selección:**
   - Haz clic en **"Aplicar Selección"**
   - El gestor se cerrará
   - Las imágenes aparecerán en el formulario

### Paso 4: Guardar el Hotel

1. Completa los demás campos del hotel
2. Haz clic en **"Guardar Cambios"**
3. ✅ Las imágenes se guardarán junto con el hotel

---

## 🔍 Verificar que Funcionó

1. **Después de guardar**, edita el hotel nuevamente
2. Las imágenes deberían aparecer en los campos correspondientes
3. También deberías ver la **vista previa** de las imágenes

---

## 🆘 Solución de Problemas

### No puedo subir imágenes

- **Verifica** que los archivos sean imágenes (JPG, PNG, etc.)
- **Verifica** que cada imagen sea menor a 5MB
- **Revisa la consola** del navegador (F12) para ver errores

### Las imágenes no aparecen después de guardar

- **Verifica** que hiciste clic en "Aplicar Selección" antes de cerrar el gestor
- **Revisa** que guardaste el hotel correctamente
- Las imágenes se guardan en Supabase, así que deberían persistir

### El gestor no se abre

- **Verifica** que estás en el formulario de crear/editar hotel
- **Revisa la consola** del navegador (F12) para ver errores

---

## 💡 Consejos

1. **Optimiza tus imágenes** antes de subirlas:
   - Usa herramientas como TinyPNG para reducir el tamaño
   - Recomendado: imágenes de 800x600px o similar

2. **Nombres descriptivos:**
   - Nombra tus archivos de forma clara (ej: "hotel-exterior.jpg")

3. **Formato recomendado:**
   - JPG para fotografías
   - PNG para imágenes con transparencia

---

## ✅ ¡Listo!

Ya puedes subir imágenes para tus hoteles. Si tienes algún problema, revisa la consola del navegador (F12) y compárteme los errores que veas.

¡Disfruta subiendo imágenes! 📸

