# 🚨 Solución: Servidor HTTP No Inicia (404 en todos los endpoints)

## ⚠️ Problema Identificado

- ❌ Todos los endpoints dan 404 (`/api/qr`, `/api/health`, `/api/status`)
- ❌ Memoria muestra "NaN B" (servicio no está corriendo realmente)
- ❌ Solo aparece "Connecting to websocket..." en logs
- ❌ NO aparece `✅ Servidor iniciado en puerto 3001`

**Diagnóstico:** El servidor HTTP (Express) no está iniciando. El código está intentando conectar a WhatsApp pero el servidor HTTP nunca se inició.

---

## 🔍 Causas Posibles

### 1. Error al Cargar `link-preview-js`
Si `link-preview-js` no se instaló correctamente o hay un error al requerirlo, el servidor puede fallar silenciosamente.

### 2. Error en el Código que Impide el Inicio
Puede haber un error de sintaxis o un error al ejecutar que impide que `start()` se ejecute.

### 3. Error Silencioso
El error puede estar ocurriendo pero no aparecer en los logs visibles.

---

## ✅ Soluciones

### Solución 1: Verificar Logs Completos con Errores

En EasyPanel → Servicios → `whatsapp` → **Logs**:

1. **Desplázate COMPLETAMENTE hacia arriba** (hasta el inicio)
2. Busca cualquier mensaje que empiece con:
   - `❌ Error`
   - `Error:`
   - `Cannot find module`
   - `MODULE_NOT_FOUND`
   - `SyntaxError`
   - `ReferenceError`

3. **Comparte esos errores** para diagnosticar

### Solución 2: Verificar que link-preview-js Esté Instalado

El error puede ser que `link-preview-js` no se instaló en el contenedor Docker.

**En EasyPanel:**
1. Ve a Servicios → `whatsapp` → **Logs**
2. Busca en los logs del despliegue (no los logs de runtime)
3. Busca mensajes como:
   - `npm install`
   - `added X packages`
   - `link-preview-js`

Si NO ves que se instaló `link-preview-js`, necesitas hacer un **rebuild completo**.

### Solución 3: Hacer Rebuild Completo

1. En EasyPanel → Servicios → `whatsapp`
2. Haz clic en **"Rebuild"** (no solo "Restart")
3. Esto reinstalará todas las dependencias incluyendo `link-preview-js`
4. Espera a que termine (puede tardar 3-5 minutos)
5. Revisa los logs del despliegue para ver si hay errores

### Solución 4: Verificar Logs del Despliegue

En EasyPanel → Servicios → `whatsapp` → **Implementaciones**:

1. Haz clic en la implementación más reciente
2. Revisa los logs de **compilación/construcción**
3. Busca errores durante `npm install` o al iniciar el servidor

### Solución 5: Temporalmente Deshabilitar link-preview-js

Si el problema es `link-preview-js`, podemos temporalmente comentar su uso para que el servidor inicie:

1. Comentar la línea que requiere `link-preview-js`
2. Comentar las funciones que lo usan
3. Hacer commit y push
4. Hacer redeploy
5. Verificar que el servidor inicie
6. Luego investigar el problema con `link-preview-js`

---

## 🧪 Diagnóstico Rápido

### Test 1: Verificar Logs desde el Inicio
```
En EasyPanel → Logs → Desplázate hacia arriba
```
**Busca:** Cualquier mensaje de error ANTES de "Connecting to websocket..."

### Test 2: Verificar Instalación de Dependencias
```
En EasyPanel → Implementaciones → Última implementación → Ver logs
```
**Busca:** `npm install` y verifica que `link-preview-js` se instaló

### Test 3: Verificar que el Código se Ejecuta
Si ves "Connecting to websocket..." significa que el código está ejecutándose hasta cierto punto, pero algo falla antes de que `server.listen()` se ejecute.

---

## 📋 Checklist de Verificación

- [ ] Revisé los logs completos desde el inicio
- [ ] Busqué mensajes de error (❌, Error:, Cannot find module)
- [ ] Verifiqué los logs del despliegue (npm install)
- [ ] Hice un Rebuild completo (no solo Restart)
- [ ] El servicio muestra estado "Running" pero no responde

---

## 🆘 Si Nada Funciona

1. **Comparte los logs completos** desde el inicio (todos los mensajes)
2. **Comparte los logs del despliegue** (especialmente la parte de `npm install`)
3. **Verifica si hay errores** que no estén visibles en la interfaz

---

## 💡 Próximos Pasos Inmediatos

1. **Desplázate hacia arriba en los logs** y busca errores
2. **Haz un Rebuild completo** (no solo Restart)
3. **Revisa los logs del despliegue** para ver si `link-preview-js` se instaló

**¿Qué ves cuando desplazas hacia arriba en los logs? ¿Hay algún mensaje de error?**
