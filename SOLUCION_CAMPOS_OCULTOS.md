# 🔧 Solución: Campos de Configuración No Visibles

## 🎯 El Problema

Los campos de configuración (Proveedor, API Key, Modelo) están ocultos por defecto y solo aparecen cuando:
1. El checkbox "Habilitar respuestas con IA" está marcado
2. Y se ejecuta la función JavaScript que los muestra

## ✅ Solución Paso a Paso

### Opción 1: Activar el Checkbox (Recomendado)

1. **Desmarca el checkbox** "Habilitar respuestas con IA"
   - Haz clic en el checkbox para desmarcarlo
   - Los campos desaparecerán (si estaban visibles)

2. **Vuelve a marcar el checkbox**
   - Haz clic nuevamente en el checkbox para marcarlo
   - **¡Los campos deberían aparecer ahora!**

3. **Deberías ver:**
   - Campo "Proveedor" (dropdown)
   - Campo "API Key" (campo de texto)
   - Campo "Modelo" (campo de texto)
   - Botones "Guardar" y "Probar Conexión"

### Opción 2: Recargar la Página

Si la Opción 1 no funciona:

1. **Guarda cualquier cambio** que hayas hecho (si hay algo)
2. **Recarga la página:**
   - Presiona `F5` o `Ctrl + R`
   - O haz clic en el botón de recargar del navegador

3. **Vuelve a la pestaña "IA"**
4. **Marca el checkbox** "Habilitar respuestas con IA"
5. Los campos deberían aparecer

### Opción 3: Abrir la Consola del Navegador

Si las opciones anteriores no funcionan:

1. **Presiona `F12`** para abrir las herramientas de desarrollador
2. **Ve a la pestaña "Console"**
3. **Ejecuta este comando:**
   ```javascript
   document.getElementById('ai-config-fields').style.display = 'block';
   ```
4. Presiona Enter
5. Los campos deberían aparecer inmediatamente

---

## 📋 Una Vez que Veas los Campos

Cuando los campos aparezcan, configura:

1. **Proveedor:** Selecciona "Google Gemini - GRATIS"
2. **API Key:** Pega tu API Key de Gemini (empieza con `AIza...`)
3. **Modelo:** Debería aparecer automáticamente "gemini-2.5-flash" (o puedes cambiarlo)
4. **Haz clic en "Guardar"**
5. **Haz clic en "Probar Conexión"** para verificar

---

## 🆘 Si Nada Funciona

Si después de intentar todo lo anterior aún no ves los campos:

1. **Verifica que estás en la pestaña correcta:**
   - Debe decir "IA" en la parte superior
   - Debe tener un icono de robot 🤖

2. **Verifica que el JavaScript esté cargado:**
   - Presiona `F12`
   - Ve a "Console"
   - Busca errores en rojo
   - Si hay errores, recarga la página

3. **Intenta en otro navegador:**
   - Chrome, Firefox, Edge, etc.

---

**¡Prueba primero la Opción 1 (desmarcar y volver a marcar el checkbox)! Es la más simple y suele funcionar.** 🚀


