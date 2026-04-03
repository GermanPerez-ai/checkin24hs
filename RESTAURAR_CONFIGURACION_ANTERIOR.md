# 🔄 Restaurar Configuración Anterior que Funcionaba

## 🎯 Configuración Anterior que Funcionaba

- ✅ **Tipo**: Node.js (no Nginx)
- ✅ **Puerto**: 3000
- ✅ **Comando**: `node server.js`
- ✅ **Variables**: `PORT=3000`, `NODE_ENV=production`
- ✅ **Ruta**: `/` (raíz del repositorio, donde está `server.js`)

## ✅ Pasos para Restaurar

### Paso 1: Eliminar el Servicio Actual (Nginx)

1. En EasyPanel, ve al servicio `dashboard`
2. Haz clic en el icono de **"Detener"** (cuadrado)
3. Espera a que se detenga
4. Haz clic en el icono de **"Eliminar"** (basura)
5. Confirma la eliminación

### Paso 2: Crear Nuevo Servicio Node.js

1. Haz clic en **"+ Servicio"** (arriba a la derecha)
2. En el modal:
   - **Seleccionar proyecto**: `checkin24hs`
   - **Nombre del servicio**: `dashboard`
   - **Tipo**: Selecciona **"Node.js"** o **"Aplicación"**
   - Haz clic en **"Crear"**

### Paso 3: Configurar la Fuente

1. Ve a la pestaña **"Fuente"**
2. Haz clic en la pestaña **"Github"**
3. Configura:
   - **Propietario**: `GermanPerez-ai` (o el tuyo)
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main` (o la que tengas)
   - **Build Path** o **Ruta de compilación**: `/` (raíz, donde está `server.js`)
   - **Dockerfile Path**: Déjalo vacío o elimínalo (no necesitamos Dockerfile para Node.js)

### Paso 4: Configurar Variables de Entorno

1. Ve a la pestaña **"Entorno"**
2. Agrega:
   ```
   PORT=3000
   NODE_ENV=production
   ```
3. Haz clic en **"Guardar"**

### Paso 5: Configurar el Puerto

1. Ve a la pestaña **"Puertos"**
2. Agrega un puerto:
   - **Puerto interno**: `3000`
   - **Puerto externo**: Puede estar vacío o ser `3000`

### Paso 6: Configurar el Comando de Inicio

1. Busca una sección **"Comando"** o **"Start Command"** o **"Comando de inicio"**
   - Puede estar en "Fuente", "Entorno", o en una sección separada
2. Configura:
   ```
   node server.js
   ```
   O si no hay campo, EasyPanel puede detectarlo automáticamente

### Paso 7: Implementar

1. Haz clic en el botón verde **"Implementar"**
2. Espera a que se construya e inicie (puede tardar varios minutos)
3. Verifica los logs - deben mostrar:
   ```
   🚀 Servidor iniciado en http://0.0.0.0:3000
   ```
   **NO** deben mostrar logs de Nginx

### Paso 8: Configurar el Dominio

1. Ve a la pestaña **"Dominios"**
2. Haz clic en **"Agregar dominio"**
3. Ingresa: `dashboard.checkin24hs.com`
4. **IMPORTANTE**: Verifica que el destino sea:
   - `http://checkin24hs_dashboard:3000/` (con puerto 3000, no 80)
5. Si el destino tiene puerto 80, edítalo para que sea 3000

### Paso 9: Probar

1. Espera 30-60 segundos después de configurar el dominio
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. **¿Funciona?**

---

## 🔍 Verificación

Después de implementar, verifica los logs:

- ✅ Deben mostrar: `🚀 Servidor iniciado en http://0.0.0.0:3000`
- ❌ NO deben mostrar: `nginx/1.29.4` o `start worker processes`

---

## ⚠️ Si No Encuentras "Comando de Inicio"

Si EasyPanel no tiene un campo para "Comando de inicio":

1. Verifica si hay un archivo `package.json` en la raíz del repositorio
2. O verifica si EasyPanel detecta automáticamente `server.js`
3. Si no, puede que necesites crear un `Dockerfile` para Node.js (pero eso es más complejo)

---

**Sigue estos pasos y dime en qué paso estás o si encuentras algún problema.**
