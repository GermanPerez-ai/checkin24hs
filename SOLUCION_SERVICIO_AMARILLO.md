# 🔧 Solución: Servicio en Amarillo (No Cambia a Verde)

## 🎯 Problema

El servicio está en amarillo, lo que significa que:
- Está en proceso de construcción
- O hay un error en la construcción
- O está iniciando

## ✅ Pasos para Diagnosticar

### Paso 1: Ver los Logs del Servicio

1. Haz clic en el servicio que está en amarillo
2. Busca la pestaña **"Registros"** o **"Logs"** (en el menú lateral izquierdo o en la parte superior)
3. Haz clic en **"Registros"** o **"Logs"**
4. Verás los logs de construcción/inicio del servicio

### Paso 2: Verificar qué Muestran los Logs

**Si ves logs de construcción:**
- El servicio está construyéndose, espera unos minutos
- Busca mensajes como "building", "pulling", "copying files"

**Si ves errores:**
- Comparte el error que aparece
- Los errores comunes son:
  - Error en el Dockerfile
  - No encuentra archivos
  - Error de permisos

**Si ves logs de Nginx iniciando:**
- El servicio está iniciando correctamente
- Espera a que termine de iniciar

### Paso 3: Verificar la Configuración

Mientras esperas, verifica:

1. **Pestaña "Fuente"**:
   - Build Path: `/deploy`
   - Dockerfile Path: `Dockerfile`

2. **Pestaña "Puertos"**:
   - Puerto interno: `80`

3. **Pestaña "Entorno"**:
   - `PORT=80`

### Paso 4: Si Hay Errores

Si ves errores en los logs, comparte:
- El mensaje de error completo
- En qué línea del Dockerfile falla (si aplica)
- Qué archivos no encuentra (si aplica)

---

## 🔍 Errores Comunes

### Error: "Dockerfile not found"
- **Solución**: Verifica que el Dockerfile Path sea correcto (`Dockerfile` o `deploy/Dockerfile`)

### Error: "Build Path not found"
- **Solución**: Verifica que el Build Path sea `/deploy` y que exista esa carpeta en tu repositorio

### Error: "nginx: not found" o similar
- **Solución**: El Dockerfile está correcto, el problema puede ser otro

### Error: "COPY failed"
- **Solución**: Verifica que los archivos existan en el Build Path

---

**Ve a la pestaña "Registros" o "Logs" y comparte qué ves allí. ¿Hay errores o solo está construyéndose?**
