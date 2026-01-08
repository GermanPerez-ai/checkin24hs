# 🔧 Solución Paso a Paso: Corregir Puerto y Error de Chromium

## 🎯 Problemas a Corregir

1. ❌ **Puerto incorrecto**: El servicio WhatsApp está usando puerto 80 en lugar de 3001
2. ❌ **Error de Chromium**: Faltan dependencias (`libnss3.so`)

---

## ⚠️ IMPORTANTE: Sobre el Puerto 80

**Webmail SÍ puede usar puerto 80** - Esto es **NORMAL y CORRECTO**:
- ✅ **Webmail (Roundcube)** usa puerto **80 INTERNO** (dentro del contenedor)
- ✅ Esto es el comportamiento estándar de Apache/Roundcube
- ✅ **NO hay conflicto** porque webmail y WhatsApp son servicios diferentes en contenedores diferentes

**WhatsApp NO debe usar puerto 80**:
- ❌ **WhatsApp** debe usar puerto **3001, 3002, 3003, o 3004**
- ❌ Si WhatsApp muestra `puerto 80`, está **MAL CONFIGURADO**
- ✅ **Cada servicio tiene su propio contenedor**, así que no hay conflicto de puertos

**Resumen**:
- Webmail puerto 80 = ✅ CORRECTO
- WhatsApp puerto 80 = ❌ INCORRECTO (debe ser 3001-3004)

---

## 📋 PASO 1: Corregir el Puerto en EasyPanel

### 1.1. Abrir EasyPanel

1. Abre tu navegador
2. Ve a **EasyPanel** (tu URL de EasyPanel)
3. Inicia sesión si es necesario

### 1.2. Encontrar el Servicio WhatsApp

1. En el panel principal, busca el servicio llamado:
   - `checkin24hs_whatsapp`
   - O simplemente `whatsapp`
   - O el nombre que le hayas dado

2. **Haz clic en el servicio** para abrir su configuración

### 1.3. Ir a Variables de Entorno

1. En la página del servicio, busca una de estas secciones:
   - **"Environment Variables"** o **"Variables de Entorno"**
   - **"Env"** o **"Environment"**
   - Puede estar en una pestaña o en el menú lateral

2. **Haz clic** en esa sección para abrirla

### 1.4. Verificar/Corregir la Variable PORT

1. **Busca** la variable llamada `PORT` en la lista

2. **Si existe**:
   - Haz clic en el **valor** (probablemente dice `80`)
   - **Cámbialo a**: `3001`
   - Haz clic en **"Save"** o **"Guardar"** en esa variable

3. **Si NO existe**:
   - Haz clic en **"Add Variable"** o **"Agregar Variable"** o el botón **"+"**
   - **Nombre**: `PORT`
   - **Valor**: `3001`
   - Haz clic en **"Save"** o **"Guardar"**

### 1.5. Verificar INSTANCE_NUMBER

1. **Busca** la variable `INSTANCE_NUMBER`

2. **Si existe**:
   - Verifica que el valor sea `1`
   - Si no, cámbialo a `1`

3. **Si NO existe**:
   - Haz clic en **"Add Variable"** o **"Agregar Variable"**
   - **Nombre**: `INSTANCE_NUMBER`
   - **Valor**: `1`
   - Haz clic en **"Save"**

### 1.6. Verificar Otras Variables Importantes

Asegúrate de que estas variables estén configuradas:

```
PORT=3001
INSTANCE_NUMBER=1
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

### 1.7. Guardar Cambios

1. **Busca el botón "Save"** o **"Guardar"** en la parte superior o inferior de la página
2. Haz clic en **"Save"**
3. Espera a que se guarden los cambios (puede tardar unos segundos)

---

## 📋 PASO 2: Reconstruir el Servicio (Para Corregir Chromium)

> ⚠️ **IMPORTANTE**: Si ya corregiste el puerto pero sigue apareciendo el error de Chromium, necesitas **forzar la reconstrucción** del servicio.  
> 📖 **Guía detallada**: [FORZAR_RECONSTRUCCION_CHROMIUM.md](./FORZAR_RECONSTRUCCION_CHROMIUM.md)

### 2.1. Ir a la Sección de Build/Deploy

1. En la página del servicio, busca una de estas opciones:
   - **"Build"** o **"Construir"**
   - **"Deploy"** o **"Desplegar"**
   - **"Rebuild"** o **"Reconstruir"**
   - Puede estar en una pestaña o como un botón

2. **Haz clic** en esa sección o botón

### 2.2. Opción A: Botón "Rebuild" o "Redeploy"

Si ves un botón que dice:
- **"Rebuild"** o **"Reconstruir"**
- **"Redeploy"** o **"Redesplegar"**
- **"Deploy"** o **"Desplegar"**

1. **Haz clic** en ese botón
2. **Confirma** si te pregunta algo
3. **Espera** a que termine (puede tardar 3-5 minutos)

### 2.3. Opción B: Forzar Reconstrucción

Si no encuentras "Rebuild", puedes:

1. **Detener el servicio**:
   - Busca el botón **"Stop"** o **"Detener"**
   - Haz clic en **"Stop"**
   - Espera a que se detenga (estado cambia a rojo o amarillo)

2. **Iniciar el servicio**:
   - Busca el botón **"Start"** o **"Iniciar"** o **"Deploy"**
   - Haz clic en **"Start"**
   - Espera a que se inicie (estado cambia a verde)

### 2.4. Verificar que se Está Reconstruyendo

1. **Ve a la pestaña "Logs"** o **"Registros"**
2. Deberías ver mensajes como:
   ```
   Building...
   Pulling image...
   Installing dependencies...
   ```
3. **Espera** hasta que veas:
   ```
   🚀 Iniciando servidor WhatsApp...
   ✅ Dependencias cargadas
   ✅ Cliente de Supabase inicializado
   📡 Servidor corriendo en puerto 3001  ← ¡Debe decir 3001, NO 80!
   ```

---

## 📋 PASO 3: Verificar que Funciona Correctamente

### 3.1. Verificar el Estado del Servicio

1. En la lista de servicios, el servicio debe estar en **verde** (Running)
2. Si está en **amarillo** o **rojo**, espera unos minutos más
3. Si sigue en amarillo/rojo, ve al **Paso 4: Solución de Problemas**

### 3.2. Verificar los Logs

1. **Haz clic en el servicio**
2. Ve a la pestaña **"Logs"** o **"Registros"**
3. **Busca** estos mensajes (deben aparecer):

   ✅ **Correcto**:
   ```
   🚀 Iniciando servidor WhatsApp...
   📦 Cargando dependencias...
   ✅ Dependencias cargadas
   ✅ Cliente de Supabase inicializado
   📁 Usando directorio de sesión: .wwebjs_auth_1 (Instancia 1)
   📡 Servidor corriendo en puerto 3001  ← ¡DEBE decir 3001!
   🌐 Panel: http://localhost:3001
   ```

   ❌ **Incorrecto** (si ves esto, el puerto sigue mal):
   ```
   📡 Servidor corriendo en puerto 80  ← ¡MAL! Debe ser 3001
   ```

   ❌ **Error de Chromium** (si ves esto, falta reconstruir):
   ```
   Error: Failed to launch the browser process!
   libnss3.so: cannot open shared object file
   ```

### 3.3. Probar el Endpoint

1. **Abre una nueva pestaña** en tu navegador
2. **Ve a**: `http://72.61.58.240:3001/api/status`
3. **Deberías ver** un JSON con información del estado:
   ```json
   {
     "status": "running",
     "instance": 1,
     "port": 3001
   }
   ```

   Si ves un error o "Connection refused", el servicio no está corriendo correctamente.

---

## 🆘 PASO 4: Solución de Problemas

### ❌ El servicio sigue mostrando puerto 80

**Solución**:
1. **Verifica** que guardaste los cambios en las variables de entorno
2. **Reinicia** el servicio (Stop → Start)
3. **Espera** 1-2 minutos
4. **Verifica los logs** nuevamente

### ❌ Sigue apareciendo el error de Chromium

**Solución**:
1. **Asegúrate** de que hiciste "Rebuild" o "Redeploy" (no solo "Restart")
2. **Espera** 3-5 minutos para que termine la reconstrucción
3. **Verifica los logs** - deberías ver que se están descargando dependencias
4. Si el error persiste, ve al **Paso 5: Reconstrucción Manual**

### ❌ El servicio no inicia (se queda en amarillo/rojo)

**Solución**:
1. **Ve a "Logs"** y busca el último error
2. **Copia el error** completo
3. **Verifica**:
   - ¿Dice "Puerto ya en uso"? → Otro servicio está usando el puerto 3001
   - ¿Dice "Cannot find module"? → Falta instalar dependencias
   - ¿Dice "Permission denied"? → Problema de permisos

### ❌ No encuentro las opciones en EasyPanel

**Solución**:
1. **Busca** en diferentes pestañas:
   - "Configuration" o "Configuración"
   - "Settings" o "Ajustes"
   - "Environment" o "Entorno"
   - "Variables" o "Variables de Entorno"

2. **Si usas EasyPanel web**, las opciones pueden estar en:
   - Menú lateral izquierdo
   - Pestañas superiores
   - Menú de tres puntos (⋮) en el servicio

---

## 📋 PASO 5: Reconstrucción Manual (Si es Necesario)

Si el "Rebuild" automático no funciona:

### 5.1. Detener el Servicio

1. **Haz clic en el servicio**
2. **Busca "Stop"** o **"Detener"**
3. **Haz clic en "Stop"**
4. **Espera** a que se detenga completamente

### 5.2. Eliminar y Recrear (Última Opción)

⚠️ **ADVERTENCIA**: Esto eliminará el servicio y tendrás que recrearlo.

1. **Haz clic en el servicio**
2. **Busca "Delete"** o **"Eliminar"** o **"Remove"**
3. **Confirma** la eliminación
4. **Crea el servicio nuevamente** siguiendo la guía principal:
   - [GUIA_PASO_A_PASO_WHATSAPP_EASYPANEL.md](./GUIA_PASO_A_PASO_WHATSAPP_EASYPANEL.md)

---

## ✅ Checklist Final

Antes de considerar que está corregido:

- [ ] Variable `PORT=3001` está configurada en EasyPanel
- [ ] Variable `INSTANCE_NUMBER=1` está configurada
- [ ] El servicio está en **verde** (Running)
- [ ] Los logs muestran: `📡 Servidor corriendo en puerto 3001` (NO 80)
- [ ] NO aparece el error de `libnss3.so`
- [ ] Puedo acceder a `http://72.61.58.240:3001/api/status` y responde

---

## 🎉 ¡Listo!

Si todos los checkboxes están marcados, el servicio está funcionando correctamente.

**Próximo paso**: Crear los otros 3 servicios (whatsapp2, whatsapp3, whatsapp4) siguiendo la guía principal, pero usando:
- `PORT=3002` para whatsapp2
- `PORT=3003` para whatsapp3
- `PORT=3004` para whatsapp4

---

## 📞 ¿Necesitas Ayuda?

Si después de seguir todos los pasos el problema persiste:

1. **Copia los logs completos** del servicio
2. **Toma una captura de pantalla** de las variables de entorno
3. **Comparte** esta información para diagnosticar el problema

