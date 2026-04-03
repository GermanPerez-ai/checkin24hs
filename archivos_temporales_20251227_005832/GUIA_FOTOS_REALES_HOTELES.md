# 📸 Guía: Subir Fotos Reales de Hoteles

## ✅ Sistema Completo Implementado

Ahora puedes subir **fotos reales** de los hoteles con los que trabajas, y estas fotos se guardarán en la ficha del hotel y se mostrarán automáticamente en tu página web (`index.html`).

---

## 🎯 Cómo Funciona

### 1. **Subes las Fotos en el Dashboard**
   - Abres el dashboard (`dashboard.html`)
   - Vas a la sección "Hoteles"
   - Creas o editas un hotel
   - Subes las fotos reales del hotel

### 2. **Las Fotos se Guardan en la Base de Datos**
   - Las fotos se guardan junto con la información del hotel
   - Se almacenan en `localStorage` o en Supabase (si está configurado)
   - Cada hotel puede tener:
     - **1 Imagen Principal** (para la tarjeta principal)
     - **Múltiples Fotos en Galería** (hasta 10 fotos)

### 3. **Las Fotos Aparecen Automáticamente en index.html**
   - Cuando alguien visita tu página web
   - Los hoteles se cargan automáticamente desde la base de datos
   - Las fotos reales se muestran en las tarjetas de hoteles

---

## 📤 Cómo Subir Fotos Reales

### Opción 1: Subir Archivos desde tu Computadora (Recomendado)

1. **Abre el Dashboard**
   - Ve a `dashboard.html`
   - Inicia sesión si es necesario

2. **Ve a la Sección de Hoteles**
   - Haz clic en "Hoteles" en el menú lateral
   - Haz clic en "Agregar Nuevo Hotel" o "Editar" en un hotel existente

3. **Abre el Gestor de Imágenes**
   - Busca el campo **"Imagen Principal"** o **"Galería de Fotos"**
   - Haz clic en el botón **"Seleccionar"**
   - Se abrirá el **Gestor de Imágenes**

4. **Sube tus Fotos**
   - Haz clic en **"Seleccionar archivo"**
   - Elige las fotos reales del hotel desde tu computadora
   - Puedes seleccionar múltiples fotos a la vez
   - Haz clic en **"Subir"**
   - ⚡ Las fotos se comprimirán automáticamente (reducción de 70-80% de tamaño)

5. **Selecciona las Fotos**
   - Las fotos subidas aparecerán en "Imágenes Disponibles"
   - Haz clic en las fotos que quieras usar
   - Haz clic en **"Aplicar Selección"**

6. **Guarda el Hotel**
   - Completa los demás campos del hotel
   - Haz clic en **"Guardar Cambios"**
   - ✅ Las fotos se guardarán junto con el hotel

---

### Opción 2: Agregar desde URL (Si las fotos ya están en internet)

1. **Abre el Gestor de Imágenes** (igual que arriba)

2. **Haz clic en "🔗 Agregar desde URL"**

3. **Pega la URL de la foto**
   - Si la foto está en internet, copia su URL
   - Pega la URL en el campo
   - Haz clic en "Aceptar"

4. **Guarda el Hotel**
   - Las fotos desde URL también se guardarán
   - Se mostrarán en `index.html` automáticamente

---

## 🌐 Cómo se Muestran en index.html

### Automático
- Las fotos se cargan automáticamente cuando alguien visita `index.html`
- No necesitas hacer nada manualmente
- El sistema busca los hoteles en la base de datos y muestra sus fotos

### Dónde Aparecen
1. **Carrusel de Ofertas**
   - Las fotos aparecen en las tarjetas del carrusel
   - Se muestra la imagen principal de cada hotel

2. **Grid de Hoteles**
   - Las fotos aparecen en las tarjetas del grid
   - Cada hotel muestra su imagen principal

3. **Detalles del Hotel**
   - Cuando se hace clic en un hotel
   - Se pueden mostrar todas las fotos de la galería

---

## 📋 Estructura de Datos

Cada hotel guarda las fotos así:

```javascript
{
  name: "Hotel Termas Chillán",
  location: "Chillán, Chile",
  mainImage: "data:image/jpeg;base64,...", // Imagen principal (base64 o URL)
  galleryImages: [                         // Galería de fotos
    "data:image/jpeg;base64,...",
    "https://ejemplo.com/foto2.jpg",
    ...
  ],
  images: [...], // Compatibilidad con versiones anteriores
  // ... otros campos del hotel
}
```

---

## 🔍 Prioridad de Imágenes

El sistema busca las imágenes en este orden:

1. **`mainImage`** - Imagen principal (prioridad máxima)
2. **`images[0]`** - Primera imagen del array (compatibilidad)
3. **`image`** - Campo antiguo (compatibilidad)
4. **`image_url`** - Campo antiguo (compatibilidad)
5. **Imagen por defecto** - Si no hay ninguna

---

## 💡 Consejos para Fotos Reales

### Tamaño Recomendado
- **Ancho:** Entre 800px y 2000px
- **Formato:** JPG o PNG
- **Tamaño de archivo:** Hasta 10MB (se comprimirá automáticamente)

### Calidad
- Usa fotos de buena calidad
- Asegúrate de que las fotos representen bien el hotel
- Evita fotos borrosas o muy oscuras

### Cantidad
- **Imagen Principal:** 1 foto (la mejor)
- **Galería:** Hasta 10 fotos adicionales

---

## 🚀 Flujo Completo

```
1. Tú subes fotos en dashboard.html
   ↓
2. Las fotos se guardan en la base de datos
   (localStorage o Supabase)
   ↓
3. index.html carga los hoteles automáticamente
   ↓
4. Las fotos se muestran en la página web
   ↓
5. Los visitantes ven las fotos reales de tus hoteles
```

---

## ✅ Verificar que Funcionó

### En el Dashboard
1. Edita un hotel
2. Verifica que las fotos aparezcan en el preview
3. Guarda el hotel
4. Abre el hotel nuevamente
5. Las fotos deberían seguir ahí

### En index.html
1. Abre `index.html` en tu navegador
2. Los hoteles deberían aparecer con sus fotos reales
3. Si no aparecen, verifica la consola del navegador (F12)

---

## 🆘 Solución de Problemas

### "Las fotos no aparecen en index.html"
- **Verifica:** Abre la consola del navegador (F12)
- **Busca:** Errores en la consola
- **Solución:** Asegúrate de que los hoteles estén guardados en `localStorage` o Supabase

### "Las fotos se ven muy grandes"
- Las fotos se comprimen automáticamente
- Si aún son muy grandes, redúcelas antes de subirlas

### "No puedo subir fotos"
- Verifica que el archivo sea menor a 10MB
- Verifica que sea un formato de imagen válido (JPG, PNG, etc.)
- Intenta con otra foto

### "Las fotos no se guardan"
- Verifica que hayas hecho clic en "Guardar Cambios"
- Revisa la consola del navegador para errores
- Asegúrate de que el navegador permita localStorage

---

## 📝 Resumen

✅ **Subes fotos reales** en el dashboard  
✅ **Se guardan** en la base de datos del hotel  
✅ **Se muestran automáticamente** en index.html  
✅ **Los visitantes** ven las fotos reales de tus hoteles  

**¡Es así de simple!** 🎉

---

## 🔄 Sincronización

### Entre Dashboard e Index.html

- **Dashboard** → Guarda hoteles en `localStorage` o Supabase
- **Index.html** → Lee hoteles desde `localStorage` o Supabase
- **Resultado** → Las fotos aparecen automáticamente en ambos lugares

### Si Usas Supabase

- Los hoteles se sincronizan en la nube
- Puedes acceder desde cualquier dispositivo
- Las fotos están disponibles siempre

### Si Usas Solo localStorage

- Los hoteles se guardan en el navegador
- Necesitas usar el mismo navegador
- Las fotos están disponibles localmente

---

## 🎉 ¡Listo!

Ahora puedes:
1. ✅ Subir fotos reales de tus hoteles
2. ✅ Guardarlas en la ficha del hotel
3. ✅ Verlas automáticamente en tu página web
4. ✅ Mostrarlas a tus clientes

**¡Tu sistema está completo y funcionando!** 🚀

