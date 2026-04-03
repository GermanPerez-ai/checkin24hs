# 🚀 Configurar Dashboard Admin (checkin24hs-admin) en EasyPanel - Paso a Paso

## 🎯 Objetivo

Configurar la aplicación React `checkin24hs-admin` en EasyPanel para que funcione en `dashboard.checkin24hs.com`.

---

## 📋 Paso 1: Acceder a EasyPanel

1. Abre tu navegador y ve a tu panel de EasyPanel
2. Inicia sesión con tus credenciales
3. Busca el proyecto **"Checkin24hs"** o el proyecto donde quieres configurar el dashboard

---

## 📋 Paso 2: Verificar o Crear el Servicio

### Opción A: Si ya existe un servicio llamado "dashboard" o "admin"

1. Haz clic en el servicio existente
2. **IMPORTANTE**: Si los logs muestran Nginx (no Node.js), necesitas reconfigurarlo completamente
3. Ve al Paso 3

### Opción B: Si no existe el servicio

1. Haz clic en **"+"** o **"Crear Servicio"** o **"Add Service"**
2. Elige el tipo: **"Node.js"** o **"Custom"** (NO elijas "Nginx" o "Static")
3. Nombre del servicio: `dashboard` o `admin`
4. Haz clic en **"Crear"** o **"Create"**

---

## 📋 Paso 3: Configurar la Fuente (Source)

1. En el servicio del dashboard, ve a la sección **"Fuente"** o **"Source"** (icono `</>`)
2. Configura los siguientes valores:

   **Propietario:**
   ```
   GermanPerez-ai
   ```

   **Repositorio:**
   ```
   checkin24hs
   ```

   **Rama:**
   ```
   main
   ```

   **Ruta de compilación:**
   ```
   /checkin24hs-admin
   ```
   ⚠️ **IMPORTANTE**: Debe ser `/checkin24hs-admin` (con la barra inicial y el nombre exacto de la carpeta)

3. Haz clic en **"Guardar"** o **"Save"**

---

## 📋 Paso 4: Configurar Variables de Entorno

1. Ve a la sección **"Variables de Entorno"** o **"Environment Variables"** (icono de engranaje)
2. Haz clic en **"Agregar Variable"** o **"Add Variable"** para cada una:

   **Variable 1:**
   ```
   Nombre: NODE_ENV
   Valor: production
   ```

   **Variable 2 (Opcional - solo si necesitas conectar a una API):**
   ```
   Nombre: REACT_APP_API_URL
   Valor: http://72.61.58.240:3001/api
   ```
   *(Solo agrega esta si tu aplicación React necesita conectarse a una API)*

3. Haz clic en **"Guardar"** o **"Save"** después de agregar cada variable

---

## 📋 Paso 5: Configurar el Build (Compilación)

1. Ve a la sección **"Compilación"** o **"Build"** (icono de herramientas)
2. Configura:

   **Comando de build:**
   ```
   npm install && npm run build
   ```
   *(Esto instala las dependencias y construye la aplicación React)*

   **Carpeta de salida (Output Directory):**
   ```
   build
   ```
   *(Esta es la carpeta donde React genera los archivos estáticos)*

3. Haz clic en **"Guardar"** o **"Save"**

---

## 📋 Paso 6: Configurar el Comando de Inicio

1. En la misma sección **"Compilación"** o **"Build"**, busca **"Comando de inicio"** o **"Start Command"**
2. Ingresa:
   ```
   npx serve -s build -l 3000
   ```
   *(Esto sirve los archivos estáticos de la carpeta `build` en el puerto 3000)*

3. Haz clic en **"Guardar"** o **"Save"**

---

## 📋 Paso 7: Configurar el Puerto

1. Ve a la sección **"Puertos"** o **"Ports"** (icono de red)
2. Si ya existe un puerto, elimínalo primero (botón X)
3. Haz clic en **"+ Agregar Puerto"** o **"+ Add Port"**
4. Configura:

   **Protocolo:**
   ```
   HTTP
   ```
   o
   ```
   TCP
   ```

   **Puerto interno (Internal Port):**
   ```
   3000
   ```

   **Puerto externo (External Port):**
   ```
   3000
   ```
   *(O déjalo automático si EasyPanel lo permite)*

5. Haz clic en **"Crear"** o **"Create"**

---

## 📋 Paso 8: Configurar el Dominio

1. Ve a la sección **"Dominios"** o **"Domains"** (icono de globo)
2. Si ya existe el dominio `dashboard.checkin24hs.com`, haz clic en él para editarlo
3. Si no existe, haz clic en **"+ Agregar Dominio"** o **"+ Add Domain"**
4. Configura:

   **Dominio:**
   ```
   dashboard.checkin24hs.com
   ```

   **Puerto:**
   ```
   3000
   ```
   ⚠️ **IMPORTANTE**: Debe ser el mismo puerto que configuraste en el Paso 7 (3000)

5. Haz clic en **"Guardar"** o **"Save"**

---

## 📋 Paso 9: Configurar Recursos (Opcional pero Recomendado)

1. Ve a la sección **"Recursos"** o **"Resources"** (icono de CPU)
2. Configura:

   **Memoria (Memory):**
   ```
   1024 MB
   ```
   o
   ```
   2048 MB
   ```
   *(Recomendado: 1024 MB mínimo para construir la aplicación React)*

   **CPU:**
   ```
   1
   ```
   *(O el que EasyPanel asigne automáticamente)*

3. Haz clic en **"Guardar"** o **"Save"**

---

## 📋 Paso 10: Implementar el Servicio

1. Ve a la sección **"Implementaciones"** o busca el botón **"Implementar"** o **"Deploy"** (botón verde)
2. Haz clic en **"Implementar"** o **"Deploy"**
3. **Espera 3-5 minutos** mientras:
   - EasyPanel descarga el código de GitHub
   - Instala las dependencias (`npm install`)
   - Construye la aplicación (`npm run build`)
   - Inicia el servidor (`npx serve`)

4. Observa el estado del servicio:
   - 🟡 **Amarillo** = Está construyendo/iniciando (espera)
   - 🟢 **Verde** = Está corriendo (listo)
   - 🔴 **Rojo** = Hay un error (revisa los logs)

---

## 📋 Paso 11: Verificar los Logs

1. Haz clic en el servicio del dashboard
2. Ve a la pestaña **"Logs"** o **"Registros"**
3. Deberías ver algo como:

   ```
   npm install
   ...
   npm run build
   ...
   Compiled successfully!
   ...
   npx serve -s build -l 3000
   Serving! http://0.0.0.0:3000
   ```

4. Si ves errores, anótalos para solucionarlos

---

## 📋 Paso 12: Probar el Dashboard

1. Abre tu navegador
2. Ve a: `https://dashboard.checkin24hs.com` (o `http://` si no tienes SSL)
3. Deberías ver:
   - ✅ La pantalla de login del panel de administración
   - ✅ O el dashboard si ya estás autenticado

4. **Credenciales de prueba:**
   - Email: `admin@checkin24hs.com`
   - Contraseña: `admin123`

---

## ✅ Checklist Final

Antes de considerar que está listo, verifica:

- [ ] El servicio está en **verde (Running)** en EasyPanel
- [ ] Los logs muestran `Serving! http://0.0.0.0:3000`
- [ ] El puerto interno es `3000`
- [ ] El dominio `dashboard.checkin24hs.com` está configurado con puerto `3000`
- [ ] Puedes acceder a `dashboard.checkin24hs.com` y ver la pantalla de login
- [ ] No hay errores en los logs

---

## 🆘 Solución de Problemas

### Problema: El servicio está en rojo

**Solución:**
1. Ve a **"Logs"** y copia los últimos mensajes
2. Busca errores como:
   - `Cannot find module` → Verifica que la ruta sea `/checkin24hs-admin`
   - `Build failed` → Revisa los errores de compilación
   - `Port already in use` → Cambia el puerto a `3001` y actualiza el dominio

### Problema: El servicio está en amarillo por mucho tiempo

**Solución:**
1. **Espera 5-10 minutos** (la primera vez puede tardar más)
2. Si después de 10 minutos sigue amarillo:
   - Revisa los logs
   - Verifica que la memoria sea suficiente (mínimo 1024 MB)
   - Intenta reiniciar el servicio

### Problema: Error 502 Bad Gateway

**Solución:**
1. Verifica que el puerto en **"Dominios"** sea `3000` (el mismo que el puerto interno)
2. Verifica que los logs muestren `Serving! http://0.0.0.0:3000`
3. Espera 1-2 minutos después de que el servicio esté en verde
4. Limpia la caché del navegador (Ctrl+F5)

### Problema: Los logs muestran Nginx en lugar de Node.js

**Solución:**
1. El servicio está configurado incorrectamente
2. **Elimina el servicio** y créalo de nuevo desde el Paso 2
3. Asegúrate de elegir **"Node.js"** o **"Custom"**, NO **"Nginx"** o **"Static"**

### Problema: "Cannot find module 'serve'"

**Solución:**
1. Cambia el comando de inicio a:
   ```
   npm install -g serve && serve -s build -l 3000
   ```
2. O usa esta alternativa:
   ```
   npm install && npm run build && npx serve -s build -l 3000
   ```

---

## 📝 Resumen de Configuración

| Sección | Configuración |
|---------|---------------|
| **Tipo de Servicio** | Node.js o Custom |
| **Fuente** | GitHub: `GermanPerez-ai/checkin24hs` (rama: `main`) |
| **Ruta de Compilación** | `/checkin24hs-admin` |
| **Comando de Build** | `npm install && npm run build` |
| **Carpeta de Salida** | `build` |
| **Comando de Inicio** | `npx serve -s build -l 3000` |
| **Puerto Interno** | `3000` |
| **Dominio** | `dashboard.checkin24hs.com` (puerto: `3000`) |
| **Variables de Entorno** | `NODE_ENV=production` |
| **Memoria** | 1024 MB (mínimo) |

---

## 🎉 ¡Listo!

Una vez completados todos los pasos, tu panel de administración React debería estar funcionando en `dashboard.checkin24hs.com`.

Si tienes algún problema en algún paso, detente y revisa los logs antes de continuar.

