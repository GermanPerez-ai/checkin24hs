# 📋 Guía Paso a Paso: Crear Servicio Dashboard en EasyPanel

## 🎯 Objetivo

Crear un nuevo servicio llamado `dashboard` con la configuración correcta.

---

## Paso 1: Crear el Nuevo Servicio

1. **En EasyPanel, busca el botón "+ Servicio"**
   - Está en la parte **superior derecha** de la pantalla
   - Al lado del botón "Plantillas"
   - Haz clic en **"+ Servicio"**

2. **Se abrirá un modal** para crear un nuevo servicio

---

## Paso 2: Configurar el Nombre y Proyecto

En el modal que se abre:

1. **"Seleccionar proyecto"** (dropdown):
   - Selecciona: `checkin24hs`

2. **"Nombre del servicio"** (campo de texto):
   - Escribe: `dashboard`

3. **Tipo de servicio**:
   - Selecciona: **"Aplicación"** o **"App"** (si hay opciones)

4. Haz clic en **"Crear"** o **"Siguiente"**

---

## Paso 3: Configurar la Fuente (Source)

Después de crear el servicio, verás varias pestañas. Ve a la pestaña **"Fuente"**:

### Opción A: Si usas GitHub

1. Haz clic en la pestaña **"Github"**
2. Selecciona tu repositorio: `Checkin24hs` (o el nombre que tenga)
3. Selecciona la rama: `main` o `master`
4. **Build Path**: Escribe `/deploy`
   - Este campo puede estar en una sección "Configuración de Build" o "Build Settings"
5. **Dockerfile Path**: Escribe `Dockerfile`
   - O si está en la carpeta deploy: `deploy/Dockerfile`

### Opción B: Si usas Git

1. Haz clic en la pestaña **"Git"**
2. Ingresa la URL de tu repositorio
3. **Build Path**: `/deploy`
4. **Dockerfile Path**: `Dockerfile` o `deploy/Dockerfile`

### Opción C: Si usas Dockerfile directamente

1. Haz clic en la pestaña **"Dockerfile"**
2. Aquí puedes especificar:
   - **Build Path**: `/deploy`
   - **Dockerfile Path**: `Dockerfile`

---

## Paso 4: Configurar el Puerto

1. Busca una sección llamada **"Puertos"** o **"Ports"**
   - Puede estar en la misma página de configuración
   - O en una pestaña separada llamada **"Puertos"** o **"Recursos"**

2. **Agrega un puerto**:
   - **Puerto interno**: `80`
   - **Puerto externo**: Puede estar vacío o ser `80` (no es crítico para el proxy)

---

## Paso 5: Configurar Variables de Entorno

1. Ve a la pestaña **"Entorno"** o **"Environment"**
2. En el campo de variables de entorno, agrega:
   ```
   PORT=80
   ```
3. Haz clic en **"Guardar"**

---

## Paso 6: Implementar el Servicio

1. Haz clic en el botón verde **"Implementar"** o **"Deploy"**
2. Espera a que se construya e inicie el servicio
   - Esto puede tardar varios minutos
   - Verás los logs de construcción en la pantalla

---

## Paso 7: Agregar el Dominio

Una vez que el servicio esté corriendo:

1. Ve a la pestaña **"Dominios"** (en el menú lateral izquierdo)
2. Haz clic en **"Agregar dominio"**
3. Ingresa: `dashboard.checkin24hs.com`
4. EasyPanel debería generar automáticamente: `http://dashboard:80/`
5. Guarda los cambios

---

## Paso 8: Probar

1. Espera 30-60 segundos
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. Deberías ver el dashboard funcionando

---

## 🔍 Si No Encuentras los Campos

Si no ves los campos "Build Path" o "Dockerfile Path":

1. **Busca una sección llamada "Configuración" o "Settings"**
2. O busca un botón **"Configuración avanzada"** o **"Advanced Settings"**
3. O busca en la pestaña **"Fuente"** opciones de configuración adicionales

---

## 📸 Dónde Está Cada Configuración

- **Build Path**: Generalmente en la pestaña "Fuente" o "Source", en la sección de configuración de build
- **Dockerfile Path**: Generalmente en la misma sección que Build Path
- **Puerto**: En la pestaña "Puertos" o "Ports", o en "Recursos" o "Resources"
- **Variables de entorno**: En la pestaña "Entorno" o "Environment"

---

**¿En qué paso estás? ¿Qué pantalla ves ahora? Comparte y te ayudo a encontrar la configuración específica.**
