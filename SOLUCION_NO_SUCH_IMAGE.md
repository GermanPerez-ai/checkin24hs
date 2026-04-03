# 🔧 Solución: Error "No such image"

## 🎯 Problema

El error "No such image: easypanel/checkin24hs/dashboard:latest" significa que el servicio está configurado para usar una imagen Docker que no existe.

Para Node.js, necesitamos que el servicio se construya desde el código fuente (GitHub), no desde una imagen Docker.

## ✅ Solución: Configurar Fuente desde GitHub

### Paso 1: Ir a la Pestaña "Fuente"

1. En el menú lateral izquierdo, haz clic en **"</> Fuente"** o **"Source"**
2. Verás varias pestañas: "Subir", "Github", "Imagen Docker", "Git", "Dockerfile"

### Paso 2: Cambiar a GitHub (No Docker Image)

1. Haz clic en la pestaña **"Github"** (NO "Imagen Docker")
2. Configura:
   - **Propietario**: `GermanPerez-ai` (o tu usuario de GitHub)
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main` (o la rama que tengas)
   - **Build Path** o **Ruta de compilación**: `/` (raíz, donde está `server.js`)
   - **Dockerfile Path**: Déjalo vacío o elimínalo (no necesitamos Dockerfile para Node.js básico)

### Paso 3: Verificar que NO Esté en "Imagen Docker"

1. Asegúrate de que la pestaña **"Imagen Docker"** NO esté seleccionada
2. Si está seleccionada, cámbiala a **"Github"**

### Paso 4: Configurar Variables de Entorno

1. Ve a la pestaña **"Entorno"** o **"Environment"**
2. Agrega:
   ```
   PORT=3000
   NODE_ENV=production
   ```
3. Guarda

### Paso 5: Configurar Puerto

1. Ve a la pestaña **"Puertos"** o **"Ports"**
2. Agrega:
   - **Puerto interno**: `3000`

### Paso 6: Implementar de Nuevo

1. Haz clic en el botón verde **"Implementar"** o **"Deploy"**
2. Esta vez debería construir desde GitHub, no buscar una imagen Docker
3. Espera a que se construya (puede tardar varios minutos)

### Paso 7: Verificar los Logs

Después de implementar, ve a **"Registros"** o **"Logs"** y verifica que:
- ✅ Muestre logs de construcción desde GitHub
- ✅ Muestre: `🚀 Servidor iniciado en http://0.0.0.0:3000`
- ❌ NO muestre: "No such image"

---

## 🔍 Si No Ves la Pestaña "Github"

Si no ves la pestaña "Github":

1. Verifica que el servicio esté configurado como **"Node.js"** o **"Aplicación"**, no como "Docker"
2. O elimina el servicio y créalo de nuevo como Node.js desde el inicio

---

**Ve a la pestaña "Fuente", cambia a "Github" (no "Imagen Docker"), configura tu repositorio, y luego haz clic en "Implementar".**
