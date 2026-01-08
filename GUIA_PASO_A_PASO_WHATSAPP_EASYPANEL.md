# 📱 Guía Paso a Paso: Configurar WhatsApp en EasyPanel

## 🎯 Objetivo

Configurar 4 servicios de WhatsApp en EasyPanel para que se conecten automáticamente con Flor IA y respondan mensajes.

---

## ⚠️ ¿Tienes Problemas con el Puerto o Chromium?

Si tu servicio ya está creado pero:
- ❌ Muestra `📡 Servidor corriendo en puerto 80` (debería ser 3001)
- ❌ Aparece error `libnss3.so: cannot open shared object file`

**Ve primero a**: [SOLUCION_PASO_A_PASO_PUERTO_Y_CHROMIUM.md](./SOLUCION_PASO_A_PASO_PUERTO_Y_CHROMIUM.md)

---

## 📋 ANTES DE EMPEZAR

### ✅ Verificaciones Previas

1. **¿Tienes acceso a EasyPanel?** → https://easypanel.io
2. **¿Tienes un proyecto creado?** → Si no, créalo primero
3. **¿Los archivos están en GitHub?** → ✅ Ya están (acabamos de subirlos)

---

## ⚠️ ANTES DE EMPEZAR: Verificar Puertos

**IMPORTANTE**: Antes de crear los servicios, verifica que los puertos 3001, 3002, 3003 y 3004 estén disponibles.

### Verificación Rápida

1. **En EasyPanel**, revisa los servicios existentes
2. **Verifica** que ningún servicio esté usando los puertos 3001-3004
3. **Si hay conflictos**, detén el servicio o usa otros puertos

📖 **Guía completa**: Ver [VERIFICAR_PUERTOS_WHATSAPP.md](./VERIFICAR_PUERTOS_WHATSAPP.md)

---

## 🚀 PASO 1: Crear el Primer Servicio (whatsapp - Instancia 1)

### 1.1. Ir a EasyPanel

1. Abre tu navegador y ve a **EasyPanel**
2. Inicia sesión con tu cuenta
3. Selecciona tu **proyecto** (o créalo si no existe)

### 1.2. Crear Nuevo Servicio

1. Haz clic en el botón **"+"** o **"New Service"** o **"Crear Servicio"**
2. **Nombre del servicio**: Escribe `whatsapp` (en minúsculas, sin espacios)
3. **Tipo de servicio**: Selecciona **"Node.js"** o **"App"**
4. Haz clic en **"Create"** o **"Crear"**

### 1.3. Configurar la Fuente (Source) - ⚠️ MUY IMPORTANTE

1. **Busca la sección "Source"** o **"Fuente"** en el menú lateral o en las pestañas
2. **Selecciona "GitHub"** como tipo de fuente
3. **Completa estos campos EXACTAMENTE como se muestra**:

```
Propietario (Owner): GermanPerez-ai
Repositorio (Repository): checkin24hs
Rama (Branch): main
Ruta de compilación (Build Path): /whatsapp-server
```

⚠️ **ATENCIÓN**: 
- La **Ruta de compilación** debe ser: `/whatsapp-server` (con barra inicial, sin barra final)
- La **Rama** debe ser: `main` (NO "working-version" ni "master")
- **Si NO encuentras el campo "Rama"**: Está dentro de la configuración de GitHub, puede estar como "Branch" o puede estar en una sección avanzada

4. **Si NO ves el campo "Rama" o "Branch"**:
   - Busca un botón **"Advanced"** o **"Avanzado"** en la sección Source
   - O busca un menú desplegable que diga **"Branch"** o **"Rama"**
   - O puede estar en la misma línea donde configuras el repositorio

5. Haz clic en **"Save"** o **"Guardar"**

### 1.4. Configurar Variables de Entorno

1. **Busca la sección "Environment Variables"** o **"Variables de Entorno"** o **"Env"**
2. Haz clic en **"Add Variable"** o **"Agregar Variable"** para cada una:

#### Variable 1: INSTANCE_NUMBER
```
Nombre (Name): INSTANCE_NUMBER
Valor (Value): 1
```

#### Variable 2: PORT
```
Nombre (Name): PORT
Valor (Value): 3001
```

#### Variable 3: SUPABASE_URL
```
Nombre (Name): SUPABASE_URL
Valor (Value): https://lmoeuyasuvoqhtvhkyia.supabase.co
```

#### Variable 4: SUPABASE_ANON_KEY
```
Nombre (Name): SUPABASE_ANON_KEY
Valor (Value): eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

#### Variable 5: PUPPETEER_SKIP_CHROMIUM_DOWNLOAD
```
Nombre (Name): PUPPETEER_SKIP_CHROMIUM_DOWNLOAD
Valor (Value): true
```

3. Haz clic en **"Save"** o **"Guardar"** después de agregar todas

### 1.5. Configurar Puertos

1. **Busca la sección "Ports"** o **"Puertos"** o **"Network"**
2. Haz clic en **"Add Port"** o **"Agregar Puerto"**
3. Completa:

```
Protocolo (Protocol): TCP
Publicado (Published): 3001
Destino (Target): 3001
```

4. Haz clic en **"Create"** o **"Crear"**

### 1.6. Configurar Comando de Inicio

1. **Busca la sección "Build"** o **"Compilación"** o **"Start Command"**
2. En el campo **"Start Command"** o **"Comando de Inicio"**, escribe:

```
node whatsapp-server.js
```

3. Haz clic en **"Save"** o **"Guardar"**

### 1.7. Habilitar Auto-Deploy (Despliegue Automático) - ⚠️ OPCIONAL

**NOTA**: Auto-Deploy puede no estar disponible en todas las versiones de EasyPanel. Si no lo encuentras, **NO ES CRÍTICO**. Puedes desplegar manualmente cuando sea necesario.

**Si encuentras la opción**:

1. **Busca la sección "Auto Deploy"** o **"Despliegue Automático"** o **"Auto Deploy"**
   - Puede estar en la sección **"Source"** (Fuente)
   - O en la sección **"Settings"** (Configuración)
   - O en **"Advanced"** (Avanzado)
   - O como un **interruptor** (toggle) en la parte superior de la página

2. **Si la encuentras**:
   - **Activa el interruptor** para habilitarlo
   - **Selecciona la rama**: `main`
   - Haz clic en **"Save"** o **"Guardar"**

3. **Si NO la encuentras** (es normal):
   - ✅ **No te preocupes**, puedes desplegar manualmente
   - Cada vez que quieras actualizar, simplemente haz clic en **"Deploy"** o **"Redeploy"**
   - O puedes hacer `git push` y luego hacer clic en "Deploy" manualmente

### 1.8. Desplegar el Servicio

1. **Busca el botón "Deploy"** o **"Implementar"** o **"Deploy Now"**
2. Haz clic en **"Deploy"**
3. **Espera** a que el servicio se ponga en **verde** (Running)
   - Esto puede tardar 2-5 minutos la primera vez
   - Verás un indicador de progreso

### 1.9. Verificar que Funciona

1. **Haz clic en el servicio** `whatsapp`
2. Ve a la pestaña **"Logs"** o **"Registros"**
3. Deberías ver mensajes como:
   ```
   🚀 Iniciando servidor WhatsApp...
   ✅ Cliente de Supabase inicializado
   WhatsApp server iniciado en puerto 3001
   ```

✅ **¡Primer servicio listo!**

---

## 🚀 PASO 2: Crear el Segundo Servicio (whatsapp2 - Instancia 2)

### 2.1. Crear Nuevo Servicio

1. Haz clic en **"+"** o **"New Service"**
2. **Nombre**: `whatsapp2`
3. **Tipo**: Node.js o App
4. Haz clic en **"Create"**

### 2.2. Configurar la Fuente

**MISMA configuración que el primero**, excepto que el nombre del servicio es diferente:

```
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

### 2.3. Variables de Entorno

**MISMAS variables**, pero cambia estas dos:

```
INSTANCE_NUMBER = 2
PORT = 3002
```

Las demás (SUPABASE_URL, SUPABASE_ANON_KEY, PUPPETEER_SKIP_CHROMIUM_DOWNLOAD) son **iguales**.

### 2.4. Puertos

```
Protocolo: TCP
Publicado: 3002
Destino: 3002
```

### 2.5. Comando de Inicio

```
node whatsapp-server.js
```

### 2.6. Auto-Deploy

```
✅ Habilitado
Rama: main
```

### 2.7. Desplegar

Haz clic en **"Deploy"** y espera a que esté en verde.

✅ **Segundo servicio listo!**

---

## 🚀 PASO 3: Crear el Tercer Servicio (whatsapp3 - Instancia 3)

**Sigue los mismos pasos**, pero con estos valores:

- **Nombre**: `whatsapp3`
- **INSTANCE_NUMBER**: `3`
- **PORT**: `3002` → **NO**, espera, debe ser `3003`
- **Puerto publicado**: `3003`
- **Puerto destino**: `3003`

✅ **Tercer servicio listo!**

---

## 🚀 PASO 4: Crear el Cuarto Servicio (whatsapp4 - Instancia 4)

**Sigue los mismos pasos**, pero con estos valores:

- **Nombre**: `whatsapp4`
- **INSTANCE_NUMBER**: `4`
- **PORT**: `3004`
- **Puerto publicado**: `3004`
- **Puerto destino**: `3004`

✅ **Cuarto servicio listo!**

---

## 📊 RESUMEN DE CONFIGURACIÓN

| Servicio | INSTANCE_NUMBER | PORT | Puerto Publicado | Puerto Destino |
|----------|----------------|------|------------------|----------------|
| whatsapp | 1 | 3001 | 3001 | 3001 |
| whatsapp2 | 2 | 3002 | 3002 | 3002 |
| whatsapp3 | 3 | 3003 | 3003 | 3003 |
| whatsapp4 | 4 | 3004 | 3004 | 3004 |

**TODOS comparten**:
- ✅ Propietario: `GermanPerez-ai`
- ✅ Repositorio: `checkin24hs`
- ✅ Rama: `main`
- ✅ Ruta: `/whatsapp-server`
- ✅ Comando: `node whatsapp-server.js`
- ✅ Auto-Deploy: Habilitado

---

## 🔍 VERIFICACIÓN FINAL

### Verificar que Todos los Servicios Están Corriendo

1. En EasyPanel, ve a la lista de servicios
2. Deberías ver 4 servicios con estos nombres:
   - `whatsapp` → 🟢 Verde (Running)
   - `whatsapp2` → 🟢 Verde (Running)
   - `whatsapp3` → 🟢 Verde (Running)
   - `whatsapp4` → 🟢 Verde (Running)

### Verificar los Logs

Para cada servicio:
1. Haz clic en el servicio
2. Ve a "Logs"
3. Deberías ver: `WhatsApp server iniciado en puerto XXXX`

---

## 🎯 PASO 5: Conectar desde el Dashboard

Una vez que los 4 servicios estén en verde:

### 5.1. Abrir el Dashboard

1. Abre tu navegador
2. Ve a: `https://dashboard.checkin24hs.com`
3. Inicia sesión

### 5.2. Ir a Flor IA

1. En el menú lateral, haz clic en **"Flor IA"**
2. Haz clic en la pestaña **"⚙️ General"** (debería estar seleccionada por defecto)

### 5.3. Configurar URL del Servidor

1. Busca la sección **"📱 Integración con WhatsApp"**
2. En el campo **"URL del Servidor WhatsApp"**, escribe:

```
http://72.61.58.240
```

3. (No necesitas guardar, se guarda automáticamente)

### 5.4. Abrir Modal de Conexión

1. Haz clic en el botón verde **"📱 Conectar Múltiples WhatsApp (hasta 4)"**
2. Se abrirá un modal con 4 tarjetas (WhatsApp 1, 2, 3, 4)

### 5.5. Conectar Cada Instancia

Para cada tarjeta (WhatsApp 1, 2, 3, 4):

1. Haz clic en el botón **"🔗 Conectar"** (botón verde)
2. Espera unos segundos
3. Debería aparecer un **código QR** en la tarjeta
4. **Abre WhatsApp** en tu teléfono
5. Ve a **Configuración** → **Dispositivos vinculados** → **Vincular un dispositivo**
6. **Escanea el código QR** que aparece en la pantalla
7. El estado debería cambiar a **"Conectado"** (verde)

### 5.6. Verificar Conexión

Después de escanear cada QR:
- El estado debería cambiar a **"Conectado"** (verde)
- Deberías ver el **número de teléfono** y el **nombre** en la tarjeta
- El código QR debería desaparecer

---

## 🆘 SOLUCIÓN DE PROBLEMAS

### ❌ El servicio no inicia (se queda en amarillo o rojo)

**Solución**:
1. Ve a "Logs" del servicio
2. Busca mensajes de error
3. Errores comunes:
   - **"Puerto ya en uso"** → Otro servicio está usando el puerto
   - **"Cannot find module"** → Falta instalar dependencias (agrega comando de build: `npm install`)
   - **"No se encuentra whatsapp-server.js"** → Verifica que la ruta sea `/whatsapp-server`

### ❌ No aparece el código QR al hacer clic en "Conectar"

**Solución**:
1. Verifica que el servicio esté en **verde** (Running)
2. Verifica que el puerto sea correcto (3001, 3002, 3003, 3004)
3. Revisa la consola del navegador (F12) para ver errores
4. Verifica que la URL del servidor sea correcta: `http://72.61.58.240`

### ❌ Error: "Failed to fetch"

**Solución**:
1. Verifica que el servicio esté corriendo (verde)
2. Verifica que el puerto sea accesible
3. Prueba acceder directamente: `http://72.61.58.240:3001/api/status`
4. Si no responde, el servicio no está corriendo correctamente

### ❌ El QR no se escanea

**Solución**:
1. Asegúrate de que el QR esté completamente visible
2. Intenta refrescar la página y generar un nuevo QR
3. Verifica que WhatsApp tenga permisos de cámara
4. Prueba con otro teléfono si es posible

### ❌ Error: "Failed to launch the browser process! libnss3.so: cannot open shared object file"

**Problema**: Faltan dependencias de Chromium en el contenedor Docker.

**Solución**:
1. **El Dockerfile ya está actualizado** con todas las dependencias necesarias
2. **Reconstruye la imagen** en EasyPanel:
   - Ve al servicio
   - Haz clic en **"Rebuild"** o **"Reconstruir"**
   - O simplemente haz **"Redeploy"** para que use la nueva imagen
3. **Espera** a que termine la reconstrucción (puede tardar 3-5 minutos)
4. **Verifica los logs** - Deberías ver que el servicio inicia correctamente

### ❌ Error: "Servidor corriendo en puerto 80" (debería ser 3001, 3002, 3003, 3004)

**Problema**: EasyPanel está configurando `PORT=80` en lugar del puerto correcto.

**Solución**:
1. **Ve al servicio** en EasyPanel
2. **Edita las variables de entorno**
3. **Verifica/Cambia** la variable `PORT`:
   - Para servicio 1: `PORT=3001`
   - Para servicio 2: `PORT=3002`
   - Para servicio 3: `PORT=3003`
   - Para servicio 4: `PORT=3004`
4. **Guarda** los cambios
5. **Reinicia** el servicio
6. **Verifica los logs** - Deberías ver: `📡 Servidor corriendo en puerto 3001` (o el puerto correspondiente)

### ❌ Error: "Puerto ya en uso" o conflicto de puertos

**Problema**: Otro servicio está usando el mismo puerto.

**Solución**:
1. **Verifica qué puertos están en uso**:
   - Usa el script: `./whatsapp-server/verificar_puertos.sh`
   - O manualmente: `netstat -tuln | grep 3001`
2. **Detén el servicio** que está usando el puerto (si no es necesario)
3. **O cambia el puerto** del servicio WhatsApp a otro disponible (ej: 3005, 3006, etc.)
4. **Actualiza la configuración** en EasyPanel con el nuevo puerto

📖 **Guía completa de verificación de puertos**: [VERIFICAR_PUERTOS_WHATSAPP.md](./VERIFICAR_PUERTOS_WHATSAPP.md)

---

## ✅ CHECKLIST FINAL

Antes de considerar que todo está listo:

- [ ] Los 4 servicios están creados en EasyPanel
- [ ] Todos los servicios están en **verde** (Running)
- [ ] Los logs muestran "WhatsApp server iniciado en puerto XXXX"
- [ ] Puedes abrir el modal de conexión desde el dashboard
- [ ] Puedes generar códigos QR para cada instancia
- [ ] Puedes escanear los QR con WhatsApp
- [ ] El estado cambia a "Conectado" después de escanear
- [ ] Auto-Deploy está habilitado en todos los servicios

---

## 🎉 ¡LISTO!

Una vez completados todos los pasos:

✅ Los 4 servicios de WhatsApp estarán corriendo  
✅ Podrás conectarlos desde el dashboard  
✅ Flor IA responderá automáticamente a los mensajes  
✅ Todo se actualizará automáticamente cuando hagas cambios en GitHub  

---

## 📞 ¿Necesitas Ayuda?

Si encuentras algún problema:
1. Revisa los logs del servicio en EasyPanel
2. Revisa la consola del navegador (F12) en el dashboard
3. Verifica que todos los valores estén configurados correctamente
4. Consulta la sección "Solución de Problemas" arriba

---

**Última actualización**: Diciembre 2025

