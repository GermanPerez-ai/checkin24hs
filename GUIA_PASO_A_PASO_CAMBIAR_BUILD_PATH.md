# 📋 Guía Paso a Paso: Cambiar Build Path en EasyPanel

## 🎯 Objetivo

Cambiar la configuración para que el Dockerfile funcione con `COPY . /usr/share/nginx/html/` (versión anterior).

---

## ✅ Paso 1: Acceder a EasyPanel

1. Abre tu navegador
2. Ve a tu panel de EasyPanel (ej: `http://72.61.58.240:3000` o la URL que uses)
3. Inicia sesión si es necesario

---

## ✅ Paso 2: Ir al Servicio Dashboard

1. En el menú lateral izquierdo, busca la sección **"SERVICIOS"**
2. Haz clic en **"dashboard"** (debería tener un punto amarillo o verde)

---

## ✅ Paso 3: Ir a la Pestaña "Fuente"

1. En la parte superior de la página, busca las pestañas:
   - `Fuente` (o `Source`)
   - `Variables`
   - `Puertos`
   - `Logs`
   - etc.

2. Haz clic en la pestaña **"Fuente"** o **"Source"**

---

## ✅ Paso 4: Cambiar "Ruta de compilación"

1. Desplázate hacia abajo hasta encontrar la sección **"Fuente"**
2. Busca el campo **"Ruta de compilación"** o **"Build Path"**
3. Actualmente debería decir: `/`
4. **Cámbialo a**: `/deploy`
5. ⚠️ **NO hagas clic en "Guardar" todavía** (espera al Paso 6)

---

## ✅ Paso 5: Cambiar "Archivo" en Compilación

1. Desplázate más abajo hasta la sección **"Compilación"** o **"Build"**
2. Verifica que el tipo sea **"Dockerfile"** (debería estar seleccionado)
3. Busca el campo **"Archivo"** o **"File"**
4. Actualmente debería decir: `deploy/Dockerfile`
5. **Cámbialo a**: `Dockerfile` (sin `deploy/`)
6. ⚠️ **NO hagas clic en "Guardar" todavía**

---

## ✅ Paso 6: Guardar Cambios

1. En la sección **"Fuente"**, haz clic en el botón verde **"Guardar"** o **"Save"**
2. En la sección **"Compilación"**, haz clic en el botón verde **"Guardar"** o **"Save"**
3. Espera a que aparezca un mensaje de confirmación (puede decir "Configuración guardada" o similar)

---

## ✅ Paso 7: Verificar Configuración

Antes de hacer deploy, verifica que:

**Fuente:**
- ✅ Propietario: `GermanPerez-ai`
- ✅ Repositorio: `checkin24hs`
- ✅ Rama: `main`
- ✅ **Ruta de compilación: `/deploy`** ← IMPORTANTE

**Compilación:**
- ✅ Tipo: `Dockerfile`
- ✅ **Archivo: `Dockerfile`** ← IMPORTANTE (sin `deploy/`)

---

## ✅ Paso 8: Hacer Redeploy

1. En la parte superior de la página, busca el botón verde grande **"Implementar"** o **"Deploy"**
2. Haz clic en **"Implementar"** o **"Deploy"**
3. Espera 2-3 minutos a que termine la construcción
4. Verás el progreso en la sección "Historial de implementaciones"

---

## ✅ Paso 9: Verificar que Funcionó

1. Espera a que el servicio esté en **verde** (punto verde en el menú lateral)
2. Abre en tu navegador: `https://dashboard.checkin24hs.com/`
3. El dashboard debería cargar sin error 404

---

## 🔍 Si Algo Sale Mal

### Error: "node: not found"
- ✅ Esto es normal si aparece durante el build, pero debería desaparecer
- Si persiste, verifica que no haya comandos de build configurados

### El servicio sigue en amarillo
- Espera 2-3 minutos más
- Revisa los logs en la pestaña "Logs"

### Sigue apareciendo 404
- Verifica que el Build Path sea exactamente `/deploy` (con la barra inicial)
- Verifica que el Archivo sea exactamente `Dockerfile` (sin `deploy/`)

---

## 📝 Resumen de Cambios

**ANTES:**
- Ruta de compilación: `/`
- Archivo: `deploy/Dockerfile`
- Dockerfile: `COPY deploy/ /usr/share/nginx/html/`

**DESPUÉS:**
- Ruta de compilación: `/deploy` ✅
- Archivo: `Dockerfile` ✅
- Dockerfile: `COPY . /usr/share/nginx/html/` ✅

---

¡Listo! Sigue estos pasos y el dashboard debería funcionar correctamente.
