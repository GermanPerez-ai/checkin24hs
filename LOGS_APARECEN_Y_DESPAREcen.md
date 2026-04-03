# ⚡ Logs Aparecen y Desaparecen - Solución

## 🔍 Problema

Los logs aparecen rápidamente y luego desaparecen. Esto significa:
- ✅ El servicio **SÍ se está iniciando**
- ❌ El proceso **se detiene inmediatamente** por un error
- ⚠️ Hay un **error que causa que el proceso falle**

## 🎯 Soluciones

### Solución 1: Refrescar los Logs Rápidamente

1. **Haz clic en el botón REFRESH (🔄)** en la esquina superior derecha de la sección "Registros"
2. **Esto debería mostrar los últimos logs**, incluso si el proceso se detuvo
3. **Copia todo lo que veas** antes de que desaparezca

### Solución 2: Reiniciar y Capturar los Logs

1. **Haz clic en el botón REFRESH/RESTART (🔄)** (flecha circular) en la parte superior
2. **Inmediatamente después**, ve a la sección "Registros"
3. **Observa los logs mientras aparecen**
4. **Toma una captura de pantalla** o **copia el texto** antes de que desaparezca

### Solución 3: Ver Logs de Implementación

Los logs de implementación pueden tener más información:

1. **Haz clic en "Implementaciones"** (menú lateral)
2. **Haz clic en "Ver"** en la implementación más reciente
3. **Desplázate hasta el final** de los logs
4. **Busca errores** o mensajes de advertencia
5. **Comparte los últimos 30-40 líneas**

### Solución 4: Verificar el Estado del Servicio

1. **Ve a "Resumen"**
2. **Observa el color del punto** del servicio `whatsapp-1`:
   - 🟢 **Verde**: Está corriendo (pero se detiene)
   - 🟡 **Amarillo**: Está iniciando (pero falla)
   - 🔴 **Rojo**: Hay un error

## 🔍 Errores Comunes que Causan Esto

### Error 1: Puerto en Uso
```
Error: listen EADDRINUSE: address already in use :::3001
```
**Solución**: Cambiar el puerto en las variables de entorno o detener el proceso que lo está usando.

### Error 2: Módulo No Encontrado
```
Error: Cannot find module 'whatsapp-web.js'
```
**Solución**: Re-implementar el servicio para reinstalar dependencias.

### Error 3: Variable de Entorno Faltante
```
Error: SUPABASE_URL is not defined
```
**Solución**: Verificar que todas las variables de entorno estén guardadas.

### Error 4: Error de Permisos
```
Error: EACCES: permission denied
```
**Solución**: Verificar permisos del directorio.

## 📋 Pasos Recomendados

1. **Haz clic en REFRESH (🔄)** en la sección "Registros"
2. **Copia todo el texto** que aparezca (aunque sea poco)
3. **Haz clic en REFRESH/RESTART (🔄)** en la parte superior
4. **Inmediatamente ve a "Registros"** y observa los logs
5. **Toma una captura de pantalla** o **copia el texto** completo
6. **Comparte lo que veas** (especialmente cualquier mensaje de error)

## 💡 Consejo

Si los logs desaparecen muy rápido:
- **Haz clic en REFRESH (🔄)** varias veces
- **Toma una captura de pantalla** mientras aparecen
- **Copia el texto** antes de que desaparezca

## 🎯 Acción Inmediata

1. **Haz clic en REFRESH (🔄)** en "Registros"
2. **Copia todo el texto** que veas
3. **Haz clic en REFRESH/RESTART (🔄)** en la parte superior
4. **Inmediatamente observa "Registros"** mientras aparecen los logs
5. **Toma una captura de pantalla** o **copia el texto**
6. **Comparte lo que veas** (especialmente errores)

Con el texto de los logs podré identificar exactamente qué está fallando.

