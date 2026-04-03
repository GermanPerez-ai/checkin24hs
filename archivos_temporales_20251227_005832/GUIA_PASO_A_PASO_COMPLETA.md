# 📋 Guía Paso a Paso Completa - Recrear Dashboard desde Cero

## 🎯 Objetivo
Recrear el servicio del dashboard desde cero usando el código que funciona en tu disco local.

---

## ✅ PASO 1: Verificar Código en tu Computadora

### 1.1. Abrir el Dashboard Local

1. Abre la carpeta: `C:\Users\German\Downloads\Checkin24hs`
2. Haz doble clic en `dashboard.html`
3. Se abrirá en tu navegador
4. **Verifica que funciona completamente**:
   - ✅ Tiene todos los menús (Dashboard, Hoteles, Reservas, etc.)
   - ✅ Puedes navegar entre secciones
   - ✅ Todo funciona correctamente

### 1.2. Verificar Archivos Necesarios

En la carpeta `C:\Users\German\Downloads\Checkin24hs`, verifica que existan estos archivos:

**Archivos principales:**
- ✅ `dashboard.html` (debe tener más de 22,000 líneas)
- ✅ `server.js`
- ✅ `Dockerfile`
- ✅ `package.json`

**Archivos JavaScript:**
- ✅ `supabase-client.js`
- ✅ `supabase-config.js`
- ✅ `database.js`
- ✅ `dashboard-integration.js`
- ✅ `flor-agent.js`
- ✅ `flor-ai-service.js`
- ✅ `flor-knowledge-base.js`
- ✅ `flor-learning-system.js`
- ✅ `flor-multimodal-service.js`
- ✅ `flor-widget.js`
- ✅ `puppeteer-real-cotizacion.js`

**Recursos:**
- ✅ `logo.png` (o logos similares)
- ✅ Carpeta `hotel-images/`

**Si falta algún archivo, avísame antes de continuar.**

---

## ✅ PASO 2: Verificar Código en GitHub

### 2.1. Abrir GitHub

1. Abre tu navegador
2. Ve a: `https://github.com/GermanPerez-ai/checkin24hs`
3. Verifica que estás en la rama `working-version` (arriba a la izquierda, selecciona la rama)

### 2.2. Verificar Archivos en GitHub

En la raíz del repositorio (no en subcarpetas), verifica que existan:

- ✅ `dashboard.html`
- ✅ `server.js`
- ✅ `Dockerfile`
- ✅ `package.json`

**Si falta algún archivo, continúa con el Paso 3 para subirlo.**

---

## ✅ PASO 3: Subir Código a GitHub (Si Falta Algo)

### 3.1. Abrir Terminal en tu Computadora

1. Presiona `Windows + R`
2. Escribe: `cmd` y presiona Enter
3. O abre PowerShell desde el menú Inicio

### 3.2. Ir a la Carpeta del Proyecto

En la terminal, escribe:

```cmd
cd C:\Users\German\Downloads\Checkin24hs
```

Presiona Enter.

### 3.3. Verificar Estado de Git

Escribe:

```cmd
git status
```

Presiona Enter.

### 3.4. Agregar Archivos a Git

Si hay archivos sin agregar, escribe:

```cmd
git add dashboard.html server.js Dockerfile package.json
git add supabase-client.js supabase-config.js database.js dashboard-integration.js
git add flor-agent.js flor-ai-service.js flor-knowledge-base.js flor-learning-system.js flor-multimodal-service.js flor-widget.js
git add puppeteer-real-cotizacion.js
git add logo*.png logo*.svg
git add hotel-images/
```

Presiona Enter después de cada línea.

### 3.5. Hacer Commit

Escribe:

```cmd
git commit -m "Asegurar código completo del dashboard"
```

Presiona Enter.

### 3.6. Subir a GitHub

Escribe:

```cmd
git push origin working-version
```

Presiona Enter.

**Espera a que termine. Si pide usuario y contraseña, ingrésalos.**

---

## ✅ PASO 4: Hacer Backup de Configuración Actual

### 4.1. Abrir EasyPanel

1. Abre tu navegador
2. Ve a tu panel de EasyPanel
3. Inicia sesión

### 4.2. Ir al Servicio Actual

1. Ve a tu proyecto `checkin24hs`
2. Haz clic en el servicio `checkin24hs-dashboard`

### 4.3. Anotar Configuración

**Anota en un papel o archivo de texto:**

1. **Variables de Entorno** (si hay):
   - Ve a la pestaña "Variables de Entorno"
   - Copia todas las variables que veas

2. **Puertos**:
   - Ve a la pestaña "Puertos"
   - Anota: Protocolo, Publicado, Destino

3. **Dominios**:
   - Ve a la pestaña "Dominios"
   - Anota: Dominio, Puerto interno

**Guarda esta información, la necesitarás después.**

---

## ✅ PASO 5: Eliminar el Servicio Actual

### 5.1. Detener el Servicio

1. En EasyPanel, en el servicio `checkin24hs-dashboard`
2. Si está corriendo (verde), busca el botón **"Detener"** o **"Stop"**
3. Haz clic y espera a que se detenga

### 5.2. Eliminar el Servicio

1. Busca el botón **"Eliminar"** o **"Delete"** (icono de basura 🗑️)
   - Generalmente está en la parte superior derecha
2. Haz clic en "Eliminar"
3. Confirma la eliminación cuando te lo pida

**⚠️ IMPORTANTE: Esto NO elimina tus datos, solo el servicio. Tus datos están seguros en la base de datos.**

---

## ✅ PASO 6: Crear el Servicio Nuevo

### 6.1. Crear Nuevo Servicio

1. En EasyPanel, en tu proyecto `checkin24hs`
2. Busca el botón **"+"** o **"Crear Servicio"** o **"New Service"**
3. Haz clic

### 6.2. Nombre del Servicio

1. En el campo **"Nombre"** o **"Name"**, escribe:
   ```
   checkin24hs-dashboard
   ```
2. **Tipo de servicio**: Selecciona `Node.js` o `Docker` (cualquiera, lo configuraremos)
3. Haz clic en **"Crear"** o **"Create"**

---

## ✅ PASO 7: Configurar la Fuente (Source)

### 7.1. Ir a la Pestaña "Fuente"

1. En el servicio que acabas de crear
2. Haz clic en la pestaña **"Fuente"** o **"Source"**

### 7.2. Seleccionar GitHub

1. Verás varias pestañas: "Subir", "Github", "Imagen Docker", etc.
2. Haz clic en la pestaña **"Github"**

### 7.3. Configurar Repositorio

1. **Propietario** o **Owner**:
   ```
   GermanPerez-ai
   ```

2. **Repositorio** o **Repository**:
   ```
   checkin24hs
   ```

3. **Rama** o **Branch**:
   ```
   working-version
   ```

4. **Ruta de compilación** o **Build Path**:
   ```
   /
   ```
   **⚠️ MUY IMPORTANTE: Debe ser `/` (solo una barra), NO `/checkin24hs-admin`**

### 7.4. Guardar

1. Haz clic en el botón **"Guardar"** o **"Save"** (generalmente verde, abajo)
2. Espera a que guarde

---

## ✅ PASO 8: Configurar la Compilación (Build)

### 8.1. Ir a la Sección "Compilación"

1. En la misma página de "Fuente"
2. Desplázate hacia abajo
3. Busca la sección **"Compilación"** o **"Build"**

### 8.2. Seleccionar Dockerfile

1. Verás opciones: "Dockerfile", "Buildpacks", "Nixpacks"
2. Selecciona **"Dockerfile"** (haz clic en el círculo)

### 8.3. Configurar Dockerfile

1. En el campo **"Archivo"** o **"File"**, debe decir:
   ```
   Dockerfile
   ```
2. Si está vacío o dice otra cosa, escríbelo: `Dockerfile`

### 8.4. Guardar

1. Haz clic en **"Guardar"** o **"Save"**

---

## ✅ PASO 9: Configurar Puertos

### 9.1. Ir a la Pestaña "Puertos"

1. En el servicio, busca la pestaña **"Puertos"** o **"Ports"**
2. Haz clic

### 9.2. Agregar Puerto

1. Busca el botón **"Agregar Puerto"** o **"Add Port"** o **"+"**
2. Haz clic

### 9.3. Configurar Puerto

1. **Protocolo** o **Protocol**: Selecciona `TCP`
2. **Publicado** o **Published**: Escribe `30002`
3. **Destino** o **Target**: Escribe `3000`
4. **Modo** o **Mode** (si hay opción): Selecciona `Ingress` o `Host` (cualquiera)

### 9.4. Guardar

1. Haz clic en **"Crear"** o **"Guardar"** o **"Save"**

---

## ✅ PASO 10: Configurar Dominio (Si Tenías Uno)

### 10.1. Ir a la Pestaña "Dominios"

1. En el servicio, busca la pestaña **"Dominios"** o **"Domains"**
2. Haz clic

### 10.2. Agregar Dominio

1. Busca el botón **"Agregar Dominio"** o **"Add Domain"**
2. Haz clic

### 10.3. Configurar Dominio

1. **Dominio**: Escribe `panel.checkin24hs.com` (o el que tenías antes)
2. **Puerto interno** o **Internal Port**: Escribe `3000`
3. **Target Service** (si hay opción): Selecciona `checkin24hs-dashboard`

### 10.4. Guardar

1. Haz clic en **"Crear"** o **"Guardar"**

---

## ✅ PASO 11: Restaurar Variables de Entorno (Si Había)

### 11.1. Ir a Variables de Entorno

1. En el servicio, busca la pestaña **"Variables de Entorno"** o **"Environment"**
2. Haz clic

### 11.2. Agregar Variables

1. Si tenías variables antes (del Paso 4), agrégalas de nuevo:
   - Haz clic en **"Agregar Variable"** o **"Add Variable"**
   - Escribe el nombre y el valor
   - Repite para cada variable

**Nota: Para el dashboard básico, normalmente NO necesitas variables de entorno.**

---

## ✅ PASO 12: Implementar el Servicio

### 12.1. Buscar el Botón "Implementar"

1. En la parte superior de la página del servicio
2. Busca el botón **"Implementar"** o **"Deploy"** (generalmente verde y grande)
3. Haz clic

### 12.2. Esperar la Construcción

1. Verás que el servicio cambia a estado "Building" o "Construyendo"
2. **Espera 2-5 minutos** mientras se construye
3. Puedes ver el progreso en la pestaña "Logs"

### 12.3. Verificar que Terminó

1. El servicio debe cambiar a estado **"Running"** o **"Corriendo"** (verde)
2. Si está en amarillo o rojo, ve al Paso 13

---

## ✅ PASO 13: Verificar Logs

### 13.1. Ir a la Pestaña "Logs"

1. En el servicio, busca la pestaña **"Logs"**
2. Haz clic

### 13.2. Verificar Mensajes

Debes ver estos mensajes:

```
🚀 Servidor iniciado en http://0.0.0.0:3000/
📊 API disponible en http://0.0.0.0:3000/api/puyehue-quote
🌐 Frontend disponible en http://0.0.0.0:3000
```

**Si ves estos mensajes, el servidor está funcionando correctamente.**

**Si ves errores, anótalos y avísame.**

---

## ✅ PASO 14: Probar el Dashboard

### 14.1. Abrir en el Navegador

1. Abre tu navegador
2. Ve a: `http://72.61.58.240:30002`
3. O si configuraste dominio: `http://panel.checkin24hs.com`

### 14.2. Verificar que Funciona

Debes ver:
- ✅ El dashboard completo con todos los menús
- ✅ Puedes hacer clic en los menús (Dashboard, Hoteles, Reservas, etc.)
- ✅ Todo funciona correctamente

**Si ves la versión incompleta (solo 4 pestañas), avísame y lo corregimos.**

---

## 🆘 Si Algo Sale Mal

### Problema: El servicio no inicia

1. Ve a la pestaña "Logs"
2. Copia los últimos mensajes de error
3. Avísame qué dice

### Problema: Error de compilación

1. Verifica que la "Ruta de compilación" sea `/` (raíz)
2. Verifica que el tipo de compilación sea `Dockerfile`
3. Verifica que el archivo Dockerfile exista en GitHub

### Problema: Puerto no funciona

1. Verifica que el puerto 30002 esté configurado
2. Prueba con otro puerto (30003, 30004)
3. Avísame y lo corregimos

---

## ✅ Checklist Final

Antes de terminar, verifica:

- [ ] Código subido a GitHub (rama `working-version`)
- [ ] Servicio creado en EasyPanel
- [ ] Ruta de compilación: `/` (raíz) ✅
- [ ] Tipo de compilación: `Dockerfile` ✅
- [ ] Puerto configurado (30002 → 3000)
- [ ] Servicio corriendo (verde)
- [ ] Logs muestran "🚀 Servidor iniciado"
- [ ] Dashboard accesible desde el navegador
- [ ] Dashboard muestra todos los menús

---

## 🎉 ¡Listo!

Si completaste todos los pasos y el dashboard funciona, ¡estás listo!

Si tienes algún problema en cualquier paso, avísame y te ayudo.


