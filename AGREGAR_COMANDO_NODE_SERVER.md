# ✅ Agregar Comando "node server.js"

## 🎯 Configuración

Sí, **debes agregar** `node server.js` en el campo **"Comando"**.

## ✅ Pasos

### Paso 1: Agregar el Comando

1. En el campo **"Comando"** (que está vacío)
2. Escribe: `node server.js`
3. **NO** agregues nada más, solo `node server.js`

### Paso 2: Guardar

1. Haz clic en el botón verde **"Guardar"** (en la parte inferior)
2. Espera a que se guarde la configuración

### Paso 3: Verificar

Después de guardar:
1. Ve a la pestaña **"Registros"** o **"Logs"**
2. Verifica que los logs muestren:
   - `🚀 Servidor iniciado en http://0.0.0.0:3000`
   - **NO** deben mostrar errores como "command not found" o similar

### Paso 4: Si el Servicio se Reinicia

Después de guardar el comando, el servicio puede reiniciarse automáticamente. Espera 1-2 minutos y verifica los logs.

---

## 🔍 Por Qué es Importante

El campo "Comando" le dice al servicio qué ejecutar cuando inicia. Sin este comando:
- El servicio puede no saber qué hacer
- O puede intentar ejecutar algo por defecto que no funciona
- O puede quedarse en un estado de espera

Con `node server.js`:
- El servicio ejecutará Node.js con el archivo `server.js`
- El servidor se iniciará correctamente en el puerto 3000

---

**Agrega `node server.js` en el campo "Comando" y haz clic en "Guardar". Luego verifica los logs para confirmar que el servidor se inicia correctamente.**
